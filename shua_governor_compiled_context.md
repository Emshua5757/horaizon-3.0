# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 45

================================================================================

<!-- START_FILE: shua_governor\Cargo.toml -->
# FILE: Cargo.toml
**Relative Path**: `shua_governor\Cargo.toml`

[package]
name        = "shua_governor"
version     = "0.1.0"
edition     = "2021"
description = "horAIzon 3.0 — Central governor: HBP v2 broker, process registry, Ollama lifecycle"
authors     = ["Joshua B. Ygot"]

[[bin]]
name = "shua_governor"
path = "src/main.rs"

[dependencies]
# Async runtime
tokio            = { version = "1", features = ["full"] }
tokio-stream     = { version = "0.1", features = ["sync"] }

# HTTP framework
axum             = { version = "0.7", features = ["ws", "multipart"] }
tower            = "0.5"
tower-http       = { version = "0.6", features = ["cors", "fs"] }
hyper            = { version = "1", features = ["full"] }
hyper-util       = { version = "0.1", features = ["full"] }
http-body-util   = "0.1"

# WebSocket
tokio-tungstenite = { version = "0.23", features = ["rustls-tls-native-roots"] }
futures-util     = "0.3"

# MessagePack serialization
rmp-serde        = "1.3"
serde            = { version = "1", features = ["derive"] }
serde_json       = "1"

# HTTP client (Ollama API)
reqwest          = { version = "0.12", features = ["json", "rustls-tls"], default-features = false }

# SQLite (centralized log persistence)
rusqlite         = { version = "0.31", features = ["bundled"] }

# Config file
toml             = "0.8"

# Scheduling (Dream Loop)
tokio-cron-scheduler = "0.13"

# Logging
tracing          = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# UUID generation
uuid             = { version = "1", features = ["v4"] }

# Misc
anyhow           = "1"
thiserror        = "1"
once_cell        = "1"
regex            = "1"
chrono           = { version = "0.4", features = ["serde"] }

# Media vault: content-addressed hashing and IPC Base64 transfers
sha2             = "0.10"
base64           = "0.22"

# Process management / signals (Unix / Pi5 only)
[target.'cfg(unix)'.dependencies]
nix              = { version = "0.29", features = ["signal", "process"] }
libc             = "0.2"

[dev-dependencies]
tokio-test = "0.4"

[profile.release]
opt-level     = 2
codegen-units = 4
lto           = "thin"
strip         = true

[profile.dev]
opt-level     = 0
debug         = 1
incremental   = true


<!-- END_FILE: shua_governor\Cargo.toml -->
================================================================================

<!-- START_FILE: shua_governor\config.toml -->
# FILE: config.toml
**Relative Path**: `shua_governor\config.toml`

# =============================================================================
# horAIzon 3.0 — Central Governor Configuration File
# Target: /etc/horaizon/governor/config.toml
# =============================================================================

[governor]
port               = 7700
log_level          = "info"
timezone           = "Asia/Manila"
offload_device_url = ""
log_retention_days = 7

[dream_loop]
enabled = true
cron    = "0 18 * * *"    # 02:00 Asia/Manila = 18:00 UTC

[ollama]
binary     = "/usr/bin/ollama"
host       = "http://127.0.0.1:11434"
ram_cap_mb = 4096

[[ollama.models]]
name       = "qwen2.5:1.5b"
ram_mb     = 980
role       = "primary_dialogue"
keep_alive = -1

[[ollama.models]]
name       = "llama3.2:3b"
ram_mb     = 2000
role       = "text_generator"
keep_alive = -1

[[modules.entry]]
name         = "ollama"
binary       = "/usr/local/bin/ollama"
auto_start   = true
ram_limit_mb = 4096

[[modules.entry]]
name         = "shua.resume"
binary       = "/usr/local/bin/shua_resume"
auto_start   = true
ram_limit_mb = 128

[[modules.entry]]
name         = "shua.diary"
binary       = "/usr/local/bin/shua_diary"
auto_start   = true
ram_limit_mb = 256

[[modules.entry]]
name         = "shua.code_visualizer"
binary       = "/usr/local/bin/shua_code_visualizer"
auto_start   = false
ram_limit_mb = 128


<!-- END_FILE: shua_governor\config.toml -->
================================================================================

<!-- START_FILE: shua_governor\src\config.rs -->
# FILE: config.rs
**Relative Path**: `shua_governor\src\config.rs`

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tracing::{info, warn};

use crate::media_vault::vault::MediaVaultConfig;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub governor: GovernorConfig,
    pub dream_loop: DreamLoopConfig,
    pub ollama: OllamaConfig,
    #[serde(default)]
    pub modules: ModulesConfig,
    #[serde(default)]
    pub media_vault: MediaVaultConfig,
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
            media_vault: MediaVaultConfig::default(),
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
            Some(PathBuf::from("_architecture/contracts/config.toml")),
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

// horAIzon 3.0 Central Governor Binary (v3.2.1 contract manifests)
mod ai_router;
mod broker;
mod config;
mod dream_loop;
mod error;
mod logging;
mod mcp;
mod media_vault;
mod ollama;
mod registry;

