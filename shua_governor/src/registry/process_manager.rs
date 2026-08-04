use anyhow::Result;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::{mpsc, Mutex, RwLock};
use tracing::{error, info, warn};

#[cfg(unix)]
use nix::sys::signal::{kill, Signal};
#[cfg(unix)]
use nix::unistd::Pid;

use crate::registry::cgroup_manager::CgroupManager;
use crate::registry::module_entry::{ModuleEntry, ModuleState};

pub struct ProcessManager {
    pub modules: Arc<RwLock<HashMap<String, ModuleEntry>>>,
    pub ipc_port: u16,
    pub client_replies: Arc<Mutex<HashMap<String, mpsc::UnboundedSender<Vec<u8>>>>>,
}

impl ProcessManager {
    pub fn new(ipc_port: u16) -> Self {
        Self {
            modules: Arc::new(RwLock::new(HashMap::new())),
            ipc_port,
            client_replies: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    #[allow(dead_code)]
    pub fn with_default_port() -> Self {
        Self::new(7701)
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
    pub fn start<'a>(
        &'a self,
        name: &'a str,
    ) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<()>> + Send + 'a>> {
        Box::pin(async move {
            let mut modules = self.modules.write().await;
            let entry = modules
                .get_mut(name)
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

            let sanitized = name.replace('.', "_");
            let candidate_binaries = vec![
                entry.binary.clone(),
                PathBuf::from(format!(
                    "/home/shua/horaizon-3.0/target/release/{sanitized}"
                )),
                PathBuf::from(format!(
                    "/home/shua/horaizon-3.0/{sanitized}/target/release/{sanitized}"
                )),
                PathBuf::from(format!("../target/release/{sanitized}")),
                PathBuf::from(format!("../{sanitized}/target/release/{sanitized}")),
                PathBuf::from(format!("./target/release/{sanitized}")),
            ];

            let effective_binary = candidate_binaries
                .into_iter()
                .find(|p| p.exists())
                .unwrap_or_else(|| entry.binary.clone());

            info!(
                subsystem = "process_manager",
                module = name,
                binary = %effective_binary.display(),
                ipc_port = self.ipc_port,
                "Spawning module process with IPC environment injection"
            );

            let mut cmd = tokio::process::Command::new(&effective_binary);

            // Inject Governor IPC environment variables for submodules
            cmd.env("SHUA_GOVERNOR_PID", std::process::id().to_string());
            cmd.env("SHUA_GOVERNOR_IPC_PORT", self.ipc_port.to_string());

            if name == "ollama" {
                cmd.arg("serve");
                cmd.env("OLLAMA_NUM_THREADS", "3");
                cmd.env("OLLAMA_NUM_PARALLEL", "1");
                cmd.env("OLLAMA_KEEP_ALIVE", "-1");
                info!(
                    subsystem = "process_manager",
                    num_threads = 3,
                    num_parallel = 1,
                    "Configured thermal thread budget for Ollama subprocess"
                );
            }

            let child = cmd.spawn()?;
            let pid = child
                .id()
                .ok_or_else(|| anyhow::anyhow!("Could not get PID"))?;

            let child_arc = Arc::new(Mutex::new(child));
            entry.pid = Some(pid);
            entry.state = ModuleState::Running;
            entry.child_handle = Some(Arc::clone(&child_arc));

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
                "Module process started successfully — watchdog attached"
            );

            // Spawn background watchdog monitoring child process exit
            let modules_clone = Arc::clone(&self.modules);
            let client_replies_clone = Arc::clone(&self.client_replies);
            let name_string = name.to_string();
            let ipc_port_val = self.ipc_port;

            tokio::spawn(async move {
                let mut guard = child_arc.lock().await;
                let exit_res = guard.wait().await;

                let mut modules = modules_clone.write().await;
                if let Some(entry) = modules.get_mut(&name_string) {
                    let was_intentional = entry.intentional_stop;
                    entry.state = ModuleState::Stopped;
                    entry.pid = None;
                    entry.ipc_tx = None;
                    entry.intentional_stop = false;

                    let exit_msg = match exit_res {
                        Ok(status) => format!("Exited with status: {status}"),
                        Err(e) => format!("Wait error: {e}"),
                    };

                    if was_intentional {
                        info!(
                            subsystem = "process_manager",
                            module = %name_string,
                            exit_status = %exit_msg,
                            "Module process stopped cleanly per governor/user request"
                        );
                    } else {
                        entry.restart_count += 1;
                        entry.last_error = Some(exit_msg.clone());

                        warn!(
                            subsystem = "process_manager",
                            module = %name_string,
                            exit_status = %exit_msg,
                            restart_count = entry.restart_count,
                            "Module process exited unexpectedly — state reset to Stopped"
                        );

                        let auto_restart = entry.auto_start && entry.restart_count <= 3;
                        if auto_restart {
                            info!(
                                subsystem = "process_manager",
                                module = %name_string,
                                restart_count = entry.restart_count,
                                "Auto-restarting module process in 2 seconds"
                            );
                            let modules_arc_again = Arc::clone(&modules_clone);
                            let client_replies_arc_again = Arc::clone(&client_replies_clone); // <-- this line was missing
                            let name_again = name_string.clone();
                            tokio::spawn(async move {
                                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
                                let pm_dummy = ProcessManager {
                                    modules: modules_arc_again,
                                    ipc_port: ipc_port_val,
                                    client_replies: client_replies_arc_again,
                                };
                                let _ = pm_dummy.start(&name_again).await;
                            });
                        } else if entry.restart_count > 3 {
                            error!(
                                subsystem = "process_manager",
                                module = %name_string,
                                restart_count = entry.restart_count,
                                "Module exceeded max auto-restart threshold (3) — halting auto-restart"
                            );
                        }
                    }
                }
            });

            Ok(())
        })
    }

