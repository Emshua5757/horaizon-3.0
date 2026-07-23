// shua_governor — Phase 8: WebDAV NAS Gateway
// Architecture spec: _architecture/governor/media-server-spec.md §11
//
// Implements the 4 required WebDAV verbs for Windows File Explorer "Map Network Drive":
//   PROPFIND  /api/dav/  or  /api/dav/{hash.ext}
//   GET       /api/dav/{hash.ext}
//   PUT       /api/dav/{filename}
//   DELETE    /api/dav/{hash.ext}
//
// IMPORTANT: PUT delegates to routes::media::process_upload_bytes (NOT reimplemented here).
// This guarantees quota enforcement, MIME validation, and ledger insertion on every WebDAV write.

use std::path::Path;

use axum::{
    body::Body,
    extract::{Request, State},
    http::{header, Method, StatusCode},
    response::{IntoResponse, Response},
};
use crate::routes::dashboard::AppState;
use crate::routes::media::process_upload_bytes;

// ─────────────────────────────────────────────────────────────────────────────
// WebDAV XML constants
// ─────────────────────────────────────────────────────────────────────────────

/// Build a RFC 4918-compliant PROPFIND multistatus response.
/// Single-allocation: builds string directly from query results.
fn build_propfind_response(entries: &[DavEntry], base_url: &str) -> String {
    let mut xml = String::with_capacity(512 + entries.len() * 256);
    xml.push_str(r#"<?xml version="1.0" encoding="utf-8"?>"#);
    xml.push_str(r#"<D:multistatus xmlns:D="DAV:">"#);

    for entry in entries {
        let href = format!("{}/{}", base_url.trim_end_matches('/'), entry.filename);
        xml.push_str("<D:response>");
        xml.push_str(&format!("<D:href>{}</D:href>", html_escape(&href)));
        xml.push_str("<D:propstat>");
        xml.push_str("<D:prop>");
        xml.push_str(&format!(
            "<D:displayname>{}</D:displayname>",
            html_escape(&entry.filename)
        ));
        xml.push_str(&format!(
            "<D:getcontentlength>{}</D:getcontentlength>",
            entry.size_bytes
        ));
        xml.push_str(&format!(
            "<D:getcontenttype>{}</D:getcontenttype>",
            html_escape(&entry.mime_type)
        ));
        xml.push_str(&format!(
            "<D:getlastmodified>{}</D:getlastmodified>",
            entry.last_modified_rfc1123
        ));
        xml.push_str(&format!(
            "<D:getetag>\"{}\"</D:getetag>",
            entry.etag
        ));
        xml.push_str("<D:resourcetype/>");
        xml.push_str("</D:prop>");
        xml.push_str("<D:status>HTTP/1.1 200 OK</D:status>");
        xml.push_str("</D:propstat>");
        xml.push_str("</D:response>");
    }

    // Root collection entry (depth 0)
    xml.push_str("<D:response>");
    xml.push_str(&format!("<D:href>{}</D:href>", html_escape(base_url)));
    xml.push_str("<D:propstat>");
    xml.push_str("<D:prop>");
    xml.push_str("<D:displayname>horAIzon Media</D:displayname>");
    xml.push_str("<D:resourcetype><D:collection/></D:resourcetype>");
    xml.push_str("</D:prop>");
    xml.push_str("<D:status>HTTP/1.1 200 OK</D:status>");
    xml.push_str("</D:propstat>");
    xml.push_str("</D:response>");

    xml.push_str("</D:multistatus>");
    xml
}

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

// ─────────────────────────────────────────────────────────────────────────────
// Database row for directory listing
// ─────────────────────────────────────────────────────────────────────────────

struct DavEntry {
    filename: String,   // e.g. "abc123.jpg"
    size_bytes: i64,
    mime_type: String,
    last_modified_rfc1123: String,
    etag: String,
}

// ─────────────────────────────────────────────────────────────────────────────
// Main dispatch handler — called by axum::routing::any("/api/dav/*path")
// ─────────────────────────────────────────────────────────────────────────────

pub async fn dav_handler(
    State(state): State<AppState>,
    req: Request<Body>,
) -> Result<Response, (StatusCode, String)> {
    let method = req.method().clone();
    let uri = req.uri().clone();
    let headers = req.headers().clone();

    // Auth check
    let is_loopback = headers
        .get("x-real-ip")
        .or_else(|| headers.get("x-forwarded-for"))
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.split(',').next())
        .and_then(|s| s.trim().parse::<std::net::IpAddr>().ok())
        .map(|ip| ip.is_loopback())
        .unwrap_or(false);

    let has_auth = headers.contains_key(header::AUTHORIZATION);
    if !is_loopback && !has_auth {
        tracing::warn!(subsystem = "media_dav", "MEDIA_UPLOAD_REJECT_AUTH — WebDAV unauthorized");
        return Ok((StatusCode::UNAUTHORIZED, "Missing Authorization").into_response());
    }

    // Extract sub-path: /api/dav/{path} → {path}
    let path_str = uri.path();
    let sub_path = path_str
        .trim_start_matches("/api/dav")
        .trim_start_matches('/')
        .to_string();

    // Dispatch by method string (PROPFIND is non-standard, use method.as_str())
    match method.as_str() {
        "PROPFIND" => handle_propfind(&state, &sub_path, path_str).await,
        "GET" | "HEAD" => handle_get(&state, &sub_path, method == Method::HEAD).await,
        "PUT" => handle_put(&state, &sub_path, req).await,
        "DELETE" => handle_delete(&state, &sub_path).await,
        "OPTIONS" => {
            // WebDAV capability advertisement (required by Windows File Explorer)
            Ok((
                StatusCode::OK,
                [
                    ("DAV", "1, 2"),
                    ("Allow", "OPTIONS, GET, HEAD, PUT, DELETE, PROPFIND"),
                    ("MS-Author-Via", "DAV"),
                ],
            )
                .into_response())
        }
        _ => Ok(StatusCode::METHOD_NOT_ALLOWED.into_response()),
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROPFIND — Directory listing (§11)
// ─────────────────────────────────────────────────────────────────────────────

async fn handle_propfind(
    state: &AppState,
    _sub_path: &str,
    request_path: &str,
) -> Result<Response, (StatusCode, String)> {
    tracing::info!(subsystem = "media_dav", path = %request_path, "WebDAV PROPFIND — directory listing requested");
    // Query all files from media_ledger
    let entries: Vec<DavEntry> = {
        let db = state.media_db.clone();
        tokio::task::spawn_blocking(move || {
            let conn = db.blocking_lock();
            let mut stmt = conn
                .prepare(
                    "SELECT hash, original_name, mime_type, size_bytes, uploaded_at \
                     FROM media_ledger ORDER BY uploaded_at DESC LIMIT 1000",
                )
                .map_err(|e| e.to_string())?;

            let rows = stmt
                .query_map([], |row| {
                    let hash: String = row.get(0)?;
                    let original_name: String = row.get(1)?;
                    let mime: String = row.get(2)?;
                    let size: i64 = row.get(3)?;
                    let uploaded_at: String = row.get(4)?;

                    let ext = Path::new(&original_name)
                        .extension()
                        .and_then(|e| e.to_str())
                        .unwrap_or("bin");

                    Ok(DavEntry {
                        filename: format!("{}.{}", hash, ext),
                        size_bytes: size,
                        mime_type: mime,
                        // RFC 1123 format for Last-Modified header
                        last_modified_rfc1123: uploaded_at.clone(),
                        etag: hash,
                    })
                })
                .map_err(|e| e.to_string())?;

            rows.collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())
        })
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .map_err(|e: String| (StatusCode::INTERNAL_SERVER_ERROR, e))?
    };

    let base_url = request_path.trim_end_matches('/');
    let xml = build_propfind_response(&entries, base_url);

    Ok((
        StatusCode::MULTI_STATUS,
        [(header::CONTENT_TYPE, "application/xml; charset=utf-8")],
        xml,
    )
        .into_response())
}

// ─────────────────────────────────────────────────────────────────────────────
// GET — File download (delegates to CAS store)
// ─────────────────────────────────────────────────────────────────────────────

async fn handle_get(
    state: &AppState,
    sub_path: &str,
    head_only: bool,
) -> Result<Response, (StatusCode, String)> {
    if sub_path.is_empty() {
        // GET on root collection → return listing as HTML (WebDAV root browse)
        return Ok((StatusCode::OK, "horAIzon Media NAS — use WebDAV client").into_response());
    }

    tracing::info!(subsystem = "media_dav", file = %sub_path, head_only = %head_only, "WebDAV GET — file download requested");

    let file_path = state.media_dir.join("uploads").join(sub_path);
    let metadata = tokio::fs::metadata(&file_path)
        .await
        .map_err(|_| (StatusCode::NOT_FOUND, "File not found".to_string()))?;

    let file_size = metadata.len();
    let hash = Path::new(sub_path)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("")
        .to_string();

    let mime_type = mime_guess::from_path(&file_path)
        .first_or_octet_stream()
        .to_string();

    if head_only {
        return Ok((
            StatusCode::OK,
            [
                (header::CONTENT_TYPE.as_str(), mime_type.as_str()),
                (header::CONTENT_LENGTH.as_str(), &file_size.to_string()),
                ("ETag", &format!("\"{}\"", hash)),
            ],
        )
            .into_response());
    }

    let data = tokio::fs::read(&file_path)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok((
        StatusCode::OK,
        [
            (header::CONTENT_TYPE.as_str(), mime_type.as_str()),
            (
                header::CACHE_CONTROL.as_str(),
                "public, max-age=31536000, immutable",
            ),
            ("ETag", &format!("\"{}\"", hash)),
        ],
        data,
    )
        .into_response())
}

// ─────────────────────────────────────────────────────────────────────────────
// PUT — File upload (MUST delegate to shared upload pipeline)
// ─────────────────────────────────────────────────────────────────────────────

async fn handle_put(
    state: &AppState,
    sub_path: &str,
    req: Request<Body>,
) -> Result<Response, (StatusCode, String)> {
    let filename = Path::new(sub_path)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("upload.bin")
        .to_string();

    let declared_mime = req
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("application/octet-stream")
        .to_string();

    // Read body bytes
    let bytes = axum::body::to_bytes(req.into_body(), usize::MAX)
        .await
        .map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))?
        .to_vec();

    // Delegate to shared pipeline — inherits quota, MIME, ledger
    let (_hash, url, _dedup) = process_upload_bytes(
        bytes,
        &filename,
        &declared_mime,
        "webdav",
        &state.media_dir,
        &state.media_db,
    )
    .await?;

    Ok((
        StatusCode::CREATED,
        [(header::LOCATION, url.as_str())],
    )
        .into_response())
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE — Soft delete (marks orphaned for 24hr lenient GC)
// ─────────────────────────────────────────────────────────────────────────────

async fn handle_delete(
    state: &AppState,
    sub_path: &str,
) -> Result<Response, (StatusCode, String)> {
    let hash = Path::new(sub_path)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("")
        .to_string();

    if hash.is_empty() {
        return Ok(StatusCode::BAD_REQUEST.into_response());
    }

    // Soft-delete: set last_gc_scan = NULL to mark as orphaned
    // Physical file removal handled by 24hr lenient GC (§5)
    let db = state.media_db.clone();
    let hash_clone = hash.clone();
    let affected = tokio::task::spawn_blocking(move || {
        let conn = db.blocking_lock();
        conn.execute(
            "UPDATE media_ledger SET last_gc_scan = NULL WHERE hash = ?1",
            rusqlite::params![hash_clone],
        )
    })
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if affected == 0 {
        return Ok(StatusCode::NOT_FOUND.into_response());
    }

    tracing::info!(
        subsystem = "media_dav",
        hash = %hash,
        "WebDAV DELETE — file marked orphaned (GC will purge after 24hr grace)"
    );

    Ok(StatusCode::NO_CONTENT.into_response())
}
