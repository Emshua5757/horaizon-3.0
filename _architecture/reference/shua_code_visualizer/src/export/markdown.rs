use std::collections::HashMap;
use std::path::PathBuf;
pub use crate::graph::store::{AppState, Visibility};
use crate::export::blast_radius::SubGraph;
use crate::export::ExportOptions;
use petgraph::visit::EdgeRef;

pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut md = String::new();
    md.push_str("# Repository Export\n\n");

    let mut file_symbols: HashMap<PathBuf, Vec<petgraph::graph::NodeIndex>> = HashMap::new();
    for &idx in &subgraph.node_indices {
        if let Some(node) = graph.node_weight(idx) {
            let file_str = intern.resolve(&node.file);
            file_symbols.entry(PathBuf::from(file_str)).or_default().push(idx);
        }
    }

    for (file_path, symbols_indices) in file_symbols {
        let total_loc: u32 = symbols_indices.iter().map(|&idx| graph.node_weight(idx).unwrap().loc).sum();
        md.push_str(&format!("### {} ({} lines)\n\n", file_path.to_string_lossy(), total_loc));

        for idx in symbols_indices {
            let node = graph.node_weight(idx).unwrap();

            if opts.pub_only.unwrap_or(false) && matches!(node.visibility, Visibility::Private) {
                continue;
            }

            let name = intern.resolve(&node.name);
            let kind = format!("{:?}", node.kind);

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

            let tags_str = if node.tags.is_empty() {
                String::new()
            } else {
                let tag_names: Vec<String> = node.tags.iter().map(|t| format!("{:?}", t)).collect();
                format!(" | [{}]", tag_names.join(", "))
            };

            let signature = if opts.strip_bodies.unwrap_or(false) {
                format!("{};", node.signature.trim_end_matches('{').trim())
            } else {
                node.signature.clone()
            };

            md.push_str(&format!("#### {} ({})\n", name, kind));
            md.push_str("```rust\n");
            md.push_str(&format!(
                "// Lines {}-{} ({} LOC | Complexity {}) | used by {} callers{}\n",
                node.line_start, node.line_end, node.loc, node.complexity, called_by.len(), tags_str
            ));
            md.push_str(&format!("{}\n", signature));

            if !calls.is_empty() {
                md.push_str(&format!("//  ↳ Calls: {}\n", calls.join(", ")));
            }
            if !called_by.is_empty() {
                md.push_str(&format!("//  ↳ Called by: {}\n", called_by.join(", ")));
            }

            md.push_str("```\n\n");
        }
    }

    md
}