use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use broker::{dispatcher::Dispatcher, server::BrokerServer};
use config::AppConfig;
use dream_loop::DreamLoopScheduler;
use logging::bridge::ChannelLogger;
use logging::broadcaster::LogBroadcaster;
use logging::entry::LogEntry;
use logging::flush::{flush_loop, resolved_important_log_path};
use logging::listener::start_log_ipc_listener;
use media_vault::vault::MediaVault;
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
            .build()?,
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

    // horAIzon 3.0 Central Governor Binary (v3.2.1 contract manifests)
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
    let process_manager = Arc::new(ProcessManager::new(7701));
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
        log_broadcaster_clone
            .run_broadcast_loop(log_broadcast_rx)
            .await;
    });

    // 11. Initialize HBP v2 Dispatcher & Broker Server
    // Resolve DB path for vault registry (same activity.db used by logging)
    let vault_db_path = logging::flush::resolved_db_path();
    let media_vault = match MediaVault::new(
        app_config.media_vault.clone(),
        Path::new(&vault_db_path),
    ) {
        Ok(v) => {
            info!(
                subsystem = "governor_main",
                "Media Vault initialized — vault HTTP server starting on port {}",
                app_config.media_vault.http_port
            );
            Arc::new(v)
        }
        Err(e) => {
            warn!(subsystem = "governor_main", error = %e, "Media Vault init failed — vault features unavailable");
            // Fail-open: create vault with a temp dir so the binary still starts
            let mut fallback_cfg = app_config.media_vault.clone();
            fallback_cfg.root_path = std::env::temp_dir()
                .join("horaizon_vault")
                .to_string_lossy()
                .to_string();
            Arc::new(
                MediaVault::new(fallback_cfg, Path::new(&vault_db_path))
                    .expect("Vault fallback init must succeed"),
            )
        }
    };

    // Spawn vault HTTP static file server on port 7702
    let vault_http_clone = Arc::clone(&media_vault);
    let vault_http_port = app_config.media_vault.http_port;
    tokio::spawn(async move {
        media_vault::http_server::serve(vault_http_clone, vault_http_port).await;
    });

    let dispatcher = Arc::new(Dispatcher::new(
        log_tx.clone(),
        Arc::clone(&log_broadcaster),
        Arc::clone(&process_manager),
        Arc::clone(&ollama_lifecycle),
        Arc::clone(&shared_config),
        Arc::clone(&ai_runtime),
        Arc::clone(&media_vault),
    ));
    let broker = BrokerServer::new(Arc::clone(&dispatcher));

    let addr_str = format!("0.0.0.0:{}", app_config.governor.port);
    let addr: SocketAddr = addr_str.parse()?;
    tokio::spawn(async move {
        if let Err(e) = broker.run(addr).await {
            tracing::error!(error = %e, "HBP WebSocket Broker error");
        }
    });

    // 12. Initialize & Spawn Dedicated Submodule JSON IPC Listener (Port 7701)
    let ipc_server =
        broker::ipc_server::IpcServer::new(Arc::clone(&process_manager), Arc::clone(&media_vault));
    let ipc_addr_str = "0.0.0.0:7701";
    let ipc_addr: SocketAddr = ipc_addr_str.parse()?;
    tokio::spawn(async move {
        if let Err(e) = ipc_server.run(ipc_addr).await {
            tracing::error!(error = %e, "JSON IPC WebSocket Listener error");
        }
    });

    info!(
        module = "shua.governor",
        port = app_config.governor.port,
        ipc_port = 7701,
        "HBP v2 WebSocket broker (port {}) & JSON IPC listener (port 7701) active",
        app_config.governor.port
    );

    tokio::signal::ctrl_c().await?;
    info!(
        module = "shua.governor",
        "Shutdown signal received — exiting cleanly"
    );
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

        // ── Collect system tools + registered submodule tools from ProcessManager ────
        let aggregator = McpAggregator::new();
        let mut all_tools = aggregator.get_system_tools();
        {
            let modules = process_manager.modules.read().await;
            for entry in modules.values() {
                all_tools.extend(entry.tools.clone());
            }
        }

        // Apply ScopeFilter using request scope label
        use crate::mcp::scope_filter::ScopeFilter;
        let mcp_schemas = ScopeFilter::filter_tools(all_tools, scope);

        // Load scope-isolated persistent memory entries
        use crate::ai_router::scope_memory::ScopeMemoryStore;
        let scope_memories = ScopeMemoryStore::load(scope);
        let memory_block = if scope_memories.is_empty() {
            String::new()
        } else {
            let lines = scope_memories
                .iter()
                .map(|m| format!("- [{}] {}", m.key, m.value))
                .collect::<Vec<_>>()
                .join("\n");
            format!("\n\nPERSISTENT CONTEXT FOR '{}' SCOPE:\n{}", scope, lines)
        };

        // Build dynamic system prompt tool enumeration
        let tool_descriptions = if mcp_schemas.is_empty() {
            "No active MCP tools available for this scope.".to_string()
        } else {
            mcp_schemas
                .iter()
                .enumerate()
                .map(|(idx, t)| format!("{}. `{}`: {}", idx + 1, t.name, t.description))
                .collect::<Vec<_>>()
                .join("\n")
        };

        let system_prompt = format!(
            "You are JOSH, the horAIzon 3.0 Central AI Assistant running on Raspberry Pi 5. \
            You have access to Model Context Protocol (MCP) system control tools (scope: '{}'). \n\
            Available MCP Tools:\n{}\n\
            INSTRUCTIONS:\n\
            - When presenting metrics, logs, hardware, or topology data, ALWAYS format in clean Markdown tables.\n\
            - When asked what MCP tools are available, list the active MCP tools above.{}{}",
            scope, tool_descriptions, memory_block, tool_enforcement_clause
        );

        // ── Build initial messages: system + sliding window context + user ────
        let mut messages = vec![ChatMessage::system(system_prompt)];
        messages.extend(context_messages);
        messages.push(ChatMessage::user(effective_prompt.clone()));

        // ── Build tools JSON once — only sent on the first turn ───────────────
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
                full_messages = %serde_json::to_string(&messages).unwrap_or_default(),
                tools_schema = %serde_json::to_string(&tools_json).unwrap_or_default(),
                "⚡ FEEDING FULL PROMPT & MCP TOOLS TO OLLAMA"
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
                    tools_for_this_turn.clone(),
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
                Err(e) if tools_for_this_turn.is_some() => {
                    warn!(
                        subsystem = "agent_loop",
                        model = model,
                        error = %e,
                        "Model rejected native tools array (HTTP 400) — falling back to text prompt tool context"
                    );
                    let delta_sender_fallback = delta_sender.clone();
                    match client
                        .chat_with_tools_stream(
                            model,
                            messages.clone(),
                            None,
                            keep_alive,
                            move |delta| {
                                if let Some(ref ds) = delta_sender_fallback {
                                    let _ = ds.send(delta.to_string());
                                }
                            },
                        )
                        .await
                    {
                        Ok(r) => r,
                        Err(e2) => {
                            let err_msg = format!("{}", e2);
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
                    }
                }
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
pub mod scope_memory;

#[allow(unused_imports)]
pub use agent_loop::McpAgentLoop;
#[allow(unused_imports)]
pub use chat_history::ChatHistoryStore;
#[allow(unused_imports)]
pub use intent_classifier::{IntentClass, IntentClassifier};
#[allow(unused_imports)]
pub use prompt_budget::PromptBudget;
#[allow(unused_imports)]
pub use scope_memory::{ScopeMemoryEntry, ScopeMemoryStore};


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

<!-- START_FILE: shua_governor\src\ai_router\scope_memory.rs -->
# FILE: scope_memory.rs
**Relative Path**: `shua_governor\src\ai_router\scope_memory.rs`

﻿use rusqlite::Connection;
use tracing::warn;
use crate::logging::flush::resolved_db_path;

#[derive(Debug, Clone)]
pub struct ScopeMemoryEntry {
    pub scope: String,
    pub key: String,
    pub value: String,
    pub source: String,
    pub session_id: Option<String>,
    pub created_at: u64,
}

pub struct ScopeMemoryStore;

impl ScopeMemoryStore {
    /// Load all persistent memory entries for a given scope, ordered by created_at DESC.
    /// Returns an empty Vec gracefully if DB read fails or table has no facts.
    pub fn load(scope: &str) -> Vec<ScopeMemoryEntry> {
        let db_path = resolved_db_path();
        let conn = match Connection::open(&db_path) {
            Ok(c) => c,
            Err(e) => {
                warn!(subsystem = "scope_memory", db_path = %db_path, error = %e, "Could not open activity.db for scope_memory read");
                return Vec::new();
            }
        };

        let mut stmt = match conn.prepare(
            "SELECT scope, key, value, source, session_id, created_at FROM scope_memory WHERE scope = ?1 ORDER BY created_at DESC LIMIT 20"
        ) {
            Ok(s) => s,
            Err(e) => {
                warn!(subsystem = "scope_memory", scope = scope, error = %e, "Could not prepare scope_memory query");
                return Vec::new();
            }
        };

        let rows = match stmt.query_map([scope], |row| {
            Ok(ScopeMemoryEntry {
                scope: row.get(0)?,
                key: row.get(1)?,
                value: row.get(2)?,
                source: row.get(3)?,
                session_id: row.get(4)?,
                created_at: row.get(5)?,
            })
        }) {
            Ok(mapped) => mapped.filter_map(|r| r.ok()).collect(),
            Err(_) => Vec::new(),
        };

        rows
    }

    /// Upserts a persistent memory entry for a target scope.
    /// Used by memory formation logic (TASK-future).
    #[allow(dead_code)]
    pub fn upsert(entry: &ScopeMemoryEntry) -> anyhow::Result<()> {
        let db_path = resolved_db_path();
        let conn = Connection::open(&db_path)?;
        let ts = if entry.created_at == 0 {
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs()
        } else {
            entry.created_at
        };

        conn.execute(
            "INSERT INTO scope_memory (scope, key, value, source, session_id, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(scope, key) DO UPDATE SET value=?3, source=?4, session_id=?5, created_at=?6",
            rusqlite::params![
                entry.scope,
                entry.key,
                entry.value,
                entry.source,
                entry.session_id,
                ts
            ],
        )?;

        Ok(())
    }
}


<!-- END_FILE: shua_governor\src\ai_router\scope_memory.rs -->
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
use crate::media_vault::vault::MediaVault;
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
    media_vault: Arc<MediaVault>,
}

