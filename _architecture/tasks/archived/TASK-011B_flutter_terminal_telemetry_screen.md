# TASK-011B — `client_flutter` Native Telemetry & Interactive Terminal Screen

| Field | Value |
| :--- | :--- |
| **Task ID** | `TASK-011B` |
| **Status** | **[x] Completed** |
| **Target Component** | `client_flutter` (`lib/features/terminal/`, `lib/router/app_router.dart`) |
| **Language / Stack** | Dart 3.4+ / Flutter 3.22+ / Riverpod 2.5 / `dartssh2` |
| **Prerequisites** | `TASK-004` (HBP v2 Logging Subsystem), `TASK-009` (HBP v2 Client), `TASK-010` (Theme Engine 2.0) |
| **Branch Policy** | `task/TASK-011B-terminal-screen` (merged `--no-ff` into `main`) |

---

## 1. Executive Summary & Context

`TASK-011B` specifies the native Flutter implementation of the **Telemetry & Interactive Terminal Screen** (`/terminal`), evolving the legacy SDUI primitive ([sdui_terminal.dart](file:///c:/horaizon-3.0/_architecture/reference/client_flutter/lib/sdui/primitives/sdui_terminal.dart)) into a 100% native, reactive, dual-tab diagnostic console:
1. **Tab 1: 📡 Telemetry & Governor Logs**: Connected to `shua_governor` daemon over HBP v2 (`shua.logging.stream` & `shua.logging.query`) for real-time log streaming, tag chip filtering, JSON payload inspection, and governor RPC execution.
2. **Tab 2: 💻 RPi 5 SSH Shell Terminal**: Powered by `dartssh2` native SSH client connecting directly to `shua@100.67.11.0:22` over Tailscale SSH for 100% real interactive Linux bash streaming.

---

## 2. Core Functional Requirements

### 2.1 Live Log Stream & Buffering ($O(1)$ Windowed Buffer)
- **HBP v2 Log Subscription**: Listens to `hbpClientProvider` stream for incoming log frames (`op: "shua.logging.stream"`).
- **Bounded Buffer**: Maintains a maximum ring buffer of `1,000` entries in memory to prevent heap inflation on Raspberry Pi 5 / client devices ($O(1)$ memory constraint).
- **Auto-Scroll Behavior**: Uses `ListView.builder` for zero-lag auto-scrolling to newest entries.

### 2.2 Severity & Subsystem Tag Filtering
- **Severity Chips**: Toggle between `ALL`, `TRACE/DBG`, `INFO`, `WARN`, and `ERR/CRITICAL` filters.
- **Subsystem Chips**: Dynamically aggregates unique log tags (`HBP`, `GOVERNOR`, `OLLAMA`, `DREAM_LOOP`, `METRICS`) for 1-click filtering.
- **Search Bar**: Real-time substring query filtering across log messages and metadata.

### 2.3 RPi 5 Native SSH PTY Shell Stream (`dartssh2`)
- **Direct SSH Connection**: Connects to `shua@100.67.11.0:22` over Tailscale.
- **Interactive Shell PTY Stream**: Real-time bash shell output with stdout/stderr decoding.

---

## 3. Complexity & Raspberry Pi 5 Optimization Analysis

- **Time Complexity $O(\cdot)$**:
  - Log Insertion: $O(1)$ ring-buffer append.
  - Subsystem Filtering: $O(N)$ linear scan over max 1,000 cached buffer entries.
- **Space Complexity $O(\cdot)$**:
  - Fixed $O(1)$ memory cap (capped at 1,000 log items ~500 KB RAM overhead).

---

## 4. Definition of Done & Verification

- [x] Navigating to `/terminal` renders the native Flutter Telemetry & Terminal screen.
- [x] Connects cleanly to `hbpClientProvider` and streams live logs from `shua_governor`.
- [x] Integrated `dartssh2` native SSH engine connecting directly to RPi 5 port 22.
- [x] Severity & Subsystem tag chips dynamically update and filter logs by tag.
- [x] Windows Task Manager style live mini sparkline charts integrated across sidebar and hero card.
- [x] `flutter analyze lib/` passes with **0 warnings / 0 errors**.
- [x] `flutter test` passes all unit tests.
