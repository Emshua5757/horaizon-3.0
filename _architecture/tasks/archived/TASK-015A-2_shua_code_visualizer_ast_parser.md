# TASK-015A-2 — `shua_code_visualizer` Multi-Language AST Parser & Symbol Extractor

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/src/parser/` |
| **Parent Task** | TASK-015A (`shua_code_visualizer` Core Engine) |
| **Prerequisites** | TASK-015A-1 (Pre-flight Contracts & Wire DTO Foundation) |

---

## Key Subtasks

### 1. Tree-sitter Grammar Wiring & Extractor Architecture
- [x] 1.1 Add `tree-sitter`, `tree-sitter-rust`, `tree-sitter-dart-orchard`, `tree-sitter-go`, `tree-sitter-python`, `tree-sitter-typescript` to `Cargo.toml`.
- [x] 1.2 Implement `LanguageExtractor` trait in `src/parser/extractor.rs`.
- [x] 1.3 Implement top-level `parse_file(...)` dispatcher routing by file extension / language enum.

### 2. Multi-Language Extractor Registries
- [x] 2.1 `src/parser/registry/rust.rs`: Parse Rust functions, structs, enums, traits, type aliases (`type`), macros (`macro_rules!`), module qualified path resolution (`core::service::Worker::run`), `///` and `/** */` doc intent, side-effect inference, cyclomatic complexity, `#[test]` attribute detection, and call/import edges (`Relation::Calls`, `Relation::Imports`).
- [x] 2.2 `src/parser/registry/dart.rs`: Parse Dart classes, mixins, extensions, methods, constructors, doc comments, parameters, return types, complexity, and call/import edges.
- [x] 2.3 `src/parser/registry/go.rs`: Parse Go functions, methods, structs, interfaces, package qualified paths (`Server.Start`), Go doc comments, parameters, return types, switch-case complexity (`expression_case`), and call/import edges.
- [x] 2.4 `src/parser/registry/python.rs`: Parse Python functions (`def`, `async def`), classes, docstrings (`"""..."""`), parameters with type hints, `elif` complexity (`elif_clause`), and call/import edges.
- [x] 2.5 `src/parser/registry/typescript.rs`: Parse TypeScript functions, methods, classes, interfaces, type aliases, enums, JSDoc (`/** ... */`), parameters, return types, and call/import edges.

---

## Acceptance Criteria
- [x] Tree-sitter correctly parses Rust, Dart, Go, Python, and TypeScript code snippets.
- [x] Qualified paths (`Module::Symbol`, `Class.method`) are assigned to all extracted symbols and call edge callers.
- [x] Cyclomatic complexity, LOC count, doc intent, parameters (`ParamDto`), `is_public`, `is_test`, and call/import edges (`ExtractedEdge`) are extracted across all 5 languages.
- [x] `cargo check` and `cargo test` pass with zero compiler warnings (8/8 unit tests passing).
