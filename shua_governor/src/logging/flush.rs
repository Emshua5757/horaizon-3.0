// shua_governor — Bounded Flush Task & Log Persistence
//
// Drains the MPSC log channel into:
//  1. SQLite LTM (`activity.db`) with WAL mode, indexed search, and 7-day auto-prune.
//  2. Append-only `important.log` audit file (10MB rotation) for actionable ERROR/FATAL/TAG_IMPORTANT logs.
//
// Dual-trigger flush policy:
//   Trigger 1: High-water mark — flush when batch.len() >= 1024 entries.
//   Trigger 2: 500ms wall-clock timeout since last flush (heartbeat drain).

use anyhow::Result;
use rusqlite::{params, Connection};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;
use tokio::sync::mpsc;
use tokio::time::{timeout, Duration, Instant};

use crate::logging::entry::{LogEntry, LEVEL_ERROR, TAG_IMPORTANT, TAG_SECURITY};

const BATCH_HIGH_WATER_MARK: usize = 1024;
const FLUSH_INTERVAL_MS: u64 = 500;
const MAX_LOG_FILE_BYTES: u64 = 10 * 1024 * 1024; // 10 MB rotation

#[cfg(target_os = "linux")]
const DB_PATH: &str = "/var/lib/horaizon/logs/activity.db";
#[cfg(target_os = "linux")]
const IMPORTANT_LOG_PATH: &str = "/var/lib/horaizon/logs/important.log";

#[cfg(not(target_os = "linux"))]
const DB_PATH_DEV: &str = "activity.db";
#[cfg(not(target_os = "linux"))]
const IMPORTANT_LOG_PATH_DEV: &str = "important.log";

pub fn resolved_db_path() -> String {
    #[cfg(target_os = "linux")]
    {
        DB_PATH.to_string()
    }
    #[cfg(not(target_os = "linux"))]
    {
        DB_PATH_DEV.to_string()
    }
}

pub fn resolved_important_log_path() -> String {
    #[cfg(target_os = "linux")]
    {
        IMPORTANT_LOG_PATH.to_string()
    }
    #[cfg(not(target_os = "linux"))]
    {
        IMPORTANT_LOG_PATH_DEV.to_string()
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
        CREATE INDEX IF NOT EXISTS idx_activity_trace_id  ON activity_log(trace_id);
    ",
    )
}

/// Query parameters for SQLite LTM log searches
#[derive(Debug, Default)]
pub struct LogQueryParams<'a> {
    pub db_path: &'a str,
    pub min_level: Option<u8>,
    pub module: Option<u8>,
    pub subsystem: Option<&'a str>,
    pub start_ts: Option<u64>,
    pub end_ts: Option<u64>,
    pub trace_id: Option<&'a str>,
    pub limit: usize,
    pub offset: usize,
}

