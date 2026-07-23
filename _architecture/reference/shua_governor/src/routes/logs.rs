// shua_governor — Log Query, Live SSE Tail & HTTP Ingest Endpoints (Phase 12)
//
// Three endpoints:
//
//   GET  /api/logs?module=&level=&limit=
//        Query SQLite `activity_log` with optional integer filters.
//        Returns JSON array. O(log n + k) via B-tree indexes.
//
//   GET  /api/logs/stream?module=&level=
//        Server-Sent Events live tail — subscribes to the broadcast channel.
//        Only entries that pass optional server-side module/level filters are emitted.
//        Zero-polling: Tokio parks the task between broadcast wakeups.
//
//   POST /api/logs/ingest
//        Accepts a raw binary body = 12-byte HBP header + MsgPack payload.
//        Used by the Flutter GovernorLogger to upload log entries over HTTP
//        (avoids contaminating the Socket.io SDUI data channel with raw binary frames).

use std::convert::Infallible;
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::{IntoResponse, sse::{Event, Sse}},
    Json,
};
use futures_util::stream::StreamExt;
use rusqlite::Connection;
use tokio_stream::wrappers::BroadcastStream;
use crate::routes::dashboard::AppState;
use crate::logging::entry::{log_min_level, BorrowedLogEntry};

#[cfg(not(target_os = "linux"))]
const DB_PATH: &str = "activity.db";
#[cfg(target_os = "linux")]
const DB_PATH: &str = "/var/lib/horaizon/logs/activity.db";

// ──────────────────────────────────────────────────────────────────────────────
// GET /api/logs
// ──────────────────────────────────────────────────────────────────────────────

/// Query parameters for log history retrieval.
#[derive(serde::Deserialize)]
pub struct LogQueryParams {
    /// HBP module integer ID (e.g. 1 = shua_diary, 10 = shua_governor, 11 = client_flutter)
    pub module: Option<i64>,
    /// Minimum severity level (1=TRACE … 6=CRITICAL). Inclusive filter.
    pub level:  Option<i64>,
    /// Maximum rows to return. Defaults to 100. Cap: 1000.
    pub limit:  Option<i64>,
}

pub async fn query_logs(
    State(_state): State<AppState>,
    Query(params): Query<LogQueryParams>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let limit = params.limit.unwrap_or(100).min(1000);

    // SQLite access is synchronous (rusqlite) — must run on a blocking thread
    tokio::task::spawn_blocking(move || {
        let conn = Connection::open(DB_PATH).map_err(|e| {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("DB open failed: {}", e))
        })?;

        // Build query dynamically based on optional filters
        let mut sql = String::from(
            "SELECT ts, level, module, subsystem, msg, tags, custom_tags, telemetry, trace_id \
             FROM activity_log WHERE 1=1"
        );
        if params.module.is_some() { sql.push_str(" AND module = ?1"); }
        if params.level.is_some()  { sql.push_str(" AND level >= ?2"); }
        sql.push_str(" ORDER BY ts DESC LIMIT ?3");

        let mut stmt = conn.prepare(&sql).map_err(|e| {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Query prepare failed: {}", e))
        })?;

        let rows = stmt.query_map(
            rusqlite::params![
                params.module.unwrap_or(-1),
                params.level.unwrap_or(-1),
                limit
            ],
            |row| {
                Ok(serde_json::json!({
                    "ts":          row.get::<_, i64>(0)?,
                    "level":       row.get::<_, i64>(1)?,
                    "module":      row.get::<_, i64>(2)?,
                    "subsystem":   row.get::<_, String>(3)?,
                    "msg":         row.get::<_, String>(4)?,
                    "tags":        row.get::<_, i64>(5)?,
                    "custom_tags": row.get::<_, Option<String>>(6)?,
                    "trace_id":    row.get::<_, Option<String>>(8)?,
                }))
            },
        ).map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Query failed: {}", e)))?;

        let results: Vec<_> = rows.flatten().collect();
        Ok(Json(results))
    })
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Blocking task error: {}", e)))?
}

// ──────────────────────────────────────────────────────────────────────────────
// GET /api/logs/stream (SSE live tail)
// ──────────────────────────────────────────────────────────────────────────────

#[derive(serde::Deserialize)]
pub struct LogStreamParams {
    pub module: Option<u8>,
    pub level:  Option<u8>,
}

pub async fn stream_logs(
    State(state): State<AppState>,
    Query(params): Query<LogStreamParams>,
) -> Sse<impl futures_util::Stream<Item = Result<Event, Infallible>>> {
    let rx = state.log_broadcast_tx.subscribe();
    let module_filter = params.module;
    let level_filter  = params.level;

    let stream = BroadcastStream::new(rx)
        .filter_map(move |result| {
            let module_filter = module_filter;
            let level_filter  = level_filter;
            async move {
                let entry = result.ok()?;

                // Server-side filter: check module and level
                if let Some(m) = module_filter {
                    if entry.module != m { return None; }
                }
                if let Some(l) = level_filter {
                    if entry.level < l { return None; }
                }

                let json = serde_json::to_string(&entry).ok()?;
                Some(Ok::<Event, Infallible>(Event::default().data(json)))
            }
        });

    Sse::new(stream).keep_alive(
        axum::response::sse::KeepAlive::new()
            .interval(std::time::Duration::from_secs(15))
            .text("keep-alive"),
    )
}

// ──────────────────────────────────────────────────────────────────────────────
// POST /api/logs/ingest (Flutter HTTP binary uplink)
// ──────────────────────────────────────────────────────────────────────────────

/// Accepts a raw binary POST body = 12-byte HBP header + MsgPack payload.
///
/// Byte layout:
///   [0]   = 0x48 ('H')  — magic byte 0
///   [1]   = 0x42 ('B')  — magic byte 1
///   [2]   = version     — reserved
///   [3]   = 0x12        — HBP type: LOG
///   [4-7] = reserved (flags / stream ID)
///   [8-11]= payload length (u32 big-endian) — informational, not validated here
///   [12+] = MsgPack-encoded integer-keyed log map
///
/// On level gate failure or decode error, responds 204 No Content to avoid
/// retries from the Flutter fire-and-forget HTTP client.
pub async fn ingest_log(
    State(state): State<AppState>,
    body: axum::body::Bytes,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    if body.len() < 12 {
        return Err((StatusCode::BAD_REQUEST, "Body too short — expected 12-byte HBP header + MsgPack payload".to_string()));
    }

    // Validate magic bytes and type
    if body[0] != 0x48 || body[1] != 0x42 || body[3] != 0x12 {
        return Err((StatusCode::BAD_REQUEST, "Invalid HBP magic bytes or type — expected LOG (0x12)".to_string()));
    }

    let payload = &body[12..];
    let min_level = log_min_level();

    match rmp_serde::from_slice::<BorrowedLogEntry>(payload) {
        Ok(borrowed_entry) => {
            if borrowed_entry.level < min_level {
                return Ok(StatusCode::NO_CONTENT.into_response());
            }
            // Fire-and-forget: if channel is saturated, drop rather than block the HTTP response
            let _ = state.log_tx.try_send(borrowed_entry.into());
            Ok(StatusCode::ACCEPTED.into_response())
        }
        Err(e) => {
            tracing::warn!(
                subsystem = "log_ingest",
                error = %e,
                "Failed to decode MsgPack payload from POST /api/logs/ingest"
            );
            // Return 204 (not 400) — a bad log frame should never cause Flutter to retry
            Ok(StatusCode::NO_CONTENT.into_response())
        }
    }
}
