use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use tracing::{info, warn};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub governor: GovernorConfig,
    pub dream_loop: DreamLoopConfig,
    pub ollama: OllamaConfig,
    #[serde(default)]
    pub modules: ModulesConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernorConfig {
    pub port: u16,
    pub log_level: String,
    pub timezone: String,
    pub offload_device_url: Option<String>,
    #[serde(default = "default_log_retention_days")]
    pub log_retention_days: u32,
}

fn default_log_retention_days() -> u32 {
    7
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DreamLoopConfig {
    pub enabled: bool,
    pub cron: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaConfig {
    pub binary: String,
    pub host: String,
    pub ram_cap_mb: u32,
    #[serde(default)]
    pub models: Vec<OllamaModelConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaModelConfig {
    pub name: String,
    pub ram_mb: u32,
    pub role: String,
    pub keep_alive: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ModulesConfig {
    #[serde(default, rename = "entry")]
    pub entries: Vec<ModuleConfigEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleConfigEntry {
    pub name: String,
    pub binary: PathBuf,
    pub auto_start: bool,
    pub ram_limit_mb: Option<u32>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            governor: GovernorConfig {
                port: 7700,
                log_level: "info".to_string(),
                timezone: "Asia/Manila".to_string(),
                offload_device_url: None,
                log_retention_days: 7,
            },
            dream_loop: DreamLoopConfig {
                enabled: true,
                cron: "0 18 * * *".to_string(), // 02:00 Asia/Manila (18:00 UTC)
            },
            ollama: OllamaConfig {
                binary: "/usr/bin/ollama".to_string(),
                host: "http://127.0.0.1:11434".to_string(),
                ram_cap_mb: 4096,
                models: vec![
                    OllamaModelConfig {
                        name: "qwen2.5:1.5b".into(),
                        ram_mb: 980,
                        role: "primary_dialogue".into(),
                        keep_alive: -1,
                    },
                    OllamaModelConfig {
                        name: "llama3.2:3b".into(),
                        ram_mb: 2000,
                        role: "text_generator".into(),
                        keep_alive: -1,
                    },
                ],
            },
            modules: ModulesConfig {
                entries: vec![
                    ModuleConfigEntry {
                        name: "shua.resume".to_string(),
                        binary: PathBuf::from("/usr/local/bin/shua_resume"),
                        auto_start: true,
                        ram_limit_mb: Some(128),
                    },
                    ModuleConfigEntry {
                        name: "shua.diary".to_string(),
                        binary: PathBuf::from("/usr/local/bin/shua_diary"),
                        auto_start: true,
                        ram_limit_mb: Some(256),
                    },
                    ModuleConfigEntry {
                        name: "shua.code_visualizer".to_string(),
                        binary: PathBuf::from("/usr/local/bin/shua_code_visualizer"),
                        auto_start: false,
                        ram_limit_mb: Some(128),
                    },
                ],
            },
        }
    }
}

impl AppConfig {
    /// Load config searching multi-path hierarchy:
    /// 1. explicit path parameter (if provided)
    /// 2. /etc/horaizon/governor/config.toml (Pi5 Linux production)
    /// 3. ./config.toml or shua_governor/config.toml (Local dev)
    /// 4. AppConfig::default() fallback
    pub fn load_from_hierarchy(custom_path: Option<&Path>) -> Self {
        let candidates = vec![
            custom_path.map(PathBuf::from),
            Some(PathBuf::from("/etc/horaizon/governor/config.toml")),
            Some(PathBuf::from("config.toml")),
            Some(PathBuf::from("shua_governor/config.toml")),
        ];

        for candidate in candidates.into_iter().flatten() {
            if candidate.exists() {
                match std::fs::read_to_string(&candidate) {
                    Ok(content) => match toml::from_str::<AppConfig>(&content) {
                        Ok(config) => {
                            info!(
                                subsystem = "config",
                                path = %candidate.display(),
                                port = config.governor.port,
                                "Successfully loaded configuration file"
                            );
                            return config;
                        }
                        Err(e) => {
                            warn!(
                                subsystem = "config",
                                path = %candidate.display(),
                                error = %e,
                                "Failed to parse config TOML — trying next candidate"
                            );
                        }
                    },
                    Err(e) => {
                        warn!(
                            subsystem = "config",
                            path = %candidate.display(),
                            error = %e,
                            "Failed to read config file"
                        );
                    }
                }
            }
        }

        warn!(
            subsystem = "config",
            "No valid config file found in search hierarchy — utilizing default AppConfig"
        );
        AppConfig::default()
    }

    /// Save current config back to disk file
    pub fn save(&self, path: &Path) -> Result<()> {
        let content = toml::to_string_pretty(self)
            .map_err(|e| anyhow::anyhow!("Config serialization error: {e}"))?;
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        std::fs::write(path, content)?;
        info!(
            subsystem = "config",
            path = %path.display(),
            "Configuration saved to disk"
        );
        Ok(())
    }
}
