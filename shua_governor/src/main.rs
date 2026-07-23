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
use dream_loop::DreamLoopScheduler;
use logging::bridge::ChannelLogger;
use logging::broadcaster::LogBroadcaster;
use logging::entry::LogEntry;
use logging::flush::{flush_loop, resolved_important_log_path};
use logging::listener::start_log_ipc_listener;
use ollama::{ModelRegistry, OllamaClient, OllamaLifecycle, RegisteredModel};
use registry::{ModuleEntry, ProcessManager};
use tokio::sync::{broadcast, mpsc};
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

    // 1. Ingress MPSC channel (capacity 4096)
    let (log_tx, log_rx) = mpsc::channel::<LogEntry>(4096);

    // 2. Broadcast channel for live SSE / WebSocket streaming (capacity 1024)
    let (log_broadcast_tx, log_broadcast_rx) = broadcast::channel::<LogEntry>(1024);

    // 3. Initialize tracing subscriber with JSON stdout + ChannelLogger MPSC bridge
    tracing_subscriber::registry()
        .with(
            EnvFilter::from_default_env()
                .add_directive("shua_governor=info".parse()?),
        )
        .with(tracing_subscriber::fmt::layer().json())
        .with(ChannelLogger::new(log_tx.clone()))
        .init();

    info!(
        module = "shua.governor",
        version = env!("CARGO_PKG_VERSION"),
        "shua_governor starting — Centralized Telemetry & HBP Broker Active"
    );

    // 4. Spawn background log flush task (SQLite activity.db LTM + important.log rotation)
    let broadcast_tx_clone = log_broadcast_tx.clone();
    tokio::spawn(async move {
        flush_loop(log_rx, broadcast_tx_clone).await;
    });

    // 5. Start IPC log listener (UDS on Linux + TCP 5001 loopback)
    start_log_ipc_listener(log_tx.clone()).await;

    // 6. Initialize ProcessManager & Register Default Modules
    let process_manager = Arc::new(ProcessManager::new());
    process_manager
        .register(ModuleEntry::new(
            "shua.resume",
            PathBuf::from("/usr/local/bin/shua_resume"),
            true,
            Some(128),
        ))
        .await;

    process_manager
        .register(ModuleEntry::new(
            "shua.diary",
            PathBuf::from("/usr/local/bin/shua_diary"),
            true,
            Some(256),
        ))
        .await;

    process_manager
        .register(ModuleEntry::new(
            "shua.code_visualizer",
            PathBuf::from("/usr/local/bin/shua_code_visualizer"),
            false,
            Some(128),
        ))
        .await;

    info!(
        subsystem = "governor_main",
        "ProcessManager initialized with default microservice entries"
    );

    // 7. Initialize Ollama Lifecycle Manager
    let registered_models = vec![
        RegisteredModel {
            name: "qwen2.5:1.5b".into(),
            ram_mb: 1200,
            role: "primary_dialogue".into(),
            keep_alive: -1,
        },
        RegisteredModel {
            name: "llama3.2:3b".into(),
            ram_mb: 2400,
            role: "text_generator".into(),
            keep_alive: -1,
        },
    ];
    let model_registry = ModelRegistry::new(registered_models, 4096);
    let ollama_client = OllamaClient::new("http://127.0.0.1:11434");
    let ollama_lifecycle = Arc::new(OllamaLifecycle::new(ollama_client, model_registry));

    info!(
        subsystem = "governor_main",
        ram_cap_mb = 4096,
        "Ollama Lifecycle Manager initialized"
    );

    // 8. Start Nightly Dream Loop Scheduler
    tokio::spawn(async move {
        if let Err(e) = DreamLoopScheduler::start().await {
            error!(error = %e, "Dream Loop scheduler failed to start");
        }
    });

    // 9. Initialize WebSocket Log Broadcaster
    let log_broadcaster = Arc::new(LogBroadcaster::new());
    let log_broadcaster_clone = Arc::clone(&log_broadcaster);
    tokio::spawn(async move {
        log_broadcaster_clone.run_broadcast_loop(log_broadcast_rx).await;
    });

    // 10. Initialize HBP v2 Dispatcher & Broker Server
    let dispatcher = Arc::new(Dispatcher::new(
        log_tx.clone(),
        Arc::clone(&log_broadcaster),
        Arc::clone(&process_manager),
        Arc::clone(&ollama_lifecycle),
    ));
    let broker = BrokerServer::new(Arc::clone(&dispatcher));

    let addr: SocketAddr = "0.0.0.0:7700".parse()?;
    tokio::spawn(async move {
        if let Err(e) = broker.run(addr).await {
            tracing::error!(error = %e, "HBP WebSocket Broker error");
        }
    });

    info!(module = "shua.governor", port = 7700, "HBP v2 WebSocket broker listening on port 7700");

    tokio::signal::ctrl_c().await?;
    info!(module = "shua.governor", "Shutdown signal received — exiting cleanly");
    Ok(())
}
