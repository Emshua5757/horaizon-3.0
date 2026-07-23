// shua_governor — Module Registry & Lifecycle Types
// Phase 10: V4 SDUI Rewrite | Architecture spec: _architecture/governor/phase10-governor-spec.md

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

/// Represents the physical execution lifecycle state of a managed microservice.
///
/// Rust algebraic enum layout: Variants carry typed payloads directly in memory,
/// avoiding external state wrappers or nullable status fields.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ModuleState {
    /// Module binary is dormant and not running in cgroups.
    Stopped,

    /// Module process has been spawned; awaiting HTTP GET /health 200 OK verification.
    Starting,

    /// Module is healthy, responding to health checks, and actively serving proxy traffic.
    Active,

    /// Module execution is paused via cgroups SIGSTOP/freeze (zero CPU consumption).
    Frozen,

    /// Module crashed unexpectedly. Holds the OS process exit code (e.g., exit_code: 137 for OOM killed).
    Crashed { exit_code: i32 },

    /// Module failed health checks or crashed; supervisor is applying exponential backoff retry.
    Backoff { attempt: u32 },
}

/// In-memory metadata and telemetry record for a registered HorAIzon module.
///
/// Example Instance (shua_diary):
/// ```rust
/// ModuleEntry {
///     id: String::from("shua_diary"),
///     display_name: String::from("Shua Diary"),
///     port: 3001,
///     health_endpoint: String::from("http://127.0.0.1:3001/health"),
///     state: ModuleState::Active,
///     pid: Some(12450),
/// }
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleEntry {
    /// Unique wire key matching `schemas/module_registry.json` (e.g., "shua_diary")
    pub id: String,

    /// IP address or hostname of the node running this module.
    /// Defaults to "127.0.0.1" (Pi 5 loopback) for all local microservices.
    /// Override to a Tailscale IP (e.g., "100.90.83.12") for remote offload nodes.
    #[serde(default = "default_host")]
    pub host: String,

    /// Human-readable display name for SDUI dashboard cards (e.g., "Shua Diary")
    pub display_name: String,

    /// Icon identifier for SDUI cards (e.g., "book", "chat")
    #[serde(default)]
    pub icon: String,

    /// Client navigation route (e.g., "/diary", "/comms")
    #[serde(default)]
    pub route: String,

    /// Internal loopback TCP port assigned to the module microservice (e.g., 3001)
    pub port: u16,

    /// Upstream HTTP health check URL probed by the supervisor loop
    pub health_endpoint: String,

    /// Shell execution command to start the module microservice (e.g., "npm run dev", "uv run main.py", "./bin")
    #[serde(default = "default_exec_cmd")]
    pub exec_cmd: String,

    /// Current execution state in the governor supervisor state machine
    #[serde(default = "default_state")]
    pub state: ModuleState,

    /// Operating system Process ID (PID) assigned by Linux when running (`None` if stopped)
    #[serde(default)]
    pub pid: Option<u32>,

    /// Live RSS RAM consumption in bytes, updated by supervisor loop every 2s via /proc/{pid}/status.
    /// Zero when module is stopped. O(1) read from in-memory field — never blocks the dashboard route.
    #[serde(default)]
    pub ram_bytes: u64,

    /// True after the module called POST /api/internal/ready/:id, confirming its HTTP server is bound.
    /// False = Governor waiting for health-check polling (legacy fallback). Cleared on Stop/Kill.
    #[serde(default)]
    pub ready_callback: bool,

    /// Per-module CPU utilisation (0.0–100.0), updated by supervisor every 2s
    /// via /proc/{pid}/stat jiffy diffing. Zero when module is stopped.
    #[serde(default)]
    pub cpu_pct: f32,

    /// Optional custom shimmer loading style (e.g. "classic", "terminal", "chat")
    #[serde(default = "default_shimmer_style")]
    pub shimmer_style: String,

    /// Dynamic runtime environment variables injected into the process when spawned via cgroups.
    #[serde(default)]
    pub env_vars: HashMap<String, String>,
}

fn default_host() -> String {
    "127.0.0.1".to_string()
}

fn default_shimmer_style() -> String {
    "classic".to_string()
}

fn default_state() -> ModuleState {
    ModuleState::Stopped
}

fn default_exec_cmd() -> String {
    "npm run dev".to_string()
}

/// Shared, thread-safe module registry type alias.
///
/// Uses `Arc` for O(1) atomic ref-count sharing across async tasks, and `RwLock`
/// for concurrent reader access with exclusive atomic writer locks.
pub type ModuleRegistry = Arc<RwLock<HashMap<String, ModuleEntry>>>;

/// Constructor function returning a new, empty thread-safe ModuleRegistry.
pub fn new_registry() -> ModuleRegistry {
    Arc::new(RwLock::new(HashMap::new()))
}

// ──────────────────────────────────────────────────────────────────────────────
// System-Level Telemetry Snapshot
// ──────────────────────────────────────────────────────────────────────────────

/// System-wide telemetry updated by the supervisor loop every 2 seconds.
/// Lives in AppState behind an Arc<RwLock<>> so both the supervisor (writer)
/// and SSE/dashboard handlers (readers) access it concurrently with O(1) clones.
#[derive(Debug, Clone, Default)]
pub struct SystemMetrics {
    /// System-wide CPU utilisation (0.0–100.0) — derived from /proc/stat jiffie diff.
    pub cpu_pct: f32,

    /// RPi 5 CPU die temperature in °C — read from thermal_zone0, no root needed.
    pub temp_c: f32,

    /// Total RSS RAM across governor + all running modules in MB.
    pub ram_mb: f64,

    /// Fraction of the 8 GB Pi 5 RAM ceiling consumed (0.0–1.0).
    pub ram_pct: f64,
}

pub type SharedSystemMetrics = Arc<RwLock<SystemMetrics>>;

/// Constructor returning zeroed system metrics behind a shared lock.
pub fn new_system_metrics() -> SharedSystemMetrics {
    Arc::new(RwLock::new(SystemMetrics::default()))
}

/// Practice exhaustive pattern matching over ModuleState.
pub fn display_state(state: &ModuleState) -> String {
    match state {
        ModuleState::Stopped => "STOPPED".to_string(),
        ModuleState::Starting => "STARTING".to_string(),
        ModuleState::Active => "ACTIVE".to_string(),
        ModuleState::Frozen => "FROZEN".to_string(),
        ModuleState::Crashed { exit_code } => format!("CRASHED (exit code: {})", exit_code),
        ModuleState::Backoff { attempt } => format!("BACKOFF (attempt: {})", attempt),
    }
}

/// Asynchronously reads `schemas/module_registry.json` and parses entries into ModuleEntry structs.
pub async fn load_from_json(
    path: &str,
) -> Result<Vec<ModuleEntry>, Box<dyn std::error::Error + Send + Sync>> {
    let content = tokio::fs::read_to_string(path).await?;

    #[derive(Deserialize)]
    struct RegistryManifest {
        modules: Vec<ModuleEntry>,
    }

    let manifest: RegistryManifest = serde_json::from_str(&content)?;
    Ok(manifest.modules)
}
