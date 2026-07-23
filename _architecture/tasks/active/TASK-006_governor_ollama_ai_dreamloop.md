# TASK-006 — `shua_governor` Ollama Lifecycle + AI Router + Dream Loop

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/ollama/`, `src/ai_router/`, `src/dream_loop/` |
| **Blocks** | TASK-007 |
| **Prerequisites** | TASK-005 complete |

---

## Context

Implement three interconnected systems:
1. **Ollama Lifecycle Manager** — load/evict models, enforce 4GB RAM cap, one-model-at-a-time rule
2. **AI Intent Router** — classify prompts by intent and route to the right model + context budget
3. **Dream Loop Scheduler** — nightly cron job at 02:00 Asia/Manila that runs background inference while no clients are connected

Read `_architecture/specs/shua_governor/shua_governor_spec.md` §§ "Ollama Lifecycle Manager", "AI Intent Router", "Dream Loop Scheduler" before implementing.

---

## Part A — Ollama Lifecycle Manager

### Step A1: `src/ollama/model_registry.rs`

```rust
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
```

### Step A2: `src/ollama/client.rs`

```rust
use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use tracing::info;

pub struct OllamaClient {
    http:    Client,
    base_url: String,
}

#[derive(Serialize)]
struct ChatPayload {
    model:      String,
    messages:   Vec<ChatMessage>,
    stream:     bool,
    keep_alive: String,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct ChatMessage {
    pub role:    String,
    pub content: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    message: ChatMessage,
}

impl OllamaClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            http:     Client::new(),
            base_url: base_url.to_string(),
        }
    }

    /// Load a model into RAM by sending a no-op chat (keep_alive = -1 keeps it alive)
    pub async fn load_model(&self, model: &str) -> Result<()> {
        let payload = ChatPayload {
            model:      model.to_string(),
            messages:   vec![ChatMessage { role: "user".into(), content: "hi".into() }],
            stream:     false,
            keep_alive: "-1".to_string(),  // keep alive indefinitely
        };
        self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;
        info!(model = model, "Model loaded into RAM");
        Ok(())
    }

    /// Evict a model from RAM immediately
    pub async fn evict_model(&self, model: &str) -> Result<()> {
        let payload = ChatPayload {
            model:      model.to_string(),
            messages:   vec![ChatMessage { role: "user".into(), content: "bye".into() }],
            stream:     false,
            keep_alive: "0".to_string(),   // evict immediately
        };
        self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?;
        info!(model = model, "Model evicted from RAM");
        Ok(())
    }

    /// Send a chat prompt and return the response string
    pub async fn chat(&self, model: &str, messages: Vec<ChatMessage>, keep_alive: i32) -> Result<String> {
        let payload = ChatPayload {
            model:      model.to_string(),
            messages,
            stream:     false,
            keep_alive: keep_alive.to_string(),
        };
        let resp: ChatResponse = self.http
            .post(format!("{}/api/chat", self.base_url))
            .json(&payload)
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?;
        Ok(resp.message.content)
    }
}
```

### Step A3: `src/ollama/lifecycle.rs`

```rust
use std::sync::Arc;
use tokio::sync::Mutex;
use anyhow::Result;
use tracing::info;

use crate::ollama::client::OllamaClient;
use crate::ollama::model_registry::{ModelRegistry, RegisteredModel};

pub struct OllamaLifecycle {
    client:   OllamaClient,
    registry: ModelRegistry,
    /// Currently loaded model name
    loaded:   Arc<Mutex<Option<String>>>,
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
        let model = self.registry.find(model_name)
            .ok_or_else(|| anyhow::anyhow!("Model not registered: {model_name}"))?;

        if model.ram_mb > self.registry.ram_cap_mb() {
            return Err(anyhow::anyhow!(
                "ERR_MODEL_TOO_LARGE: {model_name} requires {}MB, cap is {}MB",
                model.ram_mb, self.registry.ram_cap_mb()
            ));
        }

        let mut loaded = self.loaded.lock().await;

