# horAIzon 3.0 Workspace Rules

- **Git Branching & Merge Strategy**: Always create a git feature branch per task (`task/TASK-004-logging`). Merge completed tasks with `git merge --no-ff` to preserve branch history graph.
- **Raspberry Pi 5 Optimization**: Keep time $O(\cdot)$ and space $O(\cdot)$ minimal for Pi5. Always include Time & Space complexity analysis in technical designs and summaries.
- **Zero Warnings / Clean Code**: Zero compiler warnings, no unhandled/hanging code, no dead code unless explicitly tagged with `// TODO: ...`.
- **HBP Schema Documentation**: Always document any HBP operation/payload schema change in `_architecture/contracts/hbp/` as modular schema files. Never guess or force agents to guess schemas.
- **Weekly Progress Naming**: Name weekly progress files strictly by week index (`week_01_progress.md`, `week_02_progress.md`) without mid-week hardcoded dates in the filename.
- **Task Archiving Policy**: Move completed task spec files from `_architecture/tasks/active/` to `_architecture/tasks/archived/` upon task completion and mark `Status: [x] Completed`.
- **Centralized Telemetry Logging**: Always emit structured `tracing` logs (`info!`, `warn!`, `error!`) with subsystem attributes for all process state changes, RPC dispatching, and errors.
- **Minimal & Purposeful Git Commits**: Do NOT create frequent micro-commits during planning, drafting, or minor edits. Combine incremental edits and commit only at major task milestones, task completion/merge, or when explicitly requested by the user to avoid cluttering GitHub profile activity.

