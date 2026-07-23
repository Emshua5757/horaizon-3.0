mod ai_router;
mod broker;
mod config;
mod dream_loop;
mod error;
mod logger;
mod logging;
mod ollama;
mod registry;

use logging::bridge::ChannelLogger;
use logging::entry::LogEntry;
use logging::flush::flush_loop;
use logging::listener::start_log_ipc_listener;
use tokio::sync::{broadcast, mpsc};
use tracing::info;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // 1. Ingress MPSC channel (capacity 4096)
    let (log_tx, log_rx) = mpsc::channel::<LogEntry>(4096);

    // 2. Broadcast channel for live SSE streaming (capacity 1024)
    let (log_broadcast_tx, _log_broadcast_rx) = broadcast::channel::<LogEntry>(1024);

    // 3. Initialize subscriber with JSON stdout + ChannelLogger MPSC bridge
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
        "shua_governor starting — Centralized Logging Pipeline Active"
    );

    // 4. Spawn background log flush task (SQLite activity.db LTM writer)
    let broadcast_tx_clone = log_broadcast_tx.clone();
    tokio::spawn(async move {
        flush_loop(log_rx, broadcast_tx_clone).await;
    });

    // 5. Start IPC log listener (UDS on Linux + TCP 5001 loopback)
    start_log_ipc_listener(log_tx.clone()).await;

    // TODO: load config (TASK-007)
    // TODO: start process registry (TASK-005)
    // TODO: start Ollama lifecycle manager (TASK-006)
    // TODO: start Dream Loop scheduler (TASK-006)
    // TODO: start HBP v2 WebSocket broker (TASK-004)

    tokio::signal::ctrl_c().await?;
    info!(module = "shua.governor", "Shutdown signal received — exiting cleanly");
    Ok(())
}
