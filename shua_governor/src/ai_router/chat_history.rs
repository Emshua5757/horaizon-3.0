// shua_governor — Chat History Persistence
//
// Stores and retrieves the global chat session message history from the
// same `activity.db` SQLite database used by the logging subsystem.
//
// Schema (appended to activity.db via ensure_chat_schema):
//   chat_history(id, session TEXT, role TEXT, content TEXT, ts INTEGER)
//
// Design constraints (RPi5 / Pi5 NVMe):
//   - All DB calls are synchronous blocking (rusqlite) — caller must spawn_blocking.
//   - Sliding window: only last N=8 turns loaded per request. O(log n) index scan.
//   - No in-memory cache needed; NVMe SQLite reads are sub-millisecond.

use anyhow::Result;
use rusqlite::{params, Connection};
use tracing::{info, warn};

use crate::ollama::client::ChatMessage;

/// Maximum number of prior messages to inject as context per agent loop run.
pub const CONTEXT_WINDOW_SIZE: usize = 8;

/// Persistent chat history backed by SQLite activity.db.
pub struct ChatHistoryStore {
    db_path: String,
}

impl ChatHistoryStore {
    pub fn new(db_path: &str) -> Self {
        Self { db_path: db_path.to_string() }
    }

    /// Ensure `chat_history` table and index exist in activity.db.
    pub fn ensure_schema(&self) -> Result<()> {
        let conn = Connection::open(&self.db_path)?;
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS chat_history (
                id      INTEGER PRIMARY KEY AUTOINCREMENT,
                session TEXT    NOT NULL,
                role    TEXT    NOT NULL,
                content TEXT    NOT NULL,
                ts      INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_chat_session_ts
                ON chat_history(session, ts DESC);
            ",
        )?;
        Ok(())
    }

    /// Load the last `CONTEXT_WINDOW_SIZE` messages for `session_id`, ordered
    /// chronologically (oldest first) so they can be prepended as context.
    ///
    /// Returns an empty Vec if the session is new or the DB is unavailable.
    pub fn load_context(&self, session_id: &str) -> Vec<ChatMessage> {
        let conn = match Connection::open(&self.db_path) {
            Ok(c) => c,
            Err(e) => {
                warn!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    error = %e,
                    "Failed to open activity.db for context load"
                );
                return vec![];
            }
        };

        // SELECT last N rows for session, then reverse to chronological order
        let sql = "
            SELECT role, content FROM (
                SELECT role, content, ts
                FROM chat_history
                WHERE session = ?1
                ORDER BY ts DESC
                LIMIT ?2
            ) ORDER BY ts ASC
        ";

        let mut stmt = match conn.prepare(sql) {
            Ok(s) => s,
            Err(e) => {
                warn!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    error = %e,
                    "Failed to prepare chat history query"
                );
                return vec![];
            }
        };

        let rows = stmt.query_map(params![session_id, CONTEXT_WINDOW_SIZE as i64], |row| {
            let role: String  = row.get(0)?;
            let content: String = row.get(1)?;
            Ok((role, content))
        });

        match rows {
            Ok(iter) => {
                let messages: Vec<ChatMessage> = iter
                    .filter_map(|r| r.ok())
                    .map(|(role, content)| ChatMessage {
                        role,
                        content,
                        tool_calls: None,
                    })
                    .collect();

                info!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    loaded = messages.len(),
                    "Loaded chat context from SQLite"
                );
                messages
            }
            Err(e) => {
                warn!(
                    subsystem = "chat_history",
                    session_id = session_id,
                    error = %e,
                    "Failed to query chat history rows"
                );
                vec![]
            }
        }
    }

    /// Persist a single message turn to `chat_history` for the given session.
    /// `role` is `"user"` or `"assistant"`.
    pub fn append(&self, session_id: &str, role: &str, content: &str) -> Result<()> {
        let conn = Connection::open(&self.db_path)?;
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis() as i64)
            .unwrap_or(0);
        conn.execute(
            "INSERT INTO chat_history (session, role, content, ts) VALUES (?1, ?2, ?3, ?4)",
            params![session_id, role, content, ts],
        )?;

        info!(
            subsystem = "chat_history",
            session_id = session_id,
            role = role,
            content_len = content.len(),
            "Appended message to chat history"
        );
        Ok(())
    }

    /// Prune messages older than `max_age_days` for a session.
    /// Called opportunistically; failures are logged but not fatal.
    pub fn prune_old(&self, max_age_days: u64) {
        let cutoff_ms = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis() as i64 - (max_age_days as i64 * 86_400_000))
            .unwrap_or(0);

        if let Ok(conn) = Connection::open(&self.db_path) {
            let _ = conn.execute(
                "DELETE FROM chat_history WHERE ts < ?1",
                params![cutoff_ms],
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chat_history_roundtrip() {
        let tmp = std::env::temp_dir().join("test_chat_history.db");
        let store = ChatHistoryStore::new(tmp.to_str().unwrap());
        store.ensure_schema().expect("schema ok");

        let session = "test-session-001";
        store.append(session, "user", "Hello JOSH").unwrap();
        store.append(session, "assistant", "Hello Joshua!").unwrap();

        let ctx = store.load_context(session);
        assert_eq!(ctx.len(), 2);
        assert_eq!(ctx[0].role, "user");
        assert_eq!(ctx[0].content, "Hello JOSH");
        assert_eq!(ctx[1].role, "assistant");

        // Cleanup
        let _ = std::fs::remove_file(&tmp);
    }

    #[test]
    fn test_context_window_limit() {
        let tmp = std::env::temp_dir().join("test_chat_window.db");
        let store = ChatHistoryStore::new(tmp.to_str().unwrap());
        store.ensure_schema().expect("schema ok");

        let session = "test-session-002";
        for i in 0..12 {
            store.append(session, "user", &format!("msg {i}")).unwrap();
        }

        let ctx = store.load_context(session);
        assert!(ctx.len() <= CONTEXT_WINDOW_SIZE, "Window must be capped at {CONTEXT_WINDOW_SIZE}");

        let _ = std::fs::remove_file(&tmp);
    }
}
