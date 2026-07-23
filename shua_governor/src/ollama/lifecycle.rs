use std::sync::Arc;
use tokio::sync::Mutex;
use anyhow::Result;
use tracing::info;

use crate::ollama::client::OllamaClient;
use crate::ollama::model_registry::ModelRegistry;

pub struct OllamaLifecycle {
    client: OllamaClient,
    registry: ModelRegistry,
    /// Currently loaded model name
    loaded: Arc<Mutex<Option<String>>>,
}

impl OllamaLifecycle {
    pub fn new(client: OllamaClient, registry: ModelRegistry) -> Self {
        Self {
            client,
            registry,
            loaded: Arc::new(Mutex::new(None)),
        }
    }

    /// Load a model, evicting the current one if needed.
    /// Enforces the 4GB RAM cap.
    pub async fn load(&self, model_name: &str) -> Result<()> {
        let model = self
            .registry
            .find(model_name)
            .ok_or_else(|| anyhow::anyhow!("Model not registered: {model_name}"))?;

        if model.ram_mb > self.registry.ram_cap_mb() {
            return Err(anyhow::anyhow!(
                "ERR_MODEL_TOO_LARGE: {model_name} requires {}MB, cap is {}MB",
                model.ram_mb,
                self.registry.ram_cap_mb()
            ));
        }

        let mut loaded = self.loaded.lock().await;

        // Evict current model if one is loaded
        if let Some(current) = loaded.as_ref() {
            if current == model_name {
                info!(
                    subsystem = "ollama_lifecycle",
                    model = model_name,
                    "Model already loaded"
                );
                return Ok(());
            }
            let _ = self.client.evict_model(current).await;
            *loaded = None;
        }

        self.client.load_model(model_name).await?;
        *loaded = Some(model_name.to_string());
        info!(
            subsystem = "ollama_lifecycle",
            model = model_name,
            ram_mb = model.ram_mb,
            "Model loaded successfully"
        );
        Ok(())
    }

    /// Evict the currently loaded model.
    pub async fn evict(&self) -> Result<()> {
        let mut loaded = self.loaded.lock().await;
        if let Some(model) = loaded.take() {
            let _ = self.client.evict_model(&model).await;
            info!(subsystem = "ollama_lifecycle", model = %model, "Model evicted");
        }
        Ok(())
    }

    /// Get currently loaded model name.
    pub async fn current_model(&self) -> Option<String> {
        self.loaded.lock().await.clone()
    }

    pub fn client(&self) -> &OllamaClient {
        &self.client
    }

    pub fn registry(&self) -> &ModelRegistry {
        &self.registry
    }
}
