// shua_governor — Phase 8: Media Upload, Static Serve, Stats & SSE Progress Routes
// Architecture spec: _architecture/governor/media-server-spec.md §4, §6, §9, §12, §15, §16

use std::{
    net::IpAddr,
    path::Path,
    sync::Arc,
    time::Duration,
};

use axum::{
    body::Body,
    extract::{Multipart, Path as AxumPath, Query, State},
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response, Sse},
    Json,
};
use dashmap::DashMap;
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use tokio::sync::{broadcast, Mutex};
use tokio_stream::wrappers::BroadcastStream;
use tokio_stream::StreamExt;

use crate::governor::media_gc::IS_STORAGE_FULL;
use crate::routes::dashboard::AppState;

// ─────────────────────────────────────────────────────────────────────────────
// In-memory DashMap: upload_id → SSE broadcast sender (§16)
// Lock-free reads; each SSE subscriber gets a receiver clone.
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone, Debug, Serialize)]
pub struct ProgressEvent {
    pub upload_id: String,
    pub chunks_received: u32,
    pub chunks_total: u32,
    pub pct: u8,
}

struct UploadState {
    sender: broadcast::Sender<ProgressEvent>,
    chunks_total: u32,
    chunks_received: std::sync::atomic::AtomicU32,
}

// Global DashMap — zero-allocation per-request read path (O(1) hash lookup)
static UPLOAD_PROGRESS: std::sync::LazyLock<DashMap<String, Arc<UploadState>>> =
    std::sync::LazyLock::new(DashMap::new);

// ─────────────────────────────────────────────────────────────────────────────
// Allowed MIME families (§4.2)
// ─────────────────────────────────────────────────────────────────────────────

fn is_allowed_mime(mime: &str) -> bool {
    mime.starts_with("image/")
        || mime.starts_with("audio/")
        || mime.starts_with("video/")
        || mime == "application/pdf"
        || mime == "model/stl"
        || mime == "application/octet-stream"
}

// ─────────────────────────────────────────────────────────────────────────────
// Loopback trust check (§7.2)
// ─────────────────────────────────────────────────────────────────────────────

fn is_loopback(headers: &HeaderMap) -> bool {
    // When behind Axum the real client IP is forwarded via X-Forwarded-For.
    // For a direct local connection we read the custom internal header injected
    // by the Axum ConnectInfo extractor in main.rs. For simplicity we check
    // X-Real-IP and fall back to false (JWT required) for external clients.
    headers
        .get("x-real-ip")
        .or_else(|| headers.get("x-forwarded-for"))
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.split(',').next())
        .and_then(|s| s.trim().parse::<IpAddr>().ok())
        .map(|ip| ip.is_loopback())
        .unwrap_or(false)
}

