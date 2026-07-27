# horAIzon 3.0 — Master UI Screens Specification & Google Stitch Prompt

> **Purpose:** This document is the single source of truth for all visual designs, component structures, screen state variations, and user flows in the horAIzon 3.0 Flutter client. It is crafted to serve as a comprehensive, credit-efficient prompt for Google Stitch mockup generation.

---

## 🏗️ Architectural Foundations & ADR Directives

1. **ADR-001 Compliance (Native Flutter over SDUI-4)**:
   - 100% native Flutter Dart widgets (`GoRouter`, Riverpod `AsyncNotifier`).
   - Zero dynamic server-driven UI hydration or JSON blueprint engines.
   - Microservices (`shua_diary`, `shua_resume`, `shua_code_viz`) expose clean typed DTO APIs over MessagePack / HBP v2 WebSocket.

2. **ADR-002 Compliance (Disaster Recovery & Nightly Dream Loop Backup)**:
   - Automated 02:00 AM Dream Loop maintenance & 03:00 AM atomic SQLite `VACUUM INTO` backup snapshot status (`shua_diary.db`, `activity.db`, `shua_resume.db`, `shua_crypto.db`, Zstd archive over Tailscale).

3. **Raspberry Pi 5 Edge Optimization**:
   - Hardware-aware UI showing real-time CPU (4× ARM Cortex-A76), RAM Ceiling (7,168 MB active max), SoC Temperature, and Tailscale VPN latency.
   - Visual `cgroups v2` power switches (`ON / Running` vs `OFF / Sleeping - SIGSTOP Frozen`) for all supervised sub-modules.

---

## 🎨 Global Aesthetics & Strict Navigation Consistency

- **Theme Baseline:** Clean, modern, minimalist workspace with dark glassmorphism.
- **Surface Elevation & Effects:**
  - Background: Deep Charcoal / Midnight Space Navy (`#090D16` / `#0F172A`).
  - Cards: Translucent dark glass (`#1E293B` at 65% opacity, `16px` backdrop blur, 1px subtle border `#334155` at 50%).
  - Active Accents: Soft Teal (`#2DD4BF`) for online states, Indigo (`#6366F1`) for primary actions, Amber (`#F59E0B`) for warnings/sleeping modules, Coral Red (`#EF4444`) for errors/offline alerts.
- **Typography:** Inter / Roboto. Clean hierarchy, high legibility.
- **STRICT Left Sidebar Navigation (Identical Across ALL Screens):**
  - **Top:** Logo `horAIzon 3.0`, User Avatar (`Joshua B. Ygot`), and Green LED badge (`RPi5 Connected: 100.67.11.0:7700`).
  - **Navigation Scope (Strictly 4 Items):**
    1. 📊 **Dashboard** (`/dashboard`)
    2. 🧠 **AI Models** (`/models` or `/chat`)
    3. 💻 **Terminal** (`/terminal`)
    4. ⚙️ **Settings** (`/settings`)
  - **NO extra vertical sub-nav bars, NO extra secondary sidebars on inner pages!**

---

## 0. Splash & Offline Connection Screen

**Purpose:** Application initialization, HBP v2 handshake, and offline fallback when disconnected from Raspberry Pi 5 (`horaizon-pi5` / `100.67.11.0:7700`).

### State A: Connecting & Handshake
- Central glowing `horAIzon 3.0` logo with subtle pulse effect.
- Status Badge: *"Establishing HBP v2 WebSocket link to Raspberry Pi 5 (100.67.11.0:7700)..."* with linear progress glow.

### State B: Disconnected / Offline Alert
- **Header:** Coral Red warning badge: *"Disconnected from RPi5 Orchestrator"*.
- **Diagnostic Glass Card:**
  - **Target Node:** `horaizon-pi5` (`100.67.11.0:7700`) — `Unreachable`
  - **Tailscale Mesh:** WireGuard VPN Ping Fail
  - **Pi 2 Relay Watchdog:** Soft SSH reset pending / Out-of-band hardware relay ready
- **User Controls:**
  - `Retry Connection` primary button (with 10s auto-reconnect backoff timer).
  - `Launch Local Demo Mode` secondary outline button (allows inspecting offline local features).

---

## 1. Global Navigation Shell

**Purpose:** Persistent responsive shell (`NavigationRail` on Desktop/Tablet width ≥ 640px, `NavigationBar` on Mobile).

