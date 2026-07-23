// shua_governor — Phase 8: Media Garbage Collector & Disk Monitor
// Architecture spec: _architecture/governor/media-server-spec.md §5, §8, §13, §14

use std::{
    path::{Path, PathBuf},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    time::Duration,
};

use rusqlite::Connection;
use sysinfo::Disks;
use tokio::sync::Mutex;

// Manual RAII guard — resets GC_RUNNING to false on drop (including panic unwinds).
// Avoids scopeguard::defer! macro syntax incompatibility.
struct GcGuard;
impl Drop for GcGuard {
    fn drop(&mut self) {
        GC_RUNNING.store(false, Ordering::SeqCst);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global atomics — checked by upload route handlers
// ─────────────────────────────────────────────────────────────────────────────

/// Set to true when disk partition exceeds 95% capacity.
/// Upload routes reject with HTTP 507 when true.
pub static IS_STORAGE_FULL: AtomicBool = AtomicBool::new(false);

/// Re-entry guard for the GC cycle.
/// Prevents overlapping GC runs on a slow NVMe under high I/O.
static GC_RUNNING: AtomicBool = AtomicBool::new(false);

// ─────────────────────────────────────────────────────────────────────────────
// Shared MediaStats — written by disk monitor, read by dashboard handler
// ─────────────────────────────────────────────────────────────────────────────

/// Live storage telemetry. Refreshed every 60 seconds by `start_disk_monitor_loop`.
#[derive(Clone, Default)]
pub struct MediaStats {
    pub total_files: u64,
    pub total_bytes: u64,
    pub disk_used_pct: f64,
    pub pending_embeddings: u64,
    pub embedding_errors: u64,
    pub temp_chunks_active: u64,
}

pub type SharedMediaStats = Arc<tokio::sync::RwLock<MediaStats>>;

pub fn new_media_stats() -> SharedMediaStats {
    Arc::new(tokio::sync::RwLock::new(MediaStats::default()))
}

// ─────────────────────────────────────────────────────────────────────────────
// § 8: Disk Monitor Loop (60-second interval)
// ─────────────────────────────────────────────────────────────────────────────

/// Spawns a 60-second interval loop that:
///   1. Reads partition usage via sysinfo::Disks
///   2. Triggers IS_STORAGE_FULL at 95%
///   3. Queries media_ledger for aggregate stats
///   4. Writes results into SharedMediaStats for dashboard injection
pub async fn start_disk_monitor_loop(
    media_dir: Arc<PathBuf>,
    db: Arc<Mutex<Connection>>,
    stats: SharedMediaStats,
) {
    loop {
        tokio::time::sleep(Duration::from_secs(60)).await;
        refresh_disk_stats(&media_dir, &db, &stats).await;
    }
}

async fn refresh_disk_stats(
    media_dir: &Path,
    db: &Arc<Mutex<Connection>>,
    stats: &SharedMediaStats,
) {
    // ── 1. Read partition usage via sysinfo ──────────────────────────────────
    let disk_used_pct: f64 = tokio::task::spawn_blocking({
        let dir = media_dir.to_path_buf();
        move || {
            let disks = Disks::new_with_refreshed_list();
            // Find the disk whose mount point is the longest prefix of media_dir
            let mut best_pct = 0.0_f64;
            let mut best_mount_len = 0usize;
            for disk in disks.list() {
                let mount = disk.mount_point();
                if dir.starts_with(mount) && mount.as_os_str().len() > best_mount_len {
                    let total = disk.total_space();
                    let avail = disk.available_space();
                    if total > 0 {
                        best_pct = (total - avail) as f64 / total as f64 * 100.0;
                        best_mount_len = mount.as_os_str().len();
                    }
                }
            }
            best_pct
        }
    })
    .await
    .unwrap_or(0.0);

    // ── 2. Update IS_STORAGE_FULL atomic based on thresholds ─────────────────
    if disk_used_pct >= 95.0 {
        let was_full = IS_STORAGE_FULL.swap(true, Ordering::SeqCst);
        if !was_full {
            tracing::error!(
                subsystem = "media_disk",
                disk_used_pct,
                "MEDIA_DISK_FULL — disk usage exceeded 95%. Uploads halted."
            );
        }
    } else if disk_used_pct >= 90.0 {
        IS_STORAGE_FULL.store(false, Ordering::SeqCst);
        tracing::warn!(
            subsystem = "media_disk",
            disk_used_pct,
            "MEDIA_DISK_WARN — disk usage exceeded 90%."
        );
    } else {
        IS_STORAGE_FULL.store(false, Ordering::SeqCst);
    }

    // ── 3. Query media_ledger for aggregate counters ──────────────────────────
    let (total_files, total_bytes, pending_embeddings, embedding_errors) =
        tokio::task::spawn_blocking({
            let db = db.clone();
            move || -> (u64, u64, u64, u64) {
                let conn = db.blocking_lock();
                let total_files: u64 = conn
                    .query_row("SELECT COUNT(*) FROM media_ledger", [], |r| r.get(0))
                    .unwrap_or(0);
                let total_bytes: u64 = conn
                    .query_row(
                        "SELECT COALESCE(SUM(size_bytes), 0) FROM media_ledger",
                        [],
                        |r| r.get(0),
                    )
                    .unwrap_or(0);
                let pending_embeddings: u64 = conn
                    .query_row(
                        "SELECT COUNT(*) FROM media_ledger WHERE allow_embedding = 1 AND embedding IS NULL",
                        [],
                        |r| r.get(0),
                    )
                    .unwrap_or(0);
                let embedding_errors: u64 = conn
                    .query_row(
                        "SELECT COUNT(*) FROM media_ledger WHERE embedding_last_error IS NOT NULL",
                        [],
                        |r| r.get(0),
                    )
                    .unwrap_or(0);
                (total_files, total_bytes, pending_embeddings, embedding_errors)
            }
        })
        .await
        .unwrap_or((0, 0, 0, 0));

    // ── 4. Count active temp chunk sessions ───────────────────────────────────
    let temp_dir = media_dir.join("temp_chunks");
    let temp_chunks_active = tokio::task::spawn_blocking(move || {
        std::fs::read_dir(temp_dir)
            .map(|rd| rd.count() as u64)
            .unwrap_or(0)
    })
    .await
    .unwrap_or(0);

    // ── 5. Write to SharedMediaStats ──────────────────────────────────────────
    {
        let mut w = stats.write().await;
        w.total_files = total_files;
        w.total_bytes = total_bytes;
        w.disk_used_pct = disk_used_pct;
        w.pending_embeddings = pending_embeddings;
        w.embedding_errors = embedding_errors;
        w.temp_chunks_active = temp_chunks_active;
    }

    tracing::debug!(
        subsystem = "media_disk",
        total_files,
        total_bytes,
        disk_used_pct,
        "Disk stats refreshed"
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// § 5: Lenient Garbage Collection Loop
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps `run_garbage_collection` in a daily loop task.
pub async fn start_gc_loop(media_dir: Arc<PathBuf>, db: Arc<Mutex<Connection>>) {
    loop {
        tokio::time::sleep(Duration::from_secs(86_400)).await;
        run_garbage_collection(&media_dir, &db).await;
    }
}

/// Performs a single GC sweep:
///   1. Re-entry guard (AtomicBool) prevents overlapping runs
///   2. Purges finalized files with no ledger row older than 24hr
///   3. Purges stale temp_chunk folders older than 24hr (abandoned uploads)
pub async fn run_garbage_collection(media_dir: &Path, db: &Arc<Mutex<Connection>>) {
    // ── 0. Re-entry guard ────────────────────────────────────────────────────
    if GC_RUNNING
        .compare_exchange(false, true, Ordering::SeqCst, Ordering::Relaxed)
        .is_err()
    {
        tracing::warn!(
            subsystem = "media_gc",
            "MEDIA_GC_SKIP — Previous GC cycle still in progress. Skipping this run."
        );
        return;
    }
    // Reset the flag on completion or panic via RAII GcGuard (impl Drop)
    let _guard = GcGuard;

    tracing::info!(subsystem = "media_gc", "GC cycle started");

    // Load all active hashes from the media ledger in a single query
    let active_hashes = {
        let db = db.clone();
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            let mut stmt = match conn.prepare("SELECT hash FROM media_ledger") {
                Ok(s) => s,
                Err(e) => {
                    tracing::error!(subsystem = "media_gc", error = %e, "Failed to prepare ledger hash query");
                    return std::collections::HashSet::new();
                }
            };
            let hash_iter = match stmt.query_map([], |row| row.get::<_, String>(0)) {
                Ok(iter) => iter,
                Err(e) => {
                    tracing::error!(subsystem = "media_gc", error = %e, "Failed to query ledger hashes");
                    return std::collections::HashSet::new();
                }
            };
            let mut set = std::collections::HashSet::new();
            for hash_res in hash_iter {
                if let Ok(hash) = hash_res {
                    set.insert(hash);
                }
            }
            set
        })
        .await
        .unwrap_or_default()
    };

    // ── 1. Sweep finalized uploads directory ─────────────────────────────────
    let uploads_dir = media_dir.join("uploads");
    let mut read_dir = match tokio::fs::read_dir(&uploads_dir).await {
        Ok(rd) => rd,
        Err(e) => {
            tracing::warn!(subsystem = "media_gc", error = %e, "Cannot read uploads dir");
            return;
        }
    };

    while let Ok(Some(entry)) = read_dir.next_entry().await {
        let path = entry.path();
        let file_stem = path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("")
            .to_string();

        if !active_hashes.contains(&file_stem) {
            // Only purge if file is older than 24 hours (lenient grace period)
            if let Ok(meta) = tokio::fs::metadata(&path).await {
                let age_secs = meta
                    .modified()
                    .ok()
                    .and_then(|mtime| mtime.elapsed().ok())
                    .map(|d| d.as_secs())
                    .unwrap_or(0);

                if age_secs > 86_400 {
                    if let Err(e) = tokio::fs::remove_file(&path).await {
                        tracing::warn!(
                            subsystem = "media_gc",
                            hash = %file_stem,
                            error = %e,
                            "MEDIA_GC_WARN — Failed to remove orphaned file"
                        );
                    } else {
                        tracing::info!(
                            subsystem = "media_gc",
                            hash = %file_stem,
                            "MEDIA_GC_PURGE — Orphaned file removed"
                        );
                    }
                }
            }
        }
    }

    // ── 2. Sweep temp_chunks directory (abandoned uploads) ───────────────────
    let temp_dir = media_dir.join("temp_chunks");
    let mut temp_dirs = match tokio::fs::read_dir(&temp_dir).await {
        Ok(rd) => rd,
        Err(_) => return, // temp_chunks may not exist yet — that's fine
    };

    while let Ok(Some(entry)) = temp_dirs.next_entry().await {
        let path = entry.path();
        if let Ok(meta) = tokio::fs::metadata(&path).await {
            let age_secs = meta
                .modified()
                .ok()
                .and_then(|mtime| mtime.elapsed().ok())
                .map(|d| d.as_secs())
                .unwrap_or(0);

            if age_secs > 86_400 {
                if let Err(e) = tokio::fs::remove_dir_all(&path).await {
                    tracing::warn!(
                        subsystem = "media_gc",
                        path = ?path,
                        error = %e,
                        "MEDIA_GC_WARN — Failed to remove stale chunk folder"
                    );
                } else {
                    tracing::info!(
                        subsystem = "media_gc",
                        path = ?path,
                        "MEDIA_GC_PURGE — Stale chunk folder removed"
                    );
                }
            }
        }
    }

    tracing::info!(subsystem = "media_gc", "GC cycle complete");
}

// ─────────────────────────────────────────────────────────────────────────────
// § 13: Local Redundancy Backup Stub
// ─────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
pub struct BackupConfig {
    pub enabled: bool,
    pub destination_path: String,
    pub sync_interval_hrs: u32,
}

/// Reserved stub for future NVMe-to-NVMe replication via USB secondary drive.
/// No-op until physical hardware expansion in a future phase.
#[cfg(test)]
pub async fn run_backup_sync(config: &BackupConfig, _source_dir: &Path, _db_path: &Path) {
    if !config.enabled {
        return;
    }
    // TODO Phase-future: Spawn rsync-like mirroring task to destination_path
    // TODO Phase-future: Copy sqlite media.db journal cleanly (WAL checkpoint first)
    tracing::info!(
        subsystem = "media_backup",
        destination = %config.destination_path,
        interval_hrs = %config.sync_interval_hrs,
        "[STUB] Backup sync not yet implemented — Phase future"
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// § 14: Subconscious Idle Embedding Daemon — STUB (deferred to Phase 14)
// ─────────────────────────────────────────────────────────────────────────────

/// Compile-safe stub. Logs its presence every check interval.
/// Real Ollama integration is deferred to Phase 14 (Hybrid AI Router).
pub async fn start_subconscious_embedder_loop(_db: Arc<Mutex<Connection>>) {
    loop {
        tokio::time::sleep(Duration::from_secs(300)).await;
        tracing::debug!(
            subsystem = "media_embedder",
            "[STUB] Subconscious embedder — Ollama not yet deployed. Phase 14 pending."
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_run_backup_sync_disabled() {
        let config = BackupConfig {
            enabled: false,
            destination_path: "/tmp/backup_test".to_string(),
            sync_interval_hrs: 24,
        };
        run_backup_sync(&config, Path::new("."), Path::new(".")).await;
    }
}
