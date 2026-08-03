use super::McpToolSchema;

pub struct ScopeFilter;

impl ScopeFilter {
    /// Filters given list of tools based on context scope tag.
    /// Core governor system tools ("governor", "all", "*") are always included.
    /// Module-specific tools (e.g. "code", "diary", "resume") are included when matching the active target_scope.
    pub fn filter_tools(tools: Vec<McpToolSchema>, target_scope: &str) -> Vec<McpToolSchema> {
        let normalized = target_scope.trim().to_lowercase();
        if normalized.is_empty() || normalized == "all" || normalized == "*" {
            return tools;
        }

        tools
            .into_iter()
            .filter(|tool| {
                let tool_scope = tool.scope.to_lowercase();
                tool_scope == normalized
                    || tool_scope == "governor"
                    || tool_scope == "all"
                    || tool_scope == "*"
                    || normalized == "global"
                    || normalized == "default"
            })
            .collect()
    }
}