### Visual Layout:
- **Header / Top Section:**
  - User Avatar (`Joshua B. Ygot`).
  - Status LED: Glowing Green (RPi5 Connected) or Flashing Red (Disconnected).
- **Destinations (4 Scope Limit):**
  1. 📊 **Dashboard** (`/dashboard`) — Hub, hardware metrics, AI aggregator, module launchers.
  2. 🧠 **AI Models** (`/models` or `/chat`) — Governor AI Intent Router & integrated MCP tool suite.
  3. 💻 **Terminal** (`/terminal`) — Multi-tab console shell & log stream.
  4. ⚙️ **Settings** (`/settings`) — ThemeCompiler picker, HBP config, Biometric auth.
- **Footer:**
  - Governor Uptime ticker (e.g. `Uptime: 14d 06h 22m`).

---

## 2. Dashboard Screen (The Hub)

**Purpose:** Central control launchpad and real-time hardware/software telemetry overview.

### A. Hero Section (2 Main Hero Cards)

1. **Hero Card 1: Raspberry Pi 5 System Hardware & Telemetry**
   - **Live Gauges & Metrics:**
     - **CPU Load:** 4-Core ARM Cortex-A76 gauge (%).
     - **RAM Ceiling:** Memory gauge displaying active RSS vs 7,168 MB System Ceiling.
     - **SoC Temperature:** Thermal gauge (e.g. `41.8 °C`).
     - **Tailscale Ping:** Latency RTT (e.g. `14 ms`).
     - **ADR-002 Backup Badge:** *"Last Backup: 03:00 AM (Zstd Encrypted Snapshot Synced)"*.

2. **Hero Card 2: Shua Governor AI Aggregator & Model Lifecycle**
   - **Metrics & Controls:**
     - **Loaded Model:** Badge showing active model (`qwen2.5:1.5b` on Pi 5 or Heavy Offload on MSI Laptop GTX 1650).
     - **Ollama Memory:** VRAM/RAM allocation gauge (e.g., `1,840 MB`).
     - **AI Intent Router:** Live status badge (`Active - Routing Prompts`).
     - **Action Buttons:** `Load Model`, `Evict`, `Switch to Heavy Laptop Offload`.

### B. Sub-Modules Management Grid (Cards with cgroups v2 Power Toggles)

Each card controls a supervised microservice process via Linux `cgroups v2` (`SIGSTOP` / `SIGCONT`):

1. **`shua_diary` Card (Personal Diary & Media Vault)**
   - **Power Switch:** `ON (Running)` / `OFF (Sleeping - SIGSTOP)`
   - **Metrics:** Memory footprint (MB), total entries, Media Vault storage usage.
   - **Button:** `Open Diary` -> routes to `/diary`.

2. **`shua_code_viz` Card (Codebase Visualizer & AST Topology)**
   - **Power Switch:** `ON (Running)` / `OFF (Sleeping - SIGSTOP)`
   - **Metrics:** Parsed AST nodes, cyclomatic complexity index, watcher state.
   - **Button:** `Open Topology` -> routes to `/code/topology`.

3. **`shua_resume` Card (Dynamic Resume Matrix & Typst Compiler)**
   - **Power Switch:** `ON (Running)` / `OFF (Sleeping - SIGSTOP)`
   - **Metrics:** Matrix record count, last compiled PDF exhibit date.
   - **Button:** `Open Resume Builder` -> routes to `/resume/editor`.

4. **`shua_governor` Operations Card (Telemetry & System Logs)**
   - **Power Switch:** `Always-On (Spine Process)`
   - **Metrics:** HBP v2 WebSocket frame rate, subscriber count, log buffer size.
   - **Button:** `View Telemetry` -> routes to `/governor/status`.

---

## 3. Sub-Module Detailed Screens & Launchpad Views

### 3.1 `shua_diary` Screen & Native Block Gallery (`/diary`)
- **Left Pane (Entry List):** Search bar, entry timeline list, mood filter pills, and annual activity heatmap row.
- **Main Pane (Block Editor):** Vertical reorderable list rendering native block widgets (`DiaryMarkdownBlock`, `DiaryCodeBlock`, `DiaryImageBlock`, `DiaryAudioBlock`, `DiaryChartBlock`).
- **Floating Action / Toolbar:** `+ Add Block` button opens the **Block Picker BottomSheet Gallery**:
  - Displays native block types in a `GridView` with category tabs (`Text & Input`, `Layout`, `Controls`, `Media`, `Data & Charts`, `Misc`).
