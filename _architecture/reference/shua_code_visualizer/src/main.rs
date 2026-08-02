pub mod parser;
pub mod graph;
pub mod export;
pub mod debug;
pub mod routes;
pub mod logging;

#[cfg(target_os = "windows")]
#[link(name = "advapi32")]
#[link(name = "crypt32")]
extern "C" {}

use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tower_http::services::ServeDir;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::graph::store::AppState;
use crate::logging::HbpLoggerLayer;

#[tokio::main]
async fn main() {
    // 1. Initialize Logging (Centralized HBP msgpack vs Standalone human-readable text)
    let is_centralized = std::env::args().any(|arg| arg == "--centralized-logging")
        || std::env::var("HORAIZON_LOG_FORMAT").map(|v| v == "json").unwrap_or(false);

    let is_verbose = std::env::args().any(|arg| arg == "--verbose")
        || std::env::var("HORAIZON_LOG_VERBOSE").map(|v| v == "true").unwrap_or(false);

    if is_centralized {
        crate::logging::CENTRALIZED_LOGGING.store(true, std::sync::atomic::Ordering::SeqCst);
        // central logging formats all logs to stdout as binary HBP frames
        tracing_subscriber::registry()
            .with(HbpLoggerLayer::new())
            .init();
    } else {
        // standalone output color logs to standard console
        tracing_subscriber::fmt()
            .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
            .init();
    }

    if is_verbose {
        crate::logging::VERBOSE_LOGGING.store(true, std::sync::atomic::Ordering::SeqCst);
    }

    tracing::info!(subsystem = "lifecycle", "Initializing shua_code_visualizer microservice daemon...");

    // 2. Initialize in-memory AppState
    let state = AppState::new();

    // 3. Trigger Cold Scanner (Blocks startup until completed as per specification)
    let workspace_root = std::env::current_dir().unwrap_or_else(|_| std::path::PathBuf::from("."));
    tracing::info!(subsystem = "parser", root_path = ?workspace_root, "Running cold scanning traversal...");
    parser::scanner::run_full_scan(&workspace_root, &state);

    if !is_centralized {
        tracing::info!(subsystem = "lifecycle", "Standalone scan completed. Exiting.");
        return;
    }

    // 4. Configure CORS for web views
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // 5. Mount Router
    let app = Router::new()
        .route("/health", get(routes::health_check))
        .route("/api/graph", get(routes::graph::get_graph))
        .route("/api/export", get(routes::export::export_sdg))
        .route("/api/scan", post(routes::scan::trigger_scan))
        .route("/api/debug", get(routes::debug::debug_analysis))
        // Serve static SPA assets from public/ folder
        .fallback_service(ServeDir::new("public"))
        .layer(cors)
        .with_state(state);

    // Bind to local address (governor proxies calls to this port)
    let addr = SocketAddr::from(([0, 0, 0, 0], 3005));
    tracing::info!(subsystem = "server", bind_address = ?addr, "Server successfully bootstrapped.");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
