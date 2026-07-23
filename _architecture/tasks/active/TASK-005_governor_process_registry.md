# TASK-005 — `shua_governor` Process Registry + cgroups v2

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/registry/` |
| **Blocks** | TASK-007 |
| **Prerequisites** | TASK-004 complete (broker compiles) |

---

## Context

Implement the process registry that tracks all shua module processes, and the cgroups v2 manager that enforces RAM limits and enables SIGSTOP/SIGCONT power states. This is the "process supervisor" layer — `shua_governor` starts, stops, sleeps, and wakes every other module through this registry.

Read `_architecture/specs/shua_governor/shua_governor_spec.md` § "Process Registry" before implementing.

---

## Step 1: Implement `src/registry/module_entry.rs`

```rust
use std::path::PathBuf;
use serde::{Deserialize, Serialize};

/// Lifecycle state of a managed shua module process
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ModuleState {
    Running,
    Sleeping,
    Stopped,
    Unknown,
}

/// A registered shua module managed by the Governor
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleEntry {
    /// Module namespace e.g. "shua.resume"
    pub name: String,
    /// Absolute path to the module binary or start script
    pub binary: PathBuf,
    /// Current lifecycle state
    pub state: ModuleState,
    /// OS process ID when running
    pub pid: Option<u32>,
    /// Start on Governor boot?
    pub auto_start: bool,
    /// cgroup path: /sys/fs/cgroup/horaizon/<module_name>
    pub cgroup_path: PathBuf,
    /// Memory limit in MB (written to cgroup memory.max)
    pub ram_limit_mb: Option<u32>,
}

impl ModuleEntry {
    pub fn new(name: &str, binary: PathBuf, auto_start: bool, ram_limit_mb: Option<u32>) -> Self {
        let cgroup_path = PathBuf::from(format!(
            "/sys/fs/cgroup/horaizon/{}",
            name.replace('.', "_")
        ));
        Self {
            name: name.to_string(),
            binary,
            state: ModuleState::Stopped,
            pid: None,
            auto_start,
            cgroup_path,
            ram_limit_mb,
        }
    }

    pub fn is_alive(&self) -> bool {
        matches!(self.state, ModuleState::Running | ModuleState::Sleeping)
    }
}
```

---

## Step 2: Implement `src/registry/cgroup_manager.rs`

```rust
use std::fs;
use std::path::Path;
use anyhow::Result;
use tracing::info;

/// Creates a cgroup v2 subtree for a module and sets memory limits.
/// Requires the Governor process to have write access to /sys/fs/cgroup.
/// On Pi5 with bookworm, cgroups v2 is the default.
pub struct CgroupManager;

impl CgroupManager {
    /// Create the cgroup directory for a module
    pub fn create(cgroup_path: &Path) -> Result<()> {
        if !cgroup_path.exists() {
            fs::create_dir_all(cgroup_path)?;
            info!(
                subsystem = "cgroup_manager",
                path = %cgroup_path.display(),
                "cgroup created"
            );
        }
        Ok(())
    }

    /// Set the memory.max limit for a cgroup (in bytes)
    /// Pass None to set "max" (unlimited)
    pub fn set_memory_limit(cgroup_path: &Path, limit_mb: Option<u32>) -> Result<()> {
        let memory_max = cgroup_path.join("memory.max");
        let value = match limit_mb {
            Some(mb) => format!("{}", mb as u64 * 1024 * 1024),
            None => "max".to_string(),
        };
        fs::write(&memory_max, &value)?;
        info!(
            subsystem = "cgroup_manager",
            path = %memory_max.display(),
            value = %value,
            "memory.max set"
        );
        Ok(())
    }

    /// Move a PID into a cgroup
    pub fn attach_pid(cgroup_path: &Path, pid: u32) -> Result<()> {
        let cgroup_procs = cgroup_path.join("cgroup.procs");
        fs::write(&cgroup_procs, pid.to_string())?;
        info!(
            subsystem = "cgroup_manager",
            path = %cgroup_procs.display(),
            pid = pid,
            "PID attached to cgroup"
        );
        Ok(())
    }

    /// Read current memory usage in bytes
    pub fn current_usage_bytes(cgroup_path: &Path) -> Result<u64> {
        let memory_current = cgroup_path.join("memory.current");
        let content = fs::read_to_string(memory_current)?;
        Ok(content.trim().parse::<u64>()?)
    }
}
```

---

## Step 3: Implement `src/registry/process_manager.rs`

```rust
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use anyhow::Result;
use tracing::{error, info, warn};

use nix::sys::signal::{kill, Signal};
use nix::unistd::Pid;

use crate::registry::module_entry::{ModuleEntry, ModuleState};
use crate::registry::cgroup_manager::CgroupManager;

pub struct ProcessManager {
    modules: Arc<RwLock<HashMap<String, ModuleEntry>>>,
}