- **Right Drawer:** AI Assistant drawer for entry summarization and block mutations (JBC engine).

### 3.2 Governor Operations & Telemetry View (`/governor/status`)
- **3-Node Topology Canvas:** Diagram showing real-time links between MSI Laptop (Heavy LLM), Raspberry Pi 5 (Governor), and Moto G84 (Mobile Client).
- **Live Telemetry Stream:** Terminal window streaming Rust `tracing` logs from `activity.db` & `important.log` with filter chips (`hbp`, `cgroups`, `ollama`, `dream_loop`) and level toggles (`INFO`, `WARN`, `ERROR`).
- **ADR-002 Disaster Recovery Panel:** Last snapshot timestamp, SQLite `VACUUM INTO` status, and manual `Trigger Nightly Backup` button.

### 3.3 `shua_code_viz` Screen (`/code/topology`)
- **Interactive Node Canvas:** Pan/zoom graph displaying source code functions, classes, and caller edges.
- **Color Coding:** Cyclomatic complexity (Green < 5, Amber 5–10, Red > 10).
- **Symbol Inspector Drawer:** Displays symbol signature, side-effect flags (IO, network, state mutation), caller references, and file line number.

### 3.4 `shua_resume` Builder Screen (`/resume/editor`)
- **Matrix Editor Tabs:** Forms for Experience, Projects, Skills, Education.
- **Compiler & Tailor Panel:** Job Description text input box, Jaccard keyword score meter (%), Typst template picker (`default`, `modern`, `minimalist`), and `Compile PDF` button.
- **Live PDF Preview Drawer:** Real-time PDF exhibit renderer with `Download PDF` and `Share` actions.

---

## 4. AI Chat Screen (`/chat`)

**Purpose:** Primary conversation & agent pairing UI powered by `shua_governor` AI Intent Router and local/cloud MCP servers.

### Visual Layout:
- **Header:**
  - Active Model badge (`qwen2.5:1.5b` or Laptop Offload).
  - Context Window token budget gauge (`2,048 / 8,192 tokens`).
  - MCP Server Badges: `StitchMCP`, `DartMCP`, `Local Filesystem`.
- **Chat Body:**
  - User messages: Right-aligned indigo glass cards.
  - AI responses: Left-aligned dark slate cards.
  - Code Snippets: Syntax highlighted with "Copy Code" & "Run in Terminal" actions.
  - Tool Cards: Expandable badges showing executed MCP tool calls and returned JSON payloads.
- **Input Bar:** Multiline text field, attachment button (files/code), and Send button displaying token throughput (e.g. `34.5 tok/s`).

---

## 5. Terminal Screen (`/terminal`)

**Purpose:** Multi-session embedded terminal console.

### Visual Layout:
- **Top Tab Bar:** `Session 1: RPi5 SSH (100.67.11.0)`, `Session 2: Local Shell`, `Session 3: Governor Log Stream`.
- **Console Body:** Monospaced font (Fira Code / JetBrains Mono), pitch black background (`#000000`), full 256-color ANSI rendering, and active blinking block cursor.

---

## 6. Settings Screen (`/settings`)

**Purpose:** Single unified settings canvas (NO secondary vertical navigation sidebar).

### Visual Layout:
- **Main Left Sidebar:** Standard persistent navigation sidebar (**Dashboard**, **AI Chat**, **Terminal**, **Settings**).
- **Header:** "Settings & ThemeCompiler" title with a "Save Configuration" primary button.
- **Top Horizontal Segmented Tab Bar:**
  - `Appearance & Themes` (Selected) | `HBP v2 Connection` | `Security & Biometrics` | `AI Engine & RAM`
- **Main Glassmorphic Settings Cards (Single Stacked Container):**
  - **Section 1: ThemeCompiler Presets**
    - 4 theme cards: **Deep Space Navy** (Active Cyan glow), **Dark Slate**, **Cyber Amber**, **Pure OLED Black**.
  - **Section 2: HCT Material 3 Color Pickers**
    - Swatches for Primary Seed (`#00E5FF`), Secondary Seed (`#6366F1`), and Accent (`#00C853`).
  - **Section 3: Glassmorphism Visual Sliders**
    - Card Backdrop Blur slider (`16px`) and Border Opacity slider (`40%`).
  - **Section 4: System Connection & Host Summary**
    - Target: `ws://100.67.11.0:7700 (RPi5 Tailscale)` with Auto-Reconnect enabled.
