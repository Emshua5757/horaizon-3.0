# horAIzon 3.0 — MCP Server Setup: Suggestions & Criticism

Covers `mcp_master_spec.md`, TASK-006B (Governor MCP Router), and TASK-013 (n8n/Ollama/RAG agent infrastructure).

---

## 1. The transport layer is underspecified and possibly contradictory

`mcp_master_spec.md` states the protocol is **"Model Context Protocol (JSON-RPC 2.0 over HBP v2 WebSocket / Stdio)."** That sentence is doing a lot of unexamined work:

- Real MCP is JSON-RPC 2.0 — a text-based, human-readable protocol.
- HBP v2 is explicitly MessagePack — a binary format, chosen specifically (per the HBP v2 spec) *because* it avoids text/JSON overhead.
- Putting "JSON-RPC 2.0 over HBP v2 WebSocket" together means one of two things is true, and the spec doesn't say which:
  1. MCP JSON-RPC messages get serialized to a string and stuffed into HBP v2's `p` (payload) field as `bytes` — in which case you've got JSON *inside* MessagePack, which defeats most of the binary-efficiency argument for the tool-calling path specifically, and every module now needs both an HBP codec *and* a JSON-RPC codec.
  2. Or the intent is that MCP tool calls never actually go over HBP v2 at all, and "HBP v2 WebSocket" in that sentence is describing something else (maybe just that the *same* WebSocket connection carries both, multiplexed by frame type) — which is plausible but isn't written down anywhere.

Before TASK-006B is implemented, this needs one clarifying paragraph in `mcp_master_spec.md`: what bytes actually go over the wire for a tool call, end to end, from Ollama's tool-call output to the module executing it and returning a result. Right now that's assumed, not specified — and it's exactly the kind of ambiguity where whichever way TASK-006B happens to be implemented becomes the de facto spec, discovered by whoever writes TASK-015/017/020 second.

## 2. Module naming has three different conventions across MCP docs alone

Within just the MCP spec and its dependent tasks:
- `mcp_master_spec.md`'s "Subsystem Targets" list: `shua_governor`, `shua_diary`, **`code_visualizer`**, `shua_resume` — three have the `shua_` prefix, one doesn't.
- The MCP tool prefixes are `governor_*`, `diary_*`, `code_*`, `resume_*` — note `code_*`, not `code_visualizer_*` or `codeviz_*`.
- TASK-015 (the module that actually implements these tools) targets folder `shua_modules/shua_code_visualizer/` and connects over HBP module namespace `shua.code_visualizer`.
- The Governor's `governor_wake_module`/`governor_sleep_module` MCP tools use a `module_name` enum of `["shua_diary", "shua_resume", "code_visualizer"]` — a *fourth* variant, missing the `shua_` prefix that its two siblings have.

None of this breaks anything by itself, but it means there is no single string you can use to identify "the code visualizer module" across the MCP layer, the HBP layer, and the process registry — a human (or an AI agent implementing a task from these docs) has to remember which naming convention applies in which file. Worth fixing with a single canonical identifier — I'd suggest the dotted `shua.code_visualizer` form, since it's already load-bearing in the wire protocol — and updating the MCP docs and enums to reference it directly rather than re-deriving parallel names.

## 3. Scope coverage doesn't include two modules already on the roadmap

`mcp_master_spec.md`'s architectural principle #2 defines exactly four scopes: `governor`, `diary`, `code`, `resume`. TASK-006B's scope filter (`get_tools_for_scope`) is built around those same four. But `shua_gym` and `shua_crypto` are both real modules in `master_task_roadmap.md` (Phase 5) and both are in the HBP v2 module namespace list. If either of those modules is ever supposed to get AI tool-calling access (a gym module giving form feedback via Ollama seems like an obvious future ask), the scope filter as currently scoped will need to be extended — worth deciding now whether the 4-scope model is deliberately fixed forever (in which case say so) or whether it should be built as an open-ended registry from day one so TASK-006B doesn't need a breaking rework in Phase 5.

## 4. One-model-at-a-time creates an implicit MCP concurrency ceiling worth naming explicitly

The Governor enforces strict one-Ollama-model-at-a-time with `keep_alive: 0` eviction. That's a sound RAM-budget decision on its own. But it also means: if the Flutter client is mid-conversation with the `diary` scope (model loaded, context primed) and you ask the code visualizer something in the `code` scope, the diary session's model gets evicted to make room. That's probably fine for a single-user personal system, but it's a real UX consequence of the architecture that isn't written down anywhere — worth a line in `mcp_master_spec.md` or the AI Router docs saying explicitly "switching scope mid-session evicts and reloads; expect a multi-second latency hit," so it's a documented trade-off and not a surprise the first time it happens.

## 5. TASK-013's n8n agent stack has real security and safety gaps for something with write access to your codebase

This is the biggest one in this file. TASK-013 builds a fully autonomous loop: a Planner agent drafts new task files, a Reviewer agent scores them, approved-and-human-moved tasks get picked up by an **Executor** that runs `aider` + local Ollama and **writes and commits code changes to your actual repository**, triggered automatically after 15 minutes of idle time.

A few concrete issues:

- **The n8n container ships with a hardcoded, weak, checked-into-a-file credential**: `N8N_BASIC_AUTH_USER=shua` / `N8N_BASIC_AUTH_PASSWORD=horaizon3`. Even for a local-only tool, this is a plaintext secret in a file that's presumably tracked in the same repo the agent has write access to. At minimum, move it to an untracked `.env` file excluded via `.gitignore`, and use a real generated password — the fact that it's "just local" doesn't matter much once the same Tailscale network has your phone, laptop, and Pi 5 all reachable on it (see the auth discussion in the Rust Governor file — this stack shares that same "network boundary is the only boundary" assumption).
- **The entire repo is mounted read-write into the n8n container** (`c:/horaizon-3.0:/workspace`). Combined with the executor's ability to run `aider` and commit, this means a workflow bug, a bad prompt, or a compromised n8n community node has write access to everything — not just the task files it's supposed to touch.
- **No branch isolation is specified for autonomous commits.** Every other task in this codebase follows a `task/TASK-XXX-description` branch pattern merged `--no-ff` into `main` — a human-reviewable trail. TASK-013 doesn't say whether the Executor follows that same discipline or commits straight to `main`. Given this is the one part of the system that runs unsupervised, it's the part that most needs a hard rule like "Executor always works on a fresh branch per task, never merges automatically, opens a diff for you to review before merge" — otherwise the first bad autonomous run could be a same-night surprise waiting for you in the morning.
- **The human-approval gate is at the "propose a task" stage, not the "make this specific code change" stage.** You approve *that a task should be attempted*, but the Reviewer agent — not you — is the only thing standing between an approved task description and code being committed. Worth deciding whether that's the intended level of trust, especially early on before you've seen how good the Planner/Reviewer pair actually is in practice.

None of this means don't build TASK-013 — the RAG-planner-reviewer-executor pattern is a genuinely good idea for solo-dev velocity. But given it's the one part of the system designed to act without you in the loop, it's worth being stricter about its blast radius than the rest of the plan currently is.
