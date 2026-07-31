# TASK-006D — Fix JOSH Agent Loop & Thinking Model Pipeline (Qwen 3.5 / DeepSeek R1)

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 1 / Phase 2 Follow-up |
| **Type** | AI-executable |
| **Language** | Rust / Dart (Flutter) |
| **Target** | `shua_governor/src/ollama/client.rs`, `shua_governor/src/ai_router/agent_loop.rs`, `client_flutter/lib/features/chat/` |
| **Blocks** | Nothing |
| **Prerequisites** | TASK-006C (Governor Ollama Logging & Runtime Hardening) |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/contracts/hbp/` |

---

## Architecture Context & Hardware Optimization (Raspberry Pi 5)

> [!IMPORTANT]
> **Raspberry Pi 5 Resource & Execution Constraints**:
> - **Hardware**: Raspberry Pi 5 (8GB RAM, ARM Cortex-A76) + Windows Offload Host.
> - **Reasoning / Thinking Models**: Models like `qwen3.5` or `deepseek-r1` emit structured reasoning content (`<think>...</think>` tags or explicit `thinking` deltas). Without strict pipeline separation, reasoning tokens leak into conversation history and client UI buffers, leading to multi-turn reasoning spirals and redundant tool invocations.
> - **Time & Space Complexity**:
>   - **Token Delta Parsing & Tag Stripping**: $O(N)$ linear time complexity over character string length $N$ ($N \le 8192$ tokens per turn).
>   - **Client RegEx Block Splitting**: $O(M)$ single-pass regex parsing over accumulated response buffer $M$.
>   - **State Enforcement & Tool Satisfaction Tracking**: $O(1)$ constant time check per turn iteration in `agent_loop.rs`.
>   - **Memory & Allocation Efficiency**: $O(N)$ separate heap buffers for `content` and `thinking` deltas. Prevents string copying/thrashing on ARM64 Cortex-A76 cores.

---

## Compatibility & Scope Matrix

- **Thinking Models (`qwen3.5`, `deepseek-r1`)**: Items P0.1–P0.3 and F1/F2/F4 activate when models emit `thinking`, `reasoning_content`, or `<think>` tags.
- **Non-Thinking Models (`qwen2.5`, `llama3.1`)**: Items P0.1–P0.3 and F1/F2/F4 act as inert, non-breaking no-ops.
- **Universal Bug Fixes (Model-Agnostic)**: Items F0, P1, P2, P3, P4, and P5 fix core pipeline and UI parsing bugs regardless of model selection.

---

## Detailed Task Requirements

### F0 — Client: Stop Provider from Swallowing Plain (No-Tool-Call) Replies
- **Target**: `client_flutter/lib/features/chat/providers/global_chat_provider.dart` (`sendMessage()` stream listener)
- **Problem**: Replies without tool calls have `hasCompletedToolCalls == false`, forcing all output into `liveReasoning` and leaving `message.content` empty.
- **Fix**:
  - Remove the `hasCompletedToolCalls` gate entirely. Content deltas must always accumulate into `finalContent` / `message.content`.
  - Remove synthetic `liveReasoning` accumulator and synthetic `AgentLoopStep(stepType: 'reasoning')` construction.
  - Stream raw `chunk.content` directly into `message.content` and rely on `FormattedMarkdownContent` for tag rendering.

---

### P0 — Rust: Isolate Thinking Tokens from Content Buffer
- **Target**: `shua_governor/src/ollama/client.rs`
- **P0.1 Request Explicit Think Mode**:
  - Thread `think: bool` through `chat_with_tools` (~L5694) and `chat_with_tools_stream` (~L5728).
  - Add `think: Option<serde_json::Value>` to `ChatPayload` and set `serde_json::json!(true)` in request builders.
- **P0.2 Fix Streaming Accumulator**:
  - In `chat_with_tools_stream` (~L5745–5788), accumulate `content` deltas and `thinking` deltas into separate buffers.
  - Do NOT call `effective_text()` per-chunk during streaming accumulation.
  - Only fall back to `thinking`/`reasoning_content` if `content` deltas never arrived for the whole stream.
- **P0.3 Fix `effective_text()` Semantics & Strip Tags**:
  - Add `<think>...</think>` tag stripping inside/after `effective_text()` (~L5583–5596) as a defensive fallback.
  - Add unit tests for `effective_text()` validating inline `<think>` block removal.

---

### P1 — Rust: History Hygiene & Artifact Stripping
- **Target**: `shua_governor/src/ai_router/agent_loop.rs` (~L954, ~L1021)
- **Problem**: Raw, unstripped assistant outputs and thinking preambles are pushed back into `messages` history.
- **Fix**:
  - Route tool call push sites through `strip_tool_call_artifacts()` and `<think>` stripping before appending to conversation context.

---

### P2 — Rust: Tool Enforcement Satisfied Flag
- **Target**: `shua_governor/src/ai_router/agent_loop.rs` (~L815–822)
- **Problem**: `tool_enforcement_clause` stays in context across turns, forcing verbose reasoning models to re-trigger tool calls redundantly.
- **Fix**:
  - Track `tool_requirement_satisfied: bool` (set `true` upon first successful tool execution).
  - Once satisfied, strip or override `tool_enforcement_clause` with a system addendum: *"You have already called a tool this turn — do not call it again, answer using the result above."*

---

### P3 — Rust: Nudge Message Provenance & History Persistence
- **Target**: `shua_governor/src/ai_router/agent_loop.rs` (~L1067–1097)
- **Fix**:
  - Tag injected corrective commands distinctly (e.g. `ChatMessage::system(...)` or prefix `[GOVERNOR-INJECTED]`).
  - Persist intermediate `AgentLoopStep` items to `ChatHistoryStore` with clear role markers.

---

### P4 — Rust: Precompute Tool Result Values
- **Target**: `shua_governor/src/ai_router/agent_loop.rs` (~L990, ~L1050)
- **Fix**:
  - Format `governor_uptime_s` into human strings (e.g. `"2h 6m"`) in Rust before model prompt injection.
  - Precompute RAM percentage (`ram_mb / total_ram_mb`) in Rust rather than delegating arithmetic to LLM reasoning.

---

### P5 — Rust: Housekeeping & Stale Assertion Cleanup
- **Target**: `shua_governor/src/ai_router/agent_loop.rs` (~L1177)
- **Fix**:
  - Reconcile `PER_CALL_TIMEOUT_SECS` mismatch (const is `90`, assertion was `45`).
  - Run full test suite (`cargo test --all`).

---

### F1–F4 — Client: Flutter Reasoning Rendering & Export Cleanup
- **Target**: `client_flutter/lib/features/chat/`
- **F1 Robust `<think>` Tag Parsing**: Update `formatted_markdown_content.dart` regex to match `<think>(.*?)</think>` across line boundaries and mid-sentence open tags. Add widget tests.
- **F2 Deduplicate UI Rendering**: Ensure `AgentLoopCard` and `_ThinkingCard` do not double-render identical reasoning text.
- **F3 Clean Synthetic Step Types**: Clean up `'reasoning'` step type fallbacks in `chat_message.dart`.
- **F4 Shared Transcript Export Helper**: Create `stripThinkTags(String)` helper for conversation export choices.

---

## Suggested Execution Order

1. **F0 (Flutter Provider)**: Fix `global_chat_provider.dart` plain reply swallowing.
2. **P0 (Rust Wire Separation)**: Implement `think: true`, dual streaming buffers, and `<think>` stripping in `ollama/client.rs`.
3. **P1 (Rust History Hygiene)**: Strip artifacts before appending assistant turns in `agent_loop.rs`.
4. **P2 (Tool Enforcement Flag)**: Prevent redundant tool loops in `agent_loop.rs`.
5. **F1–F3 (Flutter UI Hardening)**: Update regex tag parsing, deduplicate cards, clean step types.
6. **P3 & P4 (Nudge Labeling & Precomputed Metrics)**: Label governor commands and format uptime/RAM in Rust.
7. **F4 & P5 (Transcript Helper & Stale Test Fix)**: Add `stripThinkTags` helper and fix `PER_CALL_TIMEOUT_SECS` test assertion.

---

## Acceptance Criteria

- [ ] Plain questions without tool calls display correctly in Flutter client UI without empty bubbles.
- [ ] Reasoning tokens from `qwen3.5` / `deepseek-r1` are cleanly separated into `thinking` buffers and never leak as raw text into system content.
- [ ] Models do not loop into redundant `governor_get_metrics` calls after satisfying tool requirements.
- [ ] Governor-injected nudge commands are labeled as system/governor origin and stored cleanly in history.
- [ ] Uptime and RAM percentages in tool responses are pre-formatted by Rust.
- [ ] `cargo test` and `flutter test` pass with zero compiler warnings.
