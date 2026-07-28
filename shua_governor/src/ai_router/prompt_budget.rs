use crate::ai_router::intent_classifier::IntentClass;

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct PromptBudget {
    pub model: String,
    pub temperature: f32,
    pub max_tokens: u32,
    pub offload_url: Option<String>,
    /// When true, McpAgentLoop enforces tool use via a stronger system-prompt
    /// directive and a one-time corrective nudge if the model answers in
    /// free text without calling a tool on the first turn. Ollama's native
    /// /api/chat endpoint has no tool_choice param, so this is enforced at
    /// the prompt/loop level rather than the API level.
    pub force_tool_choice: bool,
}

impl PromptBudget {
    /// Return the model, parameters, and optional offload endpoint for a given intent class.
    /// Respects client-requested model if provided, falling back to intent defaults.
    pub fn for_intent(
        intent: &IntentClass,
        offload_device_url: Option<&str>,
        requested_model: Option<&str>,
    ) -> Self {
        let offload_url = offload_device_url
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string());

        let default_model = "qwen2.5:1.5b";

        let selected_model = requested_model
            .filter(|s| !s.is_empty())
            .unwrap_or(default_model)
            .to_string();

        match intent {
            IntentClass::SystemQuery => Self {
                model: selected_model,
                temperature: 0.0,
                max_tokens: 512,
                offload_url,
                force_tool_choice: true,
            },
            IntentClass::FactualPrecision => Self {
                model: selected_model,
                temperature: 0.0,
                max_tokens: 512,
                offload_url,
                force_tool_choice: false,
            },
            IntentClass::ReflectiveDialogue => Self {
                model: selected_model,
                temperature: 0.7,
                max_tokens: 1024,
                offload_url,
                force_tool_choice: false,
            },
            IntentClass::CodeAst => Self {
                model: selected_model,
                temperature: 0.2,
                max_tokens: 2048,
                offload_url,
                force_tool_choice: false,
            },
            IntentClass::CopilotCommand => Self {
                model: selected_model,
                temperature: 0.1,
                max_tokens: 256,
                offload_url,
                force_tool_choice: false,
            },
        }
    }
}