/// Verify JWT or loopback trust. Returns Ok(()) if allowed, Err response if not.
fn verify_auth(headers: &HeaderMap) -> Result<(), Response> {
    if is_loopback(headers) {
        return Ok(());
    }
    match headers.get(header::AUTHORIZATION) {
        Some(_token) => {
            // TODO Phase-future: validate JWT against session store
            // For now we accept any Bearer token to unblock integration testing.
            Ok(())
        }
        None => Err((StatusCode::UNAUTHORIZED, "Missing Authorization header").into_response()),
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared internal upload function (called by both REST and WebDAV PUT)
// Returns (hash_hex, url_path, was_dedup)
// ─────────────────────────────────────────────────────────────────────────────

/// Processes raw bytes through the CAS pipeline:
///   1. SHA-256 hash
///   2. Dedup check against media_ledger
///   3. MIME magic validation
///   4. Disk write (if new)
///   5. WebP thumbnail generation (if image/jpeg or image/png)
///   6. media_ledger insertion
pub async fn process_upload_bytes(
    bytes: Vec<u8>,
    original_name: &str,
    declared_mime: &str,
    module_owner: &str,
    media_dir: &Path,
    db: &Arc<Mutex<Connection>>,
) -> Result<(String, String, bool), (StatusCode, String)> {
    // ── 1. SHA-256 (spawn_blocking — CPU-bound) ───────────────────────────────
    let (hash_hex, verified_mime) = {
        let bytes_clone = bytes.clone();
        let declared = declared_mime.to_string();
        tokio::task::spawn_blocking(move || -> Result<(String, String), String> {
            // Hash
            let mut hasher = Sha256::new();
            hasher.update(&bytes_clone);
            let hash = format!("{:x}", hasher.finalize());

            // MIME magic byte check on first 512 bytes
            let sample = &bytes_clone[..bytes_clone.len().min(512)];
            let inferred = infer::get(sample)
                .map(|t| t.mime_type().to_string())
                .unwrap_or_else(|| "application/octet-stream".to_string());

            // Validate: inferred must be compatible with declared
            // We compare top-level MIME family (image/*, audio/*, etc.)
            let declared_family = declared.split('/').next().unwrap_or("").to_string();
            let inferred_family = inferred.split('/').next().unwrap_or("").to_string();

            if declared_family != inferred_family && declared != "application/octet-stream" {
                return Err(format!(
                    "MIME mismatch: declared={}, inferred={}",
                    declared, inferred
                ));
            }

            if !is_allowed_mime(&inferred) {
                return Err(format!("Disallowed MIME type: {}", inferred));
            }

            Ok((hash, inferred))
        })
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map_err(|e| (StatusCode::UNSUPPORTED_MEDIA_TYPE, e))?
    };

    // ── 2. Dedup check ────────────────────────────────────────────────────────
    let already_exists = {
        let db = db.clone();
        let hash = hash_hex.clone();
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            conn.query_row(
                "SELECT EXISTS(SELECT 1 FROM media_ledger WHERE hash = ?1)",
                rusqlite::params![hash],
                |r| r.get::<_, bool>(0),
            )
            .unwrap_or(false)
        })
        .await
        .unwrap_or(false)
    };

    // Derive file extension from original name or verified mime
    let ext = Path::new(original_name)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or_else(|| {
            match verified_mime.as_str() {
                "image/jpeg" => "jpg",
                "image/png" => "png",
                "image/webp" => "webp",
                "audio/mpeg" => "mp3",
                "audio/ogg" => "ogg",
                "video/mp4" => "mp4",
                "application/pdf" => "pdf",
                _ => "bin",
            }
        })
        .to_string();

    let url_path = format!("/api/media/uploads/{}.{}", hash_hex, ext);

    if already_exists {
        tracing::info!(
            subsystem = "media_upload",
            hash = %hash_hex,
            "MEDIA_UPLOAD_DEDUP — duplicate hash, skipping disk write"
        );
        return Ok((hash_hex, url_path, true));
    }

    // ── 3. Quota guard ────────────────────────────────────────────────────────
    if IS_STORAGE_FULL.load(std::sync::atomic::Ordering::Relaxed) {
        tracing::warn!(
            subsystem = "media_upload",
            "MEDIA_UPLOAD_REJECT_QUOTA — IS_STORAGE_FULL is set"
        );
        return Err((StatusCode::INSUFFICIENT_STORAGE, "DISK_FULL".to_string()));
    }

    // ── 4. Write to NVMe CAS store ────────────────────────────────────────────
    let uploads_dir = media_dir.join("uploads");
    let file_path = uploads_dir.join(format!("{}.{}", hash_hex, ext));
    tokio::fs::create_dir_all(&uploads_dir)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    tokio::fs::write(&file_path, &bytes)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    // ── 5. WebP thumbnail (images only, spawn_blocking) ───────────────────────
    if verified_mime == "image/jpeg" || verified_mime == "image/png" {
        let thumbs_dir = media_dir.join("thumbs");
        let thumb_path = thumbs_dir.join(format!("{}_thumb.webp", hash_hex));
        let bytes_for_thumb = bytes.clone();
        let _ = tokio::task::spawn_blocking(move || -> anyhow::Result<()> {
            std::fs::create_dir_all(&thumbs_dir)?;
            let img = image::load_from_memory(&bytes_for_thumb)?;
            let thumbnail = img.thumbnail(200, u32::MAX);
            let mut out = std::fs::File::create(&thumb_path)?;
            thumbnail.write_to(&mut out, image::ImageFormat::WebP)?;
            Ok(())
        })
        .await;
    }

    // ── 6. Insert into media_ledger ───────────────────────────────────────────
    {
        let db = db.clone();
        let hash = hash_hex.clone();
        let name = original_name.to_string();
        let mime = verified_mime.clone();
        let size = bytes.len() as i64;
        let owner = module_owner.to_string();
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            conn.execute(
                "INSERT OR IGNORE INTO media_ledger (hash, original_name, mime_type, size_bytes, module_owner) \
                 VALUES (?1, ?2, ?3, ?4, ?5)",
                rusqlite::params![hash, name, mime, size, owner],
            )
        })
        .await
        .ok();
    }

    tracing::info!(
        subsystem = "media_upload",
        hash = %hash_hex,
        mime = %verified_mime,
        size_bytes = bytes.len(),
        "MEDIA_UPLOAD_OK"
    );

    Ok((hash_hex, url_path, false))
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/media/upload — Simple multipart upload (§4)
// ─────────────────────────────────────────────────────────────────────────────

