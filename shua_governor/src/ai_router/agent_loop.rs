use std::sync::Arc;
use anyhow::Result;
use serde::Serialize;
use tracing::{error, info, warn};
use tokio::sync::Semaphore;
use tokio::time::{timeout, Duration};

use crate::mcp::aggregator::McpAggregator;
use crate::mcp::executor::McpExecutor;
use crate::mcp::McpToolCall;
use crate::ollama::client::{ChatMessage, OllamaClient};
use crate::registry::process_manager::ProcessManager;
use crate::ollama::OllamaLifecycle;

pub const MAX_AGENT_ITERATIONS: usize = 5;
pub const PER_CALL_TIMEOUT_SECS: u64 = 90;
/// Suffix appended to prompts that exceed max_prompt_chars.
const TRUNCATION_SUFFIX: &str = " [...truncated to fit context budget]";

/// Strips inline tool-call artifacts emitted by models like qwen2.5 that sometimes
/// write raw `<tool_call>...</tool_call>` XML or ` ```json {"name":...} ``` ` blocks
/// directly into `content` instead of using the structured `tool_calls` field.
/// Also removes `tool_response:` sections that appear when the model narrates its
/// own tool execution inside free text.
///
/// Regexes are compiled once via `once_cell::sync::Lazy` — O(1) amortized, Pi5-safe.
fn strip_tool_call_artifacts(text: &str) -> String {
    use once_cell::sync::Lazy;
    use regex::Regex;

    // <tool_call>...</tool_call> XML blocks (DOTALL)
    static RE_XML: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"(?s)<tool_call>.*?</tool_call>").expect("valid regex")
    });
    // ```json {...} ``` fenced blocks containing a "name" key (tool call JSON)
    static RE_JSON_FENCE: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r#"(?s)```(?:json)?\s*\{[^`]*"name"[^`]*\}\s*```"#).expect("valid regex")
    });
    // Bare JSON tool call fragments: {"name":"...","arguments":...}
    static RE_BARE_JSON: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r#"\{\s*"name"\s*:\s*"[^"]+"\s*,\s*"arguments"\s*:\s*\{[^}]*\}\s*\}"#).expect("valid regex")
    });
    // tool_response: ... inline narration sections
    // Note: Rust `regex` crate does not support look-ahead (?=...), so we
    // match through the double-newline delimiter (or end of string) instead.
    static RE_TOOL_RESP: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"(?s)tool_response:\s*\n.*?(?:\n\n|$)").expect("valid regex")
    });
    // Collapse 3+ consecutive blank lines into 2
    static RE_BLANK: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r"\n{3,}").expect("valid regex")
    });

    let cleaned = RE_XML.replace_all(text, "");
    let cleaned = RE_JSON_FENCE.replace_all(&cleaned, "");
    let cleaned = RE_BARE_JSON.replace_all(&cleaned, "");
    let cleaned = RE_TOOL_RESP.replace_all(&cleaned, "");
    RE_BLANK.replace_all(cleaned.trim(), "\n\n").trim().to_string()
}

/// Parses inline tool call JSON objects from model content text.
/// Handles three formats emitted by qwen2.5 and similar models:
///  1. `<tool_call>{"name":...}</tool_call>` XML-wrapped
///  2. ` ```json {"name":...} ``` ` fenced blocks
///  3. Bare `{"name":"...","arguments":{...}}` on a line
///
/// Returns Vec of parsed McpToolCall. O(n) single-pass scan.
fn parse_inline_tool_calls(content: &str) -> Vec<McpToolCall> {
    let mut calls = Vec::new();

    // Strategy: find JSON objects containing "name" and "arguments" keys.
    // We scan for opening braces and try to parse JSON from that position.
    for line in content.lines() {
        let trimmed = line.trim()
            .trim_start_matches("<tool_call>")
            .trim_end_matches("</tool_call>")
            .trim();

        // Skip lines that are clearly not tool call JSON
        if !trimmed.starts_with('{') || !trimmed.contains("\"name\"") {
            continue;
        }

        if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(trimmed) {
            if let (Some(name), Some(args)) = (
                parsed.get("name").and_then(|v| v.as_str()),
                parsed.get("arguments"),
            ) {
                calls.push(McpToolCall {
                    id: None,
                    name: name.to_string(),
                    arguments: args.clone(),
                });
            }
        }
    }

    calls
}


