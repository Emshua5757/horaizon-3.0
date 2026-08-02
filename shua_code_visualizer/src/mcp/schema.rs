use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// High-level taxonomy of code symbols extracted from source files
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum GraphNodeKind {
    Function,
    Struct,
    Enum,
    Trait,
    Interface,
    Class,
    Module,
}

/// Categorized side effects detected during AST inspection
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum SideEffect {
    Io,
    Network,
    Lock,
    StateMutation,
}

/// Directional relationship edge type between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum Relation {
    Calls,
    Implements,
    Imports,
    Instantiates,
    TypeDependency,
}

/// Single parameter signature representation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParamDto {
    pub name: String,
    pub type_name: String,
    pub is_optional: bool,
}

/// Configurable thresholds for god-function detection
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ThresholdConfig {
    pub max_params: u32,
    pub max_complexity: u32,
    pub max_loc: u32,
}

impl Default for ThresholdConfig {
    fn default() -> Self {
        Self {
            max_params: 5,
            max_complexity: 10,
            max_loc: 75,
        }
    }
}

/// Fully-resolved node payload in the code topology graph
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct GraphNode {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
    pub fan_in: u32,
    pub fan_out: u32,
    pub risk_score: f32,
    pub is_orphan: bool,
    pub exceeds_param_threshold: bool,
    pub exceeds_complexity_threshold: bool,
    pub exceeds_loc_threshold: bool,
}

/// Directional edge linking two symbols by qualified name
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct GraphEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Response container for module or full-repo topology graph exports
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyExportResponse {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

/// Classification of incremental file changes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum ChangeType {
    Added,
    Modified,
    Removed,
}

/// Live event emitted on filesystem mutations
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyDeltaEvent {
    pub file_path: String,
    pub change_type: ChangeType,
    pub affected_node_ids: Vec<String>,
}

// ============================================================================
// MCP Tool Input Argument Schemas (for schema export & contract safety)
// ============================================================================

/// Arguments for `code_parse_ast`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParseAstArgs {
    pub file_path: String,
}

/// Arguments for `code_render_graph`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct RenderGraphArgs {
    pub module_path: Option<String>,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_blast_radius`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct BlastRadiusArgs {
    pub qualified_name: String,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_find_callers`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct FindCallersArgs {
    pub qualified_name: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dto_serialization_roundtrip() {
        let node = GraphNode {
            id: "test:id".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "test_func".to_string(),
            file: "test.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: Some("()".to_string()),
            complexity: 1,
            side_effects: vec![SideEffect::Io],
            intent: Some("Test description".to_string()),
            loc: 5,
            is_public: true,
            is_test: false,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
        };

        let json = serde_json::to_string(&node).unwrap();
        let decoded: GraphNode = serde_json::from_str(&json).unwrap();
        assert_eq!(node, decoded);
    }

    #[test]
    fn test_threshold_config_default() {
        let config = ThresholdConfig::default();
        assert_eq!(config.max_params, 5);
        assert_eq!(config.max_complexity, 10);
        assert_eq!(config.max_loc, 75);
    }

    #[test]
    fn test_schema_generation() {
        let schema = schemars::schema_for!(GraphNode);
        let schema_json = serde_json::to_string(&schema).unwrap();
        assert!(schema_json.contains("GraphNode"));
        assert!(schema_json.contains("is_public"));
    }
}
