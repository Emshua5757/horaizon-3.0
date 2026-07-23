# TASK-007 — `shua_governor` config.toml + systemd Deploy to Pi5

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable (deploy steps require SSH to Pi5) |
| **Language** | Rust + bash |
| **Target** | Pi5 at `100.67.11.0` via `ssh horaizon-pi5` |
| **Blocks** | Nothing (this completes Phase 1 backend) |
| **Prerequisites** | TASK-001 (SSH), TASK-003–006 (governor compiles) |

---

## Context

Implement config loading from `/etc/horaizon/governor/config.toml`, cross-compile the binary for Pi5 (aarch64), deploy it, and register it as a systemd service that starts on boot.

---

## Part A — Config Loader

### Step A1: Define config structs in `src/config.rs`

```rust
use std::path::PathBuf;
use serde::Deserialize;
use anyhow::Result;

#[derive(Debug, Deserialize)]
pub struct AppConfig {
    pub governor:    GovernorConfig,
    pub dream_loop:  DreamLoopConfig,
    pub ollama:      OllamaConfig,
    #[serde(default)]
    pub modules:     ModulesConfig,
}

#[derive(Debug, Deserialize)]
pub struct GovernorConfig {
    pub port:      u16,
    pub log_level: String,
    pub timezone:  String,
}

#[derive(Debug, Deserialize)]
pub struct DreamLoopConfig {
    pub enabled: bool,
    pub cron:    String,
}

#[derive(Debug, Deserialize)]
pub struct OllamaConfig {
    pub binary:   String,
    pub host:     String,
    #[serde(default)]
    pub models:   Vec<OllamaModelConfig>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct OllamaModelConfig {
    pub name:       String,
    pub ram_mb:     u32,
    pub role:       String,
    pub keep_alive: i32,
}

#[derive(Debug, Deserialize, Default)]
pub struct ModulesConfig {
    #[serde(default, rename = "entry")]
    pub entries: Vec<ModuleConfigEntry>,
}

#[derive(Debug, Deserialize)]
pub struct ModuleConfigEntry {
    pub name:          String,
    pub binary:        PathBuf,
    pub auto_start:    bool,
    pub ram_limit_mb:  Option<u32>,
}

impl AppConfig {
    pub fn load(path: &std::path::Path) -> Result<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| anyhow::anyhow!("Cannot read config {}: {e}", path.display()))?;
        toml::from_str(&content)
            .map_err(|e| anyhow::anyhow!("Config parse error: {e}"))
    }
}
```

### Step A2: Write the production `config.toml`

Create this file ON THE PI5 at `/etc/horaizon/governor/config.toml`:

```toml
[governor]
port      = 7700
log_level = "info"
timezone  = "Asia/Manila"

[dream_loop]
enabled = true
cron    = "0 18 * * *"    # 02:00 Asia/Manila = 18:00 UTC

[ollama]
binary = "/usr/bin/ollama"
host   = "127.0.0.1:11434"

[[ollama.models]]
name       = "qwen2.5:1.5b"
ram_mb     = 980
role       = "primary_dialogue"
keep_alive = 0

[[ollama.models]]
name       = "llama3.2:3b"
ram_mb     = 2000
role       = "text_generator"
keep_alive = 0

[[ollama.models]]
name       = "nomic-embed-text"
ram_mb     = 270
role       = "embeddings"
keep_alive = 0

[[modules.entry]]
name         = "shua.resume"
binary       = "/opt/horaizon/shua_resume/shua_resume"
auto_start   = false
ram_limit_mb = 256

[[modules.entry]]
name         = "shua.diary"
binary       = "/opt/horaizon/shua_diary/start.sh"
auto_start   = false
ram_limit_mb = 512

[[modules.entry]]
name         = "shua.code_visualizer"
binary       = "/opt/horaizon/shua_code_visualizer/shua_code_visualizer"
auto_start   = false
ram_limit_mb = 512
```

### Step A3: Wire config into `main.rs`

```rust
use std::path::Path;
use crate::config::AppConfig;

// At the top of main(), before anything else:
let config_path = Path::new("/etc/horaizon/governor/config.toml");
let config = AppConfig::load(config_path)
    .unwrap_or_else(|e| {
        tracing::error!(error = %e, "Config load failed — using defaults");
        // TODO: implement Default for AppConfig
        panic!("Cannot start without config: {e}");
    });

info!(
    module = "shua.governor",
    port = config.governor.port,
    "Config loaded"
);

// Use config.governor.port when binding:
let addr: SocketAddr = format!("0.0.0.0:{}", config.governor.port).parse()?;
```

---

## Part B — Cross-compile for Pi5 (aarch64)

The Pi5 uses ARM64 (aarch64-unknown-linux-gnu). Cross-compile from MSI.

