use std::env;
use std::io::Write;
use std::time::SystemTime;
use serde::Serialize;
use std::collections::HashMap;
use tracing::{Event, Level, Subscriber};
use tracing_subscriber::{
    layer::Context,
    Layer,
};
use std::sync::atomic::AtomicBool;

pub static CENTRALIZED_LOGGING: AtomicBool = AtomicBool::new(false);
pub static VERBOSE_LOGGING: AtomicBool = AtomicBool::new(false);


pub struct HbpLoggerLayer {
    min_level: u8,
}

impl HbpLoggerLayer {
    pub fn new() -> Self {
        // LogLevel: TRACE=1, DEBUG=2, INFO=3, WARN=4, ERROR=5, CRITICAL=6
        let min_level_env = env::var("LOG_MIN_LEVEL")
            .ok()
            .and_then(|s| s.parse::<u8>().ok())
            .unwrap_or(3); // Default to INFO (3)
        Self { min_level: min_level_env }
    }
}

/// Helper visitor to collect fields from tracing events.
struct FieldVisitor {
    message: String,
    fields: HashMap<String, serde_json::Value>,
}

impl tracing::field::Visit for FieldVisitor {
    fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
        let val_str = format!("{:?}", value);
        if field.name() == "message" {
            self.message = val_str;
        } else {
            self.fields.insert(field.name().to_string(), serde_json::Value::String(val_str));
        }
    }

    fn record_str(&mut self, field: &tracing::field::Field, value: &str) {
        if field.name() == "message" {
            self.message = value.to_string();
        } else {
            self.fields.insert(field.name().to_string(), serde_json::Value::String(value.to_string()));
        }
    }

    fn record_u64(&mut self, field: &tracing::field::Field, value: u64) {
        self.fields.insert(field.name().to_string(), serde_json::Value::Number(value.into()));
    }

    fn record_i64(&mut self, field: &tracing::field::Field, value: i64) {
        self.fields.insert(field.name().to_string(), serde_json::Value::Number(value.into()));
    }

    fn record_bool(&mut self, field: &tracing::field::Field, value: bool) {
        self.fields.insert(field.name().to_string(), serde_json::Value::Bool(value));
    }
}

/// Formats standard Level to our HBP level (u8)
fn map_level(level: &Level) -> u8 {
    match *level {
        Level::TRACE => 1,
        Level::DEBUG => 2,
        Level::INFO => 3,
        Level::WARN => 4,
        Level::ERROR => 5,
    }
}

impl<S: Subscriber> Layer<S> for HbpLoggerLayer {
    fn on_event(&self, event: &Event<'_>, _ctx: Context<'_, S>) {
        let metadata = event.metadata();
        let level = map_level(metadata.level());

        // Emitter Gate Check (Fast Path)
        if level < self.min_level {
            return;
        }

        // Collect fields
        let mut visitor = FieldVisitor {
            message: String::new(),
            fields: HashMap::new(),
        };
        event.record(&mut visitor);

        let ts = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as u64;

        // Build integer-keyed MessagePack payload
        // Key 0: ts, Key 1: level, Key 2: module (SHUA_CODE_VISUALIZER = 12), Key 3: subsystem, Key 4: msg
        let subsystem = visitor.fields.remove("subsystem")
            .and_then(|v| v.as_str().map(|s| s.to_string()))
            .unwrap_or_else(|| metadata.target().to_string());

        let tags: u32 = visitor.fields.remove("tags")
            .and_then(|v| v.as_u64().map(|n| n as u32))
            .unwrap_or(0);

        let trace_id = visitor.fields.remove("trace_id")
            .and_then(|v| v.as_str().map(|s| s.to_string()));

        // Check if there are other dynamic custom tags or telemetry fields
        let custom_tags = visitor.fields.remove("custom_tags")
            .and_then(|v| {
                if let serde_json::Value::Array(arr) = v {
                    Some(arr.into_iter().filter_map(|x| x.as_str().map(|s| s.to_string())).collect::<Vec<String>>())
                } else {
                    None
                }
            });

        // The remaining fields in visitor.fields are stored as telemetry
        let telemetry = if !visitor.fields.is_empty() {
            Some(serde_json::to_value(&visitor.fields).unwrap_or(serde_json::Value::Null))
        } else {
            None
        };

        // Serialize maps into MessagePack using integer keys
        // To follow the binary contract, we use a custom map or struct with serde(rename) integer keys.
        #[derive(Serialize)]
        struct HbpLogMsgpack {
            #[serde(rename = "0")]
            ts: u64,
            #[serde(rename = "1")]
            level: u8,
            #[serde(rename = "2")]
            module: u8,
            #[serde(rename = "3")]
            subsystem: String,
            #[serde(rename = "4")]
            msg: String,
            #[serde(rename = "5")]
            tags: u32,
            #[serde(skip_serializing_if = "Option::is_none")]
            #[serde(rename = "6")]
            custom_tags: Option<Vec<String>>,
            #[serde(skip_serializing_if = "Option::is_none")]
            #[serde(rename = "7")]
            telemetry: Option<serde_json::Value>,
            #[serde(skip_serializing_if = "Option::is_none")]
            #[serde(rename = "8")]
            trace_id: Option<String>,
        }

        let log_entry = HbpLogMsgpack {
            ts,
            level,
            module: 12, // SHUA_CODE_VISUALIZER = 12
            subsystem,
            msg: visitor.message,
            tags,
            custom_tags,
            telemetry,
            trace_id,
        };

        if let Ok(msgpack_bytes) = rmp_serde::to_vec(&log_entry) {
            let mut header = [0u8; 12];
            header[0] = 0x48; // 'H'
            header[1] = 0x42; // 'B'
            header[2] = 0x01; // Version 1
            header[3] = 0x12; // Type: LOG (0x12)
            // Bytes 4-7: reserved (0x00)
            
            // Length: big-endian u32
            let len = msgpack_bytes.len() as u32;
            let len_bytes = len.to_be_bytes();
            header[8..12].copy_from_slice(&len_bytes);

            // Write atomically to standard output
            let stdout = std::io::stdout();
            let mut handle = stdout.lock();
            let _ = handle.write_all(&header);
            let _ = handle.write_all(&msgpack_bytes);
            let _ = handle.flush();
        }
    }
}

pub fn log_status(subsystem: &str, message: &str) {
    let centralized = CENTRALIZED_LOGGING.load(std::sync::atomic::Ordering::Relaxed);
    if centralized {
        tracing::info!(subsystem = subsystem, message = %message);
    } else {
        println!("{}", message);
    }
}

pub fn log_verbose(subsystem: &str, message: &str) {
    let verbose = VERBOSE_LOGGING.load(std::sync::atomic::Ordering::Relaxed);
    let centralized = CENTRALIZED_LOGGING.load(std::sync::atomic::Ordering::Relaxed);
    if verbose {
        if centralized {
            tracing::info!(subsystem = subsystem, message = %message);
        } else {
            println!("{}", message);
        }
    }
}

