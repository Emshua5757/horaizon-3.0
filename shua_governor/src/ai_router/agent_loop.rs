use std::sync::Arc;
use anyhow::Result;
use tracing::{info, warn};

use crate::mcp::aggregator::McpAggregator;
use crate::mcp::executor::McpExecutor;
use crate::mcp::McpToolCall;
use crate::ollama::client::{ChatMessage, OllamaClient};
use crate::registry::process_manager::ProcessManager;
use crate::ollama::OllamaLifecycle;

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
            When given a request that requires system metrics, logs, or process control, \
            invoke the appropriate MCP tools before outputting your final summary.",
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

        let mut iterations = 0;
        let max_iterations = 5;
        let mut tools_called = Vec::new();
        let mut final_reply = String::new();

        while iterations < max_iterations {
            iterations += 1;

            info!(
                subsystem = "agent_loop",
                iteration = iterations,
                model = model,
                "Executing agent loop iteration"
            );

            let res = match client.chat_with_tools(model, messages.clone(), Some(tools_json.clone()), 0).await {
                Ok(r) => r,
                Err(e) => {
                    warn!(subsystem = "agent_loop", error = %e, "LLM chat call failed in agent loop");
                    break;
                }
            };

            // Check if LLM requested tool calls
            if let Some(ref tool_calls) = res.tool_calls {
                if !tool_calls.is_empty() {
                    info!(
                        subsystem = "agent_loop",
                        iteration = iterations,
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
            final_reply = res.content;
            break;
        }

        if final_reply.is_empty() {
            final_reply = format!(
                "Processed prompt across {} iterations. Executed tools: {:?}",
                iterations, tools_called
            );
        }

        Ok(AgentLoopResponse {
            final_reply,
            iterations,
            tools_called,
        })
    }
}
