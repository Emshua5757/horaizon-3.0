use std::sync::Arc;
use std::sync::Mutex as StdMutex;
use tokio::sync::Mutex as AsyncMutex;
use anyhow::{anyhow, Result};
use tracing::info;

use crate::ollama::client::OllamaClient;
use crate::ollama::model_registry::ModelRegistry;

#[derive(Debug, Default)]
struct LifecycleState {
    loaded_model: Option<String>,
    active_guards: usize,
}

pub struct ModelGuard {
    state: Arc<StdMutex<LifecycleState>>,
    model_name: String,
}

impl ModelGuard {
    #[allow(dead_code)]
    pub fn model_name(&self) -> &str {
        &self.model_name
    }
}

impl Drop for ModelGuard {
    fn drop(&mut self) {
        if let Ok(mut state) = self.state.lock() {
            if state.active_guards > 0 {
                state.active_guards -= 1;
                info!(
                    subsystem = "ollama_lifecycle",
                    model = %self.model_name,
                    active_guards = state.active_guards,
                    "ModelGuard released"
                );
            }
        }
    }
}

pub struct OllamaLifecycle {
    client: OllamaClient,
    registry: ModelRegistry,
    state: Arc<StdMutex<LifecycleState>>,
    load_lock: AsyncMutex<()>,
}

impl OllamaLifecycle {
    pub fn new(client: OllamaClient, registry: ModelRegistry) -> Self {
        Self {
            client,
            registry,
            state: Arc::new(StdMutex::new(LifecycleState::default())),
            load_lock: AsyncMutex::new(()),
        }
    }

    /// Load a model into RAM, evicting the current one if needed.
    /// Returns an error if an active `ModelGuard` reservation is holding a different model,
    /// or if the current model eviction fails.
    ///
    /// IMPORTANT: This is the SINGLE REQUIRED ENTRY POINT for local Ollama inference across `shua_governor`.
    /// All RPC handlers (including `ai.route`) MUST invoke `OllamaLifecycle::load()` or `reserve()` before initiating inference.
    pub async fn load(&self, model_name: &str) -> Result<()> {
        let model = self
            .registry
            .find(model_name)
            .ok_or_else(|| anyhow!("Model not registered: {model_name}"))?;

        if model.ram_mb > self.registry.ram_cap_mb() {
            return Err(anyhow!(
                "ERR_MODEL_TOO_LARGE: {model_name} requires {}MB, cap is {}MB",
                model.ram_mb,
                self.registry.ram_cap_mb()
            ));
        }

        let _lock = self.load_lock.lock().await;

        let current_to_evict = {
            let state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            if let Some(ref current) = state.loaded_model {
                if current == model_name {
                    info!(
                        subsystem = "ollama_lifecycle",
                        model = model_name,
                        "Model already loaded"
                    );
                    return Ok(());
                }
                if state.active_guards > 0 {
                    return Err(anyhow!(
                        "ERR_MODEL_BUSY: Model '{current}' is currently reserved by {} active stream(s); cannot evict to load '{model_name}'",
                        state.active_guards
                    ));
                }
                Some(current.clone())
            } else {
                None
            }
        };

        if let Some(ref current) = current_to_evict {
            self.client.evict_model(current).await?;
            let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            state.loaded_model = None;
        }

        self.client.load_model(model_name).await?;

        {
            let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            state.loaded_model = Some(model_name.to_string());
        }

        info!(
            subsystem = "ollama_lifecycle",
            model = model_name,
            ram_mb = model.ram_mb,
            "Model loaded successfully"
        );
        Ok(())
    }

    /// Load model (if needed) and acquire an active `ModelGuard` reservation.
    /// The returned guard prevents concurrent requests from evicting the model while active.
    pub async fn reserve(&self, model_name: &str) -> Result<ModelGuard> {
        self.load(model_name).await?;

        let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
        state.active_guards += 1;

        info!(
            subsystem = "ollama_lifecycle",
            model = model_name,
            active_guards = state.active_guards,
            "ModelGuard acquired"
        );

        Ok(ModelGuard {
            state: Arc::clone(&self.state),
            model_name: model_name.to_string(),
        })
    }

    /// Evict the currently loaded model. Errors if active reservations exist or eviction fails.
    pub async fn evict(&self) -> Result<()> {
        let _lock = self.load_lock.lock().await;

        let model_to_evict = {
            let state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            if let Some(ref current) = state.loaded_model {
                if state.active_guards > 0 {
                    return Err(anyhow!(
                        "ERR_MODEL_BUSY: Cannot evict '{current}' while {} ModelGuard(s) are active",
                        state.active_guards
                    ));
                }
                Some(current.clone())
            } else {
                None
            }
        };

        if let Some(ref model) = model_to_evict {
            self.client.evict_model(model).await?;
            let mut state = self.state.lock().map_err(|_| anyhow!("Poisoned lifecycle mutex"))?;
            state.loaded_model = None;
            info!(subsystem = "ollama_lifecycle", model = %model, "Model evicted");
        }

        Ok(())
    }

    /// Get currently loaded model name.
    pub async fn current_model(&self) -> Option<String> {
        self.state.lock().ok().and_then(|s| s.loaded_model.clone())
    }

    /// Get count of active ModelGuards.
    #[allow(dead_code)]
    pub fn active_guards(&self) -> usize {
        self.state.lock().map(|s| s.active_guards).unwrap_or(0)
    }

    pub fn client(&self) -> &OllamaClient {
        &self.client
    }

    pub fn registry(&self) -> &ModelRegistry {
        &self.registry
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ollama::client::KeepAlive;
    use crate::ollama::model_registry::RegisteredModel;

    #[tokio::test]
    async fn test_model_guard_prevents_eviction_when_active() {
        let state = Arc::new(StdMutex::new(LifecycleState {
            loaded_model: Some("qwen2.5:1.5b".to_string()),
            active_guards: 0,
        }));

        let registry = ModelRegistry::new(
            vec![
                RegisteredModel {
                    name: "qwen2.5:1.5b".to_string(),
                    ram_mb: 1500,
                    role: "primary_dialogue".to_string(),
                    keep_alive: KeepAlive::Forever,
                },
                RegisteredModel {
                    name: "deepseek-r1:1.5b".to_string(),
                    ram_mb: 1500,
                    role: "text_generator".to_string(),
                    keep_alive: KeepAlive::Forever,
                },
            ],
            4096,
        );

        let lifecycle = OllamaLifecycle {
            client: OllamaClient::new("http://127.0.0.1:11434"),
            registry,
            state: Arc::clone(&state),
            load_lock: AsyncMutex::new(()),
        };

        let guard = ModelGuard {
            state: Arc::clone(&state),
            model_name: "qwen2.5:1.5b".to_string(),
        };

        {
            let mut s = state.lock().unwrap();
            s.active_guards += 1;
        }

        assert_eq!(lifecycle.active_guards(), 1);

        // Attempting to evict while guard is active should fail with ERR_MODEL_BUSY
        let evict_res = lifecycle.evict().await;
        assert!(evict_res.is_err());
        assert!(evict_res.unwrap_err().to_string().contains("ERR_MODEL_BUSY"));

        // Dropping guard should decrease active count to 0
        drop(guard);
        assert_eq!(lifecycle.active_guards(), 0);
    }
}
