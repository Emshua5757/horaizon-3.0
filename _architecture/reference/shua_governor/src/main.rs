// shua_governor — Master Entrypoint & Server Listener
// Phase 10: V4 SDUI Rewrite | Architecture spec: _architecture/governor/phase10-governor-spec.md
// Phase 12: Centralized logging subsystem wired in at boot.
// Phase 8:  Media server (media.db, disk monitor, GC loops) wired in at boot.

mod governor;
mod logging;
mod proxy;
mod routes;
#[cfg(test)]
mod sdui;

use std::{path::PathBuf, sync::Arc};

use tokio::net::TcpListener;
use tokio::sync::{broadcast, mpsc};
use std::net::SocketAddr;
use tracing_subscriber::{fmt, EnvFilter};
use governor::registry::{load_from_json, new_registry, new_system_metrics};
use governor::supervisor::start_supervisor_loop;
use governor::media_gc::{new_media_stats, start_disk_monitor_loop, start_gc_loop, start_subconscious_embedder_loop};
use logging::entry::LogEntry;
use logging::flush::flush_loop;
use routes::dashboard::AppState;
use routes::create_router;
use routes::sse_metrics::MetricsSnapshot;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    use tracing_subscriber::prelude::*;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Phase 12 — MPSC log ingress channel (capacity 4096, O(1) send)
    //    log_tx: distributed to subsystems that produce log entries
    //    log_rx: consumed exclusively by the flush task
    // ─────────────────────────────────────────────────────────────────────────
    let (log_tx, log_rx): (mpsc::Sender<LogEntry>, mpsc::Receiver<LogEntry>) =
        mpsc::channel(4096);

    // Broadcast channel for live SSE tail at GET /api/logs/stream.
    // Capacity 256: a slow diagnostics subscriber can lag ~128s before
    // frames are dropped (256 × 500ms flush interval).
    // Supervisor pattern: we discard the initial dummy subscriber immediately.
    let (log_broadcast_tx, _) = broadcast::channel::<LogEntry>(256);

    // ─────────────────────────────────────────────────────────────────────────
    // 0. Initialise structured JSON tracing subscriber (non-blocking async log)
    //    Bridge tracing events to central log aggregator (ChannelLogger layer)
    // ─────────────────────────────────────────────────────────────────────────
    let fmt_layer = fmt::layer().json();
    let filter = EnvFilter::from_default_env()
        .add_directive("shua_governor=info".parse().unwrap());
        
    tracing_subscriber::registry()
        .with(filter)
        .with(fmt_layer)
        .with(logging::bridge::ChannelLogger::new(log_tx.clone()))
        .init();

    tracing::info!(
        subsystem = "boot",
        version = "4.0",
        host = "Raspberry Pi 5",
        ram_ceiling_gb = 8,
        "SHUA GOVERNOR v4.0 — High-Rigor Edge API Gateway starting"
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Spawn background log flush task (dual-trigger: 500ms OR 1024-entry HWM)
    // ─────────────────────────────────────────────────────────────────────────
    let flush_broadcast_tx = log_broadcast_tx.clone();
    tokio::spawn(async move {
        flush_loop(log_rx, flush_broadcast_tx).await;
    });
    tracing::info!(subsystem = "boot", "Log flush task spawned (4096-entry MPSC, 256-entry broadcast)");

    // Spawn background log socket listener (UDS on Linux, TCP on Windows)
    let listener_log_tx = log_tx.clone();
    tokio::spawn(async move {
        logging::listener::start_log_ipc_listener(listener_log_tx).await;
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Initialise empty thread-safe Module Registry
    // ─────────────────────────────────────────────────────────────────────────
    let registry = new_registry();

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Load module definitions from schemas/module_registry.json
    // ─────────────────────────────────────────────────────────────────────────
    let manifest_path = "schemas/module_registry.json";
    match load_from_json(manifest_path).await {
        Ok(modules) => {
            let mut guard = registry.write().await;
            for module in modules {
                tracing::info!(
                    subsystem = "registry",
                    module_id = %module.id,
                    port = module.port,
                    "Pre-loaded module from manifest"
                );
                guard.insert(module.id.clone(), module);
            }
        }
        Err(err) => {
            tracing::warn!(
                subsystem = "registry",
                path = manifest_path,
                error = %err,
                "Could not load manifest — starting empty registry"
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. SSE metrics broadcast channel (capacity 4 — supervisor publishes 2s tick)
    // ─────────────────────────────────────────────────────────────────────────
    let (metrics_tx, _) = broadcast::channel::<MetricsSnapshot>(4);
    tracing::info!(subsystem = "boot", "SSE metrics broadcast channel created (capacity: 4 frames)");

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Shared system-wide metrics snapshot — supervisor writes, handlers read
    // ─────────────────────────────────────────────────────────────────────────
    let system_metrics = new_system_metrics();


    // ─────────────────────────────────────────────────────────────────────────
    // 8. Load blueprints once at boot (cached in memory)
    // ─────────────────────────────────────────────────────────────────────────
    let blueprint_path = "schemas/blueprints/dashboard/dashboard.json";
    let dashboard_blueprint = tokio::fs::read_to_string(blueprint_path).await.unwrap_or_else(|e| {
        tracing::warn!(
            subsystem = "blueprint",
            path = blueprint_path,
            error = %e,
            "Could not load dashboard blueprint — using empty fallback"
        );
        "[{}]".to_string()
    });
    tracing::info!(
        subsystem = "blueprint",
        bytes = dashboard_blueprint.len(),
        "Dashboard schema loaded into memory cache"
    );

    let console_path = "schemas/blueprints/dashboard/console.json";
    let console_blueprint = tokio::fs::read_to_string(console_path).await.unwrap_or_else(|e| {
        tracing::warn!(
            subsystem = "blueprint",
            path = console_path,
            error = %e,
            "Could not load console blueprint — using empty fallback"
        );
        "{}".to_string()
    });
    tracing::info!(
        subsystem = "blueprint",
        bytes = console_blueprint.len(),
        "Console schema loaded into memory cache"
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 8 — Media Subsystem Boot
    // ─────────────────────────────────────────────────────────────────────────

    // 8a. Resolve media directory — env var override, platform-correct defaults.
    //     Pi 5 (Linux): /var/lib/horaizon/media
    //     Windows dev:  ./data/media  (relative to CWD where cargo run is invoked)
    let media_dir: Arc<PathBuf> = {
        let path = std::env::var("HORAIZON_MEDIA_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| {
                #[cfg(target_os = "linux")]
                { PathBuf::from("/var/lib/horaizon/media") }
                #[cfg(not(target_os = "linux"))]
                { PathBuf::from("data/media") }
            });

        // Ensure required sub-directories exist at boot
        for subdir in &["uploads", "thumbs", "temp_chunks"] {
            if let Err(e) = std::fs::create_dir_all(path.join(subdir)) {
                tracing::warn!(subsystem = "media_boot", dir = %path.join(subdir).display(), error = %e, "Could not create media subdir");
            }
        }

        tracing::info!(subsystem = "media_boot", path = %path.display(), "Media directory resolved");
        Arc::new(path)
    };

    // 8b. Open dedicated media.db SQLite connection (isolated from logs.db per §10)
    let media_db: Arc<tokio::sync::Mutex<rusqlite::Connection>> = {
        let db_path = {
            #[cfg(target_os = "linux")]
            { PathBuf::from("/var/lib/horaizon/media.db") }
            #[cfg(not(target_os = "linux"))]
            { PathBuf::from("data/media.db") }
        };

        // Ensure parent directory exists
        if let Some(parent) = db_path.parent() {
            std::fs::create_dir_all(parent).ok();
        }

        let conn = rusqlite::Connection::open(&db_path)
            .expect("Failed to open media.db — check path permissions");

        // Enable WAL mode for concurrent reads during GC scans
        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;")
            .expect("Failed to set media.db PRAGMAs");

        // DDL migration: media_ledger (§3.1)
        conn.execute_batch(
            "CREATE TABLE IF NOT EXISTS media_ledger (
                hash                VARCHAR(64) PRIMARY KEY,
                original_name       VARCHAR(255) NOT NULL,
                mime_type           VARCHAR(100) NOT NULL,
                size_bytes          BIGINT NOT NULL,
                uploaded_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                module_owner        VARCHAR(50) NOT NULL,
                last_gc_scan        TIMESTAMP,
                allow_embedding     INTEGER NOT NULL DEFAULT 1,
                embedding           BLOB,
                embedding_dim       INTEGER,
                embedding_model     VARCHAR(50),
                embedding_last_error TEXT
            );
            CREATE TABLE IF NOT EXISTS pending_uploads (
                upload_id   VARCHAR(64) PRIMARY KEY,
                filename    VARCHAR(255) NOT NULL,
                size_bytes  BIGINT NOT NULL,
                chunks_total INTEGER NOT NULL,
                created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            );",
        )
        .expect("Failed to migrate media.db schema");

        tracing::info!(
            subsystem = "media_boot",
            path = %db_path.display(),
            "media.db opened and migrated (WAL mode)"
        );

        Arc::new(tokio::sync::Mutex::new(conn))
    };

    // 8c. Shared MediaStats — written by disk monitor, read by dashboard handler
    let media_stats = new_media_stats();

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Spawn background microservice supervisor loop
    // ─────────────────────────────────────────────────────────────────────────
    {
        let registry = registry.clone();
        let metrics_tx = metrics_tx.clone();
        let system_metrics = system_metrics.clone();
        let media_stats = media_stats.clone();
        tokio::spawn(async move {
            start_supervisor_loop(registry, system_metrics, metrics_tx, media_stats).await;
        });
    }

    // 8d. Spawn background loops
    {
        let dir = media_dir.clone();
        let db = media_db.clone();
        let stats = media_stats.clone();
        tokio::spawn(async move {
            start_disk_monitor_loop(dir, db, stats).await;
        });
        tracing::info!(subsystem = "media_boot", "Disk monitor loop spawned (60s interval)");
    }
    {
        let dir = media_dir.clone();
        let db = media_db.clone();
        tokio::spawn(async move {
            start_gc_loop(dir, db).await;
        });
        tracing::info!(subsystem = "media_boot", "GC loop spawned (24hr interval)");
    }
    {
        let db = media_db.clone();
        tokio::spawn(async move {
            start_subconscious_embedder_loop(db).await;
        });
        tracing::info!(subsystem = "media_boot", "[STUB] Embedder loop spawned (Phase 14 pending)");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 9. Create shared AppState (injected into every Axum handler via Arc clone)
    // ─────────────────────────────────────────────────────────────────────────
    let state = AppState {
        registry,
        dashboard_blueprint,
        console_blueprint,
        metrics_tx,
        system_metrics,
        log_tx: log_tx.clone(),
        log_broadcast_tx,
        // ── Phase 8: Media subsystem ───────────────────────────────────────────
        media_db: media_db.clone(),
        media_dir: media_dir.clone(),
        media_stats: media_stats.clone(),
    };

    // ─────────────────────────────────────────────────────────────────────────
    // 10. Build Axum Router and bind TCP listener on 0.0.0.0:3000
    // ─────────────────────────────────────────────────────────────────────────
    let app = create_router(state);
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!(subsystem = "network", %addr, "Governor TCP listener binding");

    let listener = TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
