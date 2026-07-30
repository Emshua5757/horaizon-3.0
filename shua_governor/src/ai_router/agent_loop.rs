use std::sync::Arc;
use anyhow::Result;
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
pub const PER_CALL_TIMEOUT_SECS: u64 = 45;
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
    let cleaned = RE_TOOL_RESP.replace_all(&cleaned, "");
    RE_BLANK.replace_all(cleaned.trim(), "\n\n").trim().to_string()
}

/// Returns true when the model embedded a tool call inline in `content` text
/// rather than using the structured `tool_calls` field (qwen2.5 quirk).
fn inline_tool_calls_detected(content: &str) -> bool {
    content.contains("<tool_call>") ||
    (content.contains("```json") && content.contains("\"name\"")) ||
    content.contains("{\"name\":") // raw JSON tool call fragment
}


static LOCAL_INFERENCE_SEMAPHORE: Semaphore = Semaphore::const_new(1);

pub struct AgentLoopResponse {
    pub final_reply: String,
    pub iterations: usize,
    pub tools_called: Vec<String>,
    /// Whether the user prompt was tail-truncated before sending to the LLM.
    pub prompt_truncated: bool,
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

            let chat_future = client.chat_with_tools(model, messages.clone(), tools_for_this_turn, -1);
            let res = match timeout(Duration::from_secs(PER_CALL_TIMEOUT_SECS), chat_future).await {
                Ok(Ok(r)) => r,
                Ok(Err(e)) => {
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
                Err(_) => {
                    let err_msg = format!("Timeout after {}s", PER_CALL_TIMEOUT_SECS);
                    error!(
                        subsystem = "agent_loop",
                        prompt = %effective_prompt,
                        target_url = %client.base_url(),
                        model = model,
                        turn = iterations,
                        timeout_sec = PER_CALL_TIMEOUT_SECS,
                        "Agent loop LLM chat call timed out"
                    );
                    last_error = Some(err_msg);
                    exit_reason = "timeout";
                    break;
                }
            };

            // Check if LLM requested tool calls
            if let Some(ref tool_calls) = res.tool_calls {
                if !tool_calls.is_empty() {
                    info!(
                        subsystem = "agent_loop",
                        prompt = %effective_prompt,
                        target_url = %client.base_url(),
                        model = model,
                        turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                        tool_count = tool_calls.len(),
                        "LLM requested MCP tool execution"
                    );

                    // Append assistant's tool_calls message to context
                    messages.push(ChatMessage {
                        role: "assistant".into(),
                        content: res.content.clone(),
                        tool_calls: Some(tool_calls.clone()),
                    });

                    // Execute each requested MCP tool locally on RPi 5
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

                        // Append tool execution result JSON to message context for next turn
                        messages.push(ChatMessage::tool(format!("Tool '{}' Result:\n{}", tool_name, tool_res.result)));
                    }

                    continue;
                }
            }

            // No tool calls requested. If this intent requires guaranteed tool use and
            // we haven't nudged yet, give the model one corrective retry instead of
            // silently accepting a hallucinated free-text answer.
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

                // Preserve the model's own (rejected) reply in context, then nudge.
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

            // Detect inline tool-call artifacts: some models (e.g. qwen2.5) emit
            // <tool_call>...</tool_call> XML directly in `content` instead of using
            // the structured `tool_calls` field. Treat these the same as structured
            // tool calls — nudge the model to produce a clean answer.
            let raw_text = res.effective_text();
            if inline_tool_calls_detected(&raw_text) && !nudged_for_tool_use {
                nudged_for_tool_use = true;
                warn!(
                    subsystem = "agent_loop",
                    prompt = %effective_prompt,
                    target_url = %client.base_url(),
                    model = model,
                    turn = iterations,
                    "Detected inline <tool_call> artifacts in content — nudging for clean final answer"
                );
                messages.push(ChatMessage {
                    role: "assistant".into(),
                    content: raw_text.clone(),
                    tool_calls: None,
                });
                messages.push(ChatMessage::user(
                    "Your previous response contained raw tool call markup. \
                    The tool has already been executed. Please provide a clean, \
                    human-readable summary of the results without any <tool_call> tags or JSON blocks."
                        .to_string(),
                ));
                continue;
            }

            // No tool calls requested: LLM completed reasoning and outputted final response
            final_reply = strip_tool_call_artifacts(&raw_text);
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
}
