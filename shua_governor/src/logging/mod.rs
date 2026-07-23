// shua_governor — Centralized Logging Subsystem (ported from 2.0)
// Structured binary log pipeline — MPSC ring-buffer + SQLite LTM
//
// pub mod entry    — BorrowedLogEntry<'a> (zero-alloc filter stage) + owned LogEntry (buffer stage)
// pub mod flush    — Dual-trigger Tokio background flush task + SQLite migration
// pub mod bridge   — Tracing layer that bridges tracing events into the MPSC pipeline
// pub mod listener — UDS (Linux) + TCP loopback IPC log ingress from microservices

pub mod entry;
pub mod flush;
pub mod bridge;
pub mod listener;
