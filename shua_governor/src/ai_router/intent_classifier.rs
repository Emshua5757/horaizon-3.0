/// Intent classification categories
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IntentClass {
    FactualPrecision,
    ReflectiveDialogue,
    CodeAst,
    CopilotCommand,
}

impl IntentClass {
    pub fn as_str(&self) -> &'static str {
        match self {
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
    pub fn classify(prompt: &str, context_hint: Option<&str>) -> IntentClass {
        let lower = prompt.to_lowercase();

        // Context hint overrides
        if let Some(hint) = context_hint {
            match hint {
                "code" => return IntentClass::CodeAst,
                "diary" => return IntentClass::ReflectiveDialogue,
                "copilot" => return IntentClass::CopilotCommand,
                _ => {}
            }
        }

        // Command patterns
        if lower.starts_with("take me to")
            || lower.starts_with("open ")
            || lower.starts_with("go to ")
            || lower.starts_with("show me ")
            || lower.starts_with("make the theme")
            || lower.starts_with("switch to")
        {
            return IntentClass::CopilotCommand;
        }

        // Code patterns
        if lower.contains("function")
            || lower.contains("struct ")
            || lower.contains("impl ")
            || lower.contains("fn ")
            || lower.contains("cargo")
            || lower.contains("flutter")
            || lower.contains("dart")
            || lower.contains("rust")
            || lower.contains("code")
            || lower.contains("refactor")
        {
            return IntentClass::CodeAst;
        }

        // Reflective patterns
        if lower.contains("feel")
            || lower.contains("today")
            || lower.contains("journal")
            || lower.contains("diary")
            || lower.contains("remember")
            || lower.contains("think")
            || lower.contains("reflection")
        {
            return IntentClass::ReflectiveDialogue;
        }

        // Default: factual precision
        IntentClass::FactualPrecision
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_intent_classification() {
        assert_eq!(
            IntentClassifier::classify("take me to diary", None),
            IntentClass::CopilotCommand
        );
        assert_eq!(
            IntentClassifier::classify("how do I write a Rust struct?", None),
            IntentClass::CodeAst
        );
        assert_eq!(
            IntentClassifier::classify("how do I feel today?", None),
            IntentClass::ReflectiveDialogue
        );
        assert_eq!(
            IntentClassifier::classify("what is the capital of France?", None),
            IntentClass::FactualPrecision
        );
    }
}
