# horAIzon 3.0 Workspace Rules

- **Git Branching & Merge Strategy**: Always create a git feature branch per task (`task/TASK-004-logging`). Merge completed tasks with `git merge --no-ff` to preserve branch history graph.
- **Raspberry Pi 5 Optimization**: Keep time $O(\cdot)$ and space $O(\cdot)$ minimal for Pi5. Always include Time & Space complexity analysis in technical designs and summaries.
- **Zero Warnings / Clean Code**: Zero compiler warnings, no unhandled/hanging code, no dead code unless explicitly tagged with `// TODO: ...`.
- **HBP Schema Documentation**: Always document any HBP operation/payload schema change in `_architecture/contracts/hbp/` as modular schema files. Never guess or force agents to guess schemas.
- **Weekly Progress Naming**: Name weekly progress files strictly by week index (`week_01_progress.md`, `week_02_progress.md`) without mid-week hardcoded dates in the filename.
- **Task Archiving Policy**: Move completed task spec files from `_architecture/tasks/active/` to `_architecture/tasks/archived/` upon task completion and mark `Status: [x] Completed`.
- **Centralized Telemetry Logging**: Always emit structured `tracing` logs (`info!`, `warn!`, `error!`) with subsystem attributes for all process state changes, RPC dispatching, and errors.
- **Minimal & Purposeful Git Commits**:
  - **Backend / `shua_governor` Changes**: Commit and push immediately when modifying `shua_governor` or backend Rust logic so Raspberry Pi 5 can instantly pull (`git pull`) and compile the latest binary via `gov`.
  - **Client / Flutter / Docs Changes**: Batch minor edits. Do NOT create frequent micro-commits for minor Dart UI or documentation tweaks; commit only at key task milestones or when explicitly requested by the user.
- **Strict HBP v2 MessagePack DTO Enforcement**: Never create ad-hoc protocols, multi-format fallback parsers, or alternative text DSLs. All RPC operations, frames, and DTO payloads across `shua_governor` and submodules MUST strictly enforce the canonical MessagePack map schema (`rmp_serde` / `msgpack_dart`) defined in `_architecture/contracts/hbp/`. Multi-format trial-and-error parsing is strictly forbidden.
- **MCP Compliance & AI-Enabled Architecture**: All AI tool operations, schemas, and resource streams across submodules MUST comply with `_architecture/contracts/mcp/mcp_master_spec.md`. Expose standardized MCP tools and resources instead of ad-hoc string bytecodes or custom text DSLs, ensuring the entire horAIzon 3.0 monorepo is fully AI-agent enabled.


