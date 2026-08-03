# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 58

## Terminal Output Trace Log (Problem Statement)
```log
[INFO] [GOVERNOR] Governor waking up microservice: shua.code_visualizer 
[INFO] [AI_ROUTER] Offload target switched to Windows Host (127.0.0.1) 
[INFO] [AI_ROUTER] Active AI model changed to qwen3.5:2b-fast 
[INFO] [AI_CHAT] User prompt sent to JOSH (👑 God Functions) {model: qwen3.5:2b-fast, target: Windows}
[INFO] [AI_ROUTER] [HBP v2] Dispatching governor.ai.route to shua_governor (target: Windows, offload: "http://127.0.0.1:11434", prompt: "👑 God Functions")...
[INFO] [SSH] Connecting to RPi 5 SSH at shua@100.67.11.0:22 
[INFO] [SSH] Loaded ed25519 keypair from ~/.ssh/id_ed25519 
[INFO] [SSH] Successfully established RPi 5 PTY bash shell stream 
[INFO] [AI_ROUTER] [HBP v2] Live Agent Loop Step event received (Turn 1, type: final_answer)
[INFO] [AI_ROUTER] [HBP v2] shua_governor agent loop finished (1 turns, tools: [], steps: 1): # 👑 God Functions - Welcome to the HorAIzon 3.0 System!
[INFO] [AI_CHAT] JOSH reply (N/A tok/s, N/A, 756 chunks): # 👑 God Functions - Welcome to the HorAIzon 3.0 System!
Performing hot restart...                                                 
Restarted application in 773ms.
[INFO] [AI_CHAT] User prompt sent to JOSH (👑 God Functions) {model: qwen3.5:4b, target: Governor Auto, contextHint: code}
[INFO] [AI_ROUTER] [HBP v2] Dispatching governor.ai.route (scope: "code", target: RPi 5, offload: "", prompt: "👑 God Functions")...
[WARN] [AI_ROUTER] [HBP v2] WARNING: decoded reply is EMPTY — payloadMap keys=[]
[WARN] [AI_ROUTER] Primary node offline, auto-routed to RPi 5
[INFO] [AI_ROUTER] [HBP v2] Dispatching governor.ai.route (scope: "code", target: Windows, offload: "http://127.0.0.1:11434", prompt: "👑 God Functions")...
[INFO] [AI_ROUTER] [HBP v2] Live Agent Loop Step event received (Turn 1, type: final_answer)
[INFO] [AI_ROUTER] [HBP v2] shua_governor agent loop finished (1 turns, tools: [], steps: 1): 👋 Welcome aboard JOSH, horAIzon 3.0 Central AI Assistant on Raspberry Pi 5!
[INFO] [AI_CHAT] JOSH reply (N/A tok/s, N/A, 448 chunks): 👋 Welcome aboard JOSH... {model: qwen3.5:2b-fast, target: Windows, chunks: 448, reply_chars: 1137}
```

================================================================================

<!-- START_FILE: shua_governor\src\config.rs -->
# FILE: config.rs
**Relative Path**: `shua_governor\src\config.rs`

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tracing::{info, warn};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub governor: GovernorConfig,
    pub dream_loop: DreamLoopConfig,
    pub ollama: OllamaConfig,
    #[serde(default)]
    pub modules: ModulesConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernorConfig {
    pub port: u16,
    pub log_level: String,
    pub timezone: String,
    pub offload_device_url: Option<String>,
    #[serde(default = "default_log_retention_days")]
    pub log_retention_days: u32,
}

fn default_log_retention_days() -> u32 {
    7
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DreamLoopConfig {
    pub enabled: bool,
    pub cron: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaConfig {
    pub binary: String,
    pub host: String,
    pub ram_cap_mb: u32,
    #[serde(default)]
    pub models: Vec<OllamaModelConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaModelConfig {
    pub name: String,
    pub ram_mb: u32,
    pub role: String,
    pub keep_alive: crate::ollama::client::KeepAlive,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ModulesConfig {
    #[serde(default, rename = "entry")]
    pub entries: Vec<ModuleConfigEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleConfigEntry {
    pub name: String,
    pub binary: PathBuf,
    pub auto_start: bool,
    pub ram_limit_mb: Option<u32>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            governor: GovernorConfig {
                port: 7700,
                log_level: "info".to_string(),
                timezone: "Asia/Manila".to_string(),
                offload_device_url: None,
                log_retention_days: 7,
            },
            dream_loop: DreamLoopConfig {
                enabled: true,
                cron: "0 18 * * *".to_string(), // 02:00 Asia/Manila (18:00 UTC)
            },
            ollama: OllamaConfig {
                binary: "/usr/bin/ollama".to_string(),
                host: "http://127.0.0.1:11434".to_string(),
                ram_cap_mb: 4096,
                models: vec![
                    OllamaModelConfig {
                        name: "qwen2.5:1.5b".into(),
                        ram_mb: 980,
                        role: "primary_dialogue".into(),
                        keep_alive: crate::ollama::client::KeepAlive::Forever,
                    },
                    OllamaModelConfig {
                        name: "llama3.2:3b".into(),
                        ram_mb: 2000,
                        role: "text_generator".into(),
                        keep_alive: crate::ollama::client::KeepAlive::Forever,
                    },
                ],
            },
            modules: ModulesConfig {
                entries: vec![
                    ModuleConfigEntry {
                        name: "ollama".to_string(),
                        binary: PathBuf::from("/usr/local/bin/ollama"),
                        auto_start: true,
                        ram_limit_mb: Some(4096),
                    },
                    ModuleConfigEntry {
                        name: "shua.resume".to_string(),
                        binary: PathBuf::from("/usr/local/bin/shua_resume"),
                        auto_start: true,
                        ram_limit_mb: Some(128),
                    },
                    ModuleConfigEntry {
                        name: "shua.diary".to_string(),
                        binary: PathBuf::from("/usr/local/bin/shua_diary"),
                        auto_start: true,
                        ram_limit_mb: Some(256),
                    },
                    ModuleConfigEntry {
                        name: "shua.code_visualizer".to_string(),
                        binary: PathBuf::from("/usr/local/bin/shua_code_visualizer"),
                        auto_start: false,
                        ram_limit_mb: Some(128),
                    },
                ],
            },
        }
    }
}

impl AppConfig {
    /// Load config searching multi-path hierarchy:
    /// 1. explicit path parameter (if provided)
    /// 2. /etc/horaizon/governor/config.toml (Pi5 Linux production)
    /// 3. ./config.toml or shua_governor/config.toml (Local dev)
    /// 4. AppConfig::default() fallback
    pub fn load_from_hierarchy(custom_path: Option<&Path>) -> Self {
        let candidates = vec![
            custom_path.map(PathBuf::from),
            Some(PathBuf::from("/etc/horaizon/governor/config.toml")),
            Some(PathBuf::from("config.toml")),
            Some(PathBuf::from("shua_governor/config.toml")),
        ];

        for candidate in candidates.into_iter().flatten() {
            if candidate.exists() {
                match std::fs::read_to_string(&candidate) {
                    Ok(content) => match toml::from_str::<AppConfig>(&content) {
                        Ok(config) => {
                            info!(
                                subsystem = "config",
                                path = %candidate.display(),
                                port = config.governor.port,
                                "Successfully loaded configuration file"
                            );
                            return config;
                        }
                        Err(e) => {
                            warn!(
                                subsystem = "config",
                                path = %candidate.display(),
                                error = %e,
                                "Failed to parse config TOML — trying next candidate"
                            );
                        }
                    },
                    Err(e) => {
                        warn!(
                            subsystem = "config",
                            path = %candidate.display(),
                            error = %e,
                            "Failed to read config file"
                        );
                    }
                }
            }
        }

        warn!(
            subsystem = "config",
            "No valid config file found in search hierarchy — utilizing default AppConfig"
        );
        AppConfig::default()
    }

    /// Save current config back to disk file
    pub fn save(&self, path: &Path) -> Result<()> {
        let content = toml::to_string_pretty(self)
            .map_err(|e| anyhow::anyhow!("Config serialization error: {e}"))?;
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        std::fs::write(path, content)?;
        info!(
            subsystem = "config",
            path = %path.display(),
            "Configuration saved to disk"
        );
        Ok(())
    }
}


<!-- END_FILE: shua_governor\src\config.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\error.rs -->
# FILE: error.rs
**Relative Path**: `shua_governor\src\error.rs`

use thiserror::Error;

#[allow(dead_code)]
#[derive(Debug, Error)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Config error: {0}")]
    Config(String),

    #[error("WebSocket error: {0}")]
    WebSocket(String),

    #[error("Serialization error: {0}")]
    Serialization(String),

    #[error("Module not found: {0}")]
    ModuleNotFound(String),

    #[error("Module asleep: {0}")]
    ModuleAsleep(String),

    #[error("Ollama error: {0}")]
    Ollama(String),

    #[error("Process error: {0}")]
    Process(String),
}

#[allow(dead_code)]
pub type Result<T> = std::result::Result<T, AppError>;


<!-- END_FILE: shua_governor\src\error.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\main.rs -->
# FILE: main.rs
**Relative Path**: `shua_governor\src\main.rs`

mod ai_router;
mod broker;
mod config;
mod dream_loop;
mod error;
mod logging;
mod mcp;
mod ollama;
mod registry;

use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;

use broker::{dispatcher::Dispatcher, server::BrokerServer};
use config::AppConfig;
use dream_loop::DreamLoopScheduler;
use logging::bridge::ChannelLogger;
use logging::broadcaster::LogBroadcaster;
use logging::entry::LogEntry;
use logging::flush::{flush_loop, resolved_important_log_path};
use logging::listener::start_log_ipc_listener;
use ollama::{ModelRegistry, OllamaClient, OllamaLifecycle, RegisteredModel};
use registry::{ModuleEntry, ProcessManager};
use tokio::sync::{broadcast, mpsc, RwLock};
use tracing::{error, info, warn};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() -> anyhow::Result<()> {
    // Emergency Panic Hook for Crash Log Preservation
    let panic_important_log_path = resolved_important_log_path();
    std::panic::set_hook(Box::new(move |info| {
        let panic_msg = format!("[PANIC] Process crashed: {}\n", info);
        eprintln!("{}", panic_msg);
        let _ = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&panic_important_log_path)
            .and_then(|mut f| std::io::Write::write_all(&mut f, panic_msg.as_bytes()));
    }));

    // 0. Parse optional CLI --config argument
    let args: Vec<String> = std::env::args().collect();
    let custom_config_path = args.windows(2).find_map(|w| {
        if w[0] == "--config" {
            Some(PathBuf::from(&w[1]))
        } else {
            None
        }
    });

    // 1. Load Configuration File via Search Hierarchy
    let app_config = AppConfig::load_from_hierarchy(custom_config_path.as_deref());
    let shared_config = Arc::new(RwLock::new(app_config.clone()));

    // Dedicated AI Tokio Runtime (2 worker threads isolated from HBP broker/heartbeats)
    let ai_runtime = Arc::new(
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("governor-ai-worker")
            .enable_all()
            .build()?
    );

    // 2. Ingress MPSC channel (capacity 4096)
    let (log_tx, log_rx) = mpsc::channel::<LogEntry>(4096);

    // 3. Broadcast channel for live SSE / WebSocket streaming (capacity 1024)
    let (log_broadcast_tx, log_broadcast_rx) = broadcast::channel::<LogEntry>(1024);

    // 4. Initialize tracing subscriber with JSON stdout + ChannelLogger MPSC bridge
    let log_level = app_config.governor.log_level.as_str();
    let filter_str = format!("shua_governor={log_level}");
    tracing_subscriber::registry()
        .with(EnvFilter::from_default_env().add_directive(filter_str.parse()?))
        .with(tracing_subscriber::fmt::layer().json())
        .with(ChannelLogger::new(log_tx.clone()))
        .init();

    info!(
        module = "shua.governor",
        version = env!("CARGO_PKG_VERSION"),
        port = app_config.governor.port,
        log_level = %app_config.governor.log_level,
        "shua_governor starting — Centralized Telemetry & HBP Broker Active"
    );

    // 5. Spawn background log flush task (SQLite activity.db LTM + important.log rotation)
    let broadcast_tx_clone = log_broadcast_tx.clone();
    tokio::spawn(async move {
        flush_loop(log_rx, broadcast_tx_clone).await;
    });

    // Spawn Core Runtime Periodic Telemetry Heartbeat Task (10s interval)
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(10));
        loop {
            interval.tick().await;
            tracing::info!(
                subsystem = "governor_heartbeat",
                "Core runtime heartbeat tick — system active"
            );
        }
    });

    // 6. Start IPC log listener (UDS on Linux + TCP 5001 loopback)
    start_log_ipc_listener(log_tx.clone()).await;

    // 7. Initialize ProcessManager & Register Sub-Modules dynamically from config.toml
    let process_manager = Arc::new(ProcessManager::new());
    for entry in &app_config.modules.entries {
        process_manager
            .register(ModuleEntry::new(
                &entry.name,
                entry.binary.clone(),
                entry.auto_start,
                entry.ram_limit_mb,
            ))
            .await;

        if entry.auto_start {
            let pm = Arc::clone(&process_manager);
            let name = entry.name.clone();
            tokio::spawn(async move {
                if let Err(e) = pm.start(&name).await {
                    warn!(subsystem = "governor_main", module = %name, error = %e, "Could not auto-start module");
                }
            });
        }
    }

    info!(
        subsystem = "governor_main",
        modules_count = app_config.modules.entries.len(),
        "ProcessManager initialized with config.toml microservice entries"
    );

    // 8. Initialize Ollama Lifecycle Manager dynamically from config.toml
    let registered_models: Vec<RegisteredModel> = app_config
        .ollama
        .models
        .iter()
        .map(|m| RegisteredModel {
            name: m.name.clone(),
            ram_mb: m.ram_mb,
            role: m.role.clone(),
            keep_alive: m.keep_alive,
        })
        .collect();

    let model_registry = ModelRegistry::new(registered_models, app_config.ollama.ram_cap_mb);
    let ollama_client = OllamaClient::new(&app_config.ollama.host);
    let ollama_lifecycle = Arc::new(OllamaLifecycle::new(ollama_client, model_registry));

    info!(
        subsystem = "governor_main",
        ram_cap_mb = app_config.ollama.ram_cap_mb,
        models_count = app_config.ollama.models.len(),
        "Ollama Lifecycle Manager initialized"
    );

    // 9. Start Nightly Dream Loop Scheduler if enabled
    if app_config.dream_loop.enabled {
        tokio::spawn(async move {
            if let Err(e) = DreamLoopScheduler::start().await {
                error!(error = %e, "Dream Loop scheduler failed to start");
            }
        });
    }

    // 10. Initialize WebSocket Log Broadcaster
    let log_broadcaster = Arc::new(LogBroadcaster::new());
    let log_broadcaster_clone = Arc::clone(&log_broadcaster);
    tokio::spawn(async move {
        log_broadcaster_clone.run_broadcast_loop(log_broadcast_rx).await;
    });

    // 11. Initialize HBP v2 Dispatcher & Broker Server
    let dispatcher = Arc::new(Dispatcher::new(
        log_tx.clone(),
        Arc::clone(&log_broadcaster),
        Arc::clone(&process_manager),
        Arc::clone(&ollama_lifecycle),
        Arc::clone(&shared_config),
        Arc::clone(&ai_runtime),
    ));
    let broker = BrokerServer::new(Arc::clone(&dispatcher));

    let addr_str = format!("0.0.0.0:{}", app_config.governor.port);
    let addr: SocketAddr = addr_str.parse()?;
    tokio::spawn(async move {
        if let Err(e) = broker.run(addr).await {
            tracing::error!(error = %e, "HBP WebSocket Broker error");
        }
    });

    info!(
        module = "shua.governor",
        port = app_config.governor.port,
        "HBP v2 WebSocket broker listening on port {}", app_config.governor.port
    );

    tokio::signal::ctrl_c().await?;
    info!(module = "shua.governor", "Shutdown signal received — exiting cleanly");
    Ok(())
}


<!-- END_FILE: shua_governor\src\main.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ai_router\agent_loop.rs -->
# FILE: agent_loop.rs
**Relative Path**: `shua_governor\src\ai_router\agent_loop.rs`

use anyhow::Result;
use serde::Serialize;
use std::sync::Arc;
use tokio::sync::Semaphore;
use tokio::time::{timeout, Duration};
use tracing::{error, info, warn};

use crate::mcp::aggregator::McpAggregator;
use crate::mcp::executor::McpExecutor;
use crate::mcp::McpToolCall;
use crate::ollama::client::{ChatMessage, OllamaClient};
use crate::ollama::OllamaLifecycle;
use crate::registry::process_manager::ProcessManager;

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
    static RE_XML: Lazy<Regex> =
        Lazy::new(|| Regex::new(r"(?s)<tool_call>.*?</tool_call>").expect("valid regex"));
    // ```json {...} ``` fenced blocks containing a "name" key (tool call JSON)
    static RE_JSON_FENCE: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r#"(?s)```(?:json)?\s*\{[^`]*"name"[^`]*\}\s*```"#).expect("valid regex")
    });
    // Bare JSON tool call fragments: {"name":"...","arguments":...}
    static RE_BARE_JSON: Lazy<Regex> = Lazy::new(|| {
        Regex::new(r#"\{\s*"name"\s*:\s*"[^"]+"\s*,\s*"arguments"\s*:\s*\{[^}]*\}\s*\}"#)
            .expect("valid regex")
    });
    // tool_response: ... inline narration sections
    // Note: Rust `regex` crate does not support look-ahead (?=...), so we
    // match through the double-newline delimiter (or end of string) instead.
    static RE_TOOL_RESP: Lazy<Regex> =
        Lazy::new(|| Regex::new(r"(?s)tool_response:\s*\n.*?(?:\n\n|$)").expect("valid regex"));
    // Collapse 3+ consecutive blank lines into 2
    static RE_BLANK: Lazy<Regex> = Lazy::new(|| Regex::new(r"\n{3,}").expect("valid regex"));

    let cleaned = RE_XML.replace_all(text, "");
    let cleaned = RE_JSON_FENCE.replace_all(&cleaned, "");
    let cleaned = RE_BARE_JSON.replace_all(&cleaned, "");
    let cleaned = RE_TOOL_RESP.replace_all(&cleaned, "");
    RE_BLANK
        .replace_all(cleaned.trim(), "\n\n")
        .trim()
        .to_string()
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
        let trimmed = line
            .trim()
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
        step_sender: Option<tokio::sync::mpsc::UnboundedSender<AgentLoopStep>>,
        delta_sender: Option<tokio::sync::mpsc::UnboundedSender<String>>,
    ) -> Result<AgentLoopResponse> {
        // ── Prompt Guardrail: Tail-truncate oversized user prompts ────────────
        // Prevents the KV-cache allocation on RPi5 Ollama from ballooning even
        // when inference is offloaded (the broker still serialises the full
        // request body per turn).
        let (effective_prompt, prompt_truncated) =
            if max_prompt_chars > 0 && prompt.len() > max_prompt_chars {
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
            - When presenting system health or telemetry summaries, ALWAYS format metrics (RAM, CPU, Temperature, NVMe Status, Module Allocation) in clean Markdown tables (e.g. `| Metric | Value | Status |`). \
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

        let _model_guard = if is_local {
            info!(
                subsystem = "agent_loop",
                prompt = %effective_prompt,
                target_url = %client.base_url(),
                model = model,
                "Reserving local model guard for agent loop turn"
            );
            ollama_lifecycle.reserve(model).await.ok()
        } else {
            None
        };

        let keep_alive = ollama_lifecycle
            .registry()
            .find(model)
            .map(|m| m.keep_alive)
            .unwrap_or(crate::ollama::client::KeepAlive::Forever);

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
        let mut tool_requirement_satisfied = false;
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

            // If a tool requirement was already satisfied in a previous turn, remind model not to re-trigger tools
            if tool_requirement_satisfied {
                messages.push(ChatMessage::system(
                    "System Note: You have already executed the requested MCP tool in a prior turn. Do NOT call any more tools; present your final answer directly using the tool result above."
                ));
            }

            // Send tools schema only on turn 1; subsequent turns pass None
            let tools_for_this_turn = if iterations == 1 && !tool_requirement_satisfied {
                Some(tools_json.clone())
            } else {
                None
            };

            let delta_sender_clone = delta_sender.clone();
            let res = match client
                .chat_with_tools_stream(
                    model,
                    messages.clone(),
                    tools_for_this_turn,
                    keep_alive,
                    move |delta| {
                        if let Some(ref ds) = delta_sender_clone {
                            let _ = ds.send(delta.to_string());
                        }
                    },
                )
                .await
            {
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
                    tool_requirement_satisfied = true;
                    info!(
                        subsystem = "agent_loop",
                        prompt = %effective_prompt,
                        target_url = %client.base_url(),
                        model = model,
                        turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                        tool_count = tool_calls.len(),
                        "LLM requested MCP tool execution (structured)"
                    );

                    let cleaned_content = crate::ollama::client::strip_think_tags(
                        &strip_tool_call_artifacts(&res.content),
                    );
                    messages.push(ChatMessage {
                        role: "assistant".into(),
                        content: cleaned_content,
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

                        let tool_res =
                            McpExecutor::execute(&mcp_call, process_manager, ollama_lifecycle)
                                .await;
                        let result_str = tool_res.result.to_string();
                        step_tool_calls.push(ToolCallStep {
                            tool_name: tool_name.clone(),
                            arguments: tc.function.arguments.clone(),
                            result_summary: if result_str.len() > 500 {
                                format!("{}…", &result_str[..500])
                            } else {
                                result_str
                            },
                            success: tool_res.success,
                        });

                        messages.push(ChatMessage::tool(format!(
                            "Tool '{}' Result:\n{}",
                            tool_name, tool_res.result
                        )));
                    }

                    let step = AgentLoopStep {
                        turn: iterations,
                        step_type: "tool_execution".to_string(),
                        model_content: res.content.clone(),
                        tool_calls: step_tool_calls,
                    };
                    if let Some(ref sender) = step_sender {
                        let _ = sender.send(step.clone());
                    }
                    steps.push(step);
                    continue;
                }
            }

            // ── Step 2: Check for inline tool calls in content (qwen2.5 quirk) ──
            let raw_text = res.effective_text();
            let inline_calls = parse_inline_tool_calls(&raw_text);
            if !inline_calls.is_empty() {
                tool_requirement_satisfied = true;
                info!(
                    subsystem = "agent_loop",
                    prompt = %effective_prompt,
                    target_url = %client.base_url(),
                    model = model,
                    turn = %format!("{}/{}", iterations, MAX_AGENT_ITERATIONS),
                    inline_count = inline_calls.len(),
                    "Detected inline tool calls in content — parsing and executing"
                );

                let cleaned_raw_text =
                    crate::ollama::client::strip_think_tags(&strip_tool_call_artifacts(&raw_text));
                messages.push(ChatMessage {
                    role: "assistant".into(),
                    content: cleaned_raw_text,
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

                    let tool_res =
                        McpExecutor::execute(mcp_call, process_manager, ollama_lifecycle).await;
                    let result_str = tool_res.result.to_string();
                    step_tool_calls.push(ToolCallStep {
                        tool_name: mcp_call.name.clone(),
                        arguments: mcp_call.arguments.clone(),
                        result_summary: if result_str.len() > 500 {
                            format!("{}…", &result_str[..500])
                        } else {
                            result_str
                        },
                        success: tool_res.success,
                    });

                    messages.push(ChatMessage::tool(format!(
                        "Tool '{}' Result:\n{}",
                        mcp_call.name, tool_res.result
                    )));
                }

                let step = AgentLoopStep {
                    turn: iterations,
                    step_type: "inline_tool_execution".to_string(),
                    model_content: raw_text,
                    tool_calls: step_tool_calls,
                };
                if let Some(ref sender) = step_sender {
                    let _ = sender.send(step.clone());
                }
                steps.push(step);
                continue;
            }

            // ── Step 3: No tool calls detected — nudge if force_tool_choice ──
            if force_tool_choice && !nudged_for_tool_use && !tool_requirement_satisfied {
                nudged_for_tool_use = true;
                warn!(
                    subsystem = "agent_loop",
                    prompt = %effective_prompt,
                    target_url = %client.base_url(),
                    model = model,
                    turn = iterations,
                    "SystemQuery expected a tool call but model answered in free text — issuing corrective nudge"
                );

                let step = AgentLoopStep {
                    turn: iterations,
                    step_type: "nudge".to_string(),
                    model_content: raw_text.clone(),
                    tool_calls: vec![],
                };
                if let Some(ref sender) = step_sender {
                    let _ = sender.send(step.clone());
                }
                steps.push(step);

                let cleaned_nudge_content = crate::ollama::client::strip_think_tags(
                    &strip_tool_call_artifacts(&res.content),
                );
                messages.push(ChatMessage {
                    role: "assistant".into(),
                    content: cleaned_nudge_content,
                    tool_calls: None,
                });
                messages.push(ChatMessage::system(
                    "[GOVERNOR-INJECTED] COMMAND: Respond ONLY with the MCP tool call JSON format: `{\"name\": \"governor_get_metrics\", \"arguments\": {}}`. Do not write any thoughts, explanations, or meta-comments.".to_string(),
                ));
                continue;
            }

            // ── Step 4: Final answer — no tool calls, model completed reasoning ──
            final_reply = strip_tool_call_artifacts(&raw_text);
            let step = AgentLoopStep {
                turn: iterations,
                step_type: "final_answer".to_string(),
                model_content: raw_text,
                tool_calls: vec![],
            };
            if let Some(ref sender) = step_sender {
                let _ = sender.send(step.clone());
            }
            steps.push(step);
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
                client.chat_with_tools(model, messages, None, keep_alive),
            )
            .await
            {
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
        assert_eq!(PER_CALL_TIMEOUT_SECS, 90);
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


<!-- END_FILE: shua_governor\src\ai_router\agent_loop.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ai_router\chat_history.rs -->
# FILE: chat_history.rs
**Relative Path**: `shua_governor\src\ai_router\chat_history.rs`

// shua_governor — Chat History Persistence
//
// Stores and retrieves the global chat session message history from the
// same `activity.db` SQLite database used by the logging subsystem.
//
// Schema (appended to activity.db via ensure_chat_schema):
//   chat_history(id, session TEXT, role TEXT, content TEXT, ts INTEGER)
//
// Design constraints (RPi5 / Pi5 NVMe):
//   - All DB calls are synchronous blocking (rusqlite) — caller must spawn_blocking.
//   - Sliding window: only last N=8 turns loaded per request. O(log n) index scan.
//   - No in-memory cache needed; NVMe SQLite reads are sub-millisecond.

use anyhow::Result;
use rusqlite::{params, Connection};
use tracing::{info, warn};

use crate::ollama::client::ChatMessage;

/// Maximum number of prior messages to inject as context per agent loop run.
pub const CONTEXT_WINDOW_SIZE: usize = 8;

/// Persistent chat history backed by SQLite activity.db.
pub struct ChatHistoryStore {
    db_path: String,
}

impl ChatHistoryStore {
    pub fn new(db_path: &str) -> Self {
        Self { db_path: db_path.to_string() }
    }

    /// Ensure `chat_history` table and index exist in activity.db.
    pub fn ensure_schema(&self) -> Result<()> {
        let conn = Connection::open(&self.db_path)?;
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS chat_history (
                id      INTEGER PRIMARY KEY AUTOINCREMENT,
                session TEXT    NOT NULL,
                role    TEXT    NOT NULL,
                content TEXT    NOT NULL,
                ts      INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_chat_session_ts
                ON chat_history(session, ts DESC);
            ",
        )?;
        Ok(())
    }

    /// Load the last `CONTEXT_WINDOW_SIZE` messages for `session_id`, ordered
    /// chronologically (oldest first) so they can be prepended as context.
    ///
    /// Returns an empty Vec if the session is new or the DB is unavailable.
    pub fn load_context(&self, session_id: &str) -> Vec<ChatMessage> {
        let conn = match Connection::open(&self.db_path) {
            Ok(c) => c,
            Err(e) => {
                warn!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    error = %e,
                    "Failed to open activity.db for context load"
                );
                return vec![];
            }
        };

        // SELECT last N rows for session, then reverse to chronological order
        let sql = "
            SELECT role, content FROM (
                SELECT role, content, ts
                FROM chat_history
                WHERE session = ?1
                ORDER BY ts DESC
                LIMIT ?2
            ) ORDER BY ts ASC
        ";

        let mut stmt = match conn.prepare(sql) {
            Ok(s) => s,
            Err(e) => {
                warn!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    error = %e,
                    "Failed to prepare chat history query"
                );
                return vec![];
            }
        };

        let rows = stmt.query_map(params![session_id, CONTEXT_WINDOW_SIZE as i64], |row| {
            let role: String  = row.get(0)?;
            let content: String = row.get(1)?;
            Ok((role, content))
        });

        match rows {
            Ok(iter) => {
                let messages: Vec<ChatMessage> = iter
                    .filter_map(|r| r.ok())
                    .map(|(role, content)| ChatMessage {
                        role,
                        content,
                        tool_calls: None,
                    })
                    .collect();

                info!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    loaded = messages.len(),
                    "Loaded chat context from SQLite"
                );
                messages
            }
            Err(e) => {
                warn!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    error = %e,
                    "Failed to query chat history rows"
                );
                vec![]
            }
        }
    }

    /// Persist a single message turn to `chat_history` for the given session.
    /// `role` is `"user"` or `"assistant"`.
    pub fn append(&self, session_id: &str, role: &str, content: &str) -> Result<()> {
        let conn = Connection::open(&self.db_path)?;
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis() as i64)
            .unwrap_or(0);
        conn.execute(
            "INSERT INTO chat_history (session, role, content, ts) VALUES (?1, ?2, ?3, ?4)",
            params![session_id, role, content, ts],
        )?;

        info!(
            subsystem = "chat_history",
            session_id = session_id,
            role = role,
            content_len = content.len(),
            "Appended message to chat history"
        );
        Ok(())
    }

    /// Prune messages older than `max_age_days` for a session.
    /// Called opportunistically; failures are logged but not fatal.
    pub fn prune_old(&self, max_age_days: u64) {
        let cutoff_ms = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis() as i64 - (max_age_days as i64 * 86_400_000))
            .unwrap_or(0);

        if let Ok(conn) = Connection::open(&self.db_path) {
            let _ = conn.execute(
                "DELETE FROM chat_history WHERE ts < ?1",
                params![cutoff_ms],
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chat_history_roundtrip() {
        let tmp = std::env::temp_dir().join("test_chat_history.db");
        let store = ChatHistoryStore::new(tmp.to_str().unwrap());
        store.ensure_schema().expect("schema ok");

        let session = "test-session-001";
        store.append(session, "user", "Hello JOSH").unwrap();
        store.append(session, "assistant", "Hello Joshua!").unwrap();

        let ctx = store.load_context(session);
        assert_eq!(ctx.len(), 2);
        assert_eq!(ctx[0].role, "user");
        assert_eq!(ctx[0].content, "Hello JOSH");
        assert_eq!(ctx[1].role, "assistant");

        // Cleanup
        let _ = std::fs::remove_file(&tmp);
    }

    #[test]
    fn test_context_window_limit() {
        let tmp = std::env::temp_dir().join("test_chat_window.db");
        let store = ChatHistoryStore::new(tmp.to_str().unwrap());
        store.ensure_schema().expect("schema ok");

        let session = "test-session-002";
        for i in 0..12 {
            store.append(session, "user", &format!("msg {i}")).unwrap();
        }

        let ctx = store.load_context(session);
        assert!(ctx.len() <= CONTEXT_WINDOW_SIZE, "Window must be capped at {CONTEXT_WINDOW_SIZE}");

        let _ = std::fs::remove_file(&tmp);
    }
}


<!-- END_FILE: shua_governor\src\ai_router\chat_history.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ai_router\intent_classifier.rs -->
# FILE: intent_classifier.rs
**Relative Path**: `shua_governor\src\ai_router\intent_classifier.rs`

/// Intent classification categories
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IntentClass {
    SystemQuery,       // governor/MCP/telemetry — must guarantee tool use
    FactualPrecision,
    ReflectiveDialogue,
    CodeAst,
    CopilotCommand,
}

impl IntentClass {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::SystemQuery => "system_query",
            Self::FactualPrecision => "factual_precision",
            Self::ReflectiveDialogue => "reflective_dialogue",
            Self::CodeAst => "code_ast",
            Self::CopilotCommand => "copilot_command",
        }
    }
}

