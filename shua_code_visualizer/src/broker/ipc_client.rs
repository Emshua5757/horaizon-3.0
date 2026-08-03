use crate::graph::store::CodeGraph;
use crate::mcp::handler::McpHandler;
use crate::mcp::schema::TopologyDeltaEvent;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::sync::Arc;
use tokio::sync::{mpsc, Mutex};
use tokio::time::{sleep, Duration};
use tokio_tungstenite::{connect_async, tungstenite::Message};

pub struct IpcClient;

impl IpcClient {
    /// Connects to parent governor IPC WebSocket server, auto-registers tools, and enters duplex message loop.
    /// Returns an MPSC sender for broadcasting live TopologyDeltaEvents over the IPC connection.
    pub async fn start_ipc_loop(
        ipc_port: u16,
        graph: Arc<Mutex<CodeGraph>>,
    ) -> mpsc::UnboundedSender<TopologyDeltaEvent> {
        let (tx, mut rx) = mpsc::unbounded_channel::<TopologyDeltaEvent>();
        let url = format!("ws://127.0.0.1:{}", ipc_port);

        tokio::spawn(async move {
            loop {
                println!("Connecting to parent governor IPC socket at {}...", url);
                match connect_async(&url).await {
                    Ok((ws_stream, _)) => {
                        println!("HBP v2 IPC connection established with parent governor.");
                        let (mut write, mut read) = ws_stream.split();

                        // 1. Send registration manifest frame
                        let reg_frame = serde_json::json!({
                            "op": "governor.mcp.register",
                            "module_id": "shua.code_visualizer",
                            "version": "0.3.1",
                            "scope": "code",
                            "tools": [
                                {
                                    "name": "code_parse_ast",
                                    "description": "Parses a single source file and returns AST symbol and edge extraction payload.",
                                    "scope": "code",
                                    "timeout_s": 60,
                                    "input_schema": { "type": "object", "properties": { "file_path": { "type": "string" } }, "required": ["file_path"] }
                                },
                                {
                                    "name": "code_read_file",
                                    "description": "Fetches raw source text or a line-range snippet for a target file path.",
                                    "scope": "code",
                                    "timeout_s": 10,
                                    "input_schema": { "type": "object", "properties": { "file_path": { "type": "string" }, "start_line": { "type": "integer" }, "end_line": { "type": "integer" } }, "required": ["file_path"] }
                                },
                                {
                                    "name": "code_render_graph",
                                    "description": "Renders a filtered topology graph export payload by module path and max call depth.",
                                    "scope": "code",
                                    "timeout_s": 15,
                                    "input_schema": { "type": "object", "properties": { "module_path": { "type": "string" }, "max_depth": { "type": "integer" } }, "required": [] }
                                },
                                {
                                    "name": "code_blast_radius",
                                    "description": "Performs BFS caller-depth search for a target qualified symbol name. Returns all callers up to max_depth.",
                                    "scope": "code",
                                    "timeout_s": 20,
                                    "input_schema": { "type": "object", "properties": { "qualified_name": { "type": "string" }, "max_depth": { "type": "integer" } }, "required": ["qualified_name"] }
                                },
                                {
                                    "name": "code_find_callers",
                                    "description": "Returns all direct caller symbols of a given qualified function name.",
                                    "scope": "code",
                                    "timeout_s": 10,
                                    "input_schema": { "type": "object", "properties": { "qualified_name": { "type": "string" } }, "required": ["qualified_name"] }
                                },
                                {
                                    "name": "code_find_dead_code",
                                    "description": "Scans the code graph and returns all private, non-test, non-entrypoint symbols with zero fan-in (unreferenced dead code).",
                                    "scope": "code",
                                    "timeout_s": 30,
                                    "input_schema": { "type": "object", "properties": {}, "required": [] }
                                },
                                {
                                    "name": "code_find_god_functions",
                                    "description": "Returns functions exceeding configurable thresholds for lines-of-code, cyclomatic complexity, or parameter count.",
                                    "scope": "code",
                                    "timeout_s": 15,
                                    "input_schema": { "type": "object", "properties": {}, "required": [] }
                                },
                                {
                                    "name": "code_check_contract_drift",
                                    "description": "Verifies AST symbol signatures against HBP contract schemas and reports any drift.",
                                    "scope": "code",
                                    "timeout_s": 20,
                                    "input_schema": { "type": "object", "properties": {}, "required": [] }
                                }
                            ]
                        });

                        if let Ok(reg_text) = serde_json::to_string(&reg_frame) {
                            let _ = write.send(Message::Text(reg_text)).await;
                        }

                        // 2. Duplex event & message loop using tokio::select!
                        loop {
                            tokio::select! {
                                // Incoming IPC frames from parent governor
                                msg = read.next() => {
                                    match msg {
                                        Some(Ok(Message::Text(text))) => {
                                            if let Ok(val) = serde_json::from_str::<Value>(&text) {
                                                if val["op"] == "mcp.tool_call" {
                                                    let tool_name = val["tool"].as_str().unwrap_or("");
                                                    let args = &val["args"];
                                                    let req_id = val["id"].clone();

                                                    let mut g = graph.lock().await;
                                                    let mut handler = McpHandler::new(&mut g, None);
                                                    let res = handler.handle_tool_call(tool_name, args);

                                                    let resp_frame = match res {
                                                        Ok(result_val) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "ok",
                                                            "result": result_val
                                                        }),
                                                        Err(err_msg) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "error",
                                                            "error": err_msg
                                                        }),
                                                    };

                                                    if let Ok(resp_text) = serde_json::to_string(&resp_frame) {
                                                        let _ = write.send(Message::Text(resp_text)).await;
                                                    }
                                                } else {
                                                    println!("Received unhandled HBP IPC op: '{}'", val["op"].as_str().unwrap_or("unknown"));
                                                }
                                            }
                                        }
                                        Some(Ok(_)) => {}
                                        Some(Err(e)) => {
                                            eprintln!("Governor IPC read error: {}", e);
                                            break;
                                        }
                                        None => {
                                            println!("Governor IPC connection closed by remote.");
                                            break;
                                        }
                                    }
                                }

                                // Outgoing TopologyDeltaEvents from live watcher
                                delta_opt = rx.recv() => {
                                    if let Some(event) = delta_opt {
                                        let push_frame = serde_json::json!({
                                            "op": "changed",
                                            "event": event
                                        });

                                        if let Ok(push_text) = serde_json::to_string(&push_frame) {
                                            if let Err(e) = write.send(Message::Text(push_text)).await {
                                                eprintln!("Failed to push TopologyDeltaEvent to governor: {}", e);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!(
                            "Governor IPC connection failed ({}); retrying in 3 seconds...",
                            e
                        );
                    }
                }
                sleep(Duration::from_secs(3)).await;
            }
        });

        tx
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_ipc_client_channel_creation() {
        let graph = Arc::new(Mutex::new(CodeGraph::new()));
        let tx = IpcClient::start_ipc_loop(59999, graph).await;

        let sample_event = TopologyDeltaEvent {
            file_path: "src/lib.rs".to_string(),
            change_type: crate::mcp::schema::ChangeType::Modified,
            affected_node_ids: vec!["src/lib.rs:foo".to_string()],
        };

        assert!(tx.send(sample_event).is_ok());
    }
}
