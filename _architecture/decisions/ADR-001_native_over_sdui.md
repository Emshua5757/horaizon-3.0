# ADR-001 — Native Flutter over SDUI-4

| Field | Value |
| :--- | :--- |
| **Status** | Accepted |
| **Date** | 2026-07-21 |
| **Author** | Joshua B. Ygot |
| **Supersedes** | SDUI-4 architecture (horAIzon 2.0) |

---

## Context

horAIzon 2.0 was built on SDUI-4 (Server-Driven UI 4), a zero-trust, index-based payload contract that allowed the backend to define the entire UI structure dynamically. The backend sent MessagePack-encoded "screen blueprints" which the Flutter client rendered using a library of 37 registered primitives, a StateVault, and a style resolution engine.

This was a deliberately ambitious architecture. In theory, adding a new screen meant only writing a JSON blueprint on the server — no Flutter code changes needed.

### What Actually Happened in Practice

| Problem | Impact |
| :--- | :--- |
| Every new feature required changes in 3 places: backend blueprint, hydration engine, Dart renderer | 3× the work per feature |
| Blueprint loading (`LoadAndHydrateBlueprint`) was opaque — debugging meant tracing through JSON hydration | Extremely slow debugging cycles |
| State inside SDUI-4 was index-addressed and untyped — type errors only surfaced at runtime | Fragile state management |
| Adding a new SDUI primitive required registering it in `SduiBlockRegistry`, writing a renderer, and testing all screens that used it | High coupling despite the architecture's "decoupling" goal |
| The `assembleScreen` function in `shua_resume` grew to 287 LOC / Complexity 59 | Unmaintainable god function |
| Solo engineering across 3+ modules simultaneously made the SDUI layer a constant context-switch tax | Unsustainable for one developer |

The architecture was correct for a team building a generic app shell that multiple product teams contribute screens to. **horAIzon 3.0 is not that.** It is a single-engineer, deeply personal, multi-module personal AI OS. The overhead of SDUI-4 was net negative.

---

## Decision

**horAIzon 3.0 uses native Flutter exclusively.**

- Screens are standard Dart `Widget` classes
- State is typed `AsyncNotifier` and `Notifier` classes via Riverpod
- Navigation is GoRouter with typed routes
- There is no blueprint loader, no screen assembler, no hydration engine, no `SduiBlockRegistry`
- Backend modules expose typed data DTOs over HBP v2 — they have zero UI concerns

---

## Consequences

### Positive

- **Feature velocity**: Adding a screen is a single Dart file. No server-side blueprint to write.
- **Type safety**: All state is strongly typed at compile time. Runtime type errors from index-addressed payloads are eliminated.
- **Debuggability**: Flutter DevTools works directly. Widget tree is inspectable without understanding a hydration layer.
- **Simpler backends**: Every backend module (`shua_resume`, `shua_diary`, etc.) loses its entire `sdui/` directory. They become clean data APIs.
- **AI-friendliness**: `shua_code_visualizer` can generate accurate AST topology maps of Dart widget trees. SDUI-4's dynamic dispatch made static analysis nearly impossible.
- **Reduced cognitive load**: As a solo engineer, the mental model is now: "widget calls provider calls API." Three hops, all typed.

### Negative / Trade-offs

- **No dynamic screen injection**: A new screen requires a Flutter app update. In 2.0, screens could be added server-side with zero client deploy. This capability is surrendered.
  - *Accepted trade-off*: horAIzon 3.0 is not a public app store product. App updates are self-deployed. The cost of a Flutter rebuild is negligible.
- **More Dart code**: UI logic lives in the client, not the server. Each module requires a corresponding Flutter screen.
  - *Accepted trade-off*: This is normal. Every non-SDUI app works this way.

---

## What Is Kept From SDUI-4

The following SDUI-4 concepts survive, reframed:

| SDUI-4 Concept | v3.0 Equivalent |
| :--- | :--- |
| `SduiBlockRegistry` | Riverpod provider registry (typed, not dynamic) |
| `StateVault` | Riverpod `StateProvider` / `AsyncNotifier` per module |
| MessagePack wire format | HBP v2 (kept — binary efficiency over Tailscale is still valuable) |
| WebSocket transport | Kept in HBP v2 — bidirectional RPC |
| Module App Store / `module_registry.json` | `shua_governor` process registry (Rust, not JSON) |

---

## Alternatives Considered

| Alternative | Why Rejected |
| :--- | :--- |
| Keep SDUI-4, simplify it | The fundamental problem is the coupling of UI layout to server payloads. Simplifying SDUI-4 is still SDUI. |
| React Native / Expo | Abandons the Dart/Flutter investment from 2.0. No benefit. |
| Full Web App (Next.js) | Loses native platform integration, MediaPipe pose streaming, platform channels for future MCU work. |
| Flutter + Flame (game engine) | Overkill. Diary and resume are not games. |

---

## References

- `_architecture/reference/client_flutter.md` — 2.0 Flutter topology export
- `_architecture/reference/horAIzon_2_0_full_topology.md` — Full 2.0 codebase map
- `_architecture/contracts/hbp/hbp_v2_spec.md` — HBP v2 wire protocol