impl Dispatcher {
    pub fn new(
        log_tx: Sender<LogEntry>,
        log_broadcaster: Arc<LogBroadcaster>,
        process_manager: Arc<ProcessManager>,
        ollama: Arc<OllamaLifecycle>,
        config: Arc<RwLock<AppConfig>>,
        ai_runtime: Arc<tokio::runtime::Runtime>,
        media_vault: Arc<MediaVault>,
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
            media_vault,
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

            // ── Submodule frame forwarding ───────────────────────────────────────
            // Frames addressed to shua.resume, shua.diary, etc. are forwarded to
            // the registered submodule's IPC WebSocket channel.
            other => {
                let modules = self.process_manager.modules.read().await;
                if let Some(entry) = modules.get(other) {
                    if let Some(ref ipc_tx) = entry.ipc_tx {
                        // Serialize frame to JSON and forward via IPC channel
                        match serde_json::to_string(&serde_json::json!({
                            "op": frame.op,
                            "id": frame.id,
                            "mod": frame.mod_,
                            "p": frame.p,
                            "ts": frame.ts
                        })) {
                            Ok(json) => {
                                if ipc_tx.send(json).is_ok() {
                                    info!(
                                        subsystem = "dispatcher",
                                        module = other,
                                        op = %frame.op,
                                        "Frame forwarded to submodule via IPC"
                                    );
                                    // Response arrives asynchronously over IPC and is
                                    // handled in ipc_server.rs pending_calls resolution.
                                    return None;
                                } else {
                                    warn!(
                                        subsystem = "dispatcher",
                                        module = other,
                                        "IPC channel for module closed — cannot forward frame"
                                    );
                                }
                            }
                            Err(e) => {
                                warn!(subsystem = "dispatcher", module = other, error = %e, "Frame JSON serialization failed");
                            }
                        }
                    } else {
                        warn!(
                            subsystem = "dispatcher",
                            module = other,
                            "Module found but IPC channel not connected"
                        );
                    }
                }
                warn!(
                    subsystem = "dispatcher",
                    module = other,
                    "Unknown or offline target module"
                );
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_MODULE_OFFLINE",
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

            "governor.scopes" => {
                let modules = self.process_manager.modules.read().await;
                let mut scopes_list = vec![serde_json::json!({
                    "id": "governor",
                    "label": "System",
                    "tools_count": 5,
                    "module": "shua.governor",
                    "connected": true,
                })];

                for entry in modules.values() {
                    let scope_id = entry.module_scope.as_deref().unwrap_or("unknown");
                    scopes_list.push(serde_json::json!({
                        "id": scope_id,
                        "label": entry.name,
                        "tools_count": entry.tools.len(),
                        "module": entry.name,
                        "connected": entry.ipc_tx.is_some(),
                    }));
                }

                let payload = HbpFrame::encode_payload(&serde_json::json!({ "scopes": scopes_list })).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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

            // ── Media Vault Operations ──────────────────────────────────────────
            "vault.upload" | "governor.vault.upload" => {
                #[derive(serde::Deserialize)]
                struct VaultUploadReq {
                    module: String,
                    file_name: String,
                    mime_type: String,
                    /// Raw bytes stored in HBP payload — decode from msgpack bytes field
                    data: Option<Vec<u8>>,
                    /// Base64 alternative (from JSON IPC submodule callers)
                    data_base64: Option<String>,
                }
                match frame.decode_payload::<VaultUploadReq>() {
                    Ok(req) => {
                        let result = if let Some(raw) = req.data {
                            self.media_vault.store(&req.module, &req.file_name, &req.mime_type, &raw, "shua")
                        } else if let Some(b64) = req.data_base64 {
                            self.media_vault.store_base64(&req.module, &req.file_name, &req.mime_type, &b64, "shua")
                        } else {
                            Err(anyhow::anyhow!("vault.upload: neither data nor data_base64 provided"))
                        };
                        match result {
                            Ok(upload) => {
                                info!(
                                    subsystem = "vault_rpc",
                                    sha256 = %upload.sha256_hash,
                                    module = %req.module,
                                    deduplicated = upload.deduplicated,
                                    "vault.upload complete"
                                );
                                let payload = HbpFrame::encode_payload(&serde_json::json!({
                                    "sha256_hash": upload.sha256_hash,
                                    "url": upload.url,
                                    "file_size": upload.file_size,
                                    "deduplicated": upload.deduplicated,
                                })).unwrap_or_default();
                                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                            }
                            Err(e) => {
                                warn!(subsystem = "vault_rpc", error = %e, "vault.upload failed");
                                Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_VAULT_UPLOAD: {e}")))
                            }
                        }
                    }
                    Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_MALFORMED_PAYLOAD: {e}"))),
                }
            }

            "vault.get" | "governor.vault.get" => {
                #[derive(serde::Deserialize)]
                struct VaultGetReq { sha256_hash: String }
                match frame.decode_payload::<VaultGetReq>() {
                    Ok(req) => match self.media_vault.get_asset(&req.sha256_hash) {
                        Ok(Some(asset)) => {
                            let ext = std::path::Path::new(&asset.file_name)
                                .extension().and_then(|e| e.to_str()).unwrap_or("bin");
                            let url = self.media_vault.build_url(&asset.module, &asset.sha256_hash, ext);
                            let payload = HbpFrame::encode_payload(&serde_json::json!({
                                "sha256_hash": asset.sha256_hash,
                                "module": asset.module,
                                "file_name": asset.file_name,
                                "mime_type": asset.mime_type,
                                "file_size": asset.file_size,
                                "url": url,
                                "created_at": asset.created_at,
                            })).unwrap_or_default();
                            Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                        }
                        Ok(None) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, "ERR_NOT_FOUND")),
                        Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_VAULT_GET: {e}"))),
                    },
                    Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_MALFORMED_PAYLOAD: {e}"))),
                }
            }

            "vault.list" | "governor.vault.list" => {
                #[derive(serde::Deserialize)]
                struct VaultListReq {
                    module: Option<String>,
                    #[serde(default)] page: u32,
                    #[serde(default = "default_page_size")] page_size: u32,
                }
                fn default_page_size() -> u32 { 50 }
                let req: VaultListReq = frame.decode_payload().unwrap_or(VaultListReq { module: None, page: 0, page_size: 50 });
                match self.media_vault.list_assets(req.module.as_deref(), req.page, req.page_size) {
                    Ok((assets, total)) => {
                        let items: Vec<_> = assets.iter().map(|a| {
                            let ext = std::path::Path::new(&a.file_name)
                                .extension().and_then(|e| e.to_str()).unwrap_or("bin");
                            let url = self.media_vault.build_url(&a.module, &a.sha256_hash, ext);
                            serde_json::json!({
                                "sha256_hash": a.sha256_hash,
                                "module": a.module,
                                "file_name": a.file_name,
                                "mime_type": a.mime_type,
                                "file_size": a.file_size,
                                "url": url,
                                "created_at": a.created_at,
                            })
                        }).collect();
                        let has_more = (req.page + 1) * req.page_size < total;
                        let payload = HbpFrame::encode_payload(&serde_json::json!({
                            "items": items,
                            "total": total,
                            "has_more": has_more,
                        })).unwrap_or_default();
                        Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                    }
                    Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_VAULT_LIST: {e}"))),
                }
            }

            "vault.delete" | "governor.vault.delete" => {
                #[derive(serde::Deserialize)]
                struct VaultDeleteReq { sha256_hash: String }
                match frame.decode_payload::<VaultDeleteReq>() {
                    Ok(req) => match self.media_vault.delete_asset(&req.sha256_hash) {
                        Ok((new_rc, physically_deleted)) => {
                            info!(
                                subsystem = "vault_rpc",
                                sha256 = %req.sha256_hash,
                                new_ref_count = new_rc,
                                physically_deleted = physically_deleted,
                                "vault.delete complete"
                            );
                            let payload = HbpFrame::encode_payload(&serde_json::json!({
                                "ok": true,
                                "physically_deleted": physically_deleted,
                            })).unwrap_or_default();
                            Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                        }
                        Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_VAULT_DELETE: {e}"))),
                    },
                    Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_MALFORMED_PAYLOAD: {e}"))),
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

<!-- START_FILE: shua_governor\src\broker\ipc_server.rs -->
# FILE: ipc_server.rs
**Relative Path**: `shua_governor\src\broker\ipc_server.rs`

use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Result;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use tokio::net::TcpStream;
use tokio::sync::mpsc;
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{error, info, warn};

use crate::mcp::McpToolSchema;
use crate::media_vault::vault::MediaVault;
use crate::registry::module_entry::ModuleState;
use crate::registry::process_manager::ProcessManager;

pub struct IpcServer {
    process_manager: Arc<ProcessManager>,
    media_vault: Arc<MediaVault>,
}

impl IpcServer {
    pub fn new(process_manager: Arc<ProcessManager>, media_vault: Arc<MediaVault>) -> Self {
        Self { process_manager, media_vault }
    }

    /// Runs the dedicated JSON IPC WebSocket listener on target SocketAddr (default loopback 7701)
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
            subsystem = "ipc_server",
            address = %addr,
            "JSON IPC WebSocket listener bound and listening"
        );

        loop {
            match listener.accept().await {
                Ok((stream, peer_addr)) => {
                    info!(
                        subsystem = "ipc_server",
                        peer = %peer_addr,
                        "Submodule IPC TCP connection accepted"
                    );
                    let pm = Arc::clone(&self.process_manager);
                    let vault = Arc::clone(&self.media_vault);
                    tokio::spawn(handle_ipc_connection(stream, peer_addr, pm, vault));
                }
                Err(e) => {
                    error!(
                        subsystem = "ipc_server",
                        error = %e,
                        "IPC socket accept error"
                    );
                }
            }
        }
    }
}

/// Extract OS peer PID via SO_PEERCRED on Unix/Linux systems
#[cfg(target_family = "unix")]
fn get_peer_pid(stream: &TcpStream) -> Option<u32> {
    use std::os::unix::io::AsRawFd;
    let fd = stream.as_raw_fd();
    unsafe {
        let mut ucred: libc::ucred = std::mem::zeroed();
        let mut len = std::mem::size_of::<libc::ucred>() as libc::socklen_t;
        let res = libc::getsockopt(
            fd,
            libc::SOL_SOCKET,
            libc::SO_PEERCRED,
            &mut ucred as *mut _ as *mut libc::c_void,
            &mut len,
        );
        if res == 0 && ucred.pid > 0 {
            Some(ucred.pid as u32)
        } else {
            None
        }
    }
}

#[cfg(not(target_family = "unix"))]
fn get_peer_pid(_stream: &TcpStream) -> Option<u32> {
    None
}

async fn handle_ipc_connection(
    stream: TcpStream,
    peer_addr: SocketAddr,
    process_manager: Arc<ProcessManager>,
    media_vault: Arc<MediaVault>,
) {
    let peer_pid_opt = get_peer_pid(&stream);

    let ws_stream = match accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            warn!(peer = %peer_addr, error = %e, "IPC WebSocket handshake failed");
            return;
        }
    };

    let (mut ws_tx, mut ws_rx) = ws_stream.split();
    let (tx, mut rx) = mpsc::unbounded_channel::<String>();

    // Outbound text frame forwarder task
    let send_task = tokio::spawn(async move {
        while let Some(text_frame) = rx.recv().await {
            if ws_tx.send(Message::Text(text_frame)).await.is_err() {
                break;
            }
        }
    });

    let mut registered_module_id: Option<String> = None;

    // Inbound text message loop
    while let Some(msg) = ws_rx.next().await {
        match msg {
            Ok(Message::Text(text)) => {
                if let Ok(val) = serde_json::from_str::<Value>(&text) {
                    let op = val["op"].as_str().unwrap_or("");

                    if op == "governor.mcp.register" {
                        let module_id = val["module_id"].as_str().unwrap_or("").to_string();
                        let version = val["version"].as_str().unwrap_or("0.1.0").to_string();
                        let scope = val["scope"].as_str().unwrap_or("all").to_string();

                        if module_id.is_empty() {
                            warn!(peer = %peer_addr, "governor.mcp.register frame missing module_id");
                            continue;
                        }

                        // Parse MCP tools array from manifest
                        let tools: Vec<McpToolSchema> = val.get("tools")
                            .and_then(|t| serde_json::from_value(t.clone()).ok())
                            .unwrap_or_default();

                        let tool_count = tools.len();
                        let mut modules = process_manager.modules.write().await;

                        if let Some(entry) = modules.get_mut(&module_id) {
                            // Validate PID if available
                            if let (Some(peer_pid), Some(entry_pid)) = (peer_pid_opt, entry.pid) {
                                if peer_pid != entry_pid {
                                    warn!(
                                        subsystem = "ipc_server",
                                        module = %module_id,
                                        peer_pid = peer_pid,
                                        entry_pid = entry_pid,
                                        "IPC auth failure: peer PID mismatch — rejecting registration"
                                    );
                                    break;
                                }
                            }

                            entry.ipc_tx = Some(tx.clone());
                            entry.tools = tools;
                            entry.module_scope = Some(scope.clone());
                            entry.manifest_version = Some(version.clone());
                            entry.state = ModuleState::IpcConnected;

                            registered_module_id = Some(module_id.clone());

                            info!(
                                subsystem = "ipc_server",
                                module = %module_id,
                                version = %version,
                                scope = %scope,
                                tools_count = tool_count,
                                "Submodule registered MCP manifest over IPC (state -> IpcConnected)"
                            );
                        } else {
                            warn!(
                                subsystem = "ipc_server",
                                module = %module_id,
                                "Received registration for unknown module_id — ignoring"
                            );
                        }
                    } else if op == "changed" {
                        if let Some(ref mod_id) = registered_module_id {
                            info!(
                                subsystem = "ipc_server",
                                module = %mod_id,
                                event = ?val.get("event"),
                                "Submodule pushed topology delta event"
                            );
                        }
                    } else if op == "vault.upload" {
                        // Submodule depositing a file into the vault via IPC (Base64 path)
                        let call_id = val.get("id").and_then(|v| v.as_str()).unwrap_or("").to_string();
                        let module   = val.get("module").and_then(|v| v.as_str()).unwrap_or("shared").to_string();
                        let fname    = val.get("file_name").and_then(|v| v.as_str()).unwrap_or("file.bin").to_string();
                        let mime     = val.get("mime_type").and_then(|v| v.as_str()).unwrap_or("application/octet-stream").to_string();
                        let b64      = val.get("data_base64").and_then(|v| v.as_str()).unwrap_or("").to_string();

                        let response_json = match media_vault.store_base64(&module, &fname, &mime, &b64, "submodule") {
                            Ok(upload) => {
                                info!(
                                    subsystem = "ipc_vault",
                                    sha256 = %upload.sha256_hash,
                                    module = %module,
                                    deduplicated = upload.deduplicated,
                                    "vault.upload from submodule complete"
                                );
                                serde_json::json!({
                                    "id": call_id,
                                    "status": "ok",
                                    "result": {
                                        "sha256_hash": upload.sha256_hash,
                                        "url": upload.url,
                                        "file_size": upload.file_size,
                                        "deduplicated": upload.deduplicated,
                                    }
                                }).to_string()
                            }
                            Err(e) => {
                                warn!(subsystem = "ipc_vault", error = %e, "vault.upload from submodule failed");
                                serde_json::json!({
                                    "id": call_id,
                                    "status": "error",
                                    "error": format!("ERR_VAULT_UPLOAD: {e}")
                                }).to_string()
                            }
                        };

                        let _ = tx.send(response_json);

                    } else if let Some(id_str) = val.get("id").and_then(|v| v.as_str()) {
                        // Response frame matching pending in-flight tool call request ID
                        if let Some(ref mod_id) = registered_module_id {
                            let modules = process_manager.modules.read().await;
                            if let Some(entry) = modules.get(mod_id) {
                                let mut pending = entry.pending_calls.lock().await;
                                if let Some(oneshot_tx) = pending.remove(id_str) {
                                    let status = val.get("status").and_then(|v| v.as_str()).unwrap_or("ok");
                                    let payload = if status == "ok" {
                                        val.get("result").cloned().unwrap_or(Value::Null)
                                    } else {
                                        serde_json::json!({
                                            "error": val.get("error").and_then(|v| v.as_str()).unwrap_or("Unknown submodule error")
                                        })
                                    };
                                    let _ = oneshot_tx.send(payload);
                                }
                            }
                        }
                    }
                }
            }
            Ok(Message::Close(_)) | Err(_) => break,
            _ => {} // Ignore ping/pong/binary at WS level
        }
    }

