# TASK-011 — `client_flutter` Glassmorphic Shell Scaffold & Dashboard Screen

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/router/shell_scaffold.dart`, `lib/features/dashboard/`, `lib/features/governor/` |
| **Blocks** | TASK-012 |
| **Prerequisites** | TASK-010 complete (GoRouter & Theme Engine) |

---

## Overview & Stitch Design Alignment

Implement the native Flutter **Responsive Navigation Shell Scaffold** (`ShellScaffold`) and **Dashboard Screen** (`DashboardScreen`), strictly translating the Google Stitch designs into native Dart widgets:
1. **Desktop Expanded (width ≥ 900px)**: `Desktop | Dashboard - Telemetry Sidebar` (260px obsidian glass sidebar, profile header, LED status badge, 4 global scope items, header route back/forward navigation `<` and `>`).
2. **Desktop Minimized / Tablet (640px ≤ width < 900px, or user-toggled)**: `Desktop | Dashboard - Minimized Sidebar` (icons-only rail with cyan active indicators).
3. **Mobile (width < 640px)**: `Mobile | Dashboard - Compact` (compact bottom navigation bar).

> [!NOTE]
> **Logs & Terminal Redirection**:
> Telemetry logs from `shua_governor` are rendered exclusively within the standalone `/terminal` screen (`TerminalScreen`). The obsolete `governor_logs_screen.dart` file has been removed.

---

## Technical Specifications

### 1. Governor Status & Power Controller Provider (`lib/features/governor/governor_provider.dart`)
- Fetches RPi5 hardware telemetry (CPU %, memory ceiling RSS vs 7,168 MB, SoC temp, Tailscale RTT).
- Manages module power state toggling over HBP v2 (`governor.module.wake` / `governor.module.sleep` for `cgroups v2` SIGSTOP/SIGCONT).
- Manages Ollama model lifecycle (`governor.ollama.load` / `governor.ollama.evict`).

### 2. Responsive Navigation Shell (`lib/router/shell_scaffold.dart`)
- **Route Navigation History Controls**: Top header `<` (back) and `>` (forward) buttons invoking `context.pop()` or GoRouter stack traversal.
- **Sidebar Collapse Toggle**: Expand/collapse button to switch between 260px expanded glass sidebar and minimized icon-only rail.
- **Strict 4-Destination Navigation**: Dashboard (`/dashboard`), AI Chat (`/chat`), Terminal (`/terminal`), Settings (`/settings`).

### 3. Glassmorphic Dashboard Screen (`lib/features/dashboard/dashboard_screen.dart`)
- **Hero Card 1 (RPi5 System Hardware Telemetry)**: CPU gauge, 7,168 MB RAM ceiling gauge, SoC Temp, Tailscale latency, and ADR-002 backup status badge.
- **Hero Card 2 (Shua Governor AI Aggregator)**: Active model (`qwen2.5:1.5b`), Ollama memory allocation, intent router status, and load/evict action buttons.
- **Sub-Modules Management Matrix**: Glassmorphic cards for `shua_diary`, `shua_code_viz`, and `shua_resume` with cgroups v2 power switches (`ON/Running` vs `OFF/Sleeping`) and action buttons.

---

## Complexity Analysis (Raspberry Pi 5 Optimization)
- **Time Complexity**: 
  - Layout rendering: $\mathcal{O}(1)$ responsive widget tree rebuilding.
  - State updates: $\mathcal{O}(M)$ where $M \le 5$ is the count of supervised microservices.
- **Space Complexity**: $\mathcal{O}(1)$ memory overhead. Zero dynamic SDUI hydration allocations.

---

## Acceptance Criteria

- [x] Responsive `ShellScaffold` matches Google Stitch designs for Expanded Desktop, Minimized Rail, and Mobile Compact.
- [x] Route history controls `<` and `>` navigate backward and forward smoothly.
- [x] `DashboardScreen` renders hardware telemetry hero card, AI aggregator hero card, and microservice power toggles.
- [x] Module power toggles dispatch `wakeModule` and `sleepModule` RPCs over HBP v2.
- [x] Zero compiler warnings (`flutter analyze`).