impl ProcessManager {
    pub fn new() -> Self {
        Self {
            modules: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Register a module. Called at startup from config.
    pub async fn register(&self, entry: ModuleEntry) {
        let mut modules = self.modules.write().await;
        // Create cgroup on registration
        if let Err(e) = CgroupManager::create(&entry.cgroup_path) {
            warn!(module = %entry.name, error = %e, "Could not create cgroup (may need root)");
        }
        if let Some(limit) = entry.ram_limit_mb {
            if let Err(e) = CgroupManager::set_memory_limit(&entry.cgroup_path, Some(limit)) {
                warn!(module = %entry.name, error = %e, "Could not set memory limit");
            }
        }
        modules.insert(entry.name.clone(), entry);
    }

    /// Start a module process
    pub async fn start(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let entry = modules.get_mut(name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

        if entry.is_alive() {
            info!(module = name, "Already running, skipping start");
            return Ok(());
        }

        let child = tokio::process::Command::new(&entry.binary)
            .spawn()?;

        let pid = child.id().ok_or_else(|| anyhow::anyhow!("Could not get PID"))?;
        entry.pid = Some(pid);
        entry.state = ModuleState::Running;

        // Attach to cgroup
        if let Err(e) = CgroupManager::attach_pid(&entry.cgroup_path, pid) {
            warn!(module = name, pid = pid, error = %e, "Could not attach to cgroup");
        }

        info!(module = name, pid = pid, "Module started");

        // Leak the child handle — module runs independently
        std::mem::forget(child);
        Ok(())
    }

    /// Freeze a module with SIGSTOP
    pub async fn sleep(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let entry = modules.get_mut(name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

        let pid = entry.pid.ok_or_else(|| anyhow::anyhow!("Module has no PID"))?;

        kill(Pid::from_raw(pid as i32), Signal::SIGSTOP)?;
        entry.state = ModuleState::Sleeping;
        info!(module = name, pid = pid, "Module sleeping (SIGSTOP)");
        Ok(())
    }

    /// Resume a module with SIGCONT
    pub async fn wake(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let entry = modules.get_mut(name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

        let pid = entry.pid.ok_or_else(|| anyhow::anyhow!("Module has no PID"))?;

        kill(Pid::from_raw(pid as i32), Signal::SIGCONT)?;
        entry.state = ModuleState::Running;
        info!(module = name, pid = pid, "Module woken (SIGCONT)");
        Ok(())
    }

    /// Get a snapshot of all module states for governor.status
    pub async fn status_snapshot(&self) -> Vec<ModuleEntry> {
        self.modules.read().await.values().cloned().collect()
    }

    /// Check if a module is alive by probing /proc/<pid>/status
    pub async fn refresh_states(&self) {
        let mut modules = self.modules.write().await;
        for entry in modules.values_mut() {
            if let Some(pid) = entry.pid {
                let proc_path = format!("/proc/{pid}/status");
                if !std::path::Path::new(&proc_path).exists() {
                    entry.state = ModuleState::Stopped;
                    entry.pid = None;
                    warn!(module = %entry.name, "Module process no longer exists");
                }
            }
        }
    }
}
```

---

## Step 4: Wire ProcessManager into `dispatcher.rs`

Update `src/broker/dispatcher.rs` to hold an `Arc<ProcessManager>` and handle the real `governor.status`, `governor.module.wake`, and `governor.module.sleep` operations.

Replace the stub `handle_governor` with a real implementation:

```rust
use crate::registry::process_manager::ProcessManager;
use crate::registry::module_entry::ModuleEntry;

pub struct Dispatcher {
    pub process_manager: Arc<ProcessManager>,
}

impl Dispatcher {
    pub fn new(process_manager: Arc<ProcessManager>) -> Self {
        Self { process_manager }
    }

    async fn handle_governor(&self, frame: HbpFrame) -> Option<HbpFrame> {
        match frame.op.as_str() {
            "ping" => Some(HbpFrame::pong()),

            "status" => {
                let modules = self.process_manager.status_snapshot().await;
                let payload_data = serde_json::json!({
                    "modules": modules,
                    "ollama": { "loaded_model": null, "ram_mb": null }  // TODO TASK-006
                });
                let payload = HbpFrame::encode_payload(&payload_data).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
            }

            "module.wake" => {
                #[derive(serde::Deserialize)]
                struct Req { module: String }
                match frame.decode_payload::<Req>() {
                    Ok(req) => match self.process_manager.wake(&req.module).await {
                        Ok(_)  => Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, vec![])),
                        Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &e.to_string())),
                    },
                    Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_MALFORMED: {e}"))),
                }
            }

            "module.sleep" => {
                #[derive(serde::Deserialize)]
                struct Req { module: String }
                match frame.decode_payload::<Req>() {
                    Ok(req) => match self.process_manager.sleep(&req.module).await {
                        Ok(_)  => Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, vec![])),
                        Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &e.to_string())),
                    },
                    Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_MALFORMED: {e}"))),
                }
            }

            other => {
                Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, "ERR_UNKNOWN_OP"))
            }
        }
    }
}
```

---

## Step 5: Verify

```powershell
cd c:\horaizon-3.0\shua_governor
cargo build
cargo test
```

---

## Acceptance Criteria

- [ ] `ModuleEntry`, `ModuleState` structs compile with `serde` derives
- [ ] `ProcessManager::register()` creates cgroup directory (or warns if no root — expected on Windows dev)
- [ ] `ProcessManager::sleep()` sends SIGSTOP, sets state to `Sleeping`
- [ ] `ProcessManager::wake()` sends SIGCONT, sets state to `Running`
- [ ] `ProcessManager::status_snapshot()` returns vec of all registered modules
- [ ] `governor.status` HBP operation returns real module states
- [ ] `governor.module.wake` and `governor.module.sleep` work over WebSocket
- [ ] `cargo build` — no errors

---

## References

- `_architecture/specs/shua_governor/shua_governor_spec.md` — Process Registry section
- `_architecture/contracts/hbp/hbp_v2_spec.md` — `governor.module.wake`, `governor.module.sleep` schemas
