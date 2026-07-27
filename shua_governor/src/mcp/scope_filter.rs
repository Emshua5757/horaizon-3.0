use super::McpToolSchema;

pub struct ScopeFilter;

impl ScopeFilter {
    /// Filters given list of tools based on context scope tag
    pub fn filter_tools(tools: Vec<McpToolSchema>, target_scope: &str) -> Vec<McpToolSchema> {
        let normalized = target_scope.trim().to_lowercase();
        if normalized.is_empty() || normalized == "all" || normalized == "*" {
            return tools;
        }

        tools
            .into_iter()
            .filter(|tool| {
                let tool_scope = tool.scope.to_lowercase();
                if tool_scope == normalized {
                    return true;
                }
                // Global chat scope includes governor tools + system tools
                if (normalized == "global" || normalized == "default") && (tool_scope == "governor" || tool_scope == "global") {
                    return true;
                }
                false
            })
            .collect()
    }
}
