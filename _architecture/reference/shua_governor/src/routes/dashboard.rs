// shua_governor — Dynamic SDUI-4 Dashboard Route Handler
// Architecture spec: _architecture/sdui4/masterplan-sdui4.md
// Phase 8: media_db, media_dir, media_stats injected into AppState.

use std::{path::PathBuf, sync::Arc};

use axum::{
    extract::State,
    http::{header, HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use rusqlite::Connection;
use tokio::sync::{broadcast, Mutex};
use crate::governor::media_gc::SharedMediaStats;
use crate::governor::registry::{display_state, ModuleRegistry, SharedSystemMetrics};
use crate::routes::sse_metrics::MetricsSnapshot;
use crate::logging::entry::{LogEntry, LogSender};
use serde_json::Value;

#[derive(Clone)]
pub struct AppState {
    pub registry:            ModuleRegistry,
    /// Cached dashboard blueprint JSON string. Loaded once at boot, avoids repeated disk I/O.
    pub dashboard_blueprint: String,
    /// Cached console blueprint JSON string. Loaded once at boot, avoids repeated disk I/O.
    pub console_blueprint:   String,
    /// Broadcast sender for SSE /api/metrics/stream — supervisor publishes, SSE handler subscribes.
    /// O(1) clone via Arc-backed broadcast::Sender internals.
    pub metrics_tx:          broadcast::Sender<MetricsSnapshot>,
    /// Shared system-wide metrics (cpu_pct, temp_c, ram_mb). Written every 2s by supervisor,
    /// read by dashboard handler to inject keys 80/81 without re-reading /proc.
    pub system_metrics:      SharedSystemMetrics,
    /// MPSC sender — subsystems push LogEntry into the 4096-entry ring-buffer. O(1) send.
    pub log_tx:              LogSender,
    /// Broadcast sender for live SSE log tail at GET /api/logs/stream.
    /// Flush task publishes each entry before batching to SQLite; SSE handler subscribes.
    pub log_broadcast_tx:    broadcast::Sender<LogEntry>,
    // ── Phase 8: Media subsystem ──────────────────────────────────────────────
    /// Dedicated rusqlite connection for media.db (pool-isolated from logs.db per §10).
    /// Arc<Mutex<>> allows cheap clone into each handler without holding a lock on the hot path.
    pub media_db:            Arc<Mutex<Connection>>,
    /// Absolute path to the NVMe media root directory. Resolved once at boot from env var.
    pub media_dir:           Arc<PathBuf>,
    /// Live storage telemetry snapshot. Refreshed every 60s by disk monitor loop.
    /// Dashboard handler reads this on every SDUI render — no DB query on the hot path.
    pub media_stats:         SharedMediaStats,
}

pub async fn get_dashboard(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let registry_guard = state.registry.read().await;

    // 1. Parse blueprint from in-memory cache (O(1) string clone — no disk I/O on hot path)
    let mut payload: Value = serde_json::from_str(&state.dashboard_blueprint).map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Failed parsing dashboard blueprint schema JSON: {}", e),
        )
    })?;

    // 2. Read live system metrics from shared in-memory snapshot (O(1) read lock).
    //    The supervisor updates this every 2s — no /proc reads on the dashboard hot path.
    let (system_rss_mb, ram_pct, sys_cpu_pct, temp_c) = {
        let sm = state.system_metrics.read().await;
        (sm.ram_mb, sm.ram_pct, sm.cpu_pct, sm.temp_c)
    };

    // 3. Inject live system metrics into health card node
    if let Some(root_children) = payload.get_mut(0).and_then(|v| v.get_mut("2")).and_then(|v| v.as_array_mut()) {
        if let Some(health_card) = root_children.get_mut(1) {
            if let Some(health_children) = health_card.get_mut("2").and_then(|v| v.as_array_mut()) {
                if let Some(ram_node) = health_children.get_mut(3) {
                    if let Some(content) = ram_node.get_mut("4") {
                        content["0"]  = serde_json::json!(ram_pct);
                        content["1"]  = serde_json::json!(
                            format!("Active RSS RAM: {:.1} MB / 8 GB", system_rss_mb)
                        );
                        content["80"] = serde_json::json!(format!("{:.1}%", sys_cpu_pct));
                        content["81"] = serde_json::json!(format!("{:.1}°C", temp_c));
                    }
                }
            }
        }
    }

    // Phase 8 — Inject live NAS storage stats into health card (O(1) read lock, no DB query)
    // Keys 83-88 are reserved for storage telemetry in the health card node.
    {
        let ms = state.media_stats.read().await;
        let storage_ratio = (ms.disk_used_pct / 100.0) as f64;
        let storage_bytes_gb = ms.total_bytes as f64 / 1_073_741_824.0;

        if let Some(root_children) = payload.get_mut(0).and_then(|v| v.get_mut("2")).and_then(|v| v.as_array_mut()) {
            if let Some(health_card) = root_children.get_mut(1) {
                if let Some(health_children) = health_card.get_mut("2").and_then(|v| v.as_array_mut()) {
                    if let Some(nas_node) = health_children.get_mut(5) {
                        if let Some(content) = nas_node.get_mut("4") {
                            // Key 83: disk used ratio (0.0–1.0) for NAS progress bar
                            content["83"] = serde_json::json!(storage_ratio.min(1.0));
                            // Key 84: human-readable disk label
                            content["84"] = serde_json::json!(
                                format!("NAS Disk: {:.1}% — {} files ({:.2} GB stored)",
                                    ms.disk_used_pct, ms.total_files, storage_bytes_gb)
                            );
                            // Key 85: pending embeddings count
                            content["85"] = serde_json::json!(format!("{} embeddings queued", ms.pending_embeddings));
                            // Key 86: storage full flag (bool → string for SDUI label)
                            content["86"] = serde_json::json!(if crate::governor::media_gc::IS_STORAGE_FULL.load(std::sync::atomic::Ordering::Relaxed) {
                                "⚠ STORAGE FULL"
                            } else {
                                ""
                            });
                        }
                    }
                }
            }
        }
    }

    // 4. Inject per-module live telemetry into each Type ID 39 ModuleCard node
    inject_module_telemetry(&mut payload, &registry_guard);


    let accept_header = headers
        .get(header::ACCEPT)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    if accept_header.contains("application/msgpack") {
        let bytes = rmp_serde::to_vec(&payload).map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("MsgPack serialization failed: {}", e),
            )
        })?;
        Ok((
            StatusCode::OK,
            [(header::CONTENT_TYPE, "application/msgpack")],
            bytes,
        )
            .into_response())
    } else {
        Ok(Json(payload).into_response())
    }
}

