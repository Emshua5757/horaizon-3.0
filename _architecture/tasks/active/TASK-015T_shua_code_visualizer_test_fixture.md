# TASK-015T — Golden-Answer Test Fixture for `shua_code_visualizer`

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not Started |
| **Phase** | Phase 2 (build alongside or immediately after TASK-015A) |
| **Type** | AI-executable (fixture code can be AI-generated per §1 constraints below) |
| **Language** | Rust (test harness), Rust/Dart/Go/Python/TS (fixture code) |
| **Target** | `shua_modules/shua_code_visualizer/test_fixtures/golden_repo/` |
| **Blocks** | None — but should exist before TASK-015A is marked "done," not after |
| **Prerequisites** | TASK-015A modules implemented enough to run against fixture files (can develop in parallel — write fixtures + expected answers first, then use them as the acceptance test while building 015A) |

---

## Purpose

A small, hand-designed multi-language codebase where every "interesting" answer is known in advance: which function is called the most, which one is dead, which one is a god-function, which pair of structs has drifted across the HBP boundary. Every 015A tool that has real logic (not just AST reshaping) gets checked against this fixture instead of eyeballed against your real repo.

---

## 1. Fixture Design Constraints (read this before generating fixture code, AI or otherwise)

- [ ] 1.1 Every planted "answer" must be countable by a human in under a minute just by reading the file — no clever indirection, no macro-generated calls, no dynamic dispatch that obscures the call graph. The fixture's job is to be unambiguous, not realistic.
- [ ] 1.2 Name things so the intent is obvious in the code itself (e.g. `fn deliberately_unused_helper()`, `fn god_function_six_params(...)`) — makes it easy to verify by inspection that the fixture matches `expected_answers.toml`, and easy to re-verify after any fixture edit.
- [ ] 1.3 Keep total fixture size small (aim for <300 lines across all languages combined) — this is a correctness corpus, not a performance corpus. Performance gets tested against your real repo separately (already covered by TASK-015A §4.7).
- [ ] 1.4 Every language subfolder needs at minimum: one high-fan-in function, one dead/orphan function, one god-function (exceeds at least 2 of the 3 thresholds), one clean/unremarkable function (negative control — must NOT be flagged by anything).

---

## 2. Fixture Contents

### 2.1 Per-language basic corpus (`test_fixtures/golden_repo/{rust,dart,go,python,typescript}/`)

- [ ] `rust/orders.rs`:
  - `calculate_total(...)` — called from 5 other functions in this file → **fan_in = 5**, the deliberate "most-called" answer.
  - `apply_discount(a,b,c,d,e,f)` — 6 params, complexity ≥ 12 (nested `if`/`match`) → deliberate god-function, should trip `exceeds_param_threshold` **and** `exceeds_complexity_threshold`.
  - `deliberately_unused_helper()` — not `pub`, zero callers, not `main`, not test-annotated → deliberate `is_orphan = true`.
  - `main()` — zero callers but must **not** be flagged orphan (entrypoint allowlist test).
  - `clean_add(a: i32, b: i32) -> i32` — negative control, must trip zero flags.
- [ ] `dart/order_service.dart` — mirrors `orders.rs` structurally: one high-fan-in method, one near-duplicate of `calculate_total` (for TASK-015B's duplicate-signature clustering, if/when that's tested), one orphan, one clean control.
- [ ] `go/`, `python/`, `typescript/` — same four-symbol pattern (high-fan-in / orphan / god-function / clean control) minimally, one file each. Doesn't need the duplicate/mirror complexity Dart has — just proves each language's tree-sitter grammar extracts complexity, params, and calls correctly.

### 2.2 Cross-boundary contract pair (`test_fixtures/golden_repo/cross_boundary/`)

- [ ] `rust/graph_node.rs` — a `GraphNode` struct tagged `/// @hbp_boundary: GraphNode`, matching TASK-015A §3.3's real shape (subset is fine: id, kind, complexity, fan_in).
- [ ] `dart/graph_node_model.dart` — the paired Dart model, tagged the same way, with **one deliberately mismatched field** (e.g. `complexity: int` in Rust vs `complexity: double` in Dart, or a renamed field like `fanIn` vs the expected `fan_in`). This is the planted answer for `code_check_contract_drift`.

