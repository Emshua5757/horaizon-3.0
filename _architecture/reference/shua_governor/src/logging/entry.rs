// shua_governor — Log Entry Types (Phase 12)
//
// Two-stage ingress model to minimise heap allocations under high log throughput:
//
//  Stage 1 — FILTER: Parse raw MsgPack bytes into `BorrowedLogEntry<'a>`.
//             Lifetime 'a ties every string slice to the original byte buffer —
//             zero heap allocation. If level < LOG_MIN_LEVEL, drop here.
//
//  Stage 2 — BUFFER: Clone strings into owned `LogEntry` and push to MPSC channel.
//             Only entries that passed the filter gate allocate on the heap.
//
// Big-O:
//   Filter stage: O(k) where k = number of msgpack keys (≤ 9) — constant in practice.
//   Buffer stage: O(1) MPSC send (atomic pointer swap).
//   RAM ceiling: 4096 entries × ~256 bytes avg = ~1MB maximum buffer footprint.

use serde::{Deserialize, Serialize};
use tokio::sync::mpsc;

// ──────────────────────────────────────────────────────────────────────────────
// HBP Log Level integer constants (mirrors HbpLogLevel in hbp_constants.g.dart)
// ──────────────────────────────────────────────────────────────────────────────

pub const LEVEL_TRACE: u8    = 1;
pub const LEVEL_DEBUG: u8    = 2;
pub const LEVEL_INFO: u8     = 3;
pub const LEVEL_WARN: u8     = 4;
pub const LEVEL_ERROR: u8    = 5;

/// Minimum severity level that passes the emitter gate.
/// Entries with `level < LOG_MIN_LEVEL` are dropped before any heap allocation.
/// Configurable at runtime via the `LOG_MIN_LEVEL` environment variable.
pub fn log_min_level() -> u8 {
    std::env::var("LOG_MIN_LEVEL")
        .ok()
        .and_then(|s| s.parse::<u8>().ok())
        .unwrap_or(LEVEL_INFO)
}

// ──────────────────────────────────────────────────────────────────────────────
// Stage 1 — Zero-Allocation Filter Struct (borrowed lifetime)
// ──────────────────────────────────────────────────────────────────────────────

/// Zero-allocation log entry backed by a borrowed byte buffer.
///
/// Every `&'a str` points directly into the raw MsgPack slice — no `String`
/// heap allocations occur unless the entry passes the filter gate and is
/// promoted to `LogEntry`.
///
/// Integer keys 0–8 are the canonical wire contract shared across all languages.
/// `serde(rename)` maps the integer string keys emitted by `rmp_serde`.
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
                            let _ : serde::de::IgnoredAny = map.next_value()?;
                        }
                    }
                }

                let ts = ts.unwrap_or(0);
                let level = level.unwrap_or(3);
                let module = module.unwrap_or(255);
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

        deserializer.deserialize_map(Visitor { marker: std::marker::PhantomData })
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stage 2 — Owned Buffer Entry (heap-allocated post-filter)
// ──────────────────────────────────────────────────────────────────────────────

/// Owned log entry stored in the MPSC ring-buffer channel (capacity 4096).
///
/// Allocated only after the emitter gate check passes. `Clone` is required
/// for fan-out to the live-stream broadcast channel.
#[derive(Serialize, Clone, Debug)]
pub struct LogEntry {
    pub ts:          u64,
    pub level:       u8,
    pub module:      u8,
    pub subsystem:   String,
    pub msg:         String,
    pub tags:        u32,
    pub custom_tags: Option<Vec<String>>,
    pub telemetry:   Option<serde_json::Value>,
    pub trace_id:    Option<String>,
}

impl<'a> From<BorrowedLogEntry<'a>> for LogEntry {
    fn from(b: BorrowedLogEntry<'a>) -> Self {
        LogEntry {
            ts:          b.ts,
            level:       b.level,
            module:      b.module,
            subsystem:   b.subsystem.to_owned(),
            msg:         b.msg.to_owned(),
            tags:        b.tags,
            custom_tags: b.custom_tags.map(|v| v.into_iter().map(str::to_owned).collect()),
            telemetry:   b.telemetry,
            trace_id:    b.trace_id.map(str::to_owned),
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// Channel Type Aliases
// ──────────────────────────────────────────────────────────────────────────────

/// MPSC sender half — injected into AppState, cloned per subsystem that produces logs.
/// O(1) send: single atomic pointer swap into the bounded ring-buffer.
pub type LogSender = mpsc::Sender<LogEntry>;
