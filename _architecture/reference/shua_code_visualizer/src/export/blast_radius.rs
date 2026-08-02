use std::collections::HashSet;
use petgraph::graph::{NodeIndex, EdgeIndex};
use petgraph::visit::EdgeRef;
pub use crate::graph::store::AppState;

pub struct SubGraph {
    pub node_indices: HashSet<NodeIndex>,
    pub edge_indices: HashSet<EdgeIndex>,
}

pub fn compute_subgraph(focus_name: &str, depth: usize, state: &AppState) -> SubGraph {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut node_indices = HashSet::new();
    let mut edge_indices = HashSet::new();

    let mut start_nodes = Vec::new();
    for idx in graph.node_indices() {
        if let Some(node) = graph.node_weight(idx) {
            let label = intern.resolve(&node.name);
            if label == focus_name {
                start_nodes.push(idx);
            }
        }
    }

    if start_nodes.is_empty() {
        for idx in graph.node_indices() {
            if let Some(node) = graph.node_weight(idx) {
                let file_str = intern.resolve(&node.file);
                if file_str.contains(focus_name) {
                    start_nodes.push(idx);
                }
            }
        }
    }

    let mut current_frontier = start_nodes;
    for _ in 0..=depth {
        let mut next_frontier = Vec::new();
        for &idx in &current_frontier {
            if node_indices.insert(idx) {
                for edge in graph.edges_directed(idx, petgraph::Outgoing) {
                    edge_indices.insert(edge.id());
                    next_frontier.push(edge.target());
                }
                for edge in graph.edges_directed(idx, petgraph::Incoming) {
                    edge_indices.insert(edge.id());
                    next_frontier.push(edge.source());
                }
            }
        }
        current_frontier = next_frontier;
    }

    SubGraph { node_indices, edge_indices }
}
