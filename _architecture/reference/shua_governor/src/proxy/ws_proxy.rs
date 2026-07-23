// shua_governor — WebSocket Reverse Proxy
// Transparently pipes Flutter Socket.io connections to upstream microservices.
// Flutter ONLY knows the Governor URL (port 3000). Port resolution is done
// server-side from the in-memory ModuleRegistry — zero hardcoding in client.

use axum::{
    extract::{
        ws::{Message as AxumMsg, WebSocket, WebSocketUpgrade},
        Path, State,
    },
    response::Response,
};
use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::{connect_async, tungstenite::Message as WsMsg};

use crate::routes::dashboard::AppState;

pub async fn ws_proxy_handler(
    Path(module_id): Path<String>,
    State(state): State<AppState>,
    ws: WebSocketUpgrade,
) -> Response {
    handle_ws_proxy(module_id, state, ws).await
}

pub async fn ws_proxy_wildcard_handler(
    Path((module_id, _subpath)): Path<(String, String)>,
    State(state): State<AppState>,
    ws: WebSocketUpgrade,
) -> Response {
    handle_ws_proxy(module_id, state, ws).await
}

async fn handle_ws_proxy(
    module_id: String,
    state: AppState,
    ws: WebSocketUpgrade,
) -> Response {
    // O(1) registry lookup — resolves port without exposing it to Flutter
    let port = {
        let guard = state.registry.read().await;
        guard.get(&module_id).map(|e| e.port).unwrap_or(3001)
    };

    tracing::info!(subsystem = "ws_proxy", module_id = %module_id, "Accepting WebSocket connection for '{}' → upstream port {}", module_id, port);

    ws.on_upgrade(move |client_socket| pipe_sockets(client_socket, module_id, port))
}

/// Bidirectional TCP pipe between the Flutter client WebSocket and the upstream
/// microservice Socket.io server. Zero-copy: raw frames are forwarded without
/// parsing Engine.IO or Socket.IO protocol bytes.
async fn pipe_sockets(client: WebSocket, module_id: String, upstream_port: u16) {
    // Connect directly to upstream Socket.io WebSocket endpoint
    let upstream_url = format!(
        "ws://127.0.0.1:{}/socket.io/?EIO=4&transport=websocket",
        upstream_port
    );

    match connect_async(&upstream_url).await {
        Ok((upstream, _)) => {
            tracing::info!(subsystem = "ws_proxy", module_id = %module_id, "Piping '{}' ↔ {}", module_id, upstream_url);

            let (mut client_tx, mut client_rx) = client.split();
            let (mut upstream_tx, mut upstream_rx) = upstream.split();

            // Flutter client → upstream microservice
            let c2u = async {
                while let Some(Ok(msg)) = client_rx.next().await {
                    let fwd = match msg {
                        AxumMsg::Text(t)   => WsMsg::Text(t),
                        AxumMsg::Binary(b) => WsMsg::Binary(b),
                        AxumMsg::Ping(p)   => WsMsg::Ping(p),
                        AxumMsg::Pong(p)   => WsMsg::Pong(p),
                        AxumMsg::Close(_)  => break,
                    };
                    if upstream_tx.send(fwd).await.is_err() { break; }
                }
            };

            // Upstream microservice → Flutter client
            let u2c = async {
                while let Some(Ok(msg)) = upstream_rx.next().await {
                    let fwd = match msg {
                        WsMsg::Text(t)    => AxumMsg::Text(t),
                        WsMsg::Binary(b)  => AxumMsg::Binary(b),
                        WsMsg::Ping(p)    => AxumMsg::Ping(p),
                        WsMsg::Pong(p)    => AxumMsg::Pong(p),
                        WsMsg::Close(_)   => break,
                        WsMsg::Frame(_)   => continue,
                    };
                    if client_tx.send(fwd).await.is_err() { break; }
                }
            };

            // Race both directions — whichever closes first tears down both
            tokio::select! {
                _ = c2u => {}
                _ = u2c => {}
            }

            tracing::info!(subsystem = "ws_proxy", module_id = %module_id, "Connection closed");
        }
        Err(e) => {
            tracing::error!(subsystem = "ws_proxy", module_id = %module_id, "Failed to connect to upstream: {}", e);
        }
    }
}