/// Query logs from SQLite LTM database with rich filter criteria
pub fn query_logs_from_db(params: LogQueryParams<'_>) -> Result<(usize, Vec<LogEntry>)> {
    let conn = Connection::open(params.db_path)?;

    let mut where_clause = Vec::new();
    let mut params_vec: Vec<Box<dyn rusqlite::ToSql>> = Vec::new();

    if let Some(lvl) = params.min_level {
        where_clause.push(format!("level >= ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(lvl as i64));
    }
    if let Some(m) = params.module {
        where_clause.push(format!("module = ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(m as i64));
    }
    if let Some(sub) = params.subsystem {
        where_clause.push(format!("subsystem = ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(sub.to_string()));
    }
    if let Some(st) = params.start_ts {
        where_clause.push(format!("ts >= ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(st as i64));
    }
    if let Some(et) = params.end_ts {
        where_clause.push(format!("ts <= ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(et as i64));
    }
    if let Some(tid) = params.trace_id {
        where_clause.push(format!("trace_id = ?{}", params_vec.len() + 1));
        params_vec.push(Box::new(tid.to_string()));
    }

    let where_str = if where_clause.is_empty() {
        "".to_string()
    } else {
        format!("WHERE {}", where_clause.join(" AND "))
    };

    let count_query = format!("SELECT COUNT(*) FROM activity_log {}", where_str);
    let mut count_stmt = conn.prepare(&count_query)?;
    let params_refs: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|p| p.as_ref()).collect();
    let total: usize = count_stmt.query_row(&params_refs[..], |r| r.get(0))?;

    let lim = params.limit.min(200);
    let query_sql = format!(
        "SELECT ts, level, module, subsystem, msg, tags, custom_tags, telemetry, trace_id
         FROM activity_log {} ORDER BY ts DESC LIMIT {} OFFSET {}",
        where_str, lim, params.offset
    );

    let mut stmt = conn.prepare(&query_sql)?;
    let rows = stmt.query_map(&params_refs[..], |row| {
        let ts: i64 = row.get(0)?;
        let level: i64 = row.get(1)?;
        let module: i64 = row.get(2)?;
        let subsystem: String = row.get(3)?;
        let msg: String = row.get(4)?;
        let tags: i64 = row.get(5)?;
        let custom_tags_json: Option<String> = row.get(6)?;
        let telemetry_blob: Option<Vec<u8>> = row.get(7)?;
        let trace_id: Option<String> = row.get(8)?;

        let custom_tags = custom_tags_json.and_then(|s| serde_json::from_str(&s).ok());
        let telemetry = telemetry_blob.and_then(|b| serde_json::from_slice(&b).ok());

        Ok(LogEntry {
            ts: ts as u64,
            level: level as u8,
            module: module as u8,
            subsystem,
            msg,
            tags: tags as u32,
            custom_tags,
            telemetry,
            trace_id,
        })
    })?;

    let entries = rows.flatten().collect();
    Ok((total, entries))
}

fn rotate_important_log_if_needed(path: &str) {
    if let Ok(meta) = fs::metadata(path) {
        if meta.len() >= MAX_LOG_FILE_BYTES {
            let backup2 = format!("{}.2", path);
            let backup1 = format!("{}.1", path);
            let _ = fs::rename(&backup1, &backup2);
            let _ = fs::rename(path, &backup1);
        }
    }
}

pub async fn flush_loop(
    mut log_rx: mpsc::Receiver<LogEntry>,
    log_broadcast_tx: tokio::sync::broadcast::Sender<LogEntry>,
) {
    let mut batch: Vec<LogEntry> = Vec::with_capacity(BATCH_HIGH_WATER_MARK);
    let mut deadline = Instant::now() + Duration::from_millis(FLUSH_INTERVAL_MS);
    let db_path = resolved_db_path();
    let important_log_path = resolved_important_log_path();

    tracing::info!(
        subsystem = "log_flush",
        db_path = db_path,
        important_log = important_log_path,
        "Log flush task started (HWM={}, interval={}ms)",
        BATCH_HIGH_WATER_MARK,
        FLUSH_INTERVAL_MS
    );

    let db_path_clone = db_path.clone();
    let important_log_clone = important_log_path.clone();
    let (db_tx, db_rx) = std::sync::mpsc::channel::<Vec<LogEntry>>();

    std::thread::spawn(move || {
        if let Some(parent) = Path::new(&db_path_clone).parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        let mut conn = match Connection::open(&db_path_clone) {
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

        let mut last_prune_ts = std::time::Instant::now();

        while let Ok(batch) = db_rx.recv() {
            // 1. Write batch to SQLite LTM
            let tx = match conn.transaction() {
                Ok(t) => t,
                Err(e) => {
                    tracing::error!(
                        subsystem = "log_flush",
                        "Failed to begin transaction: {}",
                        e
                    );
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

            let _ = tx.commit();

            // 2. Write actionable high-severity entries to important.log (exclude transient warnings)
            rotate_important_log_if_needed(&important_log_clone);
            if let Ok(mut f) = OpenOptions::new()
                .create(true)
                .append(true)
                .open(&important_log_clone)
            {
                for entry in &batch {
                    let is_actionable = entry.level >= LEVEL_ERROR
                        || (entry.tags & (TAG_IMPORTANT | TAG_SECURITY)) != 0;
                    if is_actionable {
                        let line = format!(
                            "[{}] [LVL:{}] [MOD:{}] [{}] {}\n",
                            entry.ts, entry.level, entry.module, entry.subsystem, entry.msg
                        );
                        let _ = f.write_all(line.as_bytes());
                    }
                }
            }

            // 3. Auto-prune records older than 7 days once per hour
            if last_prune_ts.elapsed() > Duration::from_secs(3600) {
                let seven_days_ago_ms = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64
                    - (7 * 24 * 3600 * 1000);
                let _ = conn.execute(
                    "DELETE FROM activity_log WHERE ts < ?1",
                    params![seven_days_ago_ms as i64],
                );
                last_prune_ts = std::time::Instant::now();
            }
        }
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