### Step B1: Install cross-compilation toolchain on MSI

```powershell
# Install the cross tool (handles Docker-based cross compilation)
cargo install cross --git https://github.com/cross-rs/cross

# OR: add the target directly (requires linker setup)
rustup target add aarch64-unknown-linux-gnu
```

### Step B2: Build for Pi5 using `cross`

```powershell
cd c:\horaizon-3.0\shua_governor

# Using cross (recommended — handles all linker deps automatically via Docker)
cross build --release --target aarch64-unknown-linux-gnu
```

Output binary: `target/aarch64-unknown-linux-gnu/release/shua_governor`

### Step B3: Deploy binary to Pi5

```powershell
# From MSI
scp target/aarch64-unknown-linux-gnu/release/shua_governor horaizon-pi5:/tmp/shua_governor
```

On Pi5:
```bash
sudo mv /tmp/shua_governor /opt/horaizon/shua_governor/shua_governor
sudo chmod +x /opt/horaizon/shua_governor/shua_governor
```

### Step B4: Deploy config.toml to Pi5

```bash
# On Pi5 (already created directory in TASK-001)
sudo nano /etc/horaizon/governor/config.toml
# Paste the config.toml content from Step A2
```

---

## Part C — systemd Service Unit

### Step C1: Create service file on Pi5

```bash
sudo nano /etc/systemd/system/shua-governor.service
```

Content:
```ini
[Unit]
Description=horAIzon 3.0 — shua_governor HBP v2 broker and process supervisor
After=network.target tailscaled.service
Wants=network.target

[Service]
Type=simple
User=shua
Group=shua
ExecStart=/opt/horaizon/shua_governor/shua_governor
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=shua_governor

# Environment
Environment=RUST_LOG=shua_governor=info
Environment=RUST_BACKTRACE=1

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/etc/horaizon /opt/horaizon /sys/fs/cgroup
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

> [!NOTE]
> `ReadWritePaths=/sys/fs/cgroup` is required for cgroup management.
> `NoNewPrivileges=true` prevents privilege escalation.

### Step C2: Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable shua-governor.service
sudo systemctl start shua-governor.service

# Verify it started
sudo systemctl status shua-governor.service
```

Expected: `Active: active (running)` with JSON log lines visible.

### Step C3: View logs

```bash
journalctl -u shua-governor.service -f --output=json-pretty
```

---

## Part D — Smoke Test From MSI

### Step D1: Verify WebSocket reachability over Tailscale

```powershell
# Install wscat if needed
npm install -g wscat

# Connect from MSI to Pi5 via Tailscale
wscat -c ws://100.67.11.0:7700
```

Expected: WebSocket connection established (no error).

### Step D2: Send a PING frame

Write a small Python test script at `tools/test_hbp_ping.py`:

```python
"""Quick HBP v2 PING test — run from repo root"""
import asyncio
import msgpack
import uuid
import time
import websockets

GOVERNOR_URL = "ws://100.67.11.0:7700"

def make_ping():
    return msgpack.packb({
        "v":   2,
        "t":   4,       # PING
        "id":  str(uuid.uuid4()),
        "mod": "shua.governor",
        "op":  "ping",
        "ts":  int(time.time() * 1000),
        "p":   b"",
    }, use_bin_type=True)

async def test_ping():
    async with websockets.connect(GOVERNOR_URL) as ws:
        await ws.send(make_ping())
        raw = await asyncio.wait_for(ws.recv(), timeout=5.0)
        response = msgpack.unpackb(raw, raw=False)
        assert response["t"] == 5, f"Expected PONG (5), got {response['t']}"
        print(f"[PASS] PONG received: tx_id={response['id']}")

asyncio.run(test_ping())
```

```powershell
pip install msgpack websockets
python tools/test_hbp_ping.py
```

Expected: `[PASS] PONG received: tx_id=...`

---

## Acceptance Criteria

- [ ] `AppConfig::load()` parses the TOML file without error
- [ ] `cargo build --release` produces optimized binary
- [ ] Binary cross-compiles for `aarch64-unknown-linux-gnu`
- [ ] Binary is deployed to `/opt/horaizon/shua_governor/shua_governor` on Pi5
- [ ] `config.toml` is deployed to `/etc/horaizon/governor/config.toml` on Pi5
- [ ] `shua-governor.service` systemd unit starts on boot (`systemctl is-enabled` returns `enabled`)
- [ ] `systemctl status shua-governor` shows `active (running)`
- [ ] `tools/test_hbp_ping.py` passes from MSI over Tailscale

---

## References

- `_architecture/specs/shua_governor/shua_governor_spec.md` — config, systemd, pre-deploy checklist
- `_architecture/contracts/hbp/hbp_v2_spec.md` — HBP PING/PONG spec
- TASK-001 — Pi5 directory structure prerequisite
