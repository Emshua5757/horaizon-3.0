# TASK-004 — `shua_governor` HBP v2 Frame + WebSocket Broker

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/broker/` |
| **Blocks** | TASK-005, TASK-006, TASK-007 |
| **Prerequisites** | TASK-003 complete (`cargo check` passes) |

---

## Context

Implement the HBP v2 WebSocket broker — the core communication layer of `shua_governor`. This is the component that all Flutter clients connect to. It accepts connections, decodes MessagePack frames, routes them to the correct handler, and sends responses back.

Read `_architecture/contracts/hbp/hbp_v2_spec.md` in full before implementing.

---

## Step 1: Implement `src/broker/frame.rs` — HBP v2 envelope codec

```rust
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use anyhow::Result;

/// HBP v2 message type codes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum MsgType {
    Request  = 0x01,
    Response = 0x02,
    Event    = 0x03,
    Ping     = 0x04,
    Pong     = 0x05,
    Error    = 0x06,
}

impl TryFrom<u8> for MsgType {
    type Error = anyhow::Error;
    fn try_from(v: u8) -> Result<Self> {
        match v {
            0x01 => Ok(Self::Request),
            0x02 => Ok(Self::Response),
            0x03 => Ok(Self::Event),
            0x04 => Ok(Self::Ping),
            0x05 => Ok(Self::Pong),
            0x06 => Ok(Self::Error),
            _    => Err(anyhow::anyhow!("Unknown MsgType: {v}")),
        }
    }
}

/// Universal HBP v2 message envelope.
/// All fields map directly to the spec in hbp_v2_spec.md.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HbpFrame {
    /// Protocol version — always 2
    pub v:   u8,
    /// Message type code
    pub t:   u8,
    /// Transaction ID (UUID v4 string)
    pub id:  String,
    /// Module namespace e.g. "shua.resume"
    pub mod_: String,  // "mod" is a Rust keyword, use mod_ then rename in serde
    /// Operation name e.g. "compile"
    pub op:  String,
    /// Unix timestamp in milliseconds
    pub ts:  u64,
    /// Payload bytes (msgpack-encoded operation body)
    pub p:   Vec<u8>,
    /// Error string — None on success
    #[serde(skip_serializing_if = "Option::is_none")]
    pub err: Option<String>,
}

impl HbpFrame {
    /// Create a new REQUEST frame
    pub fn request(module: &str, op: &str, payload: Vec<u8>) -> Self {
        Self {
            v:    2,
            t:    MsgType::Request as u8,
            id:   Uuid::new_v4().to_string(),
            mod_: module.to_string(),
            op:   op.to_string(),
            ts:   now_ms(),
            p:    payload,
            err:  None,
        }
    }

    /// Create a RESPONSE frame echoing the request's tx_id
    pub fn response(req_id: &str, module: &str, op: &str, payload: Vec<u8>) -> Self {
        Self {
            v:    2,
            t:    MsgType::Response as u8,
            id:   req_id.to_string(),
            mod_: module.to_string(),
            op:   op.to_string(),
            ts:   now_ms(),
            p:    payload,
            err:  None,
        }
    }

    /// Create an error RESPONSE
    pub fn error_response(req_id: &str, module: &str, op: &str, error: &str) -> Self {
        Self {
            v:    2,
            t:    MsgType::Response as u8,
            id:   req_id.to_string(),
            mod_: module.to_string(),
            op:   op.to_string(),
            ts:   now_ms(),
            p:    vec![],
            err:  Some(error.to_string()),
        }
    }

    /// Create a server-pushed EVENT frame
    pub fn event(module: &str, event_name: &str, payload: Vec<u8>) -> Self {
        Self {
            v:    2,
            t:    MsgType::Event as u8,
            id:   Uuid::new_v4().to_string(),
            mod_: module.to_string(),
            op:   event_name.to_string(),
            ts:   now_ms(),
            p:    payload,
            err:  None,
        }
    }

    /// Create a PONG frame
    pub fn pong() -> Self {
        Self {
            v:    2,
            t:    MsgType::Pong as u8,
            id:   Uuid::new_v4().to_string(),
            mod_: "shua.governor".to_string(),
            op:   "pong".to_string(),
            ts:   now_ms(),
            p:    vec![],
            err:  None,
        }
    }

    /// Encode frame to MessagePack bytes
    pub fn encode(&self) -> Result<Vec<u8>> {
        rmp_serde::to_vec(self).map_err(|e| anyhow::anyhow!("Encode error: {e}"))
    }

    /// Decode frame from MessagePack bytes
    pub fn decode(bytes: &[u8]) -> Result<Self> {
        rmp_serde::from_slice(bytes).map_err(|e| anyhow::anyhow!("Decode error: {e}"))
    }

    /// Decode the payload field as a typed struct
    pub fn decode_payload<T: for<'de> serde::Deserialize<'de>>(&self) -> Result<T> {
        rmp_serde::from_slice(&self.p).map_err(|e| anyhow::anyhow!("Payload decode error: {e}"))
    }

    /// Encode a typed struct into the payload field bytes
    pub fn encode_payload<T: serde::Serialize>(value: &T) -> Result<Vec<u8>> {
        rmp_serde::to_vec(value).map_err(|e| anyhow::anyhow!("Payload encode error: {e}"))
    }
}

fn now_ms() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}

// Fix serde field name for "mod_" -> "mod"
// Apply a custom serde rename at the struct level
// NOTE: re-derive with rename on the field
// Already handled above — if serde complains about "mod_", add:
// #[serde(rename = "mod")]
// to the mod_ field.
```

> [!IMPORTANT]
> The field `mod_` needs `#[serde(rename = "mod")]` because `mod` is a Rust keyword. Add this attribute to the `mod_` field in the struct.