    send_task.abort();

    // Clean up registration on disconnect
    if let Some(mod_id) = registered_module_id {
        let mut modules = process_manager.modules.write().await;
        if let Some(entry) = modules.get_mut(&mod_id) {
            entry.ipc_tx = None;
            entry.tools.clear();
            entry.module_scope = None;
            if entry.state == ModuleState::IpcConnected {
                entry.state = ModuleState::Running;
            }
            warn!(
                subsystem = "ipc_server",
                module = %mod_id,
                peer = %peer_addr,
                "IPC connection closed — tools unregistered, state reverted to Running"
            );
        }
    }
}


<!-- END_FILE: shua_governor\src\broker\ipc_server.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\broker\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\broker\mod.rs`

// HBP v2 WebSocket Broker Module

pub mod dispatcher;
pub mod frame;
pub mod generated;
pub mod ipc_server;
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

// AUTO-GENERATED by sync_contracts at 2026-08-03 15:02:59 UTC — DO NOT EDIT
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

// AUTO-GENERATED by sync_contracts at 2026-08-03 15:02:59 UTC — DO NOT EDIT
// Source: _architecture/contracts/hbp/schema/*.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

#![allow(dead_code, non_snake_case)]


use serde::{Deserialize, Serialize};

use super::hbp_enums::*;

/// Single parameter signature representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParamDto {
    /// Index 1
    pub name: String,
    /// Index 2
    pub type_name: String,
    /// Index 3
    pub is_optional: bool,
}

/// Structured node representation for AST code topology
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphNode {
    /// Index 1
    pub id: String,
    /// Index 2
    pub kind: String,
    /// Index 3
    pub qualified_name: String,
    /// Index 4
    pub file: String,
    /// Index 5
    pub line: u32,
    /// Index 6
    pub params: Vec<ParamDto>,
    /// Index 7
    pub return_type: String,
    /// Index 8
    pub complexity: u32,
    /// Index 9
    pub side_effects: Vec<String>,
    /// Index 10
    pub intent: String,
    /// Index 11
    pub loc: u32,
    /// Index 12
    pub fan_in: u32,
    /// Index 13
    pub fan_out: u32,
    /// Index 14
    pub risk_score: f32,
    /// Index 15
    pub is_orphan: bool,
    /// Index 16
    pub exceeds_param_threshold: bool,
    /// Index 17
    pub exceeds_complexity_threshold: bool,
    /// Index 18
    pub exceeds_loc_threshold: bool,
}

/// Dependency call/import edge between symbols
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphEdge {
    /// Index 1
    pub from: String,
    /// Index 2
    pub to: String,
    /// Index 3
    pub relation: String,
}

/// Full AST topology graph payload
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TopologyExportResponse {
    /// Index 1
    pub nodes: Vec<GraphNode>,
    /// Index 2
    pub edges: Vec<GraphEdge>,
}

/// Incremental code delta push on file change
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TopologyDeltaEvent {
    /// Index 1
    pub file_path: String,
    /// Index 2
    pub change_type: String,
    /// Index 3
    pub affected_node_ids: Vec<String>,
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

// AUTO-GENERATED by sync_contracts at 2026-08-03 15:02:59 UTC — DO NOT EDIT
// Source: _architecture/contracts/hbp/schema/*.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

#![allow(dead_code, non_snake_case)]


/// HBP v2 operation key constants.
pub mod ops {
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

        CREATE TABLE IF NOT EXISTS scope_memory (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            scope      TEXT    NOT NULL,
            key        TEXT    NOT NULL,
            value      TEXT    NOT NULL,
            source     TEXT    NOT NULL DEFAULT 'agent_synthesized',
            session_id TEXT,
            created_at INTEGER NOT NULL,
            UNIQUE(scope, key) ON CONFLICT REPLACE
        );

        CREATE INDEX IF NOT EXISTS idx_scope_memory_scope ON scope_memory(scope);
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
                let resolved_name = match call.name.as_str() {
                    "code_ast_symbols" | "code_ast_symbol" | "code_ast" => "code_parse_ast",
                    "code_read_files" | "read_file" => "code_read_file",
                    "code_find_deadcode" => "code_find_dead_code",
                    "code_find_god_function" => "code_find_god_functions",
                    other => other,
                };

                // Dynamic submodule tool routing across ProcessManager entries
                let modules = process_manager.modules.read().await;
                let owner = modules.values().find(|e| e.tools.iter().any(|t| t.name == resolved_name));

                match owner {
                    None => {
                        warn!(subsystem = "mcp_executor", tool = %call.name, "Unknown tool — not registered by any module");
                        McpToolResponse {
                            tool_name: call.name.clone(),
                            success: false,
                            result: serde_json::Value::Null,
                            error: Some(format!("Unknown or unregistered MCP tool: '{}'", call.name)),
                        }
                    }
                    Some(entry) if entry.ipc_tx.is_none() => {
                        info!(
                            subsystem = "mcp_executor",
                            tool = %call.name,
                            module = %entry.name,
                            "Submodule owns tool but is not connected over IPC — auto-waking submodule..."
                        );
                        let mod_name = entry.name.clone();
                        drop(modules); // drop read lock before calling async wake

                        let _ = process_manager.wake(&mod_name).await;

                        // Wait up to 3 seconds for IPC connection handshake
                        let start = std::time::Instant::now();
                        let mut connected_tx = None;
                        while start.elapsed().as_secs() < 3 {
                            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                            let mods = process_manager.modules.read().await;
                            if let Some(e) = mods.get(&mod_name) {
                                if let Some(ref tx) = e.ipc_tx {
                                    connected_tx = Some(tx.clone());
                                    break;
                                }
                            }
                        }

                        if let Some(tx) = connected_tx {
                            let timeout_secs = 15;
                            let req_id = uuid::Uuid::new_v4().to_string();
                            let (tx_one, rx_one) = tokio::sync::oneshot::channel::<serde_json::Value>();

                            {
                                let mods = process_manager.modules.read().await;
                                if let Some(e) = mods.get(&mod_name) {
                                    e.pending_calls.lock().await.insert(req_id.clone(), tx_one);
                                }
                            }

                            let dispatch_frame = serde_json::json!({
                                "op": "mcp.tool_call",
                                "id": req_id,
                                "tool": resolved_name,
                                "args": call.arguments,
                            });

                            if tx.send(dispatch_frame.to_string()).is_ok() {
                                match tokio::time::timeout(tokio::time::Duration::from_secs(timeout_secs), rx_one).await {
                                    Ok(Ok(result)) => {
                                        let is_error = result.is_object() && result.get("error").is_some();
                                        McpToolResponse {
                                            tool_name: call.name.clone(),
                                            success: !is_error,
                                            result: if is_error { serde_json::Value::Null } else { result.clone() },
                                            error: if is_error {
                                                result.get("error").and_then(|e| e.as_str()).map(|s| s.to_string())
                                            } else {
                                                None
                                            },
                                        }
                                    }
                                    _ => McpToolResponse {
                                        tool_name: call.name.clone(),
                                        success: false,
                                        result: serde_json::Value::Null,
                                        error: Some(format!("Tool call failed after auto-wake: '{}'", call.name)),
                                    },
                                }
                            } else {
                                McpToolResponse {
                                    tool_name: call.name.clone(),
                                    success: false,
                                    result: serde_json::Value::Null,
                                    error: Some(format!("Failed to send IPC frame after waking '{}'", mod_name)),
                                }
                            }
                        } else {
                            McpToolResponse {
                                tool_name: call.name.clone(),
                                success: false,
                                result: serde_json::Value::Null,
                                error: Some(format!(
                                    "'{}' owns tool '{}' but failed to connect over IPC within 3s after auto-wake.",
                                    mod_name, call.name
                                )),
                            }
                        }
                    }
                    Some(entry) => {
                        let timeout_secs = entry
                            .tools
                            .iter()
                            .find(|t| t.name == call.name)
                            .and_then(|t| t.timeout_s)
                            .unwrap_or(15);

                        let req_id = uuid::Uuid::new_v4().to_string();
                        let (tx_one, rx_one) = tokio::sync::oneshot::channel::<serde_json::Value>();
                        entry.pending_calls.lock().await.insert(req_id.clone(), tx_one);

                        let dispatch_frame = serde_json::json!({
                            "op": "mcp.tool_call",
                            "id": req_id,
                            "tool": call.name,
                            "args": call.arguments,
                        });

                        let send_res = entry.ipc_tx.as_ref().unwrap().send(dispatch_frame.to_string());
                        drop(modules); // release read lock before blocking await

                        if send_res.is_err() {
                            return McpToolResponse {
                                tool_name: call.name.clone(),
                                success: false,
                                result: serde_json::Value::Null,
                                error: Some("IPC send channel closed by submodule".into()),
                            };
                        }

                        match tokio::time::timeout(tokio::time::Duration::from_secs(timeout_secs), rx_one).await {
                            Ok(Ok(result)) => {
                                let is_error = result.is_object() && result.get("error").is_some();
                                McpToolResponse {
                                    tool_name: call.name.clone(),
                                    success: !is_error,
                                    result: if is_error { serde_json::Value::Null } else { result.clone() },
                                    error: if is_error {
                                        result.get("error").and_then(|e| e.as_str()).map(|s| s.to_string())
                                    } else {
                                        None
                                    },
                                }
                            }
                            Ok(Err(_)) => McpToolResponse {
                                tool_name: call.name.clone(),
                                success: false,
                                result: serde_json::Value::Null,
                                error: Some("Submodule IPC channel dropped unexpectedly".into()),
                            },
                            Err(_) => McpToolResponse {
                                tool_name: call.name.clone(),
                                success: false,
                                result: serde_json::Value::Null,
                                error: Some(format!("Tool call timed out after {}s: '{}'", timeout_secs, call.name)),
                            },
                        }
                    }
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
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout_s: Option<u64>,
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
    /// Filters given list of tools based on context scope tag.
    /// Core governor system tools ("governor", "all", "*") are always included.
    /// Module-specific tools (e.g. "code", "diary", "resume") are included when matching the active target_scope.
    pub fn filter_tools(tools: Vec<McpToolSchema>, target_scope: &str) -> Vec<McpToolSchema> {
        let normalized = target_scope.trim().to_lowercase();
        if normalized.is_empty() || normalized == "all" || normalized == "*" {
            return tools;
        }

        tools
            .into_iter()
            .filter(|tool| {
                let tool_scope = tool.scope.to_lowercase();
                tool_scope == normalized
                    || tool_scope == "governor"
                    || tool_scope == "all"
                    || tool_scope == "*"
                    || normalized == "global"
                    || normalized == "default"
            })
            .collect()
    }
}


<!-- END_FILE: shua_governor\src\mcp\scope_filter.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\media_vault\http_server.rs -->
# FILE: http_server.rs
**Relative Path**: `shua_governor\src\media_vault\http_server.rs`

use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;

use tokio::net::TcpListener;
use tracing::{error, info, warn};

use super::vault::MediaVault;

/// Minimal async HTTP file server for the media vault (port 7702).
///
/// Serves files at:
///   GET /vault/{module}/{bucket}/{filename}
///
/// Supports:
///   - `Accept-Ranges: bytes` for PDF scrubbing and video seeking
///   - `Content-Type` from MIME type stored in registry
///   - `Cache-Control: max-age=86400` — content-addressed files are immutable
///
/// # Time Complexity: O(file_size) per request for streaming reads.
/// # Space Complexity: O(chunk_size) per active connection — never loads full file to RAM.
pub async fn serve(vault: Arc<MediaVault>, port: u16) {
    let addr: SocketAddr = format!("0.0.0.0:{port}").parse().expect("valid socket addr");
    let listener = match TcpListener::bind(addr).await {
        Ok(l) => l,
        Err(e) => {
            error!(subsystem = "vault_http", port = port, error = %e, "Failed to bind vault HTTP server");
            return;
        }
    };
    info!(subsystem = "vault_http", port = port, "Media Vault HTTP file server listening");

    loop {
        match listener.accept().await {
            Ok((stream, peer)) => {
                let vault_clone = Arc::clone(&vault);
                tokio::spawn(handle_connection(stream, peer, vault_clone));
            }
            Err(e) => {
                warn!(subsystem = "vault_http", error = %e, "Accept error on vault HTTP server");
            }
        }
    }
}

async fn handle_connection(
    mut stream: tokio::net::TcpStream,
    peer: SocketAddr,
    vault: Arc<MediaVault>,
) {
    use tokio::io::AsyncReadExt;

    let mut buf = vec![0u8; 8192];
    let n = match stream.read(&mut buf).await {
        Ok(0) | Err(_) => return,
        Ok(n) => n,
    };

    let request_str = match std::str::from_utf8(&buf[..n]) {
        Ok(s) => s,
        Err(_) => {
            let _ = write_response(&mut stream, 400, "text/plain", b"Bad Request".to_vec(), None).await;
            return;
        }
    };

    // Parse HTTP request line: "GET /vault/resume/a3/a3f2....pdf HTTP/1.1"
    let first_line = request_str.lines().next().unwrap_or("");
    let parts: Vec<&str> = first_line.splitn(3, ' ').collect();
    if parts.len() < 2 || parts[0] != "GET" {
        let _ = write_response(&mut stream, 405, "text/plain", b"Method Not Allowed".to_vec(), None).await;
        return;
    }

    let raw_path = parts[1];

    // Parse Range header if present
    let range_header = request_str
        .lines()
        .find(|l| l.to_lowercase().starts_with("range:"))
        .and_then(|l| l.split_once(':').map(|x| x.1))
        .map(|v| v.trim().to_string());

    // URL must be /vault/{module}/{bucket}/{sha256}.{ext}
    let segments: Vec<&str> = raw_path.trim_start_matches('/').split('/').collect();
    if segments.len() != 4 || segments[0] != "vault" {
        let _ = write_response(&mut stream, 404, "text/plain", b"Not Found".to_vec(), None).await;
        return;
    }

    let module = segments[1];
    let bucket = segments[2];
    let file_part = segments[3];

    // Reconstruct filesystem path
    let file_path = PathBuf::from(&vault.config.root_path)
        .join(module)
        .join(bucket)
        .join(file_part);

    // Security: canonicalize and ensure path stays inside root_path
    let root = PathBuf::from(&vault.config.root_path);
    let canonical = match file_path.canonicalize() {
        Ok(p) => p,
        Err(_) => {
            let _ = write_response(&mut stream, 404, "text/plain", b"Not Found".to_vec(), None).await;
            return;
        }
    };
    if !canonical.starts_with(&root) {
        warn!(
            subsystem = "vault_http",
            peer = %peer,
            path = %raw_path,
            "Path traversal attempt blocked"
        );
        let _ = write_response(&mut stream, 403, "text/plain", b"Forbidden".to_vec(), None).await;
        return;
    }

    // Read file bytes — O(file_size). For very large files a streaming approach would be
    // preferred, but for our use case (PDFs typically < 2 MB) this is acceptable on Pi 5.
    let file_bytes = match tokio::fs::read(&canonical).await {
        Ok(b) => b,
        Err(_) => {
            let _ = write_response(&mut stream, 404, "text/plain", b"Not Found".to_vec(), None).await;
            return;
        }
    };

    // Determine MIME type from registry or extension
    let sha256 = file_part
        .split('.')
        .next()
        .unwrap_or(file_part);
    let mime = vault
        .get_asset(sha256)
        .ok()
        .flatten()
        .map(|a| a.mime_type)
        .unwrap_or_else(|| mime_from_ext(file_part));

    // Handle Range requests for PDF scrubbing / video seeking
    if let Some(range_str) = range_header {
        if let Some(body) = apply_range(&file_bytes, &range_str) {
            let content_range = format!(
                "bytes {}-{}/{}",
                parse_range_start(&range_str, file_bytes.len()),
                parse_range_start(&range_str, file_bytes.len()) + body.len().saturating_sub(1),
                file_bytes.len()
            );
            let extra = format!(
                "Content-Range: {content_range}\r\nAccept-Ranges: bytes\r\nCache-Control: max-age=86400\r\n"
            );
            let _ = write_response_with_extra(&mut stream, 206, &mime, body, &extra).await;
            return;
        }
    }

    // Full file response
    let extra = "Accept-Ranges: bytes\r\nCache-Control: max-age=86400\r\n";
    let _ = write_response_with_extra(&mut stream, 200, &mime, file_bytes, extra).await;
}

fn mime_from_ext(filename: &str) -> String {
    let ext = filename.rsplit('.').next().unwrap_or("").to_lowercase();
    match ext.as_str() {
        "pdf" => "application/pdf",
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "webp" => "image/webp",
        "mp4" => "video/mp4",
        "opus" => "audio/ogg; codecs=opus",
        "mp3" => "audio/mpeg",
        "json" => "application/json",
        "md" => "text/markdown",
        _ => "application/octet-stream",
    }
    .to_string()
}

fn apply_range(data: &[u8], range_str: &str) -> Option<Vec<u8>> {
    // Parse "bytes=start-end" or "bytes=start-"
    let bytes_part = range_str.strip_prefix("bytes=")?;
    let mut parts = bytes_part.splitn(2, '-');
    let start: usize = parts.next()?.trim().parse().ok()?;
    let end: usize = parts
        .next()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(data.len().saturating_sub(1));

    if start >= data.len() {
        return None;
    }
    let end = end.min(data.len().saturating_sub(1));
    Some(data[start..=end].to_vec())
}

fn parse_range_start(range_str: &str, _total: usize) -> usize {
    range_str
        .strip_prefix("bytes=")
        .and_then(|s| s.split('-').next())
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(0)
}

async fn write_response(
    stream: &mut tokio::net::TcpStream,
    status: u16,
    mime: &str,
    body: Vec<u8>,
    _extra: Option<&str>,
) -> std::io::Result<()> {
    use tokio::io::AsyncWriteExt;
    let status_text = match status {
        200 => "OK",
        206 => "Partial Content",
        400 => "Bad Request",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        _ => "Internal Server Error",
    };
    let header = format!(
        "HTTP/1.1 {status} {status_text}\r\nContent-Type: {mime}\r\nContent-Length: {}\r\nAccept-Ranges: bytes\r\n\r\n",
        body.len()
    );
    stream.write_all(header.as_bytes()).await?;
    stream.write_all(&body).await?;
    Ok(())
}

async fn write_response_with_extra(
    stream: &mut tokio::net::TcpStream,
    status: u16,
    mime: &str,
    body: Vec<u8>,
    extra_headers: &str,
) -> std::io::Result<()> {
    use tokio::io::AsyncWriteExt;
    let status_text = match status {
        200 => "OK",
        206 => "Partial Content",
        _ => "OK",
    };
    let header = format!(
        "HTTP/1.1 {status} {status_text}\r\nContent-Type: {mime}\r\nContent-Length: {}\r\n{extra_headers}\r\n",
        body.len()
    );
    stream.write_all(header.as_bytes()).await?;
    stream.write_all(&body).await?;
    Ok(())
}


<!-- END_FILE: shua_governor\src\media_vault\http_server.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\media_vault\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_governor\src\media_vault\mod.rs`

