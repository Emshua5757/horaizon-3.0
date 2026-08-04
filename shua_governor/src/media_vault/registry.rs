use anyhow::{Context, Result};
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Mutex;
use tracing::info;

/// A single media asset record in the vault registry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaAsset {
    pub sha256_hash: String,
    pub module: String,
    pub file_path: String,
    pub file_name: String,
    pub mime_type: String,
    pub file_size: i64,
    pub ref_count: i64,
    pub uploaded_by: String,
    pub created_at: String,
    pub last_accessed: String,
}

/// Paginated list of media assets.
#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
pub struct MediaAssetPage {
    pub items: Vec<MediaAsset>,
    pub total: u32,
    pub has_more: bool,
}

/// SQLite-backed registry for media vault assets (stored in activity.db).
pub struct VaultRegistry {
    conn: Mutex<Connection>,
}

impl VaultRegistry {
    /// Open (or create) the registry in the given SQLite path.
    pub fn open(db_path: &std::path::Path) -> Result<Self> {
        let conn = Connection::open(db_path)
            .with_context(|| format!("Failed to open vault registry DB at {}", db_path.display()))?;

        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;

        conn.execute_batch(
            r#"
            CREATE TABLE IF NOT EXISTS media_assets (
                sha256_hash   TEXT    PRIMARY KEY,
                module        TEXT    NOT NULL,
                file_path     TEXT    NOT NULL,
                file_name     TEXT    NOT NULL,
                mime_type     TEXT    NOT NULL,
                file_size     INTEGER NOT NULL,
                ref_count     INTEGER NOT NULL DEFAULT 1,
                uploaded_by   TEXT    NOT NULL DEFAULT 'shua',
                created_at    TEXT    NOT NULL,
                last_accessed TEXT    NOT NULL
            );
            "#,
        )?;

        info!(
            subsystem = "vault_registry",
            db = %db_path.display(),
            "VaultRegistry opened — media_assets schema ensured"
        );

        Ok(Self {
            conn: Mutex::new(conn),
        })
    }

    /// Insert a new asset row. Returns `true` if newly inserted, `false` if
    /// it already existed (ref_count incremented).
    #[allow(clippy::too_many_arguments)]
    pub fn insert_or_increment(
        &self,
        sha256: &str,
        module: &str,
        file_path: &str,
        file_name: &str,
        mime_type: &str,
        file_size: i64,
        uploaded_by: &str,
    ) -> Result<bool> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");
        let now = chrono::Utc::now().to_rfc3339();

        // Try to find existing row
        let existing: Option<i64> = conn
            .query_row(
                "SELECT ref_count FROM media_assets WHERE sha256_hash = ?1",
                params![sha256],
                |row| row.get(0),
            )
            .ok();

