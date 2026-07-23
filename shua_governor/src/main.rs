mod ai_router;
mod broker;
mod config;
mod dream_loop;
mod error;
mod logging;
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
use tracing::{error, info};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

#[tokio::main]
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