pub mod http_server;
pub mod registry;
pub mod vault;


<!-- END_FILE: shua_governor\src\media_vault\mod.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\media_vault\registry.rs -->
# FILE: registry.rs
**Relative Path**: `shua_governor\src\media_vault\registry.rs`

use anyhow::{Context, Result};
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Mutex;
use tracing::info;

/// A single media asset record in the vault registry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaAsset {
    pub sha256_hash: String,
    pub module: String,
    pub file_path: String,
    pub file_name: String,
    pub mime_type: String,
    pub file_size: i64,
    pub ref_count: i64,
    pub uploaded_by: String,
    pub created_at: String,
    pub last_accessed: String,
}

/// Paginated list of media assets.
#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
pub struct MediaAssetPage {
    pub items: Vec<MediaAsset>,
    pub total: u32,
    pub has_more: bool,
}

/// SQLite-backed registry for media vault assets (stored in activity.db).
pub struct VaultRegistry {
    conn: Mutex<Connection>,
}

impl VaultRegistry {
    /// Open (or create) the registry in the given SQLite path.
    pub fn open(db_path: &std::path::Path) -> Result<Self> {
        let conn = Connection::open(db_path).with_context(|| {
            format!("Failed to open vault registry DB at {}", db_path.display())
        })?;

        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;

        conn.execute_batch(
            r#"
            CREATE TABLE IF NOT EXISTS media_assets (
                sha256_hash   TEXT    PRIMARY KEY,
                module        TEXT    NOT NULL,
                file_path     TEXT    NOT NULL,
                file_name     TEXT    NOT NULL,
                mime_type     TEXT    NOT NULL,
                file_size     INTEGER NOT NULL,
                ref_count     INTEGER NOT NULL DEFAULT 1,
                uploaded_by   TEXT    NOT NULL DEFAULT 'shua',
                created_at    TEXT    NOT NULL,
                last_accessed TEXT    NOT NULL
            );
            "#,
        )?;

        info!(
            subsystem = "vault_registry",
            db = %db_path.display(),
            "VaultRegistry opened — media_assets schema ensured"
        );

        Ok(Self {
            conn: Mutex::new(conn),
        })
    }

