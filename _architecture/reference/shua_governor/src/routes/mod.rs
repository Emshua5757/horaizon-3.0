// shua_governor — Axum Central Router, Timing Middleware & Module Exports
// Phase 10: V4 SDUI Rewrite | Architecture spec: _architecture/governor/phase10-governor-spec.md
// Phase 12: Log query/stream/ingest routes registered.
// Phase 8:  Media upload, CAS static server, WebDAV NAS gateway registered.

pub mod ai_proxy;
pub mod dashboard;
pub mod health;
pub mod logs;
pub mod manifest;
pub mod media;
pub mod media_dav;
pub mod module_control;
pub mod module_ready;
pub mod preactivation;
pub mod sse_metrics;

use std::time::Instant;
use axum::{
    body::Body,
    extract::{DefaultBodyLimit, Request, State},
    http::{HeaderValue, StatusCode},
    middleware::{self, Next},
    response::Response,
    routing::{get, post},
    Router,
};
use dashboard::AppState;
use crate::proxy::handler::proxy_request;

/// High-precision execution timing middleware measuring request latency in microseconds.
/// Uses tracing::debug! (not println!) — zero thread contention under load.
async fn track_performance_timing(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = req.method().clone();
    let path = req.uri().path().to_string();

    let mut response = next.run(req).await;
    let elapsed_micros = start.elapsed().as_micros();
    let elapsed_millis = elapsed_micros as f64 / 1000.0;

    tracing::debug!(
        subsystem = "perf",
        method = %method,
        path = %path,
        latency_us = elapsed_micros,
        latency_ms = elapsed_millis,
        "Request completed"
    );

    let header_val = format!("total;dur={:.2}", elapsed_millis);
    if let Ok(val) = HeaderValue::from_str(&header_val) {
        response.headers_mut().insert("Server-Timing", val);
    }

    response
}

/// Constructs the master Axum router with all API routes and reverse proxy fallback paths.
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health::health_check))
        .route("/api/manifest", get(manifest::get_manifest))
        .route("/api/dashboard", get(dashboard::get_dashboard))
        .route("/api/console", get(dashboard::get_console))
        .route("/api/governor/control/:id/:action", post(module_control::control_module))
        // Dynamic SDUI Pre-Activation sheet route handler
        .route("/api/governor/preactivation/:id", get(preactivation::get_preactivation_sheet))
        // Phase 11.6 — Readiness callback: module fires this after its HTTP server binds
        .route("/api/internal/ready/:id", post(module_ready::mark_ready))
        // Phase 11.8 — SSE metrics stream: persistent connection, 2s tick, replaces 5s AST poll
        .route("/api/metrics/stream", get(sse_metrics::stream_metrics))
        // Phase 12 — Centralized log endpoints
        .route("/api/logs", get(logs::query_logs))
        .route("/api/logs/stream", get(logs::stream_logs))
        .route("/api/logs/ingest", post(logs::ingest_log))
        // Phase 14 — Hybrid AI inference proxy (dual-tier: Laptop GPU → Pi 5 Ollama fallback)
        .route("/api/ai/infer", post(ai_proxy::infer))
        // Phase 8 — Media upload pipeline
        .route("/api/media/upload", post(media::upload_file))
        .route("/api/media/upload/init", post(media::chunk_init))
        .route("/api/media/upload/chunk", post(media::chunk_receive))
        .route("/api/media/upload/finalize", post(media::chunk_finalize))
        .route("/api/media/upload/progress/:upload_id", get(media::upload_progress_sse))
        // Phase 8 — CAS static file server (range-request capable)
        .route("/api/media/uploads/:filename", get(media::serve_file))
        // Phase 8 — Media telemetry stats (read-only, dashboard feed)
        .route("/api/media/stats", get(media::media_stats))
        // Phase 8 — WebDAV NAS gateway (PROPFIND/GET/PUT/DELETE via any())
        .route("/api/dav", axum::routing::any(media_dav::dav_handler))
        .route("/api/dav/", axum::routing::any(media_dav::dav_handler))
        .route("/api/dav/*path", axum::routing::any(media_dav::dav_handler))
        // WebSocket proxy — Flutter connects here, Governor resolves port from registry
        .route("/ws/:module_id", get(crate::proxy::ws_proxy::ws_proxy_handler))
        .route("/ws/:module_id/", get(crate::proxy::ws_proxy::ws_proxy_handler))
        .route("/ws/:module_id/*subpath", get(crate::proxy::ws_proxy::ws_proxy_wildcard_handler))
        // Reverse proxy route fallbacks for microservices
        .fallback(fallback_proxy_handler)
        .layer(DefaultBodyLimit::max(250 * 1024 * 1024))
        .layer(middleware::from_fn(track_performance_timing))
        .with_state(state)
}

/// Fallback handler that dynamically routes HTTP traffic to upstream services by matching request path prefixes to routes registered in module_registry.json.
async fn fallback_proxy_handler(
    State(state): State<AppState>,
    req: Request<Body>,
) -> Result<Response, (StatusCode, String)> {
    let path = req.uri().path().to_string();

    let target_addr = {
        let registry = state.registry.read().await;
        registry.values().find_map(|m| {
            if !m.route.is_empty() && path.starts_with(&format!("/api{}", m.route)) {
                Some(format!("{}:{}", m.host, m.port))
            } else {
                None
            }
        })
    };

    if let Some(target) = target_addr {
        proxy_request(req, &target).await
    } else if path.starts_with("/api/analysis") {
        proxy_request(req, "127.0.0.1:8000").await
    } else {
        Err((
            StatusCode::NOT_FOUND,
            format!("No reverse proxy route configured for path: {}", path),
        ))
    }
}
