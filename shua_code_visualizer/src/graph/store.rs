use crate::mcp::schema::{
    ChangeType, GraphEdge, GraphNode, GraphNodeKind, SideEffect, ThresholdConfig,
    TopologyDeltaEvent, TopologyExportResponse,
};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, ParseResult};
use crate::parser::parse_file;
use petgraph::algo::tarjan_scc;
use petgraph::stable_graph::{NodeIndex, StableDiGraph};
use petgraph::visit::{EdgeRef, IntoEdgeReferences};
use std::collections::{HashMap, HashSet};

/// Helper normalizing all Windows backslashes `\` to forward slashes `/`
fn normalize_path(path: &str) -> String {
    path.replace('\\', "/")
}

/// Checks if string matches module path target respecting boundary delimiters (`/`, `::`, `.`) and dot/underscore variants
fn is_module_match(file: &str, qualified_name: &str, target: &str) -> bool {
    let target_clean = target.trim();
    if target_clean.is_empty() {
        return true;
    }
    let target_underscore = target_clean.replace('.', "_");
    let target_dot = target_clean.replace('_', ".");

    let check = |s: &str| {
        if s == target_clean || s == target_underscore || s == target_dot {
            return true;
        }
        if s.contains(target_clean) || s.contains(&target_underscore) || s.contains(&target_dot) {
            return true;
        }
        false
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
        let norm_id = normalize_path(&sym.id);
        let norm_file = normalize_path(&sym.file);

        let module_path = if norm_file.contains('/') {
            norm_file
                .rsplit_once('/')
                .map(|(dir, _)| dir)
                .unwrap_or("root")
                .to_string()
        } else {
            "root".to_string()
        };

        let is_async = sym.kind == GraphNodeKind::Function
            && (sym.return_type.as_deref().unwrap_or("").contains("Future")
                || sym.return_type.as_deref().unwrap_or("").contains("impl")
                || sym.qualified_name.contains("async")
                || sym.side_effects.contains(&SideEffect::Io));

        let is_blocking =
            sym.kind == GraphNodeKind::Function && sym.side_effects.contains(&SideEffect::Io);

        let node_payload = GraphNode {
            id: norm_id,
            kind: sym.kind,
            qualified_name: sym.qualified_name.clone(),
            file: norm_file,
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
            is_entrypoint: false,
            scc_id: None,
            module_path,
            is_async,
            is_blocking,
            dag_level: 0,
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

    /// Adds a relationship edge, resolving method names to qualified names safely
    pub fn add_edge(&mut self, edge: ExtractedEdge) -> bool {
        let norm_from = normalize_path(&edge.from);
        let norm_to = normalize_path(&edge.to);

        let from_idx = match self.index.get(&norm_from).copied().or_else(|| {
            self.graph.node_indices().find(|&idx| {
                self.graph.node_weight(idx).is_some_and(|w| {
                    let short = w
                        .qualified_name
                        .rsplit_once('.')
                        .map(|(_, s)| s)
                        .unwrap_or(&w.qualified_name);
                    short == norm_from
                        || w.qualified_name.ends_with(&format!(".{}", norm_from))
                        || w.qualified_name.ends_with(&format!("::{}", norm_from))
                })
            })
        }) {
            Some(idx) => idx,
            None => return false,
        };

        let to_idx = match self.index.get(&norm_to).copied().or_else(|| {
            self.graph.node_indices().find(|&idx| {
                self.graph.node_weight(idx).is_some_and(|w| {
                    let short = w
                        .qualified_name
                        .rsplit_once('.')
                        .map(|(_, s)| s)
                        .unwrap_or(&w.qualified_name);
                    short == norm_to
                        || w.qualified_name.ends_with(&format!(".{}", norm_to))
                        || w.qualified_name.ends_with(&format!("::{}", norm_to))
                })
            })
        }) {
            Some(idx) => idx,
            None => return false,
        };

        // Prevent self-loops
        if from_idx == to_idx {
            return false;
        }

        // Check if edge already exists, increment call_count if so
        if let Some(edge_idx) = self.graph.find_edge(from_idx, to_idx) {
            if let Some(e) = self.graph.edge_weight_mut(edge_idx) {
                e.call_count += 1;
                return true;
            }
        }

        let from_qname = self
            .graph
            .node_weight(from_idx)
            .map(|w| w.qualified_name.clone())
            .unwrap_or(norm_from);
        let to_qname = self
            .graph
            .node_weight(to_idx)
            .map(|w| w.qualified_name.clone())
            .unwrap_or(norm_to);

        let edge_payload = GraphEdge {
            from: from_qname,
            to: to_qname,
            relation: edge.relation,
            call_count: 1,
        };

        self.graph.add_edge(from_idx, to_idx, edge_payload);
        true
    }

    /// Populates the graph from multiple parser results and computes degree metrics & SCC cycles
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

    /// Safely removes all symbols and connected edges belonging to a file path
    pub fn remove_file_symbols(&mut self, file_path: &str) {
        let norm_path = normalize_path(file_path);
        let to_remove: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    weight.file == norm_path
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
    pub fn apply_incremental_file_patch(
        &mut self,
        file_path: &str,
        code_opt: Option<&str>,
    ) -> TopologyDeltaEvent {
        let norm_path = normalize_path(file_path);
        let change_type = if code_opt.is_some() {
            if self.graph.node_indices().any(|idx| {
                self.graph
                    .node_weight(idx)
                    .is_some_and(|w| w.file == norm_path)
            }) {
                ChangeType::Modified
            } else {
                ChangeType::Added
            }
        } else {
            ChangeType::Removed
        };

        // 1. Remove existing symbols for this file
        self.remove_file_symbols(&norm_path);

        let mut affected_node_ids = Vec::new();

        // 2. Reparse file and add symbols/edges if code exists
        if let Some(code) = code_opt {
            let parse_res = parse_file(code, &norm_path, None);
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
            file_path: norm_path,
            change_type,
            affected_node_ids,
        }
    }

    /// Computes fan_in, fan_out, is_entrypoint, SCC cycle IDs, and DAG levels for all nodes
    pub fn update_degree_metrics(&mut self) {
        let node_indices: Vec<NodeIndex> = self.graph.node_indices().collect();

        // 1. Compute fan_in, fan_out, entrypoint status
        for &idx in &node_indices {
            let fan_in = self.graph.edges_directed(idx, petgraph::Incoming).count() as u32;
            let fan_out = self.graph.edges_directed(idx, petgraph::Outgoing).count() as u32;

            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.fan_in = fan_in;
                weight.fan_out = fan_out;
                // Normalize risk_score to 0.0 - 10.0 scale
                let raw_risk = (weight.complexity * fan_in) as f32;
                weight.risk_score = (raw_risk * 0.5).min(10.0);

                weight.is_orphan = fan_in == 0 && fan_out == 0;

                // Entrypoint MUST be an executable routine (Function) that either is main/test or has fan_in == 0 & fan_out > 0
                weight.is_entrypoint = weight.kind == GraphNodeKind::Function
                    && (weight.qualified_name == "main"
                        || weight.qualified_name.ends_with("::main")
                        || weight.is_test
                        || (fan_in == 0 && fan_out > 0));
            }
        }

        // 2. Compute Tarjan's Strongly Connected Components (SCC) for call cycles
        let sccs = tarjan_scc(&self.graph);
        for (scc_idx, scc) in sccs.iter().enumerate() {
            if scc.len() > 1 {
                for &node_idx in scc {
                    if let Some(weight) = self.graph.node_weight_mut(node_idx) {
                        weight.scc_id = Some(scc_idx);
                    }
                }
            }
        }

        // 3. Compute DAG levels starting topological rank propagation ONLY from real entrypoints
        let mut level_map = HashMap::new();
        for &idx in &node_indices {
            if let Some(weight) = self.graph.node_weight(idx) {
                if weight.is_entrypoint {
                    level_map.insert(idx, 0);
                }
            }
        }
        for _ in 0..node_indices.len() {
            for &idx in &node_indices {
                let max_parent = self
                    .graph
                    .edges_directed(idx, petgraph::Incoming)
                    .filter_map(|e| level_map.get(&e.source()).copied())
                    .max();
                if let Some(p_level) = max_parent {
                    level_map.insert(idx, p_level + 1);
                }
            }
        }
        for (idx, lvl) in level_map {
            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.dag_level = lvl;
            }
        }
    }

    /// Renders a module/depth subgraph export payload using BFS bounded by max_depth hops
    pub fn render_subgraph(
        &self,
        module_path: Option<&str>,
        max_depth: Option<usize>,
    ) -> TopologyExportResponse {
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
                    for edge_ref in self
                        .graph
                        .edges_directed(curr, petgraph::Direction::Outgoing)
                    {
                        neighbors.push(edge_ref.target());
                    }
                    for edge_ref in self
                        .graph
                        .edges_directed(curr, petgraph::Direction::Incoming)
                    {
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
            if included_nodes.contains(&edge_ref.source())
                && included_nodes.contains(&edge_ref.target())
            {
                edges.push(edge_ref.weight().clone());
            }
        }

        TopologyExportResponse {
            nodes,
            edges,
            threshold_config: ThresholdConfig::default(),
        }
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
            to: "unresolved_foo_xyz_random".to_string(),
            relation: Relation::Calls,
        };

        let added = graph.add_edge(dangling_edge);
        assert!(
            !added,
            "Dangling edge to unresolved symbol must be safely dropped (fail closed)"
        );
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
        let remaining = graph
            .index
            .get("fn3")
            .expect("fn3 in src/b.rs must survive");
        assert_eq!(
            graph.graph.node_weight(*remaining).unwrap().qualified_name,
            "fn3"
        );
    }

    #[test]
    fn test_tarjan_scc_cycle_detection() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/a.rs:fn_a".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn_a".to_string(),
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
            id: "src/b.rs:fn_b".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn_b".to_string(),
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

        // Mutual recursion call loop: fn_a -> fn_b and fn_b -> fn_a
        graph.add_edge(ExtractedEdge {
            from: "fn_a".to_string(),
            to: "fn_b".to_string(),
            relation: Relation::Calls,
        });
        graph.add_edge(ExtractedEdge {
            from: "fn_b".to_string(),
            to: "fn_a".to_string(),
            relation: Relation::Calls,
        });

        graph.update_degree_metrics();

        let node_a = graph
            .graph
            .node_weights()
            .find(|w| w.qualified_name == "fn_a")
            .unwrap();
        let node_b = graph
            .graph
            .node_weights()
            .find(|w| w.qualified_name == "fn_b")
            .unwrap();

        assert!(
            node_a.scc_id.is_some(),
            "Mutual recursion fn_a must have non-null scc_id"
        );
        assert!(
            node_b.scc_id.is_some(),
            "Mutual recursion fn_b must have non-null scc_id"
        );
        assert_eq!(
            node_a.scc_id, node_b.scc_id,
            "Both functions in mutual recursion loop must share the same scc_id"
        );
    }
}
