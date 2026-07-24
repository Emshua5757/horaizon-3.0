# horAIzon 3.0 — Flutter Client (`client_flutter`) Suggestions & Criticism

Covers `client_flutter_spec.md`, TASK-008 through TASK-012, and TASK-019.

---

## 1. Two dependencies are added with no task that ever uses them

TASK-008's `pubspec.yaml` includes:

- **`local_auth: ^2.2.0`** — biometric authentication (Face ID / Touch ID / fingerprint).
- **`multicast_dns: ^0.3.2+3`** — mDNS Pi 5 discovery on LAN.

Neither package appears again anywhere in `client_flutter_spec.md`'s design principles, screen inventory, provider registry, or connection lifecycle diagram. The connection lifecycle as documented is: load Pi5 URL from `shared_preferences` → attempt WebSocket connect → success/timeout/failure. There's no mDNS discovery step in that flow, and no lock-screen or biometric-gate step anywhere in the app.

Two possibilities, and both are worth resolving before TASK-008 ships:
- These were meant to be used and the specs just never got updated to describe how — in which case, write the missing piece (e.g. "if Pi5 URL isn't set, try mDNS discovery before falling back to manual entry" and "app requires biometric unlock on launch/resume").
- Or they were spec'd early and are no longer part of the plan — in which case, drop them from `pubspec.yaml` now. An unused biometric-auth dependency is a particularly odd thing to carry silently, since it's exactly the kind of feature people assume is active ("oh good, it's Face-ID locked") when it isn't actually wired to anything.

Given the no-auth gap discussed in the Rust Governor file, `local_auth` is actually a promising piece to *use*: a device-level app lock wouldn't fix the "no server-side auth" problem, but it would at least mean someone picking up your unlocked phone can't casually open the diary. Worth deciding deliberately rather than leaving it as a dangling import.

## 2. The GoRouter tree nests `/crypto` under `/gym`

```
└── /gym                    ← shua_gym (Phase 4 stub — locked behind feature flag)
    └── /crypto             ← shua_crypto (Phase 4 stub — locked behind feature flag)
```

As written, this makes crypto a **child route of gym** (`/gym/crypto`), which doesn't match either module's purpose — they're unrelated siblings (workout tracking vs. a key vault). This is worth catching before TASK-010 scaffolds the actual `GoRouter` config from this diagram, since a route hierarchy bug like this tends to get copy-pasted straight from documentation into code without a second look.

## 3. Phase labeling disagrees with the master roadmap in the same document set

`client_flutter_spec.md`'s route tree calls `/gym` and `/crypto` **"Phase 4"**, while `master_task_roadmap.md` puts both `shua_gym` (TASK-022) and `shua_crypto` (TASK-023) in **Phase 5**. Separately, the Screen Inventory table groups Resume screens and Diary screens together under one **"Phase 3 Screens"** heading, while the roadmap splits them — Diary is Phase 3, Resume is Phase 4. Since `client_flutter_spec.md` was likely written before the roadmap was finalized into its current phase structure, I'd treat the roadmap as canonical and do a pass to align the spec's phase labels to it.

## 4. No stated testing strategy for the one thing Phase 1 acceptance criteria actually require

The Phase 1 acceptance criteria explicitly call out: *"Connection drop → reconnect → state restores without app restart."* That's a nontrivial thing to get right — it touches `hbpClientProvider`'s reconnect-with-backoff logic, every `AsyncNotifier` that depends on a live connection, and the UI's degraded-state banners. But nothing in TASK-009 or TASK-010 describes how this gets tested — no widget test plan, no mention of a mock `HbpClient` for simulating drops in CI, nothing. Given it's called out as a hard acceptance criterion, it's worth being just as explicit about *how* you'll verify it (even if that's just "manually kill the Pi5 process mid-session and confirm the banner + reconnect") as the criterion itself is.

## 5. The "platform-adaptive layout" principle isn't backed by any breakpoint spec
Design Principle #4 says Windows gets multi-column layouts "where appropriate" and Android gets single-column with a bottom nav bar, and that GoRouter handles both identically. That's a reasonable intent, but "where appropriate" isn't a spec — there's no stated breakpoint (e.g. "multi-column above 900px logical width"), and no mention of how a single `DashboardScreen.dart` file is supposed to know it's on a 1024px Windows window vs. a phone in split-screen at 500px. Since this affects essentially every Phase 1 screen (TASK-011, TASK-012) it's worth nailing down one shared responsive-layout convention (a `LayoutBuilder`-driven breakpoint constant, most likely) in TASK-010 alongside the theme system, rather than letting each screen invent its own threshold.

## 6. `flutter_launcher_icons` + manual `windows/runner/main.cpp` edits are two different rebranding mechanisms for the same problem
TASK-008 asks you to both run a codegen tool for icons *and* hand-edit `windows/runner/main.cpp` and `Runner.rc` for the window title and executable metadata. That's fine as a one-time bootstrap step, but worth flagging because those hand-edited native files will get silently clobbered if `flutter create` or a Flutter upgrade ever regenerates the `windows/` folder — there's no note anywhere to re-apply the branding edits after a platform-folder regeneration. Worth a one-line comment in the task or a small script that reapplies the two string substitutions, so "why did the window title go back to `client_flutter`" isn't a mystery six months from now.

## 7. Riverpod provider registry doesn't mention error/loading state conventions
The provider tables list types (`AsyncNotifier<GovernorStatus>`, `StreamNotifier<List<LogEntry>>`, etc.) but nothing about a shared convention for how screens react to the error state of an `AsyncValue` — e.g. is there a shared `AsyncValueWidget`/`.when()` pattern used everywhere, or does each screen build its own loading/error UI? For a solo project this matters less for correctness and more for your own future velocity — six screens each reinventing "show a spinner, show an error card" is exactly the kind of repeated-code drift that creeps in when there's no small shared utility named up front. Worth a `shared/widgets/async_value_view.dart` convention decided in TASK-009 or TASK-011, before multiple screens have already diverged.
