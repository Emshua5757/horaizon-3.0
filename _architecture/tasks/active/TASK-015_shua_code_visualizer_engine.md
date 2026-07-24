# TASK-015 — `shua_code_visualizer` Rust AST, Topology & MCP Server Engine

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_modules/shua_code_visualizer/` |
| **Blocks** | TASK-016 |
| **Prerequisites** | TASK-004 (HBP v2 Broker), `_architecture/contracts/mcp/mcp_master_spec.md` |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md` |

---

## Architectural Directives & MCP Contract Compliance

> [!IMPORTANT]
> **MCP Contract Compliance**: `shua_code_visualizer` implements the `code_*` tools and `code://` resources specified in `_architecture/contracts/mcp/mcp_master_spec.md`:
> - Tools: `code_parse_ast`, `code_render_graph`.
> - Resources: `code://graph/{module}`.
> - Connects to `shua_governor` via HBP v2 and registers its MCP tools with the Governor MCP Aggregator (`governor.mcp.register`).

---

## Key Modules & Specifications

1. **Multi-Language AST Extractor (`src/parser/registry/`)**:
   - Extract symbols, imports, type references, and call sites for Rust, Go, Dart, TypeScript, and Python using Tree-sitter.
   - Compute cyclomatic complexity per function.
   - Infer side effects (IO, state mutation, network).
2. **Graph Resolution & SDG Engine (`src/parser/scanner.rs`)**:
   - Resolve symbol dependency hypergraphs, entry points, and cyclic dependencies.
3. **MCP Tool Server (`src/mcp/server.rs`)**:
   - Exposes `code_parse_ast` and `code_render_graph` tools per `mcp_master_spec.md`.
   - Exposes `code://graph/{module}` resource stream.
4. **HBP v2 Integration**:
   - Connects to `shua_governor` on WebSocket port 7700.
   - Registers MCP tools upon boot.
