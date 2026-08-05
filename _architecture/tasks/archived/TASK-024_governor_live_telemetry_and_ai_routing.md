# TASK-024: Governor Centralized Live Telemetry Logging & AI Offload Routing

- **Task ID**: `TASK-024`
- **Feature Branch**: `task/TASK-024-governor-telemetry-and-ai-routing`
- **Status**: `[x] Completed`
- **Date Completed**: `2026-08-05`
- **Target OS / Environment**: `Raspberry Pi 5 (Linux ARM64)`, `Windows Dev Host`

---

## 1. Overview & Objective

Implement real-time centralized live telemetry logging and AI offload target routing across `shua_governor` and the Flutter client.

Ensure all runtime execution logs, AI inference offloads, and error events stream over HBP v2 to the Flutter terminal telemetry tab with structured subsystem tagging, inline expandable JSON payload details, and clipboard export capabilities.

---

## 2. Technical Deliverables & Key Changes

1. **`shua_governor` (Rust)**:
   - Wired `ChannelLogger` tracing bridge into the MPSC logging pipeline and `activity.db` SQLite store.
   - Built live HBP v2 WebSocket broadcaster for `governor.log_event` frames.
   - Added `governor.logs.subscribe` and `governor.logs.query` HBP handlers.
   - Resolved AI offload target URL aliases (`windows`, `rpi5`, `host`, loopback) to Tailscale IP `http://100.90.83.12:11434`.
   - Enriched dispatcher error tracing with `frame_id`, `op`, `frame_mod`, `target_url`, and error traceback attributes.

2. **Flutter Client (Dart)**:
   - Added real-time Telemetry Tab view in Flutter terminal screen with live streaming `log_event` subscriber.
   - Built inline accordion expansion for log items to display pretty-printed HBP JSON frame metadata.
   - Added single-tap inline expansion and full-log clipboard copy formatting.
   - Fixed MessagePack map payload decoding in `ollama_ai_service.dart` (`_decodeHbpPayload`).

3. **HBP Contracts**:
   - Synchronized `hbp_logging.toml` schema across Rust, Go, Dart, TypeScript, and Python via `sync_contracts`.

---

## 3. Complexity Analysis

- **Time Complexity**: $O(1)$ per telemetry log event emission and broadcast over WebSocket.
- **Space Complexity**: $O(N)$ bounded ring buffer (4,096 items max) preventing memory growth on Pi 5.

---

## 4. Git History & Commits

- Key commits: `09c0238`, `c57018e`, `088804e`, `692b494`, `ba35aa6`.
