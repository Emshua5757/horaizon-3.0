use rusqlite::Connection;
use tracing::warn;
use crate::logging::flush::resolved_db_path;

#[derive(Debug, Clone)]
pub struct ScopeMemoryEntry {
    pub scope: String,
    pub key: String,
    pub value: String,
    pub source: String,
    pub session_id: Option<String>,
    pub created_at: u64,
}

pub struct ScopeMemoryStore;

impl ScopeMemoryStore {
    /// Load all persistent memory entries for a given scope, ordered by created_at DESC.
    /// Returns an empty Vec gracefully if DB read fails or table has no facts.
    pub fn load(scope: &str) -> Vec<ScopeMemoryEntry> {
        let db_path = resolved_db_path();
        let conn = match Connection::open(&db_path) {
            Ok(c) => c,
            Err(e) => {
                warn!(subsystem = "scope_memory", db_path = %db_path, error = %e, "Could not open activity.db for scope_memory read");
                return Vec::new();
            }
        };

        let mut stmt = match conn.prepare(
            "SELECT scope, key, value, source, session_id, created_at FROM scope_memory WHERE scope = ?1 ORDER BY created_at DESC LIMIT 20"
        ) {
            Ok(s) => s,
            Err(e) => {
                warn!(subsystem = "scope_memory", scope = scope, error = %e, "Could not prepare scope_memory query");
                return Vec::new();
            }
        };

        let rows = match stmt.query_map([scope], |row| {
            Ok(ScopeMemoryEntry {
                scope: row.get(0)?,
                key: row.get(1)?,
                value: row.get(2)?,
                source: row.get(3)?,
                session_id: row.get(4)?,
                created_at: row.get(5)?,
            })
        }) {
            Ok(mapped) => mapped.filter_map(|r| r.ok()).collect(),
            Err(_) => Vec::new(),
        };

        rows
    }

    /// Upserts a persistent memory entry for a target scope.
    /// Used by memory formation logic (TASK-future).
    #[allow(dead_code)]
    pub fn upsert(entry: &ScopeMemoryEntry) -> anyhow::Result<()> {
        let db_path = resolved_db_path();
        let conn = Connection::open(&db_path)?;
        let ts = if entry.created_at == 0 {
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs()
        } else {
            entry.created_at
        };

        conn.execute(
            "INSERT INTO scope_memory (scope, key, value, source, session_id, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(scope, key) DO UPDATE SET value=?3, source=?4, session_id=?5, created_at=?6",
            rusqlite::params![
                entry.scope,
                entry.key,
                entry.value,
                entry.source,
                entry.session_id,
                ts
            ],
        )?;

        Ok(())
    }
}
