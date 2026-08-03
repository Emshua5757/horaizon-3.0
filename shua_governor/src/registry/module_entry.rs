use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use serde::{Deserialize, Serialize};
use tokio::sync::{mpsc, oneshot, Mutex};

use crate::mcp::McpToolSchema;

/// In-flight MCP tool call oneshot senders keyed by UUID request ID
pub type PendingCallMap = Arc<Mutex<HashMap<String, oneshot::Sender<serde_json::Value>>>>;

/// Lifecycle state of a managed shua module process
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ModuleState {
    Running,
    IpcConnected,
    Sleeping,
    Stopped,
    Unknown,
}

/// A registered shua module managed by the Governor with live telemetry and IPC capabilities
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

    /// OS child process handle enabling watchdog monitoring
    #[serde(skip)]
    pub child_handle: Option<Arc<Mutex<tokio::process::Child>>>,

    /// IPC write channel to module WebSocket connection (None if disconnected)
    #[serde(skip)]
    pub ipc_tx: Option<mpsc::UnboundedSender<String>>,

    /// MCP tool schemas self-reported at registration
    #[serde(skip)]
    pub tools: Vec<McpToolSchema>,

    /// Scope tag declared at registration (e.g. "code", "diary")
    #[serde(skip)]
    pub module_scope: Option<String>,

    /// Semver string reported in registration manifest
    #[serde(skip)]
    pub manifest_version: Option<String>,

    /// In-flight MCP tool call oneshot senders keyed by UUID request ID
    #[serde(skip)]
    pub pending_calls: PendingCallMap,
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
            child_handle: None,
            ipc_tx: None,
            tools: Vec::new(),
            module_scope: None,
            manifest_version: None,
            pending_calls: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    #[allow(dead_code)]
    pub fn is_alive(&self) -> bool {
        matches!(self.state, ModuleState::Running | ModuleState::IpcConnected | ModuleState::Sleeping)
    }
}