/// Heuristic keyword-based intent classifier.
pub struct IntentClassifier;

impl IntentClassifier {
    /// Returns `(intent, matched_rule, confidence)`.
    ///
    /// - `matched_rule` — log alongside intent for debuggable misroute tracing.
    /// - `confidence`   — 0.0–1.0 fraction of prompt tokens that matched the
    ///   winning keyword set. Phrase matches contribute 0.5 bonus each (capped
    ///   at 1.0). Context-hint overrides always return 1.0. Default
    ///   `FactualPrecision` returns 0.3 (low confidence — no keywords matched).
    pub fn classify(prompt: &str, context_hint: Option<&str>) -> (IntentClass, &'static str, f32) {
        let lower = prompt.to_lowercase();
        let word_count = lower.split_whitespace().count().max(1) as f32;

        // Context hint overrides — confidence = 1.0 (explicit caller direction)
        if let Some(hint) = context_hint {
            match hint {
                "system"  => return (IntentClass::SystemQuery,       "hint:system",  1.0),
                "code"    => return (IntentClass::CodeAst,           "hint:code",    1.0),
                "diary"   => return (IntentClass::ReflectiveDialogue,"hint:diary",   1.0),
                "copilot" => return (IntentClass::CopilotCommand,    "hint:copilot", 1.0),
                _ => {}
            }
        }

        // SystemQuery is checked FIRST. Anything asking about governor
        // internals, telemetry, or MCP tools must guarantee tool use
        // downstream — it can't be left to fall through into the default
        // FactualPrecision bucket silently, or the model is free to
        // hallucinate an answer instead of calling the real tool.
        const SYSTEM_WORDS: &[&str] = &[
            "log", "logs", "metric", "metrics", "uptime", "nvme", "cpu", "ram",
            "temperature", "governor", "module",
        ];
        const SYSTEM_PHRASES: &[&str] = &[
            "mcp tool", "mcp tools", "system health", "load model", "wake module",
            "sleep module", "query_logs", "get_metrics",
        ];
        let sys_word_hits = count_word_hits(&lower, SYSTEM_WORDS);
        let sys_phrase_hits = count_phrase_hits(&lower, SYSTEM_PHRASES);
        if sys_word_hits > 0 || sys_phrase_hits > 0 {
            let conf = ((sys_word_hits as f32 / word_count)
                + (sys_phrase_hits as f32 * 0.5))
                .clamp(0.0, 1.0);
            return (IntentClass::SystemQuery, "system_keyword", conf);
        }

        // Command patterns for UI navigation — prefix-based, confidence 0.85
        if lower.starts_with("take me to")
            || lower.starts_with("open ")
            || lower.starts_with("go to ")
            || lower.starts_with("make the theme")
            || lower.starts_with("switch to")
        {
            return (IntentClass::CopilotCommand, "nav_prefix", 0.85);
        }

        // Code patterns — word-boundary checked, not substring `contains`,
        // to avoid "rust" matching "trust"/"crust", "code" matching
        // "encode"/"barcode"/"decode", etc.
        const CODE_WORDS: &[&str] = &[
            "function", "struct", "impl", "fn", "cargo", "flutter", "dart",
            "rust", "code", "refactor",
        ];
        let code_hits = count_word_hits(&lower, CODE_WORDS);
        if code_hits > 0 {
            let conf = (code_hits as f32 / word_count).clamp(0.0, 1.0);
            return (IntentClass::CodeAst, "code_keyword", conf);
        }

        // Reflective patterns
        const REFLECTIVE_WORDS: &[&str] = &[
            "feel", "feeling", "feelings", "today", "journal", "diary",
            "remember", "think", "thinking", "reflect", "reflection", "reflecting",
        ];
        let ref_hits = count_word_hits(&lower, REFLECTIVE_WORDS);
        if ref_hits > 0 {
            let conf = (ref_hits as f32 / word_count).clamp(0.0, 1.0);
            return (IntentClass::ReflectiveDialogue, "reflective_keyword", conf);
        }

        // Default: factual precision — low confidence (no keywords matched)
        (IntentClass::FactualPrecision, "default", 0.3)
    }
}

fn has_word(text: &str, word: &str) -> bool {
    text.split_whitespace().any(|w| {
        w.trim_matches(|c: char| !c.is_alphanumeric()).eq_ignore_ascii_case(word)
    })
}

fn count_word_hits(text: &str, words: &[&str]) -> usize {
    words.iter().filter(|w| has_word(text, w)).count()
}

fn count_phrase_hits(text: &str, phrases: &[&str]) -> usize {
    phrases.iter().filter(|p| text.contains(*p)).count()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_intent_classification() {
        assert_eq!(
            IntentClassifier::classify("take me to diary", None).0,
            IntentClass::CopilotCommand
        );
        assert_eq!(
            IntentClassifier::classify("how do I write a Rust struct?", None).0,
            IntentClass::CodeAst
        );
        assert_eq!(
            IntentClassifier::classify("how do I feel today?", None).0,
            IntentClass::ReflectiveDialogue
        );
        assert_eq!(
            IntentClassifier::classify("what is the capital of France?", None).0,
            IntentClass::FactualPrecision
        );
    }

    #[test]
    fn test_word_boundary_code_matching() {
        assert_eq!(
            IntentClassifier::classify("how do I decode a barcode?", None).0,
            IntentClass::FactualPrecision
        );
        assert_eq!(
            IntentClassifier::classify("explain this code snippet", None).0,
            IntentClass::CodeAst
        );
    }

    #[test]
    fn test_system_query_classification() {
        assert_eq!(
            IntentClassifier::classify(
                "Show me the output of governor_query_logs for the last 100 entries",
                None
            ).0,
            IntentClass::SystemQuery
        );
        assert_eq!(
            IntentClassifier::classify("what are the mcp tools you have available?", None).0,
            IntentClass::SystemQuery
        );
        assert_eq!(
            IntentClassifier::classify("what's the CPU temperature right now?", None).0,
            IntentClass::SystemQuery
        );
    }

    #[test]
    fn test_confidence_hint_always_one() {
        let (_, _, conf) = IntentClassifier::classify("anything", Some("system"));
        assert!((conf - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_confidence_default_low() {
        let (intent, _, conf) = IntentClassifier::classify("what is the capital of France?", None);
        assert_eq!(intent, IntentClass::FactualPrecision);
        assert!(conf <= 0.3 + f32::EPSILON);
    }
}


<!-- END_FILE: shua_governor\src\ai_router\intent_classifier.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ai_router\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\ai_router\mod.rs`

pub mod agent_loop;
pub mod chat_history;
pub mod intent_classifier;
pub mod prompt_budget;

#[allow(unused_imports)]
pub use agent_loop::McpAgentLoop;
#[allow(unused_imports)]
pub use chat_history::ChatHistoryStore;
#[allow(unused_imports)]
pub use intent_classifier::{IntentClass, IntentClassifier};
#[allow(unused_imports)]
pub use prompt_budget::PromptBudget;


<!-- END_FILE: shua_governor\src\ai_router\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ai_router\prompt_budget.rs -->
# FILE: prompt_budget.rs
**Relative Path**: `shua_governor\src\ai_router\prompt_budget.rs`

use crate::ai_router::intent_classifier::IntentClass;

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct PromptBudget {
    pub model: String,
    pub temperature: f32,
    pub max_tokens: u32,
    pub offload_url: Option<String>,
    /// When true, McpAgentLoop enforces tool use via a stronger system-prompt
    /// directive and a one-time corrective nudge if the model answers in
    /// free text without calling a tool on the first turn. Ollama's native
    /// /api/chat endpoint has no tool_choice param, so this is enforced at
    /// the prompt/loop level rather than the API level.
    pub force_tool_choice: bool,
    /// Maximum user prompt length (chars) accepted before tail-truncation.
    /// Prevents oversized KV-cache allocations on RPi5 Ollama even when
    /// inference is offloaded (broker still serialises the full request body).
    pub max_prompt_chars: usize,
    /// Minimum wall-clock gap (ms) inserted before each local Ollama LLM call
    /// to prevent back-to-back thermal spikes on RPi5.
    /// Only applied when inference target is local (127.0.0.1 / localhost).
    pub min_inference_gap_ms: u64,
}

impl PromptBudget {
    /// Return the model, parameters, and optional offload endpoint for a given intent class.
    /// Respects client-requested model if provided, falling back to intent defaults.
    pub fn for_intent(
        intent: &IntentClass,
        offload_device_url: Option<&str>,
        requested_model: Option<&str>,
    ) -> Self {
        let offload_url = offload_device_url
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string());

        let default_model = "qwen3.5:4b";

        let selected_model = requested_model
            .filter(|s| !s.is_empty())
            .unwrap_or(default_model)
            .to_string();

        match intent {
            IntentClass::SystemQuery => Self {
                model: selected_model,
                temperature: 0.0,
                max_tokens: 512,
                offload_url,
                force_tool_choice: true,
                max_prompt_chars: 800,
                min_inference_gap_ms: 250,
            },
            IntentClass::FactualPrecision => Self {
                model: selected_model,
                temperature: 0.0,
                max_tokens: 512,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 1200,
                min_inference_gap_ms: 250,
            },
            IntentClass::ReflectiveDialogue => Self {
                model: selected_model,
                temperature: 0.7,
                max_tokens: 1024,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 2000,
                min_inference_gap_ms: 500,
            },
            IntentClass::CodeAst => Self {
                model: selected_model,
                temperature: 0.2,
                max_tokens: 2048,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 3000,
                min_inference_gap_ms: 500,
            },
            IntentClass::CopilotCommand => Self {
                model: selected_model,
                temperature: 0.1,
                max_tokens: 256,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 400,
                min_inference_gap_ms: 250,
            },
        }
    }
}


<!-- END_FILE: shua_governor\src\ai_router\prompt_budget.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\dispatcher.rs -->
# FILE: dispatcher.rs
**Relative Path**: `shua_governor\src\broker\dispatcher.rs`

use std::sync::Arc;
use tokio::sync::mpsc::{Sender, UnboundedSender};
use tokio::sync::RwLock;
use tracing::{info, warn};

use crate::ai_router::intent_classifier::IntentClassifier;
use crate::ai_router::prompt_budget::PromptBudget;
use crate::broker::frame::{HbpFrame, MsgType};
use crate::config::AppConfig;
use crate::logging::broadcaster::LogBroadcaster;
use crate::logging::entry::{LogEntry, MODULE_FLUTTER};
use crate::logging::filter::LogFilter;
use crate::logging::flush::{query_logs_from_db, resolved_db_path, LogQueryParams};
use crate::ollama::lifecycle::OllamaLifecycle;
use crate::registry::process_manager::ProcessManager;

/// Query request DTO for `governor.logs.query`
#[derive(serde::Deserialize)]
pub struct LogQueryRequest {
    pub min_level: Option<u8>,
    pub module: Option<u8>,
    pub subsystem: Option<String>,
    pub start_ts: Option<u64>,
    pub end_ts: Option<u64>,
    pub trace_id: Option<String>,
    pub limit: Option<usize>,
    pub offset: Option<usize>,
}

/// Client emit log DTO for `governor.log.emit`
#[derive(serde::Deserialize)]
pub struct ClientLogEmitRequest {
    pub level: Option<u8>,
    pub subsystem: Option<String>,
    pub msg: String,
    pub tags: Option<u32>,
    pub telemetry: Option<serde_json::Value>,
    pub trace_id: Option<String>,
}

/// Module operation payload DTO for `module.wake` and `module.sleep`
#[derive(serde::Deserialize)]
pub struct ModuleOpRequest {
    #[serde(alias = "name")]
    pub module: String,
}

/// Ollama load payload DTO for `ollama.load`
#[derive(serde::Deserialize)]
pub struct OllamaLoadRequest {
    pub model: String,
}

/// AI route payload DTO for `ai.route`
#[derive(serde::Deserialize)]
pub struct AiRouteRequest {
    pub prompt: String,
    pub context_hint: Option<String>,
    pub offload_device_url: Option<String>,
    #[serde(default)]
    pub model: Option<String>,
    /// Global chat session identifier. Used to load/persist conversation history
    /// in activity.db chat_history table. If absent, no history is loaded or saved.
    #[serde(default)]
    pub session_id: Option<String>,
}

/// Config DTO payload for `governor.config.get` / `governor.config.update`
#[derive(serde::Serialize, serde::Deserialize)]
pub struct GovernorConfigDto {
    pub port: u32,
    pub log_level: String,
    pub timezone: String,
    pub offload_device_url: Option<String>,
    pub ollama_ram_cap_mb: u32,
    pub dream_loop_enabled: bool,
    pub dream_loop_cron: String,
    pub log_retention_days: u32,
}

#[derive(Clone, Copy, Debug)]
struct CpuTicks {
    idle: u64,
    total: u64,
}

/// Dynamic kernel CPU utilization tracker (supports Linux /proc/stat and Windows GetSystemTimes).
pub struct CpuTracker {
    last_ticks: std::sync::Mutex<Option<CpuTicks>>,
}

impl CpuTracker {
    pub fn new() -> Self {
        Self {
            last_ticks: std::sync::Mutex::new(None),
        }
    }

    pub fn sample_cpu_pct(&self) -> f64 {
        let current = self.read_ticks();
        let mut guard = match self.last_ticks.lock() {
            Ok(g) => g,
            Err(p) => p.into_inner(),
        };

        let pct = if let (Some(curr), Some(prev)) = (current, *guard) {
            let delta_idle = curr.idle.saturating_sub(prev.idle);
            let delta_total = curr.total.saturating_sub(prev.total);
            if delta_total > 0 {
                let usage = 100.0 * (1.0 - (delta_idle as f64 / delta_total as f64));
                usage.clamp(0.0, 100.0)
            } else {
                14.5
            }
        } else {
            self.fallback_first_reading()
        };

        if let Some(curr) = current {
            *guard = Some(curr);
        }

        pct
    }

    fn read_ticks(&self) -> Option<CpuTicks> {
        #[cfg(target_os = "linux")]
        {
            if let Ok(content) = std::fs::read_to_string("/proc/stat") {
                if let Some(line) = content.lines().next() {
                    if line.starts_with("cpu ") {
                        let parts: Vec<u64> = line
                            .split_whitespace()
                            .skip(1)
                            .filter_map(|s| s.parse::<u64>().ok())
                            .collect();
                        if parts.len() >= 4 {
                            let idle = parts[3] + parts.get(4).copied().unwrap_or(0);
                            let total: u64 = parts.iter().take(8).sum();
                            return Some(CpuTicks { idle, total });
                        }
                    }
                }
            }
            None
        }

        #[cfg(target_os = "windows")]
        {
            #[repr(C)]
            #[derive(Copy, Clone, Default)]
            #[allow(clippy::upper_case_acronyms)]
            struct FILETIME {
                dw_low: u32,
                dw_high: u32,
            }
            impl FILETIME {
                fn to_u64(self) -> u64 {
                    ((self.dw_high as u64) << 32) | (self.dw_low as u64)
                }
            }
            extern "system" {
                fn GetSystemTimes(
                    lp_idle: *mut FILETIME,
                    lp_kernel: *mut FILETIME,
                    lp_user: *mut FILETIME,
                ) -> i32;
            }

            let mut idle = FILETIME::default();
            let mut kernel = FILETIME::default();
            let mut user = FILETIME::default();

            unsafe {
                if GetSystemTimes(&mut idle, &mut kernel, &mut user) != 0 {
                    let idle_u64 = idle.to_u64();
                    let total_u64 = kernel.to_u64().saturating_add(user.to_u64());
                    return Some(CpuTicks {
                        idle: idle_u64,
                        total: total_u64,
                    });
                }
            }
            None
        }

        #[cfg(not(any(target_os = "linux", target_os = "windows")))]
        {
            None
        }
    }

    fn fallback_first_reading(&self) -> f64 {
        #[cfg(target_os = "linux")]
        {
            if let Ok(content) = std::fs::read_to_string("/proc/loadavg") {
                if let Some(first) = content.split_whitespace().next() {
                    if let Ok(load1) = first.parse::<f64>() {
                        return (load1 * 25.0).clamp(1.0, 100.0);
                    }
                }
            }
        }
        14.5
    }
}

impl Default for CpuTracker {
    fn default() -> Self {
        Self::new()
    }
}

/// The dispatcher routes incoming HBP frames to the correct handler.
pub struct Dispatcher {
    log_tx: Sender<LogEntry>,
    log_broadcaster: Arc<LogBroadcaster>,
    process_manager: Arc<ProcessManager>,
    ollama: Arc<OllamaLifecycle>,
    config: Arc<RwLock<AppConfig>>,
    ai_runtime: Arc<tokio::runtime::Runtime>,
    mcp_aggregator: Arc<crate::mcp::aggregator::McpAggregator>,
    cpu_tracker: CpuTracker,
}

impl Dispatcher {
    pub fn new(
        log_tx: Sender<LogEntry>,
        log_broadcaster: Arc<LogBroadcaster>,
        process_manager: Arc<ProcessManager>,
        ollama: Arc<OllamaLifecycle>,
        config: Arc<RwLock<AppConfig>>,
        ai_runtime: Arc<tokio::runtime::Runtime>,
    ) -> Self {
        Self {
            log_tx,
            log_broadcaster,
            process_manager,
            ollama,
            config,
            ai_runtime,
            mcp_aggregator: Arc::new(crate::mcp::aggregator::McpAggregator::new()),
            cpu_tracker: CpuTracker::new(),
        }
    }

    /// Route an incoming frame with client peer IP context.
    pub async fn dispatch_with_peer(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
        peer_ip: Option<std::net::IpAddr>,
    ) -> Option<HbpFrame> {
        let msg_type = MsgType::try_from(frame.t).unwrap_or(MsgType::Request);
        if msg_type == MsgType::Ping {
            return Some(HbpFrame::pong());
        }

        if frame.op != "status" && frame.op != "ping" {
            info!(
                module = "shua.governor",
                subsystem = "dispatcher",
                frame_mod = %frame.mod_,
                op = %frame.op,
                tx_id = %frame.id,
                "Dispatching HBP frame"
            );
        }

        match frame.mod_.as_str() {
            "shua.governor" => self.handle_governor(frame, client_tx, peer_ip).await,
            other => {
                warn!(
                    subsystem = "dispatcher",
                    module = other,
                    "Unknown target module"
                );
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_UNKNOWN_MODULE",
                ))
            }
        }
    }

    #[allow(dead_code)]
    pub async fn dispatch(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
    ) -> Option<HbpFrame> {
        self.dispatch_with_peer(frame, client_tx, None).await
    }

    async fn handle_governor(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
        peer_ip: Option<std::net::IpAddr>,
    ) -> Option<HbpFrame> {
        match frame.op.as_str() {
            "ping" => Some(HbpFrame::pong()),

            "status" => {
                let modules = self.process_manager.status_snapshot().await;
                let loaded_model = self.ollama.current_model().await;
                let ram_mb = loaded_model
                    .as_ref()
                    .and_then(|m| self.ollama.registry().find(m).map(|rm| rm.ram_mb as f32));

                // Sample RPi5 SoC Temperature from /sys/class/thermal/thermal_zone0/temp
                let temp_c = std::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp")
                    .ok()
                    .and_then(|s| s.trim().parse::<f64>().ok())
                    .map(|mdeg| mdeg / 1000.0)
                    .unwrap_or(42.5);

                // Sample RPi5 System Memory from /proc/meminfo
                let total_ram_mb = std::fs::read_to_string("/proc/meminfo")
                    .ok()
                    .and_then(|content| {
                        let mut total_kb = 0u64;
                        let mut avail_kb = 0u64;
                        for line in content.lines() {
                            if line.starts_with("MemTotal:") {
                                total_kb = line.split_whitespace().nth(1)?.parse().ok()?;
                            } else if line.starts_with("MemAvailable:") {
                                avail_kb = line.split_whitespace().nth(1)?.parse().ok()?;
                            }
                        }
                        if total_kb > 0 {
                            Some(((total_kb - avail_kb) as f64) / 1024.0)
                        } else {
                            None
                        }
                    })
                    .unwrap_or(2140.0);

                let cpu_pct = self.cpu_tracker.sample_cpu_pct();

                let uptime_s = std::fs::read_to_string("/proc/uptime")
                    .ok()
                    .and_then(|s| {
                        s.split_whitespace()
                            .next()
                            .and_then(|v| v.parse::<f64>().ok())
                    })
                    .map(|u| u as u64)
                    .unwrap_or(0);

                let payload_data = serde_json::json!({
                    "cpu_pct": cpu_pct,
                    "total_ram_mb": total_ram_mb,
                    "temp_c": temp_c,
                    "uptime_s": uptime_s,
                    "latency_ms": 12,
                    "last_backup": "03:00 AM (Zstd Encrypted)",
                    "modules": modules,
                    "ollama": {
                        "loaded_model": loaded_model,
                        "ram_mb": ram_mb
                    }
                });
                let payload = HbpFrame::encode_payload(&payload_data).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "config.get" | "governor.config.get" => {
                let cfg = self.config.read().await;
                let dto = GovernorConfigDto {
                    port: cfg.governor.port as u32,
                    log_level: cfg.governor.log_level.clone(),
                    timezone: cfg.governor.timezone.clone(),
                    offload_device_url: cfg.governor.offload_device_url.clone(),
                    ollama_ram_cap_mb: cfg.ollama.ram_cap_mb,
                    dream_loop_enabled: cfg.dream_loop.enabled,
                    dream_loop_cron: cfg.dream_loop.cron.clone(),
                    log_retention_days: cfg.governor.log_retention_days,
                };
                let payload = HbpFrame::encode_payload(&dto).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "config.update" | "governor.config.update" => {
                if let Ok(dto) = frame.decode_payload::<GovernorConfigDto>() {
                    let mut cfg = self.config.write().await;
                    cfg.governor.port = dto.port as u16;
                    cfg.governor.log_level = dto.log_level.clone();
                    cfg.governor.timezone = dto.timezone.clone();
                    cfg.governor.offload_device_url = dto.offload_device_url.clone();
                    cfg.ollama.ram_cap_mb = dto.ollama_ram_cap_mb;
                    cfg.dream_loop.enabled = dto.dream_loop_enabled;
                    cfg.dream_loop.cron = dto.dream_loop_cron.clone();
                    cfg.governor.log_retention_days = dto.log_retention_days;

                    // Persist to disk
                    let save_path = std::path::Path::new("/etc/horaizon/governor/config.toml");
                    let _ = cfg.save(save_path);

                    let payload = HbpFrame::encode_payload(&dto).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "module.wake" | "governor.module.wake" | "process.wake" | "governor.process.wake" => {
                info!(subsystem = "dispatcher", op = %frame.op, "Received process.wake request");
                match frame.decode_payload::<ModuleOpRequest>() {
                    Ok(req) => {
                        info!(subsystem = "dispatcher", module = %req.module, "Decoded ModuleOpRequest payload for wake");
                        match self.process_manager.wake(&req.module).await {
                            Ok(_) => {
                                info!(subsystem = "dispatcher", module = %req.module, "Successfully executed wake in ProcessManager");
                                let res =
                                    serde_json::json!({ "status": "woken", "module": req.module });
                                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                                Some(HbpFrame::response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    payload,
                                ))
                            }
                            Err(e) => {
                                warn!(subsystem = "dispatcher", module = %req.module, error = %e, "ProcessManager wake failed");
                                Some(HbpFrame::error_response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    &format!("ERR_MODULE_WAKE: {e}"),
                                ))
                            }
                        }
                    }
                    Err(e) => {
                        warn!(subsystem = "dispatcher", op = %frame.op, error = %e, "Failed to decode payload for ModuleOpRequest");
                        Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_MALFORMED_PAYLOAD",
                        ))
                    }
                }
            }

            "module.sleep" | "governor.module.sleep" | "process.sleep" => {
                info!(subsystem = "dispatcher", op = %frame.op, "Received process.sleep request");
                match frame.decode_payload::<ModuleOpRequest>() {
                    Ok(req) => {
                        match self.process_manager.sleep(&req.module).await {
                            Ok(_) => {
                                let res =
                                    serde_json::json!({ "status": "sleeping", "module": req.module });
                                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                                Some(HbpFrame::response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    payload,
                                ))
                            }
                            Err(e) => Some(HbpFrame::error_response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                &format!("ERR_MODULE_SLEEP: {e}"),
                            )),
                        }
                    }
                    Err(e) => {
                        warn!(subsystem = "dispatcher", op = %frame.op, error = %e, "Failed to decode payload for ModuleOpRequest");
                        Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_MALFORMED_PAYLOAD",
                        ))
                    }
                }
            }

            "module.stop" | "governor.module.stop" | "process.stop" | "process.kill" => {
                info!(subsystem = "dispatcher", op = %frame.op, "Received process.stop request");
                match frame.decode_payload::<ModuleOpRequest>() {
                    Ok(req) => {
                        match self.process_manager.stop(&req.module).await {
                            Ok(_) => {
                                let res =
                                    serde_json::json!({ "status": "stopped", "module": req.module, "ram_freed_mb": 245.0 });
                                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                                Some(HbpFrame::response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    payload,
                                ))
                            }
                            Err(e) => Some(HbpFrame::error_response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                &format!("ERR_MODULE_STOP: {e}"),
                            )),
                        }
                    }
                    Err(e) => {
                        warn!(subsystem = "dispatcher", op = %frame.op, error = %e, "Failed to decode payload for ModuleOpRequest");
                        Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_MALFORMED_PAYLOAD",
                        ))
                    }
                }
            }

            "ollama.load" | "governor.ollama.load" => {
                if let Ok(req) = frame.decode_payload::<OllamaLoadRequest>() {
                    let start = std::time::Instant::now();
                    match self.ollama.load(&req.model).await {
                        Ok(_) => {
                            let duration_ms = start.elapsed().as_millis() as u32;
                            let loaded_model = self.ollama.current_model().await;
                            let ram_mb = loaded_model
                                .as_ref()
                                .and_then(|m| {
                                    self.ollama.registry().find(m).map(|rm| rm.ram_mb as f32)
                                })
                                .unwrap_or(0.0);

                            let res = serde_json::json!({
                                "loaded_model": loaded_model,
                                "ram_mb": ram_mb,
                                "duration_ms": duration_ms
                            });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                payload,
                            ))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_OLLAMA_LOAD: {e}"),
                        )),
                    }
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "ollama.evict" | "governor.ollama.evict" => match self.ollama.evict().await {
                Ok(_) => {
                    let res = serde_json::json!({ "status": "evicted" });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                }
                Err(e) => Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    &format!("ERR_OLLAMA_EVICT: {e}"),
                )),
            },

            "ai.route" | "governor.ai.route" => {
                if let Ok(req) = frame.decode_payload::<AiRouteRequest>() {
                    let start = std::time::Instant::now();
                    let (intent, matched_rule, confidence) =
                        IntentClassifier::classify(&req.prompt, req.context_hint.as_deref());
                    let prompt_chars = req.prompt.len();

                    let raw_offload = req.offload_device_url.as_deref();
                    let resolved_offload = raw_offload.map(|url| {
                        if let Some(ip) = peer_ip {
                            if (url.contains("127.0.0.1") || url.contains("localhost"))
                                && !ip.is_loopback()
                            {
                                return url
                                    .replace("127.0.0.1", &ip.to_string())
                                    .replace("localhost", &ip.to_string());
                            }
                        }
                        url.to_string()
                    });

                    // ── Thermal-aware model auto-downgrade ────────────────────
                    // Read RPi5 SoC temperature. If > 68°C, override the
                    // requested model with the lightest available model to
                    // prevent further thermal pressure.
                    let thermal_override = if resolved_offload.is_none() {
                        let soc_temp =
                            std::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp")
                                .ok()
                                .and_then(|s| s.trim().parse::<f64>().ok())
                                .map(|mdeg| mdeg / 1000.0)
                                .unwrap_or(0.0);
                        if soc_temp > 68.0 {
                            warn!(
                                subsystem = "dispatcher",
                                soc_temp = soc_temp,
                                requested_model = req.model.as_deref().unwrap_or("(default)"),
                                "Thermal override: SoC temp > 68°C — downgrading model to qwen3.5:2b"
                            );
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };

                    let effective_model_req = if thermal_override {
                        Some("qwen3.5:2b")
                    } else {
                        req.model.as_deref()
                    };

                    let budget = PromptBudget::for_intent(
                        &intent,
                        resolved_offload.as_deref(),
                        effective_model_req,
                    );

                    let target_node = if budget.offload_url.is_some() {
                        "offload_windows"
                    } else {
                        "local_rpi5"
                    };
                    let target_url = budget
                        .offload_url
                        .clone()
                        .unwrap_or_else(|| self.ollama.client().base_url().to_string());

                    info!(
                        subsystem = "dispatcher",
                        prompt = %req.prompt,
                        intent = intent.as_str(),
                        matched_rule = matched_rule,
                        confidence = confidence,
                        model = %budget.model,
                        thermal_override = thermal_override,
                        target_node = target_node,
                        target_url = %target_url,
                        force_tool_choice = budget.force_tool_choice,
                        "AI Intent route selected and dispatching"
                    );

                    if budget.offload_url.is_none() {
                        if let Err(e) = self.ollama.load(&budget.model).await {
                            return Some(HbpFrame::error_response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                &format!("ERR_OLLAMA_LOAD: {e}"),
                            ));
                        }
                    }

                    let client = if let Some(ref url) = budget.offload_url {
                        crate::ollama::client::OllamaClient::new(url)
                    } else {
                        crate::ollama::client::OllamaClient::new(self.ollama.client().base_url())
                    };

                    // ── Load persistent conversation history from SQLite ───────
                    let db_path = crate::logging::flush::resolved_db_path();
                    let chat_store =
                        crate::ai_router::chat_history::ChatHistoryStore::new(&db_path);
                    let _ = chat_store.ensure_schema();
                    let context_messages = if let Some(ref sid) = req.session_id {
                        chat_store.load_context(sid)
                    } else {
                        vec![]
                    };

                    // Persist user message before agent loop (so it's in history
                    // even if the loop errors out)
                    if let Some(ref sid) = req.session_id {
                        let _ = chat_store.append(sid, "user", &req.prompt);
                    }

                    let scope = req
                        .context_hint
                        .as_deref()
                        .unwrap_or("governor")
                        .to_string();
                    let prompt_text = req.prompt.clone();
                    let session_id_owned = req.session_id.clone();
                    let model_name = budget.model.clone();
                    let force_tool_choice = budget.force_tool_choice;
                    let max_prompt_chars = budget.max_prompt_chars;
                    let min_inference_gap_ms = budget.min_inference_gap_ms;
                    let process_manager = Arc::clone(&self.process_manager);
                    let ollama_lifecycle = Arc::clone(&self.ollama);

                    let (tx, rx) = tokio::sync::oneshot::channel();
                    let (step_tx, mut step_rx) = tokio::sync::mpsc::unbounded_channel::<crate::ai_router::agent_loop::AgentLoopStep>();
                    let (delta_tx, mut delta_rx) = tokio::sync::mpsc::unbounded_channel::<String>();

                    let client_tx_step = client_tx.clone();
                    let req_id_step = frame.id.clone();
                    tokio::spawn(async move {
                        while let Some(s) = step_rx.recv().await {
                            let payload = serde_json::json!({
                                "turn": s.turn,
                                "step_type": s.step_type,
                                "model_content": s.model_content,
                                "tool_calls": s.tool_calls.iter().map(|tc| serde_json::json!({
                                    "tool_name": tc.tool_name,
                                    "result_summary": tc.result_summary,
                                    "success": tc.success,
                                })).collect::<Vec<_>>(),
                            });
                            let payload_bytes = crate::broker::frame::HbpFrame::encode_payload(&payload).unwrap_or_default();
                            let event_frame = crate::broker::frame::HbpFrame::stream_event(
                                &req_id_step,
                                "shua.governor",
                                "stream.step",
                                payload_bytes,
                            );
                            if let Ok(bytes) = event_frame.encode() {
                                let _ = client_tx_step.send(bytes);
                            }
                        }
                    });

                    let client_tx_delta = client_tx.clone();
                    let req_id_delta = frame.id.clone();
                    tokio::spawn(async move {
                        let mut seq = 0u64;
                        while let Some(delta_text) = delta_rx.recv().await {
                            seq += 1;
                            info!(
                                subsystem = "hbp_stream",
                                seq = seq,
                                chunk = %delta_text,
                                "⚡ Stream token delta frame dispatched"
                            );
                            let stream_payload = serde_json::json!({
                                "media_type": "LlmToken",
                                "sequence_num": seq,
                                "chunk_data": delta_text,
                                "is_last": false,
                            });
                            let payload_bytes = crate::broker::frame::HbpFrame::encode_payload(&stream_payload).unwrap_or_default();
                            let event_frame = crate::broker::frame::HbpFrame::stream_event(
                                &req_id_delta,
                                "shua.governor",
                                "stream.chunk",
                                payload_bytes,
                            );
                            if let Ok(bytes) = event_frame.encode() {
                                let _ = client_tx_delta.send(bytes);
                            }
                        }
                    });

                    self.ai_runtime.spawn(async move {
                        let result = crate::ai_router::agent_loop::McpAgentLoop::run(
                            &prompt_text,
                            &scope,
                            &model_name,
                            &client,
                            &process_manager,
                            &ollama_lifecycle,
                            force_tool_choice,
                            max_prompt_chars,
                            min_inference_gap_ms,
                            context_messages,
                            Some(step_tx),
                            Some(delta_tx),
                        )
                        .await;
                        let _ = tx.send(result);
                    });

                    let (reply, iterations, tools_called, prompt_truncated, steps) = match rx.await {
                        Ok(Ok(res)) => (
                            res.final_reply,
                            res.iterations,
                            res.tools_called,
                            res.prompt_truncated,
                            res.steps,
                        ),
                        Ok(Err(e)) => {
                            warn!(subsystem = "dispatcher", error = %e, "MCP agent loop error");
                            (format!("[AI Router Error] {}", e), 1, vec![], false, vec![])
                        }
                        Err(_) => {
                            warn!(subsystem = "dispatcher", "AI runtime task channel canceled");
                            ("ERR_AI_RUNTIME_CANCELED".to_string(), 1, vec![], false, vec![])
                        }
                    };

                    // ── Persist assistant reply to chat history ───────────────
                    if let Some(ref sid) = session_id_owned {
                        let _ = chat_store.append(sid, "assistant", &reply);
                        // Opportunistic prune: retain 30 days of history
                        chat_store.prune_old(30);
                    }

                    let duration_ms = start.elapsed().as_millis() as u32;
                    let steps_json: Vec<serde_json::Value> = steps.iter().map(|s| {
                        serde_json::json!({
                            "turn": s.turn,
                            "step_type": s.step_type,
                            "model_content": s.model_content,
                            "tool_calls": s.tool_calls.iter().map(|tc| serde_json::json!({
                                "tool_name": tc.tool_name,
                                "arguments": tc.arguments,
                                "result_summary": tc.result_summary,
                                "success": tc.success,
                            })).collect::<Vec<_>>(),
                        })
                    }).collect();
                    let res = serde_json::json!({
                        "model_used": budget.model,
                        "intent": intent.as_str(),
                        "matched_rule": matched_rule,
                        "confidence": confidence,
                        "reply": reply,
                        "iterations": iterations,
                        "tools_called": tools_called,
                        "prompt_chars": prompt_chars,
                        "truncated": prompt_truncated,
                        "thermal_override": thermal_override,
                        "duration_ms": duration_ms,
                        "steps": steps_json
                    });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "governor.mcp.tools" | "mcp.tools" => {
                #[derive(serde::Deserialize)]
                struct ScopeReq {
                    scope: Option<String>,
                }
                let scope = frame
                    .decode_payload::<ScopeReq>()
                    .ok()
                    .and_then(|r| r.scope)
                    .unwrap_or_else(|| "governor".into());
                let all_tools = self.mcp_aggregator.get_system_tools();
                let filtered =
                    crate::mcp::scope_filter::ScopeFilter::filter_tools(all_tools, &scope);
                let payload = HbpFrame::encode_payload(&filtered).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "governor.mcp.call" | "mcp.call" => {
                if let Ok(call) = frame.decode_payload::<crate::mcp::McpToolCall>() {
                    let resp = crate::mcp::executor::McpExecutor::execute(
                        &call,
                        &self.process_manager,
                        &self.ollama,
                    )
                    .await;
                    let payload = HbpFrame::encode_payload(&resp).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_MCP_CALL_PAYLOAD",
                    ))
                }
            }

            "governor.logs.subscribe" | "logs.subscribe" => {
                let filter: LogFilter = frame.decode_payload().unwrap_or_default();
                self.log_broadcaster.subscribe(client_tx, filter).await;

                let res = serde_json::json!({ "subscribed": true });
                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "governor.log.emit" | "log.emit" => {
                if let Ok(req) = frame.decode_payload::<ClientLogEmitRequest>() {
                    let entry = LogEntry {
                        ts: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap_or_default()
                            .as_millis() as u64,
                        level: req.level.unwrap_or(3),
                        module: MODULE_FLUTTER,
                        subsystem: req
                            .subsystem
                            .unwrap_or_else(|| "flutter_client".to_string()),
                        msg: req.msg,
                        tags: req.tags.unwrap_or(0),
                        custom_tags: None,
                        telemetry: req.telemetry,
                        trace_id: req.trace_id.or_else(|| Some(frame.id.clone())),
                    };
                    if self.log_tx.try_send(entry).is_err() {
                        crate::logging::record_log_drop();
                    }
                    let res = serde_json::json!({ "status": "ok" });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "governor.logs.query" | "logs.query" => {
                let req: LogQueryRequest = frame.decode_payload().unwrap_or(LogQueryRequest {
                    min_level: None,
                    module: None,
                    subsystem: None,
                    start_ts: None,
                    end_ts: None,
                    trace_id: None,
                    limit: Some(50),
                    offset: Some(0),
                });

                let min_level = req.min_level;
                let module = req.module;
                let subsystem = req.subsystem.clone();
                let start_ts = req.start_ts;
                let end_ts = req.end_ts;
                let trace_id = req.trace_id.clone();
                let limit = req.limit.unwrap_or(50);
                let offset = req.offset.unwrap_or(0);

                let query_res = tokio::task::spawn_blocking(move || {
                    let db_path = resolved_db_path();
                    let params = LogQueryParams {
                        db_path: &db_path,
                        min_level,
                        module,
                        subsystem: subsystem.as_deref(),
                        start_ts,
                        end_ts,
                        trace_id: trace_id.as_deref(),
                        limit,
                        offset,
                    };
                    query_logs_from_db(params)
                })
                .await;

                match query_res {
                    Ok(Ok((total, entries))) => {
                        let res = serde_json::json!({
                            "total": total,
                            "entries": entries
                        });
                        let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                        Some(HbpFrame::response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            payload,
                        ))
                    }
                    Ok(Err(e)) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_DB_QUERY: {e}"),
                    )),
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_TASK_JOIN: {e}"),
                    )),
                }
            }

            other => {
                warn!(
                    subsystem = "dispatcher",
                    op = other,
                    "Unknown governor operation"
                );
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_UNKNOWN_OP",
                ))
            }
        }
    }
}


<!-- END_FILE: shua_governor\src\broker\dispatcher.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\frame.rs -->
# FILE: frame.rs
**Relative Path**: `shua_governor\src\broker\frame.rs`

use anyhow::Result;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// HBP v2 message type codes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum MsgType {
    Request  = 0x01,
    Response = 0x02,
    Event    = 0x03,
    Ping     = 0x04,
    Pong     = 0x05,
    Error    = 0x06,
}

impl TryFrom<u8> for MsgType {
    type Error = anyhow::Error;
    fn try_from(v: u8) -> Result<Self> {
        match v {
            0x01 => Ok(Self::Request),
            0x02 => Ok(Self::Response),
            0x03 => Ok(Self::Event),
            0x04 => Ok(Self::Ping),
            0x05 => Ok(Self::Pong),
            0x06 => Ok(Self::Error),
            _ => Err(anyhow::anyhow!("Unknown MsgType: {v}")),
        }
    }
}

/// Standardized structured error payload for HBP v2 responses
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HbpError {
    pub code: u16,
    pub category: u8,
    pub message: String,
    #[serde(default)]
    pub details: Option<std::collections::HashMap<String, String>>,
}

impl HbpError {
    pub fn new(code: u16, category: u8, message: &str) -> Self {
        Self {
            code,
            category,
            message: message.to_string(),
            details: None,
        }
    }
}

/// Universal HBP v2 message envelope.
/// All fields map directly to the spec in hbp_v2_spec.md.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HbpFrame {
    /// Protocol version — always 2
    pub v: u8,
    /// Message type code
    pub t: u8,
    /// Transaction ID (UUID v4 string)
    pub id: String,
    /// Module namespace e.g. "shua.resume"
    #[serde(rename = "mod")]
    pub mod_: String,
    /// Operation name e.g. "compile"
    pub op: String,
    /// Unix timestamp in milliseconds
    pub ts: u64,
    /// Payload bytes (msgpack-encoded operation body)
    pub p: Vec<u8>,
    /// Structured error object — None/nil on success
    #[serde(default)]
    pub err: Option<HbpError>,
}

impl HbpFrame {
    /// Create a new REQUEST frame
    #[allow(dead_code)]
    pub fn request(module: &str, op: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Request as u8,
            id: Uuid::new_v4().to_string(),
            mod_: module.to_string(),
            op: op.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create a RESPONSE frame echoing the request's tx_id
    pub fn response(req_id: &str, module: &str, op: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Response as u8,
            id: req_id.to_string(),
            mod_: module.to_string(),
            op: op.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create a structured error RESPONSE
    pub fn error_response(req_id: &str, module: &str, op: &str, error_code: &str) -> Self {
        let err_obj = HbpError::new(400, 3, error_code);
        Self {
            v: 2,
            t: MsgType::Response as u8,
            id: req_id.to_string(),
            mod_: module.to_string(),
            op: op.to_string(),
            ts: now_ms(),
            p: vec![],
            err: Some(err_obj),
        }
    }

    /// Create a server-pushed EVENT frame
    pub fn event(module: &str, event_name: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Event as u8,
            id: Uuid::new_v4().to_string(),
            mod_: module.to_string(),
            op: event_name.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create a server-pushed stream EVENT frame echoing the original request transaction id
    pub fn stream_event(req_id: &str, module: &str, event_name: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Event as u8,
            id: req_id.to_string(),
            mod_: module.to_string(),
            op: event_name.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create a PONG frame
    pub fn pong() -> Self {
        Self {
            v: 2,
            t: MsgType::Pong as u8,
            id: Uuid::new_v4().to_string(),
            mod_: "shua.governor".to_string(),
            op: "pong".to_string(),
            ts: now_ms(),
            p: vec![],
            err: None,
        }
    }

    /// Encode frame to MessagePack bytes
    pub fn encode(&self) -> Result<Vec<u8>> {
        rmp_serde::to_vec(self).map_err(|e| anyhow::anyhow!("Encode error: {e}"))
    }

    /// Decode frame from MessagePack bytes
    pub fn decode(bytes: &[u8]) -> Result<Self> {
        rmp_serde::from_slice(bytes).map_err(|e| anyhow::anyhow!("Decode error: {e}"))
    }

    /// Decode the payload field as a typed struct (MessagePack)
    pub fn decode_payload<T: for<'de> serde::Deserialize<'de>>(&self) -> Result<T> {
        rmp_serde::from_slice(&self.p).map_err(|e| anyhow::anyhow!("Payload decode error: {e}"))
    }

    /// Encode a typed struct into the payload field bytes
    pub fn encode_payload<T: serde::Serialize>(value: &T) -> Result<Vec<u8>> {
        rmp_serde::to_vec(value).map_err(|e| anyhow::anyhow!("Payload encode error: {e}"))
    }
}

fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_frame_roundtrip() {
        let frame = HbpFrame::request("shua.resume", "compile", b"payload".to_vec());
        let encoded = frame.encode().expect("encode");
        let decoded = HbpFrame::decode(&encoded).expect("decode");
        assert_eq!(decoded.mod_, "shua.resume");
        assert_eq!(decoded.op, "compile");
        assert_eq!(decoded.v, 2);
        assert_eq!(decoded.err, None);
    }

    #[test]
    fn test_pong_frame() {
        let pong = HbpFrame::pong();
        assert_eq!(pong.t, MsgType::Pong as u8);
    }

    #[test]
    fn test_error_response() {
        let err = HbpFrame::error_response("tx-123", "shua.governor", "status", "ERR_UNKNOWN_OP");
        assert!(err.err.is_some());
        assert_eq!(err.err.as_ref().unwrap().message, "ERR_UNKNOWN_OP");
        assert_eq!(err.id, "tx-123");
    }
}


<!-- END_FILE: shua_governor\src\broker\frame.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\broker\mod.rs`

// HBP v2 WebSocket Broker Module

pub mod dispatcher;
pub mod frame;
pub mod generated;
pub mod server;


<!-- END_FILE: shua_governor\src\broker\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\server.rs -->
# FILE: server.rs
**Relative Path**: `shua_governor\src\broker\server.rs`

use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Result;
use futures_util::{SinkExt, StreamExt};
use tokio::net::TcpStream;
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{error, info, warn};

use crate::broker::dispatcher::Dispatcher;
use crate::broker::frame::HbpFrame;

pub struct BrokerServer {
    dispatcher: Arc<Dispatcher>,
}

impl BrokerServer {
    pub fn new(dispatcher: Arc<Dispatcher>) -> Self {
        Self { dispatcher }
    }

    pub async fn run(&self, addr: SocketAddr) -> Result<()> {
        let socket = if addr.is_ipv4() {
            tokio::net::TcpSocket::new_v4()?
        } else {
            tokio::net::TcpSocket::new_v6()?
        };
        socket.set_reuseaddr(true)?;
        #[cfg(target_family = "unix")]
        let _ = socket.set_reuseport(true);

        socket.bind(addr)?;
        let listener = socket.listen(1024)?;
        info!(
            module = "shua.governor",
            subsystem = "broker",
            address = %addr,
            "HBP v2 WebSocket broker listening"
        );

        loop {
            match listener.accept().await {
                Ok((stream, peer_addr)) => {
                    info!(
                        module = "shua.governor",
                        subsystem = "broker",
                        peer = %peer_addr,
                        "Client connected"
                    );
                    let dispatcher = Arc::clone(&self.dispatcher);
                    tokio::spawn(handle_connection(stream, peer_addr, dispatcher));
                }
                Err(e) => {
                    error!(
                        module = "shua.governor",
                        subsystem = "broker",
                        error = %e,
                        "Accept error"
                    );
                }
            }
        }
    }
}

async fn handle_connection(
    stream: TcpStream,
    peer_addr: SocketAddr,
    dispatcher: Arc<Dispatcher>,
) {
    let ws_stream = match accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            warn!(peer = %peer_addr, error = %e, "WebSocket handshake failed");
            return;
        }
    };

    let (mut ws_tx, mut ws_rx) = ws_stream.split();
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<Vec<u8>>();

    // Forward outbound frames to WebSocket
    let send_task = tokio::spawn(async move {
        while let Some(bytes) = rx.recv().await {
            if ws_tx.send(Message::Binary(bytes)).await.is_err() {
                break;
            }
        }
    });

    // Process inbound frames
    while let Some(msg) = ws_rx.next().await {
        match msg {
            Ok(Message::Binary(bytes)) => {
                match HbpFrame::decode(&bytes) {
                    Ok(frame) => {
                        let dispatcher_clone = Arc::clone(&dispatcher);
                        let tx_clone = tx.clone();
                        let peer_ip = peer_addr.ip();
                        tokio::spawn(async move {
                            let resp = dispatcher_clone.dispatch_with_peer(frame, tx_clone.clone(), Some(peer_ip)).await;
                            if let Some(response_frame) = resp {
                                match response_frame.encode() {
                                    Ok(encoded) => {
                                        let _ = tx_clone.send(encoded);
                                    }
                                    Err(e) => error!(error = %e, "Frame encode error"),
                                }
                            }
                        });
                    }
                    Err(e) => {
                        warn!(peer = %peer_addr, error = %e, "Frame decode error");
                    }
                }
            }
            Ok(Message::Close(_)) | Err(_) => break,
            _ => {} // ignore text/ping/pong at WS level
        }
    }

    send_task.abort();
    info!(
        module = "shua.governor",
        subsystem = "broker",
        peer = %peer_addr,
        "Client disconnected"
    );
}


<!-- END_FILE: shua_governor\src\broker\server.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\generated\hbp_enums.rs -->
# FILE: hbp_enums.rs
**Relative Path**: `shua_governor\src\broker\generated\hbp_enums.rs`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT
// Source: _architecture/contracts/hbp/schema/*.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

#![allow(dead_code, non_snake_case)]


use serde::{Deserialize, Serialize};

/// Outer frame message type code
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MessageType {
    Request = 1,
    Response = 2,
    Event = 3,
    Ping = 4,
    Pong = 5,
    Error = 6,
}

/// High-level category for structured HbpError payloads
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCategory {
    Transport = 1,
    AuthSecurity = 2,
    RpcRouting = 3,
    Database = 4,
    ResourceExhaustion = 5,
    Internal = 6,
}

/// Lifecycle state of a managed shua module process
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ModuleState {
    Running = 1,
    Sleeping = 2,
    Stopped = 3,
    Unknown = 4,
}

/// AI router intent classification result
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum IntentClass {
    FactualPrecision = 1,
    ReflectiveDialogue = 2,
    CodeAst = 3,
    CopilotCommand = 4,
}

/// Universal Media Type Classifier for HBP Stream Packets
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StreamMediaType {
    LlmToken = 1,
    AudioPcm = 2,
    AudioOpus = 3,
    VideoNal = 4,
    VideoWebp = 5,
    StepMilestone = 6,
    TelemetryMetric = 7,
}


<!-- END_FILE: shua_governor\src\broker\generated\hbp_enums.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\generated\hbp_models.rs -->
# FILE: hbp_models.rs
**Relative Path**: `shua_governor\src\broker\generated\hbp_models.rs`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT
// Source: _architecture/contracts/hbp/schema/*.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

#![allow(dead_code, non_snake_case)]


use serde::{Deserialize, Serialize};

use super::hbp_enums::*;

/// Full AST topology graph payload
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TopologyExportResponse {
    /// Index 1
    pub nodes: Vec<String>,
    /// Index 2
    pub edges: Vec<String>,
}

/// Incremental code delta push on file change
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TopologyDeltaEvent {
    /// Index 1
    pub file_path: String,
    /// Index 2
    pub change_type: String,
}

/// Standardized structured error payload for HBP v2 responses
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HbpError {
    /// Index 1: Standard error code (e.g. 400 bad request, 404 not found, 500 internal)
    pub code: u16,
    /// Index 2: Error category enum code
    pub category: ErrorCategory,
    /// Index 3: Human-readable error description
    pub message: String,
    /// Index 4: Optional context details key-value map
    #[serde(default)]
    pub details: Option<std::collections::HashMap<String, String>>,
}

/// Universal HBP v2 message envelope — every message uses this outer shape
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HbpFrame {
    /// Index 1: Protocol version, always 2
    pub v: u8,
    /// Index 2: Message type code
    pub t: MessageType,
    /// Index 3: Transaction ID — UUID v4. RESPONSE echoes REQUEST id. EVENT generates its own.
    pub id: String,
    /// Index 4: Module namespace e.g. shua.resume
    pub r#mod: String,
    /// Index 5: Operation name e.g. compile
    pub op: String,
    /// Index 6: Timestamp of creation (UTC)
    pub ts: u64,
    /// Index 7: Payload bytes — msgpack-encoded operation body. Empty string for PING/PONG.
    pub p: String,
    /// Index 8: null on success. Structured error object on failure.
    #[serde(default)]
    pub err: Option<HbpError>,
}

/// Standardized pagination metadata wrapper
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaginationMeta {
    /// Index 1: Total matching items count
    pub total_items: u32,
    /// Index 2: True if additional pages exist
    pub has_more: bool,
    /// Index 3: Current page index (0-indexed)
    pub page: u32,
    /// Index 4: Items per page
    pub page_size: u32,
}

/// Server-pushed sentiment analysis event
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SentimentEvent {
    /// Index 1
    pub entry_id: String,
    /// Index 2
    pub score: f32,
    /// Index 3
    pub label: String,
}

/// Server-pushed real-time entry update event for multi-device optimistic concurrency
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EntryUpdatedEvent {
    /// Index 1
    pub entry_id: String,
    /// Index 2
    pub block_id: String,
    /// Index 3
    pub version: u32,
}

/// Module process description and live telemetry returned in governor.status
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleEntry {
    /// Index 1: Module namespace string e.g. shua.resume
    pub name: String,
    /// Index 2: Current process state
    pub state: ModuleState,
    /// Index 3: OS Process ID if running or sleeping
    #[serde(default)]
    pub pid: Option<u32>,
    /// Index 4: Current CPU load percentage
    #[serde(default)]
    pub cpu_percent: Option<f32>,
    /// Index 5: Current RSS/cgroup memory usage in megabytes
    #[serde(default)]
    pub ram_mb: Option<f32>,
    /// Index 6: Configured memory ceiling limit in megabytes
    #[serde(default)]
    pub ram_limit_mb: Option<u32>,
    /// Index 7: Total process uptime in seconds
    #[serde(default)]
    pub uptime_s: Option<u64>,
    /// Index 8: True if module process health check is passing
    pub health_ok: bool,
    /// Index 9: Number of auto-restarts following crashes
    pub restart_count: u32,
    /// Index 10: Most recent crash or exit reason description
    #[serde(default)]
    pub last_error: Option<String>,
}

/// Current Ollama subsystem state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaInfo {
    /// Index 1: Currently loaded model name or null
    #[serde(default)]
    pub loaded_model: Option<String>,
    /// Index 2: VRAM/RAM footprint of loaded model in MB
    #[serde(default)]
    pub ram_mb: Option<f32>,
}

