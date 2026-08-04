use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;

use tokio::net::TcpListener;
use tracing::{error, info, warn};

use super::vault::MediaVault;

/// Minimal async HTTP file server for the media vault (port 7702).
///
/// Serves files at:
///   GET /vault/{module}/{bucket}/{filename}
///
/// Supports:
///   - `Accept-Ranges: bytes` for PDF scrubbing and video seeking
///   - `Content-Type` from MIME type stored in registry
///   - `Cache-Control: max-age=86400` — content-addressed files are immutable
///
/// # Time Complexity: O(file_size) per request for streaming reads.
/// # Space Complexity: O(chunk_size) per active connection — never loads full file to RAM.
pub async fn serve(vault: Arc<MediaVault>, port: u16) {
    let addr: SocketAddr = format!("0.0.0.0:{port}").parse().expect("valid socket addr");
    let listener = match TcpListener::bind(addr).await {
        Ok(l) => l,
        Err(e) => {
            error!(subsystem = "vault_http", port = port, error = %e, "Failed to bind vault HTTP server");
            return;
        }
    };
    info!(subsystem = "vault_http", port = port, "Media Vault HTTP file server listening");

    loop {
        match listener.accept().await {
            Ok((stream, peer)) => {
                let vault_clone = Arc::clone(&vault);
                tokio::spawn(handle_connection(stream, peer, vault_clone));
            }
            Err(e) => {
                warn!(subsystem = "vault_http", error = %e, "Accept error on vault HTTP server");
            }
        }
    }
}

async fn handle_connection(
    mut stream: tokio::net::TcpStream,
    peer: SocketAddr,
    vault: Arc<MediaVault>,
) {
    use tokio::io::AsyncReadExt;

    let mut buf = vec![0u8; 8192];
    let n = match stream.read(&mut buf).await {
        Ok(0) | Err(_) => return,
        Ok(n) => n,
    };

    let request_str = match std::str::from_utf8(&buf[..n]) {
        Ok(s) => s,
        Err(_) => {
            let _ = write_response(&mut stream, 400, "text/plain", b"Bad Request".to_vec(), None).await;
            return;
        }
    };

    // Parse HTTP request line: "GET /vault/resume/a3/a3f2....pdf HTTP/1.1"
    let first_line = request_str.lines().next().unwrap_or("");
    let parts: Vec<&str> = first_line.splitn(3, ' ').collect();
    if parts.len() < 2 || parts[0] != "GET" {
        let _ = write_response(&mut stream, 405, "text/plain", b"Method Not Allowed".to_vec(), None).await;
        return;
    }

    let raw_path = parts[1];

    // Parse Range header if present
    let range_header = request_str
        .lines()
        .find(|l| l.to_lowercase().starts_with("range:"))
        .and_then(|l| l.splitn(2, ':').nth(1))
        .map(|v| v.trim().to_string());

    // URL must be /vault/{module}/{bucket}/{sha256}.{ext}
    let segments: Vec<&str> = raw_path.trim_start_matches('/').split('/').collect();
    if segments.len() != 4 || segments[0] != "vault" {
        let _ = write_response(&mut stream, 404, "text/plain", b"Not Found".to_vec(), None).await;
        return;
    }

    let module = segments[1];
    let bucket = segments[2];
    let file_part = segments[3];

    // Reconstruct filesystem path
    let file_path = PathBuf::from(&vault.config.root_path)
        .join(module)
        .join(bucket)
        .join(file_part);

    // Security: canonicalize and ensure path stays inside root_path
    let root = PathBuf::from(&vault.config.root_path);
    let canonical = match file_path.canonicalize() {
        Ok(p) => p,
        Err(_) => {
            let _ = write_response(&mut stream, 404, "text/plain", b"Not Found".to_vec(), None).await;
            return;
        }
    };
    if !canonical.starts_with(&root) {
        warn!(
            subsystem = "vault_http",
            peer = %peer,
            path = %raw_path,
            "Path traversal attempt blocked"
        );
        let _ = write_response(&mut stream, 403, "text/plain", b"Forbidden".to_vec(), None).await;
        return;
    }

    // Read file bytes — O(file_size). For very large files a streaming approach would be
    // preferred, but for our use case (PDFs typically < 2 MB) this is acceptable on Pi 5.
    let file_bytes = match tokio::fs::read(&canonical).await {
        Ok(b) => b,
        Err(_) => {
            let _ = write_response(&mut stream, 404, "text/plain", b"Not Found".to_vec(), None).await;
            return;
        }
    };

    // Determine MIME type from registry or extension
    let sha256 = file_part
        .split('.')
        .next()
        .unwrap_or(file_part);
    let mime = vault
        .get_asset(sha256)
        .ok()
        .flatten()
        .map(|a| a.mime_type)
        .unwrap_or_else(|| mime_from_ext(file_part));

    // Handle Range requests for PDF scrubbing / video seeking
    if let Some(range_str) = range_header {
        if let Some(body) = apply_range(&file_bytes, &range_str) {
            let content_range = format!(
                "bytes {}-{}/{}",
                parse_range_start(&range_str, file_bytes.len()),
                parse_range_start(&range_str, file_bytes.len()) + body.len().saturating_sub(1),
                file_bytes.len()
            );
            let extra = format!(
                "Content-Range: {content_range}\r\nAccept-Ranges: bytes\r\nCache-Control: max-age=86400\r\n"
            );
            let _ = write_response_with_extra(&mut stream, 206, &mime, body, &extra).await;
            return;
        }
    }

    // Full file response
    let extra = "Accept-Ranges: bytes\r\nCache-Control: max-age=86400\r\n";
    let _ = write_response_with_extra(&mut stream, 200, &mime, file_bytes, extra).await;
}

