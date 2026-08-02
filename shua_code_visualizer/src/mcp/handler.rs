use crate::graph::store::CodeGraph;
use crate::mcp::schema::{
    BlastRadiusArgs, FindCallersArgs, ParseAstArgs, ReadFileArgs, RenderGraphArgs, ThresholdConfig,
};
use crate::parser::parse_file;
use petgraph::visit::EdgeRef;
use serde_json::Value;

/// Central dispatch handler for all 8 `code_*` MCP tools
pub struct McpHandler<'a> {
    pub graph: &'a mut CodeGraph,
    pub threshold_config: ThresholdConfig,
}

impl<'a> McpHandler<'a> {
    pub fn new(graph: &'a mut CodeGraph, threshold_config: Option<ThresholdConfig>) -> Self {
        Self {
            graph,
            threshold_config: threshold_config.unwrap_or_default(),
        }
    }

    /// Dispatches an incoming MCP tool call by name
    pub fn handle_tool_call(&mut self, tool_name: &str, args: &Value) -> Result<Value, String> {
        match tool_name {
            "code_parse_ast" => self.parse_ast(args),
            "code_read_file" => self.read_file(args),
            "code_render_graph" => self.render_graph(args),
            "code_blast_radius" => self.blast_radius(args),
            "code_find_callers" => self.find_callers(args),
            "code_find_dead_code" => self.find_dead_code(),
            "code_find_god_functions" => self.find_god_functions(),
            "code_check_contract_drift" => self.check_contract_drift(args),
            _ => Err(format!("Unknown MCP tool: {}", tool_name)),
        }
    }

    /// `code_parse_ast`: Parses single file and returns symbol/edge extraction payload
    fn parse_ast(&self, args: &Value) -> Result<Value, String> {
        let typed_args: ParseAstArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid ParseAstArgs: {}", e))?;
        let code = std::fs::read_to_string(&typed_args.file_path)
            .map_err(|e| format!("Failed to read file '{}': {}", typed_args.file_path, e))?;

        let res = parse_file(&code, &typed_args.file_path, None);
        serde_json::to_value(res).map_err(|e| e.to_string())
    }

    /// `code_read_file`: Fetches raw source code text or line-range snippet for target file
    fn read_file(&self, args: &Value) -> Result<Value, String> {
        let typed_args: ReadFileArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid ReadFileArgs: {}", e))?;

        let full_text = std::fs::read_to_string(&typed_args.file_path)
            .map_err(|e| format!("Failed to read file '{}': {}", typed_args.file_path, e))?;

        let lines: Vec<&str> = full_text.lines().collect();
        let total_lines = lines.len() as u32;

        let start = typed_args.start_line.unwrap_or(1).max(1) as usize;
        let end = typed_args.end_line.unwrap_or(total_lines).min(total_lines) as usize;

        if start > lines.len() || start > end {
            return serde_json::to_value(serde_json::json!({
                "file_path": typed_args.file_path,
                "total_lines": total_lines,
                "lines": [],
                "code": ""
            })).map_err(|e| e.to_string());
        }

        let sliced = &lines[(start - 1)..end];
        let code_str = sliced.join("\n");

        serde_json::to_value(serde_json::json!({
            "file_path": typed_args.file_path,
            "start_line": start,
            "end_line": end,
            "total_lines": total_lines,
            "code": code_str
        })).map_err(|e| e.to_string())
    }

    /// `code_render_graph`: Renders graph export payload filtered by module path and max depth
    fn render_graph(&self, args: &Value) -> Result<Value, String> {
        let typed_args: RenderGraphArgs = serde_json::from_value(args.clone())
            .unwrap_or(RenderGraphArgs {
                module_path: None,
                max_depth: None,
            });

        let export = self
            .graph
            .render_subgraph(typed_args.module_path.as_deref(), typed_args.max_depth);
        serde_json::to_value(export).map_err(|e| e.to_string())
    }

