use crate::mcp::schema::{ChangeType, GraphEdge, GraphNode, TopologyDeltaEvent, TopologyExportResponse};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, ParseResult};
use crate::parser::parse_file;
use petgraph::stable_graph::{NodeIndex, StableDiGraph};
use petgraph::visit::{EdgeRef, IntoEdgeReferences};
use std::collections::{HashMap, HashSet};

/// Checks if string matches module path target respecting boundary delimiters (`/`, `::`, `.`)
fn is_module_match(file: &str, qualified_name: &str, target: &str) -> bool {
    let check = |s: &str| {
        if s == target {
            return true;
        }
        if s.starts_with(target) {
            let remainder = &s[target.len()..];
            remainder.starts_with('/') || remainder.starts_with("::") || remainder.starts_with('.')
        } else {
            false
        }
    };
    check(file) || check(qualified_name)
}

/// In-memory graph resolution engine backed by `petgraph::stable_graph::StableDiGraph`
pub struct CodeGraph {
    pub graph: StableDiGraph<GraphNode, GraphEdge>,
    pub index: HashMap<String, NodeIndex>,
}

impl Default for CodeGraph {
    fn default() -> Self {
        Self::new()
    }
}

impl CodeGraph {
    /// Initializes an empty `CodeGraph`
    pub fn new() -> Self {
        Self {
            graph: StableDiGraph::new(),
            index: HashMap::new(),
        }
    }

    /// Adds or updates an extracted symbol node in the graph
    pub fn add_symbol(&mut self, sym: ExtractedSymbol) -> NodeIndex {
        let node_payload = GraphNode {
            id: sym.id,
            kind: sym.kind,
            qualified_name: sym.qualified_name.clone(),
            file: sym.file,
            line: sym.line,
            params: sym.params,
            return_type: sym.return_type,
            complexity: sym.complexity,
            side_effects: sym.side_effects,
            intent: sym.intent,
            loc: sym.loc,
            is_public: sym.is_public,
            is_test: sym.is_test,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
        };

        if let Some(&existing_idx) = self.index.get(&sym.qualified_name) {
            if let Some(weight) = self.graph.node_weight_mut(existing_idx) {
                *weight = node_payload;
            }
            existing_idx
        } else {
            let idx = self.graph.add_node(node_payload);
            self.index.insert(sym.qualified_name, idx);
            idx
        }
    }

    /// Adds a relationship edge, failing closed (safely dropping) if callee target is unresolved
    pub fn add_edge(&mut self, edge: ExtractedEdge) -> bool {
        let from_idx = match self.index.get(&edge.from) {
            Some(&idx) => idx,
            None => return false,
        };

        // Fail-closed check: drop edge if callee `to` symbol cannot be resolved
        let to_idx = match self.index.get(&edge.to) {
            Some(&idx) => idx,
            None => return false,
        };

        let edge_payload = GraphEdge {
            from: edge.from,
            to: edge.to,
            relation: edge.relation,
        };

        self.graph.add_edge(from_idx, to_idx, edge_payload);
        true
    }

    /// Populates the graph from multiple parser results and computes initial fan_in / fan_out metrics
    pub fn build_from_parse_results(&mut self, results: &[ParseResult]) {
        self.graph.clear();
        self.index.clear();

        for res in results {
            for sym in &res.symbols {
                self.add_symbol(sym.clone());
            }
        }

        for res in results {
            for edge in &res.edges {
                self.add_edge(edge.clone());
            }
        }

        self.update_degree_metrics();
    }