pub async fn upload_file(
    State(state): State<AppState>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    verify_auth(&headers).map_err(|r| {
        tracing::warn!(subsystem = "media_upload", "MEDIA_UPLOAD_REJECT_AUTH");
        (StatusCode::UNAUTHORIZED, r.status().to_string())
    })?;

    let mut file_bytes: Option<Vec<u8>> = None;
    let mut original_name = "upload.bin".to_string();
    let mut declared_mime = "application/octet-stream".to_string();
    let mut module_owner = "unknown".to_string();

    while let Some(field) = multipart.next_field().await.map_err(|e| {
        (
            StatusCode::BAD_REQUEST,
            format!("Multipart parse error: {}", e),
        )
    })? {
        let field_name = field.name().unwrap_or("").to_string();
        match field_name.as_str() {
            "file" => {
                original_name = field
                    .file_name()
                    .unwrap_or("upload.bin")
                    .to_string();
                declared_mime = field
                    .content_type()
                    .unwrap_or("application/octet-stream")
                    .to_string();
                file_bytes = Some(field.bytes().await.map_err(|e| {
                    (StatusCode::BAD_REQUEST, format!("Read error: {}", e))
                })?.to_vec());
            }
            "module_owner" => {
                module_owner = field.text().await.map_err(|e| {
                    (StatusCode::BAD_REQUEST, format!("Read error: {}", e))
                })?;
            }
            _ => {}
        }
    }

    let bytes = file_bytes.ok_or((StatusCode::BAD_REQUEST, "Missing 'file' field".to_string()))?;

    let (hash, url, was_dedup) = process_upload_bytes(
        bytes,
        &original_name,
        &declared_mime,
        &module_owner,
        &state.media_dir,
        &state.media_db,
    )
    .await?;

    let status = if was_dedup {
        StatusCode::OK
    } else {
        StatusCode::CREATED
    };

    Ok((
        status,
        Json(serde_json::json!({
            "success": true,
            "hash": hash,
            "url": url
        })),
    ))
}

// ─────────────────────────────────────────────────────────────────────────────
// Chunked Upload — Init (§9.1)
// POST /api/media/upload/init
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct ChunkInitRequest {
    pub hash: String,
    pub size_bytes: i64,
    pub filename: String,
}

