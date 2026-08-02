use std::env;
use std::time::Duration;
use tokio::time::sleep;

/// Runtime execution mode auto-detected from environment
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionMode {
    /// Standalone mode (run directly by human user on Windows or CLI). Zero network scanning.
    Standalone,
    /// Managed subprocess mode (spawned by shua_governor). Linked lifetime & active HBP IPC connection.
    ManagedSubprocess { parent_pid: u32, ipc_port: u16 },
}

pub struct ParentLink;

impl ParentLink {
    /// Detects execution mode by inspecting environment for SHUA_GOVERNOR_PID and SHUA_GOVERNOR_IPC_PORT
    pub fn detect_execution_mode() -> ExecutionMode {
        let pid_var = env::var("SHUA_GOVERNOR_PID").ok();
        let port_var = env::var("SHUA_GOVERNOR_IPC_PORT").ok();

        match (pid_var, port_var) {
            (Some(pid_str), Some(port_str)) => {
                if let (Ok(parent_pid), Ok(ipc_port)) = (pid_str.parse::<u32>(), port_str.parse::<u16>()) {
                    ExecutionMode::ManagedSubprocess { parent_pid, ipc_port }
                } else {
                    ExecutionMode::Standalone
                }
            }
            _ => ExecutionMode::Standalone,
        }
    }

    /// Spawns a background task monitoring parent_pid. If parent process terminates, self-terminates.
    pub fn spawn_parent_death_monitor(parent_pid: u32) {
        tokio::spawn(async move {
            loop {
                sleep(Duration::from_secs(1)).await;
                if !is_process_alive(parent_pid) {
                    eprintln!(
                        "Parent governor process (PID {}) terminated. Self-terminating shua_code_visualizer.",
                        parent_pid
                    );
                    std::process::exit(0);
                }
            }
        });
    }
}

/// Checks if a process PID is currently alive on OS
#[cfg(target_os = "windows")]
fn is_process_alive(pid: u32) -> bool {
    use windows_sys::Win32::Foundation::CloseHandle;
    use windows_sys::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION};

    unsafe {
        let handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if handle == 0 {
            false
        } else {
            CloseHandle(handle);
            true
        }
    }
}

#[cfg(not(target_os = "windows"))]
fn is_process_alive(pid: u32) -> bool {
    unsafe { libc::kill(pid as libc::pid_t, 0) == 0 }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_standalone_mode_when_env_unset() {
        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(mode, ExecutionMode::Standalone);
    }

    #[test]
    fn test_detect_managed_mode_when_env_set() {
        env::set_var("SHUA_GOVERNOR_PID", "12345");
        env::set_var("SHUA_GOVERNOR_IPC_PORT", "7700");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(
            mode,
            ExecutionMode::ManagedSubprocess {
                parent_pid: 12345,
                ipc_port: 7700
            }
        );

        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");
    }
}
