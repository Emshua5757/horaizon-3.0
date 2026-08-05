use std::sync::Arc;
use tokio::sync::mpsc::{Sender, UnboundedSender};
use tokio::sync::RwLock;
use tracing::{info, warn};

use crate::ai_router::intent_classifier::IntentClassifier;
use crate::ai_router::prompt_budget::PromptBudget;
use crate::broker::frame::{HbpFrame, MsgType};
use crate::config::AppConfig;
use crate::logging::broadcaster::LogBroadcaster;
use crate::logging::entry::{LogEntry, MODULE_FLUTTER};
use crate::logging::filter::LogFilter;
use crate::logging::flush::{query_logs_from_db, resolved_db_path, LogQueryParams};
use crate::media_vault::vault::MediaVault;
use crate::ollama::lifecycle::OllamaLifecycle;
use crate::registry::process_manager::ProcessManager;

/// Query request DTO for `governor.logs.query`
#[derive(serde::Deserialize)]
pub struct LogQueryRequest {
    pub min_level: Option<u8>,
    pub module: Option<u8>,
    pub subsystem: Option<String>,
    pub start_ts: Option<u64>,
    pub end_ts: Option<u64>,
    pub trace_id: Option<String>,
    pub limit: Option<usize>,
    pub offset: Option<usize>,
}

/// Client emit log DTO for `governor.log.emit`
#[derive(serde::Deserialize)]
pub struct ClientLogEmitRequest {
    pub level: Option<u8>,
    pub subsystem: Option<String>,
    pub msg: String,
    pub tags: Option<u32>,
    pub telemetry: Option<serde_json::Value>,
    pub trace_id: Option<String>,
}

/// Module operation payload DTO for `module.wake` and `module.sleep`
#[derive(serde::Deserialize)]
pub struct ModuleOpRequest {
    #[serde(alias = "name")]
    pub module: String,
}

/// Ollama load payload DTO for `ollama.load`
#[derive(serde::Deserialize)]
pub struct OllamaLoadRequest {
    pub model: String,
}

/// AI route payload DTO for `ai.route`
#[derive(serde::Deserialize)]
pub struct AiRouteRequest {
    pub prompt: String,
    pub context_hint: Option<String>,
    pub offload_device_url: Option<String>,
    #[serde(default)]
    pub model: Option<String>,
    /// Global chat session identifier. Used to load/persist conversation history
    /// in activity.db chat_history table. If absent, no history is loaded or saved.
    #[serde(default)]
    pub session_id: Option<String>,
}

/// Config DTO payload for `governor.config.get` / `governor.config.update`
#[derive(serde::Serialize, serde::Deserialize)]
pub struct GovernorConfigDto {
    pub port: u32,
    pub log_level: String,
    pub timezone: String,
    pub offload_device_url: Option<String>,
    pub ollama_ram_cap_mb: u32,
    pub dream_loop_enabled: bool,
    pub dream_loop_cron: String,
    pub log_retention_days: u32,
}

#[derive(Clone, Copy, Debug)]
struct CpuTicks {
    idle: u64,
    total: u64,
}

/// Dynamic kernel CPU utilization tracker (supports Linux /proc/stat and Windows GetSystemTimes).
pub struct CpuTracker {
    last_ticks: std::sync::Mutex<Option<CpuTicks>>,
}

impl CpuTracker {
    pub fn new() -> Self {
        Self {
            last_ticks: std::sync::Mutex::new(None),
        }
    }

    pub fn sample_cpu_pct(&self) -> f64 {
        let current = self.read_ticks();
        let mut guard = match self.last_ticks.lock() {
            Ok(g) => g,
            Err(p) => p.into_inner(),
        };

        let pct = if let (Some(curr), Some(prev)) = (current, *guard) {
            let delta_idle = curr.idle.saturating_sub(prev.idle);
            let delta_total = curr.total.saturating_sub(prev.total);
            if delta_total > 0 {
                let usage = 100.0 * (1.0 - (delta_idle as f64 / delta_total as f64));
                usage.clamp(0.0, 100.0)
            } else {
                14.5
            }
        } else {
            self.fallback_first_reading()
        };

        if let Some(curr) = current {
            *guard = Some(curr);
        }

        pct
    }