        // Evict current model if one is loaded
        if let Some(current) = loaded.as_ref() {
            if current == model_name {
                info!(model = model_name, "Already loaded");
                return Ok(());
            }
            self.client.evict_model(current).await?;
            *loaded = None;
        }

        self.client.load_model(model_name).await?;
        *loaded = Some(model_name.to_string());
        info!(model = model_name, ram_mb = model.ram_mb, "Model loaded");
        Ok(())
    }

    /// Evict the currently loaded model.
    pub async fn evict(&self) -> Result<()> {
        let mut loaded = self.loaded.lock().await;
        if let Some(model) = loaded.take() {
            self.client.evict_model(&model).await?;
            info!(model = %model, "Model evicted");
        }
        Ok(())
    }

    /// Get currently loaded model name.
    pub async fn current_model(&self) -> Option<String> {
        self.loaded.lock().await.clone()
    }
}
```

---

## Part B — AI Intent Router

### Step B1: `src/ai_router/intent_classifier.rs`

Phase 1 uses keyword heuristics (fast, no LLM required). DistilBERT gate is Phase 3+.

```rust
/// Intent classification result
#[derive(Debug, Clone, PartialEq)]
pub enum IntentClass {
    FactualPrecision,
    ReflectiveDialogue,
    CodeAst,
    CopilotCommand,
}

/// Heuristic keyword-based intent classifier.
/// Phase 1: simple keyword matching.
/// Phase 3+: replace with quantized DistilBERT gate.
pub struct IntentClassifier;

impl IntentClassifier {
    pub fn classify(prompt: &str, context_hint: Option<&str>) -> IntentClass {
        let lower = prompt.to_lowercase();

        // Context hint overrides
        if let Some(hint) = context_hint {
            match hint {
                "code" => return IntentClass::CodeAst,
                "diary" => return IntentClass::ReflectiveDialogue,
                _ => {}
            }
        }

        // Command patterns
        if lower.starts_with("take me to")
            || lower.starts_with("open ")
            || lower.starts_with("go to ")
            || lower.starts_with("show me ")
            || lower.starts_with("make the theme")
        {
            return IntentClass::CopilotCommand;
        }

        // Code patterns
        if lower.contains("function") || lower.contains("struct ") || lower.contains("impl ")
            || lower.contains("fn ") || lower.contains("cargo") || lower.contains("flutter")
            || lower.contains("dart") || lower.contains("rust") || lower.contains("code")
        {
            return IntentClass::CodeAst;
        }

        // Reflective patterns
        if lower.contains("feel") || lower.contains("today") || lower.contains("journal")
            || lower.contains("diary") || lower.contains("remember") || lower.contains("think")
        {
            return IntentClass::ReflectiveDialogue;
        }

        // Default: factual
        IntentClass::FactualPrecision
    }
}
```

### Step B2: `src/ai_router/prompt_budget.rs`

```rust
use crate::ai_router::intent_classifier::IntentClass;

pub struct PromptBudget {
    pub model:        String,
    pub temperature:  f32,
    pub max_tokens:   u32,
}

impl PromptBudget {
    /// Return the model and parameters for a given intent class
    pub fn for_intent(intent: &IntentClass) -> Self {
        match intent {
            IntentClass::FactualPrecision => Self {
                model:       "qwen2.5:1.5b".into(),
                temperature: 0.0,
                max_tokens:  512,
            },
            IntentClass::ReflectiveDialogue => Self {
                model:       "qwen2.5:1.5b".into(),
                temperature: 0.7,
                max_tokens:  1024,
            },
            IntentClass::CodeAst => Self {
                model:       "llama3.2:3b".into(),
                temperature: 0.2,
                max_tokens:  2048,
            },
            IntentClass::CopilotCommand => Self {
                model:       "qwen2.5:1.5b".into(),
                temperature: 0.1,
                max_tokens:  256,
            },
        }
    }
}
```

---

## Part C — Dream Loop Scheduler

### Step C1: `src/dream_loop/scheduler.rs`

```rust
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::info;
use anyhow::Result;

