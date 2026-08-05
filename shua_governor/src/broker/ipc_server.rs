use base64::Engine;
use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Result;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use tokio::net::TcpStream;
use tokio::sync::mpsc;
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{error, info, warn};

use crate::broker::dispatcher::Dispatcher;
use crate::broker::frame::HbpFrame;
use crate::mcp::McpToolSchema;
use crate::media_vault::vault::MediaVault;
use crate::registry::module_entry::ModuleState;
use crate::registry::process_manager::ProcessManager;

pub struct IpcServer {
    process_manager: Arc<ProcessManager>,
    media_vault: Arc<MediaVault>,
    dispatcher: Arc<Dispatcher>,
}

impl IpcServer {
    pub fn new(
        process_manager: Arc<ProcessManager>,
        media_vault: Arc<MediaVault>,
        dispatcher: Arc<Dispatcher>,
    ) -> Self {
        Self {
            process_manager,
            media_vault,
            dispatcher,
        }
    }

    /// Runs the dedicated JSON IPC WebSocket listener on target SocketAddr (default loopback 7701)
    pub async fn run(&self, addr: SocketAddr) -> Result<()> {
        let socket = if addr.is_ipv4() {
            tokio::net::TcpSocket::new_v4()?
        } else {
            tokio::net::TcpSocket::new_v6()?
        };
        socket.set_reuseaddr(true)?;
        #[cfg(target_family = "unix")]
        let _ = socket.set_reuseport(true);

        socket.bind(addr)?;
        let listener = socket.listen(1024)?;
        info!(
            subsystem = "ipc_server",
            address = %addr,
            "JSON IPC WebSocket listener bound and listening"
        );

        loop {
            match listener.accept().await {
                Ok((stream, peer_addr)) => {
                    info!(
                        subsystem = "ipc_server",
                        peer = %peer_addr,
                        "Submodule IPC TCP connection accepted"
                    );
                    let pm = Arc::clone(&self.process_manager);
                    let vault = Arc::clone(&self.media_vault);
                    let disp = Arc::clone(&self.dispatcher);
                    tokio::spawn(handle_ipc_connection(stream, peer_addr, pm, vault, disp));
                }
                Err(e) => {
                    error!(
                        subsystem = "ipc_server",
                        error = %e,
                        "IPC socket accept error"
                    );
                }
            }
        }
    }
}

/// Extract OS peer PID via SO_PEERCRED on Unix/Linux systems
#[cfg(target_family = "unix")]
fn get_peer_pid(stream: &TcpStream) -> Option<u32> {
    use std::os::unix::io::AsRawFd;
    let fd = stream.as_raw_fd();
    unsafe {
        let mut ucred: libc::ucred = std::mem::zeroed();
        let mut len = std::mem::size_of::<libc::ucred>() as libc::socklen_t;
        let res = libc::getsockopt(
            fd,
            libc::SOL_SOCKET,
            libc::SO_PEERCRED,
            &mut ucred as *mut _ as *mut libc::c_void,
            &mut len,
        );
        if res == 0 && ucred.pid > 0 {
            Some(ucred.pid as u32)
        } else {
            None
        }
    }
}

#[cfg(not(target_family = "unix"))]
fn get_peer_pid(_stream: &TcpStream) -> Option<u32> {
    None
}

