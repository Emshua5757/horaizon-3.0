// shua_governor — Centralized Logging & Telemetry Subsystem
// Structured binary log pipeline — MPSC ring-buffer + SQLite LTM + WebSocket Stream

pub mod bridge;
pub mod broadcaster;
pub mod entry;
pub mod filter;
pub mod flush;
pub mod listener;