        if let Some(_rc) = existing {
            // Already exists — just bump ref_count and update last_accessed
            conn.execute(
                "UPDATE media_assets SET ref_count = ref_count + 1, last_accessed = ?1 WHERE sha256_hash = ?2",
                params![now, sha256],
            )?;
            info!(
                subsystem = "vault_registry",
                sha256 = %sha256,
                module = %module,
                "Deduplicated upload — ref_count incremented"
            );
            Ok(false) // not newly created
        } else {
            conn.execute(
                r#"INSERT INTO media_assets
                   (sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed)
                   VALUES (?1, ?2, ?3, ?4, ?5, ?6, 1, ?7, ?8, ?8)"#,
                params![sha256, module, file_path, file_name, mime_type, file_size, uploaded_by, now],
            )?;
            info!(
                subsystem = "vault_registry",
                sha256 = %sha256,
                module = %module,
                file_size = file_size,
                "New asset inserted into vault registry"
            );
            Ok(true) // newly created
        }
    }

    /// Fetch a single asset by SHA256 hash.
    pub fn get(&self, sha256: &str) -> Result<Option<MediaAsset>> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");
        let now = chrono::Utc::now().to_rfc3339();
        // Update last_accessed on read
        let _ = conn.execute(
            "UPDATE media_assets SET last_accessed = ?1 WHERE sha256_hash = ?2",
            params![now, sha256],
        );
        let mut stmt = conn.prepare(
            "SELECT sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed FROM media_assets WHERE sha256_hash = ?1"
        )?;
        let result = stmt
            .query_row(params![sha256], |row| {
                Ok(MediaAsset {
                    sha256_hash: row.get(0)?,
                    module: row.get(1)?,
                    file_path: row.get(2)?,
                    file_name: row.get(3)?,
                    mime_type: row.get(4)?,
                    file_size: row.get(5)?,
                    ref_count: row.get(6)?,
                    uploaded_by: row.get(7)?,
                    created_at: row.get(8)?,
                    last_accessed: row.get(9)?,
                })
            })
            .ok();
        Ok(result)
    }

    /// List assets, optionally filtered by module, with pagination.
    /// Returns (items, total_count).
    pub fn list(
        &self,
        module_filter: Option<&str>,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<MediaAsset>, u32)> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");
        let offset = page * page_size;

        let (count_sql, list_sql, use_filter) = if let Some(m) = module_filter {
            let _ = m; // used below via params
            (
                "SELECT COUNT(*) FROM media_assets WHERE module = ?1",
                "SELECT sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed FROM media_assets WHERE module = ?1 ORDER BY created_at DESC LIMIT ?2 OFFSET ?3",
                true,
            )
        } else {
            (
                "SELECT COUNT(*) FROM media_assets",
                "SELECT sha256_hash, module, file_path, file_name, mime_type, file_size, ref_count, uploaded_by, created_at, last_accessed FROM media_assets ORDER BY created_at DESC LIMIT ?1 OFFSET ?2",
                false,
            )
        };

        let total: u32 = if use_filter {
            conn.query_row(count_sql, params![module_filter.unwrap()], |r| r.get(0))?
        } else {
            conn.query_row(count_sql, [], |r| r.get(0))?
        };

        let mut stmt = conn.prepare(list_sql)?;
        let rows: Vec<MediaAsset> = if use_filter {
            stmt.query_map(
                params![module_filter.unwrap(), page_size, offset],
                |row| {
                    Ok(MediaAsset {
                        sha256_hash: row.get(0)?,
                        module: row.get(1)?,
                        file_path: row.get(2)?,
                        file_name: row.get(3)?,
                        mime_type: row.get(4)?,
                        file_size: row.get(5)?,
                        ref_count: row.get(6)?,
                        uploaded_by: row.get(7)?,
                        created_at: row.get(8)?,
                        last_accessed: row.get(9)?,
                    })
                },
            )?
            .filter_map(|r| r.ok())
            .collect()
        } else {
            stmt.query_map(params![page_size, offset], |row| {
                Ok(MediaAsset {
                    sha256_hash: row.get(0)?,
                    module: row.get(1)?,
                    file_path: row.get(2)?,
                    file_name: row.get(3)?,
                    mime_type: row.get(4)?,
                    file_size: row.get(5)?,
                    ref_count: row.get(6)?,
                    uploaded_by: row.get(7)?,
                    created_at: row.get(8)?,
                    last_accessed: row.get(9)?,
                })
            })?
            .filter_map(|r| r.ok())
            .collect()
        };

        Ok((rows, total))
    }

    /// Decrement ref_count. Returns the new ref_count, and the file_path if the
    /// row was physically deleted (ref_count reached 0). Both operations execute
    /// inside a single SQLite transaction — atomic by design.
    pub fn decrement_ref(&self, sha256: &str) -> Result<(i64, Option<PathBuf>)> {
        let conn = self.conn.lock().expect("vault_registry mutex poisoned");

        // Begin transaction
        conn.execute_batch("BEGIN;").context("BEGIN transaction")?;

        // Fetch current ref_count (inside transaction)
        let rc: i64 = match conn.query_row(
            "SELECT ref_count FROM media_assets WHERE sha256_hash = ?1",
            params![sha256],
            |r| r.get(0),
        ) {
            Ok(v) => v,
            Err(e) => {
                let _ = conn.execute_batch("ROLLBACK;");
                return Err(anyhow::anyhow!("SHA256 '{}' not found: {e}", sha256));
            }
        };

        if rc <= 1 {
            // Fetch file path before deleting row
            let path: String = match conn.query_row(
                "SELECT file_path FROM media_assets WHERE sha256_hash = ?1",
                params![sha256],
                |r| r.get(0),
            ) {
                Ok(p) => p,
                Err(e) => {
                    let _ = conn.execute_batch("ROLLBACK;");
                    return Err(anyhow::anyhow!("file_path query failed: {e}"));
                }
            };
            if let Err(e) = conn.execute(
                "DELETE FROM media_assets WHERE sha256_hash = ?1",
                params![sha256],
            ) {
                let _ = conn.execute_batch("ROLLBACK;");
                return Err(anyhow::anyhow!("DELETE failed: {e}"));
            }
            conn.execute_batch("COMMIT;").context("COMMIT delete")?;
            Ok((0, Some(PathBuf::from(path))))
        } else {
            if let Err(e) = conn.execute(
                "UPDATE media_assets SET ref_count = ref_count - 1 WHERE sha256_hash = ?1",
                params![sha256],
            ) {
                let _ = conn.execute_batch("ROLLBACK;");
                return Err(anyhow::anyhow!("UPDATE ref_count failed: {e}"));
            }
            conn.execute_batch("COMMIT;").context("COMMIT decrement")?;
            Ok((rc - 1, None))
        }
    }
}
