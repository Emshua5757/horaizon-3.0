// shua_governor — Bounded Flush Task (Phase 12)
//
// Background Tokio task that drains the MPSC log channel into SQLite LTM.
//
// Dual-trigger flush policy:
//   Trigger 1: High-water mark — flush when batch.len() >= 1024 entries.
//   Trigger 2: 500ms wall-clock timeout since last flush (heartbeat drain).

use crate::logging::entry::LogEntry;
use rusqlite::{params, Connection};
use std::path::Path;
use tokio::sync::mpsc;
use tokio::time::{timeout, Duration, Instant};

const BATCH_HIGH_WATER_MARK: usize = 1024;
const FLUSH_INTERVAL_MS: u64 = 500;

#[cfg(target_os = "linux")]
const DB_PATH: &str = "/var/lib/horaizon/logs/activity.db";

#[cfg(not(target_os = "linux"))]
const DB_PATH_DEV: &str = "activity.db";

fn resolved_db_path() -> &'static str {
    #[cfg(target_os = "linux")]
    {
        DB_PATH
    }
    #[cfg(not(target_os = "linux"))]
    {
        DB_PATH_DEV
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
    ",
    )
}

pub async fn flush_loop(
    mut log_rx: mpsc::Receiver<LogEntry>,
    log_broadcast_tx: tokio::sync::broadcast::Sender<LogEntry>,
) {
    let mut batch: Vec<LogEntry> = Vec::with_capacity(BATCH_HIGH_WATER_MARK);
    let mut deadline = Instant::now() + Duration::from_millis(FLUSH_INTERVAL_MS);
    let db_path = resolved_db_path().to_owned();

    tracing::info!(
        subsystem = "log_flush",
        db_path = db_path,
        "Log flush task started (HWM={}, interval={}ms)",
        BATCH_HIGH_WATER_MARK,
        FLUSH_INTERVAL_MS
    );

    let path_clone = db_path.clone();
    let (db_tx, db_rx) = std::sync::mpsc::channel::<Vec<LogEntry>>();

    std::thread::spawn(move || {
        if let Some(parent) = Path::new(&path_clone).parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        let mut conn = match Connection::open(&path_clone) {
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

        tracing::info!(
            subsystem = "log_flush",
            "Database writer thread initialized successfully"
        );

        while let Ok(batch) = db_rx.recv() {
            let tx = match conn.transaction() {
                Ok(t) => t,
                Err(e) => {
                    tracing::error!(subsystem = "log_flush", "Failed to begin transaction: {}", e);
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

            if let Err(e) = tx.commit() {
                tracing::error!(subsystem = "log_flush", "Transaction commit failed: {}", e);
            } else {
                tracing::debug!(
                    subsystem = "log_flush",
                    count = batch.len(),
                    "Flushed {} log entries to SQLite",
                    batch.len()
                );
            }
        }

        tracing::info!(subsystem = "log_flush", "Database writer thread terminated");
    });

    loop {
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
                tracing::info!(
                    subsystem = "log_flush",
                    "Log flush task terminated (channel closed)"
                );
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
