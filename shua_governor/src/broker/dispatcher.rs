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

/// The dispatcher routes incoming HBP frames to the correct handler.
pub struct Dispatcher {
    log_tx: Sender<LogEntry>,
    log_broadcaster: Arc<LogBroadcaster>,
    process_manager: Arc<ProcessManager>,
    ollama: Arc<OllamaLifecycle>,
    config: Arc<RwLock<AppConfig>>,
}

impl Dispatcher {
    pub fn new(
        log_tx: Sender<LogEntry>,
        log_broadcaster: Arc<LogBroadcaster>,
        process_manager: Arc<ProcessManager>,
        ollama: Arc<OllamaLifecycle>,
        config: Arc<RwLock<AppConfig>>,
    ) -> Self {
        Self {
            log_tx,
            log_broadcaster,
            process_manager,
            ollama,
            config,
        }
    }

    /// Route an incoming frame. Returns an optional response frame.
    pub async fn dispatch(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
    ) -> Option<HbpFrame> {
        let msg_type = MsgType::try_from(frame.t).unwrap_or(MsgType::Request);
        if msg_type == MsgType::Ping {
            return Some(HbpFrame::pong());
        }

        info!(
            module = "shua.governor",
            subsystem = "dispatcher",
            frame_mod = %frame.mod_,
            op = %frame.op,
            tx_id = %frame.id,
            "Dispatching HBP frame"
        );

        match frame.mod_.as_str() {
            "shua.governor" => self.handle_governor(frame, client_tx).await,
            other => {
                warn!(subsystem = "dispatcher", module = other, "Unknown target module");
                Some(HbpFrame::error_response(
                    &frame.id,
                    &frame.mod_,
                    &frame.op,
                    "ERR_UNKNOWN_MODULE",
                ))
            }
        }
    }

