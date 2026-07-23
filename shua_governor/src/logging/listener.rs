// shua_governor — Multi-client Socket Log Ingress (UDS / TCP Loopback)
// Phase 12.2: Ultra-efficient local IPC logging pipeline.

#[cfg(target_os = "linux")]
use std::path::Path;
use tokio::io::{AsyncBufReadExt, AsyncReadExt, BufReader};
use tokio::sync::mpsc;
use crate::logging::entry::{log_min_level, BorrowedLogEntry, LogEntry};

const HBP_MAGIC_0: u8  = 0x48; // 'H'
const HBP_MAGIC_1: u8  = 0x42; // 'B'
const HBP_TYPE_LOG: u8 = 0x12; // Type byte at offset 3

pub async fn start_log_ipc_listener(log_tx: mpsc::Sender<LogEntry>) {
    let log_tx_tcp = log_tx.clone();
    tokio::spawn(async move {
        let addr = "127.0.0.1:5001";
        let listener = match tokio::net::TcpListener::bind(addr).await {
            Ok(l) => l,
            Err(e) => {
                tracing::error!(subsystem = "log_listener", "Failed to bind TCP logging port {}: {}", addr, e);
                return;
            }
        };

        tracing::info!(subsystem = "log_listener", addr = addr, "Log TCP loopback listener started");

        loop {
            match listener.accept().await {
                Ok((stream, _addr)) => {
                    tracing::info!(subsystem = "log_listener", "Accepted TCP log client connection");
                    let log_tx_clone = log_tx_tcp.clone();
                    tokio::spawn(async move {
                        harvest_socket_stream(stream, log_tx_clone).await;
                    });
                }
                Err(e) => {
                    tracing::warn!(subsystem = "log_listener", "TCP accept failed: {}", e);
                }
            }
        }
    });

    #[cfg(target_os = "linux")]
    {
        use std::os::unix::fs::PermissionsExt;

        let socket_path = "/tmp/horaizon_logs.sock";
        if Path::new(socket_path).exists() {
            let _ = std::fs::remove_file(socket_path);
        }

        let listener = match tokio::net::UnixListener::bind(socket_path) {
            Ok(l) => {
                let _ = std::fs::set_permissions(socket_path, std::fs::Permissions::from_mode(0o777));
                l
            }
            Err(e) => {
                tracing::error!(subsystem = "log_listener", "Failed to bind Unix Domain Socket at '{}': {}", socket_path, e);
                return;
            }
        };

        tracing::info!(subsystem = "log_listener", path = socket_path, "Log UDS IPC listener started");

        loop {
            match listener.accept().await {
                Ok((stream, _addr)) => {
                    tracing::info!(subsystem = "log_listener", "Accepted UDS log client connection");
                    let log_tx_clone = log_tx.clone();
                    tokio::spawn(async move {
                        harvest_socket_stream(stream, log_tx_clone).await;
                    });
                }
                Err(e) => {
                    tracing::warn!(subsystem = "log_listener", "UDS accept failed: {}", e);
                }
            }
        }
    }
}

async fn harvest_socket_stream<S>(stream: S, log_tx: mpsc::Sender<LogEntry>)
where
    S: tokio::io::AsyncRead + Unpin + Send + 'static,
{
    let min_level = log_min_level();
    let mut reader = BufReader::new(stream);

    loop {
        let mut b1 = [0u8; 1];
        match reader.read_exact(&mut b1).await {
            Ok(_) => {}
            Err(_) => break,
        }

        if b1[0] == HBP_MAGIC_0 {
            let mut b2 = [0u8; 1];
            if reader.read_exact(&mut b2).await.is_err() {
                let line_str = String::from_utf8_lossy(&b1);
                let _ = log_tx.try_send(wrap_socket_raw_line(&line_str));
                break;
            }

            if b2[0] == HBP_MAGIC_1 {
                let mut header_rest = [0u8; 10];
                if reader.read_exact(&mut header_rest).await.is_err() {
                    let bytes = vec![HBP_MAGIC_0, HBP_MAGIC_1];
                    let line_str = String::from_utf8_lossy(&bytes);
                    let _ = log_tx.try_send(wrap_socket_raw_line(&line_str));
                    break;
                }

                let mut header = [0u8; 12];
                header[0] = HBP_MAGIC_0;
                header[1] = HBP_MAGIC_1;
                header[2..12].copy_from_slice(&header_rest);

                if header[3] == HBP_TYPE_LOG {
                    let payload_len = u32::from_be_bytes([header[8], header[9], header[10], header[11]]) as usize;
                    let mut payload = vec![0u8; payload_len];
                    if reader.read_exact(&mut payload).await.is_ok() {
                        match rmp_serde::from_slice::<BorrowedLogEntry>(&payload) {
                            Ok(borrowed_entry) => {
                                if borrowed_entry.level >= min_level {
                                    let _ = log_tx.try_send(borrowed_entry.into());
                                }
                                continue;
                            }
                            Err(e) => {
                                tracing::warn!(subsystem = "log_listener", error = %e, "Failed to decode socket HBP LOG frame");
                                continue;
                            }
                        }
                    }
                    let mut fallback_bytes = header.to_vec();
                    fallback_bytes.extend(payload);
                    let mut rest = Vec::new();
                    let _ = read_until_newline(&mut reader, &mut rest).await;
                    fallback_bytes.extend(rest);
                    let line_str = String::from_utf8_lossy(&fallback_bytes);
                    let _ = log_tx.try_send(wrap_socket_raw_line(&line_str));
                } else {
                    let mut fallback_bytes = header.to_vec();
                    let mut rest = Vec::new();
                    let _ = read_until_newline(&mut reader, &mut rest).await;
                    fallback_bytes.extend(rest);
                    let line_str = String::from_utf8_lossy(&fallback_bytes);
                    let _ = log_tx.try_send(wrap_socket_raw_line(&line_str));
                }
            } else {
                let mut line_bytes = vec![HBP_MAGIC_0, b2[0]];
                let mut rest = Vec::new();
                let _ = read_until_newline(&mut reader, &mut rest).await;
                line_bytes.extend(rest);
                let line_str = String::from_utf8_lossy(&line_bytes);
                let _ = log_tx.try_send(wrap_socket_raw_line(&line_str));
            }
        } else {
            let mut line_bytes = vec![b1[0]];
            let mut rest = Vec::new();
            let _ = read_until_newline(&mut reader, &mut rest).await;
            line_bytes.extend(rest);
            let line_str = String::from_utf8_lossy(&line_bytes);
            let _ = log_tx.try_send(wrap_socket_raw_line(&line_str));
        }
    }
}

fn wrap_socket_raw_line(line: &str) -> LogEntry {
    LogEntry {
        ts:          chrono::Utc::now().timestamp_millis() as u64,
        level:       3, // INFO
        module:      255, // UNKNOWN
        subsystem:   "socket_raw".to_string(),
        msg:         line.trim_end().to_string(),
        tags:        0,
        custom_tags: None,
        telemetry:   None,
        trace_id:    None,
    }
}

async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
where
    R: tokio::io::AsyncBufRead + Unpin,
{
    let bytes_read = reader.read_until(b'\n', buf).await?;
    if buf.ends_with(b"\n") {
        buf.pop();
        if buf.ends_with(b"\r") {
            buf.pop();
        }
    }
    Ok(bytes_read)
}