---

## Step 2: Implement `src/broker/server.rs` — WebSocket listener

```rust
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

    // Spawn a channel so dispatcher can send frames back to this client
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<Vec<u8>>();

    // Forward outbound frames to WebSocket
    let send_task = tokio::spawn(async move {
        while let Some(bytes) = rx.recv().await {
            if ws_tx.send(Message::Binary(bytes.into())).await.is_err() {
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
                                Ok(encoded) => { let _ = tx.send(encoded); }
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
    info!(module = "shua.governor", subsystem = "broker", peer = %peer_addr, "Client disconnected");
}
```

---

## Step 3: Implement `src/broker/dispatcher.rs` — frame routing

```rust
use std::sync::Arc;
use tokio::sync::mpsc::UnboundedSender;
use tracing::{info, warn};

use crate::broker::frame::{HbpFrame, MsgType};

/// The dispatcher routes incoming HBP frames to the correct handler.
/// In Phase 1, only shua.governor operations are handled internally.
/// Other modules will be added in TASK-005/006.
pub struct Dispatcher {
    // Future: add module handles here
}

impl Dispatcher {
    pub fn new() -> Self {
        Self {}
    }

    /// Route an incoming frame. Returns an optional response frame.
    /// For EVENT or fire-and-forget operations, returns None.
    pub async fn dispatch(
        &self,
        frame: HbpFrame,
        _client_tx: UnboundedSender<Vec<u8>>,
    ) -> Option<HbpFrame> {
        // Handle PING at the protocol level
        let msg_type = MsgType::try_from(frame.t).unwrap_or(MsgType::Request);
        if msg_type == MsgType::Ping {
            return Some(HbpFrame::pong());
        }

        info!(
            module = "shua.governor",
            subsystem = "dispatcher",
            frame_mod = %frame.mod_,
            op = %frame.op,
            tx_id = %frame.id,
            "Dispatching frame"
        );

        match frame.mod_.as_str() {
            "shua.governor" => self.handle_governor(frame).await,
            other => {
                warn!(subsystem = "dispatcher", module = other, "Unknown module");
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_UNKNOWN_MODULE",
                ))
            }
        }
    }

    async fn handle_governor(&self, frame: HbpFrame) -> Option<HbpFrame> {
        match frame.op.as_str() {
            "ping" => Some(HbpFrame::pong()),

            "status" => {
                // TODO: TASK-005 — return real registry status
                // For now return a stub response
                let stub = serde_json::json!({
                    "modules": [],
                    "ollama": { "loaded_model": null, "ram_mb": null }
                });
                let payload = HbpFrame::encode_payload(&stub).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
            }

            other => {
                warn!(subsystem = "dispatcher", op = other, "Unknown governor op");
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_UNKNOWN_OP",
                ))
            }
        }
    }
}
```

---

## Step 4: Update `src/main.rs` to start the broker

Add the broker startup to `main.rs`:

```rust
use std::net::SocketAddr;
use std::sync::Arc;

use crate::broker::{dispatcher::Dispatcher, server::BrokerServer};

// Inside main(), replace the placeholder with:
let dispatcher = Arc::new(Dispatcher::new());
let broker = BrokerServer::new(Arc::clone(&dispatcher));

let addr: SocketAddr = "0.0.0.0:7700".parse()?;
tokio::spawn(async move {
    if let Err(e) = broker.run(addr).await {
        tracing::error!(error = %e, "Broker error");
    }
});

info!(module = "shua.governor", port = 7700, "HBP v2 broker started");
tokio::signal::ctrl_c().await?;
```

---

## Step 5: Write unit test for `frame.rs`

In `src/broker/frame.rs`, add at the bottom:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_frame_roundtrip() {
        let frame = HbpFrame::request("shua.resume", "compile", b"payload".to_vec());
        let encoded = frame.encode().expect("encode");
        let decoded = HbpFrame::decode(&encoded).expect("decode");
        assert_eq!(decoded.mod_, "shua.resume");
        assert_eq!(decoded.op, "compile");
        assert_eq!(decoded.v, 2);
    }

    #[test]
    fn test_pong_frame() {
        let pong = HbpFrame::pong();
        assert_eq!(pong.t, MsgType::Pong as u8);
    }

    #[test]
    fn test_error_response() {
        let err = HbpFrame::error_response("tx-123", "shua.governor", "status", "ERR_UNKNOWN_OP");
        assert!(err.err.is_some());
        assert_eq!(err.id, "tx-123");
    }
}
```

---

## Step 6: Verify

```powershell
cd c:\horaizon-3.0\shua_governor
cargo test
cargo build
```

Manual integration test (run the binary, use `wscat` or any WebSocket client):

```bash
# Install wscat if needed: npm i -g wscat
# Connect to the broker
wscat -c ws://localhost:7700

# Send a ping frame (as binary MessagePack) — use a script or Postman
# Expected: PONG frame returned within 50ms
```

---

## Acceptance Criteria

- [ ] `src/broker/frame.rs` — `HbpFrame` encodes and decodes with MessagePack (unit test passes)
- [ ] `src/broker/server.rs` — WebSocket server accepts connections on port 7700
- [ ] `src/broker/dispatcher.rs` — PING returns PONG, `governor.status` returns stub JSON, unknown module returns `ERR_UNKNOWN_MODULE`
- [ ] `cargo test` — all tests pass
- [ ] `cargo build` — builds without errors
- [ ] Running the binary and sending a PING via WebSocket returns a PONG frame

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — complete frame spec
- `_architecture/specs/shua_governor/shua_governor_spec.md` — broker implementation notes