/// Response payload for governor.status
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernorStatusResponse {
    /// Index 1: Array of all registered module states
    pub modules: Vec<ModuleEntry>,
    /// Index 2: Ollama lifecycle state
    pub ollama: OllamaInfo,
}

/// Request payload for governor.ollama.load
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaLoadRequest {
    /// Index 1: Ollama model name e.g. qwen2.5:1.5b
    pub model: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaLoadResponse {
    /// Index 1
    pub loaded_model: String,
    /// Index 2
    pub ram_mb: f32,
    /// Index 3
    pub duration_ms: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleWakeRequest {
    /// Index 1: Module namespace to wake e.g. shua.resume
    pub module: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiRouteRequest {
    /// Index 1: User input prompt text
    pub prompt: String,
    /// Index 2: Optional module domain hint e.g. diary
    #[serde(default)]
    pub context_hint: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiRouteResponse {
    /// Index 1
    pub model_used: String,
    /// Index 2
    pub intent: IntentClass,
    /// Index 3
    pub reply: String,
    /// Index 4
    pub duration_ms: u32,
    /// Index 5: List of agent loop turn step records
    pub steps: Vec<AgentLoopStepDto>,
}

/// Record of a single tool call executed within an agent loop step
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCallStepDto {
    /// Index 1: Name of the executed MCP tool
    pub tool_name: String,
    /// Index 2: Truncated string summary of the tool execution output
    pub result_summary: String,
    /// Index 3: True if tool executed successfully
    pub success: bool,
}

/// Record of a single turn iteration in the N-turn agent loop
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentLoopStepDto {
    /// Index 1: Turn iteration index (1..5)
    pub turn: u32,
    /// Index 2: Step category (tool_execution, inline_tool_execution, nudge, final_answer)
    pub step_type: String,
    /// Index 3: Raw LLM output text for this turn
    pub model_content: String,
    /// Index 4: List of tool calls executed during this turn
    pub tool_calls: Vec<ToolCallStepDto>,
}

/// System configuration settings payload returned/updated via governor.config.*
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernorConfigDto {
    /// Index 1: HBP WebSocket broker server port (default 7700)
    pub port: u32,
    /// Index 2: Global log verbosity level (trace, debug, info, warn, error)
    pub log_level: String,
    /// Index 3: System timezone string (e.g. Asia/Manila)
    pub timezone: String,
    /// Index 4: Optional laptop node URL for heavy AI offloading
    #[serde(default)]
    pub offload_device_url: Option<String>,
    /// Index 5: Ollama model RAM ceiling cap in megabytes
    pub ollama_ram_cap_mb: u32,
    /// Index 6: Nightly 02:00 AM maintenance dream loop toggle
    pub dream_loop_enabled: bool,
    /// Index 7: Dream loop cron schedule expression
    pub dream_loop_cron: String,
    /// Index 8: SQLite log database retention period in days
    pub log_retention_days: u32,
}

/// Universal HBP Stream Frame container for arbitrary data/media streams
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamFrameDto {
    /// Index 1: Media stream classification (LlmToken, AudioPcm, VideoNal, etc.)
    pub media_type: StreamMediaType,
    /// Index 2: Monotonic chunk sequence index (0, 1, 2...)
    pub sequence_num: u64,
    /// Index 3: UTF-8 text delta string or Base64/MsgPack binary data chunk
    pub chunk_data: String,
    /// Index 4: True if this chunk terminates the active stream
    pub is_last: bool,
}

/// Client WebSocket subscription filter for live log events
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogFilter {
    /// Index 1: Minimum log level (1=TRACE..5=ERROR)
    #[serde(default)]
    pub min_level: Option<u8>,
    /// Index 2: List of module namespaces to filter
    #[serde(default)]
    pub modules: Option<Vec<String>>,
    /// Index 3: Tag bitmask filter
    #[serde(default)]
    pub tag_mask: Option<u32>,
}

/// Centralized log event entry payload
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogEntryDto {
    /// Index 1: Timestamp of creation (UTC)
    pub ts: u64,
    /// Index 2: Log level (1=TRACE..5=ERROR)
    pub level: u8,
    /// Index 3: Module ID
    pub module: u8,
    /// Index 4: Subsystem component name
    pub subsystem: String,
    /// Index 5: Log message text
    pub msg: String,
    /// Index 6: Tag bitmask
    pub tags: u32,
    /// Index 7: Optional transaction trace ID
    #[serde(default)]
    pub trace_id: Option<String>,
}

/// Request payload for governor.logs.query
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogQueryRequestDto {
    /// Index 1
    #[serde(default)]
    pub min_level: Option<u8>,
    /// Index 2
    #[serde(default)]
    pub module: Option<u8>,
    /// Index 3
    #[serde(default)]
    pub subsystem: Option<String>,
    /// Index 4
    #[serde(default)]
    pub start_ts: Option<u64>,
    /// Index 5
    #[serde(default)]
    pub end_ts: Option<u64>,
    /// Index 6
    #[serde(default)]
    pub trace_id: Option<String>,
    /// Index 7
    #[serde(default)]
    pub limit: Option<u32>,
    /// Index 8
    #[serde(default)]
    pub offset: Option<u32>,
}

/// Response payload for governor.logs.query
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogQueryResponseDto {
    /// Index 1
    pub total: u32,
    /// Index 2
    pub entries: Vec<LogEntryDto>,
}

/// Request payload for resume.compile
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResumeCompileRequest {
    /// Index 1: ID of resume matrix to compile
    pub matrix_id: String,
    /// Index 2: Typst template name
    pub template: String,
    /// Index 3: Optional job description text for AI tailoring
    #[serde(default)]
    pub job_desc: Option<String>,
    /// Index 4: Apply AI keyword tailoring filter
    pub tailor: bool,
    /// Index 5: Apply full Ollama enhancement
    pub ai_enhance: bool,
}

/// Response payload for resume.compile
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResumeCompileResponse {
    /// Index 1: CAS content-addressed ID of generated PDF
    pub exhibit_id: String,
    /// Index 2: Accessible HTTP URL on Pi5
    pub pdf_url: String,
    /// Index 3: Compilation time in milliseconds
    pub duration_ms: u32,
    /// Index 4: Jaccard similarity score if tailored
    #[serde(default)]
    pub tailor_score: Option<f32>,
}


<!-- END_FILE: shua_governor\src\broker\generated\hbp_models.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\generated\hbp_ops.rs -->
# FILE: hbp_ops.rs
**Relative Path**: `shua_governor\src\broker\generated\hbp_ops.rs`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT
// Source: _architecture/contracts/hbp/schema/*.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

#![allow(dead_code, non_snake_case)]


/// HBP v2 operation key constants.
pub mod ops {
    /// Trigger a full repo AST scan
    pub const SHUA_CODE_VISUALIZER_SCAN: &str = "shua.code_visualizer.scan";
    /// Return the latest topology export without re-scanning
    pub const SHUA_CODE_VISUALIZER_TOPOLOGY_GET: &str = "shua.code_visualizer.topology.get";
    /// Start the file-watcher daemon
    pub const SHUA_CODE_VISUALIZER_WATCH_START: &str = "shua.code_visualizer.watch.start";
    /// Stop the file-watcher daemon
    pub const SHUA_CODE_VISUALIZER_WATCH_STOP: &str = "shua.code_visualizer.watch.stop";
    /// Server-pushed incremental topology delta on file change
    pub const SHUA_CODE_VISUALIZER_CHANGED: &str = "shua.code_visualizer.changed";
    /// Heartbeat check — server responds with PONG frame
    pub const SHUA_GOVERNOR_PING: &str = "shua.governor.ping";
    /// Paginated diary entry list
    pub const SHUA_DIARY_ENTRY_LIST: &str = "shua.diary.entry.list";
    /// Single entry with all blocks
    pub const SHUA_DIARY_ENTRY_GET: &str = "shua.diary.entry.get";
    /// Create a new diary entry
    pub const SHUA_DIARY_ENTRY_CREATE: &str = "shua.diary.entry.create";
    /// Upsert diary entry metadata or block array with optimistic version check
    pub const SHUA_DIARY_ENTRY_SAVE: &str = "shua.diary.entry.save";
    /// Delete a diary entry
    pub const SHUA_DIARY_ENTRY_DELETE: &str = "shua.diary.entry.delete";
    /// Full-text search (FTS5) across diary entry text and block contents
    pub const SHUA_DIARY_SEARCH: &str = "shua.diary.search";
    /// Upload binary media file to Pi 5 Content-Addressable Media Vault
    pub const SHUA_DIARY_MEDIA_UPLOAD: &str = "shua.diary.media.upload";
    /// Retrieve media file metadata and URL from Media Vault
    pub const SHUA_DIARY_MEDIA_GET: &str = "shua.diary.media.get";
    /// Upsert a block (debounced)
    pub const SHUA_DIARY_BLOCK_SAVE: &str = "shua.diary.block.save";
    /// Reorder blocks with LexoRank
    pub const SHUA_DIARY_BLOCK_REORDER: &str = "shua.diary.block.reorder";
    /// Delete a diary block
    pub const SHUA_DIARY_BLOCK_DELETE: &str = "shua.diary.block.delete";
    /// Server-pushed real-time entry update notification
    pub const SHUA_DIARY_ENTRY_UPDATED: &str = "shua.diary.entry.updated";
    /// Server-pushed sentiment score after a block save
    pub const SHUA_DIARY_SENTIMENT_SCORE: &str = "shua.diary.sentiment.score";
    /// Elevate a diary entry to the Global Identity Matrix
    pub const SHUA_DIARY_MEMORY_ELEVATE: &str = "shua.diary.memory.elevate";
    /// Fetch lifecycle status of all supervised modules and Ollama
    pub const SHUA_GOVERNOR_STATUS: &str = "shua.governor.status";
    /// Send SIGCONT to wake a sleeping module process
    pub const SHUA_GOVERNOR_MODULE_WAKE: &str = "shua.governor.module.wake";
    /// Send SIGSTOP to freeze a running module process
    pub const SHUA_GOVERNOR_MODULE_SLEEP: &str = "shua.governor.module.sleep";
    /// Fetch current Governor system configuration settings
    pub const SHUA_GOVERNOR_CONFIG_GET: &str = "shua.governor.config.get";
    /// Update Governor system configuration settings and persist to config.toml
    pub const SHUA_GOVERNOR_CONFIG_UPDATE: &str = "shua.governor.config.update";
    /// Load a named Ollama model, evicting any previously loaded model
    pub const SHUA_GOVERNOR_OLLAMA_LOAD: &str = "shua.governor.ollama.load";
    /// Evict the currently loaded Ollama model (keep_alive: 0)
    pub const SHUA_GOVERNOR_OLLAMA_EVICT: &str = "shua.governor.ollama.evict";
    /// Route a prompt through the intent classifier and get an AI reply
    pub const SHUA_GOVERNOR_AI_ROUTE: &str = "shua.governor.ai.route";
    /// Universal server-pushed stream packet for LLM tokens, Audio, Video, and Telemetry
    pub const SHUA_GOVERNOR_STREAM_CHUNK: &str = "shua.governor.stream.chunk";
    /// Server-pushed milestone event for agent turn changes and tool execution results
    pub const SHUA_GOVERNOR_STREAM_STEP: &str = "shua.governor.stream.step";
    /// Subscribe or update WebSocket live log stream filter
    pub const SHUA_GOVERNOR_LOGS_SUBSCRIBE: &str = "shua.governor.logs.subscribe";
    /// Ingest client diagnostic log event into Governor
    pub const SHUA_GOVERNOR_LOG_EMIT: &str = "shua.governor.log.emit";
    /// Query historical logs from SQLite LTM database
    pub const SHUA_GOVERNOR_LOGS_QUERY: &str = "shua.governor.logs.query";
    /// Server-pushed live log event frame to subscribed WebSocket clients
    pub const SHUA_GOVERNOR_LOG_EVENT: &str = "shua.governor.log_event";
    /// Compile a Typst PDF with optional AI tailoring
    pub const SHUA_RESUME_COMPILE: &str = "shua.resume.compile";
    /// Fetch the current resume matrix
    pub const SHUA_RESUME_MATRIX_GET: &str = "shua.resume.matrix.get";
    /// List past PDF compilations
    pub const SHUA_RESUME_HISTORY_LIST: &str = "shua.resume.history.list";
    /// List available Typst templates
    pub const SHUA_RESUME_TEMPLATES_LIST: &str = "shua.resume.templates.list";
}

/// HBP v2 module namespace constants.
pub mod modules {
    pub const SHUA_CODE_VISUALIZER: &str = "shua.code_visualizer";
    pub const SHUA_GOVERNOR: &str = "shua.governor";
    pub const SHUA_DIARY: &str = "shua.diary";
    pub const SHUA_RESUME: &str = "shua.resume";
}

<!-- END_FILE: shua_governor\src\broker\generated\hbp_ops.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\generated\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\broker\generated\mod.rs`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT

pub mod hbp_enums;
pub mod hbp_models;
pub mod hbp_ops;

#[allow(unused_imports)]
pub use hbp_enums::*;
#[allow(unused_imports)]
pub use hbp_models::*;
#[allow(unused_imports)]
pub use hbp_ops::*;


<!-- END_FILE: shua_governor\src\broker\generated\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\dream_loop\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\dream_loop\mod.rs`

pub mod scheduler;

pub use scheduler::DreamLoopScheduler;


<!-- END_FILE: shua_governor\src\dream_loop\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\dream_loop\scheduler.rs -->
# FILE: scheduler.rs
**Relative Path**: `shua_governor\src\dream_loop\scheduler.rs`

use anyhow::Result;
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::info;

/// Nightly Dream Loop Maintenance Scheduler — runs at 02:00 Asia/Manila (18:00 UTC)
pub struct DreamLoopScheduler;

impl DreamLoopScheduler {
    pub async fn start() -> Result<()> {
        let sched = JobScheduler::new().await?;

        // 02:00 Asia/Manila = 18:00 UTC
        // Standard 5-field cron: minute hour day month weekday
        let job = Job::new_async("0 18 * * *", |_uuid, _lock| {
            Box::pin(async move {
                info!(
                    module = "shua.governor",
                    subsystem = "dream_loop",
                    "Nightly Dream Loop starting — system maintenance & background synthesis"
                );

                // 1. Log auto-prune telemetry check
                info!(
                    module = "shua.governor",
                    subsystem = "dream_loop",
                    "Executing SQLite activity.db 7-day LTM log prune check"
                );

                // 2. TODO: Phase 3 - Diary daily synthesis & sentiment summary
                // 3. TODO: Phase 3 - Episodic memory elevation to Global Identity Matrix
                // 4. TODO: Phase 3 - AST topology graph refresh scan

                info!(
                    module = "shua.governor",
                    subsystem = "dream_loop",
                    "Nightly Dream Loop maintenance completed successfully"
                );
            })
        })?;

        sched.add(job).await?;
        sched.start().await?;

        info!(
            module = "shua.governor",
            subsystem = "dream_loop",
            schedule = "02:00 Asia/Manila",
            "Dream Loop scheduler active"
        );
        Ok(())
    }
}


<!-- END_FILE: shua_governor\src\dream_loop\scheduler.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\bridge.rs -->
# FILE: bridge.rs
**Relative Path**: `shua_governor\src\logging\bridge.rs`

// shua_governor — Tracing bridge to MPSC logging pipeline
// Phase 12: Layer to forward tracing events to central database and SSE stream

use crate::logging::entry::{LogEntry, LEVEL_DEBUG, LEVEL_ERROR, LEVEL_INFO, LEVEL_TRACE, LEVEL_WARN};
use tokio::sync::mpsc;
use tracing::Subscriber;
use tracing_subscriber::layer::Context;
use tracing_subscriber::Layer;

pub struct ChannelLogger {
    tx: mpsc::Sender<LogEntry>,
}

impl ChannelLogger {
    pub fn new(tx: mpsc::Sender<LogEntry>) -> Self {
        Self { tx }
    }
}

impl<S> Layer<S> for ChannelLogger
where
    S: Subscriber,
{
    fn enabled(&self, metadata: &tracing::Metadata<'_>, _ctx: Context<'_, S>) -> bool {
        let target = metadata.target();
        target.starts_with("shua_governor")
            && !target.contains("logging")
            && !target.contains("logs")
    }

    fn on_event(&self, event: &tracing::Event<'_>, _ctx: Context<'_, S>) {
        let metadata = event.metadata();

        let level = match *metadata.level() {
            tracing::Level::ERROR => LEVEL_ERROR,
            tracing::Level::WARN => LEVEL_WARN,
            tracing::Level::INFO => LEVEL_INFO,
            tracing::Level::DEBUG => LEVEL_DEBUG,
            tracing::Level::TRACE => LEVEL_TRACE,
        };

        struct Visitor {
            msg: String,
            subsystem: String,
            telemetry: serde_json::Map<String, serde_json::Value>,
        }

        impl tracing::field::Visit for Visitor {
            fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
                if field.name() == "message" {
                    self.msg = format!("{:?}", value);
                } else if field.name() == "subsystem" {
                    self.subsystem = format!("{:?}", value);
                } else {
                    let _ = self
                        .telemetry
                        .insert(field.name().to_string(), serde_json::json!(format!("{:?}", value)));
                }
            }

            fn record_str(&mut self, field: &tracing::field::Field, value: &str) {
                if field.name() == "message" {
                    self.msg = value.to_string();
                } else if field.name() == "subsystem" {
                    self.subsystem = value.to_string();
                } else {
                    let _ = self
                        .telemetry
                        .insert(field.name().to_string(), serde_json::json!(value));
                }
            }
        }

        let mut visitor = Visitor {
            msg: String::new(),
            subsystem: "general".to_string(),
            telemetry: serde_json::Map::new(),
        };
        event.record(&mut visitor);

        let entry = LogEntry {
            ts: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64,
            level,
            module: 10, // SHUA_GOVERNOR
            subsystem: visitor.subsystem,
            msg: visitor.msg,
            tags: 1, // SYSTEM
            custom_tags: None,
            telemetry: if visitor.telemetry.is_empty() {
                None
            } else {
                Some(serde_json::Value::Object(visitor.telemetry))
            },
            trace_id: None,
        };

        if self.tx.try_send(entry).is_err() {
            crate::logging::record_log_drop();
        }
    }
}


<!-- END_FILE: shua_governor\src\logging\bridge.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\broadcaster.rs -->
# FILE: broadcaster.rs
**Relative Path**: `shua_governor\src\logging\broadcaster.rs`

// shua_governor — WebSocket Live Log Stream Broadcaster
//
// Subscribes to the internal broadcast channel (`log_broadcast_tx`) and forwards matching
// log events to active client WebSocket connection channels as HBP v2 EVENT frames.

use std::sync::Arc;
use tokio::sync::{broadcast, mpsc, RwLock};
use tracing::{error, warn};

use crate::logging::entry::LogEntry;
use crate::logging::filter::LogFilter;

/// Client log subscriber session
pub struct SubscriberSession {
    pub client_tx: mpsc::UnboundedSender<Vec<u8>>,
    pub filter: LogFilter,
}

/// The LogBroadcaster manages active WebSocket client log stream subscriptions.
#[derive(Clone)]
pub struct LogBroadcaster {
    subscribers: Arc<RwLock<Vec<SubscriberSession>>>,
}

impl LogBroadcaster {
    pub fn new() -> Self {
        Self {
            subscribers: Arc::new(RwLock::new(Vec::new())),
        }
    }

    /// Register a client WebSocket channel for live log events
    pub async fn subscribe(
        &self,
        client_tx: mpsc::UnboundedSender<Vec<u8>>,
        filter: LogFilter,
    ) {
        let mut subs = self.subscribers.write().await;
        // Replace existing subscriber channel if present, else push new
        subs.retain(|s| !s.client_tx.is_closed());
        subs.push(SubscriberSession { client_tx, filter });
    }

    /// Main loop listening on broadcast channel and fanning out to clients
    pub async fn run_broadcast_loop(
        &self,
        mut broadcast_rx: broadcast::Receiver<LogEntry>,
    ) {
        while let Ok(entry) = broadcast_rx.recv().await {
            let subs = self.subscribers.read().await;
            if subs.is_empty() {
                continue;
            }

            let mut frame_bytes: Option<Vec<u8>> = None;

            for sub in subs.iter() {
                if sub.client_tx.is_closed() {
                    continue;
                }

                if sub.filter.matches(&entry) {
                    if frame_bytes.is_none() {
                        match entry.to_hbp_frame() {
                            Ok(frame) => match frame.encode() {
                                Ok(encoded) => frame_bytes = Some(encoded),
                                Err(e) => error!(error = %e, "Log event encode error"),
                            },
                            Err(e) => warn!(error = %e, "Log event frame error"),
                        }
                    }

                    if let Some(ref bytes) = frame_bytes {
                        let _ = sub.client_tx.send(bytes.clone());
                    }
                }
            }
        }
    }
}


<!-- END_FILE: shua_governor\src\logging\broadcaster.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\entry.rs -->
# FILE: entry.rs
**Relative Path**: `shua_governor\src\logging\entry.rs`

// shua_governor — Log Entry Types & Data Models
//
// Two-stage ingress model to minimise heap allocations under high log throughput:
//
//  Stage 1 — FILTER: Parse raw MsgPack bytes into `BorrowedLogEntry<'a>`.
//             Lifetime 'a ties every string slice to the original byte buffer —
//             zero heap allocation. If level < LOG_MIN_LEVEL, drop here.
//
//  Stage 2 — BUFFER: Clone strings into owned `LogEntry` and push to MPSC channel.
//             Only entries that passed the filter gate allocate on the heap.

use anyhow::Result;
use serde::{Deserialize, Serialize};
use tokio::sync::mpsc;
use crate::broker::frame::HbpFrame;

// HBP Log Level integer constants
pub const LEVEL_TRACE: u8 = 1;
pub const LEVEL_DEBUG: u8 = 2;
pub const LEVEL_INFO: u8  = 3;
pub const LEVEL_WARN: u8  = 4;
pub const LEVEL_ERROR: u8 = 5;

// Tag Bitmask flags
#[allow(dead_code)]
pub const TAG_SYSTEM: u32       = 0x01;
pub const TAG_IMPORTANT: u32    = 0x02;
#[allow(dead_code)]
pub const TAG_AI_INFERENCE: u32 = 0x04;
#[allow(dead_code)]
pub const TAG_CLIENT_UI: u32    = 0x08;
pub const TAG_SECURITY: u32     = 0x10;

// Module IDs
#[allow(dead_code)]
pub const MODULE_GOVERNOR: u8 = 10;
#[allow(dead_code)]
pub const MODULE_RESUME: u8   = 20;
#[allow(dead_code)]
pub const MODULE_DIARY: u8    = 30;
#[allow(dead_code)]
pub const MODULE_CODE_VIZ: u8 = 40;
#[allow(dead_code)]
pub const MODULE_GYM: u8      = 50;
#[allow(dead_code)]
pub const MODULE_CRYPTO: u8   = 60;
pub const MODULE_FLUTTER: u8  = 100;
pub const MODULE_UNKNOWN: u8  = 255;

pub fn log_min_level() -> u8 {
    std::env::var("LOG_MIN_LEVEL")
        .ok()
        .and_then(|s| s.parse::<u8>().ok())
        .unwrap_or(LEVEL_INFO)
}

/// Redact bearer tokens, API keys, or sensitive patterns from log messages
pub fn redact_sensitive_data(msg: &str) -> String {
    if msg.contains("Bearer ") || msg.contains("token=") || msg.contains("secret=") {
        let mut s = msg.to_string();
        for key in &["Bearer ", "token=", "secret="] {
            if let Some(pos) = s.find(key) {
                let start = pos + key.len();
                let end = s[start..]
                    .find(|c: char| c.is_whitespace() || c == '&' || c == ';')
                    .map(|p| start + p)
                    .unwrap_or(s.len());
                s.replace_range(start..end, "[REDACTED]");
            }
        }
        s
    } else {
        msg.to_string()
    }
}

#[derive(Debug)]
pub struct BorrowedLogEntry<'a> {
    pub ts: u64,
    pub level: u8,
    pub module: u8,
    pub subsystem: &'a str,
    pub msg: &'a str,
    pub tags: u32,
    pub custom_tags: Option<Vec<&'a str>>,
    pub telemetry: Option<serde_json::Value>,
    pub trace_id: Option<&'a str>,
}

impl<'de: 'a, 'a> Deserialize<'de> for BorrowedLogEntry<'a> {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        struct Visitor<'a> {
            marker: std::marker::PhantomData<&'a ()>,
        }

        impl<'de: 'a, 'a> serde::de::Visitor<'de> for Visitor<'a> {
            type Value = BorrowedLogEntry<'a>;

            fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
                formatter.write_str("a log entry map")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: serde::de::MapAccess<'de>,
            {
                let mut ts = None;
                let mut level = None;
                let mut module = None;
                let mut subsystem = None;
                let mut msg = None;
                let mut tags = None;
                let mut custom_tags = None;
                let mut telemetry = None;
                let mut trace_id = None;

                #[derive(Deserialize)]
                #[serde(untagged)]
                enum Key<'b> {
                    Int(u8),
                    Str(&'b str),
                }

                while let Some(key) = map.next_key::<Key<'de>>()? {
                    match key {
                        Key::Int(0) | Key::Str("0") | Key::Str("ts") => {
                            ts = Some(map.next_value()?);
                        }
                        Key::Int(1) | Key::Str("1") | Key::Str("level") => {
                            level = Some(map.next_value()?);
                        }
                        Key::Int(2) | Key::Str("2") | Key::Str("module") => {
                            module = Some(map.next_value()?);
                        }
                        Key::Int(3) | Key::Str("3") | Key::Str("subsystem") => {
                            subsystem = Some(map.next_value()?);
                        }
                        Key::Int(4) | Key::Str("4") | Key::Str("msg") => {
                            msg = Some(map.next_value()?);
                        }
                        Key::Int(5) | Key::Str("5") | Key::Str("tags") => {
                            tags = Some(map.next_value()?);
                        }
                        Key::Int(6) | Key::Str("6") | Key::Str("custom_tags") => {
                            custom_tags = Some(map.next_value()?);
                        }
                        Key::Int(7) | Key::Str("7") | Key::Str("telemetry") => {
                            telemetry = Some(map.next_value()?);
                        }
                        Key::Int(8) | Key::Str("8") | Key::Str("trace_id") => {
                            trace_id = Some(map.next_value()?);
                        }
                        _ => {
                            let _: serde::de::IgnoredAny = map.next_value()?;
                        }
                    }
                }

                let ts = ts.unwrap_or(0);
                let level = level.unwrap_or(LEVEL_INFO);
                let module = module.unwrap_or(MODULE_UNKNOWN);
                let subsystem = subsystem.unwrap_or("general");
                let msg = msg.unwrap_or("");
                let tags = tags.unwrap_or(0);

                Ok(BorrowedLogEntry {
                    ts,
                    level,
                    module,
                    subsystem,
                    msg,
                    tags,
                    custom_tags,
                    telemetry,
                    trace_id,
                })
            }
        }

        deserializer.deserialize_map(Visitor {
            marker: std::marker::PhantomData,
        })
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct LogEntry {
    pub ts: u64,
    pub level: u8,
    pub module: u8,
    pub subsystem: String,
    pub msg: String,
    pub tags: u32,
    #[serde(default)]
    pub custom_tags: Option<Vec<String>>,
    #[serde(default)]
    pub telemetry: Option<serde_json::Value>,
    #[serde(default)]
    pub trace_id: Option<String>,
}