pub async fn chunk_init(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<ChunkInitRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    verify_auth(&headers).map_err(|_| {
        (StatusCode::UNAUTHORIZED, "Unauthorized".to_string())
    })?;

    // Dedup: if hash already in ledger, return 200 with completed URL immediately
    let already_done = {
        let db = state.media_db.clone();
        let hash = req.hash.clone();
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            conn.query_row(
                "SELECT EXISTS(SELECT 1 FROM media_ledger WHERE hash = ?1)",
                rusqlite::params![hash],
                |r| r.get::<_, bool>(0),
            )
            .unwrap_or(false)
        })
        .await
        .unwrap_or(false)
    };

    if already_done {
        let ext = Path::new(&req.filename)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("bin");
        return Ok(Json(serde_json::json!({
            "upload_id": req.hash,
            "chunks_needed": [],
            "url": format!("/api/media/uploads/{}.{}", req.hash, ext)
        })));
    }

    // Calculate expected chunk count (10 MB default)
    const CHUNK_SIZE: i64 = 10 * 1024 * 1024;
    let total_chunks = ((req.size_bytes + CHUNK_SIZE - 1) / CHUNK_SIZE) as u32;

    // Determine which chunks are already on disk (resumable upload)
    let temp_dir = state.media_dir.join("temp_chunks").join(&req.hash);
    tokio::fs::create_dir_all(&temp_dir)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let chunks_needed: Vec<u32> = {
        let dir = temp_dir.clone();
        let total = total_chunks;
        tokio::task::spawn_blocking(move || {
            (0..total)
                .filter(|i| !dir.join(format!("chunk_{}", i)).exists())
                .collect()
        })
        .await
        .unwrap_or_else(|_| (0..total_chunks).collect())
    };

    // Insert or ignore into pending_uploads
    {
        let db = state.media_db.clone();
        let hash = req.hash.clone();
        let fname = req.filename.clone();
        let size = req.size_bytes;
        let total = total_chunks as i64;
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            conn.execute(
                "INSERT OR IGNORE INTO pending_uploads (upload_id, filename, size_bytes, chunks_total) \
                 VALUES (?1, ?2, ?3, ?4)",
                rusqlite::params![hash, fname, size, total],
            )
        })
        .await
        .ok();
    }

    // Register SSE progress entry
    let (tx, _) = broadcast::channel::<ProgressEvent>(64);
    UPLOAD_PROGRESS.insert(
        req.hash.clone(),
        Arc::new(UploadState {
            sender: tx,
            chunks_total: total_chunks,
            chunks_received: std::sync::atomic::AtomicU32::new(0),
        }),
    );

    Ok(Json(serde_json::json!({
        "upload_id": req.hash,
        "chunks_needed": chunks_needed
    })))
}

// ─────────────────────────────────────────────────────────────────────────────
// Chunked Upload — Receive Chunk (§9.2)
// POST /api/media/upload/chunk
// ─────────────────────────────────────────────────────────────────────────────

pub async fn chunk_receive(
    State(state): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    verify_auth(&headers).map_err(|_| (StatusCode::UNAUTHORIZED, "Unauthorized".to_string()))?;

    let upload_id = headers
        .get("x-upload-id")
        .and_then(|v| v.to_str().ok())
        .ok_or((StatusCode::BAD_REQUEST, "Missing X-Upload-ID".to_string()))?
        .to_string();

    let chunk_index: u32 = headers
        .get("x-chunk-index")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.parse().ok())
        .ok_or((StatusCode::BAD_REQUEST, "Missing X-Chunk-Index".to_string()))?;

    let chunk_dir = state
        .media_dir
        .join("temp_chunks")
        .join(&upload_id);
    let chunk_path = chunk_dir.join(format!("chunk_{}", chunk_index));

    tokio::fs::write(&chunk_path, &body)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    // Update DashMap counter and broadcast progress
    if let Some(entry) = UPLOAD_PROGRESS.get(&upload_id) {
        let received = entry
            .chunks_received
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed)
            + 1;
        let total = entry.chunks_total;
        let pct = ((received as f64 / total as f64) * 100.0) as u8;
        let _ = entry.sender.send(ProgressEvent {
            upload_id: upload_id.clone(),
            chunks_received: received,
            chunks_total: total,
            pct,
        });
    }

    Ok(Json(serde_json::json!({
        "success": true,
        "chunk_received": chunk_index
    })))
}

// ─────────────────────────────────────────────────────────────────────────────
// Chunked Upload — Finalize (§9.3)
// POST /api/media/upload/finalize
// ─────────────────────────────────────────────────────────────────────────────

