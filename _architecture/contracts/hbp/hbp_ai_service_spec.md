# HBP v2 AI Service & Ollama Completion Specification

| Field | Value |
| :--- | :--- |
| **Specification ID** | `HBP-SPEC-004-AI` |
| **Subsystem** | `shua_governor::ai` / `client_flutter::ai` |
| **Status** | **Active Standard** |
| **Target Nodes** | RPi 5 (`100.67.11.0:11434`), Windows Offload (`127.0.0.1:11434`) |

---

## 1. Overview

This document specifies the payload schemas and RPC dispatching contracts for streaming AI completions across **horAIzon 3.0**. Supports both direct Ollama NDJSON streams (`/api/chat`) and binary MessagePack frames over HBP v2 WebSocket (`ws://host:7700/hbp`).

---

## 2. Payload Schemas

### 2.1 Ollama Direct Chat NDJSON Request (`POST /api/chat`)

```json
{
  "model": "qwen2.5-coder:7b",
  "messages": [
    { "role": "system", "content": "You are JOSH, the horAIzon 3.0 Central AI Assistant." },
    { "role": "user", "content": "Explain RPi 5 offload pipeline." }
  ],
  "options": {
    "temperature": 0.3,
    "top_p": 0.9,
    "num_ctx": 8192
  },
  "stream": true
}
```

### 2.2 Ollama NDJSON Stream Chunk Response

```json
{
  "model": "qwen2.5-coder:7b",
  "created_at": "2026-07-28T01:37:00Z",
  "message": {
    "role": "assistant",
    "content": " The RPi 5 offload pipeline..."
  },
  "done": false
}
```

### 2.3 Terminal Done Frame (when `done == true`)

```json
{
  "model": "qwen2.5-coder:7b",
  "done": true,
  "total_duration": 1240000000,
  "load_duration": 420000000,
  "prompt_eval_count": 48,
  "eval_count": 120,
  "eval_duration": 820000000
}
```

---

## 3. Offload Node Routing Policy

* **Node A (RPi 5 Primary)**: `http://100.67.11.0:11434` / `ws://100.67.11.0:7700/hbp`
* **Node B (Windows Host Offload)**: `http://127.0.0.1:11434` / `ws://127.0.0.1:7700/hbp`

If target node is unreachable within **3,000ms**, fallback mechanism automatically notifies client and attempts local host fallback.
