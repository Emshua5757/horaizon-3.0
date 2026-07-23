// shua_governor — WebSocket Live Log Stream Broadcaster
//
// Subscribes to the internal broadcast channel (`log_broadcast_tx`) and forwards matching
// log events to active client WebSocket connection channels as HBP v2 EVENT frames.

use std::sync::Arc;
use tokio::sync::{broadcast, mpsc, RwLock};
use tracing::{error, warn};

use crate::logging::entry::LogEntry;
use crate::logging::filter::LogFilter;

/// Client log subscriber session
pub struct SubscriberSession {
    pub client_tx: mpsc::UnboundedSender<Vec<u8>>,
    pub filter: LogFilter,
}

/// The LogBroadcaster manages active WebSocket client log stream subscriptions.
#[derive(Clone)]
pub struct LogBroadcaster {
    subscribers: Arc<RwLock<Vec<SubscriberSession>>>,
}

impl LogBroadcaster {
    pub fn new() -> Self {
        Self {
            subscribers: Arc::new(RwLock::new(Vec::new())),
        }
    }

    /// Register a client WebSocket channel for live log events
    pub async fn subscribe(
        &self,
        client_tx: mpsc::UnboundedSender<Vec<u8>>,
        filter: LogFilter,
    ) {
        let mut subs = self.subscribers.write().await;
        // Replace existing subscriber channel if present, else push new
        subs.retain(|s| !s.client_tx.is_closed());
        subs.push(SubscriberSession { client_tx, filter });
    }

    /// Main loop listening on broadcast channel and fanning out to clients
    pub async fn run_broadcast_loop(
        &self,
        mut broadcast_rx: broadcast::Receiver<LogEntry>,
    ) {
        while let Ok(entry) = broadcast_rx.recv().await {
            let subs = self.subscribers.read().await;
            if subs.is_empty() {
                continue;
            }

            let mut frame_bytes: Option<Vec<u8>> = None;

            for sub in subs.iter() {
                if sub.client_tx.is_closed() {
                    continue;
                }

                if sub.filter.matches(&entry) {
                    if frame_bytes.is_none() {
                        match entry.to_hbp_frame() {
                            Ok(frame) => match frame.encode() {
                                Ok(encoded) => frame_bytes = Some(encoded),
                                Err(e) => error!(error = %e, "Log event encode error"),
                            },
                            Err(e) => warn!(error = %e, "Log event frame error"),
                        }
                    }

                    if let Some(ref bytes) = frame_bytes {
                        let _ = sub.client_tx.send(bytes.clone());
                    }
                }
            }
        }
    }
}
