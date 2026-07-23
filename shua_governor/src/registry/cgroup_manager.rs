use std::fs;
use std::path::Path;
use anyhow::Result;
use tracing::{info, warn};

/// Creates a cgroup v2 subtree for a module and sets memory limits.
/// Requires the Governor process to have write access to /sys/fs/cgroup.
/// On Pi5 with Debian Bookworm, cgroups v2 is the default hierarchy.
pub struct CgroupManager;

impl CgroupManager {
    /// Create the cgroup directory for a module
    pub fn create(cgroup_path: &Path) -> Result<()> {
        if cfg!(target_os = "linux") {
            if !cgroup_path.exists() {
                fs::create_dir_all(cgroup_path)?;
                info!(
                    subsystem = "cgroup_manager",
                    path = %cgroup_path.display(),
                    "cgroup v2 directory created"
                );
            }
        } else {
            info!(
                subsystem = "cgroup_manager",
                path = %cgroup_path.display(),
                "[dev-stub] cgroup creation skipped (non-linux)"
            );
        }
        Ok(())
    }

    /// Set the memory.max limit for a cgroup (in bytes)
    /// Pass None to set "max" (unlimited)
    pub fn set_memory_limit(cgroup_path: &Path, limit_mb: Option<u32>) -> Result<()> {
        if cfg!(target_os = "linux") {
            let memory_max = cgroup_path.join("memory.max");
            let value = match limit_mb {
                Some(mb) => format!("{}", mb as u64 * 1024 * 1024),
                None => "max".to_string(),
            };
            if let Err(e) = fs::write(&memory_max, &value) {
                warn!(
                    subsystem = "cgroup_manager",
                    path = %memory_max.display(),
                    error = %e,
                    "Failed to set memory.max limit"
                );
            } else {
                info!(
                    subsystem = "cgroup_manager",
                    path = %memory_max.display(),
                    value = %value,
                    "cgroup memory.max limit applied"
                );
            }
        } else {
            info!(
                subsystem = "cgroup_manager",
                limit_mb = ?limit_mb,
                "[dev-stub] memory.max limit skipped (non-linux)"
            );
        }
        Ok(())
    }

    /// Move a PID into a cgroup
    #[allow(dead_code)]
    pub fn attach_pid(cgroup_path: &Path, pid: u32) -> Result<()> {
        if cfg!(target_os = "linux") {
            let cgroup_procs = cgroup_path.join("cgroup.procs");
            fs::write(&cgroup_procs, pid.to_string())?;
            info!(
                subsystem = "cgroup_manager",
                path = %cgroup_procs.display(),
                pid = pid,
                "PID attached to cgroup"
            );
        } else {
            info!(
                subsystem = "cgroup_manager",
                pid = pid,
                "[dev-stub] PID cgroup attachment skipped (non-linux)"
            );
        }
        Ok(())
    }

    /// Read current memory usage in bytes
    #[allow(dead_code)]
    pub fn current_usage_bytes(cgroup_path: &Path) -> Result<u64> {
        if cfg!(target_os = "linux") {
            let memory_current = cgroup_path.join("memory.current");
            if memory_current.exists() {
                let content = fs::read_to_string(memory_current)?;
                return Ok(content.trim().parse::<u64>()?);
            }
        }
        Ok(0)
    }
}