    fn find_key(
        modules: &std::collections::HashMap<String, ModuleEntry>,
        name: &str,
    ) -> Option<String> {
        if modules.contains_key(name) {
            return Some(name.to_string());
        }
        let dot_variant = name.replace('_', ".");
        if modules.contains_key(&dot_variant) {
            return Some(dot_variant);
        }
        let underscore_variant = name.replace('.', "_");
        if modules.contains_key(&underscore_variant) {
            return Some(underscore_variant);
        }
        None
    }

    /// Freeze a module with SIGSTOP
    pub async fn sleep(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let key = Self::find_key(&modules, name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;
        let entry = modules.get_mut(&key).unwrap();

        if let Some(pid) = entry.pid {
            #[cfg(unix)]
            {
                let _ = kill(Pid::from_raw(pid as i32), Signal::SIGSTOP);
            }
            info!(
                subsystem = "process_manager",
                module = %key,
                pid = pid,
                "Module power state changed to Sleeping (SIGSTOP)"
            );
        } else {
            info!(
                subsystem = "process_manager",
                module = %key,
                "Module power state changed to Sleeping"
            );
        }

        entry.state = ModuleState::Sleeping;
        entry.cpu_percent = Some(0.0);
        Ok(())
    }

    /// Resume a module with SIGCONT or start if not spawned
    pub async fn wake(&self, name: &str) -> Result<()> {
        let key = {
            let modules = self.modules.read().await;
            match Self::find_key(&modules, name) {
                Some(k) => k,
                None => {
                    let keys: Vec<String> = modules.keys().cloned().collect();
                    warn!(subsystem = "process_manager", target_name = %name, available_keys = ?keys, "ERR_UNKNOWN_MODULE lookup failed");
                    return Err(anyhow::anyhow!(
                        "ERR_UNKNOWN_MODULE: {name} (available: {keys:?})"
                    ));
                }
            }
        };

        let has_pid = {
            let modules = self.modules.read().await;
            modules.get(&key).and_then(|e| e.pid).is_some()
        };

        if has_pid {
            let mut modules = self.modules.write().await;
            if let Some(entry) = modules.get_mut(&key) {
                if let Some(pid) = entry.pid {
                    #[cfg(unix)]
                    {
                        let _ = kill(Pid::from_raw(pid as i32), Signal::SIGCONT);
                    }
                    info!(
                        subsystem = "process_manager",
                        module = %key,
                        pid = pid,
                        "Module power state changed to Running (SIGCONT)"
                    );
                    entry.state = ModuleState::Running;
                }
            }
            Ok(())
        } else {
            info!(
                subsystem = "process_manager",
                module = %key,
                "Module has no PID attached — launching process via start()"
            );
            self.start(&key).await
        }
    }

    /// Terminate a module process with SIGTERM/SIGKILL to free RAM budget
    pub async fn stop(&self, name: &str) -> Result<()> {
        let mut modules = self.modules.write().await;
        let key = Self::find_key(&modules, name)
            .ok_or_else(|| anyhow::anyhow!("ERR_UNKNOWN_MODULE: {name}"))?;
        let entry = modules.get_mut(&key).unwrap();

        entry.intentional_stop = true;
        if let Some(pid) = entry.pid {
            #[cfg(unix)]
            {
                let _ = kill(Pid::from_raw(pid as i32), Signal::SIGTERM);
            }
            info!(
                subsystem = "process_manager",
                module = %key,
                pid = pid,
                "Terminated module process to release RAM budget (SIGTERM)"
            );
        }

        entry.pid = None;
        entry.state = ModuleState::Stopped;
        entry.ram_mb = Some(0.0);
        entry.cpu_percent = Some(0.0);
        Ok(())
    }

    fn read_proc_rss_mb(pid: u32) -> Option<f32> {
        let path = format!("/proc/{pid}/status");
        if let Ok(content) = std::fs::read_to_string(path) {
            for line in content.lines() {
                if line.starts_with("VmRSS:") {
                    let parts: Vec<&str> = line.split_whitespace().collect();
                    if parts.len() >= 2 {
                        if let Ok(kb) = parts[1].parse::<f32>() {
                            return Some(kb / 1024.0);
                        }
                    }
                }
            }
        }
        None
    }

    /// Get a snapshot of all module states with live telemetry for governor.status
    pub async fn status_snapshot(&self) -> Vec<ModuleEntry> {
        let modules = self.modules.read().await;
        let mut list = Vec::new();
        for entry in modules.values() {
            let mut snapshot = entry.clone();
            if snapshot.is_alive() {
                let mut measured_ram = None;
                // 1. Measure real memory from Linux cgroup v2 memory.current
                if let Ok(bytes) = CgroupManager::current_usage_bytes(&snapshot.cgroup_path) {
                    if bytes > 0 {
                        measured_ram = Some((bytes as f32) / (1024.0 * 1024.0));
                    }
                }
                // 2. Measure real memory from Linux /proc/<pid>/status VmRSS
                if measured_ram.is_none() {
                    if let Some(pid) = snapshot.pid {
                        measured_ram = Self::read_proc_rss_mb(pid);
                    }
                }
                snapshot.ram_mb = measured_ram.or(snapshot.ram_mb);
            } else {
                snapshot.ram_mb = Some(0.0);
                snapshot.cpu_percent = Some(0.0);
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
        let pm = ProcessManager::new(7701);
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