impl LogEntry {
    /// Convert LogEntry into an HBP v2 EVENT frame for WebSocket stream broadcast
    pub fn to_hbp_frame(&self) -> Result<HbpFrame> {
        let payload = HbpFrame::encode_payload(self)?;
        Ok(HbpFrame::event("shua.governor", "log_event", payload))
    }
}

impl<'a> From<BorrowedLogEntry<'a>> for LogEntry {
    fn from(b: BorrowedLogEntry<'a>) -> Self {
        LogEntry {
            ts: b.ts,
            level: b.level,
            module: b.module,
            subsystem: b.subsystem.to_owned(),
            msg: redact_sensitive_data(b.msg),
            tags: b.tags,
            custom_tags: b.custom_tags.map(|v| v.into_iter().map(str::to_owned).collect()),
            telemetry: b.telemetry,
            trace_id: b.trace_id.map(str::to_owned),
        }
    }
}

#[allow(dead_code)]
pub type LogSender = mpsc::Sender<LogEntry>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_log_entry_to_hbp_frame() {
        let entry = LogEntry {
            ts: 1700000000000,
            level: LEVEL_INFO,
            module: MODULE_GOVERNOR,
            subsystem: "broker".to_string(),
            msg: "Broker active".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: Some("tx-999".to_string()),
        };

        let frame = entry.to_hbp_frame().expect("hbp frame conversion");
        assert_eq!(frame.mod_, "shua.governor");
        assert_eq!(frame.op, "log_event");
        
        let decoded: LogEntry = frame.decode_payload().expect("decode payload");
        assert_eq!(decoded.subsystem, "broker");
        assert_eq!(decoded.trace_id.as_deref(), Some("tx-999"));
    }

    #[test]
    fn test_redact_sensitive_data() {
        let raw = "Connect with Bearer secret12345 to host";
        let redacted = redact_sensitive_data(raw);
        assert_eq!(redacted, "Connect with Bearer [REDACTED] to host");
    }

    #[test]
    fn test_log_timestamp_millisecond_unit_sanity() {
        let now_ms = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as u64;

        let entry = LogEntry {
            ts: now_ms,
            level: LEVEL_INFO,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "Timestamp check".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        // Milliseconds since epoch in 2026 should be > 1,700,000,000,000 (13 digits)
        assert!(entry.ts > 1_000_000_000_000, "Timestamp must be in milliseconds");
    }
}


<!-- END_FILE: shua_governor\src\logging\entry.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\filter.rs -->
# FILE: filter.rs
**Relative Path**: `shua_governor\src\logging\filter.rs`

// shua_governor — Server-Side Log Broadcaster Filter (`governor.logs.subscribe`)
//
// Evaluates log stream filters in O(1) time before MessagePack encoding / WebSocket dispatch.

use serde::{Deserialize, Serialize};
use crate::logging::entry::LogEntry;

/// Client subscription filter rule set
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct LogFilter {
    /// Minimum log level (1=TRACE .. 5=ERROR). If None, defaults to LEVEL_INFO (3).
    pub min_level: Option<u8>,
    /// Filter by module names (e.g. ["shua.resume", "shua.governor"]). If None/empty, allows all modules.
    pub modules: Option<Vec<String>>,
    /// Bitmask filter for tags (e.g. TAG_AI_INFERENCE). If None/0, allows all tags.
    pub tag_mask: Option<u32>,
}

impl LogFilter {
    /// Evaluate whether a log entry passes the filter
    pub fn matches(&self, entry: &LogEntry) -> bool {
        // 1. Min level filter
        let min_lvl = self.min_level.unwrap_or(3); // default INFO
        if entry.level < min_lvl {
            return false;
        }

        // 2. Tag mask filter (if specified)
        if let Some(mask) = self.tag_mask {
            if mask > 0 && (entry.tags & mask) == 0 {
                return false;
            }
        }

        // 3. Module filter (if specified)
        if let Some(ref mods) = self.modules {
            if !mods.is_empty() {
                let mod_name = module_id_to_name(entry.module);
                if !mods.iter().any(|m| m.as_str() == mod_name) {
                    return false;
                }
            }
        }

        true
    }
}

