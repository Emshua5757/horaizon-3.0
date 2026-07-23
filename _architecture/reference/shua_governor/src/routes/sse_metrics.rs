// shua_governor — SSE Real-Time Metrics Stream
// Phase 11.8 | GET /api/metrics/stream
//
// Design:
//   The supervisor loop publishes a MetricsSnapshot to a broadcast::channel every 2s.
//   This handler subscribes and streams each snapshot as an SSE "data:" frame.
//
//   O(1) fan-out: N Flutter clients each hold a broadcast::Receiver. The supervisor
//   writes once per tick regardless of subscriber count. No per-subscriber work on
//   the publish side.
//
//   Channel capacity = 4: a slow client can lag up to 4 ticks (8s) before frames
//   are dropped. This is acceptable for a metrics stream.
//
//   No dedicated core needed: Tokio parks the subscriber task between wakeups.
//   The RPi 5's work-stealing scheduler handles this efficiently.

use std::collections::HashMap;
use std::convert::Infallible;
use std::time::Duration;
use axum::{
    extract::State,
    response::sse::{Event, KeepAlive, Sse},
};
use futures_util::stream;
use serde::{Deserialize, Serialize};
use tokio::sync::broadcast;
use crate::routes::dashboard::AppState;

// ──────────────────────────────────────────────────────────────────────────────
// Data Types
// ──────────────────────────────────────────────────────────────────────────────

/// Per-module telemetry fields included in each MetricsSnapshot.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleMetrics {
    /// State label: "ACTIVE", "STOPPED", "STARTING", "FROZEN", etc.
    pub state:   String,
    /// Current RSS RAM in megabytes.
    pub ram_mb:  f64,
    /// CPU utilisation 0.0–100.0 (per-core, not system-normalised).
    pub cpu_pct: f32,
}

/// Compact system snapshot broadcast by the supervisor every 2 seconds.
/// JSON-serialised and streamed as SSE "data:" frames.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MetricsSnapshot {
    /// Unix timestamp (seconds) when this snapshot was taken.
    pub ts:      u64,
    /// System-wide CPU utilisation (0.0–100.0).
    pub cpu_pct: f32,
    /// RPi 5 CPU die temperature in °C.
    pub temp_c:  f32,
    /// Total RSS RAM across governor + all running modules (MB).
    pub ram_mb:  f64,
    /// Fraction of the 8 GB RPi 5 RAM ceiling consumed (0.0–1.0).
    pub ram_pct: f64,
    /// NVMe disk utilization percentage (0.0–100.0).
    pub disk_used_pct: f64,
    /// Per-module telemetry keyed by module_id (e.g. "shua_diary").
    pub modules: HashMap<String, ModuleMetrics>,
}

// ──────────────────────────────────────────────────────────────────────────────
// SSE Handler
// ──────────────────────────────────────────────────────────────────────────────

/// GET /api/metrics/stream
///
/// Opens a Server-Sent Events connection. The client receives a JSON metrics
/// packet every 2 seconds for as long as the connection is open.
///
/// Example SSE frame:
///   data: {"ts":1751234567,"cpu_pct":12.3,"temp_c":54.1,"ram_mb":412.5,"ram_pct":0.05,
///          "modules":{"shua_diary":{"state":"ACTIVE","ram_mb":24.5,"cpu_pct":1.2}}}
///
/// Clients that lag more than 4 frames (8s) will receive a stream error and should
/// reconnect. The EventSource API in browsers / http package in Dart reconnects automatically.
pub async fn stream_metrics(
    State(state): State<AppState>,
) -> Sse<impl futures_util::Stream<Item = Result<Event, Infallible>>> {
    let rx: broadcast::Receiver<MetricsSnapshot> = state.metrics_tx.subscribe();

    // Build a stream by polling the broadcast receiver in a loop.
    // Each call to `unfold` receives ownership of `rx`, pulls one message,
    // then yields (event, rx) so the next iteration gets ownership again.
    // This satisfies the borrow checker: no &mut references escape the async block.
    let event_stream = stream::unfold(rx, |mut rx| async move {
        loop {
            match rx.recv().await {
                Ok(snapshot) => {
                    let json = serde_json::to_string(&snapshot)
                        .unwrap_or_else(|_| "{}".to_string());
                    let event = Event::default().data(json);
                    return Some((Ok::<Event, Infallible>(event), rx));
                }
                Err(broadcast::error::RecvError::Lagged(n)) => {
                    // Client was too slow — skip dropped frames and continue
                    tracing::warn!(subsystem = "sse_metrics", lagged_frames = n, "subscriber lagged");
                    // Continue loop — rx ownership retained, loop again
                }
                Err(broadcast::error::RecvError::Closed) => {
                    // Supervisor shut down — end the stream cleanly
                    return None;
                }
            }
        }
    });

    Sse::new(event_stream).keep_alive(
        KeepAlive::new()
            .interval(Duration::from_secs(15))
            .text("ping"),
    )
}

