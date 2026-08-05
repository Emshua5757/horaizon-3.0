# TASK-025: Submodule IPC HBP Telemetry Logging

- **Task ID**: `TASK-025`
- **Feature Branch**: `task/TASK-025-hbp-submodule-logging`
- **Status**: `[x] Completed`
- **Date Completed**: `2026-08-05`
- **Target OS / Environment**: `Raspberry Pi 5 (Linux ARM64)`, `Windows Dev Host`

---

## 1. Overview & Objective

Enforce strict **HBP v2 Binary Frame Logging** over IPC sockets across all `shua` submodules (`shua_resume` Go, `shua_code_visualizer` Rust) and `shua_governor` Rust backend before log streams reach the Flutter client.

Eliminate fragile plain-text JSON line parsing and un-routed raw `println!` streams.

---

## 2. Technical Deliverables & Key Changes

1. **HBP Contracts & Specs**:
   - Updated `hbp_logging.toml` to add `module_name` (`str?`) field at index `8` of `LogEntryDto`.
   - Documented **§7 Submodule IPC Log Attribution** in `hbp_logging_spec.md`.
   - Executed `sync_contracts` to generate DTOs for Go, Rust, Dart, TypeScript, Python.

2. **`shua_governor` (Rust)**:
   - Added `module_name()` u8 integer-to-string mapping helper and `module_name_str` field in `entry.rs`.
   - Updated `to_hbp_frame()` to set `mod_ = module_name(self.module)` on WebSocket event frames.
   - Removed legacy plain-text JSON line fallback path in `listener.rs`.

3. **`shua_resume` (Go)**:
   - Replaced JSON line string formatting in `logger.go` with 12-byte HBP binary header + MsgPack `LogEntryDto` frames (`vmihailenco/msgpack/v5`).

4. **`shua_code_visualizer` (Rust)**:
   - Created `src/logging/sender.rs` (`HbpLogLayer`) to stream `tracing` events via TCP socket (`127.0.0.1:5001`).
   - Replaced all raw `println!` calls with `tracing::info!`, `warn!`, `error!`.

5. **`client_flutter` (Dart)**:
   - Updated `terminal_screen.dart` log parsing to prefer `module_name` string field.
   - Updated `TelemetryLogItem` with `moduleId` and `moduleName` fields.

---

## 3. Complexity Analysis

- **Time Complexity**: $O(n)$ where $n$ is byte payload length (zero heap allocation via `BorrowedLogEntry`).
- **Space Complexity**: $O(1)$ stack allocation for 12-byte HBP binary header + non-blocking MPSC channel send.

---

## 4. Git History & Merge

- **Feature Branch**: `task/TASK-025-hbp-submodule-logging`
- **Merge Method**: `git merge --no-ff` into `main`
