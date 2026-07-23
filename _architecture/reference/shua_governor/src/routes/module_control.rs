// shua_governor — Module Lifecycle Control Handler (Phase 10 + 12)
//
// Phase 12 additions:
//   - Child stdout/stderr are piped (not inherited).
//   - Two Tokio tasks per spawned child harvest output line-by-line:
//       * HBP magic check (0x48, 0x42, ..., 0x12): decode BorrowedLogEntry via rmp_serde,
//         gate by LOG_MIN_LEVEL, promote to LogEntry, push to log_tx.
//       * Fallback: wrap raw text line as INFO (stdout) or ERROR (stderr) LogEntry.

use std::collections::HashMap;
use std::process::Stdio;
use crate::governor::{cgroups, registry::ModuleState};
use crate::routes::dashboard::AppState;
use crate::logging::entry::{log_min_level, BorrowedLogEntry, LogEntry, LogSender, LEVEL_INFO, LEVEL_ERROR};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use tokio::io::{AsyncReadExt, BufReader};

// HBP frame constants used in the magic byte check
const HBP_MAGIC_0: u8  = 0x48; // 'H'
const HBP_MAGIC_1: u8  = 0x42; // 'B'
const HBP_TYPE_LOG: u8 = 0x12; // Type byte at offset 3

pub async fn control_module(
    State(state): State<AppState>,
    Path((id, action)): Path<(String, String)>,
    Query(query_params): Query<HashMap<String, String>>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let mut registry_guard = state.registry.write().await;

    let entry = registry_guard.get_mut(&id).ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            format!("Module '{}' not found in registry", id),
        )
    })?;

    match action.as_str() {
        "start" => {
            // If already active or starting, return early
            if entry.state == ModuleState::Active {
                return Ok(Json(serde_json::json!({ "status": "active", "id": id })));
            }

            // Save query parameters (e.g. provider=ollama) into entry env_vars
            if let Some(provider) = query_params.get("provider") {
                entry.env_vars.insert("SHUA_AI_PROVIDER".to_string(), provider.clone());
                tracing::info!(
                    subsystem = "module_control",
                    module_id = %id,
                    provider = %provider,
                    "Configured runtime env SHUA_AI_PROVIDER"
                );
            }

            entry.state = ModuleState::Starting;
            let module_dir = format!("shua_modules/{}", id);
            let port_str = entry.port.to_string();

            // Clear any stale processes occupying this port before spawning to prevent EADDRINUSE conflicts
            #[cfg(target_os = "linux")]
            {
                let _ = tokio::process::Command::new("fuser")
                    .args(["-k", "-9", &format!("{}/tcp", port_str)])
                    .output()
                    .await;
            }

            // Set up platform-specific Command builder with piped stdout/stderr
            let mut cmd = if cfg!(target_os = "windows") {
                let mut c = tokio::process::Command::new("cmd");
                c.args(["/C", &entry.exec_cmd]);
                c
            } else {
                let mut c = tokio::process::Command::new("sh");
                c.args(["-c", &entry.exec_cmd]);
                c
            };

            cmd.current_dir(&module_dir);
            cmd.env("PORT", &port_str);
            for (k, v) in &entry.env_vars {
                cmd.env(k, v);
            }

            // Phase 12: pipe stdout and stderr so we can harvest HBP binary log frames
            cmd.stdout(Stdio::piped());
            cmd.stderr(Stdio::piped());

            // On Linux, use a pre_exec hook to assign the child process to its cgroup
            // before executing. This avoids the fork-to-exec cgroups escape race condition.
            #[cfg(target_os = "linux")]
            {
                let cgroup_dir = match cgroups::ensure_cgroup_dir(&id).await {
                    Ok(path) => path,
                    Err(e) => {
                        tracing::error!(
                            subsystem = "module_control",
                            module_id = %id,
                            error = %e,
                            "Failed to resolve cgroup directory"
                        );
                        std::path::PathBuf::from("/sys/fs/cgroup/shua").join(&id)
                    }
                };

                let mut cgroup_procs_path = cgroup_dir;
                cgroup_procs_path.push("cgroup.procs");
                let cgroup_procs_path_c = std::ffi::CString::new(cgroup_procs_path.to_string_lossy().as_bytes()).unwrap();

                unsafe {
                    cmd.pre_exec(move || {
                        let fd = libc::open(cgroup_procs_path_c.as_ptr(), libc::O_WRONLY);
                        if fd >= 0 {
                            let _res = libc::write(fd, b"0\n".as_ptr() as *const libc::c_void, 2);
                            libc::close(fd);
                        }
                        Ok(())
                    });
                }
            }

            match cmd.spawn() {
                Ok(mut child) => {
                    let pid = child.id().unwrap_or(0);
                    entry.pid = Some(pid);

                    tracing::info!(
                        subsystem = "module_control",
                        module_id = %id,
                        pid = pid,
                        port = %port_str,
                        "Spawned module via shell"
                    );

                    // Phase 12 — Harvest child stdout for HBP binary log frames
                    if let Some(stdout) = child.stdout.take() {
                        let log_tx = state.log_tx.clone();
                        let module_id_str = id.clone();
                        tokio::spawn(async move {
                            harvest_pipe(stdout, log_tx, module_id_str, false).await;
                        });
                    }

                    // Phase 12 — Harvest child stderr (always wrapped as ERROR)
                    if let Some(stderr) = child.stderr.take() {
                        let log_tx = state.log_tx.clone();
                        let module_id_str = id.clone();
                        tokio::spawn(async move {
                            harvest_pipe(stderr, log_tx, module_id_str, true).await;
                        });
                    }

                    // On non-Linux (e.g. Windows dev machine), write the PID to the mock file
                    #[cfg(not(target_os = "linux"))]
                    {
                        let _ = cgroups::assign_pid(&id, pid).await;
                    }
                }
                Err(e) => {
                    tracing::error!(
                        subsystem = "module_control",
                        module_id = %id,
                        error = %e,
                        "Failed to spawn module"
                    );
                    entry.state = ModuleState::Stopped;
                }
            }
            Ok(Json(serde_json::json!({ "status": "starting", "id": id })))
        }
        "freeze" => {
            cgroups::freeze(&id).await.map_err(|e| {
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    format!("cgroup freeze failed: {}", e),
                )
            })?;
            entry.state = ModuleState::Frozen;
            tracing::info!(subsystem = "module_control", module_id = %id, "Module frozen via cgroup");
            Ok(Json(serde_json::json!({ "status": "frozen", "id": id })))
        }
        "unfreeze" => {
            cgroups::unfreeze(&id).await.map_err(|e| {
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    format!("cgroup unfreeze failed: {}", e),
                )
            })?;
            entry.state = ModuleState::Active;
            tracing::info!(subsystem = "module_control", module_id = %id, "Module unfrozen via cgroup");
            Ok(Json(serde_json::json!({ "status": "active", "id": id })))
        }
        "stop" | "kill" => {
            let port = entry.port;

            let _ = cgroups::kill(&id).await;

            if let Some(pid) = entry.pid.take() {
                tracing::info!(
                    subsystem = "module_control",
                    module_id = %id,
                    pid = pid,
                    port = port,
                    "Stopping module"
                );

                #[cfg(target_os = "windows")]
                {
                    let _ = tokio::process::Command::new("taskkill")
                        .args(["/F", "/T", "/PID", &pid.to_string()])
                        .output()
                        .await;
                }

                #[cfg(unix)]
                {
                    unsafe {
                        libc::kill(pid as i32, libc::SIGKILL);
                    }
                }
            }

            #[cfg(target_os = "linux")]
            {
                let _ = tokio::process::Command::new("fuser")
                    .args(["-k", "-9", &format!("{}/tcp", port)])
                    .output()
                    .await;
            }

            entry.ram_bytes = 0;
            entry.cpu_pct = 0.0;
            entry.ready_callback = false;
            entry.state = ModuleState::Stopped;
            Ok(Json(serde_json::json!({ "status": "stopped", "id": id })))
        }
        _ => Err((
            StatusCode::BAD_REQUEST,
            format!("Unknown action '{}'", action),
        )),
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// Phase 12 — Child Process Pipe Harvester
// ──────────────────────────────────────────────────────────────────────────────

