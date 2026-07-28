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
    /// Returns `(intent, matched_rule, confidence)`.
    ///
    /// - `matched_rule` — log alongside intent for debuggable misroute tracing.
    /// - `confidence`   — 0.0–1.0 fraction of prompt tokens that matched the
    ///   winning keyword set. Phrase matches contribute 0.5 bonus each (capped
    ///   at 1.0). Context-hint overrides always return 1.0. Default
    ///   `FactualPrecision` returns 0.3 (low confidence — no keywords matched).
    pub fn classify(prompt: &str, context_hint: Option<&str>) -> (IntentClass, &'static str, f32) {
        let lower = prompt.to_lowercase();
        let word_count = lower.split_whitespace().count().max(1) as f32;

        // Context hint overrides — confidence = 1.0 (explicit caller direction)
        if let Some(hint) = context_hint {
            match hint {
                "system"  => return (IntentClass::SystemQuery,       "hint:system",  1.0),
                "code"    => return (IntentClass::CodeAst,           "hint:code",    1.0),
                "diary"   => return (IntentClass::ReflectiveDialogue,"hint:diary",   1.0),
                "copilot" => return (IntentClass::CopilotCommand,    "hint:copilot", 1.0),
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
        let sys_word_hits = count_word_hits(&lower, SYSTEM_WORDS);
        let sys_phrase_hits = count_phrase_hits(&lower, SYSTEM_PHRASES);
        if sys_word_hits > 0 || sys_phrase_hits > 0 {
            let conf = ((sys_word_hits as f32 / word_count)
                + (sys_phrase_hits as f32 * 0.5))
                .clamp(0.0, 1.0);
            return (IntentClass::SystemQuery, "system_keyword", conf);
        }

        // Command patterns for UI navigation — prefix-based, confidence 0.85
        if lower.starts_with("take me to")
            || lower.starts_with("open ")
            || lower.starts_with("go to ")
            || lower.starts_with("make the theme")
            || lower.starts_with("switch to")
        {
            return (IntentClass::CopilotCommand, "nav_prefix", 0.85);
        }

        // Code patterns — word-boundary checked, not substring `contains`,
        // to avoid "rust" matching "trust"/"crust", "code" matching
        // "encode"/"barcode"/"decode", etc.
        const CODE_WORDS: &[&str] = &[
            "function", "struct", "impl", "fn", "cargo", "flutter", "dart",
            "rust", "code", "refactor",
        ];
        let code_hits = count_word_hits(&lower, CODE_WORDS);
        if code_hits > 0 {
            let conf = (code_hits as f32 / word_count).clamp(0.0, 1.0);
            return (IntentClass::CodeAst, "code_keyword", conf);
        }

        // Reflective patterns
        const REFLECTIVE_WORDS: &[&str] = &[
            "feel", "feeling", "feelings", "today", "journal", "diary",
            "remember", "think", "thinking", "reflect", "reflection", "reflecting",
        ];
        let ref_hits = count_word_hits(&lower, REFLECTIVE_WORDS);
        if ref_hits > 0 {
            let conf = (ref_hits as f32 / word_count).clamp(0.0, 1.0);
            return (IntentClass::ReflectiveDialogue, "reflective_keyword", conf);
        }

        // Default: factual precision — low confidence (no keywords matched)
        (IntentClass::FactualPrecision, "default", 0.3)
    }
}

fn has_word(text: &str, word: &str) -> bool {
    text.split_whitespace().any(|w| {
        w.trim_matches(|c: char| !c.is_alphanumeric()).eq_ignore_ascii_case(word)
    })
}

fn count_word_hits(text: &str, words: &[&str]) -> usize {
    words.iter().filter(|w| has_word(text, w)).count()
}

fn count_phrase_hits(text: &str, phrases: &[&str]) -> usize {
    phrases.iter().filter(|p| text.contains(*p)).count()
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

    #[test]
    fn test_confidence_hint_always_one() {
        let (_, _, conf) = IntentClassifier::classify("anything", Some("system"));
        assert!((conf - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_confidence_default_low() {
        let (intent, _, conf) = IntentClassifier::classify("what is the capital of France?", None);
        assert_eq!(intent, IntentClass::FactualPrecision);
        assert!(conf <= 0.3 + f32::EPSILON);
    }
}
