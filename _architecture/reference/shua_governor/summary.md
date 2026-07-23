# SHUA Governor: Module Summary

The **SHUA Governor** (`shua_governor`) is a native systems-level daemon written in **Rust** designed to run on the Raspberry Pi 5. It acts as the unified entry API gateway, reverse proxy, process supervisor, and cgroups resource monitor.

---

## 1. Technical Architecture

*   **Runtime Engine:** Tokio async runtime for non-blocking task execution and concurrent subprocess supervision.
*   **Web Framework:** Axum + Tower HTTP for routing, connection pooling, and permissive CORS layers.
*   **Reverse Proxy:** Hyper client connections with zero-copy body streaming.
*   **Resource Monitoring:** Sysinfo for cross-platform RAM tracking, and direct procfs/cgroups file descriptors reads.
*   **cgroups Engine:** Native Linux `/sys/fs/cgroup/shua/` directory writes. On Windows/macOS hosts, platform-aware fallbacks emulate writes to a local mock filesystem `./mock_cgroup`.
*   **SDUI Compiler:** Pre-allocated byte-buffers serialized to binary MessagePack (`rmp-serde`) or JSON representation.

---

## 2. API Gateway Routing Table

| Route Pattern | Target Destination | Handler Mode | Payload Stream |
| :--- | :--- | :--- | :--- |
| **`GET /health`** | Local Governor | Axum Handler | JSON |
| **`GET /api/dashboard`** | Local Governor | Axum Handler | MsgPack / JSON |
| **`POST /api/governor/toggle/:id`** | Local Governor | Axum Handler | JSON |
| **`/api/diary/*`** | `http://127.0.0.1:3001` | Hyper Reverse Proxy | Zero-Copy Stream |
| **`/api/analysis/*`** | `http://127.0.0.1:8000` | Hyper Reverse Proxy | Zero-Copy Stream |

---

## 3. Development Status

*   **Status:** Scaffolding complete.
*   **Completed:** Cargo project setup, Axum boilerplate configuration, basic static SDUI payload endpoints, platform-aware mock file structure.
*   **Pending:** Gateway proxy forwarding, cgroups procfs monitoring loops, process spawning supervision, and binary MsgPack integration.