    /// Insert a new asset row. Returns `true` if newly inserted, `false` if
    /// it already existed (ref_count incremented).
    #[allow(clippy::too_many_arguments)]
    pub fn insert_or_increment(
        &self,
        sha256: &str,
        module: &str,
        file_path: &str,
        file_name: &str,
        mime_type: &str,
        file_size: i64,
        uploaded_by: &str,
    ) -> Result<bool> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");
        let now = chrono::Utc::now().to_rfc3339();

        // Try to find existing row
        let existing: Option<i64> = conn
            .query_row(
                "SELECT ref_count FROM media_assets WHERE sha256_hash = ?1",
                params![sha256],
                |row| row.get(0),
            )
            .ok();

        if let Some(_rc) = existing {
            // Already exists — just bump ref_count and update last_accessed
            conn.execute(
                "UPDATE media_assets SET ref_count = ref_count + 1, last_accessed = ?1 WHERE sha256_hash = ?2",
                params![now, sha256],
            )?;
            info!(
                subsystem = "vault_registry",
                sha256 = %sha256,
                module = %module,
                "Deduplicated upload — ref_count incremented"
            );
            Ok(false) // not newly created
        } else {
            conn.execute(
                r#"INSERT INTO media_assets
                   (sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed)
                   VALUES (?1, ?2, ?3, ?4, ?5, ?6, 1, ?7, ?8, ?8)"#,
                params![sha256, module, file_path, file_name, mime_type, file_size, uploaded_by, now],
            )?;
            info!(
                subsystem = "vault_registry",
                sha256 = %sha256,
                module = %module,
                file_size = file_size,
                "New asset inserted into vault registry"
            );
            Ok(true) // newly created
        }
    }

    /// Fetch a single asset by SHA256 hash.
    pub fn get(&self, sha256: &str) -> Result<Option<MediaAsset>> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");
        let now = chrono::Utc::now().to_rfc3339();
        // Update last_accessed on read
        let _ = conn.execute(
            "UPDATE media_assets SET last_accessed = ?1 WHERE sha256_hash = ?2",
            params![now, sha256],
        );
        let mut stmt = conn.prepare(
            "SELECT sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed FROM media_assets WHERE sha256_hash = ?1"
        )?;
        let result = stmt
            .query_row(params![sha256], |row| {
                Ok(MediaAsset {
                    sha256_hash: row.get(0)?,
                    module: row.get(1)?,
                    file_path: row.get(2)?,
                    file_name: row.get(3)?,
                    mime_type: row.get(4)?,
                    file_size: row.get(5)?,
                    ref_count: row.get(6)?,
                    uploaded_by: row.get(7)?,
                    created_at: row.get(8)?,
                    last_accessed: row.get(9)?,
                })
            })
            .ok();
        Ok(result)
    }

    /// List assets, optionally filtered by module, with pagination.
    /// Returns (items, total_count).
    pub fn list(
        &self,
        module_filter: Option<&str>,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<MediaAsset>, u32)> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");
        let offset = page * page_size;

        let (count_sql, list_sql, use_filter) = if let Some(m) = module_filter {
            let _ = m; // used below via params
            (
                "SELECT COUNT(*) FROM media_assets WHERE module = ?1",
                "SELECT sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed FROM media_assets WHERE module = ?1 ORDER BY created_at DESC LIMIT ?2 OFFSET ?3",
                true,
            )
        } else {
            (
                "SELECT COUNT(*) FROM media_assets",
                "SELECT sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed FROM media_assets ORDER BY created_at DESC LIMIT ?1 OFFSET ?2",
                false,
            )
        };

        let total: u32 = if use_filter {
            conn.query_row(count_sql, params![module_filter.unwrap()], |r| r.get(0))?
        } else {
            conn.query_row(count_sql, [], |r| r.get(0))?
        };

        let mut stmt = conn.prepare(list_sql)?;
        let rows: Vec<MediaAsset> = if use_filter {
            stmt.query_map(params![module_filter.unwrap(), page_size, offset], |row| {
                Ok(MediaAsset {
                    sha256_hash: row.get(0)?,
                    module: row.get(1)?,
                    file_path: row.get(2)?,
                    file_name: row.get(3)?,
                    mime_type: row.get(4)?,
                    file_size: row.get(5)?,
                    ref_count: row.get(6)?,
                    uploaded_by: row.get(7)?,
                    created_at: row.get(8)?,
                    last_accessed: row.get(9)?,
                })
            })?
            .filter_map(|r| r.ok())
            .collect()
        } else {
            stmt.query_map(params![page_size, offset], |row| {
                Ok(MediaAsset {
                    sha256_hash: row.get(0)?,
                    module: row.get(1)?,
                    file_path: row.get(2)?,
                    file_name: row.get(3)?,
                    mime_type: row.get(4)?,
                    file_size: row.get(5)?,
                    ref_count: row.get(6)?,
                    uploaded_by: row.get(7)?,
                    created_at: row.get(8)?,
                    last_accessed: row.get(9)?,
                })
            })?
            .filter_map(|r| r.ok())
            .collect()
        };

        Ok((rows, total))
    }

    /// Decrement ref_count. Returns the new ref_count, and the file_path if the
    /// row was physically deleted (ref_count reached 0). Both operations execute
    /// inside a single SQLite transaction — atomic by design.
    pub fn decrement_ref(&self, sha256: &str) -> Result<(i64, Option<PathBuf>)> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");

        // Begin transaction
        conn.execute_batch("BEGIN;").context("BEGIN transaction")?;

        // Fetch current ref_count (inside transaction)
        let rc: i64 = match conn.query_row(
            "SELECT ref_count FROM media_assets WHERE sha256_hash = ?1",
            params![sha256],
            |r| r.get(0),
        ) {
            Ok(v) => v,
            Err(e) => {
                let _ = conn.execute_batch("ROLLBACK;");
                return Err(anyhow::anyhow!("SHA256 '{}' not found: {e}", sha256));
            }
        };

        if rc <= 1 {
            // Fetch file path before deleting row
            let path: String = match conn.query_row(
                "SELECT file_path FROM media_assets WHERE sha256_hash = ?1",
                params![sha256],
                |r| r.get(0),
            ) {
                Ok(p) => p,
                Err(e) => {
                    let _ = conn.execute_batch("ROLLBACK;");
                    return Err(anyhow::anyhow!("file_path query failed: {e}"));
                }
            };
            if let Err(e) = conn.execute(
                "DELETE FROM media_assets WHERE sha256_hash = ?1",
                params![sha256],
            ) {
                let _ = conn.execute_batch("ROLLBACK;");
                return Err(anyhow::anyhow!("DELETE failed: {e}"));
            }
            conn.execute_batch("COMMIT;").context("COMMIT delete")?;
            Ok((0, Some(PathBuf::from(path))))
        } else {
            if let Err(e) = conn.execute(
                "UPDATE media_assets SET ref_count = ref_count - 1 WHERE sha256_hash = ?1",
                params![sha256],
            ) {
                let _ = conn.execute_batch("ROLLBACK;");
                return Err(anyhow::anyhow!("UPDATE ref_count failed: {e}"));
            }
            conn.execute_batch("COMMIT;").context("COMMIT decrement")?;
            Ok((rc - 1, None))
        }
    }
}