/// Reads lines from a child process pipe (stdout or stderr).
///
/// For each line:
///   - Converts to bytes and checks for the HBP magic header (0x48, 0x42, ..., 0x12 at byte 3).
///   - If magic matches: decodes MsgPack payload via `rmp_serde::from_slice` into
///     `BorrowedLogEntry<'_>`, gates by `LOG_MIN_LEVEL`, promotes to `LogEntry`.
///   - If no magic: wraps the raw text as a fallback INFO (stdout) or ERROR (stderr) `LogEntry`.
///
/// Note: We use line-based reading (BufReader<Lines>) rather than raw byte streaming
/// because child processes that mix text and binary output are rare in our stack.
/// shua_diary emits HBP frames as complete lines (Buffer.concat writes atomically).
/// The 12-byte header + msgpack body fits within a single line write.
async fn harvest_pipe<R>(
    reader: R,
    log_tx: LogSender,
    module_id: String,
    is_stderr: bool,
) where
    R: tokio::io::AsyncRead + Unpin + Send + 'static,
{
    let min_level = log_min_level();
    let module_u8 = module_id_to_u8(&module_id);
    let mut reader = BufReader::new(reader);

    loop {
        // 1. Read first byte
        let mut b1 = [0u8; 1];
        match reader.read_exact(&mut b1).await {
            Ok(_) => {}
            Err(_) => break, // EOF or pipe closed
        }

        if b1[0] == HBP_MAGIC_0 {
            // Read second byte
            let mut b2 = [0u8; 1];
            if reader.read_exact(&mut b2).await.is_err() {
                let line_str = String::from_utf8_lossy(&b1);
                if let Some(entry) = wrap_raw_line(&line_str, module_u8, is_stderr) {
                    let _ = log_tx.try_send(entry);
                }
                break;
            }

            if b2[0] == HBP_MAGIC_1 {
                // Read next 10 bytes to finish header
                let mut header_rest = [0u8; 10];
                if reader.read_exact(&mut header_rest).await.is_err() {
                    let bytes = vec![HBP_MAGIC_0, HBP_MAGIC_1];
                    let line_str = String::from_utf8_lossy(&bytes);
                    if let Some(entry) = wrap_raw_line(&line_str, module_u8, is_stderr) {
                        let _ = log_tx.try_send(entry);
                    }
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
                                tracing::debug!(
                                    subsystem = "pipe_harvester",
                                    module_id = %module_id,
                                    error = %e,
                                    "Failed to decode HBP LOG frame — treating as raw text"
                                );
                            }
                        }
                    }
                    let mut fallback_bytes = header.to_vec();
                    fallback_bytes.extend(payload);
                    let mut rest = Vec::new();
                    let _ = read_until_newline(&mut reader, &mut rest).await;
                    fallback_bytes.extend(rest);
                    let line_str = String::from_utf8_lossy(&fallback_bytes);
                    if let Some(entry) = wrap_raw_line(&line_str, module_u8, is_stderr) {
                        let _ = log_tx.try_send(entry);
                    }
                } else {
                    let mut fallback_bytes = header.to_vec();
                    let mut rest = Vec::new();
                    let _ = read_until_newline(&mut reader, &mut rest).await;
                    fallback_bytes.extend(rest);
                    let line_str = String::from_utf8_lossy(&fallback_bytes);
                    if let Some(entry) = wrap_raw_line(&line_str, module_u8, is_stderr) {
                        let _ = log_tx.try_send(entry);
                    }
                }
            } else {
                let mut line_bytes = vec![HBP_MAGIC_0, b2[0]];
                let mut rest = Vec::new();
                let _ = read_until_newline(&mut reader, &mut rest).await;
                line_bytes.extend(rest);
                let line_str = String::from_utf8_lossy(&line_bytes);
                if let Some(entry) = wrap_raw_line(&line_str, module_u8, is_stderr) {
                    let _ = log_tx.try_send(entry);
                }
            }
        } else {
            let mut line_bytes = vec![b1[0]];
            let mut rest = Vec::new();
            let _ = read_until_newline(&mut reader, &mut rest).await;
            line_bytes.extend(rest);
            let line_str = String::from_utf8_lossy(&line_bytes);
            if let Some(entry) = wrap_raw_line(&line_str, module_u8, is_stderr) {
                let _ = log_tx.try_send(entry);
            }
        }
    }

    tracing::info!(
        subsystem = "pipe_harvester",
        module_id = %module_id,
        pipe = if is_stderr { "stderr" } else { "stdout" },
        "Child pipe closed"
    );
}

