use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Result;
use futures_util::{SinkExt, StreamExt};
use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{error, info, warn};

use crate::broker::dispatcher::Dispatcher;
use crate::broker::frame::HbpFrame;

pub struct BrokerServer {
    dispatcher: Arc<Dispatcher>,
}

impl BrokerServer {
    pub fn new(dispatcher: Arc<Dispatcher>) -> Self {
        Self { dispatcher }
    }

    pub async fn run(&self, addr: SocketAddr) -> Result<()> {
        let listener = TcpListener::bind(addr).await?;
        info!(
            module = "shua.governor",
            subsystem = "broker",
            address = %addr,
            "HBP v2 WebSocket broker listening"
        );

        loop {
            match listener.accept().await {
                Ok((stream, peer_addr)) => {
                    info!(
                        module = "shua.governor",
                        subsystem = "broker",
                        peer = %peer_addr,
                        "Client connected"
                    );
                    let dispatcher = Arc::clone(&self.dispatcher);
                    tokio::spawn(handle_connection(stream, peer_addr, dispatcher));
                }
                Err(e) => {
                    error!(
                        module = "shua.governor",
                        subsystem = "broker",
                        error = %e,
                        "Accept error"
                    );
                }
            }
        }
    }
}

async fn handle_connection(
    stream: TcpStream,
    peer_addr: SocketAddr,
    dispatcher: Arc<Dispatcher>,
) {
    let ws_stream = match accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            warn!(peer = %peer_addr, error = %e, "WebSocket handshake failed");
            return;
        }
    };

    let (mut ws_tx, mut ws_rx) = ws_stream.split();
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<Vec<u8>>();

    // Forward outbound frames to WebSocket
    let send_task = tokio::spawn(async move {
        while let Some(bytes) = rx.recv().await {
            if ws_tx.send(Message::Binary(bytes)).await.is_err() {
                break;
            }
        }
    });

    // Process inbound frames
    while let Some(msg) = ws_rx.next().await {
        match msg {
            Ok(Message::Binary(bytes)) => {
                match HbpFrame::decode(&bytes) {
                    Ok(frame) => {
                        let resp = dispatcher.dispatch(frame, tx.clone()).await;
                        if let Some(response_frame) = resp {
                            match response_frame.encode() {
                                Ok(encoded) => {
                                    let _ = tx.send(encoded);
                                }
                                Err(e) => error!(error = %e, "Frame encode error"),
                            }
                        }
                    }
                    Err(e) => {
                        warn!(peer = %peer_addr, error = %e, "Frame decode error");
                    }
                }
            }
            Ok(Message::Close(_)) | Err(_) => break,
            _ => {} // ignore text/ping/pong at WS level
        }
    }

    send_task.abort();
    info!(
        module = "shua.governor",
        subsystem = "broker",
        peer = %peer_addr,
        "Client disconnected"
    );
}
