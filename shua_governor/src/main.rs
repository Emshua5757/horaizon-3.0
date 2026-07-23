mod broker;
mod config;
mod error;
mod registry;
mod ollama;
mod ai_router;
mod dream_loop;
mod logger;

use tracing::info;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize structured JSON logging (mirrors 2.0 ChannelLogger pattern)
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::from_default_env()
                .add_directive("shua_governor=info".parse()?),
        )
        .json()
        .init();

    info!(
        module = "shua.governor",
        version = env!("CARGO_PKG_VERSION"),
        "shua_governor starting"
    );

    // TODO: load config (TASK-007)
    // TODO: start process registry (TASK-005)
    // TODO: start Ollama lifecycle manager (TASK-006)
    // TODO: start Dream Loop scheduler (TASK-006)
    // TODO: start HBP v2 WebSocket broker (TASK-004)

    // Placeholder: keep alive until Ctrl-C
    tokio::signal::ctrl_c().await?;
    info!(module = "shua.governor", "Shutdown signal received — exiting cleanly");
    Ok(())
}