/// Reads from reader until a newline (0x0A) or EOF is encountered.
/// The newline character is consumed but NOT included in the output buffer.
async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
where
    R: tokio::io::AsyncRead + Unpin,
{
    let mut total = 0;
    let mut byte = [0u8; 1];
    loop {
        match reader.read_exact(&mut byte).await {
            Ok(_) => {
                total += 1;
                if byte[0] == b'\n' {
                    break;
                }
                if byte[0] != b'\r' {
                    buf.push(byte[0]);
                }
            }
            Err(e) => {
                if total > 0 && e.kind() == std::io::ErrorKind::UnexpectedEof {
                    break;
                }
                return Err(e);
            }
        }
    }
    Ok(total)
}

/// Wraps a raw stdout/stderr text line as a fallback LogEntry.
/// stdout → INFO (level 3), stderr → ERROR (level 5).
fn wrap_raw_line(line: &str, module_u8: u8, is_stderr: bool) -> Option<LogEntry> {
    let level = if is_stderr { LEVEL_ERROR } else { LEVEL_INFO };
    
    // DEBUG TOOL: Print this to the Governor's stdout so we can see it in journalctl!
    let stream_name = if is_stderr { "STDERR" } else { "STDOUT" };
    println!("[RAW-PIPE {}] {}", stream_name, line);

    Some(LogEntry {
        ts:          chrono::Utc::now().timestamp_millis() as u64,
        level,
        module:      module_u8,
        subsystem:   "stdout".to_string(),
        msg:         line.to_string(),
        tags:        0,
        custom_tags: None,
        telemetry:   None,
        trace_id:    None,
    })
}

/// Maps a module ID string to its HBP integer constant.
/// Mirrors the HbpModule constants in hbp_constants.g.dart.
fn module_id_to_u8(id: &str) -> u8 {
    match id {
        "shua_diary"       => 1,
        "shua_crypto"      => 2,
        "shua_gym_vision"  => 3,
        "shua_trading_bot" => 4,
        "shua_resume"      => 5,
        "shua_memory_lane" => 6,
        "shua_code_review" => 7,
        "shua_edge_ml"     => 8,
        "shua_bill_tracker"=> 9,
        "shua_governor"    => 10,
        _                  => 255, // UNKNOWN
    }
}
