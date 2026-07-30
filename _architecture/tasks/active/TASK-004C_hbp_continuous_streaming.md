# TASK-004C — HBP v2 Continuous Streaming, Real-Time AI Tokens & N-Loop Event Architecture

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Active |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust, Dart, Python, TOML |
| **Target** | `_architecture/contracts/hbp/`, `shua_governor/`, `client_flutter/` |
| **Prerequisites** | TASK-004B complete |
| **Branch** | `task/TASK-004C-hbp-continuous-streaming` |

---

## 1. Context & Overview

Standard HBP v2 RPC (`0x01 REQUEST` $\rightarrow$ `0x02 RESPONSE`) buffers the full result until execution completes. For multi-turn agentic AI loops (Qwen 3.5 executing MCP tools over 2–5 iterations), this batching creates multi-second visual silences where the UI cannot display live token generation or step updates.

TASK-004C extends HBP v2 with a **Universal Zero-Overhead Continuous Binary Streaming Protocol** (`stream.chunk`, `stream.step`, `StreamMediaType`), adds real-time word-by-word token streaming, enables live N-loop step tracking in Flutter, and updates the AI Chat broker & UI components.

---

## 2. Technical Specifications

### A. Universal Stream Contract Schema (`hbp_governor.toml`)
- **`StreamMediaType` Enum**: `LlmToken` (`1`), `AudioPcm` (`2`), `AudioOpus` (`3`), `VideoNal` (`4`), `VideoWebp` (`5`), `StepMilestone` (`6`), `TelemetryMetric` (`7`).
- **`StreamFrameDto` Struct**: Container for stream media types with `sequence_num`, `chunk_data`, and `is_last`.
- **`AgentLoopStepDto` & `ToolCallStepDto` Structs**: Structured payloads for agent turn step milestones.
- **`stream.chunk` Operation**: Universal server-pushed stream packet.
- **`stream.step` Operation**: Agent loop turn & tool call milestone event.

### B. Rust Governor Broker (`shua_governor`)
- `HbpFrame::stream_event()` constructor echoing request transaction `id`.
- Unbounded `step_tx` channel forwarding `ai.route.step` HBP `EVENT` frames live as turns execute.
- LLM streaming token evaluation forwarding `stream.chunk` token deltas.
- Timeout removal for active LLM generation passes.

### C. Flutter Client (`client_flutter`)
- `OllamaAiService` listening to `_hbpClient.events` matching `txId`.
- Real-time `OllamaStreamChunk` yielding on `stream.step` and `stream.chunk`.
- `GlobalChatNotifier` updating `ChatMessage.content` and `ChatMessage.steps` in real-time.
- `AgentLoopCard` live rendering for turn steps with markdown formatting.

---

## 3. Raspberry Pi 5 Complexity Analysis

| Metric | Target | Notes |
|---|---|---|
| Stream Event Latency | < 5ms | Direct `tokio::io` frame write from slice pointer |
| Time Complexity | $O(1)$ | Direct slice pass-through (`utf8.decode(bytes)`) |
| Space Complexity | $O(1)$ | Zero heap allocations — reuses single thread-local ring buffer |
| Network Wire Overhead | 0 bytes | Payload `p` contains raw bytes directly |

---

## 4. Acceptance Criteria

- [ ] `hbp_governor.toml` contains `StreamMediaType`, `StreamFrameDto`, `AgentLoopStepDto`, `stream.chunk`, and `stream.step`.
- [ ] `python -m tools.sync_contracts` generates typed DTOs across Rust, Dart, Go, and TypeScript cleanly.
- [ ] `shua_governor` builds cleanly with zero compiler warnings (`cargo check`).
- [ ] `client_flutter` builds cleanly with zero Dart analysis errors (`dart analyze`).
- [ ] Real-time LLM token streaming and N-loop step tracking operate live over HBP WebSocket.
- [ ] Feature branch merged to `main` via `git merge --no-ff`.