    /// `code_blast_radius`: Performs BFS caller depth search for target symbol
    fn blast_radius(&self, args: &Value) -> Result<Value, String> {
        let typed_args: BlastRadiusArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid BlastRadiusArgs: {}", e))?;
        let max_depth = typed_args.max_depth.unwrap_or(3);

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut caller_nodes = Vec::new();
        let mut queue = vec![(root_idx, 0usize)];
        let mut visited = std::collections::HashSet::new();
        visited.insert(root_idx);

        while let Some((curr, depth)) = queue.pop() {
            if depth < max_depth {
                for edge_ref in self.graph.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                    let source_idx = edge_ref.source();
                    if visited.insert(source_idx) {
                        if let Some(weight) = self.graph.graph.node_weight(source_idx) {
                            caller_nodes.push(weight.clone());
                        }
                        queue.push((source_idx, depth + 1));
                    }
                }
            }
        }

        serde_json::to_value(caller_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_callers`: Returns direct caller nodes of target symbol
    fn find_callers(&self, args: &Value) -> Result<Value, String> {
        let typed_args: FindCallersArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid FindCallersArgs: {}", e))?;

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut callers = Vec::new();
        for edge_ref in self.graph.graph.edges_directed(root_idx, petgraph::Direction::Incoming) {
            if let Some(weight) = self.graph.graph.node_weight(edge_ref.source()) {
                callers.push(weight.clone());
            }
        }

        serde_json::to_value(callers).map_err(|e| e.to_string())
    }

    /// `code_find_dead_code`: Returns unreferenced non-pub, non-test symbols
    fn find_dead_code(&self) -> Result<Value, String> {
        let mut dead_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                if weight.fan_in == 0
                    && !weight.is_public
                    && !weight.is_test
                    && weight.qualified_name != "main"
                    && !weight.qualified_name.ends_with("::main")
                {
                    let mut node_copy = weight.clone();
                    node_copy.is_orphan = true;
                    dead_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(dead_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_god_functions`: Returns functions exceeding complexity / loc / param thresholds
    fn find_god_functions(&self) -> Result<Value, String> {
        let mut god_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                let exceeds_loc = weight.loc > self.threshold_config.max_loc;
                let exceeds_complexity = weight.complexity > self.threshold_config.max_complexity;
                let exceeds_param = (weight.params.len() as u32) > self.threshold_config.max_params;

                if exceeds_loc || exceeds_complexity || exceeds_param {
                    let mut node_copy = weight.clone();
                    node_copy.exceeds_loc_threshold = exceeds_loc;
                    node_copy.exceeds_complexity_threshold = exceeds_complexity;
                    node_copy.exceeds_param_threshold = exceeds_param;
                    god_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(god_nodes).map_err(|e| e.to_string())
    }

    /// `code_check_contract_drift`: Verifies AST symbols against HBP contract schemas
    fn check_contract_drift(&self, _args: &Value) -> Result<Value, String> {
        let drift_report = serde_json::json!({
            "status": "not_implemented",
            "message": "Contract drift analysis is deferred to TASK-015A §9"
        });
        Ok(drift_report)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNode, GraphNodeKind};
    use crate::parser::extractor::ExtractedSymbol;

    #[test]
    fn test_all_mcp_tools() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/lib.rs:process".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "process".to_string(),
            file: "src/lib.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 25, // exceeds complexity threshold
            side_effects: vec![],
            intent: None,
            loc: 120, // exceeds loc threshold
            is_public: false,
            is_test: false,
        };

        graph.add_symbol(s1);

        let mut handler = McpHandler::new(&mut graph, None);

        let god_res = handler.handle_tool_call("code_find_god_functions", &serde_json::json!({})).unwrap();
        let god_nodes: Vec<GraphNode> = serde_json::from_value(god_res).unwrap();
        assert_eq!(god_nodes.len(), 1);
        assert!(god_nodes[0].exceeds_complexity_threshold);

        let dead_res = handler.handle_tool_call("code_find_dead_code", &serde_json::json!({})).unwrap();
        let dead_nodes: Vec<GraphNode> = serde_json::from_value(dead_res).unwrap();
        assert_eq!(dead_nodes.len(), 1);
    }
}
