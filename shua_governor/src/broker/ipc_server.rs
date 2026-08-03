use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Result;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use tokio::net::TcpStream;
use tokio::sync::mpsc;
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{error, info, warn};

use crate::mcp::McpToolSchema;
use crate::registry::module_entry::ModuleState;
use crate::registry::process_manager::ProcessManager;

pub struct IpcServer {
    process_manager: Arc<ProcessManager>,
}

impl IpcServer {
    pub fn new(process_manager: Arc<ProcessManager>) -> Self {
        Self { process_manager }
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
                    tokio::spawn(handle_ipc_connection(stream, peer_addr, pm));
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
                        let tools: Vec<McpToolSchema> = val.get("tools")
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
                    } else if let Some(id_str) = val.get("id").and_then(|v| v.as_str()) {
                        // Response frame matching pending in-flight tool call request ID
                        if let Some(ref mod_id) = registered_module_id {
                            let modules = process_manager.modules.read().await;
                            if let Some(entry) = modules.get(mod_id) {
                                let mut pending = entry.pending_calls.lock().await;
                                if let Some(oneshot_tx) = pending.remove(id_str) {
                                    let status = val.get("status").and_then(|v| v.as_str()).unwrap_or("ok");
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
            );
        }
    }
}