### 2.3 Watcher / incremental-diff scenario (`test_fixtures/golden_repo/watch_scenario/`)

- [ ] `v1/counter.rs` — baseline: two functions, `increment` and `reset`.
- [ ] `v2/counter.rs` — modified: `increment`'s signature changes (param added), a new function `decrement` is added, `reset` is deleted.
- [ ] Test harness copies `v1` into a scratch dir, runs a full scan, then overwrites with `v2`'s content and triggers the watcher, asserting the resulting `TopologyDeltaEvent` reports exactly: 1 modified (`increment`), 1 added (`decrement`), 1 removed (`reset`) — validates TASK-015A §4.4 patch logic, not just full-scan correctness.

- [ ] Reuse `orders.rs` — asserted blast radius of `calculate_total` at depth 1 must be exactly its 5 known callers, no more, no less, and must resolve by qualified path (add a second, unrelated `calculate_total` in a different module/file in the fixture specifically to catch any accidental bare-name-match regression — this directly tests the fix for the horAIzon 2.0 substring-fallback bug).

### 2.5 Unresolved callee scenario

- [ ] Method call on a variable instance (e.g. `worker.run()`) in fixture code. Test harness asserts that building the graph with dangling edges completes cleanly without panicking and drops/tags unresolved target edges without corrupting `fan_in` metrics.


---

## 3. Expected Answers File

- [ ] `test_fixtures/golden_repo/expected_answers.toml` — hand-written, not generated, and reviewed by you line-by-line since this is the ground truth everything else is graded against. One entry per planted symbol:
  ```toml
  [["rust::orders::calculate_total"]]
  fan_in = 5
  is_orphan = false
  exceeds_complexity_threshold = false

  [["rust::orders::apply_discount"]]
  exceeds_param_threshold = true
  exceeds_complexity_threshold = true

  [["rust::orders::deliberately_unused_helper"]]
  is_orphan = true

  [["rust::orders::main"]]
  is_orphan = false   # entrypoint allowlist

  [["cross_boundary::GraphNode"]]
  drift_expected = true
  drift_field = "complexity"  # or whichever field you plant as mismatched
  ```

---

## 4. Test Harness (`shua_modules/shua_code_visualizer/tests/golden_repo_test.rs`)

- [ ] 4.1 Runs a full scan against `test_fixtures/golden_repo/` and loads `expected_answers.toml`.
- [ ] 4.2 One `#[test]` per tool being validated:
  - `test_fan_in_matches_expected` — checks `calculate_total.fan_in == 5`.
  - `test_god_function_flags` — checks `apply_discount` trips both flags, `clean_add` trips none.
  - `test_dead_code_detection` — checks `deliberately_unused_helper` is flagged, `main` is not.
  - `test_blast_radius_qualified_resolution` — checks the duplicate-name trap in §2.4 resolves correctly.
  - `test_contract_drift_detected` — checks `code_check_contract_drift` flags the planted mismatch in §2.2, and does **not** false-positive on any correctly-matched fields.
  - `test_watcher_incremental_diff` — runs the §2.3 v1→v2 scenario, asserts the exact added/modified/removed set.
- [ ] 4.3 This test suite becomes a required CI gate for TASK-015A — no PR to `shua_code_visualizer` merges if `golden_repo_test.rs` fails.

---

## Acceptance Criteria

- [ ] `test_fixtures/golden_repo/` exists with all files from §2, each planted answer traceable by reading the file (per §1.1/1.2).
- [ ] `expected_answers.toml` exists and has been manually reviewed against the fixture code (not generated by the same process being tested).
- [ ] All six tests in §4.2 pass against a working TASK-015A build.
- [ ] Deliberately breaking one piece of logic (e.g. reverting qualified-path resolution to bare-name matching) causes `test_blast_radius_qualified_resolution` to fail — i.e. the test suite is verified to actually catch the regression it's designed for, not just pass trivially.