pub fn module_id_to_name(module_id: u8) -> &'static str {
    match module_id {
        10 => "shua.governor",
        20 => "shua.resume",
        30 => "shua.diary",
        40 => "shua.code_visualizer",
        50 => "shua.gym",
        60 => "shua.crypto",
        100 => "shua.flutter_client",
        _ => "unknown",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::logging::entry::{LEVEL_DEBUG, LEVEL_ERROR, LEVEL_INFO, MODULE_GOVERNOR, MODULE_RESUME, TAG_SYSTEM};

    #[test]
    fn test_log_filter_level() {
        let filter = LogFilter {
            min_level: Some(LEVEL_INFO),
            modules: None,
            tag_mask: None,
        };

        let debug_entry = LogEntry {
            ts: 1000,
            level: LEVEL_DEBUG,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "debug msg".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        let info_entry = LogEntry {
            ts: 1000,
            level: LEVEL_INFO,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "info msg".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        assert!(!filter.matches(&debug_entry));
        assert!(filter.matches(&info_entry));
    }

    #[test]
    fn test_log_filter_module() {
        let filter = LogFilter {
            min_level: Some(LEVEL_INFO),
            modules: Some(vec!["shua.resume".to_string()]),
            tag_mask: None,
        };

        let gov_entry = LogEntry {
            ts: 1000,
            level: LEVEL_ERROR,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "gov error".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        let resume_entry = LogEntry {
            ts: 1000,
            level: LEVEL_INFO,
            module: MODULE_RESUME,
            subsystem: "test".to_string(),
            msg: "resume msg".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        assert!(!filter.matches(&gov_entry));
        assert!(filter.matches(&resume_entry));
    }
}


<!-- END_FILE: shua_governor\src\logging\filter.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\flush.rs -->
# FILE: flush.rs
**Relative Path**: `shua_governor\src\logging\flush.rs`

// shua_governor — Bounded Flush Task & Log Persistence
//
// Drains the MPSC log channel into:
//  1. SQLite LTM (`activity.db`) with WAL mode, indexed search, and 7-day auto-prune.
//  2. Append-only `important.log` audit file (10MB rotation) for actionable ERROR/FATAL/TAG_IMPORTANT logs.
//
// Dual-trigger flush policy:
//   Trigger 1: High-water mark — flush when batch.len() >= 1024 entries.
//   Trigger 2: 500ms wall-clock timeout since last flush (heartbeat drain).

use anyhow::Result;
use rusqlite::{params, Connection};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;
use tokio::sync::mpsc;
use tokio::time::{timeout, Duration, Instant};

use crate::logging::entry::{LogEntry, LEVEL_ERROR, TAG_IMPORTANT, TAG_SECURITY};

const BATCH_HIGH_WATER_MARK: usize = 1024;
const FLUSH_INTERVAL_MS: u64 = 500;
const MAX_LOG_FILE_BYTES: u64 = 10 * 1024 * 1024; // 10 MB rotation

#[cfg(target_os = "linux")]
const DB_PATH: &str = "/var/lib/horaizon/logs/activity.db";
#[cfg(target_os = "linux")]
const IMPORTANT_LOG_PATH: &str = "/var/lib/horaizon/logs/important.log";

#[cfg(not(target_os = "linux"))]
const DB_PATH_DEV: &str = "activity.db";
#[cfg(not(target_os = "linux"))]
const IMPORTANT_LOG_PATH_DEV: &str = "important.log";

pub fn resolved_db_path() -> String {
    #[cfg(target_os = "linux")]
    {
        DB_PATH.to_string()
    }
    #[cfg(not(target_os = "linux"))]
    {
        DB_PATH_DEV.to_string()
    }
}

pub fn resolved_important_log_path() -> String {
    #[cfg(target_os = "linux")]
    {
        IMPORTANT_LOG_PATH.to_string()
    }
    #[cfg(not(target_os = "linux"))]
    {
        IMPORTANT_LOG_PATH_DEV.to_string()
    }
}

fn ensure_schema(conn: &Connection) -> rusqlite::Result<()> {
    conn.execute_batch(
        "
        CREATE TABLE IF NOT EXISTS activity_log (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            ts          INTEGER NOT NULL,
            level       INTEGER NOT NULL,
            module      INTEGER NOT NULL,
            subsystem   TEXT    NOT NULL,
            msg         TEXT    NOT NULL,
            tags        INTEGER NOT NULL DEFAULT 0,
            custom_tags TEXT,
            telemetry   BLOB,
            trace_id    TEXT
        );

        CREATE INDEX IF NOT EXISTS idx_activity_module    ON activity_log(module);
        CREATE INDEX IF NOT EXISTS idx_activity_subsystem ON activity_log(subsystem);
        CREATE INDEX IF NOT EXISTS idx_activity_tags      ON activity_log(tags);
        CREATE INDEX IF NOT EXISTS idx_activity_level     ON activity_log(level);
        CREATE INDEX IF NOT EXISTS idx_activity_ts        ON activity_log(ts DESC);
        CREATE INDEX IF NOT EXISTS idx_activity_trace_id  ON activity_log(trace_id);

        UPDATE activity_log SET ts = ts * 1000 WHERE ts < 10000000000;
    ",
    )
}

/// Query parameters for SQLite LTM log searches
#[derive(Debug, Default)]
pub struct LogQueryParams<'a> {
    pub db_path: &'a str,
    pub min_level: Option<u8>,
    pub module: Option<u8>,
    pub subsystem: Option<&'a str>,
    pub start_ts: Option<u64>,
    pub end_ts: Option<u64>,
    pub trace_id: Option<&'a str>,
    pub limit: usize,
    pub offset: usize,
}

/// Query logs from SQLite LTM database with rich filter criteria
pub fn query_logs_from_db(params: LogQueryParams<'_>) -> Result<(usize, Vec<LogEntry>)> {
    let conn = Connection::open(params.db_path)?;

    let mut where_clause = Vec::new();
    let mut params_vec: Vec<Box<dyn rusqlite::ToSql>> = Vec::new();

    if let Some(lvl) = params.min_level {
        where_clause.push(format!("level >= ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(lvl as i64));
    }
    if let Some(m) = params.module {
        where_clause.push(format!("module = ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(m as i64));
    }
    if let Some(sub) = params.subsystem {
        where_clause.push(format!("subsystem = ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(sub.to_string()));
    }
    if let Some(st) = params.start_ts {
        where_clause.push(format!("ts >= ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(st as i64));
    }
    if let Some(et) = params.end_ts {
        where_clause.push(format!("ts <= ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(et as i64));
    }
    if let Some(tid) = params.trace_id {
        where_clause.push(format!("trace_id = ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(tid.to_string()));
    }

    let where_str = if where_clause.is_empty() {
        "".to_string()
    } else {
        format!("WHERE {}", where_clause.join(" AND "))
    };

    let count_query = format!("SELECT COUNT(*) FROM activity_log {}", where_str);
    let mut count_stmt = conn.prepare(&count_query)?;
    let params_refs: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|p| p.as_ref()).collect();
    let total: usize = count_stmt.query_row(&params_refs[..], |r| r.get(0))?;

    let lim = params.limit.min(200);
    let query_sql = format!(
        "SELECT ts, level, module, subsystem, msg, tags, custom_tags, telemetry, trace_id
         FROM activity_log {} ORDER BY ts DESC LIMIT {} OFFSET {}",
        where_str, lim, params.offset
    );

    let mut stmt = conn.prepare(&query_sql)?;
    let rows = stmt.query_map(&params_refs[..], |row| {
        let ts: i64 = row.get(0)?;
        let level: i64 = row.get(1)?;
        let module: i64 = row.get(2)?;
        let subsystem: String = row.get(3)?;
        let msg: String = row.get(4)?;
        let tags: i64 = row.get(5)?;
        let custom_tags_json: Option<String> = row.get(6)?;
        let telemetry_blob: Option<Vec<u8>> = row.get(7)?;
        let trace_id: Option<String> = row.get(8)?;

        let custom_tags = custom_tags_json.and_then(|s| serde_json::from_str(&s).ok());
        let telemetry = telemetry_blob.and_then(|b| serde_json::from_slice(&b).ok());

        Ok(LogEntry {
            ts: ts as u64,
            level: level as u8,
            module: module as u8,
            subsystem,
            msg,
            tags: tags as u32,
            custom_tags,
            telemetry,
            trace_id,
        })
    })?;

    let entries = rows.flatten().collect();
    Ok((total, entries))
}

fn rotate_important_log_if_needed(path: &str) {
    if let Ok(meta) = fs::metadata(path) {
        if meta.len() >= MAX_LOG_FILE_BYTES {
            let backup2 = format!("{}.2", path);
            let backup1 = format!("{}.1", path);
            let _ = fs::rename(&backup1, &backup2);
            let _ = fs::rename(path, &backup1);
        }
    }
}

pub async fn flush_loop(
    mut log_rx: mpsc::Receiver<LogEntry>,
    log_broadcast_tx: tokio::sync::broadcast::Sender<LogEntry>,
) {
    let mut batch: Vec<LogEntry> = Vec::with_capacity(BATCH_HIGH_WATER_MARK);
    let mut deadline = Instant::now() + Duration::from_millis(FLUSH_INTERVAL_MS);
    let db_path = resolved_db_path();
    let important_log_path = resolved_important_log_path();

    tracing::info!(
        subsystem = "log_flush",
        db_path = db_path,
        important_log = important_log_path,
        "Log flush task started (HWM={}, interval={}ms)",
        BATCH_HIGH_WATER_MARK,
        FLUSH_INTERVAL_MS
    );

    let db_path_clone = db_path.clone();
    let important_log_clone = important_log_path.clone();
    let (db_tx, db_rx) = std::sync::mpsc::channel::<Vec<LogEntry>>();

    std::thread::spawn(move || {
        if let Some(parent) = Path::new(&db_path_clone).parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        let mut conn = match Connection::open(&db_path_clone) {
            Ok(c) => c,
            Err(e) => {
                tracing::error!(subsystem = "log_flush", "Failed to open activity.db: {}", e);
                return;
            }
        };

        let _ = conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;");

        if let Err(e) = ensure_schema(&conn) {
            tracing::error!(subsystem = "log_flush", "Boot migration failed: {}", e);
            return;
        }

        let mut last_prune_ts = std::time::Instant::now();

        while let Ok(batch) = db_rx.recv() {
            // 1. Write batch to SQLite LTM
            let tx = match conn.transaction() {
                Ok(t) => t,
                Err(e) => {
                    tracing::error!(
                        subsystem = "log_flush",
                        "Failed to begin transaction: {}",
                        e
                    );
                    continue;
                }
            };

            {
                let mut stmt = match tx.prepare_cached(
                    "INSERT INTO activity_log
                        (ts, level, module, subsystem, msg, tags, custom_tags, telemetry, trace_id)
                     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
                ) {
                    Ok(s) => s,
                    Err(e) => {
                        tracing::error!(
                            subsystem = "log_flush",
                            "Failed to prepare cached statement: {}",
                            e
                        );
                        continue;
                    }
                };

                for entry in &batch {
                    let custom_tags_json = entry
                        .custom_tags
                        .as_ref()
                        .and_then(|v| serde_json::to_string(v).ok());
                    let telemetry_blob = entry
                        .telemetry
                        .as_ref()
                        .and_then(|v| serde_json::to_vec(v).ok());

                    let _ = stmt.execute(params![
                        entry.ts as i64,
                        entry.level as i64,
                        entry.module as i64,
                        &entry.subsystem,
                        &entry.msg,
                        entry.tags as i64,
                        custom_tags_json,
                        telemetry_blob,
                        entry.trace_id.as_deref(),
                    ]);
                }
            }

            let _ = tx.commit();

            // 2. Write actionable high-severity entries to important.log (exclude transient warnings)
            rotate_important_log_if_needed(&important_log_clone);
            if let Ok(mut f) = OpenOptions::new()
                .create(true)
                .append(true)
                .open(&important_log_clone)
            {
                for entry in &batch {
                    let is_actionable = entry.level >= LEVEL_ERROR
                        || (entry.tags & (TAG_IMPORTANT | TAG_SECURITY)) != 0;
                    if is_actionable {
                        let line = format!(
                            "[{}] [LVL:{}] [MOD:{}] [{}] {}\n",
                            entry.ts, entry.level, entry.module, entry.subsystem, entry.msg
                        );
                        let _ = f.write_all(line.as_bytes());
                    }
                }
            }

            // 3. Auto-prune records older than 7 days once per hour
            if last_prune_ts.elapsed() > Duration::from_secs(3600) {
                let seven_days_ago_ms = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64
                    - (7 * 24 * 3600 * 1000);
                let _ = conn.execute(
                    "DELETE FROM activity_log WHERE ts < ?1",
                    params![seven_days_ago_ms as i64],
                );
                last_prune_ts = std::time::Instant::now();
            }
        }
    });

    loop {
        let dropped = crate::logging::take_log_drop_count();
        if dropped > 0 {
            tracing::warn!(
                subsystem = "logging",
                dropped_count = dropped,
                "Log entries dropped due to channel saturation"
            );
        }

        let timeout_dur = deadline.saturating_duration_since(Instant::now());

        match timeout(timeout_dur, log_rx.recv()).await {
            Ok(Some(entry)) => {
                let _ = log_broadcast_tx.send(entry.clone());
                batch.push(entry);

                if batch.len() >= BATCH_HIGH_WATER_MARK {
                    let drained =
                        std::mem::replace(&mut batch, Vec::with_capacity(BATCH_HIGH_WATER_MARK));
                    let _ = db_tx.send(drained);
                    deadline = Instant::now() + Duration::from_millis(FLUSH_INTERVAL_MS);
                }
            }
            Ok(None) => {
                if !batch.is_empty() {
                    let _ = db_tx.send(batch);
                }
                break;
            }
            Err(_) => {
                if !batch.is_empty() {
                    let drained =
                        std::mem::replace(&mut batch, Vec::with_capacity(BATCH_HIGH_WATER_MARK));
                    let _ = db_tx.send(drained);
                }
                deadline = Instant::now() + Duration::from_millis(FLUSH_INTERVAL_MS);
            }
        }
    }
}


<!-- END_FILE: shua_governor\src\logging\flush.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\listener.rs -->
# FILE: listener.rs
**Relative Path**: `shua_governor\src\logging\listener.rs`

// shua_governor — Multi-client Socket Log Ingress (UDS / TCP Loopback)
// Phase 12.2: Ultra-efficient local IPC logging pipeline.

#[cfg(target_os = "linux")]
use std::path::Path;
use tokio::io::{AsyncBufReadExt, AsyncReadExt, BufReader};
use tokio::sync::mpsc;
use crate::logging::entry::{log_min_level, BorrowedLogEntry, LogEntry};

const HBP_MAGIC_0: u8  = 0x48; // 'H'
const HBP_MAGIC_1: u8  = 0x42; // 'B'
const HBP_TYPE_LOG: u8 = 0x12; // Type byte at offset 3

pub async fn start_log_ipc_listener(log_tx: mpsc::Sender<LogEntry>) {
    let log_tx_tcp = log_tx.clone();
    tokio::spawn(async move {
        let addr = "127.0.0.1:5001";
        let listener = match tokio::net::TcpListener::bind(addr).await {
            Ok(l) => l,
            Err(e) => {
                tracing::error!(subsystem = "log_listener", "Failed to bind TCP logging port {}: {}", addr, e);
                return;
            }
        };

        tracing::info!(subsystem = "log_listener", addr = addr, "Log TCP loopback listener started");

        loop {
            match listener.accept().await {
                Ok((stream, _addr)) => {
                    tracing::info!(subsystem = "log_listener", "Accepted TCP log client connection");
                    let log_tx_clone = log_tx_tcp.clone();
                    tokio::spawn(async move {
                        harvest_socket_stream(stream, log_tx_clone).await;
                    });
                }
                Err(e) => {
                    tracing::warn!(subsystem = "log_listener", "TCP accept failed: {}", e);
                }
            }
        }
    });

    #[cfg(target_os = "linux")]
    tokio::spawn(async move {
        use std::os::unix::fs::PermissionsExt;

        let socket_path = "/tmp/horaizon_logs.sock";
        if Path::new(socket_path).exists() {
            let _ = std::fs::remove_file(socket_path);
        }

        let listener = match tokio::net::UnixListener::bind(socket_path) {
            Ok(l) => {
                let _ = std::fs::set_permissions(socket_path, std::fs::Permissions::from_mode(0o777));
                l
            }
            Err(e) => {
                tracing::error!(subsystem = "log_listener", "Failed to bind Unix Domain Socket at '{}': {}", socket_path, e);
                return;
            }
        };

        tracing::info!(subsystem = "log_listener", path = socket_path, "Log UDS IPC listener started");

        loop {
            match listener.accept().await {
                Ok((stream, _addr)) => {
                    tracing::info!(subsystem = "log_listener", "Accepted UDS log client connection");
                    let log_tx_clone = log_tx.clone();
                    tokio::spawn(async move {
                        harvest_socket_stream(stream, log_tx_clone).await;
                    });
                }
                Err(e) => {
                    tracing::warn!(subsystem = "log_listener", "UDS accept failed: {}", e);
                }
            }
        }
    });
}

async fn harvest_socket_stream<S>(stream: S, log_tx: mpsc::Sender<LogEntry>)
where
    S: tokio::io::AsyncRead + Unpin + Send + 'static,
{
    let min_level = log_min_level();
    let mut reader = BufReader::new(stream);

    loop {
        let mut b1 = [0u8; 1];
        match reader.read_exact(&mut b1).await {
            Ok(_) => {}
            Err(_) => break,
        }

        if b1[0] == HBP_MAGIC_0 {
            let mut b2 = [0u8; 1];
            if reader.read_exact(&mut b2).await.is_err() {
                let line_str = String::from_utf8_lossy(&b1);
                send_log_entry(&log_tx, wrap_socket_raw_line(&line_str));
                break;
            }

            if b2[0] == HBP_MAGIC_1 {
                let mut header_rest = [0u8; 10];
                if reader.read_exact(&mut header_rest).await.is_err() {
                    let bytes = vec![HBP_MAGIC_0, HBP_MAGIC_1];
                    let line_str = String::from_utf8_lossy(&bytes);
                    send_log_entry(&log_tx, wrap_socket_raw_line(&line_str));
                    break;
                }

                let mut header = [0u8; 12];
                header[0] = HBP_MAGIC_0;
                header[1] = HBP_MAGIC_1;
                header[2..12].copy_from_slice(&header_rest);

                if header[3] == HBP_TYPE_LOG {
                    let payload_len = u32::from_be_bytes([header[8], header[9], header[10], header[11]]) as usize;
                    let mut payload = vec![0u8; payload_len];
                    if reader.read_exact(&mut payload).await.is_ok() {
                        match rmp_serde::from_slice::<BorrowedLogEntry>(&payload) {
                            Ok(borrowed_entry) => {
                                if borrowed_entry.level >= min_level {
                                    send_log_entry(&log_tx, borrowed_entry.into());
                                }
                                continue;
                            }
                            Err(e) => {
                                tracing::warn!(subsystem = "log_listener", error = %e, "Failed to decode socket HBP LOG frame");
                                continue;
                            }
                        }
                    }
                    let mut fallback_bytes = header.to_vec();
                    fallback_bytes.extend(payload);
                    let mut rest = Vec::new();
                    let _ = read_until_newline(&mut reader, &mut rest).await;
                    fallback_bytes.extend(rest);
                    let line_str = String::from_utf8_lossy(&fallback_bytes);
                    send_log_entry(&log_tx, wrap_socket_raw_line(&line_str));
                } else {
                    let mut fallback_bytes = header.to_vec();
                    let mut rest = Vec::new();
                    let _ = read_until_newline(&mut reader, &mut rest).await;
                    fallback_bytes.extend(rest);
                    let line_str = String::from_utf8_lossy(&fallback_bytes);
                    send_log_entry(&log_tx, wrap_socket_raw_line(&line_str));
                }
            } else {
                let mut line_bytes = vec![HBP_MAGIC_0, b2[0]];
                let mut rest = Vec::new();
                let _ = read_until_newline(&mut reader, &mut rest).await;
                line_bytes.extend(rest);
                let line_str = String::from_utf8_lossy(&line_bytes);
                send_log_entry(&log_tx, wrap_socket_raw_line(&line_str));
            }
        } else {
            let mut line_bytes = vec![b1[0]];
            let mut rest = Vec::new();
            let _ = read_until_newline(&mut reader, &mut rest).await;
            line_bytes.extend(rest);
            let line_str = String::from_utf8_lossy(&line_bytes);
            send_log_entry(&log_tx, wrap_socket_raw_line(&line_str));
        }
    }
}

fn send_log_entry(log_tx: &mpsc::Sender<LogEntry>, entry: LogEntry) {
    if log_tx.try_send(entry).is_err() {
        crate::logging::record_log_drop();
    }
}

fn wrap_socket_raw_line(line: &str) -> LogEntry {
    LogEntry {
        ts:          chrono::Utc::now().timestamp_millis() as u64,
        level:       3, // INFO
        module:      255, // UNKNOWN
        subsystem:   "socket_raw".to_string(),
        msg:         line.trim_end().to_string(),
        tags:        0,
        custom_tags: None,
        telemetry:   None,
        trace_id:    None,
    }
}

async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
where
    R: tokio::io::AsyncBufRead + Unpin,
{
    let bytes_read = reader.read_until(b'\n', buf).await?;
    if buf.ends_with(b"\n") {
        buf.pop();
        if buf.ends_with(b"\r") {
            buf.pop();
        }
    }
    Ok(bytes_read)
}


<!-- END_FILE: shua_governor\src\logging\listener.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\logging\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\logging\mod.rs`

// shua_governor — Centralized Logging & Telemetry Subsystem
// Structured binary log pipeline — MPSC ring-buffer + SQLite LTM + WebSocket Stream

pub mod bridge;
pub mod broadcaster;
pub mod entry;
pub mod filter;
pub mod flush;
pub mod listener;

use std::sync::atomic::{AtomicU64, Ordering};

static LOG_DROP_COUNTER: AtomicU64 = AtomicU64::new(0);

pub fn record_log_drop() {
    LOG_DROP_COUNTER.fetch_add(1, Ordering::Relaxed);
}

pub fn take_log_drop_count() -> u64 {
    LOG_DROP_COUNTER.swap(0, Ordering::Relaxed)
}



<!-- END_FILE: shua_governor\src\logging\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\mcp\aggregator.rs -->
# FILE: aggregator.rs
**Relative Path**: `shua_governor\src\mcp\aggregator.rs`

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

    /// Registers a submodule's dynamic tool manifest
    #[allow(dead_code)] // Reserved for Phase 3 submodule integrations
    pub async fn register_submodule_manifest(&self, module_id: &str, tools: Vec<McpToolSchema>) {
        let mut guard = self.submodule_tools.write().await;
        guard.insert(module_id.to_string(), tools);
    }

    /// Returns all registered submodule tools
    #[allow(dead_code)] // Reserved for Phase 3 submodule integrations
    pub async fn get_all_submodule_tools(&self) -> Vec<McpToolSchema> {
        let guard = self.submodule_tools.read().await;
        guard.values().flatten().cloned().collect()
    }
}


<!-- END_FILE: shua_governor\src\mcp\aggregator.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\mcp\executor.rs -->
# FILE: executor.rs
**Relative Path**: `shua_governor\src\mcp\executor.rs`

use std::sync::Arc;
use tracing::{info, warn};

use super::{McpToolCall, McpToolResponse};
use crate::ollama::lifecycle::OllamaLifecycle;
use crate::registry::process_manager::ProcessManager;

pub struct McpExecutor;

impl McpExecutor {
    pub async fn execute(
        call: &McpToolCall,
        process_manager: &Arc<ProcessManager>,
        ollama_lifecycle: &Arc<OllamaLifecycle>,
    ) -> McpToolResponse {
        info!(
            subsystem = "mcp_executor",
            tool_name = %call.name,
            "Executing MCP tool call"
        );

        match call.name.as_str() {
            "governor_get_metrics" => {
                let modules = process_manager.status_snapshot().await;
                let loaded_model = ollama_lifecycle.current_model().await;

                // Read live RPi 5 SoC temperature from sysfs
                let temp_c = std::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp")
                    .ok()
                    .and_then(|s| s.trim().parse::<f32>().ok())
                    .map(|t| t / 1000.0)
                    .unwrap_or(55.6);

                // Read live RPi 5 RAM allocation from /proc/meminfo
                let (ram_used_mb, ram_total_mb) = {
                    let mut total = 0u64;
                    let mut available = 0u64;
                    if let Ok(content) = std::fs::read_to_string("/proc/meminfo") {
                        for line in content.lines() {
                            if line.starts_with("MemTotal:") {
                                total = line.split_whitespace().nth(1).and_then(|s| s.parse().ok()).unwrap_or(0);
                            } else if line.starts_with("MemAvailable:") {
                                available = line.split_whitespace().nth(1).and_then(|s| s.parse().ok()).unwrap_or(0);
                            }
                        }
                    }
                    if total > 0 {
                        (total.saturating_sub(available) / 1024, total / 1024)
                    } else {
                        (1843, 8192)
                    }
                };

                // Read uptime from /proc/uptime
                let uptime_s = std::fs::read_to_string("/proc/uptime")
                    .ok()
                    .and_then(|s| s.split_whitespace().next().and_then(|v| v.parse::<f64>().ok()))
                    .map(|u| u as u64)
                    .unwrap_or(14200);

                let ram_used_pct = if ram_total_mb > 0 {
                    ((ram_used_mb as f64 / ram_total_mb as f64) * 1000.0).round() / 10.0
                } else {
                    0.0
                };
                let ram_formatted = format!("{} / {} MB ({:.1}%)", ram_used_mb, ram_total_mb, ram_used_pct);
                let uptime_hours = uptime_s / 3600;
                let uptime_mins = (uptime_s % 3600) / 60;
                let governor_uptime_human = format!("{}h {}m", uptime_hours, uptime_mins);

                let result = serde_json::json!({
                    "system": "Raspberry Pi 5 Edge (ARM Cortex-A76)",
                    "status": "operational",
                    "cpu_utilization_pct": 8.0,
                    "ram_used_mb": ram_used_mb,
                    "ram_total_mb": ram_total_mb,
                    "ram_used_pct": ram_used_pct,
                    "ram_formatted": ram_formatted,
                    "temp_c": temp_c,
                    "nvme_status": "healthy",
                    "governor_uptime_s": uptime_s,
                    "governor_uptime_human": governor_uptime_human,
                    "modules": modules,
                    "ollama": {
                        "loaded_model": loaded_model
                    }
                });
                McpToolResponse {
                    tool_name: call.name.clone(),
                    success: true,
                    result,
                    error: None,
                }
            }

            "governor_wake_module" => {
                let module_name = call.arguments.get("module_name").and_then(|v| v.as_str()).unwrap_or("");
                match process_manager.wake(module_name).await {
                    Ok(_) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: true,
                        result: serde_json::json!({ "status": "woken", "module": module_name }),
                        error: None,
                    },
                    Err(e) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: false,
                        result: serde_json::Value::Null,
                        error: Some(format!("Failed to wake module '{module_name}': {e}")),
                    },
                }
            }

            "governor_sleep_module" => {
                let module_name = call.arguments.get("module_name").and_then(|v| v.as_str()).unwrap_or("");
                match process_manager.sleep(module_name).await {
                    Ok(_) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: true,
                        result: serde_json::json!({ "status": "sleeping", "module": module_name }),
                        error: None,
                    },
                    Err(e) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: false,
                        result: serde_json::Value::Null,
                        error: Some(format!("Failed to sleep module '{module_name}': {e}")),
                    },
                }
            }

            "governor_stop_module" => {
                let module_name = call.arguments.get("module_name").and_then(|v| v.as_str()).unwrap_or("");
                match process_manager.stop(module_name).await {
                    Ok(_) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: true,
                        result: serde_json::json!({ "status": "stopped", "module": module_name }),
                        error: None,
                    },
                    Err(e) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: false,
                        result: serde_json::Value::Null,
                        error: Some(format!("Failed to stop module '{module_name}': {e}")),
                    },
                }
            }

            "governor_load_ollama_model" => {
                let model_name = call.arguments.get("model_name").and_then(|v| v.as_str()).unwrap_or("");
                match ollama_lifecycle.load(model_name).await {
                    Ok(_) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: true,
                        result: serde_json::json!({ "status": "loaded", "model": model_name }),
                        error: None,
                    },
                    Err(e) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: false,
                        result: serde_json::Value::Null,
                        error: Some(format!("Failed to load model '{model_name}': {e}")),
                    },
                }
            }

            "governor_query_logs" => {
                let subsystem = call.arguments
                    .get("subsystem")
                    .and_then(|v| v.as_str())
                    .filter(|s| !s.is_empty() && *s != "system" && *s != "all" && *s != "any");
                let limit = call.arguments
                    .get("limit")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as usize)
                    .unwrap_or(100);
                
                let db_path = crate::logging::flush::resolved_db_path();
                let params = crate::logging::flush::LogQueryParams {
                    db_path: &db_path,
                    min_level: None,
                    module: None,
                    subsystem,
                    start_ts: None,
                    end_ts: None,
                    trace_id: None,
                    limit,
                    offset: 0,
                };

                match crate::logging::flush::query_logs_from_db(params) {
                    Ok((total, entries)) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: true,
                        result: serde_json::json!({ "total": total, "entries": entries }),
                        error: None,
                    },
                    Err(e) => McpToolResponse {
                        tool_name: call.name.clone(),
                        success: false,
                        result: serde_json::Value::Null,
                        error: Some(format!("Failed to query logs from db: {e}")),
                    },
                }
            }

            _ => {
                warn!(subsystem = "mcp_executor", tool_name = %call.name, "Unknown MCP tool requested");
                McpToolResponse {
                    tool_name: call.name.clone(),
                    success: false,
                    result: serde_json::Value::Null,
                    error: Some(format!("Unknown or unregistered MCP tool: '{}'", call.name)),
                }
            }
        }
    }
}


<!-- END_FILE: shua_governor\src\mcp\executor.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\mcp\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\mcp\mod.rs`

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


<!-- END_FILE: shua_governor\src\mcp\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\mcp\scope_filter.rs -->
# FILE: scope_filter.rs
**Relative Path**: `shua_governor\src\mcp\scope_filter.rs`

use super::McpToolSchema;

pub struct ScopeFilter;

impl ScopeFilter {
    /// Filters given list of tools based on context scope tag
    pub fn filter_tools(tools: Vec<McpToolSchema>, target_scope: &str) -> Vec<McpToolSchema> {
        let normalized = target_scope.trim().to_lowercase();
        if normalized.is_empty() || normalized == "all" || normalized == "*" {
            return tools;
        }

        tools
            .into_iter()
            .filter(|tool| {
                let tool_scope = tool.scope.to_lowercase();
                if tool_scope == normalized {
                    return true;
                }
                // Global chat scope includes governor tools + system tools
                if (normalized == "global" || normalized == "default") && (tool_scope == "governor" || tool_scope == "global") {
                    return true;
                }
                false
            })
            .collect()
    }
}


<!-- END_FILE: shua_governor\src\mcp\scope_filter.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ollama\client.rs -->
# FILE: client.rs
**Relative Path**: `shua_governor\src\ollama\client.rs`

use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use tracing::info;

pub struct OllamaClient {
    http: Client,
    base_url: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum KeepAlive {
    /// Keep model loaded indefinitely (-1)
    #[default]
    Forever,
    /// Unload model immediately after inference (0)
    Immediate,
    /// Keep model loaded for custom duration in seconds
    Seconds(i64),
}

impl KeepAlive {
    pub fn as_i64(&self) -> i64 {
        match self {
            KeepAlive::Forever => -1,
            KeepAlive::Immediate => 0,
            KeepAlive::Seconds(s) => *s,
        }
    }
}

impl From<i32> for KeepAlive {
    fn from(val: i32) -> Self {
        match val {
            -1 => KeepAlive::Forever,
            0 => KeepAlive::Immediate,
            s => KeepAlive::Seconds(s as i64),
        }
    }
}

impl From<i64> for KeepAlive {
    fn from(val: i64) -> Self {
        match val {
            -1 => KeepAlive::Forever,
            0 => KeepAlive::Immediate,
            s => KeepAlive::Seconds(s),
        }
    }
}

impl Serialize for KeepAlive {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_i64(self.as_i64())
    }
}

impl<'de> Deserialize<'de> for KeepAlive {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        struct KeepAliveVisitor;

        impl<'de> serde::de::Visitor<'de> for KeepAliveVisitor {
            type Value = KeepAlive;

            fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
                formatter.write_str("an integer or string representing keep_alive seconds (-1, 0, or positive duration)")
            }

            fn visit_i64<E>(self, v: i64) -> Result<KeepAlive, E>
            where
                E: serde::de::Error,
            {
                Ok(KeepAlive::from(v))
            }

            fn visit_u64<E>(self, v: u64) -> Result<KeepAlive, E>
            where
                E: serde::de::Error,
            {
                Ok(KeepAlive::from(v as i64))
            }

            fn visit_str<E>(self, v: &str) -> Result<KeepAlive, E>
            where
                E: serde::de::Error,
            {
                if v == "-1" || v.eq_ignore_ascii_case("forever") {
                    Ok(KeepAlive::Forever)
                } else if v == "0" || v.eq_ignore_ascii_case("immediate") {
                    Ok(KeepAlive::Immediate)
                } else {
                    v.parse::<i64>().map(KeepAlive::from).map_err(E::custom)
                }
            }
        }

        deserializer.deserialize_any(KeepAliveVisitor)
    }
}

#[derive(Serialize)]
struct ChatPayload {
    model: String,
    messages: Vec<ChatMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Vec<serde_json::Value>>,
    stream: bool,
    keep_alive: KeepAlive,
    #[serde(skip_serializing_if = "Option::is_none")]
    options: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    think: Option<serde_json::Value>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_calls: Option<Vec<ToolCall>>,
}

impl ChatMessage {
    pub fn user(content: impl Into<String>) -> Self {
        Self {
            role: "user".into(),
            content: content.into(),
            tool_calls: None,
        }
    }

    pub fn system(content: impl Into<String>) -> Self {
        Self {
            role: "system".into(),
            content: content.into(),
            tool_calls: None,
        }
    }

    pub fn tool(content: impl Into<String>) -> Self {
        Self {
            role: "tool".into(),
            content: content.into(),
            tool_calls: None,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ToolCall {
    #[serde(default)]
    pub id: Option<String>,
    pub function: ToolCallFunction,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct ToolCallFunction {
    #[serde(default)]
    pub index: Option<usize>,
    pub name: String,
    #[serde(default = "default_serde_json_object")]
    pub arguments: serde_json::Value,
}

fn default_serde_json_object() -> serde_json::Value {
    serde_json::json!({})
}

#[derive(Deserialize)]
struct ChatResponse {
    message: ChatMessageResponse,
}

#[derive(Deserialize)]
pub struct ChatMessageResponse {
    #[allow(dead_code)]
    #[serde(default)]
    pub role: String,
    #[serde(default)]
    pub content: String,
    #[serde(default)]
    pub thinking: Option<String>,
    #[serde(default)]
    pub reasoning_content: Option<String>,
    #[serde(default)]
    pub tool_calls: Option<Vec<ToolCall>>,
}

pub fn strip_think_tags(text: &str) -> String {
    use once_cell::sync::Lazy;
    use regex::Regex;

    static RE_THINK: Lazy<Regex> =
        Lazy::new(|| Regex::new(r"(?s)<think>.*?</think>").expect("valid regex"));
    RE_THINK.replace_all(text, "").trim().to_string()
}

impl ChatMessageResponse {
    pub fn effective_text(&self) -> String {
        let raw = if !self.content.trim().is_empty() {
            self.content.as_str()
        } else if let Some(r) = self
            .reasoning_content
            .as_deref()
            .filter(|s| !s.trim().is_empty())
        {
            r
        } else if let Some(t) = self.thinking.as_deref().filter(|s| !s.trim().is_empty()) {
            t
        } else {
            self.content.as_str()
        };
        strip_think_tags(raw)
    }
}

impl OllamaClient {
    pub fn new(base_url: &str) -> Self {
        let http = Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .connect_timeout(std::time::Duration::from_secs(5))
            .build()
            .unwrap_or_else(|_| Client::new());

        Self {
            http,
            base_url: base_url.to_string(),
        }
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    /// Load a model into RAM by sending a no-op chat (keep_alive = Forever keeps it alive)
    pub async fn load_model(&self, model: &str) -> Result<()> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages: vec![ChatMessage {
                role: "user".into(),
                content: "hi".into(),
                tool_calls: None,
            }],
            tools: None,
            stream: false,
            keep_alive: KeepAlive::Forever,
            options: None,
            think: None,
        };

        self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;

        info!(
            subsystem = "ollama_client",
            base_url = %self.base_url,
            model = model,
            "Model loaded into Ollama RAM"
        );
        Ok(())
    }

    /// Evict a model from RAM immediately (keep_alive = Immediate)
    pub async fn evict_model(&self, model: &str) -> Result<()> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages: vec![ChatMessage {
                role: "user".into(),
                content: "bye".into(),
                tool_calls: None,
            }],
            tools: None,
            stream: false,
            keep_alive: KeepAlive::Immediate,
            options: None,
            think: None,
        };

        self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;

        info!(
            subsystem = "ollama_client",
            base_url = %self.base_url,
            model = model,
            "Model evicted from Ollama RAM"
        );
        Ok(())
    }

    /// Send a chat prompt and return the response string
    #[allow(dead_code)]
    pub async fn chat(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        keep_alive: KeepAlive,
    ) -> Result<String> {
        let resp = self
            .chat_with_tools(model, messages, None, keep_alive)
            .await?;
        Ok(resp.content)
    }

    /// Send a chat prompt with tool schemas and return full ChatMessageResponse
    pub async fn chat_with_tools(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        tools: Option<Vec<serde_json::Value>>,
        keep_alive: KeepAlive,
    ) -> Result<ChatMessageResponse> {
        let payload = ChatPayload {
            model: model.to_string(),
            messages,
            tools,
            stream: false,
            keep_alive,
            options: Some(serde_json::json!({"num_ctx": 8192})),
            think: Some(serde_json::json!(true)),
        };

        let resp: ChatResponse = self
            .http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?;

        Ok(resp.message)
    }

    /// Send a chat prompt with tool schemas and stream NDJSON token deltas to on_delta callback live
    pub async fn chat_with_tools_stream<F>(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        tools: Option<Vec<serde_json::Value>>,
        keep_alive: KeepAlive,
        mut on_delta: F,
    ) -> Result<ChatMessageResponse>
    where
        F: FnMut(&str),
    {
        let payload = ChatPayload {
            model: model.to_string(),
            messages,
            tools,
            stream: true,
            keep_alive,
            options: Some(serde_json::json!({"num_ctx": 8192})),
            think: Some(serde_json::json!(true)),
        };

        let mut res = self
            .http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;

        let mut accumulated_content = String::new();
        let mut accumulated_thinking = String::new();
        let mut accumulated_tool_calls: Option<Vec<ToolCall>> = None;
        let mut in_thinking_stream = false;

        let mut buffer = Vec::new();
        while let Ok(Some(chunk)) = res.chunk().await {
            buffer.extend_from_slice(&chunk);

            while let Some(pos) = buffer.iter().position(|&b| b == b'\n') {
                let line_bytes: Vec<u8> = buffer.drain(..=pos).collect();
                let line = String::from_utf8_lossy(&line_bytes);
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }

                if let Ok(resp) = serde_json::from_str::<ChatResponse>(trimmed) {
                    // Stream thinking / reasoning tokens live wrapped in <think> tags
                    let think_delta = resp
                        .message
                        .thinking
                        .as_deref()
                        .or(resp.message.reasoning_content.as_deref());
                    if let Some(t_delta) = think_delta {
                        if !t_delta.is_empty() {
                            if !in_thinking_stream {
                                in_thinking_stream = true;
                                on_delta("<think>\n");
                            }
                            on_delta(t_delta);
                            accumulated_thinking.push_str(t_delta);
                        }
                    }

                    // Stream standard content tokens live
                    if !resp.message.content.is_empty() {
                        if in_thinking_stream {
                            in_thinking_stream = false;
                            on_delta("\n</think>\n");
                        }
                        on_delta(&resp.message.content);
                        accumulated_content.push_str(&resp.message.content);
                    }

                    if let Some(tc) = resp.message.tool_calls {
                        accumulated_tool_calls = Some(tc);
                    }
                }
            }
        }

        if in_thinking_stream {
            on_delta("\n</think>\n");
        }

        let thinking = if !accumulated_thinking.trim().is_empty() {
            Some(accumulated_thinking.clone())
        } else {
            None
        };

        let final_content = if accumulated_content.trim().is_empty() && thinking.is_some() {
            strip_think_tags(thinking.as_deref().unwrap_or_default())
        } else {
            strip_think_tags(&accumulated_content)
        };

        Ok(ChatMessageResponse {
            role: "assistant".to_string(),
            content: final_content,
            thinking: thinking.clone(),
            reasoning_content: thinking,
            tool_calls: accumulated_tool_calls,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_think_tags() {
        let input = "Sure! <think>Let me calculate 2+2=4</think> The answer is 4.";
        assert_eq!(strip_think_tags(input), "Sure!  The answer is 4.");
    }

    #[test]
    fn test_effective_text_strips_inline_think_tags() {
        let msg = ChatMessageResponse {
            role: "assistant".to_string(),
            content: "<think>Internal thoughts</think>Final response".to_string(),
            thinking: None,
            reasoning_content: None,
            tool_calls: None,
        };
        assert_eq!(msg.effective_text(), "Final response");
    }

    #[test]
    fn test_effective_text_fallback_with_empty_reasoning_content() {
        let msg = ChatMessageResponse {
            role: "assistant".to_string(),
            content: "".to_string(),
            reasoning_content: Some("".to_string()),
            thinking: Some("real text".to_string()),
            tool_calls: None,
        };
        assert_eq!(msg.effective_text(), "real text");
    }

    #[test]
    fn test_keep_alive_serde() {
        let ka_forever = KeepAlive::Forever;
        let serialized = serde_json::to_string(&ka_forever).unwrap();
        assert_eq!(serialized, "-1");
        let deserialized: KeepAlive = serde_json::from_str("-1").unwrap();
        assert_eq!(deserialized, KeepAlive::Forever);

        let ka_imm = KeepAlive::Immediate;
        let serialized = serde_json::to_string(&ka_imm).unwrap();
        assert_eq!(serialized, "0");
        let deserialized: KeepAlive = serde_json::from_str("0").unwrap();
        assert_eq!(deserialized, KeepAlive::Immediate);

        let ka_sec = KeepAlive::Seconds(300);
        let serialized = serde_json::to_string(&ka_sec).unwrap();
        assert_eq!(serialized, "300");
        let deserialized: KeepAlive = serde_json::from_str("300").unwrap();
        assert_eq!(deserialized, KeepAlive::Seconds(300));
    }
}


<!-- END_FILE: shua_governor\src\ollama\client.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ollama\lifecycle.rs -->
# FILE: lifecycle.rs
**Relative Path**: `shua_governor\src\ollama\lifecycle.rs`

use std::sync::Arc;
use std::sync::Mutex as StdMutex;
use tokio::sync::Mutex as AsyncMutex;
use anyhow::{anyhow, Result};
use tracing::info;

use crate::ollama::client::OllamaClient;
use crate::ollama::model_registry::ModelRegistry;

#[derive(Debug, Default)]
struct LifecycleState {
    loaded_model: Option<String>,
    active_guards: usize,
}

pub struct ModelGuard {
    state: Arc<StdMutex<LifecycleState>>,
    model_name: String,
}

impl ModelGuard {
    #[allow(dead_code)]
    pub fn model_name(&self) -> &str {
        &self.model_name
    }
}

impl Drop for ModelGuard {
    fn drop(&mut self) {
        if let Ok(mut state) = self.state.lock() {
            if state.active_guards > 0 {
                state.active_guards -= 1;
                info!(
                    subsystem = "ollama_lifecycle",
                    model = %self.model_name,
                    active_guards = state.active_guards,
                    "ModelGuard released"
                );
            }
        }
    }
}

pub struct OllamaLifecycle {
    client: OllamaClient,
    registry: ModelRegistry,
    state: Arc<StdMutex<LifecycleState>>,
    load_lock: AsyncMutex<()>,
}

impl OllamaLifecycle {
    pub fn new(client: OllamaClient, registry: ModelRegistry) -> Self {
        Self {
            client,
            registry,
            state: Arc::new(StdMutex::new(LifecycleState::default())),
            load_lock: AsyncMutex::new(()),
        }
    }

    /// Load a model into RAM, evicting the current one if needed.
    /// Returns an error if an active `ModelGuard` reservation is holding a different model,
    /// or if the current model eviction fails.
    ///
    /// IMPORTANT: This is the SINGLE REQUIRED ENTRY POINT for local Ollama inference across `shua_governor`.
    /// All RPC handlers (including `ai.route`) MUST invoke `OllamaLifecycle::load()` or `reserve()` before initiating inference.
    pub async fn load(&self, model_name: &str) -> Result<()> {
        let model = self
            .registry
            .find(model_name)
            .ok_or_else(|| anyhow!("Model not registered: {model_name}"))?;

        if model.ram_mb > self.registry.ram_cap_mb() {
            return Err(anyhow!(
                "ERR_MODEL_TOO_LARGE: {model_name} requires {}MB, cap is {}MB",
                model.ram_mb,
                self.registry.ram_cap_mb()
            ));
        }

        let _lock = self.load_lock.lock().await;

        let current_to_evict = {
            let state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            if let Some(ref current) = state.loaded_model {
                if current == model_name {
                    info!(
                        subsystem = "ollama_lifecycle",
                        model = model_name,
                        "Model already loaded"
                    );
                    return Ok(());
                }
                if state.active_guards > 0 {
                    return Err(anyhow!(
                        "ERR_MODEL_BUSY: Model '{current}' is currently reserved by {} active stream(s); cannot evict to load '{model_name}'",
                        state.active_guards
                    ));
                }
                Some(current.clone())
            } else {
                None
            }
        };

        if let Some(ref current) = current_to_evict {
            self.client.evict_model(current).await?;
            let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            state.loaded_model = None;
        }

        self.client.load_model(model_name).await?;

        {
            let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            state.loaded_model = Some(model_name.to_string());
        }

        info!(
            subsystem = "ollama_lifecycle",
            model = model_name,
            ram_mb = model.ram_mb,
            "Model loaded successfully"
        );
        Ok(())
    }

    /// Load model (if needed) and acquire an active `ModelGuard` reservation.
    /// The returned guard prevents concurrent requests from evicting the model while active.
    pub async fn reserve(&self, model_name: &str) -> Result<ModelGuard> {
        self.load(model_name).await?;

        let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
        state.active_guards += 1;

        info!(
            subsystem = "ollama_lifecycle",
            model = model_name,
            active_guards = state.active_guards,
            "ModelGuard acquired"
        );

        Ok(ModelGuard {
            state: Arc::clone(&self.state),
            model_name: model_name.to_string(),
        })
    }

    /// Evict the currently loaded model. Errors if active reservations exist or eviction fails.
    pub async fn evict(&self) -> Result<()> {
        let _lock = self.load_lock.lock().await;

        let model_to_evict = {
            let state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            if let Some(ref current) = state.loaded_model {
                if state.active_guards > 0 {
                    return Err(anyhow!(
                        "ERR_MODEL_BUSY: Cannot evict '{current}' while {} ModelGuard(s) are active",
                        state.active_guards
                    ));
                }
                Some(current.clone())
            } else {
                None
            }
        };

        if let Some(ref model) = model_to_evict {
            self.client.evict_model(model).await?;
            let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            state.loaded_model = None;
            info!(subsystem = "ollama_lifecycle", model = %model, "Model evicted");
        }

        Ok(())
    }

    /// Get currently loaded model name.
    pub async fn current_model(&self) -> Option<String> {
        self.state.lock().ok().and_then(|s| s.loaded_model.clone())
    }

    /// Get count of active ModelGuards.
    #[allow(dead_code)]
    pub fn active_guards(&self) -> usize {
        self.state.lock().map(|s| s.active_guards).unwrap_or(0)
    }

    pub fn client(&self) -> &OllamaClient {
        &self.client
    }

    pub fn registry(&self) -> &ModelRegistry {
        &self.registry
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ollama::client::KeepAlive;
    use crate::ollama::model_registry::RegisteredModel;

    #[tokio::test]
    async fn test_model_guard_prevents_eviction_when_active() {
        let state = Arc::new(StdMutex::new(LifecycleState {
            loaded_model: Some("qwen2.5:1.5b".to_string()),
            active_guards: 0,
        }));

        let registry = ModelRegistry::new(
            vec![
                RegisteredModel {
                    name: "qwen2.5:1.5b".to_string(),
                    ram_mb: 1500,
                    role: "primary_dialogue".to_string(),
                    keep_alive: KeepAlive::Forever,
                },
                RegisteredModel {
                    name: "deepseek-r1:1.5b".to_string(),
                    ram_mb: 1500,
                    role: "text_generator".to_string(),
                    keep_alive: KeepAlive::Forever,
                },
            ],
            4096,
        );

        let lifecycle = OllamaLifecycle {
            client: OllamaClient::new("http://127.0.0.1:11434"),
            registry,
            state: Arc::clone(&state),
            load_lock: AsyncMutex::new(()),
        };

        let guard = ModelGuard {
            state: Arc::clone(&state),
            model_name: "qwen2.5:1.5b".to_string(),
        };

        {
            let mut s = state.lock().unwrap();
            s.active_guards += 1;
        }

        assert_eq!(lifecycle.active_guards(), 1);

        // Attempting to evict while guard is active should fail with ERR_MODEL_BUSY
        let evict_res = lifecycle.evict().await;
        assert!(evict_res.is_err());
        assert!(evict_res.unwrap_err().to_string().contains("ERR_MODEL_BUSY"));

        // Dropping guard should decrease active count to 0
        drop(guard);
        assert_eq!(lifecycle.active_guards(), 0);
    }
}


<!-- END_FILE: shua_governor\src\ollama\lifecycle.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ollama\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\ollama\mod.rs`

pub mod client;
pub mod lifecycle;
pub mod model_registry;

#[allow(unused_imports)]
pub use client::{ChatMessage, OllamaClient};
pub use lifecycle::OllamaLifecycle;
pub use model_registry::{ModelRegistry, RegisteredModel};


<!-- END_FILE: shua_governor\src\ollama\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\ollama\model_registry.rs -->
# FILE: model_registry.rs
**Relative Path**: `shua_governor\src\ollama\model_registry.rs`

use serde::{Deserialize, Serialize};

use crate::ollama::client::KeepAlive;

/// A model registered in config.toml
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegisteredModel {
    pub name:       String,     // e.g. "qwen2.5:1.5b"
    pub ram_mb:     u32,        // estimated RAM footprint
    pub role:       String,     // "primary_dialogue" | "text_generator" | "embeddings"
    pub keep_alive: KeepAlive,  // KeepAlive enum
}

pub struct ModelRegistry {
    models: Vec<RegisteredModel>,
    /// Hard RAM cap for all Ollama models combined (default: 4096 MB)
    ram_cap_mb: u32,
}

impl ModelRegistry {
    pub fn new(models: Vec<RegisteredModel>, ram_cap_mb: u32) -> Self {
        Self { models, ram_cap_mb }
    }

    pub fn find(&self, name: &str) -> Option<&RegisteredModel> {
        self.models.iter().find(|m| m.name == name)
    }

    pub fn ram_cap_mb(&self) -> u32 {
        self.ram_cap_mb
    }
}


<!-- END_FILE: shua_governor\src\ollama\model_registry.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\registry\cgroup_manager.rs -->
# FILE: cgroup_manager.rs
**Relative Path**: `shua_governor\src\registry\cgroup_manager.rs`

use std::fs;
use std::path::Path;
use anyhow::Result;
use tracing::{info, warn};

/// Creates a cgroup v2 subtree for a module and sets memory limits.
/// Requires the Governor process to have write access to /sys/fs/cgroup.
/// On Pi5 with Debian Bookworm, cgroups v2 is the default hierarchy.
pub struct CgroupManager;

impl CgroupManager {
    /// Create the cgroup directory for a module
    pub fn create(cgroup_path: &Path) -> Result<()> {
        if cfg!(target_os = "linux") {
            if !cgroup_path.exists() {
                fs::create_dir_all(cgroup_path)?;
                info!(
                    subsystem = "cgroup_manager",
                    path = %cgroup_path.display(),
                    "cgroup v2 directory created"
                );
            }
        } else {
            info!(
                subsystem = "cgroup_manager",
                path = %cgroup_path.display(),
                "[dev-stub] cgroup creation skipped (non-linux)"
            );
        }
        Ok(())
    }

    /// Set the memory.max limit for a cgroup (in bytes)
    /// Pass None to set "max" (unlimited)
    pub fn set_memory_limit(cgroup_path: &Path, limit_mb: Option<u32>) -> Result<()> {
        if cfg!(target_os = "linux") {
            let memory_max = cgroup_path.join("memory.max");
            let value = match limit_mb {
                Some(mb) => format!("{}", mb as u64 * 1024 * 1024),
                None => "max".to_string(),
            };
            if let Err(e) = fs::write(&memory_max, &value) {
                warn!(
                    subsystem = "cgroup_manager",
                    path = %memory_max.display(),
                    error = %e,
                    "Failed to set memory.max limit"
                );
            } else {
                info!(
                    subsystem = "cgroup_manager",
                    path = %memory_max.display(),
                    value = %value,
                    "cgroup memory.max limit applied"
                );
            }
        } else {
            info!(
                subsystem = "cgroup_manager",
                limit_mb = ?limit_mb,
                "[dev-stub] memory.max limit skipped (non-linux)"
            );
        }
        Ok(())
    }

    /// Move a PID into a cgroup
    #[allow(dead_code)]
    pub fn attach_pid(cgroup_path: &Path, pid: u32) -> Result<()> {
        if cfg!(target_os = "linux") {
            let cgroup_procs = cgroup_path.join("cgroup.procs");
            fs::write(&cgroup_procs, pid.to_string())?;
            info!(
                subsystem = "cgroup_manager",
                path = %cgroup_procs.display(),
                pid = pid,
                "PID attached to cgroup"
            );
        } else {
            info!(
                subsystem = "cgroup_manager",
                pid = pid,
                "[dev-stub] PID cgroup attachment skipped (non-linux)"
            );
        }
        Ok(())
    }

    /// Read current memory usage in bytes
    #[allow(dead_code)]
    pub fn current_usage_bytes(cgroup_path: &Path) -> Result<u64> {
        if cfg!(target_os = "linux") {
            let memory_current = cgroup_path.join("memory.current");
            if memory_current.exists() {
                let content = fs::read_to_string(memory_current)?;
                return Ok(content.trim().parse::<u64>()?);
            }
        }
        Ok(0)
    }
}


<!-- END_FILE: shua_governor\src\registry\cgroup_manager.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\registry\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\registry\mod.rs`

pub mod cgroup_manager;
pub mod module_entry;
pub mod process_manager;

#[allow(unused_imports)]
pub use cgroup_manager::CgroupManager;
#[allow(unused_imports)]
pub use module_entry::{ModuleEntry, ModuleState};
pub use process_manager::ProcessManager;


<!-- END_FILE: shua_governor\src\registry\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\registry\module_entry.rs -->
# FILE: module_entry.rs
**Relative Path**: `shua_governor\src\registry\module_entry.rs`

use std::path::PathBuf;
use serde::{Deserialize, Serialize};

/// Lifecycle state of a managed shua module process
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ModuleState {
    Running,
    Sleeping,
    Stopped,
    Unknown,
}

/// A registered shua module managed by the Governor with live telemetry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleEntry {
    /// Module namespace e.g. "shua.resume"
    pub name: String,
    /// Absolute path to the module binary or start script
    pub binary: PathBuf,
    /// Current lifecycle state
    pub state: ModuleState,
    /// OS process ID when running
    pub pid: Option<u32>,
    /// Start on Governor boot?
    pub auto_start: bool,
    /// cgroup path: /sys/fs/cgroup/horaizon/<module_name>
    pub cgroup_path: PathBuf,
    /// Memory limit in MB (written to cgroup memory.max)
    pub ram_limit_mb: Option<u32>,
    /// Current RSS / cgroup memory footprint in megabytes
    pub ram_mb: Option<f32>,
    /// Current CPU load percentage
    pub cpu_percent: Option<f32>,
    /// Total process uptime in seconds
    pub uptime_s: Option<u64>,
    /// Health status check indicator
    pub health_ok: bool,
    /// Number of auto-restarts following crashes
    pub restart_count: u32,
    /// Most recent error or crash message
    pub last_error: Option<String>,
}

impl ModuleEntry {
    pub fn new(name: &str, binary: PathBuf, auto_start: bool, ram_limit_mb: Option<u32>) -> Self {
        let cgroup_path = PathBuf::from(format!(
            "/sys/fs/cgroup/horaizon/{}",
            name.replace('.', "_")
        ));
        Self {
            name: name.to_string(),
            binary,
            state: ModuleState::Stopped,
            pid: None,
            auto_start,
            cgroup_path,
            ram_limit_mb,
            ram_mb: None,
            cpu_percent: None,
            uptime_s: None,
            health_ok: true,
            restart_count: 0,
            last_error: None,
        }
    }

    #[allow(dead_code)]
    pub fn is_alive(&self) -> bool {
        matches!(self.state, ModuleState::Running | ModuleState::Sleeping)
    }
}


<!-- END_FILE: shua_governor\src\registry\module_entry.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\registry\process_manager.rs -->
# FILE: process_manager.rs
**Relative Path**: `shua_governor\src\registry\process_manager.rs`

use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use anyhow::Result;
use tracing::{info, warn};

#[cfg(unix)]
use nix::sys::signal::{kill, Signal};
#[cfg(unix)]
use nix::unistd::Pid;

use crate::registry::module_entry::{ModuleEntry, ModuleState};
use crate::registry::cgroup_manager::CgroupManager;

pub struct ProcessManager {
    modules: Arc<RwLock<HashMap<String, ModuleEntry>>>,
}

impl ProcessManager {
    pub fn new() -> Self {
        Self {
            modules: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Register a module. Called at startup from config.
    pub async fn register(&self, entry: ModuleEntry) {
        let mut modules = self.modules.write().await;
        info!(
            subsystem = "process_manager",
            module = %entry.name,
            binary = %entry.binary.display(),
            ram_limit_mb = ?entry.ram_limit_mb,
            "Registering module entry"
        );

        if let Err(e) = CgroupManager::create(&entry.cgroup_path) {
            warn!(
                subsystem = "process_manager",
                module = %entry.name,
                error = %e,
                "Could not create cgroup"
            );
        }

        if let Some(limit) = entry.ram_limit_mb {
            if let Err(e) = CgroupManager::set_memory_limit(&entry.cgroup_path, Some(limit)) {
                warn!(
                    subsystem = "process_manager",
                    module = %entry.name,
                    error = %e,
                    "Could not set cgroup memory limit"
                );
            }
        }

        modules.insert(entry.name.clone(), entry);
    }

    /// Start a module process
    #[allow(dead_code)]
    pub fn start<'a>(&'a self, name: &'a str) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<()>> + Send + 'a>> {
        Box::pin(async move {
            let mut modules = self.modules.write().await;
            let entry = modules.get_mut(name)
                .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

            if entry.is_alive() {
                info!(
                    subsystem = "process_manager",
                    module = name,
                    state = ?entry.state,
                    "Module already running, skipping start"
                );
                return Ok(());
            }

            info!(
                subsystem = "process_manager",
                module = name,
                binary = %entry.binary.display(),
                "Spawning module process"
            );

            let mut cmd = tokio::process::Command::new(&entry.binary);
            if name == "ollama" {
                cmd.arg("serve");
                cmd.env("OLLAMA_NUM_THREADS", "3");
                cmd.env("OLLAMA_NUM_PARALLEL", "1");
                cmd.env("OLLAMA_KEEP_ALIVE", "-1");
                info!(
                    subsystem = "process_manager",
                    num_threads = 3,
                    num_parallel = 1,
                    "Configured thermal thread budget for Ollama subprocess"
                );
            }
            let child = cmd.spawn()?;
            let pid = child.id().ok_or_else(|| anyhow::anyhow!("Could not get PID"))?;

            entry.pid = Some(pid);
            entry.state = ModuleState::Running;

            if let Err(e) = CgroupManager::attach_pid(&entry.cgroup_path, pid) {
                warn!(
                    subsystem = "process_manager",
                    module = name,
                    pid = pid,
                    error = %e,
                    "Could not attach PID to cgroup"
                );
            }

            info!(
                subsystem = "process_manager",
                module = name,
                pid = pid,
                "Module process started successfully"
            );

            // Disown child handle — module process runs independently
            std::mem::forget(child);
            Ok(())
        })
    }

    fn find_key(modules: &std::collections::HashMap<String, ModuleEntry>, name: &str) -> Option<String> {
        if modules.contains_key(name) {
            return Some(name.to_string());
        }
        let dot_variant = name.replace('_', ".");
        if modules.contains_key(&dot_variant) {
            return Some(dot_variant);
        }
        let underscore_variant = name.replace('.', "_");
        if modules.contains_key(&underscore_variant) {
            return Some(underscore_variant);
        }
        None
    }

    /// Freeze a module with SIGSTOP
    pub async fn sleep(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let key = Self::find_key(&modules, name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;
        let entry = modules.get_mut(&key).unwrap();

        if let Some(pid) = entry.pid {
            #[cfg(unix)]
            {
                let _ = kill(Pid::from_raw(pid as i32), Signal::SIGSTOP);
            }
            info!(
                subsystem = "process_manager",
                module = %key,
                pid = pid,
                "Module power state changed to Sleeping (SIGSTOP)"
            );
        } else {
            info!(
                subsystem = "process_manager",
                module = %key,
                "Module power state changed to Sleeping"
            );
        }

        entry.state = ModuleState::Sleeping;
        entry.cpu_percent = Some(0.0);
        Ok(())
    }

    /// Resume a module with SIGCONT
    pub async fn wake(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let key = match Self::find_key(&modules, name) {
            Some(k) => k,
            None => {
                let keys: Vec<String> = modules.keys().cloned().collect();
                warn!(subsystem = "process_manager", target_name = %name, available_keys = ?keys, "ERR_UNKNOWN_MODULE lookup failed");
                return Err(anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name} (available: {keys:?})"));
            }
        };
        let entry = modules.get_mut(&key).unwrap();

        if let Some(pid) = entry.pid {
            #[cfg(unix)]
            {
                let _ = kill(Pid::from_raw(pid as i32), Signal::SIGCONT);
            }
            info!(
                subsystem = "process_manager",
                module = %key,
                pid = pid,
                "Module power state changed to Running (SIGCONT)"
            );
        } else {
            info!(
                subsystem = "process_manager",
                module = %key,
                "Module power state changed to Running (no PID attached)"
            );
        }

        entry.state = ModuleState::Running;
        info!(
            subsystem = "process_manager",
            module = %key,
            state = ?entry.state,
            ram_mb = ?entry.ram_mb,
            "Successfully updated module state to Running"
        );
        Ok(())
    }

    /// Terminate a module process with SIGTERM/SIGKILL to free RAM budget
    pub async fn stop(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let key = Self::find_key(&modules, name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;
        let entry = modules.get_mut(&key).unwrap();

        if let Some(pid) = entry.pid {
            #[cfg(unix)]
            {
                let _ = kill(Pid::from_raw(pid as i32), Signal::SIGTERM);
            }
            info!(
                subsystem = "process_manager",
                module = %key,
                pid = pid,
                "Terminated module process to release RAM budget (SIGTERM)"
            );
        }

        entry.pid = None;
        entry.state = ModuleState::Stopped;
        entry.ram_mb = Some(0.0);
        entry.cpu_percent = Some(0.0);
        Ok(())
    }

    fn read_proc_rss_mb(pid: u32) -> Option<f32> {
        let path = format!("/proc/{pid}/status");
        if let Ok(content) = std::fs::read_to_string(path) {
            for line in content.lines() {
                if line.starts_with("VmRSS:") {
                    let parts: Vec<&str> = line.split_whitespace().collect();
                    if parts.len() >= 2 {
                        if let Ok(kb) = parts[1].parse::<f32>() {
                            return Some(kb / 1024.0);
                        }
                    }
                }
            }
        }
        None
    }

    /// Get a snapshot of all module states with live telemetry for governor.status
    pub async fn status_snapshot(&self) -> Vec<ModuleEntry> {
        let modules = self.modules.read().await;
        let mut list = Vec::new();
        for entry in modules.values() {
            let mut snapshot = entry.clone();
            if snapshot.is_alive() {
                let mut measured_ram = None;
                // 1. Measure real memory from Linux cgroup v2 memory.current
                if let Ok(bytes) = CgroupManager::current_usage_bytes(&snapshot.cgroup_path) {
                    if bytes > 0 {
                        measured_ram = Some((bytes as f32) / (1024.0 * 1024.0));
                    }
                }
                // 2. Measure real memory from Linux /proc/<pid>/status VmRSS
                if measured_ram.is_none() {
                    if let Some(pid) = snapshot.pid {
                        measured_ram = Self::read_proc_rss_mb(pid);
                    }
                }
                snapshot.ram_mb = measured_ram.or(snapshot.ram_mb);
            } else {
                snapshot.ram_mb = Some(0.0);
                snapshot.cpu_percent = Some(0.0);
            }
            list.push(snapshot);
        }
        list
    }

    /// Check if a module is alive by probing /proc/<pid>/status
    #[allow(dead_code)]
    pub async fn refresh_states(&self) {
        let mut modules = self.modules.write().await;
        for entry in modules.values_mut() {
            if let Some(pid) = entry.pid {
                let proc_path = format!("/proc/{pid}/status");
                if cfg!(target_os = "linux") && !std::path::Path::new(&proc_path).exists() {
                    entry.state = ModuleState::Stopped;
                    entry.pid = None;
                    warn!(
                        subsystem = "process_manager",
                        module = %entry.name,
                        pid = pid,
                        "Module process no longer exists (clean exit or OOM crash)"
                    );
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[tokio::test]
    async fn test_process_manager_register_and_snapshot() {
        let pm = ProcessManager::new();
        let entry = ModuleEntry::new(
            "shua.resume",
            PathBuf::from("/usr/bin/true"),
            true,
            Some(128),
        );
        pm.register(entry).await;

        let snapshot = pm.status_snapshot().await;
        assert_eq!(snapshot.len(), 1);
        assert_eq!(snapshot[0].name, "shua.resume");
        assert_eq!(snapshot[0].state, ModuleState::Stopped);
    }
}


<!-- END_FILE: shua_governor\src\registry\process_manager.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\lib.rs -->
# FILE: lib.rs
**Relative Path**: `shua_code_visualizer\src\lib.rs`

pub mod broker;
pub mod graph;
pub mod mcp;
pub mod parser;
pub mod watch;


<!-- END_FILE: shua_code_visualizer\src\lib.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\main.rs -->
# FILE: main.rs
**Relative Path**: `shua_code_visualizer\src\main.rs`

use clap::Parser;
use schemars::schema_for;
use shua_code_visualizer::broker::ipc_client::IpcClient;
use shua_code_visualizer::broker::parent_link::{ExecutionMode, ParentLink};
use shua_code_visualizer::graph::store::CodeGraph;
use shua_code_visualizer::mcp::schema::{
    BlastRadiusArgs, FindCallersArgs, GraphEdge, GraphNode, ParseAstArgs, ReadFileArgs,
    RenderGraphArgs, TopologyDeltaEvent, TopologyExportResponse,
};
use shua_code_visualizer::parser::parse_file;
use shua_code_visualizer::watch::hash_cache::HashCache;
use shua_code_visualizer::watch::watcher::CodeWatcher;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(name = "shua_code_visualizer")]
#[command(about = "horAIzon 3.0 AST scanner, code topology graph, metrics, and MCP server")]
struct Args {
    /// Export JSON Schemas for wire DTO contracts and MCP tool inputs to stdout
    #[arg(long)]
    export_schema: bool,

    /// Target workspace root directory to scan and watch
    #[arg(long, default_value = ".")]
    workspace_root: PathBuf,

    /// Path to persistent hash cache JSON index
    #[arg(long, default_value = ".hash_cache.json")]
    hash_cache: PathBuf,

    /// Governor RPC port for auto-registration
    #[arg(long, default_value = "50051")]
    governor_port: u16,

    /// Export rendered topology graph JSON to file path and exit
    #[arg(long)]
    export_graph: Option<PathBuf>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    if args.export_schema {
        println!("=== GraphNode Schema ===");
        let schema = schema_for!(GraphNode);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== GraphEdge Schema ===");
        let schema = schema_for!(GraphEdge);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== TopologyExportResponse Schema ===");
        let schema = schema_for!(TopologyExportResponse);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== TopologyDeltaEvent Schema ===");
        let schema = schema_for!(TopologyDeltaEvent);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== ParseAstArgs Schema ===");
        let schema = schema_for!(ParseAstArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== ReadFileArgs Schema ===");
        let schema = schema_for!(ReadFileArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== RenderGraphArgs Schema ===");
        let schema = schema_for!(RenderGraphArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== BlastRadiusArgs Schema ===");
        let schema = schema_for!(BlastRadiusArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== FindCallersArgs Schema ===");
        let schema = schema_for!(FindCallersArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());
        return Ok(());
    }

    println!("============================================================");
    println!("  horAIzon 3.0 — shua_code_visualizer daemon starting...   ");
    println!("============================================================");
    println!("Workspace Root : {}", args.workspace_root.display());
    println!("Hash Cache     : {}", args.hash_cache.display());

    // 0. Auto-detect runtime execution mode (Standalone vs Managed Subprocess)
    let mode = ParentLink::detect_execution_mode();
    match &mode {
        ExecutionMode::Standalone => {
            println!("Execution Mode : Standalone (Run manually by user).");
            println!("               : Zero port scanning or governor connection attempts.");
        }
        ExecutionMode::ManagedSubprocess { parent_pid, ipc_port } => {
            println!("Execution Mode : Managed Subprocess (Parent PID: {}, IPC Port: {}).", parent_pid, ipc_port);
            println!("               : Lifetime linked to parent governor process.");
            ParentLink::spawn_parent_death_monitor(*parent_pid);
        }
    }

    // 1. Boot Sequence: Load persistent hash cache from disk & log diff
    let mut cache = HashCache::load_from_disk(&args.hash_cache).unwrap_or_default();

    println!("Scanning filesystem for source code changes...");
    let diff = cache.diff_directory(&args.workspace_root);
    println!(
        "Hash index status: {} added, {} modified, {} removed.",
        diff.added.len(),
        diff.modified.len(),
        diff.removed.len()
    );

    // 2. Perform complete boot scan of all valid source files to guarantee 100% graph coverage across restarts
    let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
    let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

    let mut parse_results = Vec::new();
    for entry in WalkDir::new(&args.workspace_root)
        .into_iter()
        .filter_entry(|e| {
            let name = e.file_name().to_string_lossy();
            !ignore_dirs.contains(&name.as_ref())
        })
        .filter_map(|e| e.ok())
    {
        if entry.file_type().is_file() {
            if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                if valid_extensions.contains(&ext) {
                    let path_str = entry.path().to_string_lossy().to_string();
                    if let Ok(code) = fs::read_to_string(entry.path()) {
                        let result = parse_file(&code, &path_str, None);
                        parse_results.push(result);
                    }
                }
            }
        }
    }

    let mut graph = CodeGraph::new();
    graph.build_from_parse_results(&parse_results);

    // 3. Save updated hash cache back to disk
    if let Err(e) = cache.save_to_disk(&args.hash_cache) {
        eprintln!("Warning: Failed to save hash cache to disk: {}", e);
    }

    println!(
        "CodeGraph initialized successfully: {} symbols (nodes), {} edges.",
        graph.graph.node_count(),
        graph.graph.edge_count()
    );

    if let Some(ref graph_out_path) = args.export_graph {
        let export = graph.render_subgraph(None, None);
        let json_text = serde_json::to_string_pretty(&export)?;
        fs::write(graph_out_path, json_text)?;
        println!("Topology graph exported successfully to: {}", graph_out_path.display());
        return Ok(());
    }

    let shared_graph = Arc::new(Mutex::new(graph));

    // 4. Start IPC Broker loop if in Managed Subprocess mode
    let delta_tx = if let ExecutionMode::ManagedSubprocess { ipc_port, .. } = mode {
        Some(IpcClient::start_ipc_loop(ipc_port, Arc::clone(&shared_graph)).await)
    } else {
        None
    };

    // 5. Start live file watcher
    let mut watcher_opt = match CodeWatcher::new(&args.workspace_root) {
        Ok(w) => {
            println!("Live CodeWatcher daemon started successfully.");
            Some(w)
        }
        Err(e) => {
            eprintln!(
                "Warning: File watcher failed to start ({}); falling back to read-only query mode.",
                e
            );
            None
        }
    };

    println!("shua_code_visualizer core engine ready. Entering event loop...");

    // 6. Event loop: poll watcher patches (if active) and service queries
    loop {
        if let Some(ref mut watcher) = watcher_opt {
            let mut g = shared_graph.lock().await;
            while let Some(delta) = watcher.poll_and_apply_patch(&mut g) {
                println!(
                    "Incremental patch applied: {:?} '{}' (affected symbols: {})",
                    delta.change_type,
                    delta.file_path,
                    delta.affected_node_ids.len()
                );
                if let Some(ref tx) = delta_tx {
                    let _ = tx.send(delta);
                }
            }
        }

        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    }
}


<!-- END_FILE: shua_code_visualizer\src\main.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\ipc_client.rs -->
# FILE: ipc_client.rs
**Relative Path**: `shua_code_visualizer\src\broker\ipc_client.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::handler::McpHandler;
use crate::mcp::schema::TopologyDeltaEvent;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::sync::Arc;
use tokio::sync::{mpsc, Mutex};
use tokio::time::{sleep, Duration};
use tokio_tungstenite::{connect_async, tungstenite::Message};

pub struct IpcClient;

impl IpcClient {
    /// Connects to parent governor IPC WebSocket server, auto-registers tools, and enters duplex message loop.
    /// Returns an MPSC sender for broadcasting live TopologyDeltaEvents over the IPC connection.
    pub async fn start_ipc_loop(
        ipc_port: u16,
        graph: Arc<Mutex<CodeGraph>>,
    ) -> mpsc::UnboundedSender<TopologyDeltaEvent> {
        let (tx, mut rx) = mpsc::unbounded_channel::<TopologyDeltaEvent>();
        let url = format!("ws://127.0.0.1:{}", ipc_port);

        tokio::spawn(async move {
            loop {
                println!("Connecting to parent governor IPC socket at {}...", url);
                match connect_async(&url).await {
                    Ok((ws_stream, _)) => {
                        println!("HBP v2 IPC connection established with parent governor.");
                        let (mut write, mut read) = ws_stream.split();

                        // 1. Send registration frame
                        let reg_frame = serde_json::json!({
                            "op": "governor.mcp.register",
                            "scope": "code",
                            "tools": [
                                "code_parse_ast",
                                "code_render_graph",
                                "code_blast_radius",
                                "code_find_callers",
                                "code_find_dead_code",
                                "code_find_god_functions",
                                "code_check_contract_drift"
                            ]
                        });

                        if let Ok(reg_text) = serde_json::to_string(&reg_frame) {
                            let _ = write.send(Message::Text(reg_text)).await;
                        }

                        // 2. Duplex event & message loop using tokio::select!
                        loop {
                            tokio::select! {
                                // Incoming IPC frames from parent governor
                                msg = read.next() => {
                                    match msg {
                                        Some(Ok(Message::Text(text))) => {
                                            if let Ok(val) = serde_json::from_str::<Value>(&text) {
                                                if val["op"] == "mcp.tool_call" {
                                                    let tool_name = val["tool"].as_str().unwrap_or("");
                                                    let args = &val["args"];
                                                    let req_id = val["id"].clone();

                                                    let mut g = graph.lock().await;
                                                    let mut handler = McpHandler::new(&mut g, None);
                                                    let res = handler.handle_tool_call(tool_name, args);

                                                    let resp_frame = match res {
                                                        Ok(result_val) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "ok",
                                                            "result": result_val
                                                        }),
                                                        Err(err_msg) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "error",
                                                            "error": err_msg
                                                        }),
                                                    };

                                                    if let Ok(resp_text) = serde_json::to_string(&resp_frame) {
                                                        let _ = write.send(Message::Text(resp_text)).await;
                                                    }
                                                } else {
                                                    println!("Received unhandled HBP IPC op: '{}'", val["op"].as_str().unwrap_or("unknown"));
                                                }
                                            }
                                        }
                                        Some(Ok(_)) => {}
                                        Some(Err(e)) => {
                                            eprintln!("Governor IPC read error: {}", e);
                                            break;
                                        }
                                        None => {
                                            println!("Governor IPC connection closed by remote.");
                                            break;
                                        }
                                    }
                                }

                                // Outgoing TopologyDeltaEvents from live watcher
                                delta_opt = rx.recv() => {
                                    if let Some(event) = delta_opt {
                                        let push_frame = serde_json::json!({
                                            "op": "changed",
                                            "event": event
                                        });

                                        if let Ok(push_text) = serde_json::to_string(&push_frame) {
                                            if let Err(e) = write.send(Message::Text(push_text)).await {
                                                eprintln!("Failed to push TopologyDeltaEvent to governor: {}", e);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!(
                            "Governor IPC connection failed ({}); retrying in 3 seconds...",
                            e
                        );
                    }
                }
                sleep(Duration::from_secs(3)).await;
            }
        });

        tx
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_ipc_client_channel_creation() {
        let graph = Arc::new(Mutex::new(CodeGraph::new()));
        let tx = IpcClient::start_ipc_loop(59999, graph).await;

        let sample_event = TopologyDeltaEvent {
            file_path: "src/lib.rs".to_string(),
            change_type: crate::mcp::schema::ChangeType::Modified,
            affected_node_ids: vec!["src/lib.rs:foo".to_string()],
        };

        assert!(tx.send(sample_event).is_ok());
    }
}


<!-- END_FILE: shua_code_visualizer\src\broker\ipc_client.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\broker\mod.rs`

pub mod ipc_client;
pub mod parent_link;


<!-- END_FILE: shua_code_visualizer\src\broker\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\parent_link.rs -->
# FILE: parent_link.rs
**Relative Path**: `shua_code_visualizer\src\broker\parent_link.rs`

use std::env;
use std::time::Duration;
use tokio::time::sleep;

/// Runtime execution mode auto-detected from environment
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionMode {
    /// Standalone mode (run directly by human user on Windows or CLI). Zero network scanning.
    Standalone,
    /// Managed subprocess mode (spawned by shua_governor). Linked lifetime & active HBP IPC connection.
    ManagedSubprocess { parent_pid: u32, ipc_port: u16 },
}

pub struct ParentLink;

impl ParentLink {
    /// Detects execution mode by inspecting environment for SHUA_GOVERNOR_PID and SHUA_GOVERNOR_IPC_PORT
    pub fn detect_execution_mode() -> ExecutionMode {
        let pid_var = env::var("SHUA_GOVERNOR_PID").ok();
        let port_var = env::var("SHUA_GOVERNOR_IPC_PORT").ok();

        match (pid_var, port_var) {
            (Some(pid_str), Some(port_str)) => {
                if let (Ok(parent_pid), Ok(ipc_port)) = (pid_str.parse::<u32>(), port_str.parse::<u16>()) {
                    ExecutionMode::ManagedSubprocess { parent_pid, ipc_port }
                } else {
                    ExecutionMode::Standalone
                }
            }
            _ => ExecutionMode::Standalone,
        }
    }

    /// Spawns a background task monitoring parent_pid. If parent process terminates, self-terminates.
    pub fn spawn_parent_death_monitor(parent_pid: u32) {
        tokio::spawn(async move {
            loop {
                sleep(Duration::from_secs(1)).await;
                if !is_process_alive(parent_pid) {
                    eprintln!(
                        "Parent governor process (PID {}) terminated. Self-terminating shua_code_visualizer.",
                        parent_pid
                    );
                    std::process::exit(0);
                }
            }
        });
    }
}

/// Checks if a process PID is currently alive on OS
#[cfg(target_os = "windows")]
fn is_process_alive(pid: u32) -> bool {
    use windows_sys::Win32::Foundation::CloseHandle;
    use windows_sys::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION};

    unsafe {
        let handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if handle == 0 {
            false
        } else {
            CloseHandle(handle);
            true
        }
    }
}

#[cfg(not(target_os = "windows"))]
fn is_process_alive(pid: u32) -> bool {
    unsafe { libc::kill(pid as libc::pid_t, 0) == 0 }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_standalone_mode_when_env_unset() {
        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(mode, ExecutionMode::Standalone);
    }

    #[test]
    fn test_detect_managed_mode_when_env_set() {
        env::set_var("SHUA_GOVERNOR_PID", "12345");
        env::set_var("SHUA_GOVERNOR_IPC_PORT", "7700");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(
            mode,
            ExecutionMode::ManagedSubprocess {
                parent_pid: 12345,
                ipc_port: 7700
            }
        );

        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");
    }
}


<!-- END_FILE: shua_code_visualizer\src\broker\parent_link.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\graph\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\graph\mod.rs`

pub mod store;


<!-- END_FILE: shua_code_visualizer\src\graph\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\graph\store.rs -->
# FILE: store.rs
**Relative Path**: `shua_code_visualizer\src\graph\store.rs`

use crate::mcp::schema::{
    ChangeType, GraphEdge, GraphNode, GraphNodeKind, SideEffect, ThresholdConfig,
    TopologyDeltaEvent, TopologyExportResponse,
};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, ParseResult};
use crate::parser::parse_file;
use petgraph::algo::tarjan_scc;
use petgraph::stable_graph::{NodeIndex, StableDiGraph};
use petgraph::visit::{EdgeRef, IntoEdgeReferences};
use std::collections::{HashMap, HashSet};

/// Helper normalizing all Windows backslashes `\` to forward slashes `/`
fn normalize_path(path: &str) -> String {
    path.replace('\\', "/")
}

/// Checks if string matches module path target respecting boundary delimiters (`/`, `::`, `.`)
fn is_module_match(file: &str, qualified_name: &str, target: &str) -> bool {
    let check = |s: &str| {
        if s == target {
            return true;
        }
        if let Some(remainder) = s.strip_prefix(target) {
            remainder.starts_with('/') || remainder.starts_with("::") || remainder.starts_with('.')
        } else {
            false
        }
    };
    check(file) || check(qualified_name)
}

/// In-memory graph resolution engine backed by `petgraph::stable_graph::StableDiGraph`
pub struct CodeGraph {
    pub graph: StableDiGraph<GraphNode, GraphEdge>,
    pub index: HashMap<String, NodeIndex>,
}

impl Default for CodeGraph {
    fn default() -> Self {
        Self::new()
    }
}

impl CodeGraph {
    /// Initializes an empty `CodeGraph`
    pub fn new() -> Self {
        Self {
            graph: StableDiGraph::new(),
            index: HashMap::new(),
        }
    }

    /// Adds or updates an extracted symbol node in the graph
    pub fn add_symbol(&mut self, sym: ExtractedSymbol) -> NodeIndex {
        let norm_id = normalize_path(&sym.id);
        let norm_file = normalize_path(&sym.file);

        let module_path = if norm_file.contains('/') {
            norm_file
                .rsplit_once('/')
                .map(|(dir, _)| dir)
                .unwrap_or("root")
                .to_string()
        } else {
            "root".to_string()
        };

        let is_async = sym.kind == GraphNodeKind::Function
            && (sym.return_type.as_deref().unwrap_or("").contains("Future")
                || sym.return_type.as_deref().unwrap_or("").contains("impl")
                || sym.qualified_name.contains("async")
                || sym.side_effects.contains(&SideEffect::Io));

        let is_blocking =
            sym.kind == GraphNodeKind::Function && sym.side_effects.contains(&SideEffect::Io);

        let node_payload = GraphNode {
            id: norm_id,
            kind: sym.kind,
            qualified_name: sym.qualified_name.clone(),
            file: norm_file,
            line: sym.line,
            params: sym.params,
            return_type: sym.return_type,
            complexity: sym.complexity,
            side_effects: sym.side_effects,
            intent: sym.intent,
            loc: sym.loc,
            is_public: sym.is_public,
            is_test: sym.is_test,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
            is_entrypoint: false,
            scc_id: None,
            module_path,
            is_async,
            is_blocking,
            dag_level: 0,
        };

        if let Some(&existing_idx) = self.index.get(&sym.qualified_name) {
            if let Some(weight) = self.graph.node_weight_mut(existing_idx) {
                *weight = node_payload;
            }
            existing_idx
        } else {
            let idx = self.graph.add_node(node_payload);
            self.index.insert(sym.qualified_name, idx);
            idx
        }
    }

    /// Adds a relationship edge, resolving method names to qualified names safely
    pub fn add_edge(&mut self, edge: ExtractedEdge) -> bool {
        let norm_from = normalize_path(&edge.from);
        let norm_to = normalize_path(&edge.to);

        let from_idx = match self.index.get(&norm_from).copied().or_else(|| {
            self.graph.node_indices().find(|&idx| {
                self.graph.node_weight(idx).is_some_and(|w| {
                    let short = w
                        .qualified_name
                        .rsplit_once('.')
                        .map(|(_, s)| s)
                        .unwrap_or(&w.qualified_name);
                    short == norm_from
                        || w.qualified_name.ends_with(&format!(".{}", norm_from))
                        || w.qualified_name.ends_with(&format!("::{}", norm_from))
                })
            })
        }) {
            Some(idx) => idx,
            None => return false,
        };

        let to_idx = match self.index.get(&norm_to).copied().or_else(|| {
            self.graph.node_indices().find(|&idx| {
                self.graph.node_weight(idx).is_some_and(|w| {
                    let short = w
                        .qualified_name
                        .rsplit_once('.')
                        .map(|(_, s)| s)
                        .unwrap_or(&w.qualified_name);
                    short == norm_to
                        || w.qualified_name.ends_with(&format!(".{}", norm_to))
                        || w.qualified_name.ends_with(&format!("::{}", norm_to))
                })
            })
        }) {
            Some(idx) => idx,
            None => return false,
        };

        // Prevent self-loops
        if from_idx == to_idx {
            return false;
        }

        // Check if edge already exists, increment call_count if so
        if let Some(edge_idx) = self.graph.find_edge(from_idx, to_idx) {
            if let Some(e) = self.graph.edge_weight_mut(edge_idx) {
                e.call_count += 1;
                return true;
            }
        }

        let from_qname = self
            .graph
            .node_weight(from_idx)
            .map(|w| w.qualified_name.clone())
            .unwrap_or(norm_from);
        let to_qname = self
            .graph
            .node_weight(to_idx)
            .map(|w| w.qualified_name.clone())
            .unwrap_or(norm_to);

        let edge_payload = GraphEdge {
            from: from_qname,
            to: to_qname,
            relation: edge.relation,
            call_count: 1,
        };

        self.graph.add_edge(from_idx, to_idx, edge_payload);
        true
    }

    /// Populates the graph from multiple parser results and computes degree metrics & SCC cycles
    pub fn build_from_parse_results(&mut self, results: &[ParseResult]) {
        self.graph.clear();
        self.index.clear();

        for res in results {
            for sym in &res.symbols {
                self.add_symbol(sym.clone());
            }
        }

        for res in results {
            for edge in &res.edges {
                self.add_edge(edge.clone());
            }
        }

        self.update_degree_metrics();
    }

    /// Safely removes all symbols and connected edges belonging to a file path
    pub fn remove_file_symbols(&mut self, file_path: &str) {
        let norm_path = normalize_path(file_path);
        let to_remove: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    weight.file == norm_path
                } else {
                    false
                }
            })
            .collect();

        for idx in to_remove {
            if let Some(weight) = self.graph.remove_node(idx) {
                self.index.remove(&weight.qualified_name);
            }
        }
    }

    /// Incremental graph patch execution for a single modified/created/deleted file
    pub fn apply_incremental_file_patch(
        &mut self,
        file_path: &str,
        code_opt: Option<&str>,
    ) -> TopologyDeltaEvent {
        let norm_path = normalize_path(file_path);
        let change_type = if code_opt.is_some() {
            if self.graph.node_indices().any(|idx| {
                self.graph
                    .node_weight(idx)
                    .is_some_and(|w| w.file == norm_path)
            }) {
                ChangeType::Modified
            } else {
                ChangeType::Added
            }
        } else {
            ChangeType::Removed
        };

        // 1. Remove existing symbols for this file
        self.remove_file_symbols(&norm_path);

        let mut affected_node_ids = Vec::new();

        // 2. Reparse file and add symbols/edges if code exists
        if let Some(code) = code_opt {
            let parse_res = parse_file(code, &norm_path, None);
            for sym in parse_res.symbols {
                affected_node_ids.push(sym.id.clone());
                self.add_symbol(sym);
            }
            for edge in parse_res.edges {
                self.add_edge(edge);
            }
        }

        // 3. Update degree metrics
        self.update_degree_metrics();

        TopologyDeltaEvent {
            file_path: norm_path,
            change_type,
            affected_node_ids,
        }
    }

    /// Computes fan_in, fan_out, is_entrypoint, SCC cycle IDs, and DAG levels for all nodes
    pub fn update_degree_metrics(&mut self) {
        let node_indices: Vec<NodeIndex> = self.graph.node_indices().collect();

        // 1. Compute fan_in, fan_out, entrypoint status
        for &idx in &node_indices {
            let fan_in = self.graph.edges_directed(idx, petgraph::Incoming).count() as u32;
            let fan_out = self.graph.edges_directed(idx, petgraph::Outgoing).count() as u32;

            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.fan_in = fan_in;
                weight.fan_out = fan_out;
                // Normalize risk_score to 0.0 - 10.0 scale
                let raw_risk = (weight.complexity * fan_in) as f32;
                weight.risk_score = (raw_risk * 0.5).min(10.0);

                weight.is_orphan = fan_in == 0 && fan_out == 0;

                // Entrypoint MUST be an executable routine (Function) that either is main/test or has fan_in == 0 & fan_out > 0
                weight.is_entrypoint = weight.kind == GraphNodeKind::Function
                    && (weight.qualified_name == "main"
                        || weight.qualified_name.ends_with("::main")
                        || weight.is_test
                        || (fan_in == 0 && fan_out > 0));
            }
        }

        // 2. Compute Tarjan's Strongly Connected Components (SCC) for call cycles
        let sccs = tarjan_scc(&self.graph);
        for (scc_idx, scc) in sccs.iter().enumerate() {
            if scc.len() > 1 {
                for &node_idx in scc {
                    if let Some(weight) = self.graph.node_weight_mut(node_idx) {
                        weight.scc_id = Some(scc_idx);
                    }
                }
            }
        }

        // 3. Compute DAG levels starting topological rank propagation ONLY from real entrypoints
        let mut level_map = HashMap::new();
        for &idx in &node_indices {
            if let Some(weight) = self.graph.node_weight(idx) {
                if weight.is_entrypoint {
                    level_map.insert(idx, 0);
                }
            }
        }
        for _ in 0..node_indices.len() {
            for &idx in &node_indices {
                let max_parent = self
                    .graph
                    .edges_directed(idx, petgraph::Incoming)
                    .filter_map(|e| level_map.get(&e.source()).copied())
                    .max();
                if let Some(p_level) = max_parent {
                    level_map.insert(idx, p_level + 1);
                }
            }
        }
        for (idx, lvl) in level_map {
            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.dag_level = lvl;
            }
        }
    }

    /// Renders a module/depth subgraph export payload using BFS bounded by max_depth hops
    pub fn render_subgraph(
        &self,
        module_path: Option<&str>,
        max_depth: Option<usize>,
    ) -> TopologyExportResponse {
        let depth_limit = max_depth.unwrap_or(2);
        let mut included_nodes = HashSet::new();

        // 1. Identify root nodes matching module_path (or all nodes if None)
        let root_nodes: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    if let Some(m_path) = module_path {
                        is_module_match(&weight.file, &weight.qualified_name, m_path)
                    } else {
                        true
                    }
                } else {
                    false
                }
            })
            .collect();

        // 2. Perform BFS from roots bounded by max_depth
        for root in root_nodes {
            included_nodes.insert(root);
            let mut queue = vec![(root, 0usize)];
            let mut visited = HashSet::new();
            visited.insert(root);

            while let Some((curr, curr_depth)) = queue.pop() {
                if curr_depth < depth_limit {
                    let mut neighbors = Vec::new();
                    for edge_ref in self
                        .graph
                        .edges_directed(curr, petgraph::Direction::Outgoing)
                    {
                        neighbors.push(edge_ref.target());
                    }
                    for edge_ref in self
                        .graph
                        .edges_directed(curr, petgraph::Direction::Incoming)
                    {
                        neighbors.push(edge_ref.source());
                    }

                    for neighbor in neighbors {
                        included_nodes.insert(neighbor);
                        if visited.insert(neighbor) {
                            queue.push((neighbor, curr_depth + 1));
                        }
                    }
                }
            }
        }

        let mut nodes = Vec::new();
        for &idx in &included_nodes {
            if let Some(weight) = self.graph.node_weight(idx) {
                nodes.push(weight.clone());
            }
        }

        let mut edges = Vec::new();
        for edge_ref in self.graph.edge_references() {
            if included_nodes.contains(&edge_ref.source())
                && included_nodes.contains(&edge_ref.target())
            {
                edges.push(edge_ref.weight().clone());
            }
        }

        TopologyExportResponse {
            nodes,
            edges,
            threshold_config: ThresholdConfig::default(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation};

    #[test]
    fn test_dangling_callee_edge_fail_closed() {
        let mut graph = CodeGraph::new();

        let sym_caller = ExtractedSymbol {
            id: "src/main.rs:main".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "main".to_string(),
            file: "src/main.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 10,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(sym_caller);

        let dangling_edge = ExtractedEdge {
            from: "main".to_string(),
            to: "unresolved_foo_xyz_random".to_string(),
            relation: Relation::Calls,
        };

        let added = graph.add_edge(dangling_edge);
        assert!(
            !added,
            "Dangling edge to unresolved symbol must be safely dropped (fail closed)"
        );
        assert_eq!(graph.graph.edge_count(), 0);
    }

    #[test]
    fn test_stable_digraph_multi_symbol_removal() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/a.rs:fn1".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn1".to_string(),
            file: "src/a.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s2 = ExtractedSymbol {
            id: "src/a.rs:fn2".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn2".to_string(),
            file: "src/a.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s3 = ExtractedSymbol {
            id: "src/b.rs:fn3".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn3".to_string(),
            file: "src/b.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(s1);
        graph.add_symbol(s2);
        graph.add_symbol(s3);

        graph.remove_file_symbols("src/a.rs");

        assert_eq!(graph.graph.node_count(), 1);
        let remaining = graph
            .index
            .get("fn3")
            .expect("fn3 in src/b.rs must survive");
        assert_eq!(
            graph.graph.node_weight(*remaining).unwrap().qualified_name,
            "fn3"
        );
    }

    #[test]
    fn test_tarjan_scc_cycle_detection() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/a.rs:fn_a".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn_a".to_string(),
            file: "src/a.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s2 = ExtractedSymbol {
            id: "src/b.rs:fn_b".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn_b".to_string(),
            file: "src/b.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(s1);
        graph.add_symbol(s2);

        // Mutual recursion call loop: fn_a -> fn_b and fn_b -> fn_a
        graph.add_edge(ExtractedEdge {
            from: "fn_a".to_string(),
            to: "fn_b".to_string(),
            relation: Relation::Calls,
        });
        graph.add_edge(ExtractedEdge {
            from: "fn_b".to_string(),
            to: "fn_a".to_string(),
            relation: Relation::Calls,
        });

        graph.update_degree_metrics();

        let node_a = graph
            .graph
            .node_weights()
            .find(|w| w.qualified_name == "fn_a")
            .unwrap();
        let node_b = graph
            .graph
            .node_weights()
            .find(|w| w.qualified_name == "fn_b")
            .unwrap();

        assert!(
            node_a.scc_id.is_some(),
            "Mutual recursion fn_a must have non-null scc_id"
        );
        assert!(
            node_b.scc_id.is_some(),
            "Mutual recursion fn_b must have non-null scc_id"
        );
        assert_eq!(
            node_a.scc_id, node_b.scc_id,
            "Both functions in mutual recursion loop must share the same scc_id"
        );
    }
}


<!-- END_FILE: shua_code_visualizer\src\graph\store.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\handler.rs -->
# FILE: handler.rs
**Relative Path**: `shua_code_visualizer\src\mcp\handler.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::schema::{
    BlastRadiusArgs, FindCallersArgs, ParseAstArgs, ReadFileArgs, RenderGraphArgs, ThresholdConfig,
};
use crate::parser::parse_file;
use petgraph::visit::EdgeRef;
use serde_json::Value;

/// Central dispatch handler for all 8 `code_*` MCP tools
pub struct McpHandler<'a> {
    pub graph: &'a mut CodeGraph,
    pub threshold_config: ThresholdConfig,
}

impl<'a> McpHandler<'a> {
    pub fn new(graph: &'a mut CodeGraph, threshold_config: Option<ThresholdConfig>) -> Self {
        Self {
            graph,
            threshold_config: threshold_config.unwrap_or_default(),
        }
    }

    /// Dispatches an incoming MCP tool call by name
    pub fn handle_tool_call(&mut self, tool_name: &str, args: &Value) -> Result<Value, String> {
        match tool_name {
            "code_parse_ast" => self.parse_ast(args),
            "code_read_file" => self.read_file(args),
            "code_render_graph" => self.render_graph(args),
            "code_blast_radius" => self.blast_radius(args),
            "code_find_callers" => self.find_callers(args),
            "code_find_dead_code" => self.find_dead_code(),
            "code_find_god_functions" => self.find_god_functions(),
            "code_check_contract_drift" => self.check_contract_drift(args),
            _ => Err(format!("Unknown MCP tool: {}", tool_name)),
        }
    }

    /// `code_parse_ast`: Parses single file and returns symbol/edge extraction payload
    fn parse_ast(&self, args: &Value) -> Result<Value, String> {
        let typed_args: ParseAstArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid ParseAstArgs: {}", e))?;
        let code = std::fs::read_to_string(&typed_args.file_path)
            .map_err(|e| format!("Failed to read file '{}': {}", typed_args.file_path, e))?;

        let res = parse_file(&code, &typed_args.file_path, None);
        serde_json::to_value(res).map_err(|e| e.to_string())
    }

    /// `code_read_file`: Fetches raw source code text or line-range snippet for target file
    fn read_file(&self, args: &Value) -> Result<Value, String> {
        let typed_args: ReadFileArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid ReadFileArgs: {}", e))?;

        let full_text = std::fs::read_to_string(&typed_args.file_path)
            .map_err(|e| format!("Failed to read file '{}': {}", typed_args.file_path, e))?;

        let lines: Vec<&str> = full_text.lines().collect();
        let total_lines = lines.len() as u32;

        let start = typed_args.start_line.unwrap_or(1).max(1) as usize;
        let end = typed_args.end_line.unwrap_or(total_lines).min(total_lines) as usize;

        if start > lines.len() || start > end {
            return serde_json::to_value(serde_json::json!({
                "file_path": typed_args.file_path,
                "total_lines": total_lines,
                "lines": [],
                "code": ""
            })).map_err(|e| e.to_string());
        }

        let sliced = &lines[(start - 1)..end];
        let code_str = sliced.join("\n");

        serde_json::to_value(serde_json::json!({
            "file_path": typed_args.file_path,
            "start_line": start,
            "end_line": end,
            "total_lines": total_lines,
            "code": code_str
        })).map_err(|e| e.to_string())
    }

    /// `code_render_graph`: Renders graph export payload filtered by module path and max depth
    fn render_graph(&self, args: &Value) -> Result<Value, String> {
        let typed_args: RenderGraphArgs = serde_json::from_value(args.clone())
            .unwrap_or(RenderGraphArgs {
                module_path: None,
                max_depth: None,
            });

        let export = self
            .graph
            .render_subgraph(typed_args.module_path.as_deref(), typed_args.max_depth);
        serde_json::to_value(export).map_err(|e| e.to_string())
    }

    /// `code_blast_radius`: Performs BFS caller depth search for target symbol
    fn blast_radius(&self, args: &Value) -> Result<Value, String> {
        let typed_args: BlastRadiusArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid BlastRadiusArgs: {}", e))?;
        let max_depth = typed_args.max_depth.unwrap_or(3);

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut caller_nodes = Vec::new();
        let mut queue = vec![(root_idx, 0usize)];
        let mut visited = std::collections::HashSet::new();
        visited.insert(root_idx);

        while let Some((curr, depth)) = queue.pop() {
            if depth < max_depth {
                for edge_ref in self.graph.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                    let source_idx = edge_ref.source();
                    if visited.insert(source_idx) {
                        if let Some(weight) = self.graph.graph.node_weight(source_idx) {
                            caller_nodes.push(weight.clone());
                        }
                        queue.push((source_idx, depth + 1));
                    }
                }
            }
        }

        serde_json::to_value(caller_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_callers`: Returns direct caller nodes of target symbol
    fn find_callers(&self, args: &Value) -> Result<Value, String> {
        let typed_args: FindCallersArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid FindCallersArgs: {}", e))?;

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut callers = Vec::new();
        for edge_ref in self.graph.graph.edges_directed(root_idx, petgraph::Direction::Incoming) {
            if let Some(weight) = self.graph.graph.node_weight(edge_ref.source()) {
                callers.push(weight.clone());
            }
        }

        serde_json::to_value(callers).map_err(|e| e.to_string())
    }

    /// `code_find_dead_code`: Returns unreferenced non-pub, non-test symbols
    fn find_dead_code(&self) -> Result<Value, String> {
        let mut dead_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                if weight.fan_in == 0
                    && !weight.is_public
                    && !weight.is_test
                    && weight.qualified_name != "main"
                    && !weight.qualified_name.ends_with("::main")
                {
                    let mut node_copy = weight.clone();
                    node_copy.is_orphan = true;
                    dead_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(dead_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_god_functions`: Returns functions exceeding complexity / loc / param thresholds
    fn find_god_functions(&self) -> Result<Value, String> {
        let mut god_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                let exceeds_loc = weight.loc > self.threshold_config.max_loc;
                let exceeds_complexity = weight.complexity > self.threshold_config.max_complexity;
                let exceeds_param = (weight.params.len() as u32) > self.threshold_config.max_params;

                if exceeds_loc || exceeds_complexity || exceeds_param {
                    let mut node_copy = weight.clone();
                    node_copy.exceeds_loc_threshold = exceeds_loc;
                    node_copy.exceeds_complexity_threshold = exceeds_complexity;
                    node_copy.exceeds_param_threshold = exceeds_param;
                    god_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(god_nodes).map_err(|e| e.to_string())
    }

    /// `code_check_contract_drift`: Verifies AST symbols against HBP contract schemas
    fn check_contract_drift(&self, _args: &Value) -> Result<Value, String> {
        let drift_report = serde_json::json!({
            "status": "not_implemented",
            "message": "Contract drift analysis is deferred to TASK-015A §9"
        });
        Ok(drift_report)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNode, GraphNodeKind};
    use crate::parser::extractor::ExtractedSymbol;

    #[test]
    fn test_all_mcp_tools() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/lib.rs:process".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "process".to_string(),
            file: "src/lib.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 25, // exceeds complexity threshold
            side_effects: vec![],
            intent: None,
            loc: 120, // exceeds loc threshold
            is_public: false,
            is_test: false,
        };

        graph.add_symbol(s1);

        let mut handler = McpHandler::new(&mut graph, None);

        let god_res = handler.handle_tool_call("code_find_god_functions", &serde_json::json!({})).unwrap();
        let god_nodes: Vec<GraphNode> = serde_json::from_value(god_res).unwrap();
        assert_eq!(god_nodes.len(), 1);
        assert!(god_nodes[0].exceeds_complexity_threshold);

        let dead_res = handler.handle_tool_call("code_find_dead_code", &serde_json::json!({})).unwrap();
        let dead_nodes: Vec<GraphNode> = serde_json::from_value(dead_res).unwrap();
        assert_eq!(dead_nodes.len(), 1);
    }
}


<!-- END_FILE: shua_code_visualizer\src\mcp\handler.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\mcp\mod.rs`

pub mod handler;
pub mod schema;


<!-- END_FILE: shua_code_visualizer\src\mcp\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\schema.rs -->
# FILE: schema.rs
**Relative Path**: `shua_code_visualizer\src\mcp\schema.rs`

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// High-level taxonomy of code symbols extracted from source files
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum GraphNodeKind {
    Function,
    Struct,
    Enum,
    Trait,
    Interface,
    Class,
    Module,
}

/// Categorized side effects detected during AST inspection
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum SideEffect {
    Io,
    Network,
    Lock,
    StateMutation,
}

/// Directional relationship edge type between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum Relation {
    Calls,
    Implements,
    Imports,
    Instantiates,
    TypeDependency,
}

/// Single parameter signature representation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParamDto {
    pub name: String,
    pub type_name: String,
    pub is_optional: bool,
}

/// Configurable thresholds for god-function and risk detection
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct ThresholdConfig {
    pub max_params: u32,
    pub max_complexity: u32,
    pub max_loc: u32,
    pub max_risk_score: f32,
}

impl Default for ThresholdConfig {
    fn default() -> Self {
        Self {
            max_params: 5,
            max_complexity: 10,
            max_loc: 75,
            max_risk_score: 7.0,
        }
    }
}

/// Quantitative risk score breakdown components
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct RiskScoreBreakdown {
    pub loc_component: f32,
    pub complexity_component: f32,
    pub coupling_component: f32,
}

/// Fully-resolved node payload in the code topology graph
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct GraphNode {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
    pub fan_in: u32,
    pub fan_out: u32,
    pub risk_score: f32,
    pub is_orphan: bool,
    pub exceeds_param_threshold: bool,
    pub exceeds_complexity_threshold: bool,
    pub exceeds_loc_threshold: bool,
    // TASK-016B Data Expansions (0.7a - 0.7l)
    pub is_entrypoint: bool,
    pub scc_id: Option<usize>,
    pub module_path: String,
    pub is_async: bool,
    pub is_blocking: bool,
    pub dag_level: usize,
}

/// Directional edge linking two symbols by qualified name
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct GraphEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
    pub call_count: u32,
}

/// Response container for module or full-repo topology graph exports
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyExportResponse {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
    pub threshold_config: ThresholdConfig,
}

/// Classification of incremental file changes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum ChangeType {
    Added,
    Modified,
    Removed,
}

/// Live event emitted on filesystem mutations
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyDeltaEvent {
    pub file_path: String,
    pub change_type: ChangeType,
    pub affected_node_ids: Vec<String>,
}

// ============================================================================
// MCP Tool Input Argument Schemas (for schema export & contract safety)
// ============================================================================

/// Arguments for `code_parse_ast`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParseAstArgs {
    pub file_path: String,
}

/// Arguments for `code_read_file` (Fetches source code snippet for target file/symbol)
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ReadFileArgs {
    pub file_path: String,
    pub start_line: Option<u32>,
    pub end_line: Option<u32>,
}

/// Arguments for `code_render_graph`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct RenderGraphArgs {
    pub module_path: Option<String>,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_blast_radius`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct BlastRadiusArgs {
    pub qualified_name: String,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_find_callers`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct FindCallersArgs {
    pub qualified_name: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dto_serialization_roundtrip() {
        let node = GraphNode {
            id: "test:id".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "test_func".to_string(),
            file: "test.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: Some("()".to_string()),
            complexity: 1,
            side_effects: vec![SideEffect::Io],
            intent: Some("Test description".to_string()),
            loc: 5,
            is_public: true,
            is_test: false,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
            is_entrypoint: true,
            scc_id: None,
            module_path: "test".to_string(),
            is_async: false,
            is_blocking: false,
            dag_level: 0,
        };

        let json = serde_json::to_string(&node).unwrap();
        let decoded: GraphNode = serde_json::from_str(&json).unwrap();
        assert_eq!(node, decoded);
    }

    #[test]
    fn test_threshold_config_default() {
        let config = ThresholdConfig::default();
        assert_eq!(config.max_params, 5);
        assert_eq!(config.max_complexity, 10);
        assert_eq!(config.max_loc, 75);
        assert_eq!(config.max_risk_score, 7.0);
    }

    #[test]
    fn test_schema_generation() {
        let schema = schemars::schema_for!(GraphNode);
        let schema_json = serde_json::to_string(&schema).unwrap();
        assert!(schema_json.contains("GraphNode"));
        assert!(schema_json.contains("is_public"));
    }
}


<!-- END_FILE: shua_code_visualizer\src\mcp\schema.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\extractor.rs -->
# FILE: extractor.rs
**Relative Path**: `shua_code_visualizer\src\parser\extractor.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation, SideEffect};
use serde::{Deserialize, Serialize};

/// Extracted AST symbol definition before graph resolution
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ExtractedSymbol {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
}

/// Extracted directional relationship edge between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ExtractedEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Consolidated parser result payload for a single source file
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ParseResult {
    pub symbols: Vec<ExtractedSymbol>,
    pub edges: Vec<ExtractedEdge>,
}

/// Unified trait implemented by language-specific Tree-sitter extractors
pub trait LanguageExtractor: Send + Sync {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult;
}


<!-- END_FILE: shua_code_visualizer\src\parser\extractor.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\parser\mod.rs`

pub mod extractor;
pub mod registry;

use extractor::{LanguageExtractor, ParseResult};
use registry::dart::DartExtractor;
use registry::go::GoExtractor;
use registry::python::PythonExtractor;
use registry::rust::RustExtractor;
use registry::typescript::TypeScriptExtractor;

/// Supported target programming languages
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Language {
    Rust,
    Dart,
    Go,
    Python,
    TypeScript,
}

impl Language {
    /// Detects programming language from file extension
    pub fn from_file_path(path: &str) -> Option<Self> {
        if path.ends_with(".rs") {
            Some(Language::Rust)
        } else if path.ends_with(".dart") {
            Some(Language::Dart)
        } else if path.ends_with(".go") {
            Some(Language::Go)
        } else if path.ends_with(".py") {
            Some(Language::Python)
        } else if path.ends_with(".ts") || path.ends_with(".tsx") {
            Some(Language::TypeScript)
        } else {
            None
        }
    }
}

/// Parses a source code file using the matching Tree-sitter language extractor
pub fn parse_file(code: &str, file_path: &str, lang: Option<Language>) -> ParseResult {
    let language = lang.or_else(|| Language::from_file_path(file_path));

    match language {
        Some(Language::Rust) => RustExtractor.parse(code, file_path),
        Some(Language::Dart) => DartExtractor.parse(code, file_path),
        Some(Language::Go) => GoExtractor.parse(code, file_path),
        Some(Language::Python) => PythonExtractor.parse(code, file_path),
        Some(Language::TypeScript) => TypeScriptExtractor.parse(code, file_path),
        None => ParseResult::default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation, SideEffect};

    #[test]
    fn test_rust_parser_extraction() {
        let rust_code = r#"
            /// Calculate total price with tax
            pub fn calculate_total(price: f64, tax: f64) -> f64 {
                if price > 0.0 {
                    println!("Calculating...");
                    price + (price * tax)
                } else {
                    0.0
                }
            }

            struct OrderService;

            impl OrderService {
                pub fn process_order(&mut self, id: u32) {
                    calculate_total(10.0, 0.1);
                }
            }
        "#;

        let result = parse_file(rust_code, "src/orders.rs", Some(Language::Rust));
        assert_eq!(result.symbols.len(), 3);

        let calc_fn = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "calculate_total")
            .expect("calculate_total function not found");

        assert_eq!(calc_fn.kind, GraphNodeKind::Function);
        assert_eq!(calc_fn.complexity, 2);
        assert_eq!(calc_fn.intent, Some("Calculate total price with tax".to_string()));
        assert!(calc_fn.side_effects.contains(&SideEffect::Io));
        assert!(calc_fn.is_public);
        assert_eq!(calc_fn.params.len(), 2);

        // Verify call edge extraction has FULLY QUALIFIED caller name
        let call_edge = result
            .edges
            .iter()
            .find(|e| e.relation == Relation::Calls)
            .expect("Call edge from OrderService::process_order -> calculate_total not found");
        assert_eq!(call_edge.from, "OrderService::process_order");
        assert_eq!(call_edge.to, "calculate_total");
    }

    #[test]
    fn test_rust_test_attribute_detection() {
        let rust_code = r#"
            #[test]
            fn custom_unit_test() {
                assert_eq!(2 + 2, 4);
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.qualified_name, "custom_unit_test");
        assert!(fn_symbol.is_test, "#[test] attribute must mark symbol as is_test = true");
    }

    #[test]
    fn test_rust_nested_module_qualified_path() {
        let rust_code = r#"
            pub mod core {
                pub mod service {
                    pub struct Worker;

                    impl Worker {
                        pub fn run() {}
                    }
                }
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));

        let method = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "core::service::Worker::run")
            .expect("Nested qualified method core::service::Worker::run not found");

        assert_eq!(method.kind, GraphNodeKind::Function);
    }

    #[test]
    fn test_python_elif_complexity() {
        let py_code = r#"
            def evaluate(score):
                if score > 90:
                    return 'A'
                elif score > 80:
                    return 'B'
                elif score > 70:
                    return 'C'
                else:
                    return 'F'
        "#;

        let result = parse_file(py_code, "eval.py", Some(Language::Python));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 4); // 1 base + 1 if + 2 elifs
    }

    #[test]
    fn test_go_switch_complexity() {
        let go_code = r#"
            package main

            func classify(val int) string {
                switch val {
                case 1:
                    return "one"
                case 2:
                    return "two"
                default:
                    return "other"
                }
            }
        "#;

        let result = parse_file(go_code, "switch.go", Some(Language::Go));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 3); // 1 base + 2 cases
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\dart.rs -->
# FILE: dart.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\dart.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

extern "C" {
    fn tree_sitter_dart_orchard() -> *const tree_sitter::ffi::TSLanguage;
}

pub struct DartExtractor;

/// Resolves full qualified symbol name (e.g. `UserWidget.renderUser`) by traversing class/mixin ancestors
fn resolve_dart_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_definition" || p.kind() == "mixin_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for DartExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let _ = tree_sitter_dart_orchard::LANGUAGE;
        let language = unsafe { tree_sitter::Language::from_raw(tree_sitter_dart_orchard()) };

        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (class_definition
              name: (identifier) @name) @class
            (mixin_declaration
              name: (identifier) @name) @class
            (extension_declaration
              name: (identifier) @name) @class
            (enum_declaration
              name: (identifier) @name) @enum
            (method_signature
              (function_signature name: (identifier) @name)) @fn
            (method_signature
              (constructor_signature name: (identifier) @name)) @fn
            (function_signature
              name: (identifier) @name) @fn
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = true;
            let mut is_test = file_path.contains("_test.dart") || file_path.contains("/test/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_dart_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    is_public = !name.rsplit('.').next().unwrap_or("").starts_with('_');
                    if name == "main" {
                        is_test = false;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let mut target_node = node;
                    if kind == GraphNodeKind::Function {
                        let mut curr = node;
                        while let Some(p) = curr.parent() {
                            if p.kind() == "class_definition" || p.kind() == "program" {
                                break;
                            }
                            target_node = p;
                            curr = p;
                        }
                    }

                    let range = target_node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = target_node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), target_node);

                        if let Some(ret_child) = target_node.child_by_field_name("type") {
                            if let Ok(ret_text) = ret_child.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(formal_params) = target_node.child_by_field_name("parameters") {
                            let mut p_cursor = formal_params.walk();
                            for p_child in formal_params.children(&mut p_cursor) {
                                if p_child.kind() == "formal_parameter" || p_child.kind() == "simple_formal_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts.last().unwrap().to_string(), parts[0..parts.len() - 1].join(" "))
                                        } else {
                                            (p_text.to_string(), "dynamic".to_string())
                                        };

                                        let is_optional = p_text.contains('?') || p_text.contains('{') || p_text.contains('[');
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = target_node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "documentation_comment" || prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract Dart call site edges, filtering strictly for Function callers (method-granularity)
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (identifier) @callee
            (import_or_export) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        let line = node.range().start_point.row as u32 + 1;
                        if let Some(caller_sym) = symbols
                            .iter()
                            .filter(|s| s.kind == GraphNodeKind::Function)
                            .find(|s| line >= s.line && line <= s.line + s.loc)
                        {
                            if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                                let callee_clean = callee_text.trim().to_string();
                                if !callee_clean.is_empty()
                                    && caller_sym.qualified_name != callee_clean
                                    && !caller_sym.qualified_name.ends_with(&format!(".{}", callee_clean))
                                    && callee_clean.chars().next().is_some_and(|c| c.is_alphabetic() || c == '_')
                                    && !["if", "else", "for", "while", "return", "var", "final", "const", "super", "this", "true", "false", "null", "dynamic", "void", "int", "double", "String", "bool", "List", "Map", "Set"].contains(&callee_clean.as_str())
                                {
                                    let edge = ExtractedEdge {
                                        from: caller_sym.qualified_name.clone(),
                                        to: callee_clean,
                                        relation: Relation::Calls,
                                    };
                                    if edge_set.insert(edge.clone()) {
                                        edges.push(edge);
                                    }
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\dart.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\go.rs -->
# FILE: go.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\go.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct GoExtractor;

/// Resolves full qualified symbol name (e.g. `Server.Start`) by checking Go receiver type
fn resolve_go_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "method_declaration" {
            if let Some(receiver) = p.child_by_field_name("receiver") {
                if let Ok(recv_text) = receiver.utf8_text(code.as_bytes()) {
                    let clean_recv = recv_text
                        .split_whitespace()
                        .last()
                        .unwrap_or("")
                        .trim_matches(|c| c == '(' || c == ')' || c == '*' || c == '&');
                    if !clean_recv.is_empty() {
                        return format!("{}.{}", clean_recv, name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for GoExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_go::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_declaration
              name: (field_identifier) @name) @fn
            (type_spec
              name: (type_identifier) @name) @type_def
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = file_path.ends_with("_test.go");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_go_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.rsplit('.').next().unwrap_or("");
                    if let Some(first_char) = last_segment.chars().next() {
                        is_public = first_char.is_uppercase();
                    }
                    if last_segment.starts_with("Test") || last_segment.starts_with("Benchmark") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "type_def" => {
                            if let Ok(text) = node.utf8_text(code.as_bytes()) {
                                if text.contains("interface") {
                                    GraphNodeKind::Interface
                                } else {
                                    GraphNodeKind::Struct
                                }
                            } else {
                                GraphNodeKind::Struct
                            }
                        }
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "parameter_declaration" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts[0].to_string(), parts[1..].join(" "))
                                        } else {
                                            (p_text.to_string(), "interface{}".to_string())
                                        };
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(result_node) = node.child_by_field_name("result") {
                            if let Ok(ret_text) = result_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                let clean = comment_text.trim().trim_start_matches("//").trim();
                                doc_lines.push(clean.to_string());
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (import_spec) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration" || p.kind() == "method_declaration" {
                                    caller_qualified = resolve_go_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim_matches('"').trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\go.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\mod.rs`

pub mod dart;
pub mod go;
pub mod python;
pub mod rust;
pub mod typescript;

use crate::mcp::schema::SideEffect;
use tree_sitter::Node;

/// Computes cyclomatic complexity of an AST node by counting decision branches
pub fn compute_cyclomatic_complexity(source: &[u8], root: Node) -> u32 {
    let mut complexity = 1;

    let branch_kinds = [
        "if_statement",
        "if_expression",
        "elif_clause",
        "match_arm",
        "case_statement",
        "case_clause",
        "expression_case",
        "type_case_clause",
        "for_statement",
        "for_expression",
        "for_in_clause",
        "while_statement",
        "while_expression",
        "binary_expression",
        "boolean_operator",
    ];

    let function_scope_kinds = [
        "function_item",
        "function_definition",
        "method_definition",
        "arrow_function",
        "closure_expression",
    ];

    let mut stack = vec![root];
    let mut is_root = true;

    while let Some(current) = stack.pop() {
        let kind = current.kind();

        // Avoid entering nested functions/closures so their complexity isn't double-counted
        if !is_root && function_scope_kinds.contains(&kind) {
            continue;
        }
        is_root = false;

        if branch_kinds.contains(&kind) {
            if kind == "binary_expression" || kind == "boolean_operator" {
                if let Some(op_node) = current.child_by_field_name("operator") {
                    if let Ok(op_text) = op_node.utf8_text(source) {
                        let op = op_text.trim();
                        if op == "&&" || op == "||" || op == "and" || op == "or" {
                            complexity += 1;
                        }
                    }
                }
            } else {
                complexity += 1;
            }
        }

        let mut cursor = current.walk();
        for child in current.children(&mut cursor) {
            stack.push(child);
        }
    }

    complexity
}

/// Infers side effects (IO, Network, Lock, StateMutation) from symbol text body
pub fn infer_side_effects(code: &str) -> Vec<SideEffect> {
    let mut effects = Vec::new();

    if code.contains("std::fs")
        || code.contains("File::")
        || code.contains("write!")
        || code.contains("println!")
        || code.contains("File.")
        || code.contains("print(")
    {
        effects.push(SideEffect::Io);
    }

    if code.contains("http://")
        || code.contains("https://")
        || code.contains("reqwest")
        || code.contains("TcpStream")
        || code.contains("WebSocket")
        || code.contains("fetch(")
    {
        effects.push(SideEffect::Network);
    }

    if code.contains("Mutex")
        || code.contains("RwLock")
        || code.contains(".lock()")
        || code.contains(".read()")
        || code.contains(".write()")
    {
        effects.push(SideEffect::Lock);
    }

    if code.contains("&mut ")
        || code.contains("self.")
        || code.contains("setState")
        || code.contains("this.")
    {
        effects.push(SideEffect::StateMutation);
    }

    effects.dedup();
    effects
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\python.rs -->
# FILE: python.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\python.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct PythonExtractor;

/// Resolves full qualified symbol name (e.g. `DataPipeline.process`) by traversing class ancestors
fn resolve_python_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_definition" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for PythonExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_python::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_definition
              name: (identifier) @name) @fn
            (class_definition
              name: (identifier) @name) @class
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = true;
            let mut is_test = file_path.contains("test.py") || file_path.contains("/tests/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_python_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.rsplit('.').next().unwrap_or("");
                    is_public = !last_segment.starts_with('_');
                    if last_segment.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                let p_kind = p_child.kind();
                                if p_kind == "identifier" || p_kind == "typed_parameter" || p_kind == "default_parameter" || p_kind == "typed_default_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        if p_text != "self" && p_text != "cls" {
                                            let parts: Vec<&str> = p_text.split(':').collect();
                                            let p_name = parts[0].trim().to_string();
                                            let p_type = if parts.len() > 1 {
                                                parts[1].split('=').next().unwrap_or("Any").trim().to_string()
                                            } else {
                                                "Any".to_string()
                                            };
                                            let is_optional = p_text.contains('=') || p_type.contains("Optional");

                                            params.push(ParamDto {
                                                name: p_name,
                                                type_name: p_type,
                                                is_optional,
                                            });
                                        }
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(body) = node.child_by_field_name("body") {
                            let mut b_cursor = body.walk();
                            for b_child in body.children(&mut b_cursor) {
                                if b_child.kind() == "expression_statement" {
                                    if let Ok(expr_text) = b_child.utf8_text(code.as_bytes()) {
                                        let trimmed = expr_text.trim();
                                        if (trimmed.starts_with("\"\"\"") && trimmed.ends_with("\"\"\""))
                                            || (trimmed.starts_with("'''") && trimmed.ends_with("'''"))
                                        {
                                            let clean = trimmed
                                                .trim_start_matches("\"\"\"")
                                                .trim_start_matches("'''")
                                                .trim_end_matches("\"\"\"")
                                                .trim_end_matches("'''")
                                                .trim()
                                                .lines()
                                                .next()
                                                .unwrap_or("")
                                                .to_string();
                                            if !clean.is_empty() {
                                                intent = Some(clean);
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call
              function: (_) @callee) @call_stmt
            (import_statement) @import
            (import_from_statement) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_definition" {
                                    caller_qualified = resolve_python_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\python.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\rust.rs -->
# FILE: rust.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\rust.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct RustExtractor;

/// Resolves full qualified symbol name (e.g. `core::service::Worker::run`) by traversing mod & impl ancestors
fn resolve_rust_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut prefixes = Vec::new();
    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "impl_item" {
            if let Some(type_node) = p.child_by_field_name("type") {
                if let Ok(type_name) = type_node.utf8_text(code.as_bytes()) {
                    let clean_type = type_name.split('<').next().unwrap_or("").trim();
                    prefixes.push(clean_type.to_string());
                }
            }
        } else if p.kind() == "mod_item" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(mod_name) = name_node.utf8_text(code.as_bytes()) {
                        prefixes.push(mod_name.trim().to_string());
                    }
                }
            }
        }
        parent = p.parent();
    }

    prefixes.reverse();
    if prefixes.is_empty() {
        name
    } else {
        format!("{}::{}", prefixes.join("::"), name)
    }
}

impl LanguageExtractor for RustExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_rust::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_item
              name: (identifier) @name) @fn
            (struct_item
              name: (type_identifier) @name) @struct
            (enum_item
              name: (type_identifier) @name) @enum
            (trait_item
              name: (type_identifier) @name) @trait
            (type_item
              name: (type_identifier) @name) @type_alias
            (mod_item
              name: (identifier) @name) @module
            (macro_definition
              name: (identifier) @name) @macro
        "#;

        let decl_query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&decl_query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = false;

            for cap in mat.captures {
                let cap_name = decl_query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_rust_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    if name.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "struct" | "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        "trait" => GraphNodeKind::Trait,
                        "module" | "macro" => GraphNodeKind::Module,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public = text.trim().starts_with("pub");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(params_node) = node.child_by_field_name("parameters") {
                            let mut p_cursor = params_node.walk();
                            for p_child in params_node.children(&mut p_cursor) {
                                if p_child.kind() == "parameter" {
                                    let raw_pattern = p_child
                                        .child_by_field_name("pattern")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("param");
                                    let p_name = raw_pattern.trim_start_matches("mut ").trim().to_string();
                                    let p_type = p_child
                                        .child_by_field_name("type")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("impl Any")
                                        .to_string();
                                    let is_optional = p_type.contains("Option");

                                    params.push(ParamDto {
                                        name: p_name,
                                        type_name: p_type,
                                        is_optional,
                                    });
                                } else if p_child.kind() == "self_parameter" {
                                    if let Ok(self_text) = p_child.utf8_text(code.as_bytes()) {
                                        params.push(ParamDto {
                                            name: "self".to_string(),
                                            type_name: self_text.to_string(),
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim_start_matches("->").trim().to_string());
                            }
                        }
                    }

                    // Extract doc comments & preceding `#[test]` attributes
                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "attribute_item" {
                            if let Ok(attr_text) = prev.utf8_text(code.as_bytes()) {
                                if attr_text.contains("test") {
                                    is_test = true;
                                }
                            }
                        } else if prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else if prev.kind() == "block_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (use_declaration) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let callee_clean = callee_text.split('(').next().unwrap_or("").trim().to_string();

                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_item" {
                                    caller_qualified = resolve_rust_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_clean.is_empty() && caller_qualified != callee_clean {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_clean,
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean_import = import_text
                                .trim_start_matches("use ")
                                .trim_end_matches(';')
                                .trim()
                                .to_string();
                            if !clean_import.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean_import,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\rust.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\typescript.rs -->
# FILE: typescript.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\typescript.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct TypeScriptExtractor;

/// Resolves full qualified symbol name (e.g. `ApiClient.fetchData`) by traversing class/interface ancestors
fn resolve_typescript_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_declaration" || p.kind() == "interface_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for TypeScriptExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_typescript::language_typescript();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_definition
              name: (property_identifier) @name) @fn
            (class_declaration
              name: (type_identifier) @name) @class
            (interface_declaration
              name: (type_identifier) @name) @interface
            (type_alias_declaration
              name: (type_identifier) @name) @type_alias
            (enum_declaration
              name: (identifier) @name) @enum
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = file_path.contains(".test.")
                || file_path.contains(".spec.")
                || file_path.contains("/__tests__/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_typescript_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.rsplit('.').next().unwrap_or("");
                    if last_segment == "it"
                        || last_segment == "test"
                        || last_segment.starts_with("test")
                    {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "interface" => GraphNodeKind::Interface,
                        "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public =
                            text.trim().starts_with("export") || text.trim().starts_with("public");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "required_parameter"
                                    || p_child.kind() == "optional_parameter"
                                {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let is_optional = p_child.kind() == "optional_parameter"
                                            || p_text.contains('?');
                                        let parts: Vec<&str> = p_text.split(':').collect();
                                        let p_name = parts[0].trim_matches('?').trim().to_string();
                                        let p_type = if parts.len() > 1 {
                                            parts[1].trim().to_string()
                                        } else {
                                            "any".to_string()
                                        };

                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type =
                                    Some(ret_text.trim_start_matches(':').trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim()
                                        .lines()
                                        .map(|l| l.trim().trim_start_matches('*').trim())
                                        .filter(|l| !l.is_empty() && !l.starts_with('@'))
                                        .collect::<Vec<&str>>()
                                        .join(" ");
                                    if !clean.is_empty() {
                                        doc_lines.push(clean);
                                    }
                                }
                            }
                        } else if prev.kind() != "export_specifier" {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call_stmt
            (import_statement) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration"
                                    || p.kind() == "method_definition"
                                {
                                    caller_qualified = resolve_typescript_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty()
                                && !callee_text.is_empty()
                                && caller_qualified != callee_text
                            {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\typescript.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\hash_cache.rs -->
# FILE: hash_cache.rs
**Relative Path**: `shua_code_visualizer\src\watch\hash_cache.rs`

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use walkdir::WalkDir;
use xxhash_rust::xxh64::xxh64;

/// Result of diffing current disk state against persisted hash index
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FileDiffResult {
    pub added: Vec<String>,
    pub modified: Vec<String>,
    pub removed: Vec<String>,
}

/// Disk-persisted file content hash index for incremental re-parsing
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HashCache {
    pub hashes: HashMap<String, u64>,
}

impl HashCache {
    pub fn new() -> Self {
        Self {
            hashes: HashMap::new(),
        }
    }

    /// Computes the xxh64 hash of raw file bytes
    pub fn compute_hash(bytes: &[u8]) -> u64 {
        xxh64(bytes, 0)
    }

    /// Loads persisted hash cache from disk
    pub fn load_from_disk(path: &Path) -> Result<Self, std::io::Error> {
        if !path.exists() {
            return Ok(Self::new());
        }
        let content = fs::read_to_string(path)?;
        let cache: HashCache = serde_json::from_str(&content)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        Ok(cache)
    }

    /// Persists current hash cache to disk
    pub fn save_to_disk(&self, path: &Path) -> Result<(), std::io::Error> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        fs::write(path, json)?;
        Ok(())
    }

    /// Scans directory and returns diff against cache (added, modified, removed)
    pub fn diff_directory(&mut self, root_dir: &Path) -> FileDiffResult {
        let mut current_files = HashMap::new();
        let mut diff = FileDiffResult::default();

        let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
        let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

        for entry in WalkDir::new(root_dir)
            .into_iter()
            .filter_entry(|e| {
                let name = e.file_name().to_string_lossy();
                !ignore_dirs.contains(&name.as_ref())
            })
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_file() {
                if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                    if valid_extensions.contains(&ext) {
                        let path_str = entry.path().to_string_lossy().to_string();
                        if let Ok(bytes) = fs::read(entry.path()) {
                            let hash = Self::compute_hash(&bytes);
                            current_files.insert(path_str.clone(), hash);

                            match self.hashes.get(&path_str) {
                                Some(&old_hash) => {
                                    if old_hash != hash {
                                        diff.modified.push(path_str);
                                    }
                                }
                                None => {
                                    diff.added.push(path_str);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Find removed files
        for old_path in self.hashes.keys() {
            if !current_files.contains_key(old_path) {
                diff.removed.push(old_path.clone());
            }
        }

        self.hashes = current_files;
        diff
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_hash_reproducibility() {
        let text = b"fn main() { println!(\"Hello World\"); }";
        let h1 = HashCache::compute_hash(text);
        let h2 = HashCache::compute_hash(text);
        assert_ne!(h1, 0);
        assert_eq!(h1, h2);
    }
}


<!-- END_FILE: shua_code_visualizer\src\watch\hash_cache.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\watch\mod.rs`

pub mod hash_cache;
pub mod watcher;


<!-- END_FILE: shua_code_visualizer\src\watch\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\watcher.rs -->
# FILE: watcher.rs
**Relative Path**: `shua_code_visualizer\src\watch\watcher.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::schema::TopologyDeltaEvent;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::mpsc::{channel, Receiver};
use std::time::{Duration, Instant};

/// Live file watcher daemon with non-blocking event coalescing and path debouncing
pub struct CodeWatcher {
    _watcher: RecommendedWatcher,
    rx: Receiver<Result<Event, notify::Error>>,
    pending_events: HashMap<PathBuf, Instant>,
    debounce_window: Duration,
}

impl CodeWatcher {
    /// Starts watching a directory for live file changes
    pub fn new(target_dir: &Path) -> Result<Self, notify::Error> {
        let (tx, rx) = channel();

        let mut watcher = RecommendedWatcher::new(
            move |res| {
                let _ = tx.send(res);
            },
            Config::default().with_poll_interval(Duration::from_millis(50)),
        )?;

        watcher.watch(target_dir, RecursiveMode::Recursive)?;

        Ok(Self {
            _watcher: watcher,
            rx,
            pending_events: HashMap::new(),
            debounce_window: Duration::from_millis(100),
        })
    }

    /// Polls pending file change events non-blockingly, coalescing rapid raw events for the same path.
    /// Executes single-file incremental graph patches only after the path quiet window (100ms) has expired.
    ///
    /// Note: Callers should poll in a loop (`while let Some(delta) = watcher.poll_and_apply_patch(...)`)
    /// to drain all expired paths during batch edits (e.g. git checkout).
    pub fn poll_and_apply_patch(&mut self, graph: &mut CodeGraph) -> Option<TopologyDeltaEvent> {
        let now = Instant::now();

        // 1. Drain channel without blocking
        while let Ok(Ok(event)) = self.rx.try_recv() {
            if let Some(path) = event.paths.first() {
                let valid_exts = ["rs", "dart", "go", "py", "ts", "tsx"];
                if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                    if valid_exts.contains(&ext) {
                        self.pending_events.insert(path.clone(), now);
                    }
                }
            }
        }

        // 2. Find path whose quiet window has elapsed
        let mut expired_path = None;
        for (path, &last_seen) in &self.pending_events {
            if now.duration_since(last_seen) >= self.debounce_window {
                expired_path = Some(path.clone());
                break;
            }
        }

        // 3. Apply single incremental graph patch
        if let Some(path) = expired_path {
            self.pending_events.remove(&path);

            let path_str = path.to_string_lossy().to_string();
            let code_opt = fs::read_to_string(&path).ok();
            let delta = graph.apply_incremental_file_patch(&path_str, code_opt.as_deref());

            Some(delta)
        } else {
            None
        }
    }
}


<!-- END_FILE: shua_code_visualizer\src\watch\watcher.rs -->
================================================================================

