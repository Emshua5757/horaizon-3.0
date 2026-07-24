# Architectural Masterplan: Behavioral Meta-SDUI (Self-Evolutionary Engine)

This document establishes the official technical design specification and data-flow blueprints for converting the native, block-based `shua_diary` engine into an **autonomous, self-evolutionary, component-level Server-Driven UI (SDUI)** system.

---

## 1. Core Architectural Paradigm

To preserve the butter-smooth $60\text{ fps}$ local tactile physics of a mobile client while achieving the infinite flexibility of server-driven layout evolution on edge nodes (Pi 5), we reject both Page-Level SDUI and hardcoded Component-Widget SDUI. Instead, we establish a **Behavioral Meta-SDUI** paradigm:

*   **Native Flutter Orchestration Shell:** The viewport scrolling context, reordering controllers (LexoRank optimized), swipe gestures, native keyboard mechanics, and raw SQLite database syncing (Drift) remain **100% native** to eliminate UI jank.
*   **Decoupled Layout & Behavior (SDUI):** Each individual diary block renders inside a generic stateful factory container. The visual presentation and stateful capabilities are parsed recursively from a server-sent layout JSON, dynamically binding native interaction loops at runtime.

```
+─────────────────────────────────────────────────────────────+
│                  NATIVE FLUTTER VIEWPORT                    │
│                                                             │
│  [ Title Block ] ── (Native Text Field)                     │
│                                                             │
│  +───────────────────────────────────────────────────────+  │
│  │   GENERIC STATEFUL SDUI FACTORY CONTAINER             │  │
│  │                                                       │  │
│  │   [Card Node]                                         │  │
│  │     ├── [Text Node] ── (Rendered State Value)         │  │
│  │     └── [Switch Node] ── (Optimistic Local Toggle)    │  │
│  │                                                       │  │
│  │   ⚡ Active Strategies:                                 │  │
│  │     - TOGGLE_COMPLETION ──► State Key: "water_done"   │  │
│  │     - KEYBOARD_ENTER_APPEND ──► Focus Router          │  │
│  +───────────────────────────────────────────────────────+  │
│                                                             │
+─────────────────────────────────────────────────────────────+
```

---

## 2. Decoupled Factories & Dynamic Composition

The Flutter client maintains **only two generic factories**, eliminating all block-specific widget boilerplate:

### A. The Static SDUI Factory
Translates flat, presentation-only JSON nodes recursively. Handles elements with zero micro-interaction state.
*   **Mapped Elements:** Paragraphs, `heading1`–`heading4`, dividers, quotes, callouts.
*   **Performance Bounds:** $O(N)$ recursive paint pass. Compiled structures are cached in Riverpod state upon ingress to eliminate dynamic parsing overhead during rapid scrolls.

### B. The Stateful SDUI Factory
Instantiates an abstract stateful lifecycle shell that dynamically composes **Behavioral Strategies** at runtime based on the JSON specification.
*   **Mapped Elements:** Checklists, habit trackers, countdown timers, weekly review logs, workout sets, and goal blocks.
*   **Stateful Injection Strategy:** Strategies attach listeners natively (e.g. `FocusNodes`, `TextEditingControllers`) to the generic UI components at build-time.

---

## 3. Behavioral Strategy Registry

Instead of coding dedicated Dart widgets for new blocks, we code modular, reusable **Behavioral Strategies** inside the `StatefulFactory` action registry.

```
                               ┌────────────────────────────────┐
                               │   Stateful Action Registry     │
                               └────────────────┬───────────────┘
                                                │
                 ┌──────────────────────────────┼──────────────────────────────┐
                 ▼                              ▼                              ▼
    ┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
    │  KEYBOARD_ENTER_APPEND  │    │    TOGGLE_COMPLETION    │    │   FILTER_EMPTY_ITEMS    │
    ├─────────────────────────┤    ├─────────────────────────┤    ├─────────────────────────┤
    │ Captures key events.    │    │ Triggers optimistic     │    │ Listens to focus loss.  │
    │ Inserts a new visual    │    │ local checks; schedules │    │ Trims empty text nodes  │
    │ node to state array.    │    │ async SQLite commits.   │    │ to keep databases lean. │
    └─────────────────────────┘    └─────────────────────────┘    └─────────────────────────┘
```

### The Declarative JSON Contract
The server composes visual structures and behavior strings dynamically inside the block definition:

```json
{
  "type": "stateful_block",
  "properties": {
    "visuals": {
      "type": "card",
      "children": [
        {
          "type": "text",
          "properties": { "text": "Gym Routine Tracker", "style": "titleSmall" }
        },
        {
          "type": "row",
          "properties": { "mainAxisAlignment": "spaceBetween" },
          "children": [
            { "type": "text", "properties": { "text": "Squats 5x5", "style": "bodyLarge" } },
            { 
              "type": "checkbox", 
              "properties": { 
                "stateKey": "squats_completed",
                "onChanged": "TOGGLE_COMPLETION" 
              } 
            }
          ]
        }
      ]
    },
    "behaviors": [
      "TOGGLE_COMPLETION"
    ]
  }
}
```

---

## 4. The Dumb State-Broker Pattern (Data-Flow)

To ensure the client maintains zero business logic, we implement the **Dumb State-Broker** model.

### A. The Data Schema
Each block in the native SQLite table represents a single row. The state variables are stored inside a flat, unstructured JSON map column called `content`:
```json
{
  "squats_completed": true,
  "bench_completed": false,
  "volume_metric": 5000
}
```

### B. The State Bindings (Read/Write Loop)

```
        CLIENT READ LOOP                                  CLIENT WRITE LOOP
┌───────────────────────────────┐                 ┌───────────────────────────────┐
│     SQLite DB (Row State)     │                 │   User Toggles UI Checkbox    │
└──────────────┬────────────────┘                 └──────────────┬────────────────┘
               │                                                 │
               ▼                                                 ▼
┌───────────────────────────────┐                 ┌───────────────────────────────┐
│   Factory extracts stateMap   │                 │   Factory Intercepts Event    │
└──────────────┬────────────────┘                 └──────────────┬────────────────┘
               │                                                 │
               ▼                                                 ▼
┌───────────────────────────────┐                 ┌───────────────────────────────┐
│ Dynamic Property Interpolation│                 │  Clones local stateMap; sets  │
│  state[squats_completed]      │                 │  "squats_completed" = value   │
└──────────────┬────────────────┘                 └──────────────┬────────────────┘
               │                                                 │
               ▼                                                 ▼
┌───────────────────────────────┐                 ┌───────────────────────────────┐
│ Paints native Switch Widget   │                 │ Write-Back: Commit mutated    │
│  value = true                 │                 │ stateMap JSON back to SQLite  │
└───────────────────────────────┘                 └───────────────────────────────┘
```

---

## 5. DevSecOps: Automated QA Compiler Pipeline (n8n & Selenium)

Because Behavioral Meta-SDUI is highly abstract and prone to dynamic focus collisions, event races, or layout overflows during autonomous self-evolution runs, **we do not deploy newly generated layouts directly to production**. We establish an automated **QA Safety Gate**:

```
 ┌────────────────────────┐
 │   Self-Evolution AI    ├────────┐
 └────────────────────────┘        │ (Generates new block layout & behaviors)
                                   ▼
 ┌────────────────────────┐   ┌─────────┐   ┌────────────────────────┐
 │   Verified Templates   │◄──┤   n8n   ├──►│   Headless Test Node   │
 │   Production Catalog   │   │ Pipeline│   │  (Selenium / Playwright│
 └────────────────────────┘   └────┬────┘   └───────────┬────────────┘
                                   │                    │ (Runs automated test cases)
                                   │                    ▼
                                   │        ┌────────────────────────┐
                                   │        │  - Visual regression   │
                                   │        │  - VM Exception checks │
                                   └────────┤  - SQLite commit tests │
                                            └────────────────────────┘
```

1.  **Generation Ingress:** The backend self-evolution model designs a new block template.
2.  **DevOps Orchestration (n8n):** n8n intercept hooks trigger an automated integration run.
3.  **Headless Sandbox Run (Selenium/Playwright):** 
    *   Mounts the dynamic component inside a simulated viewport.
    *   Simulates rapid user actions (taps, keyboard events, text changes).
    *   Verifies **Visual Bounds** (asserts no RenderFlex or layout overflows).
    *   Verifies **VM Exception Logs** (ensures zero uncaught Dart exceptions).
    *   Verifies **Database Mutation** (asserts that state mutations successfully persist in the SQLite schema).
4.  **Signing & Sync:** If the test completes with **0 errors and 0 warnings**, the template is cryptographically signed, added to the production catalog, and synched to mobile clients.
5.  **Self-Healing Feedback Loop:** If the test fails, n8n grabs the Selenium layout screenshot and the Dart VM stack trace, feeding it back to the AI Planner as a compiler diagnostic log for autonomous self-healing.
