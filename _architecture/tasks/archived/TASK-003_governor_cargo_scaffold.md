# TASK-003 — `shua_governor` Cargo Scaffold

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `c:\horaizon-3.0\shua_governor\` |
| **Blocks** | TASK-004, TASK-005, TASK-006, TASK-007 |
| **Prerequisites** | Rust toolchain installed (`rustup`, `cargo`) |

---

## Context

Create the `shua_governor` Rust binary crate from scratch. This task only covers the skeleton: `Cargo.toml`, directory structure, placeholder modules, and a `main.rs` that compiles and prints a startup message. No real logic yet — that comes in TASK-004 through TASK-007.

---

## Step 1: Create the crate

```powershell
# From repo root
cargo new shua_governor --bin
```

This creates:
```
shua_governor/
├── Cargo.toml
└── src/
    └── main.rs
```

---

## Step 2: Replace `Cargo.toml`

Replace the contents of `shua_governor/Cargo.toml` with:

```toml
[package]
name        = "shua_governor"
version     = "0.1.0"
edition     = "2021"
description = "horAIzon 3.0 — Central governor: HBP v2 broker, process registry, Ollama lifecycle"
authors     = ["Joshua B. Ygot"]

[[bin]]
name = "shua_governor"
path = "src/main.rs"

[dependencies]
# Async runtime
tokio            = { version = "1", features = ["full"] }

# WebSocket
tokio-tungstenite = { version = "0.23", features = ["rustls-tls-native-roots"] }
futures-util     = "0.3"

# MessagePack serialization
rmp-serde        = "1.3"
serde            = { version = "1", features = ["derive"] }

# HTTP client (Ollama API)
reqwest          = { version = "0.12", features = ["json", "rustls-tls"], default-features = false }

# Process management / signals
nix              = { version = "0.29", features = ["signal", "process"] }

# Config file
toml             = "0.8"

# Scheduling (Dream Loop)
tokio-cron-scheduler = "0.13"

# Logging
tracing          = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# UUID generation
uuid             = { version = "1", features = ["v4"] }

# Misc
anyhow           = "1"
thiserror        = "1"
once_cell        = "1"
chrono           = { version = "0.4", features = ["serde"] }

[dev-dependencies]
tokio-test       = "0.4"

[profile.release]
opt-level = 3
lto       = true
strip     = true
```

---

## Step 3: Create the full source directory structure

Create these directories and empty placeholder files:

```
shua_governor/src/
├── main.rs                         ← entry point
├── config.rs                       ← TOML config loader
├── error.rs                        ← AppError type
├── broker/
│   ├── mod.rs
│   ├── server.rs                   ← WebSocket listener
│   ├── dispatcher.rs               ← frame routing
│   └── frame.rs                    ← HBP v2 encode/decode
├── registry/
│   ├── mod.rs
│   ├── module_entry.rs             ← ModuleEntry + ModuleState
│   ├── process_manager.rs          ← spawn/SIGSTOP/SIGCONT
│   └── cgroup_manager.rs           ← cgroups v2 memory limits
├── ollama/
│   ├── mod.rs
│   ├── client.rs                   ← reqwest HTTP to Ollama API
│   ├── lifecycle.rs                ← load/evict orchestration
│   └── model_registry.rs           ← registered models from config
├── ai_router/
│   ├── mod.rs
│   ├── intent_classifier.rs        ← heuristic classifier
│   └── prompt_budget.rs            ← context window partitioning
├── dream_loop/
│   ├── mod.rs
│   └── scheduler.rs                ← tokio-cron-scheduler
└── logger/
    ├── mod.rs
    └── log_broadcaster.rs          ← streams logs to HBP clients
```

Create each directory and a stub `mod.rs` or file as listed. Use the commands below.

```powershell
cd shua_governor