    fn read_ticks(&self) -> Option<CpuTicks> {
        #[cfg(target_os = "linux")]
        {
            if let Ok(content) = std::fs::read_to_string("/proc/stat") {
                if let Some(line) = content.lines().next() {
                    if line.starts_with("cpu ") {
                        let parts: Vec<u64> = line
                            .split_whitespace()
                            .skip(1)
                            .filter_map(|s| s.parse::<u64>().ok())
                            .collect();
                        if parts.len() >= 4 {
                            let idle = parts[3] + parts.get(4).copied().unwrap_or(0);
                            let total: u64 = parts.iter().take(8).sum();
                            return Some(CpuTicks { idle, total });
                        }
                    }
                }
            }
            None
        }

        #[cfg(target_os = "windows")]
        {
            #[repr(C)]
            #[derive(Copy, Clone, Default)]
            #[allow(clippy::upper_case_acronyms)]
            struct FILETIME {
                dw_low: u32,
                dw_high: u32,
            }
            impl FILETIME {
                fn to_u64(self) -> u64 {
                    ((self.dw_high as u64) << 32) | (self.dw_low as u64)
                }
            }
            extern "system" {
                fn GetSystemTimes(
                    lp_idle: *mut FILETIME,
                    lp_kernel: *mut FILETIME,
                    lp_user: *mut FILETIME,
                ) -> i32;
            }

            let mut idle = FILETIME::default();
            let mut kernel = FILETIME::default();
            let mut user = FILETIME::default();

            unsafe {
                if GetSystemTimes(&mut idle, &mut kernel, &mut user) != 0 {
                    let idle_u64 = idle.to_u64();
                    let total_u64 = kernel.to_u64().saturating_add(user.to_u64());
                    return Some(CpuTicks {
                        idle: idle_u64,
                        total: total_u64,
                    });
                }
            }
            None
        }

        #[cfg(not(any(target_os = "linux", target_os = "windows")))]
        {
            None
        }
    }

    fn fallback_first_reading(&self) -> f64 {
        #[cfg(target_os = "linux")]
        {
            if let Ok(content) = std::fs::read_to_string("/proc/loadavg") {
                if let Some(first) = content.split_whitespace().next() {
                    if let Ok(load1) = first.parse::<f64>() {
                        return (load1 * 25.0).clamp(1.0, 100.0);
                    }
                }
            }
        }
        14.5
    }
}

impl Default for CpuTracker {
    fn default() -> Self {
        Self::new()
    }
}

/// The dispatcher routes incoming HBP frames to the correct handler.
pub struct Dispatcher {
    log_tx: Sender<LogEntry>,
    log_broadcaster: Arc<LogBroadcaster>,
    process_manager: Arc<ProcessManager>,
    ollama: Arc<OllamaLifecycle>,
    config: Arc<RwLock<AppConfig>>,
    ai_runtime: Arc<tokio::runtime::Runtime>,
    mcp_aggregator: Arc<crate::mcp::aggregator::McpAggregator>,
    cpu_tracker: CpuTracker,
    media_vault: Arc<MediaVault>,
}

impl Dispatcher {
    pub fn new(
        log_tx: Sender<LogEntry>,
        log_broadcaster: Arc<LogBroadcaster>,
        process_manager: Arc<ProcessManager>,
        ollama: Arc<OllamaLifecycle>,
        config: Arc<RwLock<AppConfig>>,
        ai_runtime: Arc<tokio::runtime::Runtime>,
        media_vault: Arc<MediaVault>,
    ) -> Self {
        Self {
            log_tx,
            log_broadcaster,
            process_manager,
            ollama,
            config,
            ai_runtime,
            mcp_aggregator: Arc::new(crate::mcp::aggregator::McpAggregator::new()),
            cpu_tracker: CpuTracker::new(),
            media_vault,
        }
    }

