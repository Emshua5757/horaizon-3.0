# TASK-006D — Fix JOSH Agent Loop, Eviction Race & Thinking Model Pipeline (Qwen 3.5 / DeepSeek R1)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] In Progress (Awaiting User Manual Verification) |
| **Phase** | Phase 1 / Phase 2 Follow-up |
| **Type** | AI-executable |
| **Language** | Rust / Dart (Flutter) |
| **Target** | `shua_governor/src/ollama/lifecycle.rs`, `shua_governor/src/ollama/client.rs`, `shua_governor/src/ai_router/agent_loop.rs`, `shua_governor/src/ollama/model_registry.rs`, `client_flutter/lib/features/chat/` |
| **Blocks** | Nothing |
| **Prerequisites** | TASK-006C (Governor Ollama Logging & Runtime Hardening) |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/contracts/hbp/` |

---

## Architecture Context & Hardware Optimization (Raspberry Pi 5)

> [!IMPORTANT]
> **Raspberry Pi 5 Resource & Concurrency Execution Constraints**:
> - **Hardware**: Raspberry Pi 5 (8GB RAM, ARM Cortex-A76) + Windows Offload Host.
> - **Eviction Concurrency Race**: `OllamaLifecycle::load()` previously released its mutex immediately after loading, allowing concurrent inference requests to evict an active model mid-stream.
> - **Model Guard Reservation**: `OllamaLifecycle::reserve()` locks the loaded model with an `Arc`-counted `ModelGuard` for the full multi-turn agent loop.
> - **Time & Space Complexity**:
>   - **Model Reservation Guard**: $O(1)$ constant time lock acquisition and guard drop.
>   - **Token Delta Stream Parsing & Tag Stripping**: $O(N)$ linear pass over streamed tokens/character buffers ($N \le 8192$ tokens per turn).
>   - **Client RegEx Block Splitting**: $O(M)$ single-pass regex parsing over accumulated response buffer $M$.
>   - **Memory & Allocation Efficiency**: $O(N)$ separate heap buffers for `content` and `thinking` deltas. Zero heap thrashing or duplicate allocation cascades on ARM64 Cortex-A76.

---

## Part 1 — Initial Thinking Model Pipeline & Client Stream Fixes (Completed)

- [x] **F0 (Client Stream Gate)**: Removed `hasCompletedToolCalls` gate in `global_chat_provider.dart`. Plain responses stream directly into `message.content`.
- [x] **P0 (Rust Content Separation)**: Added `think: true` to `ChatPayload`, dual streaming accumulators, and `<think>` tag stripping.
- [x] **P1 (Rust History Hygiene)**: Stripped tool call artifacts and think tags before appending assistant turns to context.
- [x] **P2 (Tool Enforcement Flag)**: Added `tool_requirement_satisfied` flag to prevent redundant tool loops.
- [x] **P3 & P4 (Nudge Provenance & Precomputed Metrics)**: Tagged governor nudge messages as system role and pre-calculated RAM/uptime metrics in Rust.
- [x] **F1–F4 (Flutter UI Hardening & Transcript Export)**: Added `stripThinkTags` helper, updated regex tag extraction, and added `'reasoning'` step type icons.

---

## Part 2 — Ollama Model Eviction Race & `client.rs` Cleanup (Active)

### P0 — Hold Model Reservation for Full Inference Duration
- **Target**: `shua_governor/src/ollama/lifecycle.rs`, `shua_governor/src/ai_router/agent_loop.rs`
- **Problem**: `OllamaLifecycle::load()` releases its mutex as soon as `load_model` returns. Concurrent calls to `load()` for a different model evict the resident model mid-stream.
- **Fix**:
  - Add reservation/guard API: `OllamaLifecycle::reserve(&self, model_name: &str) -> Result<ModelGuard>`.
  - `ModelGuard` holds an active reference/permit preventing eviction for as long as inference is running.
  - `agent_loop.rs` holds `ModelGuard` for the full agent loop turn (across all iterations).
  - `load()` for a different model must block or error if an active `ModelGuard` exists for the current model — never evict out from under a live stream.
  - Stop swallowing eviction errors (`let _ = self.client.evict_model(...)`). Fail fast if eviction fails before attempting `load_model`.
  - Add integration/unit test in `lifecycle.rs` simulating a long-running stream to assert eviction blocks/fails while a guard is active.

---

### P1 — Wire or Clean Up Model Registry `keep_alive` Config Field
- **Target**: `shua_governor/src/ollama/model_registry.rs`, `shua_governor/src/ai_router/agent_loop.rs`
- **Problem**: `RegisteredModel.keep_alive` is documented in `config.toml` but ignored; call sites hardcode `-1`.
- **Fix**:
  - Wire `keep_alive` from `RegisteredModel` into `agent_loop.rs` chat call sites (or remove the field from `RegisteredModel` and `config.toml` if `-1`-always is the single canonical policy).

---

### P2 — Fix `effective_text()` Fallback Chain
- **Target**: `shua_governor/src/ollama/client.rs` (`ChatMessageResponse::effective_text()`)
- **Problem**: If `reasoning_content` is `Some("")`, the fallback chain returns empty `content` instead of checking `thinking`.
- **Fix**:
  - Flatten fallback to straight priority: `content` → `reasoning_content` → `thinking`.
  - Add unit test with `content: ""`, `reasoning_content: Some("")`, `thinking: Some("real text")` asserting `effective_text()` returns `"real text"`.

---

### P3 — `client.rs` Housekeeping & Type-Safe `KeepAlive` Enum
- **Target**: `shua_governor/src/ollama/client.rs`
- **Fix**:
  - Separate `accumulated_content` and `accumulated_thinking` clean buffers; synthesize display markup (`<think>`) only in the `on_delta` callback.
  - Populate `reasoning_content` consistently in streaming path or normalize reasoning field handling.
  - Replace magic numbers (`json!(-1)`, `json!(0)`) with a type-safe `KeepAlive` enum (`Forever`, `Immediate`, `Duration(u64)`).

---

## Part 2 Suggested Execution Order

1. **Part 2 - P0 (Lifecycle Guard & Reservation)**: Implement `ModelGuard` in `ollama/lifecycle.rs` and hold guard in `agent_loop.rs`.
2. **Part 2 - P1 (Keep-Alive Config Plumbing)**: Resolve `RegisteredModel.keep_alive` usage in `model_registry.rs`.
3. **Part 2 - P2 (`effective_text()` Fallback Fix)**: Flatten priority chain and add unit test.
4. **Part 2 - P3 (`client.rs` Housekeeping)**: Add `KeepAlive` enum and clean buffer separation.

---

## Acceptance Criteria

- [x] Plain questions without tool calls display correctly in Flutter client UI without empty bubbles.
- [x] Reasoning tokens from `qwen3.5` / `deepseek-r1` are cleanly separated into `thinking` buffers and stream live token-by-token over HBP.
- [x] Concurrent `load()` calls for a different model block or error while an active `ModelGuard` holds an inference reservation.
- [x] Eviction errors in `OllamaLifecycle` are returned as explicit errors rather than silently swallowed.
- [x] `ChatMessageResponse::effective_text()` returns `thinking` text when `reasoning_content` is an empty string `Some("")`.
- [x] `cargo test` and `flutter test` pass with zero compiler warnings.
