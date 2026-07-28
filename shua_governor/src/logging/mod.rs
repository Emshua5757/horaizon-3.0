// shua_governor — Centralized Logging & Telemetry Subsystem
// Structured binary log pipeline — MPSC ring-buffer + SQLite LTM + WebSocket Stream

pub mod bridge;
pub mod broadcaster;
pub mod entry;
pub mod filter;
pub mod flush;
pub mod listener;

use std::sync::atomic::{AtomicU64, Ordering};

static LOG_DROP_COUNTER: AtomicU64 = AtomicU64::new(0);

pub fn record_log_drop() {
    LOG_DROP_COUNTER.fetch_add(1, Ordering::Relaxed);
}

pub fn take_log_drop_count() -> u64 {
    LOG_DROP_COUNTER.swap(0, Ordering::Relaxed)
}

