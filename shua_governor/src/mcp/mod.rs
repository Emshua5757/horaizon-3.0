pub mod aggregator;
pub mod executor;
pub mod scope_filter;

use serde::{Deserialize, Serialize};

/// Canonical MCP Tool Schema complying with _architecture/contracts/mcp/mcp_master_spec.md
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpToolSchema {
    pub name: String,
    pub description: String,
    pub scope: String,
    pub input_schema: serde_json::Value,
}

/// Invocation request for an MCP tool selected by an LLM model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpToolCall {
    pub id: Option<String>,
    pub name: String,
    pub arguments: serde_json::Value,
}

/// Output response after executing an MCP tool
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpToolResponse {
    pub tool_name: String,
    pub success: bool,
    pub result: serde_json::Value,
    pub error: Option<String>,
}
