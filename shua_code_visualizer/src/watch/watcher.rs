use crate::graph::store::CodeGraph;
use crate::mcp::schema::TopologyDeltaEvent;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::mpsc::{channel, Receiver};
use std::time::{Duration, Instant};

/// Live file watcher daemon with non-blocking event coalescing and path debouncing
pub struct CodeWatcher {
    _watcher: RecommendedWatcher,
    rx: Receiver<Result<Event, notify::Error>>,
    pending_events: HashMap<PathBuf, Instant>,
    debounce_window: Duration,
}

impl CodeWatcher {
    /// Starts watching a directory for live file changes
    pub fn new(target_dir: &Path) -> Result<Self, notify::Error> {
        let (tx, rx) = channel();

        let mut watcher = RecommendedWatcher::new(
            move |res| {
                let _ = tx.send(res);
            },
            Config::default().with_poll_interval(Duration::from_millis(50)),
        )?;

        watcher.watch(target_dir, RecursiveMode::Recursive)?;

        Ok(Self {
            _watcher: watcher,
            rx,
            pending_events: HashMap::new(),
            debounce_window: Duration::from_millis(100),
        })
    }

    /// Polls pending file change events non-blockingly, coalescing rapid raw events for the same path.
    /// Executes single-file incremental graph patches only after the path quiet window (100ms) has expired.
    ///
    /// Note: Callers should poll in a loop (`while let Some(delta) = watcher.poll_and_apply_patch(...)`)
    /// to drain all expired paths during batch edits (e.g. git checkout).
    pub fn poll_and_apply_patch(&mut self, graph: &mut CodeGraph) -> Option<TopologyDeltaEvent> {
        let now = Instant::now();

        // 1. Drain channel without blocking
        while let Ok(Ok(event)) = self.rx.try_recv() {
            if let Some(path) = event.paths.first() {
                let valid_exts = ["rs", "dart", "go", "py", "ts", "tsx"];
                if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                    if valid_exts.contains(&ext) {
                        self.pending_events.insert(path.clone(), now);
                    }
                }
            }
        }

        // 2. Find path whose quiet window has elapsed
        let mut expired_path = None;
        for (path, &last_seen) in &self.pending_events {
            if now.duration_since(last_seen) >= self.debounce_window {
                expired_path = Some(path.clone());
                break;
            }
        }

        // 3. Apply single incremental graph patch
        if let Some(path) = expired_path {
            self.pending_events.remove(&path);

            let path_str = path.to_string_lossy().to_string();
            let code_opt = fs::read_to_string(&path).ok();
            let delta = graph.apply_incremental_file_patch(&path_str, code_opt.as_deref());

            Some(delta)
        } else {
            None
        }
    }
}