static LOCAL_INFERENCE_SEMAPHORE: Semaphore = Semaphore::const_new(1);

/// Record of a single tool call executed during an agent loop turn.
#[derive(Debug, Clone, Serialize)]
pub struct ToolCallStep {
    pub tool_name: String,
    pub arguments: serde_json::Value,
    /// Truncated result for wire efficiency (max 500 chars).
    pub result_summary: String,
    pub success: bool,
}

/// Record of a single turn within the N-turn agent loop.
#[derive(Debug, Clone, Serialize)]
pub struct AgentLoopStep {
    pub turn: usize,
    /// One of: "tool_execution", "inline_tool_execution", "nudge", "final_answer"
    pub step_type: String,
    pub model_content: String,
    pub tool_calls: Vec<ToolCallStep>,
}

pub struct AgentLoopResponse {
    pub final_reply: String,
    pub iterations: usize,
    pub tools_called: Vec<String>,
    /// Whether the user prompt was tail-truncated before sending to the LLM.
    pub prompt_truncated: bool,
    /// Detailed record of each turn for Flutter UI visibility.
    pub steps: Vec<AgentLoopStep>,
}

pub struct McpAgentLoop;

impl McpAgentLoop {
    /// Execute an autonomous N-Turn MCP tool-calling agent loop (max 5 iterations).
    ///
    /// # Arguments
    /// - `prompt`            — raw user input (may be truncated if > max_prompt_chars)
    /// - `scope`             — routing scope label (e.g. "governor")
    /// - `model`             — model name to use for inference
    /// - `client`            — OllamaClient pointing at local RPi5 or offload Windows
    /// - `process_manager`   — for MCP tool execution
    /// - `ollama_lifecycle`  — for MCP tool execution
    /// - `force_tool_choice` — when true, enforces tool call before free-text answer
    /// - `max_prompt_chars`  — tail-truncation limit; 0 = unlimited
    /// - `min_inference_gap_ms` — sleep before each local LLM call to pace thermals; 0 = none
    /// - `context_messages`  — prior conversation history to prepend (sliding window)
    #[allow(clippy::too_many_arguments)]
    pub async fn run(
        prompt: &str,
        scope: &str,
        model: &str,
        client: &OllamaClient,
        process_manager: &Arc<ProcessManager>,
        ollama_lifecycle: &Arc<OllamaLifecycle>,
        force_tool_choice: bool,
        max_prompt_chars: usize,
        min_inference_gap_ms: u64,
        context_messages: Vec<ChatMessage>,
    ) -> Result<AgentLoopResponse> {
        // ── Prompt Guardrail: Tail-truncate oversized user prompts ────────────
        // Prevents the KV-cache allocation on RPi5 Ollama from ballooning even
        // when inference is offloaded (the broker still serialises the full
        // request body per turn).
        let (effective_prompt, prompt_truncated) = if max_prompt_chars > 0
            && prompt.len() > max_prompt_chars
        {
            let safe_limit = max_prompt_chars.saturating_sub(TRUNCATION_SUFFIX.len());
            let mut truncated = prompt[..safe_limit].to_string();
            truncated.push_str(TRUNCATION_SUFFIX);
            warn!(
                subsystem = "agent_loop",
                original_len = prompt.len(),
                limit = max_prompt_chars,
                "Prompt exceeded max_prompt_chars — tail-truncated"
            );
            (truncated, true)
        } else {
            (prompt.to_string(), false)
        };

        let tool_enforcement_clause = if force_tool_choice {
            " CRITICAL: For this request you MUST call one of the MCP tools listed above \
            before giving a final answer. Do NOT claim you lack access to system information \
            — you have direct tool access via MCP. Never suggest generic OS-level commands \
            (dmesg, Event Viewer, etc.) when an MCP tool exists for the task. Call the tool first."
        } else {
            ""
        };

        let system_prompt = format!(
            "You are JOSH, the horAIzon 3.0 Central AI Assistant running on Raspberry Pi 5. \
            You have access to Model Context Protocol (MCP) system control tools (scope: '{}'). \
            Available MCP Tools: \
            1. `governor_get_metrics`: Fetches live Pi 5 CPU %, RAM, temperature, NVMe status, uptime, and module states. \
            2. `governor_query_logs`: Queries recent system logs, errors, telemetry metrics, and events from activity.db database. \
            3. `governor_wake_module`: Resumes a sleeping microservice (shua.diary, shua.resume, etc.). \
            4. `governor_sleep_module`: Pauses a running microservice to free RAM/CPU. \
            5. `governor_load_ollama_model`: Loads a specified LLM model into RAM/VRAM. \
            INSTRUCTIONS: \
            - When asked for system health, NVMe status, hardware metrics, or uptime, call `governor_get_metrics`. \
            - When asked for system logs, errors, activity.db, or `governor_query_logs`, call `governor_query_logs`. \
            - When asked what MCP tools are available, list the horAIzon 3.0 system tools above.{}",
            scope, tool_enforcement_clause
        );

        // ── Build initial messages: system + sliding window context + user ────
        let mut messages = vec![ChatMessage::system(system_prompt)];
        messages.extend(context_messages);
        messages.push(ChatMessage::user(effective_prompt.clone()));

        // ── Build tools JSON once — only sent on the first turn ───────────────
        // Subsequent turns receive None to avoid re-serialising the full schema
        // on every loop iteration, which wastes Pi 5 RAM and serialisation CPU.
        let aggregator = McpAggregator::new();
        let mcp_schemas = aggregator.get_system_tools();
        let tools_json: Vec<serde_json::Value> = mcp_schemas
            .into_iter()
            .map(|t| {
                serde_json::json!({
                    "type": "function",
                    "function": {
                        "name": t.name,
                        "description": t.description,
                        "parameters": t.input_schema,
                    }
                })
            })
            .collect();

        let is_local = client.base_url().contains("127.0.0.1")
            || client.base_url().contains("localhost")
            || client.base_url().contains("0.0.0.0");

        let _permit = if is_local {
            info!(
                subsystem = "agent_loop",
                prompt = %effective_prompt,
                target_url = %client.base_url(),
                "Acquiring local inference semaphore permit"
            );
            Some(LOCAL_INFERENCE_SEMAPHORE.acquire().await.ok())
        } else {
            None
        };

        let mut iterations = 0;
        let mut tools_called = Vec::new();
        let mut final_reply = String::new();
        let mut exit_reason = "max_iterations_reached";
        let mut last_error: Option<String> = None;
        let mut nudged_for_tool_use = false;
        let mut steps: Vec<AgentLoopStep> = Vec::new();

        while iterations < MAX_AGENT_ITERATIONS {
            iterations += 1;

            // ── Thermal pacing: sleep before local calls to reduce SoC heat ──
            if is_local && min_inference_gap_ms > 0 {
                tokio::time::sleep(Duration::from_millis(min_inference_gap_ms)).await;
            }

            info!(
                subsystem = "agent_loop",
                prompt = %effective_prompt,
                target_url = %client.base_url(),
                model = model,
                turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                force_tool_choice = force_tool_choice,
                prompt_truncated = prompt_truncated,
                "Executing N-turn agent loop iteration"
            );

            // Send tools schema only on turn 1; subsequent turns pass None
            let tools_for_this_turn = if iterations == 1 {
                Some(tools_json.clone())
            } else {
                None
            };

            let res = match client.chat_with_tools(model, messages.clone(), tools_for_this_turn, -1).await {
                Ok(r) => r,
                Err(e) => {
                    let err_msg = format!("{}", e);
                    error!(
                        subsystem = "agent_loop",
                        prompt = %effective_prompt,
                        target_url = %client.base_url(),
                        model = model,
                        error = %err_msg,
                        turn = iterations,
                        "LLM chat call failed in agent loop"
                    );
                    last_error = Some(err_msg);
                    exit_reason = "llm_error";
                    break;
                }
            };

            // ── Step 1: Check for structured tool calls (Ollama native) ────
            if let Some(ref tool_calls) = res.tool_calls {
                if !tool_calls.is_empty() {
                    info!(
                        subsystem = "agent_loop",
                        prompt = %effective_prompt,
                        target_url = %client.base_url(),
                        model = model,
                        turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                        tool_count = tool_calls.len(),
                        "LLM requested MCP tool execution (structured)"
                    );

                    messages.push(ChatMessage {
                        role: "assistant".into(),
                        content: res.content.clone(),
                        tool_calls: Some(tool_calls.clone()),
                    });

                    let mut step_tool_calls = Vec::new();
                    for tc in tool_calls {
                        let tool_name = &tc.function.name;
                        tools_called.push(tool_name.clone());

                        let mcp_call = McpToolCall {
                            id: None,
                            name: tool_name.clone(),
                            arguments: tc.function.arguments.clone(),
                        };

                        info!(
                            subsystem = "agent_loop",
                            prompt = %effective_prompt,
                            target_url = %client.base_url(),
                            turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                            tool_name = %tool_name,
                            arguments = %tc.function.arguments,
                            "Executing local MCP tool on RPi 5"
                        );

                        let tool_res = McpExecutor::execute(&mcp_call, process_manager, ollama_lifecycle).await;
                        let result_str = tool_res.result.to_string();
                        step_tool_calls.push(ToolCallStep {
                            tool_name: tool_name.clone(),
                            arguments: tc.function.arguments.clone(),
                            result_summary: if result_str.len() > 500 { format!("{}…", &result_str[..500]) } else { result_str },
                            success: tool_res.success,
                        });

                        messages.push(ChatMessage::tool(format!("Tool '{}' Result:\n{}", tool_name, tool_res.result)));
                    }

                    steps.push(AgentLoopStep {
                        turn: iterations,
                        step_type: "tool_execution".to_string(),
                        model_content: res.content.clone(),
                        tool_calls: step_tool_calls,
                    });
                    continue;
                }
            }

            // ── Step 2: Check for inline tool calls in content (qwen2.5 quirk) ──
            let raw_text = res.effective_text();
            let inline_calls = parse_inline_tool_calls(&raw_text);
            if !inline_calls.is_empty() {
                info!(
                    subsystem = "agent_loop",
                    prompt = %effective_prompt,
                    target_url = %client.base_url(),
                    model = model,
                    turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                    inline_count = inline_calls.len(),
                    "Detected inline tool calls in content — parsing and executing"
                );

                messages.push(ChatMessage {
                    role: "assistant".into(),
                    content: raw_text.clone(),
                    tool_calls: None,
                });

                let mut step_tool_calls = Vec::new();
                for mcp_call in &inline_calls {
                    tools_called.push(mcp_call.name.clone());

                    info!(
                        subsystem = "agent_loop",
                        prompt = %effective_prompt,
                        target_url = %client.base_url(),
                        turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                        tool_name = %mcp_call.name,
                        arguments = %mcp_call.arguments,
                        "Executing inline-parsed MCP tool on RPi 5"
                    );

                    let tool_res = McpExecutor::execute(mcp_call, process_manager, ollama_lifecycle).await;
                    let result_str = tool_res.result.to_string();
                    step_tool_calls.push(ToolCallStep {
                        tool_name: mcp_call.name.clone(),
                        arguments: mcp_call.arguments.clone(),
                        result_summary: if result_str.len() > 500 { format!("{}…", &result_str[..500]) } else { result_str },
                        success: tool_res.success,
                    });

                    messages.push(ChatMessage::tool(format!("Tool '{}' Result:\n{}", mcp_call.name, tool_res.result)));
                }

                steps.push(AgentLoopStep {
                    turn: iterations,
                    step_type: "inline_tool_execution".to_string(),
                    model_content: raw_text,
                    tool_calls: step_tool_calls,
                });
                continue;
            }

            // ── Step 3: No tool calls detected — nudge if force_tool_choice ──
            if force_tool_choice && !nudged_for_tool_use {
                nudged_for_tool_use = true;
                warn!(
                    subsystem = "agent_loop",
                    prompt = %effective_prompt,
                    target_url = %client.base_url(),
                    model = model,
                    turn = iterations,
                    "SystemQuery expected a tool call but model answered in free text — issuing corrective nudge"
                );

                steps.push(AgentLoopStep {
                    turn: iterations,
                    step_type: "nudge".to_string(),
                    model_content: raw_text.clone(),
                    tool_calls: vec![],
                });

                messages.push(ChatMessage {
                    role: "assistant".into(),
                    content: res.content.clone(),
                    tool_calls: None,
                });
                messages.push(ChatMessage::user(
                    "You did not call a tool. This request requires calling the appropriate \
                    MCP tool listed in your instructions before answering. Call it now."
                        .to_string(),
                ));
                continue;
            }

            // ── Step 4: Final answer — no tool calls, model completed reasoning ──
            final_reply = strip_tool_call_artifacts(&raw_text);
            steps.push(AgentLoopStep {
                turn: iterations,
                step_type: "final_answer".to_string(),
                model_content: raw_text,
                tool_calls: vec![],
            });
            exit_reason = "clean_completion";
            break;
        }

        if final_reply.trim().is_empty() {
            info!(
                subsystem = "agent_loop",
                prompt = %effective_prompt,
                target_url = %client.base_url(),
                "Executing direct synthesis pass for empty response"
            );
            if let Ok(Ok(direct_res)) = timeout(
                Duration::from_secs(PER_CALL_TIMEOUT_SECS),
                client.chat_with_tools(model, messages, None, -1),
            ).await {
                final_reply = strip_tool_call_artifacts(&direct_res.effective_text());
            }
        }

        if final_reply.trim().is_empty() {
            if let Some(err) = last_error {
                final_reply = format!(
                    "[AI Router Error on target '{}'] LLM call failed for model '{}': {}. Check target node status.",
                    client.base_url(),
                    model,
                    err
                );
            } else {
                final_reply = format!(
                    "Processed prompt across {} iterations. Executed tools: {:?}",
                    iterations, tools_called
                );
            }
        }

        info!(
            subsystem = "agent_loop",
            prompt = %effective_prompt,
            target_url = %client.base_url(),
            model = model,
            iterations = iterations,
            exit_reason = exit_reason,
            tools_called_count = tools_called.len(),
            prompt_truncated = prompt_truncated,
            final_reply_length = final_reply.len(),
            "Agent loop finished execution"
        );

        Ok(AgentLoopResponse {
            final_reply,
            iterations,
            tools_called,
            prompt_truncated,
            steps,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_max_agent_iterations_constant() {
        assert_eq!(MAX_AGENT_ITERATIONS, 5);
        assert_eq!(PER_CALL_TIMEOUT_SECS, 45);
    }

    #[test]
    fn test_prompt_truncation_logic() {
        let long = "a".repeat(1000);
        let limit = 100;
        let suffix_len = TRUNCATION_SUFFIX.len();
        let safe = limit - suffix_len;
        let mut expected = long[..safe].to_string();
        expected.push_str(TRUNCATION_SUFFIX);
        assert_eq!(expected.len(), limit);
        assert!(expected.ends_with(TRUNCATION_SUFFIX));
    }

    #[test]
    fn test_parse_inline_tool_calls_bare_json() {
        let content = r#"I'll check that for you.
{"name": "governor_get_metrics", "arguments": {}}
"#;
        let calls = parse_inline_tool_calls(content);
        assert_eq!(calls.len(), 1);
        assert_eq!(calls[0].name, "governor_get_metrics");
    }

    #[test]
    fn test_parse_inline_tool_calls_xml_wrapped() {
        let content = r#"Let me look.
<tool_call>{"name": "governor_query_logs", "arguments": {"limit": 50}}</tool_call>
"#;
        let calls = parse_inline_tool_calls(content);
        assert_eq!(calls.len(), 1);
        assert_eq!(calls[0].name, "governor_query_logs");
        assert_eq!(calls[0].arguments["limit"], 50);
    }

    #[test]
    fn test_parse_inline_tool_calls_no_match() {
        let content = "Hello! I'm JOSH, your AI assistant. How can I help?";
        let calls = parse_inline_tool_calls(content);
        assert!(calls.is_empty());
    }

    #[test]
    fn test_strip_bare_json_tool_call() {
        let text = r#"Let me check.
{"name": "governor_get_metrics", "arguments": {}}
Some more text."#;
        let stripped = strip_tool_call_artifacts(text);
        assert!(!stripped.contains("governor_get_metrics"));
        assert!(stripped.contains("Let me check"));
        assert!(stripped.contains("Some more text"));
    }
}
