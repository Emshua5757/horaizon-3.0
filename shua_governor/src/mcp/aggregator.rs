use super::McpToolSchema;

/// System MCP Tool Registry & Aggregator
pub struct McpAggregator {
    system_tools: Vec<McpToolSchema>,
}

impl McpAggregator {
    pub fn new() -> Self {
        let system_tools = vec![
            McpToolSchema {
                name: "governor_get_metrics".into(),
                description: "Fetches real-time Pi 5 CPU %, RAM allocation, system temperature, disk usage, and process count.".into(),
                scope: "governor".into(),
                input_schema: serde_json::json!({
                    "type": "object",
                    "properties": {},
                    "required": []
                }),
                timeout_s: None,
            },
            McpToolSchema {
                name: "governor_wake_module".into(),
                description: "Sends wake signal via cgroups/process manager to resume a sleeping horAIzon microservice.".into(),
                scope: "governor".into(),
                input_schema: serde_json::json!({
                    "type": "object",
                    "properties": {
                        "module_name": {
                            "type": "string",
                            "enum": ["shua.diary", "shua.code_visualizer", "shua.resume", "shua.gym", "shua.crypto"]
                        }
                    },
                    "required": ["module_name"]
                }),
                timeout_s: None,
            },
            McpToolSchema {
                name: "governor_sleep_module".into(),
                description: "Sends sleep signal to pause a running microservice and free RAM/CPU on Raspberry Pi 5.".into(),
                scope: "governor".into(),
                input_schema: serde_json::json!({
                    "type": "object",
                    "properties": {
                        "module_name": {
                            "type": "string",
                            "enum": ["shua.diary", "shua.code_visualizer", "shua.resume", "shua.gym", "shua.crypto"]
                        }
                    },
                    "required": ["module_name"]
                }),
                timeout_s: None,
            },
            McpToolSchema {
                name: "governor_load_ollama_model".into(),
                description: "Loads a specified GGUF LLM model into Raspberry Pi 5 RAM or offloaded Laptop GPU VRAM.".into(),
                scope: "governor".into(),
                input_schema: serde_json::json!({
                    "type": "object",
                    "properties": {
                        "model_name": { "type": "string" },
                        "target_device": { "type": "string", "enum": ["pi5_ram", "laptop_gpu"] }
                    },
                    "required": ["model_name"]
                }),
                timeout_s: None,
            },
            McpToolSchema {
                name: "governor_query_logs".into(),
                description: "Queries the most recent system logs, errors, telemetry metrics, and subsystem events across all modules from governor database (activity.db). Leave subsystem empty or omitted to return all log events.".into(),
                scope: "governor".into(),
                input_schema: serde_json::json!({
                    "type": "object",
                    "properties": {
                        "subsystem": { "type": "string" },
                        "limit": { "type": "integer" }
                    },
                    "required": []
                }),
                timeout_s: None,
            },
        ];

        Self { system_tools }
    }

    /// Returns list of core system tools
    pub fn get_system_tools(&self) -> Vec<McpToolSchema> {
        self.system_tools.clone()
    }
}
