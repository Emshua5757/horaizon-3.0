// shua_governor — Log Entry Types & Data Models
//
// Two-stage ingress model to minimise heap allocations under high log throughput:
//
//  Stage 1 — FILTER: Parse raw MsgPack bytes into `BorrowedLogEntry<'a>`.
//             Lifetime 'a ties every string slice to the original byte buffer —
//             zero heap allocation. If level < LOG_MIN_LEVEL, drop here.
//
//  Stage 2 — BUFFER: Clone strings into owned `LogEntry` and push to MPSC channel.
//             Only entries that passed the filter gate allocate on the heap.

use anyhow::Result;
use serde::{Deserialize, Serialize};
use tokio::sync::mpsc;
use crate::broker::frame::HbpFrame;

// HBP Log Level integer constants
pub const LEVEL_TRACE: u8 = 1;
pub const LEVEL_DEBUG: u8 = 2;
pub const LEVEL_INFO: u8  = 3;
pub const LEVEL_WARN: u8  = 4;
pub const LEVEL_ERROR: u8 = 5;

// Tag Bitmask flags
#[allow(dead_code)]
pub const TAG_SYSTEM: u32       = 0x01;
pub const TAG_IMPORTANT: u32    = 0x02;
#[allow(dead_code)]
pub const TAG_AI_INFERENCE: u32 = 0x04;
#[allow(dead_code)]
pub const TAG_CLIENT_UI: u32    = 0x08;
pub const TAG_SECURITY: u32     = 0x10;

// Module IDs
#[allow(dead_code)]
pub const MODULE_GOVERNOR: u8 = 10;
#[allow(dead_code)]
pub const MODULE_RESUME: u8   = 20;
#[allow(dead_code)]
pub const MODULE_DIARY: u8    = 30;
#[allow(dead_code)]
pub const MODULE_CODE_VIZ: u8 = 40;
#[allow(dead_code)]
pub const MODULE_GYM: u8      = 50;
#[allow(dead_code)]
pub const MODULE_CRYPTO: u8   = 60;
pub const MODULE_FLUTTER: u8  = 100;
pub const MODULE_UNKNOWN: u8  = 255;

pub fn log_min_level() -> u8 {
    std::env::var("LOG_MIN_LEVEL")
        .ok()
        .and_then(|s| s.parse::<u8>().ok())
        .unwrap_or(LEVEL_INFO)
}

/// Redact bearer tokens, API keys, or sensitive patterns from log messages
pub fn redact_sensitive_data(msg: &str) -> String {
    if msg.contains("Bearer ") || msg.contains("token=") || msg.contains("secret=") {
        let mut s = msg.to_string();
        for key in &["Bearer ", "token=", "secret="] {
            if let Some(pos) = s.find(key) {
                let start = pos + key.len();
                let end = s[start..]
                    .find(|c: char| c.is_whitespace() || c == '&' || c == ';')
                    .map(|p| start + p)
                    .unwrap_or(s.len());
                s.replace_range(start..end, "[REDACTED]");
            }
        }
        s
    } else {
        msg.to_string()
    }
}

#[derive(Debug)]
pub struct BorrowedLogEntry<'a> {
    pub ts: u64,
    pub level: u8,
    pub module: u8,
    pub subsystem: &'a str,
    pub msg: &'a str,
    pub tags: u32,
    pub custom_tags: Option<Vec<&'a str>>,
    pub telemetry: Option<serde_json::Value>,
    pub trace_id: Option<&'a str>,
}

