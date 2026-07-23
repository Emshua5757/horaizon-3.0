# horAIzon 3.0 Workspace Rules

- **Git Branching & Merge Strategy**: Always create a git feature branch per task (`task/TASK-004-logging`). Merge completed tasks with `git merge --no-ff` to preserve branch history graph.
- **Raspberry Pi 5 Optimization**: Keep time $O(\cdot)$ and space $O(\cdot)$ minimal for Pi5. Always include Time & Space complexity analysis in technical designs and summaries.
- **Zero Warnings / Clean Code**: Zero compiler warnings, no unhandled/hanging code, no dead code unless explicitly tagged with `// TODO: ...`.
- **HBP Schema Documentation**: Always document any HBP operation/payload schema change in `_architecture/contracts/hbp/` as modular schema files. Never guess or force agents to guess schemas.
