// shua_governor — Tracing bridge to MPSC logging pipeline
// Phase 12: Layer to forward tracing events to central database and SSE stream

use crate::logging::entry::{LogEntry, LEVEL_DEBUG, LEVEL_ERROR, LEVEL_INFO, LEVEL_TRACE, LEVEL_WARN};
use tokio::sync::mpsc;
use tracing::Subscriber;
use tracing_subscriber::layer::Context;
use tracing_subscriber::Layer;

pub struct ChannelLogger {
    tx: mpsc::Sender<LogEntry>,
}

impl ChannelLogger {
    pub fn new(tx: mpsc::Sender<LogEntry>) -> Self {
        Self { tx }
    }
}

impl<S> Layer<S> for ChannelLogger
where
    S: Subscriber,
{
    fn enabled(&self, metadata: &tracing::Metadata<'_>, _ctx: Context<'_, S>) -> bool {
        let target = metadata.target();
        target.starts_with("shua_governor")
            && !target.contains("logging")
            && !target.contains("logs")
    }

    fn on_event(&self, event: &tracing::Event<'_>, _ctx: Context<'_, S>) {
        let metadata = event.metadata();

        let level = match *metadata.level() {
            tracing::Level::ERROR => LEVEL_ERROR,
            tracing::Level::WARN => LEVEL_WARN,
            tracing::Level::INFO => LEVEL_INFO,
            tracing::Level::DEBUG => LEVEL_DEBUG,
            tracing::Level::TRACE => LEVEL_TRACE,
        };

        struct Visitor {
            msg: String,
            subsystem: String,
            telemetry: serde_json::Map<String, serde_json::Value>,
        }

        impl tracing::field::Visit for Visitor {
            fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
                if field.name() == "message" {
                    self.msg = format!("{:?}", value);
                } else if field.name() == "subsystem" {
                    self.subsystem = format!("{:?}", value);
                } else {
                    let _ = self
                        .telemetry
                        .insert(field.name().to_string(), serde_json::json!(format!("{:?}", value)));
                }
            }

            fn record_str(&mut self, field: &tracing::field::Field, value: &str) {
                if field.name() == "message" {
                    self.msg = value.to_string();
                } else if field.name() == "subsystem" {
                    self.subsystem = value.to_string();
                } else {
                    let _ = self
                        .telemetry
                        .insert(field.name().to_string(), serde_json::json!(value));
                }
            }
        }

        let mut visitor = Visitor {
            msg: String::new(),
            subsystem: "general".to_string(),
            telemetry: serde_json::Map::new(),
        };
        event.record(&mut visitor);

        let entry = LogEntry {
            ts: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
            level,
            module: 10, // SHUA_GOVERNOR
            subsystem: visitor.subsystem,
            msg: visitor.msg,
            tags: 1, // SYSTEM
            custom_tags: None,
            telemetry: if visitor.telemetry.is_empty() {
                None
            } else {
                Some(serde_json::Value::Object(visitor.telemetry))
            },
            trace_id: None,
        };

        let _ = self.tx.try_send(entry);
    }
}
