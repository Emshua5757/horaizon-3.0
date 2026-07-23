use anyhow::Result;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

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
            _ => Err(anyhow::anyhow!("Unknown MsgType: {v}")),
        }
    }
}

/// Universal HBP v2 message envelope.
/// All fields map directly to the spec in hbp_v2_spec.md.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HbpFrame {
    /// Protocol version — always 2
    pub v: u8,
    /// Message type code
    pub t: u8,
    /// Transaction ID (UUID v4 string)
    pub id: String,
    /// Module namespace e.g. "shua.resume"
    #[serde(rename = "mod")]
    pub mod_: String,
    /// Operation name e.g. "compile"
    pub op: String,
    /// Unix timestamp in milliseconds
    pub ts: u64,
    /// Payload bytes (msgpack-encoded operation body)
    pub p: Vec<u8>,
    /// Error string — None/nil on success
    #[serde(default)]
    pub err: Option<String>,
}

impl HbpFrame {
    /// Create a new REQUEST frame
    #[allow(dead_code)]
    pub fn request(module: &str, op: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Request as u8,
            id: Uuid::new_v4().to_string(),
            mod_: module.to_string(),
            op: op.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create a RESPONSE frame echoing the request's tx_id
    pub fn response(req_id: &str, module: &str, op: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Response as u8,
            id: req_id.to_string(),
            mod_: module.to_string(),
            op: op.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create an error RESPONSE
    pub fn error_response(req_id: &str, module: &str, op: &str, error: &str) -> Self {
        Self {
            v: 2,
            t: MsgType::Response as u8,
            id: req_id.to_string(),
            mod_: module.to_string(),
            op: op.to_string(),
            ts: now_ms(),
            p: vec![],
            err: Some(error.to_string()),
        }
    }

    /// Create a server-pushed EVENT frame
    pub fn event(module: &str, event_name: &str, payload: Vec<u8>) -> Self {
        Self {
            v: 2,
            t: MsgType::Event as u8,
            id: Uuid::new_v4().to_string(),
            mod_: module.to_string(),
            op: event_name.to_string(),
            ts: now_ms(),
            p: payload,
            err: None,
        }
    }

    /// Create a PONG frame
    pub fn pong() -> Self {
        Self {
            v: 2,
            t: MsgType::Pong as u8,
            id: Uuid::new_v4().to_string(),
            mod_: "shua.governor".to_string(),
            op: "pong".to_string(),
            ts: now_ms(),
            p: vec![],
            err: None,
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
        assert_eq!(decoded.err, None);
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
