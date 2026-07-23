---
trigger: always_on
description: horAIzon 3.0 Mandatory Engineering Ruleset
---

# horAIzon 3.0 Workspace Ruleset

## 1. Git Branching & Merge Strategy
- **Task Feature Branches**: Always create a dedicated git branch for every task before making changes (e.g. `feature/task-004-logging` or `task/TASK-004-logging`).
- **Explicit Merge Commits (`--no-ff`)**: Upon completing a major task, merge the feature branch into the main branch using `--no-ff` (`git merge --no-ff <branch-name>`). Never use fast-forward merges, ensuring complete version topology and historical visualization for repo history animators.

## 2. Raspberry Pi 5 Performance & Resource Optimization
- **Hardware Constraints**: All code must be optimized for execution on Raspberry Pi 5 (8GB RAM, ARM Cortex-A76).
- **Complexity Analysis**: Explicitly state Time Complexity $O(\dots)$ and Space Complexity $O(\dots)$ in implementation plans, key algorithms, and task summaries.
- **Resource Management**: Prefer zero-allocation parsing, bounded channels/buffers, and minimal heap allocations.

## 3. Zero Warnings & Clean Code Policy
- **Zero Warnings**: Code must build cleanly with zero compiler warnings (`cargo check`, `cargo build`, linter).
- **No Dead / Hanging Code**: All unused code, unhandled futures, or obsolete placeholders must be cleaned up unless explicitly marked with `// TODO: ...` or `#[allow(dead_code)]` with documented justification for future tasks.

## 4. HBP Schema Documentation & Modularization
- **Living Contract Specs**: Whenever adding or modifying an HBP operation, DTO, or payload schema, document it immediately in `_architecture/contracts/hbp/`.
- **Modularized Schema Files**: Keep HBP specifications organized in dedicated domain-specific files under `_architecture/contracts/hbp/` (e.g. `hbp_v2_spec.md`, `hbp_logging_spec.md`, `hbp_governor_ops.md`) so AI agents and developers can reference precise schemas without inferring or guessing.
