# HBP v2 — horAIzon Binary Protocol Specification

| Field | Value |
| :--- | :--- |
| **Version** | 2.0.0 |
| **Date** | 2026-07-21 |
| **Transport** | WebSocket (wss:// over Tailscale, ws:// on LAN) |
| **Encoding** | MessagePack (binary) |
| **Supersedes** | HBP v1 / SDUI-4 payload contract (horAIzon 2.0) |

---

## What Changed From v1

HBP v1 encoded **UI structure** (SDUI-4 screen blueprints) inside the payload. The backend decided how the screen looked. This created an invisible coupling between every backend module and the Flutter rendering engine.

HBP v2 encodes **data only**. The Flutter client holds all rendering logic. Backend modules are pure data APIs with no UI concern.

| | HBP v1 | HBP v2 |
| :--- | :--- | :--- |
| Payload content | SDUI-4 screen blueprint | Typed data DTO |
| Who decides layout | Server | Flutter client |
| Index addressing | Yes (zero-trust index) | No — named fields |
| Message direction | Server → Client push (primary) | Full bidirectional RPC |
| Binary format | MessagePack | MessagePack |
| Type safety | Runtime only | Schema-enforced per operation |

---

## Transport Layer

```
Client (Flutter)                     Server (shua_governor)
      │                                        │
      │  WebSocket Handshake (Tailscale TLS)   │
      │───────────────────────────────────────►│
      │                                        │
      │  HBP v2 Frame (MessagePack bytes)      │
      │◄──────────────────────────────────────►│
      │        (bidirectional, persistent)     │
```

- **Connection target**: `wss://100.67.11.0:7700` (Tailscale) or `ws://[lan-ip]:7700` (LAN)
- **Port**: `7700` (Governor HBP broker port — reserved)
- **Connection lifecycle**: Single persistent WebSocket per client session. Reconnect with exponential backoff on drop.
- **Heartbeat**: Client sends `PING` frame every 15s. Governor responds with `PONG`. Client considers connection dead after 2 missed PONGs (30s).

---

## Message Types

| Type | Code | Direction | Description |
| :--- | :--- | :--- | :--- |
| `REQUEST` | `0x01` | Client → Server | Client invokes a server operation |
| `RESPONSE` | `0x02` | Server → Client | Server replies to a specific REQUEST |
| `EVENT` | `0x03` | Server → Client | Server pushes an unsolicited event |
| `PING` | `0x04` | Client → Server | Heartbeat ping |
| `PONG` | `0x05` | Server → Client | Heartbeat pong |
| `ERROR` | `0x06` | Server → Client | Protocol-level error (not application error) |

---

## Frame Envelope

Every HBP v2 message — regardless of type, module, or operation — uses the same outer envelope. The `payload` field is a nested MessagePack map whose schema is operation-specific.

### MessagePack Map Schema

```
{
  "v":   uint8,   // Protocol version. Always 2.
  "t":   uint8,   // Message type code (0x01–0x06)
  "id":  str,     // Transaction ID — UUID v4 (36 chars)
                  // RESPONSE must echo the REQUEST's id.
                  // EVENT generates its own unique id.
  "mod": str,     // Module namespace (e.g. "shua.resume")
  "op":  str,     // Operation name (e.g. "compile")
  "ts":  uint64,  // Unix timestamp in milliseconds (UTC)
  "p":   bytes,   // Payload — msgpack-encoded operation body
                  // Empty bytes (0x00) for PING/PONG
  "err": str|nil  // null on success. Error string on failure.
                  // Only present on RESPONSE and ERROR frames.
}
```

### Field Rules

| Field | Required on REQUEST | Required on RESPONSE | Required on EVENT |
| :--- | :--- | :--- | :--- |
| `v` | ✅ | ✅ | ✅ |
| `t` | ✅ | ✅ | ✅ |
| `id` | ✅ (new UUID) | ✅ (echo request UUID) | ✅ (new UUID) |
| `mod` | ✅ | ✅ | ✅ |
| `op` | ✅ | ✅ (echo request op) | ✅ (event name) |
| `ts` | ✅ | ✅ | ✅ |
| `p` | ✅ | ✅ | ✅ |
| `err` | ❌ (omit) | ✅ (null or string) | ❌ (omit) |

---

## Module Namespaces

Modules are dot-namespaced. The Governor is the root broker — all messages flow through it before being forwarded to the target module process.

```
shua.governor.*        ← Governor self (process mgmt, heartbeat, AI router)
shua.resume.*          ← Go: PDF compilation, matrix CRUD
shua.diary.*           ← TypeScript: block editor, JBC, memory elevator
shua.code_visualizer.* ← Rust: AST scan, topology export
shua.gym.*             ← Python: MediaPipe pose streaming
shua.crypto.*          ← Python: portfolio aggregator
```

---

## Operation Registry

### `shua.governor`

| Operation | Direction | Description |
| :--- | :--- | :--- |
| `governor.ping` | C→S | Heartbeat check |
| `governor.status` | C→S | Returns all module process states |
| `governor.module.wake` | C→S | SIGCONT a suspended module |
| `governor.module.sleep` | C→S | SIGSTOP a module |
| `governor.ollama.load` | C→S | Load a named Ollama model |
| `governor.ollama.evict` | C→S | Evict current Ollama model (keep_alive: 0) |
| `governor.ai.route` | C→S | Route a prompt through the intent classifier |
| `governor.logs.subscribe` | C→S | Subscribe/filter live WebSocket log stream |
| `governor.log.emit` | C→S | Ingest client log event into Governor |
| `governor.logs.query` | C→S | Query historical logs from SQLite LTM |
| `governor.log_event` | S→C EVENT | Push live log event to subscribed WebSocket client |

### `shua.resume`

| Operation | Direction | Description |
| :--- | :--- | :--- |
| `resume.matrix.get` | C→S | Fetch current resume matrix |
| `resume.matrix.update` | C→S | Update resume matrix fields |
| `resume.compile` | C→S | Compile Typst PDF (with optional AI tailoring) |
| `resume.history.list` | C→S | List past compilations |
| `resume.templates.list` | C→S | List available Typst templates |

### `shua.diary`

| Operation | Direction | Description |
| :--- | :--- | :--- |
| `diary.entry.list` | C→S | Paginated entry list |
| `diary.entry.get` | C→S | Single entry with all blocks |
| `diary.entry.create` | C→S | Create new entry |
| `diary.entry.delete` | C→S | Delete entry |
| `diary.block.save` | C→S | Upsert a block (debounced) |
| `diary.block.reorder` | C→S | Reorder blocks (LexoRank) |
| `diary.block.delete` | C→S | Delete a block |
| `diary.jbc.prompt` | C→S | Send JBC AI co-pilot prompt |
| `diary.memory.elevate` | C→S | Elevate entry to Global Identity Matrix |
| `diary.sentiment.score` | S→C EVENT | Push sentiment score after save |

### `shua.code_visualizer`

| Operation | Direction | Description |
| :--- | :--- | :--- |
| `code_viz.scan` | C→S | Trigger repo AST scan |
| `code_viz.topology.get` | C→S | Return latest topology export |
| `code_viz.watch.start` | C→S | Start file-watcher daemon |
| `code_viz.watch.stop` | C→S | Stop file-watcher daemon |
| `code_viz.changed` | S→C EVENT | Push incremental topology delta on file change |

---

## Error Handling

Application-level errors are returned in the `RESPONSE` frame with a non-null `err` field and an empty `p` payload.

Protocol-level errors (malformed frame, unknown module, unrecognized op) are returned as `ERROR` frames.

### Standard Error Codes (in `err` string, prefix format)

```
ERR_UNKNOWN_MODULE    — mod not registered in Governor
ERR_UNKNOWN_OP        — operation not recognized by module
ERR_MODULE_ASLEEP     — module is SIGSTOP'd; client must wake first
ERR_TIMEOUT           — operation exceeded 30s deadline
ERR_MALFORMED         — frame failed MessagePack decode or schema validation
ERR_UNAUTHORIZED      — future: auth token invalid (not used in v1 scope)
```

---

## Payload Schemas (Key Operations)

### `resume.compile` REQUEST payload

```msgpack
{
  "matrix_id":    str,          // ID of the resume matrix to compile
  "template":     str,          // Typst template name
  "job_desc":     str|nil,      // Optional: job description for AI tailoring
  "tailor":       bool,         // Apply AI tailoring filter?
  "ai_enhance":   bool          // Apply full Ollama enhancement?
}
```

### `resume.compile` RESPONSE payload

```msgpack
{
  "exhibit_id":   str,          // CAS content-addressed ID of the PDF
  "pdf_url":      str,          // Accessible URL on Pi5
  "duration_ms":  uint32,       // Compilation time
  "tailor_score": float32|nil   // Jaccard similarity score (if tailored)
}
```

### `diary.block.save` REQUEST payload

```msgpack
{
  "entry_id":     str,
  "block_id":     str,
  "block_type":   str,          // "paragraph", "heading1", "code", etc.
  "content":      str,
  "sort_order":   str           // LexoRank string
}
```

### `governor.status` RESPONSE payload

```msgpack
{
  "modules": [
    {
      "name":     str,          // e.g. "shua.resume"
      "state":    str,          // "running" | "sleeping" | "stopped" | "unknown"
      "pid":      uint32|nil,
      "ram_mb":   float32|nil,
      "uptime_s": uint32|nil
    }
  ],
  "ollama": {
    "loaded_model": str|nil,    // Currently loaded model name, or nil
    "ram_mb":       float32|nil
  }
}
```

---

## Client Implementation Notes (Dart)

```
lib/
└── core/
    └── hbp/
        ├── hbp_client.dart         ← WebSocket connection, reconnect logic, heartbeat
        ├── hbp_frame.dart          ← Envelope encode/decode (MessagePack)
        ├── hbp_dispatcher.dart     ← Routes incoming frames to module handlers
        └── hbp_request.dart        ← Typed request builder with tx_id generation
```

- Use `msgpack_dart` or `messagepack` pub package for encoding
- Each pending REQUEST is stored in a `Map<String, Completer>` keyed by `tx_id`
- RESPONSE frames resolve the matching Completer
- EVENT frames are dispatched to a `StreamController` per module namespace

---

## Server Implementation Notes (Rust — shua_governor)

- Governor holds a single `tokio::net::TcpListener` on port 7700
- Each WebSocket connection gets its own `tokio::task`
- Module processes are registered at startup; frames are forwarded via Unix socket or internal channel (not TCP — avoid double-hop latency on localhost)
- `serde_json` is NOT used — all serialization uses `rmp-serde` (MessagePack + serde)

---

## References

- `_architecture/contracts/hbp/hbp_logging_spec.md` — Centralized logging protocol & IPC wire spec
- `ADR-001_native_over_sdui.md` — decision that eliminated SDUI-4 payload encoding
- `_architecture/reference/shua_governor.md` — 2.0 Governor topology
- `_architecture/reference/shua_diary.md` — 2.0 Diary SDUI orchestrator (for migration reference)