async fn handle_ipc_connection(
    stream: TcpStream,
    peer_addr: SocketAddr,
    process_manager: Arc<ProcessManager>,
    media_vault: Arc<MediaVault>,
    dispatcher: Arc<Dispatcher>,
) {
    let peer_pid_opt = get_peer_pid(&stream);

    let ws_stream = match accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            warn!(peer = %peer_addr, error = %e, "IPC WebSocket handshake failed");
            return;
        }
    };

    let (mut ws_tx, mut ws_rx) = ws_stream.split();
    let (tx, mut rx) = mpsc::unbounded_channel::<String>();

    // Outbound text frame forwarder task
    let send_task = tokio::spawn(async move {
        while let Some(text_frame) = rx.recv().await {
            if ws_tx.send(Message::Text(text_frame)).await.is_err() {
                break;
            }
        }
    });

    let mut registered_module_id: Option<String> = None;

    // Inbound text message loop
    while let Some(msg) = ws_rx.next().await {
        match msg {
            Ok(Message::Text(text)) => {
                if let Ok(val) = serde_json::from_str::<Value>(&text) {
                    let op = val["op"].as_str().unwrap_or("");

                    if op == "governor.mcp.register" {
                        let module_id = val["module_id"].as_str().unwrap_or("").to_string();
                        let version = val["version"].as_str().unwrap_or("0.1.0").to_string();
                        let scope = val["scope"].as_str().unwrap_or("all").to_string();

                        if module_id.is_empty() {
                            warn!(peer = %peer_addr, "governor.mcp.register frame missing module_id");
                            continue;
                        }

                        // Parse MCP tools array from manifest
                        let tools: Vec<McpToolSchema> = val
                            .get("tools")
                            .and_then(|t| serde_json::from_value(t.clone()).ok())
                            .unwrap_or_default();

                        let tool_count = tools.len();
                        let mut modules = process_manager.modules.write().await;

                        if let Some(entry) = modules.get_mut(&module_id) {
                            // Validate PID if available
                            if let (Some(peer_pid), Some(entry_pid)) = (peer_pid_opt, entry.pid) {
                                if peer_pid != entry_pid {
                                    warn!(
                                        subsystem = "ipc_server",
                                        module = %module_id,
                                        peer_pid = peer_pid,
                                        entry_pid = entry_pid,
                                        "IPC auth failure: peer PID mismatch — rejecting registration"
                                    );
                                    break;
                                }
                            }

                            entry.ipc_tx = Some(tx.clone());
                            entry.tools = tools;
                            entry.module_scope = Some(scope.clone());
                            entry.manifest_version = Some(version.clone());
                            entry.state = ModuleState::IpcConnected;

                            registered_module_id = Some(module_id.clone());

                            info!(
                                subsystem = "ipc_server",
                                module = %module_id,
                                version = %version,
                                scope = %scope,
                                tools_count = tool_count,
                                "Submodule registered MCP manifest over IPC (state -> IpcConnected)"
                            );
                        } else {
                            warn!(
                                subsystem = "ipc_server",
                                module = %module_id,
                                "Received registration for unknown module_id — ignoring"
                            );
                        }
                    } else if op == "changed" {
                        if let Some(ref mod_id) = registered_module_id {
                            info!(
                                subsystem = "ipc_server",
                                module = %mod_id,
                                event = ?val.get("event"),
                                "Submodule pushed topology delta event"
                            );
                        }
                    } else if op == "vault.upload" {
                        // Submodule depositing a file into the vault via IPC (Base64 path)
                        let call_id = val
                            .get("id")
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string();
                        let module = val
                            .get("module")
                            .and_then(|v| v.as_str())
                            .unwrap_or("shared")
                            .to_string();
                        let fname = val
                            .get("file_name")
                            .and_then(|v| v.as_str())
                            .unwrap_or("file.bin")
                            .to_string();
                        let mime = val
                            .get("mime_type")
                            .and_then(|v| v.as_str())
                            .unwrap_or("application/octet-stream")
                            .to_string();
                        let b64 = val
                            .get("data_base64")
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string();

                        let response_json = match media_vault.store_base64(
                            &module,
                            &fname,
                            &mime,
                            &b64,
                            "submodule",
                        ) {
                            Ok(upload) => {
                                info!(
                                    subsystem = "ipc_vault",
                                    sha256 = %upload.sha256_hash,
                                    module = %module,
                                    deduplicated = upload.deduplicated,
                                    "vault.upload from submodule complete"
                                );
                                serde_json::json!({
                                    "id": call_id,
                                    "status": "ok",
                                    "result": {
                                        "sha256_hash": upload.sha256_hash,
                                        "url": upload.url,
                                        "file_size": upload.file_size,
                                        "deduplicated": upload.deduplicated,
                                    }
                                })
                                .to_string()
                            }
                            Err(e) => {
                                warn!(subsystem = "ipc_vault", error = %e, "vault.upload from submodule failed");
                                serde_json::json!({
                                    "id": call_id,
                                    "status": "error",
                                    "error": format!("ERR_VAULT_UPLOAD: {e}")
                                })
                                .to_string()
                            }
                        };

                        let _ = tx.send(response_json);
                    } else if op == "governor.ai.route" || op == "ai.route" {
                        // Submodule requesting AI route over IPC WebSocket
                        let call_id = val
                            .get("id")
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string();
                        let prompt = val.get("prompt").and_then(|v| v.as_str()).unwrap_or("").to_string();
                        let context_hint = val.get("context_hint").and_then(|v| v.as_str()).map(|s| s.to_string());
                        let model = val.get("model").and_then(|v| v.as_str()).map(|s| s.to_string());
                        let offload_url = val.get("offload_device_url").and_then(|v| v.as_str()).map(|s| s.to_string());

                        let ai_payload = serde_json::json!({
                            "prompt": prompt,
                            "context_hint": context_hint,
                            "model": model,
                            "offload_device_url": offload_url,
                        });

                        let payload_bytes = serde_json::to_vec(&ai_payload).unwrap_or_default();
                        let mut req_frame = HbpFrame::request("shua.governor", "ai.route", payload_bytes);
                        req_frame.id = call_id.clone();

                        let (dummy_tx, _) = tokio::sync::mpsc::unbounded_channel();
                        let disp_clone = Arc::clone(&dispatcher);
                        let peer_ip = peer_addr.ip();
                        let tx_reply = tx.clone();

                        tokio::spawn(async move {
                            if let Some(resp_frame) = disp_clone.dispatch_with_peer(req_frame, dummy_tx, Some(peer_ip)).await {
                                let reply_str = match serde_json::from_slice::<Value>(&resp_frame.p) {
                                    Ok(v) => v.get("reply").and_then(|r| r.as_str()).unwrap_or("").to_string(),
                                    Err(_) => String::from_utf8_lossy(&resp_frame.p).to_string(),
                                };
                                let resp_json = serde_json::json!({
                                    "id": call_id,
                                    "status": "ok",
                                    "reply": reply_str,
                                }).to_string();
                                let _ = tx_reply.send(resp_json);
                            } else {
                                let resp_json = serde_json::json!({
                                    "id": call_id,
                                    "status": "error",
                                    "error": "ERR_AI_ROUTE_FAILED"
                                }).to_string();
                                let _ = tx_reply.send(resp_json);
                            }
                        });
                    } else if let Some(id_str) = val.get("id").and_then(|v| v.as_str()) {
                        let id_str = id_str.to_string();

                        // Check first: is this the reply to a direct client-forwarded
                        // HBP request (e.g. Flutter's matrix.get)?
                        let client_reply_tx = {
                            let mut replies = process_manager.client_replies.lock().await;
                            replies.remove(&id_str)
                        };

                        if let Some(reply_tx) = client_reply_tx {
                            let mod_name = val
                                .get("mod")
                                .and_then(|v| v.as_str())
                                .unwrap_or("")
                                .to_string();
                            let op_name = val
                                .get("op")
                                .and_then(|v| v.as_str())
                                .unwrap_or("")
                                .to_string();

                            let hbp_frame = if let Some(err_msg) =
                                val.get("err").and_then(|v| v.as_str())
                            {
                                crate::broker::frame::HbpFrame::error_response(
                                    &id_str, &mod_name, &op_name, err_msg,
                                )
                            } else {
                                let payload_bytes = val
                                    .get("p")
                                    .and_then(|v| v.as_str())
                                    .and_then(|b64| {
                                        base64::engine::general_purpose::STANDARD.decode(b64).ok()
                                    })
                                    .unwrap_or_default();
                                crate::broker::frame::HbpFrame::response(
                                    &id_str,
                                    &mod_name,
                                    &op_name,
                                    payload_bytes,
                                )
                            };

                            match hbp_frame.encode() {
                                Ok(encoded) => {
                                    let _ = reply_tx.send(encoded);
                                    info!(subsystem = "ipc_server", id = %id_str, module = %mod_name, "Routed submodule reply back to client");
                                }
                                Err(e) => {
                                    warn!(subsystem = "ipc_server", error = %e, "Failed to encode HBP frame for client reply");
                                }
                            }
                        } else if let Some(ref mod_id) = registered_module_id {
                            // Existing MCP tool-call reply resolution (unchanged)
                            let modules = process_manager.modules.read().await;
                            if let Some(entry) = modules.get(mod_id) {
                                let mut pending = entry.pending_calls.lock().await;
                                if let Some(oneshot_tx) = pending.remove(&id_str) {
                                    let status =
                                        val.get("status").and_then(|v| v.as_str()).unwrap_or("ok");
                                    let payload = if status == "ok" {
                                        val.get("result").cloned().unwrap_or(Value::Null)
                                    } else {
                                        serde_json::json!({
                                            "error": val.get("error").and_then(|v| v.as_str()).unwrap_or("Unknown submodule error")
                                        })
                                    };
                                    let _ = oneshot_tx.send(payload);
                                }
                            }
                        }
                    }
                }
            }
            Ok(Message::Close(_)) | Err(_) => break,
            _ => {} // Ignore ping/pong/binary at WS level
        }
    }

    send_task.abort();

    // Clean up registration on disconnect
    if let Some(mod_id) = registered_module_id {
        let mut modules = process_manager.modules.write().await;
        if let Some(entry) = modules.get_mut(&mod_id) {
            entry.ipc_tx = None;
            entry.tools.clear();
            entry.module_scope = None;
            if entry.state == ModuleState::IpcConnected {
                entry.state = ModuleState::Running;
            }
            warn!(
                subsystem = "ipc_server",
                module = %mod_id,
                peer = %peer_addr,
                "IPC connection closed — tools unregistered, state reverted to Running"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_governor_ai_route_json_frame_parsing() {
        let raw_json = serde_json::json!({
            "id": "test-tx-123",
            "op": "governor.ai.route",
            "prompt": "SYSTEM: You are a JSON transformation engine...",
            "context_hint": "resume",
            "model": "qwen3.5:2b",
            "offload_device_url": "windows"
        });

        let op = raw_json["op"].as_str().unwrap();
        assert_eq!(op, "governor.ai.route");

        let call_id = raw_json["id"].as_str().unwrap();
        assert_eq!(call_id, "test-tx-123");

        let context_hint = raw_json["context_hint"].as_str().unwrap();
        assert_eq!(context_hint, "resume");

        let model = raw_json["model"].as_str().unwrap();
        assert_eq!(model, "qwen3.5:2b");
    }
}