/// Nightly Dream Loop — runs at 02:00 Asia/Manila
/// (UTC+8, so 18:00 UTC)
pub struct DreamLoopScheduler;

impl DreamLoopScheduler {
    pub async fn start() -> Result<()> {
        let sched = JobScheduler::new().await?;

        // 02:00 Asia/Manila = 18:00 UTC
        // Cron: minute hour day month weekday
        let job = Job::new_async("0 18 * * *", |_uuid, _lock| {
            Box::pin(async move {
                info!(
                    module = "shua.governor",
                    subsystem = "dream_loop",
                    "Dream Loop starting"
                );
                // TODO Phase 3: run actual dream loop jobs
                // 1. UMAP projection
                // 2. Diary summary generation
                // 3. Memory compaction
                // 4. Code topology delta scan
                info!(
                    module = "shua.governor",
                    subsystem = "dream_loop",
                    "Dream Loop complete (stub)"
                );
            })
        })?;

        sched.add(job).await?;
        sched.start().await?;

        info!(
            module = "shua.governor",
            subsystem = "dream_loop",
            schedule = "02:00 Asia/Manila",
            "Dream Loop scheduler started"
        );
        Ok(())
    }
}
```

---

## Step D: Wire everything into `dispatcher.rs`

Add `governor.ollama.load`, `governor.ollama.evict`, and `governor.ai.route` operations to `handle_governor()`. The dispatcher now holds an `Arc<OllamaLifecycle>`.

```rust
"ollama.load" => {
    #[derive(serde::Deserialize)]
    struct Req { model: String }
    match frame.decode_payload::<Req>() {
        Ok(req) => match self.ollama.load(&req.model).await {
            Ok(_) => {
                let current = self.ollama.current_model().await;
                let payload_data = serde_json::json!({
                    "loaded_model": current,
                    "ram_mb": 0,      // TODO: query actual RAM
                    "duration_ms": 0  // TODO: measure duration
                });
                let payload = HbpFrame::encode_payload(&payload_data).unwrap_or_default();
                Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, payload))
            }
            Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &e.to_string())),
        },
        Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &format!("ERR_MALFORMED: {e}"))),
    }
}

"ollama.evict" => {
    match self.ollama.evict().await {
        Ok(_)  => Some(HbpFrame::response(&frame.id, &frame.mod_, &frame.op, vec![])),
        Err(e) => Some(HbpFrame::error_response(&frame.id, &frame.mod_, &frame.op, &e.to_string())),
    }
}
```

---

## Step E: Wire Dream Loop into `main.rs`

```rust
use crate::dream_loop::scheduler::DreamLoopScheduler;

// In main(), after broker starts:
tokio::spawn(async {
    if let Err(e) = DreamLoopScheduler::start().await {
        tracing::error!(error = %e, "Dream Loop scheduler failed to start");
    }
});
```

---

## Acceptance Criteria

- [ ] `OllamaClient::load_model("qwen2.5:1.5b")` loads the model on Pi5 Ollama
- [ ] `OllamaLifecycle::load()` evicts the current model before loading a new one
- [ ] `OllamaLifecycle::load()` returns `ERR_MODEL_TOO_LARGE` if model exceeds 4GB cap
- [ ] `IntentClassifier::classify("take me to diary", None)` returns `CopilotCommand`
- [ ] `IntentClassifier::classify("how do I write a Rust struct?", None)` returns `CodeAst`
- [ ] `DreamLoopScheduler::start()` starts without error and logs the schedule
- [ ] `governor.ollama.load` HBP operation works end-to-end over WebSocket
- [ ] `governor.ollama.evict` HBP operation works
- [ ] `cargo build` — no errors

---

## References

- `_architecture/specs/shua_governor/shua_governor_spec.md` — Ollama, AI Router, Dream Loop sections
- `_architecture/contracts/hbp/hbp_v2_spec.md` — `ollama.load`, `ollama.evict`, `ai.route` schemas
