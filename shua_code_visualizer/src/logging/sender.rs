// shua_code_visualizer — HBP v2 Binary Frame Log Sender
//
// Connects to the shua_governor TCP log loopback (127.0.0.1:5001) and forwards
// structured tracing events as HBP v2 binary frames (12-byte header + MsgPack LogEntry).
//
// This mirrors the ChannelLogger pattern used by shua_governor's bridge.rs,
// adapted for an external Rust subprocess that does not embed the governor pipeline.
//
// Time Complexity:  O(n) — n = fields in telemetry map per log event.
// Space Complexity: O(1) — bounded MPSC buffer + single TCP connection.

use serde::{Deserialize, Serialize};
use std::io::Write;
use std::net::TcpStream;
use std::sync::{mpsc, Mutex};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tracing::{field::Visit, Subscriber};
use tracing_subscriber::{layer::Context, Layer};

const HBP_MAGIC_0: u8 = 0x48; // 'H'
const HBP_MAGIC_1: u8 = 0x42; // 'B'
const HBP_VERSION: u8 = 0x02;
const HBP_TYPE_LOG: u8 = 0x12;
const MODULE_CODE_VIZ: u8 = 40;

#[derive(Serialize, Deserialize)]
struct LogEntry {
    ts: u64,
    level: u8,
    module: u8,
    subsystem: String,
    msg: String,
    tags: u32,
    telemetry: Option<serde_json::Value>,
    module_name_str: Option<String>,
    trace_id: Option<String>,
}

struct PendingEntry {
    level: u8,
    subsystem: String,
    msg: String,
    telemetry: Option<serde_json::Map<String, serde_json::Value>>,
}

/// Background sender that holds a TCP connection to governor:5001 and
/// drains a sync MPSC channel, encoding entries as HBP binary frames.
struct HbpSender {
    stream: Option<TcpStream>,
}

impl HbpSender {
    fn connect() -> Self {
        match TcpStream::connect("127.0.0.1:5001") {
            Ok(s) => {
                let _ = s.set_write_timeout(Some(Duration::from_millis(200)));
                Self { stream: Some(s) }
            }
            Err(_) => Self { stream: None },
        }
    }

    fn send(&mut self, entry: &LogEntry) {
        let payload = match rmp_serde::to_vec_named(entry) {
            Ok(b) => b,
            Err(_) => return,
        };
        let len = payload.len() as u32;
        let mut header = [0u8; 12];
        header[0] = HBP_MAGIC_0;
        header[1] = HBP_MAGIC_1;
        header[2] = HBP_VERSION;
        header[3] = HBP_TYPE_LOG;
        // bytes 4..7 = reserved
        header[8] = (len >> 24) as u8;
        header[9] = (len >> 16) as u8;
        header[10] = (len >> 8) as u8;
        header[11] = len as u8;

        if let Some(ref mut stream) = self.stream {
            if stream.write_all(&header).is_err() || stream.write_all(&payload).is_err() {
                self.stream = None; // drop broken connection — will reconnect next cycle
            }
        }
    }
}

/// Tracing subscriber Layer that captures events from `shua_code_visualizer`
/// and forwards them as HBP v2 binary log frames to shua_governor.
pub struct HbpLogLayer {
    tx: Mutex<mpsc::SyncSender<PendingEntry>>,
}

impl Default for HbpLogLayer {
    fn default() -> Self {
        Self::new()
    }
}

impl HbpLogLayer {
    pub fn new() -> Self {
        let (tx, rx) = mpsc::sync_channel::<PendingEntry>(512);
        thread::spawn(move || {
            let mut sender = HbpSender::connect();
            for pending in rx {
                // Reconnect if stream lost
                if sender.stream.is_none() {
                    sender = HbpSender::connect();
                }
                let ts = SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_millis() as u64;
                let entry = LogEntry {
                    ts,
                    level: pending.level,
                    module: MODULE_CODE_VIZ,
                    subsystem: pending.subsystem,
                    msg: pending.msg,
                    tags: 1, // TAG_SYSTEM
                    telemetry: pending.telemetry.map(serde_json::Value::Object),
                    module_name_str: Some("shua.code_visualizer".to_string()),
                    trace_id: None,
                };
                sender.send(&entry);
            }
        });
        Self { tx: Mutex::new(tx) }
    }
}

impl<S> Layer<S> for HbpLogLayer
where
    S: Subscriber,
{
    fn enabled(&self, metadata: &tracing::Metadata<'_>, _ctx: Context<'_, S>) -> bool {
        metadata.target().starts_with("shua_code_visualizer")
    }

    fn on_event(&self, event: &tracing::Event<'_>, _ctx: Context<'_, S>) {
        let level = match *event.metadata().level() {
            tracing::Level::ERROR => 5u8,
            tracing::Level::WARN  => 4u8,
            tracing::Level::INFO  => 3u8,
            tracing::Level::DEBUG => 2u8,
            tracing::Level::TRACE => 1u8,
        };

        struct Visitor {
            msg: String,
            subsystem: String,
            telemetry: serde_json::Map<String, serde_json::Value>,
        }

        impl Visit for Visitor {
            fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
                match field.name() {
                    "message"   => self.msg = format!("{:?}", value),
                    "subsystem" => self.subsystem = format!("{:?}", value),
                    other => { self.telemetry.insert(other.to_string(), serde_json::json!(format!("{:?}", value))); }
                }
            }
            fn record_str(&mut self, field: &tracing::field::Field, value: &str) {
                match field.name() {
                    "message"   => self.msg = value.to_string(),
                    "subsystem" => self.subsystem = value.to_string(),
                    other => { self.telemetry.insert(other.to_string(), serde_json::json!(value)); }
                }
            }
        }

        let mut visitor = Visitor {
            msg: String::new(),
            subsystem: "general".to_string(),
            telemetry: serde_json::Map::new(),
        };
        event.record(&mut visitor);

        if visitor.msg.is_empty() { return; }

        let pending = PendingEntry {
            level,
            subsystem: visitor.subsystem,
            msg: visitor.msg,
            telemetry: if visitor.telemetry.is_empty() { None } else { Some(visitor.telemetry) },
        };

        if let Ok(tx) = self.tx.lock() {
            let _ = tx.try_send(pending); // non-blocking — drop if full
        }
    }
}
