pub use crate::graph::store::{AppState, Visibility, SymbolNode};
use crate::export::blast_radius::SubGraph;
use crate::export::ExportOptions;
use petgraph::visit::EdgeRef;

#[derive(serde::Serialize)]
pub struct ExportNode {
    pub name: String,
    pub file: String,
    pub kind: String,
    pub lines: (u32, u32),
    pub loc: u32,
    pub complexity: u32,
    pub visibility: String,
    pub signature: String,
    pub in_degree: u32,
    pub out_degree: u32,
    pub is_cycle: bool,
    pub tags: Vec<String>,
    pub calls: Vec<String>,
    pub called_by: Vec<String>,
}

pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut nodes = Vec::new();

    for &idx in &subgraph.node_indices {
        let node = graph.node_weight(idx).unwrap();

        if opts.pub_only.unwrap_or(false) && matches!(node.visibility, Visibility::Private) {
            continue;
        }

        let name = intern.resolve(&node.name).to_string();
        let file = intern.resolve(&node.file).to_string();
        let kind = format!("{:?}", node.kind);
        let visibility = format!("{:?}", node.visibility);
        let tags = node.tags.iter().map(|t| format!("{:?}", t)).collect();

        let mut calls = Vec::new();
        let mut called_by = Vec::new();

        for edge in graph.edges_directed(idx, petgraph::Outgoing) {
            if subgraph.node_indices.contains(&edge.target()) {
                let target_node = graph.node_weight(edge.target()).unwrap();
                calls.push(intern.resolve(&target_node.name).to_string());
            }
        }

        for edge in graph.edges_directed(idx, petgraph::Incoming) {
            if subgraph.node_indices.contains(&edge.source()) {
                let source_node = graph.node_weight(edge.source()).unwrap();
                called_by.push(intern.resolve(&source_node.name).to_string());
            }
        }

        let signature = if opts.strip_bodies.unwrap_or(false) {
            format!("{};", node.signature.trim_end_matches('{').trim())
        } else {
            node.signature.clone()
        };

        nodes.push(ExportNode {
            name,
            file,
            kind,
            lines: (node.line_start, node.line_end),
            loc: node.loc,
            complexity: node.complexity,
            visibility,
            signature,
            in_degree: node.in_degree,
            out_degree: node.out_degree,
            is_cycle: node.is_cycle,
            tags,
            calls,
            called_by,
        });
    }

    serde_json::to_string_pretty(&nodes).unwrap_or_else(|_| "[]".to_string())
}
