/// Intent classification categories
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IntentClass {
    SystemQuery,       // governor/MCP/telemetry — must guarantee tool use
    FactualPrecision,
    ReflectiveDialogue,
    CodeAst,
    CopilotCommand,
}

impl IntentClass {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::SystemQuery => "system_query",
            Self::FactualPrecision => "factual_precision",
            Self::ReflectiveDialogue => "reflective_dialogue",
            Self::CodeAst => "code_ast",
            Self::CopilotCommand => "copilot_command",
        }
    }
}

/// Heuristic keyword-based intent classifier.
pub struct IntentClassifier;

impl IntentClassifier {
    /// Returns (intent, matched_rule). matched_rule is for logging — log it
    /// alongside the intent in the dispatcher so misroutes are debuggable
    /// instead of guesswork.
    pub fn classify(prompt: &str, context_hint: Option<&str>) -> (IntentClass, &'static str) {
        let lower = prompt.to_lowercase();

        // Context hint overrides
        if let Some(hint) = context_hint {
            match hint {
                "system" => return (IntentClass::SystemQuery, "hint:system"),
                "code" => return (IntentClass::CodeAst, "hint:code"),
                "diary" => return (IntentClass::ReflectiveDialogue, "hint:diary"),
                "copilot" => return (IntentClass::CopilotCommand, "hint:copilot"),
                _ => {}
            }
        }

        // SystemQuery is checked FIRST. Anything asking about governor
        // internals, telemetry, or MCP tools must guarantee tool use
        // downstream — it can't be left to fall through into the default
        // FactualPrecision bucket silently, or the model is free to
        // hallucinate an answer instead of calling the real tool.
        const SYSTEM_WORDS: &[&str] = &[
            "log", "logs", "metric", "metrics", "uptime", "nvme", "cpu", "ram",
            "temperature", "governor", "module",
        ];
        const SYSTEM_PHRASES: &[&str] = &[
            "mcp tool", "mcp tools", "system health", "load model", "wake module",
            "sleep module", "query_logs", "get_metrics",
        ];
        if has_any_word(&lower, SYSTEM_WORDS) || has_any_phrase(&lower, SYSTEM_PHRASES) {
            return (IntentClass::SystemQuery, "system_keyword");
        }

        // Command patterns for UI navigation
        if lower.starts_with("take me to")
            || lower.starts_with("open ")
            || lower.starts_with("go to ")
            || lower.starts_with("make the theme")
            || lower.starts_with("switch to")
        {
            return (IntentClass::CopilotCommand, "nav_prefix");
        }

        // Code patterns — word-boundary checked, not substring `contains`,
        // to avoid "rust" matching "trust"/"crust", "code" matching
        // "encode"/"barcode"/"decode", etc.
        const CODE_WORDS: &[&str] = &[
            "function", "struct", "impl", "fn", "cargo", "flutter", "dart",
            "rust", "code", "refactor",
        ];
        if has_any_word(&lower, CODE_WORDS) {
            return (IntentClass::CodeAst, "code_keyword");
        }

        // Reflective patterns
        const REFLECTIVE_WORDS: &[&str] = &[
            "feel", "feeling", "feelings", "today", "journal", "diary",
            "remember", "think", "thinking", "reflect", "reflection", "reflecting",
        ];
        if has_any_word(&lower, REFLECTIVE_WORDS) {
            return (IntentClass::ReflectiveDialogue, "reflective_keyword");
        }

        // Default: factual precision
        (IntentClass::FactualPrecision, "default")
    }
}

fn has_word(text: &str, word: &str) -> bool {
    text.split_whitespace().any(|w| {
        w.trim_matches(|c: char| !c.is_alphanumeric()).eq_ignore_ascii_case(word)
    })
}

fn has_any_word(text: &str, words: &[&str]) -> bool {
    words.iter().any(|w| has_word(text, w))
}

fn has_any_phrase(text: &str, phrases: &[&str]) -> bool {
    phrases.iter().any(|p| text.contains(p))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_intent_classification() {
        assert_eq!(
            IntentClassifier::classify("take me to diary", None).0,
            IntentClass::CopilotCommand
        );
        assert_eq!(
            IntentClassifier::classify("how do I write a Rust struct?", None).0,
            IntentClass::CodeAst
        );
        assert_eq!(
            IntentClassifier::classify("how do I feel today?", None).0,
            IntentClass::ReflectiveDialogue
        );
        assert_eq!(
            IntentClassifier::classify("what is the capital of France?", None).0,
            IntentClass::FactualPrecision
        );
    }

    #[test]
    fn test_word_boundary_code_matching() {
        assert_eq!(
            IntentClassifier::classify("how do I decode a barcode?", None).0,
            IntentClass::FactualPrecision
        );
        assert_eq!(
            IntentClassifier::classify("explain this code snippet", None).0,
            IntentClass::CodeAst
        );
    }

    #[test]
    fn test_system_query_classification() {
        assert_eq!(
            IntentClassifier::classify(
                "Show me the output of governor_query_logs for the last 100 entries",
                None
            ).0,
            IntentClass::SystemQuery
        );
        assert_eq!(
            IntentClassifier::classify("what are the mcp tools you have available?", None).0,
            IntentClass::SystemQuery
        );
        assert_eq!(
            IntentClassifier::classify("what's the CPU temperature right now?", None).0,
            IntentClass::SystemQuery
        );
    }
}
