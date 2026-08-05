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
    /// Maximum user prompt length (chars) accepted before tail-truncation.
    /// Prevents oversized KV-cache allocations on RPi5 Ollama even when
    /// inference is offloaded (broker still serialises the full request body).
    pub max_prompt_chars: usize,
    /// Minimum wall-clock gap (ms) inserted before each local Ollama LLM call
    /// to prevent back-to-back thermal spikes on RPi5.
    /// Only applied when inference target is local (127.0.0.1 / localhost).
    pub min_inference_gap_ms: u64,
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

        let default_model = "qwen3.5:4b";

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
                max_prompt_chars: 800,
                min_inference_gap_ms: 250,
            },
            IntentClass::FactualPrecision => Self {
                model: selected_model,
                temperature: 0.0,
                max_tokens: 4096,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 16000,
                min_inference_gap_ms: 250,
            },
            IntentClass::ReflectiveDialogue => Self {
                model: selected_model,
                temperature: 0.7,
                max_tokens: 1024,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 2000,
                min_inference_gap_ms: 500,
            },
            IntentClass::CodeAst => Self {
                model: selected_model,
                temperature: 0.2,
                max_tokens: 2048,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 3000,
                min_inference_gap_ms: 500,
            },
            IntentClass::CopilotCommand => Self {
                model: selected_model,
                temperature: 0.1,
                max_tokens: 256,
                offload_url,
                force_tool_choice: false,
                max_prompt_chars: 400,
                min_inference_gap_ms: 250,
            },
        }
    }
}
