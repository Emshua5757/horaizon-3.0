# horAIzon 3.0 — Planning Review & Suggestions

A pass through the full compiled context (architecture, contracts, specs, and all active/archived tasks) while you're still in planning mode, before more of this gets built and harder to change.

---

## 1. Concrete inconsistencies to fix now

These are small, but they're the kind of thing that's cheap to fix in a planning doc and expensive to fix once code and task branches exist.

### 1.1 Block widget count: 36 vs 37
`master_task_roadmap.md` lists TASK-019 as **"37 Native Block Widgets Library."** Every other reference — the MCP master spec's `diary_create_block` enum, TASK-012's Block Gallery screen, and TASK-019's own body — says **36**. The "37" almost certainly got copy-pasted from ADR-001's note that SDUI-4 had "a library of 37 registered primitives." Fix the roadmap line so it doesn't quietly drift back to a stale number.

### 1.2 `governor_wake_module` / `governor_sleep_module` naming is inconsistent
The `module_name` enum in the MCP spec is `["shua_diary", "shua_resume", "code_visualizer"]` — two entries use the `shua_` prefix, one doesn't. Meanwhile HBP v2's module namespaces are dot-separated (`shua.diary`, `shua.resume`, `shua.code_visualizer`) and the Governor's `config.toml` module names also use dots. You've got three different naming conventions for the same five modules across the codebase (`shua.resume` / `shua_resume` / `resume`). Pick one canonical identifier format now — I'd suggest keeping the dotted `shua.module` form as canonical since it's already load-bearing in the wire protocol, and have MCP tool schemas and any Rust/enum code reference it directly rather than re-deriving a parallel naming scheme.

### 1.3 Phase numbering disagrees across three documents
- `master_task_roadmap.md`: `shua_gym` and `shua_crypto` are **Phase 5**.
- `client_flutter_spec.md`'s GoRouter tree: `/gym` and `/crypto` are labeled **"Phase 4 stub."**
- `client_flutter_spec.md`'s Screen Inventory: Resume *and* Diary screens are both grouped under one **"Phase 3 Screens"** heading, even though the roadmap puts Resume in Phase 4 and Diary in Phase 3.

None of these are wrong exactly — they were probably written at different points as the roadmap evolved — but right now there's no single source of truth for "what phase is X in." Since `master_task_roadmap.md` is the most recently structured and most granular, I'd treat it as canonical and do a find-and-replace pass through the two spec files to match it.

### 1.4 The GoRouter tree has a structural bug, not just a phase-label bug
```
└── /gym                    ← shua_gym (Phase 4 stub — locked behind feature flag)
    └── /crypto             ← shua_crypto (Phase 4 stub — locked behind feature flag)
```
The indentation makes `/crypto` a **child route of `/gym`**, i.e. `/gym/crypto`. That's presumably not intended — crypto and gym are unrelated modules. Worth fixing before TASK-008 scaffolds the router, since a copy-pasted route tree bug like this is the kind of thing that's easy to build around wrongly and annoying to unwind later.

### 1.5 `ERR_UNAUTHORIZED` comment still says "not used in v1 scope"
Minor, but the HBP v2 spec's error code table has a leftover reference to "v1 scope" in a v2 document. Small copy-paste residue from the v1→v2 rewrite, same category as the SDUI-4 language you already cleaned out elsewhere.

---

## 2. Bigger things worth deciding before you start building

### 2.1 There is currently no authentication model at all
`shua_governor_spec.md` states it directly: *"Module auth is implicit (the Governor's process boundary is the trust boundary)."* That covers module-to-module trust on the Pi5, but it doesn't cover **client-to-Governor** trust. As written, any device that can open a WebSocket to port 7700 — over Tailscale *or* plain LAN `ws://` — can read your diary entries, trigger resume compiles, load/evict Ollama models, and SIGSTOP/SIGCONT any module. `ERR_UNAUTHORIZED` exists in the error enum but is explicitly marked unused.

This is fine for "only my laptop and my phone are on this Tailscale network," but it's worth being deliberate about rather than accidental:
- If you're relying on Tailscale ACLs as your entire security boundary, say so explicitly in the spec so it's a decision, not an omission — and note that the LAN `ws://` fallback bypasses that boundary entirely (no TLS, no Tailscale ACL).
- If you want a floor of protection, a static pre-shared token in the initial HBP handshake (checked once, cached per-connection) is cheap to add now and painful to retrofit once TASK-008-012 assume no auth step in the connection lifecycle diagram.

### 2.2 The 30-second `ERR_TIMEOUT` deadline doesn't fit AI operations
HBP v2's global timeout is 30s for any operation. But `governor.ollama.load` involves pulling/loading model weights, and `diary.jbc.prompt` / `diary_synthesize_notes` involve LLM inference on a Pi 5 — both plausibly exceed 30s, especially on first load or with a cold model. Worth either exempting AI-router operations from the global timeout or giving them an explicit longer budget in the spec, so TASK-009 (Flutter HBP client) doesn't get built assuming a uniform timeout that AI calls will routinely blow through.

### 2.3 Dream Loop resume behavior is only specified for one of four jobs
The spec describes what happens if a client connects mid-Dream-Loop for the UMAP projection step (SIGSTOP, preserve progress, SIGCONT on disconnect) but doesn't say what happens to the other three jobs (diary summary, memory compaction, code topology scan) if they're interrupted mid-run. Worth deciding now whether they're resumable, restarted from scratch, or simply skipped for that night — otherwise TASK-006's dream loop implementation will have to invent an answer on the fly.