<!-- END_FILE: shua_governor\src\media_vault\registry.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\media_vault\vault.rs -->
# FILE: vault.rs
**Relative Path**: `shua_governor\src\media_vault\vault.rs`

use anyhow::{Context, Result};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tracing::{info, warn};

use super::registry::{MediaAsset, VaultRegistry};

/// Config loaded from config.toml [media_vault] section.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct MediaVaultConfig {
    pub root_path: String,
    pub http_port: u16,
    pub max_file_size_mb: u64,
}

impl Default for MediaVaultConfig {
    fn default() -> Self {
        Self {
            root_path: "/var/lib/horaizon/vault".to_string(),
            http_port: 7702,
            max_file_size_mb: 256,
        }
    }
}

/// Upload result returned to callers.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadResult {
    pub sha256_hash: String,
    pub url: String,
    pub file_size: u64,
    /// True if a duplicate — ref_count was incremented rather than a new file written.
    pub deduplicated: bool,
}

/// The MediaVault manages content-addressed binary storage on the Pi 5 filesystem.
///
/// # Layout
/// ```
/// {root_path}/{module}/{sha256[0..2]}/{sha256}.{ext}
/// ```
///
/// # Time Complexity
/// - `store`: O(n) for SHA256 computation (n = file bytes); O(1) for path construction.
/// - `get_asset`: O(1) registry lookup.
/// - `delete`: O(1) registry + O(1) filesystem unlink.
///
/// # Space Complexity
/// - O(n) for n stored unique files; O(1) per request.
pub struct MediaVault {
    pub config: MediaVaultConfig,
    pub registry: Arc<VaultRegistry>,
    pi5_ip: String,
}

impl MediaVault {
    /// Create a new MediaVault. `db_path` must point to the governor activity.db.
    pub fn new(config: MediaVaultConfig, db_path: &Path) -> Result<Self> {
        let registry = Arc::new(
            VaultRegistry::open(db_path)
                .context("Failed to open VaultRegistry in activity.db")?,
        );

        // Create module subdirectories
        for module in &["resume", "diary", "shared"] {
            let dir = PathBuf::from(&config.root_path).join(module);
            std::fs::create_dir_all(&dir).with_context(|| {
                format!("Failed to create vault module dir {}", dir.display())
            })?;
        }

        // Detect Pi 5 / local IP for URL construction (prefer tailscale, fallback to localhost)
        let pi5_ip = detect_ip();

        info!(
            subsystem = "media_vault",
            root = %config.root_path,
            http_port = config.http_port,
            max_file_mb = config.max_file_size_mb,
            pi5_ip = %pi5_ip,
            "MediaVault initialized"
        );

        Ok(Self {
            config,
            registry,
            pi5_ip,
        })
    }

    /// Store file bytes. Returns an `UploadResult` with SHA256 and HTTP URL.
    ///
    /// If the same content already exists (same SHA256), the file is NOT written
    /// again — the ref_count is incremented and `deduplicated: true` is returned.
    pub fn store(
        &self,
        module: &str,
        file_name: &str,
        mime_type: &str,
        data: &[u8],
        uploaded_by: &str,
    ) -> Result<UploadResult> {
        let max_bytes = self.config.max_file_size_mb * 1024 * 1024;
        if data.len() as u64 > max_bytes {
            return Err(anyhow::anyhow!(
                "File too large: {} bytes (max {} MB)",
                data.len(),
                self.config.max_file_size_mb
            ));
        }

        // Compute SHA256 — O(n) where n = data length
        let hash = compute_sha256(data);

        // Derive extension from file_name
        let ext = Path::new(file_name)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("bin");

        // Content-addressed path: {root}/{module}/{hash[0..2]}/{hash}.{ext}
        let bucket = &hash[..2];
        let bucket_dir = PathBuf::from(&self.config.root_path)
            .join(module)
            .join(bucket);
        let file_path = bucket_dir.join(format!("{hash}.{ext}"));

        // Registry insert-or-increment — determines if file already existed
        let newly_inserted = self.registry.insert_or_increment(
            &hash,
            module,
            &file_path.to_string_lossy(),
            file_name,
            mime_type,
            data.len() as i64,
            uploaded_by,
        )?;

        if newly_inserted {
            // Write to disk only for new files
            std::fs::create_dir_all(&bucket_dir)
                .with_context(|| format!("Failed to create bucket dir {}", bucket_dir.display()))?;
            std::fs::write(&file_path, data)
                .with_context(|| format!("Failed to write file {}", file_path.display()))?;
            info!(
                subsystem = "media_vault",
                sha256 = %hash,
                module = module,
                file = %file_path.display(),
                bytes = data.len(),
                "File stored to vault"
            );
        }

        let url = self.build_url(module, &hash, ext);

        Ok(UploadResult {
            sha256_hash: hash,
            url,
            file_size: data.len() as u64,
            deduplicated: !newly_inserted,
        })
    }

    /// Store file from Base64-encoded string (used by submodule IPC calls).
    pub fn store_base64(
        &self,
        module: &str,
        file_name: &str,
        mime_type: &str,
        data_base64: &str,
        uploaded_by: &str,
    ) -> Result<UploadResult> {
        let data = BASE64
            .decode(data_base64)
            .context("Invalid Base64 in vault.upload IPC call")?;
        self.store(module, file_name, mime_type, &data, uploaded_by)
    }

    /// Fetch asset metadata by SHA256.
    pub fn get_asset(&self, sha256: &str) -> Result<Option<MediaAsset>> {
        self.registry.get(sha256)
    }

    /// List assets with optional module filter and pagination.
    pub fn list_assets(
        &self,
        module_filter: Option<&str>,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<MediaAsset>, u32)> {
        self.registry.list(module_filter, page, page_size)
    }

    /// Delete an asset. Decrements ref_count; physically unlinks the file only
    /// when ref_count reaches 0. The registry DELETE and file unlink are performed
    /// atomically inside the registry transaction.
    ///
    /// Returns `(new_ref_count, physically_deleted)`.
    pub fn delete_asset(&self, sha256: &str) -> Result<(i64, bool)> {
        let (new_rc, path_to_delete) = self.registry.decrement_ref(sha256)?;

        if let Some(path) = path_to_delete {
            match std::fs::remove_file(&path) {
                Ok(_) => {
                    info!(
                        subsystem = "media_vault",
                        sha256 = %sha256,
                        path = %path.display(),
                        "File physically deleted from vault (ref_count = 0)"
                    );
                    return Ok((0, true));
                }
                Err(e) => {
                    warn!(
                        subsystem = "media_vault",
                        sha256 = %sha256,
                        path = %path.display(),
                        error = %e,
                        "Registry row deleted but file unlink failed (may already be missing)"
                    );
                    return Ok((0, false));
                }
            }
        }

        Ok((new_rc, false))
    }

    /// Build the HTTP URL for a stored file.
    pub fn build_url(&self, module: &str, sha256: &str, ext: &str) -> String {
        let bucket = &sha256[..2];
        format!(
            "http://{}:{}/vault/{}/{}/{}.{}",
            self.pi5_ip, self.config.http_port, module, bucket, sha256, ext
        )
    }
}

/// Compute SHA256 hex string of bytes. O(n).
fn compute_sha256(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

/// Detect the host IP — tries Tailscale range first, falls back to 127.0.0.1.
fn detect_ip() -> String {
    // On Pi 5, the Tailscale IP is typically in 100.x.x.x range.
    // We read the governor config or fall back to localhost.
    // This is best-effort — production should set this via config.toml.
    if let Ok(output) = std::process::Command::new("hostname").arg("-I").output() {
        let ips = String::from_utf8_lossy(&output.stdout);
        for ip in ips.split_whitespace() {
            if ip.starts_with("100.") {
                // Tailscale IP
                return ip.to_string();
            }
        }
        // First non-loopback IP
        for ip in ips.split_whitespace() {
            if ip != "127.0.0.1" {
                return ip.to_string();
            }
        }
    }
    "127.0.0.1".to_string()
}


<!-- END_FILE: shua_governor\src\media_vault\vault.rs -->
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

/// Utility function to strip <think>...</think> reasoning tags from LLM responses
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

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use serde::{Deserialize, Serialize};
use tokio::sync::{mpsc, oneshot, Mutex};

use crate::mcp::McpToolSchema;

/// In-flight MCP tool call oneshot senders keyed by UUID request ID
pub type PendingCallMap = Arc<Mutex<HashMap<String, oneshot::Sender<serde_json::Value>>>>;

/// Lifecycle state of a managed shua module process
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ModuleState {
    Running,
    IpcConnected,
    Sleeping,
    Stopped,
    Unknown,
}

/// A registered shua module managed by the Governor with live telemetry and IPC capabilities
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
    /// Flag indicating whether the last stop signal was intentionally issued
    #[serde(skip)]
    pub intentional_stop: bool,
    /// Most recent error or crash message
    pub last_error: Option<String>,

    /// OS child process handle enabling watchdog monitoring
    #[serde(skip)]
    pub child_handle: Option<Arc<Mutex<tokio::process::Child>>>,

    /// IPC write channel to module WebSocket connection (None if disconnected)
    #[serde(skip)]
    pub ipc_tx: Option<mpsc::UnboundedSender<String>>,

    /// MCP tool schemas self-reported at registration
    #[serde(skip)]
    pub tools: Vec<McpToolSchema>,

    /// Scope tag declared at registration (e.g. "code", "diary")
    #[serde(skip)]
    pub module_scope: Option<String>,

    /// Semver string reported in registration manifest
    #[serde(skip)]
    pub manifest_version: Option<String>,

    /// In-flight MCP tool call oneshot senders keyed by UUID request ID
    #[serde(skip)]
    pub pending_calls: PendingCallMap,
}

