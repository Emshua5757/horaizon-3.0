# horAIzon 3.0 — Rust Governor (`shua_governor`) Suggestions & Criticism

Covers `hbp_v2_spec.md`, `hbp_logging_spec.md`, `shua_governor_spec.md`, `API_REFERENCE.md`, TASK-006B, and the completed TASK-003–007.

---

## 1. The `err` field's type contradicts itself across two documents

This is the most concrete bug-in-waiting in the whole plan.

`hbp_v2_spec.md` (dated 2026-07-21) defines the frame envelope's `err` field as:
```
"err": str|nil  // null on success. Error string on failure.
```
and documents "Standard Error Codes" as prefix strings like `ERR_UNKNOWN_MODULE`, `ERR_TIMEOUT`, etc.

But `API_REFERENCE.md` — the **auto-generated** contract, produced by `sync_contracts` from the TOML schemas per TASK-004B (completed 2026-07-23, two days later) — defines the same field as:
```
`8` | `err` | `HbpError?` | null on success. Structured error object on failure.
```
where `HbpError` is a struct with `code: u16`, `category: ErrorCategory`, `message: str`, `details: map<str,str>?`.

These are not compatible wire formats. A client built against the hand-written spec would try to parse `err` as an optional string; a client built against the generated reference (which reflects what the actual TOML schema — and therefore actual generated Rust/Dart/TS code — will produce) needs to parse it as an optional structured map. Since `hbp_v2_spec.md` is the document a human is most likely to read first (it's the canonical wire-protocol spec, referenced by name from three other specs), and it's now stale relative to the generated source of truth, it should be updated to match `HbpError` — including replacing the whole "Standard Error Codes (prefix string)" section with the actual `ErrorCategory` enum and `code: u16` values it now uses. Left as-is, this is exactly the kind of thing that costs an afternoon of "why is my Dart client throwing a deserialization error" debugging that has nothing to do with your actual code.

## 2. `FATAL` and `PANIC` are used as log severities but don't exist in the log level table

`hbp_logging_spec.md`'s Log Levels table defines exactly five levels: `TRACE=1, DEBUG=2, INFO=3, WARN=4, ERROR=5`. But the persistence policy section says the audit file stores *"ONLY high-severity entries (`ERROR`, `FATAL`, `PANIC`, or `TAG_IMPORTANT`/`TAG_SECURITY`)"* — referencing two severities, `FATAL` and `PANIC`, that have no corresponding integer value anywhere in the spec. Either these need to be added as levels 6 and 7 (and the `min_level: u8` semantics updated accordingly), or — more likely, since Rust's `panic!` and a genuine fatal condition are meaningfully different from a normal `ERROR` — they should be dropped from that sentence and treated as `ERROR`-level events with a `TAG_IMPORTANT` or new tag bit instead, since the tag bitmask system already exists for exactly this kind of orthogonal classification.

## 3. No accounting for total system RAM once all five modules are considered

The Ollama RAM Budget Rule is explicit and good: 4GB hard cap for Ollama models, leaving 4GB for "modules + OS" on an 8GB Pi 5. But nothing sums up what "modules" actually costs. From `config.toml`'s example `ram_limit_mb` entries: `shua_resume` 256MB + `shua_diary` 512MB + `shua_code_visualizer` 512MB = 1.28GB already committed — and that's only 3 of the 5 planned modules; `shua_gym` (MediaPipe pose streaming, which is not a lightweight workload) and `shua_crypto` aren't budgeted yet at all. Add typical Linux/systemd/Tailscale daemon overhead (realistically several hundred MB) and you're not obviously left with much headroom in that "remaining 4GB" once every module is actually running simultaneously — which is exactly the scenario the wake/sleep cgroup system exists to prevent, but there's no enforcement rule described anywhere ("Governor refuses to wake a module if it would exceed total system RAM budget"). Worth adding a global RAM ceiling check to the wake path in TASK-005/007's actual implementation, not just per-module `memory.max` limits — cgroups will stop one module from *itself* running away with RAM, but nothing currently stops five well-behaved modules plus a loaded Ollama model from collectively exceeding 8GB.

## 4. Dream Loop interruption handling is specified for one job out of four
The spec walks through exactly what happens if a client connects mid-Dream-Loop for the UMAP embedding projection step (SIGSTOP it, preserve progress, resume on disconnect) but says nothing about the other three nightly jobs — diary summary generation, memory compaction, and the code topology delta scan. If a client happens to connect while, say, memory compaction is mid-merge, is that safe to just kill/defer, or could it leave the diary DB in a partially-compacted state? This is worth resolving as part of TASK-006's implementation (or a small follow-up task) rather than being implicitly "whatever the code happens to do," since memory compaction touching the diary DB is exactly the kind of job where "we didn't think about the interrupted case" turns into corrupted data down the line.

## 5. The Governor is a hard single point of failure, by design — worth stating as an accepted trade-off, not an oversight
Every other module can be asleep, crashed, or mid-restart and the system limps on in a degraded state. The Governor cannot: it's the only thing that binds port 7700, the only WebSocket entry point, and the sole router for *every* client request including AI routing. If it crashes, the entire client app loses connectivity to everything at once — diary, resume, code visualizer, logs, all of it — until systemd's `Restart=always` brings it back. This is a completely reasonable trade-off for a solo-engineer personal system (a proper HA broker would be wild overkill here), but it's currently implicit rather than written down. I'd add one line to `shua_governor_spec.md`'s architecture section making it explicit — e.g. *"The Governor is an intentional single point of failure; `RestartSec=3s` plus a Flutter reconnect-with-backoff is considered sufficient resilience for a single-user system"* — so it reads as a decision (like ADR-001) rather than something nobody thought about.

## 6. `cgroups-rs` / direct `/sys/fs/cgroup/` writes have no fallback story for the actual dev machine
The tech stack lists `cgroups-rs` crate or direct `/sys/fs/cgroup/` writes for the cgroups v2 manager — but development happens on a Windows laptop (per `client_flutter_spec.md`'s platform targets and TASK-008's PowerShell-based setup), and cgroups v2 is a Linux-only kernel feature. TASK-005's summary does mention "cross-platform dev fallback stubs" for the `CgroupManager`, which is good — but it's only mentioned in passing in a completed-task summary, not specified anywhere as an actual behavior contract (what does `wake_module`/`sleep_module` do on the dev fallback — no-op? mock state transition? log-only?). Worth pulling that fallback behavior out into a documented contract in `shua_governor_spec.md` itself, since it affects how you'll actually be able to test TASK-006B and any future Governor work from the Windows laptop before deploying to the Pi 5.
