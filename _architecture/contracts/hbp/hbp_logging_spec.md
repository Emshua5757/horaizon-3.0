# HBP Logging Protocol & Centralized Telemetry Specification

| Field | Value |
| :--- | :--- |
| **Version** | 2.0.0 |
| **Date** | 2026-07-23 |
| **Domain** | Centralized Logging & Telemetry |
| **Transport** | Unix Domain Socket (`/tmp/horaizon_logs.sock`), TCP Loopback (`127.0.0.1:5001`), HBP v2 WebSocket |
| **Storage** | SQLite `activity.db` LTM + Append-only `important.log` audit file |

---

## 1. Overview

The horAIzon Centralized Logging Protocol defines how logs, events, metrics, and diagnostics across the entire horAIzon ecosystem (Governor, local microservices, AI models, and Flutter apps) are ingested, filtered, stored, and streamed.

```
+-----------------------------------------------------------------------------------+
| Microservices (Go, Node, Python, Rust)                                            |
|   --> Binary HBP Log Frames over IPC UDS/TCP (HB magic + 0x12)                   |
+-----------------------------------------------------------------------------------+
                                   |
+----------------------------------v------------------------------------------------+
| Flutter Clients (MSI, Moto G84)                                                   |
|   --> HBP v2 Request Frame (mod: "shua.governor", op: "log.emit")                 |
+----------------------------------+------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------------------+
|                              shua_governor Pipeline                               |
|   1. Ingress Stage 1 Filter & Sensitive Data Redaction ([REDACTED])               |
|   2. Ingress Stage 2 MPSC Ring Buffer (4,096 items max)                           |
|   3. Background Flush Worker (`flush_loop`):                                      |
|      - SQLite `activity.db` LTM (7-day retention)                                 |
|      - `important.log` Audit File (Actionable ERROR/PANIC/TAG_IMPORTANT only)     |
|   4. HBP v2 Broadcaster (`LogBroadcaster`):                                       |
|      - Evaluates client `LogFilter` (min_level, modules, tag_mask)               |
|      - Pushes `EVENT` frames (op: "log_event") over WebSocket                      |
+-----------------------------------------------------------------------------------+
```

---

## 2. Microservice IPC Wire Format

Local microservices communicate with the Governor log listener over `/tmp/horaizon_logs.sock` (Linux UDS) or `127.0.0.1:5001` (TCP Loopback).

### Binary Frame Header (12 Bytes)

```
 0               1               2               3
+---------------+---------------+---------------+---------------+
| Magic 'H'     | Magic 'B'     | Version (0x02)| MsgType (0x12)|  Header Bytes 0..3
+---------------+---------------+---------------+---------------+
|                             Reserved                          |  Header Bytes 4..7
+---------------+---------------+---------------+---------------+
|                     Payload Length (u32 BE)                   |  Header Bytes 8..11
+---------------+---------------+---------------+---------------+
|                     Payload Bytes (MessagePack map)           |  Payload Bytes...
+---------------+---------------+---------------+---------------+
```

- **Magic Bytes**: `0x48 ('H')`, `0x42 ('B')`
- **MsgType Code**: `0x12` (Log Frame)
- **Payload**: MessagePack-encoded map matching `BorrowedLogEntry`.

---

## 3. Log Entry Data Model

### Integer Constants

#### Log Levels
| Level Name | Integer Value | Description |
| :--- | :--- | :--- |
| `TRACE` | `1` | Fine-grained internal execution detail |
| `DEBUG` | `2` | Diagnostic debugging statements |
| `INFO` | `3` | Normal operational lifecycle events |
| `WARN` | `4` | Non-fatal anomalies or transient retries |
| `ERROR` | `5` | Actionable runtime errors requiring attention |

#### Module IDs (`module` u8)
| Module Name | ID | Description |
| :--- | :--- | :--- |
| `shua.governor` | `10` | Central Governor process |
| `shua.resume` | `20` | Resume builder Go process |
| `shua.diary` | `30` | Diary block editor Node process |
| `shua.code_visualizer` | `40` | Rust code topology scanner |
| `shua.gym` | `50` | Python MediaPipe pose daemon |
| `shua.crypto` | `60` | Python crypto tracker |
| `shua.flutter_client` | `100` | Cross-platform Flutter UI client |
| `unknown` | `255` | Unidentified or raw socket stream |

#### Tag Bitmasks (`tags` u32)
| Tag Flag | Bitmask | Description |
| :--- | :--- | :--- |
| `TAG_SYSTEM` | `0x01` | System infrastructure event |
| `TAG_IMPORTANT` | `0x02` | Actionable high-priority audit event |
| `TAG_AI_INFERENCE` | `0x04` | Ollama model load/evict/prompt event |
| `TAG_CLIENT_UI` | `0x08` | Flutter client diagnostic event |
| `TAG_SECURITY` | `0x10` | Auth, permission, or security audit event |

---

## 4. HBP v2 Operations for Logging

### `governor.logs.subscribe` (C → S REQUEST)

Subscribes or updates the client's WebSocket live log stream filter.

#### Payload Schema
```msgpack
{
  "min_level":      uint8,        // Minimum level (1=TRACE .. 5=ERROR)
  "modules":        [str]|nil,    // Filter by module names (e.g. ["shua.resume"])
  "tag_mask":       uint32|nil    // Bitmask filter for tags
}
```

### `governor.log.emit` (C → S REQUEST)

Client emits a log event to Governor.

#### Payload Schema
```msgpack
{
  "level":          uint8,
  "subsystem":      str,
  "msg":            str,
  "tags":           uint32|nil,
  "telemetry":      map|nil,
  "trace_id":       str|nil
}
```

### `governor.logs.query` (C → S REQUEST)

Query historical logs from SQLite LTM.

#### Request Payload
```msgpack
{
  "min_level":      uint8|nil,
  "module":         uint8|nil,
  "subsystem":      str|nil,
  "start_ts":       uint64|nil,
  "end_ts":         uint64|nil,
  "trace_id":       str|nil,
  "limit":          uint32|nil,   // Max results (default 50, max 200)
  "offset":         uint32|nil
}
```

#### Response Payload
```msgpack
{
  "total":          uint32,
  "entries": [
    {
      "ts":         uint64,
      "level":      uint8,
      "module":     uint8,
      "subsystem":  str,
      "msg":        str,
      "tags":       uint32,
      "custom_tags": [str]|nil,
      "telemetry":  map|nil,
      "trace_id":   str|nil
    }
  ]
}
```

### `governor.log_event` (S → C EVENT)

Live server-pushed log event frame emitted to subscribed clients.

#### Payload Schema
Same structure as individual item in `governor.logs.query` response entries.

---

## 5. Persistence Routing & Storage Policy

1. **SQLite LTM (`activity.db`)**:
   - Table `activity_log` with indexes on `ts`, `module`, `subsystem`, `level`, `tags`.
   - Stores ALL logs (`TRACE` through `ERROR`).
   - Retention policy: Auto-purge records older than **7 days**.

2. **Audit File (`important.log`)**:
   - Appended to `/var/lib/horaizon/logs/important.log` (or `important.log` in local dev).
   - Stores ONLY high-severity entries (`ERROR`, `FATAL`, `PANIC`, or `TAG_IMPORTANT`/`TAG_SECURITY`).
   - Transient `WARN` logs (retries, cache misses) are **omitted**.
   - Rotation policy: Rotates at **10MB** (keeps `important.log.1`, `important.log.2`).

---

## 6. References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — Wire envelope spec
- `_architecture/specs/shua_governor/shua_governor_spec.md` — Governor architecture spec