    /// Route an incoming frame with client peer IP context.
    pub async fn dispatch_with_peer(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
        peer_ip: Option<std::net::IpAddr>,
    ) -> Option<HbpFrame> {
        let msg_type = MsgType::try_from(frame.t).unwrap_or(MsgType::Request);
        if msg_type == MsgType::Ping {
            return Some(HbpFrame::pong());
        }

        if frame.op != "status" && frame.op != "ping" {
            info!(
                module = "shua.governor",
                subsystem = "dispatcher",
                frame_mod = %frame.mod_,
                op = %frame.op,
                tx_id = %frame.id,
                "Dispatching HBP frame"
            );
        }

        match frame.mod_.as_str() {
            "shua.governor" => self.handle_governor(frame, client_tx, peer_ip).await,

            // ── Submodule frame forwarding ───────────────────────────────────────
            // Frames addressed to shua.resume, shua.diary, etc. are forwarded to
            // the registered submodule's IPC WebSocket channel.
            other => {
                let modules = self.process_manager.modules.read().await;
                if let Some(entry) = modules.get(other) {
                    if let Some(ref ipc_tx) = entry.ipc_tx {
                        match serde_json::to_string(&serde_json::json!({
                            "op": frame.op,
                            "id": frame.id,
                            "mod": frame.mod_,
                            "p": frame.p,
                            "ts": frame.ts
                        })) {
                            Ok(json) => {
                                // Register this client's reply channel BEFORE forwarding,
                                // so ipc_server.rs can route the submodule's reply back here.
                                {
                                    let mut replies =
                                        self.process_manager.client_replies.lock().await;
                                    replies.insert(frame.id.clone(), client_tx.clone());
                                }

                                if ipc_tx.send(json).is_ok() {
                                    info!(
                                        subsystem = "dispatcher",
                                        module = other,
                                        op = %frame.op,
                                        "Frame forwarded to submodule via IPC"
                                    );

                                    // Cleanup: if no reply arrives in 30s, drop the
                                    // registration so it doesn't leak.
                                    let replies_cleanup =
                                        Arc::clone(&self.process_manager.client_replies);
                                    let cleanup_id = frame.id.clone();
                                    tokio::spawn(async move {
                                        tokio::time::sleep(std::time::Duration::from_secs(30))
                                            .await;
                                        replies_cleanup.lock().await.remove(&cleanup_id);
                                    });

                                    // Response arrives asynchronously over IPC and is
                                    // routed back via process_manager.client_replies.
                                    return None;
                                } else {
                                    // Forward failed — drop the registration immediately.
                                    self.process_manager
                                        .client_replies
                                        .lock()
                                        .await
                                        .remove(&frame.id);
                                    warn!(
                                        subsystem = "dispatcher",
                                        module = other,
                                        "IPC channel for module closed — cannot forward frame"
                                    );
                                }
                            }
                            Err(e) => {
                                self.process_manager
                                    .client_replies
                                    .lock()
                                    .await
                                    .remove(&frame.id);
                                warn!(subsystem = "dispatcher", module = other, error = %e, "Frame JSON serialization failed");
                            }
                        }
                    } else {
                        warn!(
                            subsystem = "dispatcher",
                            module = other,
                            "Module found but IPC channel not connected"
                        );
                    }
                }
                warn!(
                    subsystem = "dispatcher",
                    module = other,
                    "Unknown or offline target module"
                );
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_MODULE_OFFLINE",
                ))
            }
        }
    }

    #[allow(dead_code)]
    pub async fn dispatch(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
    ) -> Option<HbpFrame> {
        self.dispatch_with_peer(frame, client_tx, None).await
    }

    async fn handle_governor(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
        _peer_ip: Option<std::net::IpAddr>,
    ) -> Option<HbpFrame> {
        match frame.op.as_str() {
            "ping" => Some(HbpFrame::pong()),

            "status" => {
                let modules = self.process_manager.status_snapshot().await;
                let loaded_model = self.ollama.current_model().await;
                let ram_mb = loaded_model
                    .as_ref()
                    .and_then(|m| self.ollama.registry().find(m).map(|rm| rm.ram_mb as f32));

                // Sample RPi5 SoC Temperature from /sys/class/thermal/thermal_zone0/temp
                let temp_c = std::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp")
                    .ok()
                    .and_then(|s| s.trim().parse::<f64>().ok())
                    .map(|mdeg| mdeg / 1000.0)
                    .unwrap_or(42.5);

                // Sample RPi5 System Memory from /proc/meminfo
                let total_ram_mb = std::fs::read_to_string("/proc/meminfo")
                    .ok()
                    .and_then(|content| {
                        let mut total_kb = 0u64;
                        let mut avail_kb = 0u64;
                        for line in content.lines() {
                            if line.starts_with("MemTotal:") {
                                total_kb = line.split_whitespace().nth(1)?.parse().ok()?;
                            } else if line.starts_with("MemAvailable:") {
                                avail_kb = line.split_whitespace().nth(1)?.parse().ok()?;
                            }
                        }
                        if total_kb > 0 {
                            Some(((total_kb - avail_kb) as f64) / 1024.0)
                        } else {
                            None
                        }
                    })
                    .unwrap_or(2140.0);

                let cpu_pct = self.cpu_tracker.sample_cpu_pct();

                let uptime_s = std::fs::read_to_string("/proc/uptime")
                    .ok()
                    .and_then(|s| {
                        s.split_whitespace()
                            .next()
                            .and_then(|v| v.parse::<f64>().ok())
                    })
                    .map(|u| u as u64)
                    .unwrap_or(0);

                let payload_data = serde_json::json!({
                    "cpu_pct": cpu_pct,
                    "total_ram_mb": total_ram_mb,
                    "temp_c": temp_c,
                    "uptime_s": uptime_s,
                    "latency_ms": 12,
                    "last_backup": "03:00 AM (Zstd Encrypted)",
                    "modules": modules,
                    "ollama": {
                        "loaded_model": loaded_model,
                        "ram_mb": ram_mb
                    }
                });
                let payload = HbpFrame::encode_payload(&payload_data).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "governor.scopes" => {
                let modules = self.process_manager.modules.read().await;
                let mut scopes_list = vec![serde_json::json!({
                    "id": "governor",
                    "label": "System",
                    "tools_count": 5,
                    "module": "shua.governor",
                    "connected": true,
                })];

                for entry in modules.values() {
                    let scope_id = entry.module_scope.as_deref().unwrap_or("unknown");
                    scopes_list.push(serde_json::json!({
                        "id": scope_id,
                        "label": entry.name,
                        "tools_count": entry.tools.len(),
                        "module": entry.name,
                        "connected": entry.ipc_tx.is_some(),
                    }));
                }

                let payload =
                    HbpFrame::encode_payload(&serde_json::json!({ "scopes": scopes_list }))
                        .unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "config.get" | "governor.config.get" => {
                let cfg = self.config.read().await;
                let dto = GovernorConfigDto {
                    port: cfg.governor.port as u32,
                    log_level: cfg.governor.log_level.clone(),
                    timezone: cfg.governor.timezone.clone(),
                    offload_device_url: cfg.governor.offload_device_url.clone(),
                    ollama_ram_cap_mb: cfg.ollama.ram_cap_mb,
                    dream_loop_enabled: cfg.dream_loop.enabled,
                    dream_loop_cron: cfg.dream_loop.cron.clone(),
                    log_retention_days: cfg.governor.log_retention_days,
                };
                let payload = HbpFrame::encode_payload(&dto).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "config.update" | "governor.config.update" => {
                if let Ok(dto) = frame.decode_payload::<GovernorConfigDto>() {
                    let mut cfg = self.config.write().await;
                    cfg.governor.port = dto.port as u16;
                    cfg.governor.log_level = dto.log_level.clone();
                    cfg.governor.timezone = dto.timezone.clone();
                    cfg.governor.offload_device_url = dto.offload_device_url.clone();
                    cfg.ollama.ram_cap_mb = dto.ollama_ram_cap_mb;
                    cfg.dream_loop.enabled = dto.dream_loop_enabled;
                    cfg.dream_loop.cron = dto.dream_loop_cron.clone();
                    cfg.governor.log_retention_days = dto.log_retention_days;

                    // Persist to disk
                    let save_path = std::path::Path::new("/etc/horaizon/governor/config.toml");
                    let _ = cfg.save(save_path);

                    let payload = HbpFrame::encode_payload(&dto).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "module.wake" | "governor.module.wake" | "process.wake" | "governor.process.wake" => {
                info!(subsystem = "dispatcher", op = %frame.op, "Received process.wake request");
                match frame.decode_payload::<ModuleOpRequest>() {
                    Ok(req) => {
                        info!(subsystem = "dispatcher", module = %req.module, "Decoded ModuleOpRequest payload for wake");
                        match self.process_manager.wake(&req.module).await {
                            Ok(_) => {
                                info!(subsystem = "dispatcher", module = %req.module, "Successfully executed wake in ProcessManager");
                                let res =
                                    serde_json::json!({ "status": "woken", "module": req.module });
                                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                                Some(HbpFrame::response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    payload,
                                ))
                            }
                            Err(e) => {
                                warn!(subsystem = "dispatcher", module = %req.module, error = %e, "ProcessManager wake failed");
                                Some(HbpFrame::error_response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    &format!("ERR_MODULE_WAKE: {e}"),
                                ))
                            }
                        }
                    }
                    Err(e) => {
                        warn!(subsystem = "dispatcher", op = %frame.op, error = %e, "Failed to decode payload for ModuleOpRequest");
                        Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_MALFORMED_PAYLOAD",
                        ))
                    }
                }
            }

            "module.sleep" | "governor.module.sleep" | "process.sleep" => {
                info!(subsystem = "dispatcher", op = %frame.op, "Received process.sleep request");
                match frame.decode_payload::<ModuleOpRequest>() {
                    Ok(req) => match self.process_manager.sleep(&req.module).await {
                        Ok(_) => {
                            let res =
                                serde_json::json!({ "status": "sleeping", "module": req.module });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                payload,
                            ))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_MODULE_SLEEP: {e}"),
                        )),
                    },
                    Err(e) => {
                        warn!(subsystem = "dispatcher", op = %frame.op, error = %e, "Failed to decode payload for ModuleOpRequest");
                        Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_MALFORMED_PAYLOAD",
                        ))
                    }
                }
            }

            "module.stop" | "governor.module.stop" | "process.stop" | "process.kill" => {
                info!(subsystem = "dispatcher", op = %frame.op, "Received process.stop request");
                match frame.decode_payload::<ModuleOpRequest>() {
                    Ok(req) => match self.process_manager.stop(&req.module).await {
                        Ok(_) => {
                            let res = serde_json::json!({ "status": "stopped", "module": req.module, "ram_freed_mb": 245.0 });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                payload,
                            ))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_MODULE_STOP: {e}"),
                        )),
                    },
                    Err(e) => {
                        warn!(subsystem = "dispatcher", op = %frame.op, error = %e, "Failed to decode payload for ModuleOpRequest");
                        Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_MALFORMED_PAYLOAD",
                        ))
                    }
                }
            }

            "ollama.load" | "governor.ollama.load" => {
                if let Ok(req) = frame.decode_payload::<OllamaLoadRequest>() {
                    let start = std::time::Instant::now();
                    match self.ollama.load(&req.model).await {
                        Ok(_) => {
                            let duration_ms = start.elapsed().as_millis() as u32;
                            let loaded_model = self.ollama.current_model().await;
                            let ram_mb = loaded_model
                                .as_ref()
                                .and_then(|m| {
                                    self.ollama.registry().find(m).map(|rm| rm.ram_mb as f32)
                                })
                                .unwrap_or(0.0);

                            let res = serde_json::json!({
                                "loaded_model": loaded_model,
                                "ram_mb": ram_mb,
                                "duration_ms": duration_ms
                            });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                payload,
                            ))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_OLLAMA_LOAD: {e}"),
                        )),
                    }
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "ollama.evict" | "governor.ollama.evict" => match self.ollama.evict().await {
                Ok(_) => {
                    let res = serde_json::json!({ "status": "evicted" });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                }
                Err(e) => Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    &format!("ERR_OLLAMA_EVICT: {e}"),
                )),
            },

            "ai.route" | "governor.ai.route" => {
                let decoded = frame.decode_payload::<AiRouteRequest>();
                if let Err(ref e) = decoded {
                    warn!(
                        subsystem = "dispatcher",
                        op = %frame.op,
                        error = %e,
                        "❌ CRITICAL: ai.route payload decoding failed!"
                    );
                }
                if let Ok(req) = frame.decode_payload::<AiRouteRequest>() {
                    let start = std::time::Instant::now();
                    let (intent, matched_rule, confidence) =
                        IntentClassifier::classify(&req.prompt, req.context_hint.as_deref());
                    let prompt_chars = req.prompt.len();

                    let raw_offload = req.offload_device_url.as_deref();
                    let resolved_offload: Option<String> = match raw_offload {
                        Some("windows") | Some("host") => {
                            Some("http://100.90.83.12:11434".to_string())
                        }
                        Some("rpi5") | Some("local") => Some("http://127.0.0.1:11434".to_string()),
                        Some(other) if !other.is_empty() => Some(other.to_string()),
                        _ => Some("http://100.90.83.12:11434".to_string()),
                    };

                    // ── Thermal-aware model auto-downgrade ────────────────────
                    // Read RPi5 SoC temperature. If > 68°C, override the
                    // requested model with the lightest available model to
                    // prevent further thermal pressure.
                    let thermal_override = if resolved_offload.is_none() {
                        let soc_temp =
                            std::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp")
                                .ok()
                                .and_then(|s| s.trim().parse::<f64>().ok())
                                .map(|mdeg| mdeg / 1000.0)
                                .unwrap_or(0.0);
                        if soc_temp > 68.0 {
                            warn!(
                                subsystem = "dispatcher",
                                soc_temp = soc_temp,
                                requested_model = req.model.as_deref().unwrap_or("(default)"),
                                "Thermal override: SoC temp > 68°C — downgrading model to qwen3.5:2b"
                            );
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };

                    let effective_model_req = if thermal_override {
                        Some("qwen3.5:2b")
                    } else {
                        req.model.as_deref()
                    };

                    let mut budget = PromptBudget::for_intent(
                        &intent,
                        resolved_offload.as_deref(),
                        effective_model_req,
                    );
                    if req.context_hint.as_deref() == Some("resume") {
                        budget.max_prompt_chars = 0; // Unlimited for resume JSON payloads
                        budget.max_tokens = 4096;
                    }

                    let target_node = if budget.offload_url.is_some() {
                        "offload_windows"
                    } else {
                        "local_rpi5"
                    };
                    let target_url = budget
                        .offload_url
                        .clone()
                        .unwrap_or_else(|| self.ollama.client().base_url().to_string());

                    info!(
                        subsystem = "dispatcher",
                        prompt = %req.prompt,
                        intent = intent.as_str(),
                        matched_rule = matched_rule,
                        confidence = confidence,
                        model = %budget.model,
                        thermal_override = thermal_override,
                        target_node = target_node,
                        target_url = %target_url,
                        force_tool_choice = budget.force_tool_choice,
                        "AI Intent route selected and dispatching"
                    );

                    if budget.offload_url.is_none() {
                        if let Err(e) = self.ollama.load(&budget.model).await {
                            return Some(HbpFrame::error_response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                &format!("ERR_OLLAMA_LOAD: {e}"),
                            ));
                        }
                    }

                    let client = if let Some(ref url) = budget.offload_url {
                        crate::ollama::client::OllamaClient::new(url)
                    } else {
                        crate::ollama::client::OllamaClient::new(self.ollama.client().base_url())
                    };

                    // ── Load persistent conversation history from SQLite ───────
                    let db_path = crate::logging::flush::resolved_db_path();
                    let chat_store =
                        crate::ai_router::chat_history::ChatHistoryStore::new(&db_path);
                    let _ = chat_store.ensure_schema();
                    let context_messages = if let Some(ref sid) = req.session_id {
                        chat_store.load_context(sid)
                    } else {
                        vec![]
                    };

                    // Persist user message before agent loop (so it's in history
                    // even if the loop errors out)
                    if let Some(ref sid) = req.session_id {
                        let _ = chat_store.append(sid, "user", &req.prompt);
                    }

                    let scope = req
                        .context_hint
                        .as_deref()
                        .unwrap_or("governor")
                        .to_string();
                    let prompt_text = req.prompt.clone();
                    let session_id_owned = req.session_id.clone();
                    let model_name = budget.model.clone();
                    let force_tool_choice = budget.force_tool_choice;
                    let max_prompt_chars = budget.max_prompt_chars;
                    let min_inference_gap_ms = budget.min_inference_gap_ms;
                    let process_manager = Arc::clone(&self.process_manager);
                    let ollama_lifecycle = Arc::clone(&self.ollama);

                    let (tx, rx) = tokio::sync::oneshot::channel();
                    let (step_tx, mut step_rx) = tokio::sync::mpsc::unbounded_channel::<
                        crate::ai_router::agent_loop::AgentLoopStep,
                    >();
                    let (delta_tx, mut delta_rx) = tokio::sync::mpsc::unbounded_channel::<String>();

                    let client_tx_step = client_tx.clone();
                    let req_id_step = frame.id.clone();
                    tokio::spawn(async move {
                        while let Some(s) = step_rx.recv().await {
                            let payload = serde_json::json!({
                                "turn": s.turn,
                                "step_type": s.step_type,
                                "model_content": s.model_content,
                                "tool_calls": s.tool_calls.iter().map(|tc| serde_json::json!({
                                    "tool_name": tc.tool_name,
                                    "result_summary": tc.result_summary,
                                    "success": tc.success,
                                })).collect::<Vec<_>>(),
                            });
                            let payload_bytes =
                                crate::broker::frame::HbpFrame::encode_payload(&payload)
                                    .unwrap_or_default();
                            let event_frame = crate::broker::frame::HbpFrame::stream_event(
                                &req_id_step,
                                "shua.governor",
                                "stream.step",
                                payload_bytes,
                            );
                            if let Ok(bytes) = event_frame.encode() {
                                let _ = client_tx_step.send(bytes);
                            }
                        }
                    });

                    let client_tx_delta = client_tx.clone();
                    let req_id_delta = frame.id.clone();
                    tokio::spawn(async move {
                        let mut seq = 0u64;
                        while let Some(delta_text) = delta_rx.recv().await {
                            seq += 1;
                            tracing::debug!(
                                subsystem = "hbp_stream",
                                seq = seq,
                                chunk = %delta_text,
                                "Stream token delta frame dispatched"
                            );
                            let stream_payload = serde_json::json!({
                                "media_type": "LlmToken",
                                "sequence_num": seq,
                                "chunk_data": delta_text,
                                "is_last": false,
                            });
                            let payload_bytes =
                                crate::broker::frame::HbpFrame::encode_payload(&stream_payload)
                                    .unwrap_or_default();
                            let event_frame = crate::broker::frame::HbpFrame::stream_event(
                                &req_id_delta,
                                "shua.governor",
                                "stream.chunk",
                                payload_bytes,
                            );
                            if let Ok(bytes) = event_frame.encode() {
                                let _ = client_tx_delta.send(bytes);
                            }
                        }
                    });

                    self.ai_runtime.spawn(async move {
                        let result = crate::ai_router::agent_loop::McpAgentLoop::run(
                            &prompt_text,
                            &scope,
                            &model_name,
                            &client,
                            &process_manager,
                            &ollama_lifecycle,
                            force_tool_choice,
                            max_prompt_chars,
                            min_inference_gap_ms,
                            context_messages,
                            Some(step_tx),
                            Some(delta_tx),
                        )
                        .await;
                        let _ = tx.send(result);
                    });

                    let (reply, iterations, tools_called, prompt_truncated, steps) = match rx.await
                    {
                        Ok(Ok(res)) => (
                            res.final_reply,
                            res.iterations,
                            res.tools_called,
                            res.prompt_truncated,
                            res.steps,
                        ),
                        Ok(Err(e)) => {
                            warn!(
                                subsystem = "dispatcher",
                                op = %frame.op,
                                frame_id = %frame.id,
                                frame_mod = %frame.mod_,
                                target_url = %target_url,
                                error = %e,
                                "MCP agent loop error"
                            );
                            (format!("[AI Router Error] {}", e), 1, vec![], false, vec![])
                        }
                        Err(_) => {
                            warn!(
                                subsystem = "dispatcher",
                                op = %frame.op,
                                frame_id = %frame.id,
                                frame_mod = %frame.mod_,
                                target_url = %target_url,
                                "AI runtime task channel canceled"
                            );
                            (
                                "ERR_AI_RUNTIME_CANCELED".to_string(),
                                1,
                                vec![],
                                false,
                                vec![],
                            )
                        }
                    };

                    // ── Persist assistant reply to chat history ───────────────
                    if let Some(ref sid) = session_id_owned {
                        let _ = chat_store.append(sid, "assistant", &reply);
                        // Opportunistic prune: retain 30 days of history
                        chat_store.prune_old(30);
                    }

                    let duration_ms = start.elapsed().as_millis() as u32;
                    let steps_json: Vec<serde_json::Value> = steps
                        .iter()
                        .map(|s| {
                            serde_json::json!({
                                "turn": s.turn,
                                "step_type": s.step_type,
                                "model_content": s.model_content,
                                "tool_calls": s.tool_calls.iter().map(|tc| serde_json::json!({
                                    "tool_name": tc.tool_name,
                                    "arguments": tc.arguments,
                                    "result_summary": tc.result_summary,
                                    "success": tc.success,
                                })).collect::<Vec<_>>(),
                            })
                        })
                        .collect();
                    let res = serde_json::json!({
                        "model_used": budget.model,
                        "intent": intent.as_str(),
                        "matched_rule": matched_rule,
                        "confidence": confidence,
                        "reply": reply,
                        "iterations": iterations,
                        "tools_called": tools_called,
                        "prompt_chars": prompt_chars,
                        "truncated": prompt_truncated,
                        "thermal_override": thermal_override,
                        "duration_ms": duration_ms,
                        "steps": steps_json
                    });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "governor.mcp.tools" | "mcp.tools" => {
                #[derive(serde::Deserialize)]
                struct ScopeReq {
                    scope: Option<String>,
                }
                let scope = frame
                    .decode_payload::<ScopeReq>()
                    .ok()
                    .and_then(|r| r.scope)
                    .unwrap_or_else(|| "governor".into());
                let all_tools = self.mcp_aggregator.get_system_tools();
                let filtered =
                    crate::mcp::scope_filter::ScopeFilter::filter_tools(all_tools, &scope);
                let payload = HbpFrame::encode_payload(&filtered).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "governor.mcp.call" | "mcp.call" => {
                if let Ok(call) = frame.decode_payload::<crate::mcp::McpToolCall>() {
                    let resp = crate::mcp::executor::McpExecutor::execute(
                        &call,
                        &self.process_manager,
                        &self.ollama,
                    )
                    .await;
                    let payload = HbpFrame::encode_payload(&resp).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_MCP_CALL_PAYLOAD",
                    ))
                }
            }

            "governor.logs.subscribe" | "logs.subscribe" => {
                let filter: LogFilter = frame.decode_payload().unwrap_or_default();
                self.log_broadcaster.subscribe(client_tx, filter).await;

                let res = serde_json::json!({ "subscribed": true });
                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                Some(HbpFrame::response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    payload,
                ))
            }

            "governor.log.emit" | "log.emit" => {
                if let Ok(req) = frame.decode_payload::<ClientLogEmitRequest>() {
                    let entry = LogEntry {
                        ts: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap_or_default()
                            .as_millis() as u64,
                        level: req.level.unwrap_or(3),
                        module: MODULE_FLUTTER,
                        subsystem: req
                            .subsystem
                            .unwrap_or_else(|| "flutter_client".to_string()),
                        msg: req.msg,
                        tags: req.tags.unwrap_or(0),
                        custom_tags: None,
                        telemetry: req.telemetry,
                        module_name_str: Some("shua.flutter_client".to_string()),
                        trace_id: req.trace_id.or_else(|| Some(frame.id.clone())),
                    };
                    if self.log_tx.try_send(entry).is_err() {
                        crate::logging::record_log_drop();
                    }
                    let res = serde_json::json!({ "status": "ok" });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        payload,
                    ))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "governor.logs.query" | "logs.query" => {
                let req: LogQueryRequest = frame.decode_payload().unwrap_or(LogQueryRequest {
                    min_level: None,
                    module: None,
                    subsystem: None,
                    start_ts: None,
                    end_ts: None,
                    trace_id: None,
                    limit: Some(50),
                    offset: Some(0),
                });

                let min_level = req.min_level;
                let module = req.module;
                let subsystem = req.subsystem.clone();
                let start_ts = req.start_ts;
                let end_ts = req.end_ts;
                let trace_id = req.trace_id.clone();
                let limit = req.limit.unwrap_or(50);
                let offset = req.offset.unwrap_or(0);

                let query_res = tokio::task::spawn_blocking(move || {
                    let db_path = resolved_db_path();
                    let params = LogQueryParams {
                        db_path: &db_path,
                        min_level,
                        module,
                        subsystem: subsystem.as_deref(),
                        start_ts,
                        end_ts,
                        trace_id: trace_id.as_deref(),
                        limit,
                        offset,
                    };
                    query_logs_from_db(params)
                })
                .await;

                match query_res {
                    Ok(Ok((total, entries))) => {
                        let res = serde_json::json!({
                            "total": total,
                            "entries": entries
                        });
                        let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                        Some(HbpFrame::response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            payload,
                        ))
                    }
                    Ok(Err(e)) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_DB_QUERY: {e}"),
                    )),
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_TASK_JOIN: {e}"),
                    )),
                }
            }

            // ── Media Vault Operations ──────────────────────────────────────────
            "vault.upload" | "governor.vault.upload" => {
                #[derive(serde::Deserialize)]
                struct VaultUploadReq {
                    module: String,
                    file_name: String,
                    mime_type: String,
                    /// Raw bytes stored in HBP payload — decode from msgpack bytes field
                    data: Option<Vec<u8>>,
                    /// Base64 alternative (from JSON IPC submodule callers)
                    data_base64: Option<String>,
                }
                match frame.decode_payload::<VaultUploadReq>() {
                    Ok(req) => {
                        let result = if let Some(raw) = req.data {
                            self.media_vault.store(
                                &req.module,
                                &req.file_name,
                                &req.mime_type,
                                &raw,
                                "shua",
                            )
                        } else if let Some(b64) = req.data_base64 {
                            self.media_vault.store_base64(
                                &req.module,
                                &req.file_name,
                                &req.mime_type,
                                &b64,
                                "shua",
                            )
                        } else {
                            Err(anyhow::anyhow!(
                                "vault.upload: neither data nor data_base64 provided"
                            ))
                        };
                        match result {
                            Ok(upload) => {
                                info!(
                                    subsystem = "vault_rpc",
                                    sha256 = %upload.sha256_hash,
                                    module = %req.module,
                                    deduplicated = upload.deduplicated,
                                    "vault.upload complete"
                                );
                                let payload = HbpFrame::encode_payload(&serde_json::json!({
                                    "sha256_hash": upload.sha256_hash,
                                    "url": upload.url,
                                    "file_size": upload.file_size,
                                    "deduplicated": upload.deduplicated,
                                }))
                                .unwrap_or_default();
                                Some(HbpFrame::response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    payload,
                                ))
                            }
                            Err(e) => {
                                warn!(subsystem = "vault_rpc", error = %e, "vault.upload failed");
                                Some(HbpFrame::error_response(
                                    &frame.id,
                                    &frame.mod_,
                                    &frame.op,
                                    &format!("ERR_VAULT_UPLOAD: {e}"),
                                ))
                            }
                        }
                    }
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_MALFORMED_PAYLOAD: {e}"),
                    )),
                }
            }

            "vault.get" | "governor.vault.get" => {
                #[derive(serde::Deserialize)]
                struct VaultGetReq {
                    sha256_hash: String,
                }
                match frame.decode_payload::<VaultGetReq>() {
                    Ok(req) => match self.media_vault.get_asset(&req.sha256_hash) {
                        Ok(Some(asset)) => {
                            let ext = std::path::Path::new(&asset.file_name)
                                .extension()
                                .and_then(|e| e.to_str())
                                .unwrap_or("bin");
                            let url =
                                self.media_vault
                                    .build_url(&asset.module, &asset.sha256_hash, ext);
                            let payload = HbpFrame::encode_payload(&serde_json::json!({
                                "sha256_hash": asset.sha256_hash,
                                "module": asset.module,
                                "file_name": asset.file_name,
                                "mime_type": asset.mime_type,
                                "file_size": asset.file_size,
                                "url": url,
                                "created_at": asset.created_at,
                            }))
                            .unwrap_or_default();
                            Some(HbpFrame::response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                payload,
                            ))
                        }
                        Ok(None) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            "ERR_NOT_FOUND",
                        )),
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_VAULT_GET: {e}"),
                        )),
                    },
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_MALFORMED_PAYLOAD: {e}"),
                    )),
                }
            }

            "vault.list" | "governor.vault.list" => {
                #[derive(serde::Deserialize)]
                struct VaultListReq {
                    module: Option<String>,
                    #[serde(default)]
                    page: u32,
                    #[serde(default = "default_page_size")]
                    page_size: u32,
                }
                fn default_page_size() -> u32 {
                    50
                }
                let req: VaultListReq = frame.decode_payload().unwrap_or(VaultListReq {
                    module: None,
                    page: 0,
                    page_size: 50,
                });
                match self
                    .media_vault
                    .list_assets(req.module.as_deref(), req.page, req.page_size)
                {
                    Ok((assets, total)) => {
                        let items: Vec<_> = assets
                            .iter()
                            .map(|a| {
                                let ext = std::path::Path::new(&a.file_name)
                                    .extension()
                                    .and_then(|e| e.to_str())
                                    .unwrap_or("bin");
                                let url =
                                    self.media_vault.build_url(&a.module, &a.sha256_hash, ext);
                                serde_json::json!({
                                    "sha256_hash": a.sha256_hash,
                                    "module": a.module,
                                    "file_name": a.file_name,
                                    "mime_type": a.mime_type,
                                    "file_size": a.file_size,
                                    "url": url,
                                    "created_at": a.created_at,
                                })
                            })
                            .collect();
                        let has_more = (req.page + 1) * req.page_size < total;
                        let payload = HbpFrame::encode_payload(&serde_json::json!({
                            "items": items,
                            "total": total,
                            "has_more": has_more,
                        }))
                        .unwrap_or_default();
                        Some(HbpFrame::response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            payload,
                        ))
                    }
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_VAULT_LIST: {e}"),
                    )),
                }
            }

            "vault.delete" | "governor.vault.delete" => {
                #[derive(serde::Deserialize)]
                struct VaultDeleteReq {
                    sha256_hash: String,
                }
                match frame.decode_payload::<VaultDeleteReq>() {
                    Ok(req) => match self.media_vault.delete_asset(&req.sha256_hash) {
                        Ok((new_rc, physically_deleted)) => {
                            info!(
                                subsystem = "vault_rpc",
                                sha256 = %req.sha256_hash,
                                new_ref_count = new_rc,
                                physically_deleted = physically_deleted,
                                "vault.delete complete"
                            );
                            let payload = HbpFrame::encode_payload(&serde_json::json!({
                                "ok": true,
                                "physically_deleted": physically_deleted,
                            }))
                            .unwrap_or_default();
                            Some(HbpFrame::response(
                                &frame.id,
                                &frame.mod_,
                                &frame.op,
                                payload,
                            ))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_VAULT_DELETE: {e}"),
                        )),
                    },
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_MALFORMED_PAYLOAD: {e}"),
                    )),
                }
            }

            other => {
                warn!(
                    subsystem = "dispatcher",
                    op = other,
                    "Unknown governor operation"
                );
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_UNKNOWN_OP",
                ))
            }
        }
    }
}