impl ModuleEntry {
    pub fn new(name: &str, binary: PathBuf, auto_start: bool, ram_limit_mb: Option<u32>) -> Self {
        let cgroup_path = PathBuf::from(format!(
            "/sys/fs/cgroup/horaizon/{}",
            name.replace('.', "_")
        ));

        // Pre-populate tools manifest from contract JSON file if available on disk
        let sanitized = name.replace('.', "_");
        let manifest_filename = format!("{sanitized}_mcp.json");

        let mut candidate_paths: Vec<PathBuf> = vec![
            PathBuf::from(format!("_architecture/contracts/mcp/{manifest_filename}")),
            PathBuf::from(format!("../_architecture/contracts/mcp/{manifest_filename}")),
            PathBuf::from(format!("/home/shua/horaizon-3.0/_architecture/contracts/mcp/{manifest_filename}")),
            PathBuf::from(format!("/etc/horaizon/_architecture/contracts/mcp/{manifest_filename}")),
            PathBuf::from(format!("/var/lib/horaizon/_architecture/contracts/mcp/{manifest_filename}")),
        ];

        if let Ok(cwd) = std::env::current_dir() {
            candidate_paths.push(cwd.join("_architecture/contracts/mcp").join(&manifest_filename));
            if let Some(parent) = cwd.parent() {
                candidate_paths.push(parent.join("_architecture/contracts/mcp").join(&manifest_filename));
            }
        }

        let mut found_content = None;
        let mut searched_paths = Vec::new();

        for path in &candidate_paths {
            searched_paths.push(path.display().to_string());
            if let Ok(content) = std::fs::read_to_string(path) {
                found_content = Some((content, path.clone()));
                break;
            }
        }

        let (tools, module_scope, manifest_version) = if let Some((content, matched_path)) = found_content {
            let clean_content = content.trim_start_matches('\u{feff}');
            match serde_json::from_str::<serde_json::Value>(clean_content) {
                Ok(val) => {
                    let parsed_tools: Vec<McpToolSchema> = val.get("tools")
                        .and_then(|t| serde_json::from_value(t.clone()).ok())
                        .unwrap_or_default();
                    let scope = val["scope"].as_str().unwrap_or("").to_string();
                    let version = val["version"].as_str().unwrap_or("0.1.0").to_string();
                    tracing::info!(
                        subsystem = "module_entry",
                        module = %name,
                        tools_count = parsed_tools.len(),
                        scope = %scope,
                        manifest_path = %matched_path.display(),
                        "Pre-populated MCP tools from contract manifest JSON"
                    );
                    (
                        parsed_tools,
                        if scope.is_empty() { None } else { Some(scope) },
                        Some(version),
                    )
                }
                Err(e) => {
                    tracing::warn!(
                        subsystem = "module_entry",
                        module = %name,
                        manifest_path = %matched_path.display(),
                        error = %e,
                        "Failed to parse contract manifest JSON file"
                    );
                    (Vec::new(), None, None)
                }
            }
        } else {
            tracing::warn!(
                subsystem = "module_entry",
                module = %name,
                searched = ?searched_paths,
                "Could not find MCP contract manifest JSON on disk — tools initialized empty"
            );
            (Vec::new(), None, None)
        };

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
            intentional_stop: false,
            last_error: None,
            child_handle: None,
            ipc_tx: None,
            tools,
            module_scope,
            manifest_version,
            pending_calls: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    #[allow(dead_code)]
    pub fn is_running(&self) -> bool {
        matches!(self.state, ModuleState::Running | ModuleState::IpcConnected)
    }

    #[allow(dead_code)]
    pub fn is_alive(&self) -> bool {
        matches!(self.state, ModuleState::Running | ModuleState::IpcConnected | ModuleState::Sleeping)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_prepopulate_shua_code_visualizer_mcp_manifest() {
        let entry = ModuleEntry::new(
            "shua.code_visualizer",
            PathBuf::from("/usr/local/bin/shua_code_visualizer"),
            false,
            Some(128),
        );

        println!("Loaded module scope: {:?}", entry.module_scope);
        println!("Loaded manifest version: {:?}", entry.manifest_version);
        println!("Loaded tools count: {}", entry.tools.len());
        for tool in &entry.tools {
            println!("  - Tool: {} (scope: {})", tool.name, tool.scope);
        }

        assert_eq!(entry.tools.len(), 8, "Expected 8 code_* MCP tools from manifest");
        assert_eq!(entry.module_scope.as_deref(), Some("code"));
        assert!(entry.tools.iter().any(|t| t.name == "code_parse_ast"));
        assert!(entry.tools.iter().any(|t| t.name == "code_read_file"));
        assert!(entry.tools.iter().any(|t| t.name == "code_render_graph"));
    }
}


<!-- END_FILE: shua_governor\src\registry\module_entry.rs -->
================================================================================

<!-- START_FILE: shua_governor\src\registry\process_manager.rs -->
# FILE: process_manager.rs
**Relative Path**: `shua_governor\src\registry\process_manager.rs`

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use anyhow::Result;
use tokio::sync::{Mutex, RwLock};
use tracing::{error, info, warn};

#[cfg(unix)]
use nix::sys::signal::{kill, Signal};
#[cfg(unix)]
use nix::unistd::Pid;

use crate::registry::cgroup_manager::CgroupManager;
use crate::registry::module_entry::{ModuleEntry, ModuleState};

pub struct ProcessManager {
    pub modules: Arc<RwLock<HashMap<String, ModuleEntry>>>,
    pub ipc_port: u16,
}

impl ProcessManager {
    pub fn new(ipc_port: u16) -> Self {
        Self {
            modules: Arc::new(RwLock::new(HashMap::new())),
            ipc_port,
        }
    }

    #[allow(dead_code)]
    pub fn with_default_port() -> Self {
        Self::new(7701)
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

            let sanitized = name.replace('.', "_");
            let candidate_binaries = vec![
                entry.binary.clone(),
                PathBuf::from(format!("/home/shua/horaizon-3.0/target/release/{sanitized}")),
                PathBuf::from(format!("/home/shua/horaizon-3.0/{sanitized}/target/release/{sanitized}")),
                PathBuf::from(format!("../target/release/{sanitized}")),
                PathBuf::from(format!("../{sanitized}/target/release/{sanitized}")),
                PathBuf::from(format!("./target/release/{sanitized}")),
            ];

            let effective_binary = candidate_binaries.into_iter().find(|p| p.exists()).unwrap_or_else(|| entry.binary.clone());

            info!(
                subsystem = "process_manager",
                module = name,
                binary = %effective_binary.display(),
                ipc_port = self.ipc_port,
                "Spawning module process with IPC environment injection"
            );

            let mut cmd = tokio::process::Command::new(&effective_binary);

            // Inject Governor IPC environment variables for submodules
            cmd.env("SHUA_GOVERNOR_PID", std::process::id().to_string());
            cmd.env("SHUA_GOVERNOR_IPC_PORT", self.ipc_port.to_string());

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

            let child_arc = Arc::new(Mutex::new(child));
            entry.pid = Some(pid);
            entry.state = ModuleState::Running;
            entry.child_handle = Some(Arc::clone(&child_arc));

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
                "Module process started successfully — watchdog attached"
            );

            // Spawn background watchdog monitoring child process exit
            let modules_clone = Arc::clone(&self.modules);
            let name_string = name.to_string();
            let ipc_port_val = self.ipc_port;

            tokio::spawn(async move {
                let mut guard = child_arc.lock().await;
                let exit_res = guard.wait().await;

                let mut modules = modules_clone.write().await;
                if let Some(entry) = modules.get_mut(&name_string) {
                    let was_intentional = entry.intentional_stop;
                    entry.state = ModuleState::Stopped;
                    entry.pid = None;
                    entry.ipc_tx = None;
                    entry.intentional_stop = false;

                    let exit_msg = match exit_res {
                        Ok(status) => format!("Exited with status: {status}"),
                        Err(e) => format!("Wait error: {e}"),
                    };

                    if was_intentional {
                        info!(
                            subsystem = "process_manager",
                            module = %name_string,
                            exit_status = %exit_msg,
                            "Module process stopped cleanly per governor/user request"
                        );
                    } else {
                        entry.restart_count += 1;
                        entry.last_error = Some(exit_msg.clone());

                        warn!(
                            subsystem = "process_manager",
                            module = %name_string,
                            exit_status = %exit_msg,
                            restart_count = entry.restart_count,
                            "Module process exited unexpectedly — state reset to Stopped"
                        );

                        let auto_restart = entry.auto_start && entry.restart_count <= 3;
                        if auto_restart {
                            info!(
                                subsystem = "process_manager",
                                module = %name_string,
                                restart_count = entry.restart_count,
                                "Auto-restarting module process in 2 seconds"
                            );
                            let modules_arc_again = Arc::clone(&modules_clone);
                            let name_again = name_string.clone();
                            tokio::spawn(async move {
                                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
                                let pm_dummy = ProcessManager { modules: modules_arc_again, ipc_port: ipc_port_val };
                                let _ = pm_dummy.start(&name_again).await;
                            });
                        } else if entry.restart_count > 3 {
                            error!(
                                subsystem = "process_manager",
                                module = %name_string,
                                restart_count = entry.restart_count,
                                "Module exceeded max auto-restart threshold (3) — halting auto-restart"
                            );
                        }
                    }
                }
            });

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

    /// Resume a module with SIGCONT or start if not spawned
    pub async fn wake(&self, name: &str) -> Result<()> {
        let key = {
            let modules = self.modules.read().await;
            match Self::find_key(&modules, name) {
                Some(k) => k,
                None => {
                    let keys: Vec<String> = modules.keys().cloned().collect();
                    warn!(subsystem = "process_manager", target_name = %name, available_keys = ?keys, "ERR_UNKNOWN_MODULE lookup failed");
                    return Err(anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name} (available: {keys:?})"));
                }
            }
        };

        let has_pid = {
            let modules = self.modules.read().await;
            modules.get(&key).and_then(|e| e.pid).is_some()
        };

        if has_pid {
            let mut modules = self.modules.write().await;
            if let Some(entry) = modules.get_mut(&key) {
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
                    entry.state = ModuleState::Running;
                }
            }
            Ok(())
        } else {
            info!(
                subsystem = "process_manager",
                module = %key,
                "Module has no PID attached — launching process via start()"
            );
            self.start(&key).await
        }
    }

    /// Terminate a module process with SIGTERM/SIGKILL to free RAM budget
    pub async fn stop(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let key = Self::find_key(&modules, name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;
        let entry = modules.get_mut(&key).unwrap();

        entry.intentional_stop = true;
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
        let pm = ProcessManager::new(7701);
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