# Create directories
New-Item -ItemType Directory -Force src/broker, src/registry, src/ollama, src/ai_router, src/dream_loop, src/logger
```

---

## Step 4: Write `src/error.rs`

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Config error: {0}")]
    Config(String),

    #[error("WebSocket error: {0}")]
    WebSocket(String),

    #[error("Serialization error: {0}")]
    Serialization(String),

    #[error("Module not found: {0}")]
    ModuleNotFound(String),

    #[error("Module asleep: {0}")]
    ModuleAsleep(String),

    #[error("Ollama error: {0}")]
    Ollama(String),

    #[error("Process error: {0}")]
    Process(String),
}

pub type Result<T> = std::result::Result<T, AppError>;
```

---

## Step 5: Write stub `mod.rs` files

For each module directory, create a `mod.rs` with a single comment indicating it's a stub:

**`src/broker/mod.rs`**
```rust
// HBP v2 WebSocket broker — TASK-004
pub mod server;
pub mod dispatcher;
pub mod frame;
```

**`src/registry/mod.rs`**
```rust
// Process registry + cgroups — TASK-005
pub mod module_entry;
pub mod process_manager;
pub mod cgroup_manager;
```

**`src/ollama/mod.rs`**
```rust
// Ollama lifecycle manager — TASK-006
pub mod client;
pub mod lifecycle;
pub mod model_registry;
```

**`src/ai_router/mod.rs`**
```rust
// AI intent router — TASK-006
pub mod intent_classifier;
pub mod prompt_budget;
```

**`src/dream_loop/mod.rs`**
```rust
// Dream Loop scheduler — TASK-006
pub mod scheduler;
```

**`src/logger/mod.rs`**
```rust
// Log broadcaster — TASK-004
pub mod log_broadcaster;
```

---

## Step 6: Write stub source files

For every file listed in Step 3 that is NOT a `mod.rs`, create it with a single placeholder:

```rust
// TODO: implemented in TASK-XXX
```

Apply this to:
- `src/config.rs`
- `src/broker/server.rs`, `dispatcher.rs`, `frame.rs`
- `src/registry/module_entry.rs`, `process_manager.rs`, `cgroup_manager.rs`
- `src/ollama/client.rs`, `lifecycle.rs`, `model_registry.rs`
- `src/ai_router/intent_classifier.rs`, `prompt_budget.rs`
- `src/dream_loop/scheduler.rs`
- `src/logger/log_broadcaster.rs`

---

## Step 7: Write `src/main.rs`

```rust
mod broker;
mod config;
mod error;
mod registry;
mod ollama;
mod ai_router;
mod dream_loop;
mod logger;

use tracing::info;
use tracing_subscriber::{fmt, EnvFilter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize structured logging
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env()
            .add_directive("shua_governor=info".parse()?))
        .json()
        .init();

    info!(
        module = "shua.governor",
        version = env!("CARGO_PKG_VERSION"),
        "shua_governor starting"
    );

    // TODO: load config (TASK-007)
    // TODO: start process registry (TASK-005)
    // TODO: start Ollama lifecycle manager (TASK-006)
    // TODO: start Dream Loop scheduler (TASK-006)
    // TODO: start HBP v2 WebSocket broker (TASK-004)

    // Placeholder: keep alive
    tokio::signal::ctrl_c().await?;
    info!(module = "shua.governor", "Shutdown signal received");
    Ok(())
}
```

---

## Step 8: Verify it compiles

```powershell
cd c:\horaizon-3.0\shua_governor
cargo check
```

Expected: no errors (only warnings about unused stubs are acceptable).

```powershell
cargo build
```

Expected: builds successfully, produces `target/debug/shua_governor.exe`.

---

## Acceptance Criteria

- [x] `shua_governor/Cargo.toml` exists with all dependencies listed
- [x] All source directories exist (`broker/`, `registry/`, `ollama/`, etc.)
- [x] `cargo check` passes with zero errors
- [x] `cargo build` produces a binary
- [x] Running the binary prints a JSON log line containing `"shua_governor starting"`
- [x] `cargo clippy` produces no `error` level output

---

## References

- `_architecture/specs/shua_governor/shua_governor_spec.md` — full module spec
- `_architecture/contracts/hbp/hbp_v2_spec.md` — HBP v2 for TASK-004
