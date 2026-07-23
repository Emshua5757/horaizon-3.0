// shua_governor — Server-Side Log Broadcaster Filter (`governor.logs.subscribe`)
//
// Evaluates log stream filters in O(1) time before MessagePack encoding / WebSocket dispatch.

use serde::{Deserialize, Serialize};
use crate::logging::entry::LogEntry;

/// Client subscription filter rule set
#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct LogFilter {
    /// Minimum log level (1=TRACE .. 5=ERROR). If None, defaults to LEVEL_INFO (3).
    pub min_level: Option<u8>,
    /// Filter by module names (e.g. ["shua.resume", "shua.governor"]). If None/empty, allows all modules.
    pub modules: Option<Vec<String>>,
    /// Bitmask filter for tags (e.g. TAG_AI_INFERENCE). If None/0, allows all tags.
    pub tag_mask: Option<u32>,
}

impl LogFilter {
    /// Evaluate whether a log entry passes the filter
    pub fn matches(&self, entry: &LogEntry) -> bool {
        // 1. Min level filter
        let min_lvl = self.min_level.unwrap_or(3); // default INFO
        if entry.level < min_lvl {
            return false;
        }

        // 2. Tag mask filter (if specified)
        if let Some(mask) = self.tag_mask {
            if mask > 0 && (entry.tags & mask) == 0 {
                return false;
            }
        }

        // 3. Module filter (if specified)
        if let Some(ref mods) = self.modules {
            if !mods.is_empty() {
                let mod_name = module_id_to_name(entry.module);
                if !mods.iter().any(|m| m.as_str() == mod_name) {
                    return false;
                }
            }
        }

        true
    }
}

pub fn module_id_to_name(module_id: u8) -> &'static str {
    match module_id {
        10 => "shua.governor",
        20 => "shua.resume",
        30 => "shua.diary",
        40 => "shua.code_visualizer",
        50 => "shua.gym",
        60 => "shua.crypto",
        100 => "shua.flutter_client",
        _ => "unknown",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::logging::entry::{LEVEL_DEBUG, LEVEL_ERROR, LEVEL_INFO, MODULE_GOVERNOR, MODULE_RESUME, TAG_SYSTEM};

    #[test]
    fn test_log_filter_level() {
        let filter = LogFilter {
            min_level: Some(LEVEL_INFO),
            modules: None,
            tag_mask: None,
        };

        let debug_entry = LogEntry {
            ts: 1000,
            level: LEVEL_DEBUG,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "debug msg".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        let info_entry = LogEntry {
            ts: 1000,
            level: LEVEL_INFO,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "info msg".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        assert!(!filter.matches(&debug_entry));
        assert!(filter.matches(&info_entry));
    }

    #[test]
    fn test_log_filter_module() {
        let filter = LogFilter {
            min_level: Some(LEVEL_INFO),
            modules: Some(vec!["shua.resume".to_string()]),
            tag_mask: None,
        };

        let gov_entry = LogEntry {
            ts: 1000,
            level: LEVEL_ERROR,
            module: MODULE_GOVERNOR,
            subsystem: "test".to_string(),
            msg: "gov error".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        let resume_entry = LogEntry {
            ts: 1000,
            level: LEVEL_INFO,
            module: MODULE_RESUME,
            subsystem: "test".to_string(),
            msg: "resume msg".to_string(),
            tags: TAG_SYSTEM,
            custom_tags: None,
            telemetry: None,
            trace_id: None,
        };

        assert!(!filter.matches(&gov_entry));
        assert!(filter.matches(&resume_entry));
    }
}
