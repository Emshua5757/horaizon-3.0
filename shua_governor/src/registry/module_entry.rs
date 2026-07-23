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

/// A registered shua module managed by the Governor with live telemetry
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
    /// Current RSS / cgroup memory footprint in megabytes
    pub ram_mb: Option<f32>,
    /// Current CPU load percentage
    pub cpu_percent: Option<f32>,
    /// Total process uptime in seconds
    pub uptime_s: Option<u64>,
    /// Health status check indicator
    pub health_ok: bool,
    /// Number of auto-restarts following crashes
    pub restart_count: u32,
    /// Most recent error or crash message
    pub last_error: Option<String>,
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
            ram_mb: None,
            cpu_percent: None,
            uptime_s: None,
            health_ok: true,
            restart_count: 0,
            last_error: None,
        }
    }

    #[allow(dead_code)]
    pub fn is_alive(&self) -> bool {
        matches!(self.state, ModuleState::Running | ModuleState::Sleeping)
    }
}
