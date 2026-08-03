use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

use super::McpToolSchema;

/// System MCP Tool Registry & Aggregator
pub struct McpAggregator {
    system_tools: Vec<McpToolSchema>,
    #[allow(dead_code)] // Reserved for Phase 3 submodule tool manifest registrations (shua.diary, shua.resume)
    submodule_tools: Arc<RwLock<HashMap<String, Vec<McpToolSchema>>>>,
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
            },
        ];

        Self {
            system_tools,
            submodule_tools: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Returns list of core system tools
    pub fn get_system_tools(&self) -> Vec<McpToolSchema> {
        self.system_tools.clone()
    }

    /// Dynamically returns system tools + any submodule tools registered for the target scope
    pub async fn get_tools_for_scope(&self, scope: &str) -> Vec<McpToolSchema> {
        let mut tools = self.system_tools.clone();
        let scope_clean = scope.trim().to_lowercase();
        let guard = self.submodule_tools.read().await;

        for (module_id, sub_tools) in guard.iter() {
            let mod_clean = module_id.to_lowercase();
            if mod_clean == scope_clean
                || mod_clean.contains(&scope_clean)
                || scope_clean.contains(&mod_clean)
                || (scope_clean == "code" && mod_clean.contains("code"))
                || (scope_clean == "diary" && mod_clean.contains("diary"))
                || (scope_clean == "resume" && mod_clean.contains("resume"))
            {
                tools.extend(sub_tools.clone());
            }
        }

        tools
    }

    /// Registers a submodule's dynamic tool manifest over HBP RPC (mcp.register_manifest)
    #[allow(dead_code)]
    pub async fn register_submodule_manifest(&self, module_id: &str, tools: Vec<McpToolSchema>) {
        let mut guard = self.submodule_tools.write().await;
        guard.insert(module_id.to_string(), tools);
    }

    /// Returns all registered submodule tools
    #[allow(dead_code)]
    pub async fn get_all_submodule_tools(&self) -> Vec<McpToolSchema> {
        let guard = self.submodule_tools.read().await;
        guard.values().flatten().cloned().collect()
    }
}
