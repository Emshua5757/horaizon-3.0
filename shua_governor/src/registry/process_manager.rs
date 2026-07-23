use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use anyhow::Result;
use tracing::{info, warn};

#[cfg(unix)]
use nix::sys::signal::{kill, Signal};
#[cfg(unix)]
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
        info!(
            subsystem = "process_manager",
            module = %entry.name,
            binary = %entry.binary.display(),
            ram_limit_mb = ?entry.ram_limit_mb,
            "Registering module entry"
        );

        if let Err(e) = CgroupManager::create(&entry.cgroup_path) {
            warn!(
                subsystem = "process_manager",
                module = %entry.name,
                error = %e,
                "Could not create cgroup"
            );
        }

        if let Some(limit) = entry.ram_limit_mb {
            if let Err(e) = CgroupManager::set_memory_limit(&entry.cgroup_path, Some(limit)) {
                warn!(
                    subsystem = "process_manager",
                    module = %entry.name,
                    error = %e,
                    "Could not set cgroup memory limit"
                );
            }
        }

        modules.insert(entry.name.clone(), entry);
    }

    /// Start a module process
    #[allow(dead_code)]
    pub fn start<'a>(&'a self, name: &'a str) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<()>> + Send + 'a>> {
        Box::pin(async move {
            let mut modules = self.modules.write().await;
            let entry = modules.get_mut(name)
                .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

            if entry.is_alive() {
                info!(
                    subsystem = "process_manager",
                    module = name,
                    state = ?entry.state,
                    "Module already running, skipping start"
                );
                return Ok(());
            }

            info!(
                subsystem = "process_manager",
                module = name,
                binary = %entry.binary.display(),
                "Spawning module process"
            );

            let child = tokio::process::Command::new(&entry.binary).spawn()?;
            let pid = child.id().ok_or_else(|| anyhow::anyhow!("Could not get PID"))?;

            entry.pid = Some(pid);
            entry.state = ModuleState::Running;

            if let Err(e) = CgroupManager::attach_pid(&entry.cgroup_path, pid) {
                warn!(
                    subsystem = "process_manager",
                    module = name,
                    pid = pid,
                    error = %e,
                    "Could not attach PID to cgroup"
                );
            }

            info!(
                subsystem = "process_manager",
                module = name,
                pid = pid,
                "Module process started successfully"
            );

            // Disown child handle — module process runs independently
            std::mem::forget(child);
            Ok(())
        })
    }

    /// Freeze a module with SIGSTOP
    pub async fn sleep(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let entry = modules.get_mut(name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

        let pid = entry.pid.ok_or_else(|| anyhow::anyhow!("Module has no PID"))?;

        #[cfg(unix)]
        {
            kill(Pid::from_raw(pid as i32), Signal::SIGSTOP)?;
        }

        entry.state = ModuleState::Sleeping;
        info!(
            subsystem = "process_manager",
            module = name,
            pid = pid,
            "Module power state changed to Sleeping (SIGSTOP)"
        );
        Ok(())
    }

    /// Resume a module with SIGCONT
    pub async fn wake(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let entry = modules.get_mut(name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;

        let pid = entry.pid.ok_or_else(|| anyhow::anyhow!("Module has no PID"))?;

        #[cfg(unix)]
        {
            kill(Pid::from_raw(pid as i32), Signal::SIGCONT)?;
        }

        entry.state = ModuleState::Running;
        info!(
            subsystem = "process_manager",
            module = name,
            pid = pid,
            "Module power state changed to Running (SIGCONT)"
        );
        Ok(())
    }

    /// Get a snapshot of all module states with live telemetry for governor.status
    pub async fn status_snapshot(&self) -> Vec<ModuleEntry> {
        let modules = self.modules.read().await;
        let mut list = Vec::new();
        for entry in modules.values() {
            let mut snapshot = entry.clone();
            if snapshot.is_alive() {
                if let Ok(bytes) = CgroupManager::current_usage_bytes(&snapshot.cgroup_path) {
                    if bytes > 0 {
                        snapshot.ram_mb = Some((bytes as f32) / (1024.0 * 1024.0));
                    }
                }
            }
            list.push(snapshot);
        }
        list
    }

    /// Check if a module is alive by probing /proc/<pid>/status
    #[allow(dead_code)]
    pub async fn refresh_states(&self) {
        let mut modules = self.modules.write().await;
        for entry in modules.values_mut() {
            if let Some(pid) = entry.pid {
                let proc_path = format!("/proc/{pid}/status");
                if cfg!(target_os = "linux") && !std::path::Path::new(&proc_path).exists() {
                    entry.state = ModuleState::Stopped;
                    entry.pid = None;
                    warn!(
                        subsystem = "process_manager",
                        module = %entry.name,
                        pid = pid,
                        "Module process no longer exists (clean exit or OOM crash)"
                    );
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[tokio::test]
    async fn test_process_manager_register_and_snapshot() {
        let pm = ProcessManager::new();
        let entry = ModuleEntry::new(
            "shua.resume",
            PathBuf::from("/usr/bin/true"),
            true,
            Some(128),
        );
        pm.register(entry).await;

        let snapshot = pm.status_snapshot().await;
        assert_eq!(snapshot.len(), 1);
        assert_eq!(snapshot[0].name, "shua.resume");
        assert_eq!(snapshot[0].state, ModuleState::Stopped);
    }
}
