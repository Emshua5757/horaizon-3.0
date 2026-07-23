use crate::ai_router::intent_classifier::IntentClass;

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct PromptBudget {
    pub model: String,
    pub temperature: f32,
    pub max_tokens: u32,
    pub offload_url: Option<String>,
}

impl PromptBudget {
    /// Return the model, parameters, and optional offload endpoint for a given intent class
    pub fn for_intent(intent: &IntentClass, offload_device_url: Option<&str>) -> Self {
        match intent {
            IntentClass::FactualPrecision => Self {
                model: "qwen2.5:1.5b".into(),
                temperature: 0.0,
                max_tokens: 512,
                offload_url: None,
            },
            IntentClass::ReflectiveDialogue => Self {
                model: "qwen2.5:1.5b".into(),
                temperature: 0.7,
                max_tokens: 1024,
                offload_url: None,
            },
            IntentClass::CodeAst => Self {
                model: "llama3.2:3b".into(),
                temperature: 0.2,
                max_tokens: 2048,
                offload_url: offload_device_url.map(|s| s.to_string()),
            },
            IntentClass::CopilotCommand => Self {
                model: "qwen2.5:1.5b".into(),
                temperature: 0.1,
                max_tokens: 256,
                offload_url: None,
            },
        }
    }
}