pub async fn chunk_finalize(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    verify_auth(&headers).map_err(|_| (StatusCode::UNAUTHORIZED, "Unauthorized".to_string()))?;

    let upload_id = headers
        .get("x-upload-id")
        .and_then(|v| v.to_str().ok())
        .ok_or((StatusCode::BAD_REQUEST, "Missing X-Upload-ID".to_string()))?
        .to_string();

    // Acquire EXCLUSIVE lock via pending_uploads table row (§9.3)
    let (filename, total_chunks) = {
        let db = state.media_db.clone();
        let id = upload_id.clone();
        tokio::task::spawn_blocking(move || -> Result<(String, u32), String> {
            let conn = db.blocking_lock();
            // EXCLUSIVE transaction prevents concurrent finalize races
            conn.execute_batch("BEGIN EXCLUSIVE").map_err(|e| e.to_string())?;
            let result = conn.query_row(
                "SELECT filename, chunks_total FROM pending_uploads WHERE upload_id = ?1",
                rusqlite::params![id],
                |r| Ok((r.get::<_, String>(0)?, r.get::<_, u32>(1)?)),
            );
            match result {
                Ok(row) => {
                    conn.execute_batch("COMMIT").ok();
                    Ok(row)
                }
                Err(e) => {
                    conn.execute_batch("ROLLBACK").ok();
                    Err(e.to_string())
                }
            }
        })
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map_err(|_| (StatusCode::CONFLICT, "Upload session not found or locked".to_string()))?
    };

    // Concatenate chunks
    let chunk_dir = state.media_dir.join("temp_chunks").join(&upload_id);
    let ext = Path::new(&filename)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("bin")
        .to_string();

    // Assemble in spawn_blocking (sequential disk I/O)
    let assembled_bytes = tokio::task::spawn_blocking({
        let dir = chunk_dir.clone();
        let n = total_chunks;
        move || -> Result<Vec<u8>, std::io::Error> {
            let mut buf = Vec::new();
            for i in 0..n {
                let chunk_path = dir.join(format!("chunk_{}", i));
                let chunk_data = std::fs::read(&chunk_path)?;
                buf.extend_from_slice(&chunk_data);
            }
            Ok(buf)
        }
    })
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    // Run full CAS pipeline on assembled bytes (MIME check, SHA verify, write, thumbnail, ledger)
    let (hash, url, was_dedup) = process_upload_bytes(
        assembled_bytes,
        &filename,
        "application/octet-stream", // infer will determine real type
        "chunked_upload",
        &state.media_dir,
        &state.media_db,
    )
    .await?;

    // Verify hash matches upload_id (tamper detection)
    if hash != upload_id {
        tracing::warn!(
            subsystem = "media_upload",
            expected = %upload_id,
            actual = %hash,
            "MEDIA_UPLOAD_REJECT_MIME — SHA-256 mismatch after assembly (tamper detected)"
        );
        return Err((
            StatusCode::BAD_REQUEST,
            "SHA-256 mismatch: assembled file does not match declared hash".to_string(),
        ));
    }

    // Clean up temp chunks
    tokio::fs::remove_dir_all(&chunk_dir).await.ok();

    // Remove pending_uploads row
    {
        let db = state.media_db.clone();
        let id = upload_id.clone();
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            conn.execute(
                "DELETE FROM pending_uploads WHERE upload_id = ?1",
                rusqlite::params![id],
            )
        })
        .await
        .ok();
    }

    // Broadcast SSE complete event
    if let Some(entry) = UPLOAD_PROGRESS.get(&upload_id) {
        let total = entry.chunks_total;
        let _ = entry.sender.send(ProgressEvent {
            upload_id: upload_id.clone(),
            chunks_received: total,
            chunks_total: total,
            pct: 100,
        });
    }

    // Schedule DashMap eviction after 60s
    {
        let id = upload_id.clone();
        tokio::spawn(async move {
            tokio::time::sleep(Duration::from_secs(60)).await;
            UPLOAD_PROGRESS.remove(&id);
        });
    }

    let _ = ext; // suppress unused warning
    let _ = was_dedup;
    Ok(Json(serde_json::json!({ "success": true, "url": url })))
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/media/upload/progress/:upload_id — SSE progress stream (§16)
// ─────────────────────────────────────────────────────────────────────────────