impl<'de: 'a, 'a> Deserialize<'de> for BorrowedLogEntry<'a> {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        struct Visitor<'a> {
            marker: std::marker::PhantomData<&'a ()>,
        }

        impl<'de: 'a, 'a> serde::de::Visitor<'de> for Visitor<'a> {
            type Value = BorrowedLogEntry<'a>;

            fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
                formatter.write_str("a log entry map")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: serde::de::MapAccess<'de>,
            {
                let mut ts = None;
                let mut level = None;
                let mut module = None;
                let mut subsystem = None;
                let mut msg = None;
                let mut tags = None;
                let mut custom_tags = None;
                let mut telemetry = None;
                let mut trace_id = None;

                #[derive(Deserialize)]
                #[serde(untagged)]
                enum Key<'b> {
                    Int(u8),
                    Str(&'b str),
                }

                while let Some(key) = map.next_key::<Key<'de>>()? {
                    match key {
                        Key::Int(0) | Key::Str("0") | Key::Str("ts") => {
                            ts = Some(map.next_value()?);
                        }
                        Key::Int(1) | Key::Str("1") | Key::Str("level") => {
                            level = Some(map.next_value()?);
                        }
                        Key::Int(2) | Key::Str("2") | Key::Str("module") => {
                            module = Some(map.next_value()?);
                        }
                        Key::Int(3) | Key::Str("3") | Key::Str("subsystem") => {
                            subsystem = Some(map.next_value()?);
                        }
                        Key::Int(4) | Key::Str("4") | Key::Str("msg") => {
                            msg = Some(map.next_value()?);
                        }
                        Key::Int(5) | Key::Str("5") | Key::Str("tags") => {
                            tags = Some(map.next_value()?);
                        }
                        Key::Int(6) | Key::Str("6") | Key::Str("custom_tags") => {
                            custom_tags = Some(map.next_value()?);
                        }
                        Key::Int(7) | Key::Str("7") | Key::Str("telemetry") => {
                            telemetry = Some(map.next_value()?);
                        }
                        Key::Int(8) | Key::Str("8") | Key::Str("trace_id") => {
                            trace_id = Some(map.next_value()?);
                        }
                        _ => {
                            let _: serde::de::IgnoredAny = map.next_value()?;
                        }
                    }
                }

                let ts = ts.unwrap_or(0);
                let level = level.unwrap_or(LEVEL_INFO);
                let module = module.unwrap_or(MODULE_UNKNOWN);
                let subsystem = subsystem.unwrap_or("general");
                let msg = msg.unwrap_or("");
                let tags = tags.unwrap_or(0);

                Ok(BorrowedLogEntry {
                    ts,
                    level,
                    module,
                    subsystem,
                    msg,
                    tags,
                    custom_tags,
                    telemetry,
                    trace_id,
                })
            }
        }

        deserializer.deserialize_map(Visitor {
            marker: std::marker::PhantomData,
        })
    }
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct LogEntry {
    pub ts: u64,
    pub level: u8,
    pub module: u8,
    pub subsystem: String,
    pub msg: String,
    pub tags: u32,
    #[serde(default)]
    pub custom_tags: Option<Vec<String>>,
    #[serde(default)]
    pub telemetry: Option<serde_json::Value>,
    #[serde(default)]
    pub trace_id: Option<String>,
}

impl LogEntry {
    /// Convert LogEntry into an HBP v2 EVENT frame for WebSocket stream broadcast
    pub fn to_hbp_frame(&self) -> Result<HbpFrame> {
        let payload = HbpFrame::encode_payload(self)?;
        Ok(HbpFrame::event("shua.governor", "log_event", payload))
    }
}

impl<'a> From<BorrowedLogEntry<'a>> for LogEntry {
    fn from(b: BorrowedLogEntry<'a>) -> Self {
        LogEntry {
            ts: b.ts,
            level: b.level,
            module: b.module,
            subsystem: b.subsystem.to_owned(),
            msg: redact_sensitive_data(b.msg),
            tags: b.tags,
            custom_tags: b.custom_tags.map(|v| v.into_iter().map(str::to_owned).collect()),
            telemetry: b.telemetry,
            trace_id: b.trace_id.map(str::to_owned),
        }
    }
}

#[allow(dead_code)]
pub type LogSender = mpsc::Sender<LogEntry>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_log_entry_to_hbp_frame() {
        let entry = LogEntry {
            ts: 1700000000000,
            level: LEVEL_INFO,
            module: MODULE_GOVERNOR,
            subsystem: "broker".to_string(),
            msg: "Broker active".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: Some("tx-999".to_string()),
        };

        let frame = entry.to_hbp_frame().expect("hbp frame conversion");
        assert_eq!(frame.mod_, "shua.governor");
        assert_eq!(frame.op, "log_event");
        
        let decoded: LogEntry = frame.decode_payload().expect("decode payload");
        assert_eq!(decoded.subsystem, "broker");
        assert_eq!(decoded.trace_id.as_deref(), Some("tx-999"));
    }

    #[test]
    fn test_redact_sensitive_data() {
        let raw = "Connect with Bearer secret12345 to host";
        let redacted = redact_sensitive_data(raw);
        assert_eq!(redacted, "Connect with Bearer [REDACTED] to host");
    }
}