### 2.4 No documented reconciliation strategy for the "offline shell"
`client_flutter_spec.md` states the app should launch and navigate with the Pi5 unreachable, showing a connection-error state per screen. That's good. But it's not yet specified what happens to in-flight writes — e.g. a diary block being edited when the connection drops. Given ADR-001 explicitly rejected "Offline Sync Complexity" as a non-goal, that's a reasonable simplification, but it's worth stating explicitly ("unsaved edits during a disconnect are not queued or retried — the user must reconnect before continuing to edit") so it's a documented trade-off rather than a surprise gap discovered later.

### 2.5 No testing strategy is mentioned anywhere except "N/N unit tests passing"
Every completed task reports a unit test count, which is good hygiene, but there's no mention of integration or end-to-end testing anywhere — particularly for the HBP v2 wire protocol itself (frame encode/decode round-tripping across Rust/Dart/TS/Go) or for the Flutter connection lifecycle (drop → reconnect → state restore, which is explicitly called out as a Phase 1 acceptance criterion but has no corresponding task describing how it'll be tested). Given HBP v2 is the one contract every module depends on, a small shared conformance test (encode a frame in each language, decode it in each other language) would catch drift early and is worth being an explicit task rather than an implicit assumption.

---

## 3. Task backlog gaps

- **TASK-016** (Code Topology Screen) and **TASK-021** (Resume Builder Screen) are referenced as dependents in the roadmap's "Blocks" column but have no task file yet in `_architecture/tasks/active/`. Not urgent since they're downstream, but write them before you're mid-way through TASK-015/TASK-020 and need them.
- **TASK-022** (`shua_gym`) and **TASK-023** (`shua_crypto`) are listed with `Language/Stack: TBD` — reasonable for Phase 5, but flagging so it doesn't get lost that these need a tech-stack decision before they're actionable.
- Given `shua_crypto` is a "decentralized vault & key manager," it's worth deciding early whether it has different security requirements than the rest of the system — the "no auth" model discussed in §2.1 seems like a worse fit for a crypto key vault than for a diary or resume tool. Worth a short note in that task's eventual spec about whether it inherits the same trust model or needs its own.

---

## 4. Suggested execution order (unchanged from before, restated for the doc)

With TASK-001–007 and TASK-004B complete, everything below is unblocked and can start immediately:

| Start now | Then | Waits on both |
| :--- | :--- | :--- |
| TASK-008 → 009 → 010 → 011 → 012 (Flutter chain) | — | TASK-019 waits on 010 *and* 018 |
| TASK-006B (small, unblocks 018 & 020) | TASK-018, TASK-020 | |
| TASK-015 (code visualizer) | TASK-016 (once written) | |
| TASK-017 (diary backend) | TASK-018 (needs 017 *and* 006B) | |
| TASK-013, TASK-014 (standalone, no dependents) | do opportunistically | |

Doing TASK-006B first (it's small) before diving into the Flutter chain removes a blocker for two later tasks with minimal upfront cost.

---

## 5.5 Second pass — deeper criticism by subsystem

A closer read of the full contract/task set surfaced several issues serious enough to warrant their own documents, split by subsystem so each is easy to work from independently:

- **[`horaizon_3.0_mcp_server_suggestions.md`](#)** — MCP transport mismatch, scope coverage gaps, the n8n agent's autonomy/security posture
- **[`horaizon_3.0_flutter_client_suggestions.md`](#)** — unwired dependencies, the route-tree bug in more depth, dev-cycle friction
- **[`horaizon_3.0_rust_governor_suggestions.md`](#)** — protocol contract drift, RAM budget gaps, single point of failure
- **[`horaizon_3.0_shua_modules_suggestions.md`](#)** — language sprawl, diary contract drift, media vault / backup gap

Two findings from that pass are serious enough to call out here, at the top level, rather than bury in a subsystem file:

### The `requires_auth` field is set on every single operation — but no auth exists
`hbp_diary.toml` (and the other module schema files) mark every operation `requires_auth = true`. Not "planned," not "future" — the schema-of-record for the wire protocol currently says every diary read and write requires authentication. But `shua_governor_spec.md` states outright that module auth is implicit via process boundary, and `ERR_UNAUTHORIZED` is explicitly documented as unused. **The schema and the architecture directly contradict each other on whether auth exists.** This isn't a style nit — it's the kind of contradiction that means whoever (or whatever AI agent) implements TASK-017 has to just guess which document is right, and diary data is the most personal data in the whole system. This needs an explicit decision before TASK-017 starts, not during it.

### The diary backend task doesn't implement the diary schema
`hbp_diary.toml` defines `entry.create`. TASK-017's own RPC operations table implements `entry.save` instead — a different name, and arguably different upsert semantics. TASK-017 also adds four operations that don't exist anywhere in `hbp_diary.toml` at all: `diary.search`, `diary.media.upload`, `diary.media.get`, and `diary.entry.updated`. Since `hbp_diary.toml` is supposed to be the single source of truth that `sync_contracts` code-generates Dart/TS/Rust types from (per TASK-004B), building TASK-017 as written means the implementation silently diverges from the generated contract — the generated Dart types on the Flutter side won't have request/response shapes for half of what the diary backend actually exposes. This should be fixed by updating `hbp_diary.toml` to match TASK-017's real operation list *before* TASK-017 is implemented, not after.

---

## 6. What's already in good shape

Worth naming, since a review like this can read as all-criticism: ADR-001 is a clean, well-reasoned decision record with real trade-offs acknowledged rather than hand-waved, the HBP v2 schema-modularization work (TASK-004B) is a genuinely good "protobuf-style indexing" pattern for a solo-maintained multi-language contract, and every active task file already consistently reflects the native-Flutter decision — there's no leftover 2.0/SDUI logic bleeding into the new plan. The foundation is solid; the issues above are refinements, not red flags.
