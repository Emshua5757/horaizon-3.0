use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation, SideEffect};
use serde::{Deserialize, Serialize};

/// Extracted AST symbol definition before graph resolution
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ExtractedSymbol {
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
}

/// Extracted directional relationship edge between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ExtractedEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Consolidated parser result payload for a single source file
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ParseResult {
    pub symbols: Vec<ExtractedSymbol>,
    pub edges: Vec<ExtractedEdge>,
}

/// Unified trait implemented by language-specific Tree-sitter extractors
pub trait LanguageExtractor: Send + Sync {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult;
}
