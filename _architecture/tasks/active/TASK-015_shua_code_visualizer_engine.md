# TASK-015 — `shua_code_visualizer` Rust AST & Topology Engine

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_modules/shua_code_visualizer/` |
| **Blocks** | TASK-016 |
| **Prerequisites** | TASK-004 (HBP v2 Broker) |

---

## Overview

Build the `shua_code_visualizer` Rust microservice that parses local codebase ASTs using Tree-sitter, calculates cyclomatic complexity, resolves call graphs and side effects, and registers with `shua_governor` via HBP v2.

---

## Key Modules & Specifications

1. **Multi-Language AST Extractor (`src/parser/registry/`)**:
   - Extract symbols, imports, type references, and call sites for Rust, Go, Dart, TypeScript, and Python.
   - Compute cyclomatic complexity per function.
   - Infer side effects (IO, state mutation, network).
2. **Graph Resolution & SDG Engine (`src/parser/scanner.rs`)**:
   - Resolve symbol dependency graphs, entry points, and cyclic dependencies.
3. **HBP v2 Integration**:
   - Connect to `shua_governor` on WebSocket port 7700.
   - Expose `code_visualizer.scan` and `code_visualizer.get_graph` RPC operations.
