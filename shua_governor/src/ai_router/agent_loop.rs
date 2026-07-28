use std::sync::Arc;
use anyhow::Result;
use tracing::{info, warn};
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

static LOCAL_INFERENCE_SEMAPHORE: Semaphore = Semaphore::const_new(1);

pub struct AgentLoopResponse {
    pub final_reply: String,
    pub iterations: usize,
    pub tools_called: Vec<String>,
}

pub struct McpAgentLoop;

impl McpAgentLoop {
    /// Execute an autonomous N-Turn MCP tool-calling agent loop (max 5 iterations).
    /// Dispatches LLM inference to offload_url or local RPi 5 Ollama, and executes requested
    /// MCP tools locally on RPi 5.
    pub async fn run(
        prompt: &str,
        scope: &str,
        model: &str,
        client: &OllamaClient,
        process_manager: &Arc<ProcessManager>,
        ollama_lifecycle: &Arc<OllamaLifecycle>,
    ) -> Result<AgentLoopResponse> {
        let system_prompt = format!(
            "You are JOSH, the horAIzon 3.0 AI Assistant running on Raspberry Pi 5. \
            You have access to MCP system tools (scope: '{}'). \
            When given a user query requesting system health, NVMe status, hardware metrics, or uptime, \
            YOU MUST call the `governor_get_metrics` tool FIRST to fetch real hardware metrics before outputting your response.",
            scope
        );

        let mut messages = vec![
            ChatMessage::system(system_prompt),
            ChatMessage::user(prompt),
        ];

        // Fetch MCP tools for active scope
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
            info!(subsystem = "agent_loop", "Acquiring local inference semaphore permit");
            Some(LOCAL_INFERENCE_SEMAPHORE.acquire().await.ok())
        } else {
            None
        };

        let mut iterations = 0;
        let mut tools_called = Vec::new();
        let mut final_reply = String::new();
        let mut exit_reason = "max_iterations_reached";

        while iterations < MAX_AGENT_ITERATIONS {
            iterations += 1;

            info!(
                subsystem = "agent_loop",
                turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                model = model,
                "Executing N-turn agent loop iteration"
            );

            let chat_future = client.chat_with_tools(model, messages.clone(), Some(tools_json.clone()), -1);
            let res = match timeout(Duration::from_secs(PER_CALL_TIMEOUT_SECS), chat_future).await {
                Ok(Ok(r)) => r,
                Ok(Err(e)) => {
                    warn!(subsystem = "agent_loop", error = %e, turn = iterations, "LLM chat call failed in agent loop");
                    exit_reason = "llm_error";
                    break;
                }
                Err(_) => {
                    warn!(
                        subsystem = "agent_loop",
                        turn = iterations,
                        timeout_sec = PER_CALL_TIMEOUT_SECS,
                        "Agent loop LLM chat call timed out"
                    );
                    exit_reason = "timeout";
                    break;
                }
            };

            // Check if LLM requested tool calls
            if let Some(ref tool_calls) = res.tool_calls {
                if !tool_calls.is_empty() {
                    info!(
                        subsystem = "agent_loop",
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
                            turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                            tool_name = %tool_name,
                            "Executing local MCP tool on RPi 5"
                        );

                        let tool_res = McpExecutor::execute(&mcp_call, process_manager, ollama_lifecycle).await;

                        // Append tool execution result JSON to message context for next turn
                        messages.push(ChatMessage::tool(format!("Tool '{}' Result:\n{}", tool_name, tool_res.result)));
                    }

                    continue;
                }
            }

            // No tool calls requested: LLM completed reasoning and outputted final response
            final_reply = res.effective_text();
            exit_reason = "clean_completion";
            break;
        }

        if final_reply.trim().is_empty() && (!tools_called.is_empty() || iterations == MAX_AGENT_ITERATIONS) {
            info!(subsystem = "agent_loop", "Executing final synthesis pass after tool execution");
            if let Ok(Ok(direct_res)) = timeout(
                Duration::from_secs(PER_CALL_TIMEOUT_SECS),
                client.chat_with_tools(model, messages, None, -1),
            ).await {
                final_reply = direct_res.effective_text();
            }
        }

        if final_reply.trim().is_empty() {
            final_reply = format!(
                "Processed prompt across {} iterations. Executed tools: {:?}",
                iterations, tools_called
            );
        }

        info!(
            subsystem = "agent_loop",
            iterations = iterations,
            exit_reason = exit_reason,
            tools_called_count = tools_called.len(),
            "Agent loop finished execution"
        );

        Ok(AgentLoopResponse {
            final_reply,
            iterations,
            tools_called,
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
}
