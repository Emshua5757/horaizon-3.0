use serde::{Deserialize, Serialize};

/// A model registered in config.toml
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegisteredModel {
    pub name:       String,     // e.g. "qwen2.5:1.5b"
    pub ram_mb:     u32,        // estimated RAM footprint
    pub role:       String,     // "primary_dialogue" | "text_generator" | "embeddings"
    pub keep_alive: i32,        // 0 = evict immediately after inference
}

pub struct ModelRegistry {
    models: Vec<RegisteredModel>,
    /// Hard RAM cap for all Ollama models combined (default: 4096 MB)
    ram_cap_mb: u32,
}

impl ModelRegistry {
    pub fn new(models: Vec<RegisteredModel>, ram_cap_mb: u32) -> Self {
        Self { models, ram_cap_mb }
    }

    pub fn find(&self, name: &str) -> Option<&RegisteredModel> {
        self.models.iter().find(|m| m.name == name)
    }

    pub fn ram_cap_mb(&self) -> u32 {
        self.ram_cap_mb
    }
}