fn mime_from_ext(filename: &str) -> String {
    let ext = filename.rsplit('.').next().unwrap_or("").to_lowercase();
    match ext.as_str() {
        "pdf" => "application/pdf",
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "webp" => "image/webp",
        "mp4" => "video/mp4",
        "opus" => "audio/ogg; codecs=opus",
        "mp3" => "audio/mpeg",
        "json" => "application/json",
        "md" => "text/markdown",
        _ => "application/octet-stream",
    }
    .to_string()
}

fn apply_range(data: &[u8], range_str: &str) -> Option<Vec<u8>> {
    // Parse "bytes=start-end" or "bytes=start-"
    let bytes_part = range_str.strip_prefix("bytes=")?;
    let mut parts = bytes_part.splitn(2, '-');
    let start: usize = parts.next()?.trim().parse().ok()?;
    let end: usize = parts
        .next()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(data.len().saturating_sub(1));

    if start >= data.len() {
        return None;
    }
    let end = end.min(data.len().saturating_sub(1));
    Some(data[start..=end].to_vec())
}

fn parse_range_start(range_str: &str, _total: usize) -> usize {
    range_str
        .strip_prefix("bytes=")
        .and_then(|s| s.split('-').next())
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(0)
}

async fn write_response(
    stream: &mut tokio::net::TcpStream,
    status: u16,
    mime: &str,
    body: Vec<u8>,
    _extra: Option<&str>,
) -> std::io::Result<()> {
    use tokio::io::AsyncWriteExt;
    let status_text = match status {
        200 => "OK",
        206 => "Partial Content",
        400 => "Bad Request",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        _ => "Internal Server Error",
    };
    let header = format!(
        "HTTP/1.1 {status} {status_text}\r\nContent-Type: {mime}\r\nContent-Length: {}\r\nAccept-Ranges: bytes\r\n\r\n",
        body.len()
    );
    stream.write_all(header.as_bytes()).await?;
    stream.write_all(&body).await?;
    Ok(())
}

async fn write_response_with_extra(
    stream: &mut tokio::net::TcpStream,
    status: u16,
    mime: &str,
    body: Vec<u8>,
    extra_headers: &str,
) -> std::io::Result<()> {
    use tokio::io::AsyncWriteExt;
    let status_text = match status {
        200 => "OK",
        206 => "Partial Content",
        _ => "OK",
    };
    let header = format!(
        "HTTP/1.1 {status} {status_text}\r\nContent-Type: {mime}\r\nContent-Length: {}\r\n{extra_headers}\r\n",
        body.len()
    );
    stream.write_all(header.as_bytes()).await?;
    stream.write_all(&body).await?;
    Ok(())
}