    /// Safely removes all symbols and connected edges belonging to a file path without corrupting node indices
    pub fn remove_file_symbols(&mut self, file_path: &str) {
        let to_remove: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    weight.file == file_path
                } else {
                    false
                }
            })
            .collect();

        for idx in to_remove {
            if let Some(weight) = self.graph.remove_node(idx) {
                self.index.remove(&weight.qualified_name);
            }
        }
    }

    /// Incremental graph patch execution for a single modified/created/deleted file
    pub fn apply_incremental_file_patch(&mut self, file_path: &str, code_opt: Option<&str>) -> TopologyDeltaEvent {
        let change_type = if code_opt.is_some() {
            if self
                .graph
                .node_indices()
                .any(|idx| self.graph.node_weight(idx).map_or(false, |w| w.file == file_path))
            {
                ChangeType::Modified
            } else {
                ChangeType::Added
            }
        } else {
            ChangeType::Removed
        };

        // 1. Remove existing symbols for this file
        self.remove_file_symbols(file_path);

        let mut affected_node_ids = Vec::new();

        // 2. Reparse file and add symbols/edges if code exists
        if let Some(code) = code_opt {
            let parse_res = parse_file(code, file_path, None);
            for sym in parse_res.symbols {
                affected_node_ids.push(sym.id.clone());
                self.add_symbol(sym);
            }
            for edge in parse_res.edges {
                self.add_edge(edge);
            }
        }

        // 3. Update degree metrics
        self.update_degree_metrics();

        TopologyDeltaEvent {
            file_path: file_path.to_string(),
            change_type,
            affected_node_ids,
        }
    }

    /// Computes fan_in, fan_out, and basic risk scores for all nodes
    pub fn update_degree_metrics(&mut self) {
        let node_indices: Vec<NodeIndex> = self.graph.node_indices().collect();

        for idx in node_indices {
            let fan_in = self.graph.edges_directed(idx, petgraph::Incoming).count() as u32;
            let fan_out = self.graph.edges_directed(idx, petgraph::Outgoing).count() as u32;

            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.fan_in = fan_in;
                weight.fan_out = fan_out;
                weight.risk_score = (weight.complexity * fan_in) as f32;
                // Heuristic placeholder for basic node isolation (fan_in == 0 && fan_out == 0).
                // Full dead-code detection (TASK-015A §7 / code_find_dead_code) applies pub/test/entrypoint exemptions.
                weight.is_orphan = fan_in == 0 && fan_out == 0;
            }
        }
    }

    /// Renders a module/depth subgraph export payload using BFS bounded by max_depth hops
    pub fn render_subgraph(&self, module_path: Option<&str>, max_depth: Option<usize>) -> TopologyExportResponse {
        let depth_limit = max_depth.unwrap_or(2);
        let mut included_nodes = HashSet::new();

        // 1. Identify root nodes matching module_path (or all nodes if None)
        let root_nodes: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    if let Some(m_path) = module_path {
                        is_module_match(&weight.file, &weight.qualified_name, m_path)
                    } else {
                        true
                    }
                } else {
                    false
                }
            })
            .collect();

        // 2. Perform BFS from roots bounded by max_depth
        for root in root_nodes {
            included_nodes.insert(root);
            let mut queue = vec![(root, 0usize)];
            let mut visited = HashSet::new();
            visited.insert(root);

            while let Some((curr, curr_depth)) = queue.pop() {
                if curr_depth < depth_limit {
                    let mut neighbors = Vec::new();
                    for edge_ref in self.graph.edges_directed(curr, petgraph::Direction::Outgoing) {
                        neighbors.push(edge_ref.target());
                    }
                    for edge_ref in self.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                        neighbors.push(edge_ref.source());
                    }

                    for neighbor in neighbors {
                        included_nodes.insert(neighbor);
                        if visited.insert(neighbor) {
                            queue.push((neighbor, curr_depth + 1));
                        }
                    }
                }
            }
        }

        let mut nodes = Vec::new();
        for &idx in &included_nodes {
            if let Some(weight) = self.graph.node_weight(idx) {
                nodes.push(weight.clone());
            }
        }

        let mut edges = Vec::new();
        for edge_ref in self.graph.edge_references() {
            if included_nodes.contains(&edge_ref.source()) && included_nodes.contains(&edge_ref.target()) {
                edges.push(edge_ref.weight().clone());
            }
        }

        TopologyExportResponse { nodes, edges }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation};

    #[test]
    fn test_dangling_callee_edge_fail_closed() {
        let mut graph = CodeGraph::new();

        let sym_caller = ExtractedSymbol {
            id: "src/main.rs:main".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "main".to_string(),
            file: "src/main.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 10,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(sym_caller);

        let dangling_edge = ExtractedEdge {
            from: "main".to_string(),
            to: "self.foo".to_string(),
            relation: Relation::Calls,
        };

        let added = graph.add_edge(dangling_edge);
        assert!(!added, "Dangling edge to unresolved symbol must be safely dropped (fail closed)");
        assert_eq!(graph.graph.edge_count(), 0);
    }

    #[test]
    fn test_stable_digraph_multi_symbol_removal() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/a.rs:fn1".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn1".to_string(),
            file: "src/a.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s2 = ExtractedSymbol {
            id: "src/a.rs:fn2".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn2".to_string(),
            file: "src/a.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s3 = ExtractedSymbol {
            id: "src/b.rs:fn3".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn3".to_string(),
            file: "src/b.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(s1);
        graph.add_symbol(s2);
        graph.add_symbol(s3);

        graph.remove_file_symbols("src/a.rs");

        assert_eq!(graph.graph.node_count(), 1);
        let remaining = graph.index.get("fn3").expect("fn3 in src/b.rs must survive");
        assert_eq!(graph.graph.node_weight(*remaining).unwrap().qualified_name, "fn3");
    }
}