    async fn handle_governor(
        &self,
        frame: HbpFrame,
        client_tx: UnboundedSender<Vec<u8>>,
    ) -> Option<HbpFrame> {
        match frame.op.as_str() {
            "ping" => Some(HbpFrame::pong()),

            "status" => {
                let modules = self.process_manager.status_snapshot().await;
                let loaded_model = self.ollama.current_model().await;
                let ram_mb = loaded_model.as_ref().and_then(|m| {
                    self.ollama.registry().find(m).map(|rm| rm.ram_mb as f32)
                });

                let payload_data = serde_json::json!({
                    "modules": modules,
                    "ollama": {
                        "loaded_model": loaded_model,
                        "ram_mb": ram_mb
                    }
                });
                let payload = HbpFrame::encode_payload(&payload_data).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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
                    Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "module.wake" | "governor.module.wake" => {
                if let Ok(req) = frame.decode_payload::<ModuleOpRequest>() {
                    match self.process_manager.wake(&req.module).await {
                        Ok(_) => {
                            let res = serde_json::json!({ "status": "woken", "module": req.module });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_MODULE_WAKE: {e}"),
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

            "module.sleep" | "governor.module.sleep" => {
                if let Ok(req) = frame.decode_payload::<ModuleOpRequest>() {
                    match self.process_manager.sleep(&req.module).await {
                        Ok(_) => {
                            let res = serde_json::json!({ "status": "sleeping", "module": req.module });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                        }
                        Err(e) => Some(HbpFrame::error_response(
                            &frame.id,
                            &frame.mod_,
                            &frame.op,
                            &format!("ERR_MODULE_SLEEP: {e}"),
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

            "ollama.load" | "governor.ollama.load" => {
                if let Ok(req) = frame.decode_payload::<OllamaLoadRequest>() {
                    let start = std::time::Instant::now();
                    match self.ollama.load(&req.model).await {
                        Ok(_) => {
                            let duration_ms = start.elapsed().as_millis() as u32;
                            let loaded_model = self.ollama.current_model().await;
                            let ram_mb = loaded_model.as_ref().and_then(|m| {
                                self.ollama.registry().find(m).map(|rm| rm.ram_mb as f32)
                            }).unwrap_or(0.0);

                            let res = serde_json::json!({
                                "loaded_model": loaded_model,
                                "ram_mb": ram_mb,
                                "duration_ms": duration_ms
                            });
                            let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                            Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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

            "ollama.evict" | "governor.ollama.evict" => {
                match self.ollama.evict().await {
                    Ok(_) => {
                        let res = serde_json::json!({ "status": "evicted" });
                        let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                        Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                    }
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_OLLAMA_EVICT: {e}"),
                    )),
                }
            }

            "ai.route" | "governor.ai.route" => {
                if let Ok(req) = frame.decode_payload::<AiRouteRequest>() {
                    let start = std::time::Instant::now();
                    let intent = IntentClassifier::classify(&req.prompt, req.context_hint.as_deref());

                    let offload_url = req.offload_device_url.as_deref().or_else(|| {
                        // Use global offload URL if set
                        None
                    });

                    let budget = PromptBudget::for_intent(&intent, offload_url);

                    info!(
                        subsystem = "dispatcher",
                        intent = intent.as_str(),
                        model = %budget.model,
                        offload_url = ?budget.offload_url,
                        "AI Intent route selected"
                    );

                    let client = if let Some(ref url) = budget.offload_url {
                        crate::ollama::client::OllamaClient::new(url)
                    } else {
                        crate::ollama::client::OllamaClient::new(self.ollama.client().base_url())
                    };

                    let messages = vec![crate::ollama::client::ChatMessage {
                        role: "user".into(),
                        content: req.prompt.clone(),
                    }];

                    let reply = match client.chat(&budget.model, messages, 0).await {
                        Ok(res) => res,
                        Err(e) => {
                            warn!(subsystem = "dispatcher", error = %e, "Ollama chat fallback to stub");
                            format!("[AI Router Stub ({})] Intent: {}", intent.as_str(), req.prompt)
                        }
                    };

                    let duration_ms = start.elapsed().as_millis() as u32;
                    let res = serde_json::json!({
                        "model_used": budget.model,
                        "intent": intent.as_str(),
                        "reply": reply,
                        "duration_ms": duration_ms
                    });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                } else {
                    Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        "ERR_MALFORMED_PAYLOAD",
                    ))
                }
            }

            "governor.logs.subscribe" | "logs.subscribe" => {
                let filter: LogFilter = frame.decode_payload().unwrap_or_default();
                self.log_broadcaster.subscribe(client_tx, filter).await;
                
                let res = serde_json::json!({ "subscribed": true });
                let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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
                        subsystem: req.subsystem.unwrap_or_else(|| "flutter_client".to_string()),
                        msg: req.msg,
                        tags: req.tags.unwrap_or(0),
                        custom_tags: None,
                        telemetry: req.telemetry,
                        trace_id: req.trace_id.or_else(|| Some(frame.id.clone())),
                    };
                    let _ = self.log_tx.try_send(entry);
                    let res = serde_json::json!({ "status": "ok" });
                    let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                    Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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

                let db_path = resolved_db_path();
                let params = LogQueryParams {
                    db_path: &db_path,
                    min_level: req.min_level,
                    module: req.module,
                    subsystem: req.subsystem.as_deref(),
                    start_ts: req.start_ts,
                    end_ts: req.end_ts,
                    trace_id: req.trace_id.as_deref(),
                    limit: req.limit.unwrap_or(50),
                    offset: req.offset.unwrap_or(0),
                };

                match query_logs_from_db(params) {
                    Ok((total, entries)) => {
                        let res = serde_json::json!({
                            "total": total,
                            "entries": entries
                        });
                        let payload = HbpFrame::encode_payload(&res).unwrap_or_default();
                        Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
                    }
                    Err(e) => Some(HbpFrame::error_response(
                        &frame.id,
                        &frame.mod_,
                        &frame.op,
                        &format!("ERR_DB_QUERY: {e}"),
                    )),
                }
            }

            other => {
                warn!(subsystem = "dispatcher", op = other, "Unknown governor operation");
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
