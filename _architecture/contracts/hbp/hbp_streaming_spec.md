# HBP v2 Universal Future-Proof Continuous Streaming Specification (`hbp_streaming_spec.md`)

| Field | Value |
| :--- | :--- |
| **Protocol** | HBP v2 (horAIzon Binary Protocol) |
| **Extension** | Universal Future-Proof Continuous Binary & Media Streaming |
| **Module** | `shua.governor` & All Microservices (`shua.diary`, `shua.resume`, `shua.code_visualizer`) |
| **Media Types** | LLM Tokens (`1`), Audio PCM (`2`), Audio Opus (`3`), Video NAL (`4`), Video WebP (`5`), Step Milestones (`6`), Telemetry (`7`) |
| **Operations** | `stream.chunk` (universal media/data), `stream.step` (agent milestones) |
| **Target Hardware** | Raspberry Pi 5 (8GB RAM, ARM Cortex-A76) |
| **Status** | Active Contract Specification |

---

## 1. Architectural Vision: Universal Continuous Streaming

HBP v2 Continuous Streaming is engineered to be **100% future-proof** for any continuous data or media stream across the horAIzon 3.0 ecosystem:
1. **Real-Time LLM Token Streaming** (word-by-word typewriter effect)
2. **Low-Latency Audio Streaming** (Full-duplex PCM / Opus voice chat)
3. **High-Frame-Rate Video Streaming** (Camera NAL units / WebP frames)
4. **Agent Loop Step Milestones** (N-turn tool call notifications)
5. **High-Frequency Telemetry Metrics** (CPU/RAM/Temp sensor streams)

---

## 2. Universal Schema Contracts (`hbp_governor.toml`)

### A. Media Type Classifier (`StreamMediaType`)

```toml
[[enums]]
name        = "StreamMediaType"
description = "Universal Media Type Classifier for HBP Stream Packets"
[[enums.variants]]
name = "LlmToken"        # 1: UTF-8 LLM text delta chunk
value = 1
[[enums.variants]]
name = "AudioPcm"        # 2: Raw PCM 16-bit audio sample buffer
value = 2
[[enums.variants]]
name = "AudioOpus"       # 3: Encoded Opus audio packet
value = 3
[[enums.variants]]
name = "VideoNal"        # 4: H.264 video NAL unit frame
value = 4
[[enums.variants]]
name = "VideoWebp"       # 5: WebP keyframe/delta image byte buffer
value = 5
[[enums.variants]]
name = "StepMilestone"   # 6: Agent turn milestone / tool call notification
value = 6
[[enums.variants]]
name = "TelemetryMetric" # 7: Sensor / cgroup telemetry data packet
value = 7
```

---

### B. Universal Stream Frame DTO (`StreamFrameDto`)

```toml
[[structs]]
name        = "StreamFrameDto"
description = "Universal HBP Stream Frame container for arbitrary data/media streams"
[[structs.fields]]
index       = 1
name        = "media_type"
type        = "StreamMediaType"
[[structs.fields]]
index       = 2
name        = "sequence_num"
type        = "u64"
[[structs.fields]]
index       = 3
name        = "chunk_data"
type        = "str"
[[structs.fields]]
index       = 4
name        = "is_last"
type        = "bool"
```

---

### C. Universal Operations

```toml
[[operations]]
module          = "shua.governor"
name            = "stream.chunk"
type            = "stream"
requires_auth   = true
description     = "Universal server-pushed stream packet for LLM tokens, Audio, Video, and Telemetry"
request_struct  = ""
response_struct = "StreamFrameDto"

[[operations]]
module          = "shua.governor"
name            = "stream.step"
type            = "stream"
requires_auth   = true
description     = "Server-pushed milestone event for agent turn changes and tool execution results"
request_struct  = ""
response_struct = "AgentLoopStepDto"
```

---

## 3. Sequence Diagram

```
Client (Flutter / Microservices)               Server (shua_governor)
      │                                                │
      │── 0x01 REQUEST (id: "req-123", op: "ai.route") ─►│
      │                                                │  (Agent Loop Turn 1)
      │◄── 0x03 EVENT (op: "stream.step") ─────────────│  [Step: governor_get_metrics]
      │                                                │  (Executing MCP Tool...)
      │                                                │  (Agent Loop Turn 2)
      │◄── 0x03 EVENT (op: "stream.step") ─────────────│  [Step: final_answer]
      │                                                │  (Tokens generating...)
      │◄── 0x03 EVENT (op: "stream.chunk") ────────────│  [Chunk #0: "RPi 5 ", media: LlmToken]
      │◄── 0x03 EVENT (op: "stream.chunk") ────────────│  [Chunk #1: "is operational.", is_last: true]
      │                                                │
      │◄── 0x02 RESPONSE (op: "ai.route") ──────────────│  [Final Payload + Steps]
```

---

## 4. Raspberry Pi 5 Complexity & Resource Analysis

| Metric | Complexity | Technical Justification |
|---|---|---|
| **Time Complexity (Send)** | $O(1)$ | Direct array packet construction without dynamic string formatting |
| **Time Complexity (Receive)** | $O(1)$ | MsgPack integer enum match (`media_type`) |
| **Space Complexity** | $O(1)$ | Zero heap allocations — reuses single thread-local ring buffer |
| **Extensibility** | 100% | Adding new streams (e.g. LiDAR, canvas drawing) only requires 1 new enum variant |
