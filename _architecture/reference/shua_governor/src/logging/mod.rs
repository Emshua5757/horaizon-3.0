// shua_governor — Centralized Logging Subsystem
// Phase 12: Structured binary log pipeline — MPSC ring-buffer + SQLite LTM
//
// pub mod entry  — BorrowedLogEntry<'a> (zero-alloc filter stage) + owned LogEntry (buffer stage)
// pub mod flush  — Dual-trigger Tokio background flush task + SQLite migration

pub mod entry;
pub mod flush;
pub mod bridge;
pub mod listener;