pub async fn get_console(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let payload: Value = serde_json::from_str(&state.console_blueprint).map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Failed parsing console blueprint schema JSON: {}", e),
        )
    })?;

    let accept_header = headers
        .get(header::ACCEPT)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    if accept_header.contains("application/msgpack") {
        let bytes = rmp_serde::to_vec(&payload).map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("MsgPack serialization failed: {}", e),
            )
        })?;
        Ok((
            StatusCode::OK,
            [(header::CONTENT_TYPE, "application/msgpack")],
            bytes,
        )
            .into_response())
    } else {
        Ok(Json(payload).into_response())
    }
}

/// Recursively walks the SDUI-4 AST and enriches every Type ID 39 (ModuleCard) node
/// with live telemetry from the registry:
///   Content Key 72 = state label  (e.g. "RUNNING", "STOPPED", "FROZEN")
///   Content Key 73 = RAM label    (e.g. "24.5 MB")
///   Content Key 74 = port label   (e.g. "3001")
fn inject_module_telemetry(
    node: &mut Value,
    registry: &std::collections::HashMap<String, crate::governor::registry::ModuleEntry>,
) {
    if let Some(arr) = node.as_array_mut() {
        for item in arr.iter_mut() {
            inject_module_telemetry(item, registry);
        }
        return;
    }

    if let Some(obj) = node.as_object_mut() {
        // Check if this node is Type ID 39 (ModuleCard)
        let type_id = obj.get("0").and_then(|v| v.as_i64()).unwrap_or(-1);
        if type_id == 39 {
            // Read module ID from content key "0"
            let module_id = obj
                .get("4")
                .and_then(|c| c.get("0"))
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();

            if let Some(entry) = registry.get(&module_id) {
                let state_label = display_state(&entry.state);
                let ram_mb = entry.ram_bytes as f64 / 1024.0 / 1024.0;
                let ram_label = if entry.ram_bytes > 0 {
                    format!("{:.1} MB", ram_mb)
                } else {
                    "—".to_string()
                };
                let port_label = format!(":{}", entry.port);

                let content = obj.entry("4").or_insert_with(|| serde_json::json!({}));
                content["70"] = serde_json::json!(entry.display_name);
                content["71"] = serde_json::json!(entry.icon);
                content["72"] = serde_json::json!(state_label);
                content["73"] = serde_json::json!(ram_label);
                content["74"] = serde_json::json!(port_label);
                content["75"] = serde_json::json!(entry.route);
                content["76"] = serde_json::json!(format!("/sdui_modal/preactivation_{}", module_id));
                content["77"] = serde_json::json!(format!("/api/governor/control/{}/stop",     module_id));
                content["78"] = serde_json::json!(format!("/api/governor/control/{}/freeze",   module_id));
                content["79"] = serde_json::json!(format!("/api/governor/control/{}/unfreeze", module_id));
                content["82"] = serde_json::json!(format!("{:.1}%", entry.cpu_pct));
                content["85"] = serde_json::json!(entry.shimmer_style);
            }
        }



        // Recurse into children
        if let Some(children) = obj.get_mut("2") {
            inject_module_telemetry(children, registry);
        }
    }
}