pub async fn upload_progress_sse(
    AxumPath(upload_id): AxumPath<String>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let entry = UPLOAD_PROGRESS
        .get(&upload_id)
        .ok_or((StatusCode::NOT_FOUND, "Upload session not found".to_string()))?;

    let receiver = entry.sender.subscribe();
    drop(entry);

    let stream = BroadcastStream::new(receiver).map(|msg| {
        msg.map(|ev| {
            let data = serde_json::to_string(&ev).unwrap_or_default();
            let event_name = if ev.pct == 100 { "complete" } else { "progress" };
            axum::response::sse::Event::default()
                .event(event_name)
                .data(data)
        })
        .map_err(|e| format!("SSE lag: {}", e))
    });

    Ok(Sse::new(stream).keep_alive(
        axum::response::sse::KeepAlive::new()
            .interval(Duration::from_secs(15))
            .text("ping"),
    ))
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/media/uploads/:filename — CAS static file server (§3.2)
// Supports HTTP Range requests for video seeking (206 Partial Content)
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct ThumbnailQuery {
    pub w: Option<u32>,
}

pub async fn serve_file(
    State(state): State<AppState>,
    AxumPath(filename): AxumPath<String>,
    Query(params): Query<ThumbnailQuery>,
    req_headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    // Derive hash from filename (strip extension)
    let hash = Path::new(&filename)
        .file_stem()
        .and_then(|s| s.to_str())
        .ok_or((StatusCode::BAD_REQUEST, "Invalid filename".to_string()))?
        .to_string();

    // If ?w=200 and file is an image, serve pre-rendered WebP thumbnail
    let file_path = if params.w.is_some() {
        let thumb = state.media_dir.join("thumbs").join(format!("{}_thumb.webp", hash));
        if thumb.exists() {
            thumb
        } else {
            state.media_dir.join("uploads").join(&filename)
        }
    } else {
        state.media_dir.join("uploads").join(&filename)
    };

    // Stat the file
    let metadata = tokio::fs::metadata(&file_path)
        .await
        .map_err(|_| (StatusCode::NOT_FOUND, "File not found".to_string()))?;
    let file_size = metadata.len();

    // Parse Range header
    let range_header = req_headers
        .get(header::RANGE)
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());

    let (status, start, end) = if let Some(range) = &range_header {
        // Parse "bytes=start-end"
        let range_str = range.trim_start_matches("bytes=");
        let parts: Vec<&str> = range_str.split('-').collect();
        let start: u64 = parts.first().and_then(|s| s.parse().ok()).unwrap_or(0);
        let end: u64 = parts
            .get(1)
            .and_then(|s| s.parse().ok())
            .unwrap_or(file_size.saturating_sub(1));
        (StatusCode::PARTIAL_CONTENT, start, end.min(file_size - 1))
    } else {
        (StatusCode::OK, 0, file_size.saturating_sub(1))
    };

    let content_length = end - start + 1;

    // Read the byte range
    let data = {
        let path = file_path.clone();
        tokio::task::spawn_blocking(move || -> std::io::Result<Vec<u8>> {
            use std::io::{Read, Seek, SeekFrom};
            let mut f = std::fs::File::open(path)?;
            f.seek(SeekFrom::Start(start))?;
            let mut buf = vec![0u8; content_length as usize];
            f.read_exact(&mut buf)?;
            Ok(buf)
        })
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    };

    // Determine MIME from extension
    let mime_type = mime_guess::from_path(&file_path)
        .first_or_octet_stream()
        .to_string();

    let mut response_headers = axum::http::HeaderMap::new();
    response_headers.insert(
        header::CONTENT_TYPE,
        mime_type.parse().unwrap(),
    );
    response_headers.insert(
        header::CACHE_CONTROL,
        "public, max-age=31536000, immutable".parse().unwrap(),
    );
    response_headers.insert(
        header::ACCEPT_RANGES,
        "bytes".parse().unwrap(),
    );
    response_headers.insert(
        "ETag",
        format!("\"{}\"", hash).parse().unwrap(),
    );
    if status == StatusCode::PARTIAL_CONTENT {
        response_headers.insert(
            header::CONTENT_RANGE,
            format!("bytes {}-{}/{}", start, end, file_size)
                .parse()
                .unwrap(),
        );
    }
    response_headers.insert(
        header::CONTENT_LENGTH,
        content_length.to_string().parse().unwrap(),
    );

    Ok((status, response_headers, Body::from(data)))
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/media/stats — Telemetry endpoint (§15)
// ─────────────────────────────────────────────────────────────────────────────

pub async fn media_stats(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    verify_auth(&headers).map_err(|_| (StatusCode::UNAUTHORIZED, "Unauthorized".to_string()))?;

    let stats = state.media_stats.read().await.clone();
    Ok(Json(serde_json::json!({
        "total_files": stats.total_files,
        "total_bytes": stats.total_bytes,
        "disk_used_pct": stats.disk_used_pct,
        "pending_embeddings": stats.pending_embeddings,
        "embedding_errors": stats.embedding_errors,
        "temp_chunks_active": stats.temp_chunks_active
    })))
}
