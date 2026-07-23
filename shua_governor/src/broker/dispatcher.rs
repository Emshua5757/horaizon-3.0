use std::sync::Arc;
use tokio::sync::mpsc::{Sender, UnboundedSender};
use tracing::{info, warn};

use crate::broker::frame::{HbpFrame, MsgType};
use crate::logging::broadcaster::LogBroadcaster;
use crate::logging::entry::{LogEntry, MODULE_FLUTTER};
use crate::logging::filter::LogFilter;
use crate::logging::flush::{query_logs_from_db, resolved_db_path, LogQueryParams};
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

/// The dispatcher routes incoming HBP frames to the correct handler.
pub struct Dispatcher {
    log_tx: Sender<LogEntry>,
    log_broadcaster: Arc<LogBroadcaster>,
    process_manager: Arc<ProcessManager>,
}

impl Dispatcher {
    pub fn new(
        log_tx: Sender<LogEntry>,
        log_broadcaster: Arc<LogBroadcaster>,
        process_manager: Arc<ProcessManager>,
    ) -> Self {
        Self {
            log_tx,
            log_broadcaster,
            process_manager,
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
                let payload_data = serde_json::json!({
                    "modules": modules,
                    "ollama": { "loaded_model": null, "ram_mb": null }
                });
                let payload = HbpFrame::encode_payload(&payload_data).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
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
