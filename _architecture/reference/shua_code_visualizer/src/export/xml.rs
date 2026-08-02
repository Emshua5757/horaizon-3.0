use std::collections::HashMap;
use std::path::PathBuf;
pub use crate::graph::store::{AppState, Visibility, SymbolTag};
use crate::export::blast_radius::SubGraph;
use crate::export::ExportOptions;
use petgraph::visit::EdgeRef;

pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut client_cache_map: HashMap<String, u64> = HashMap::new();
    if let Some(ref cache_str) = opts.client_cache {
        if let Ok(map) = serde_json::from_str::<HashMap<String, u64>>(cache_str) {
            client_cache_map = map;
        }
    }

    let mut file_hashes: HashMap<PathBuf, u64> = HashMap::new();
    for &idx in &subgraph.node_indices {
        if let Some(node) = graph.node_weight(idx) {
            let file_str = intern.resolve(&node.file);
            let file_path = PathBuf::from(file_str);
            file_hashes.insert(file_path, node.content_hash);
        }
    }

    let mut path_legend: HashMap<PathBuf, usize> = HashMap::new();
    let mut legend_xml = String::new();
    legend_xml.push_str("  <legend>\n");
    {
        let file_metadata = state.file_metadata.read().unwrap();
        for (i, file_path) in file_hashes.keys().enumerate() {
            let id = i + 1;
            path_legend.insert(file_path.clone(), id);
            let summary_attr = match file_metadata.get(file_path) {
                Some(meta) if !meta.summary.is_empty() => format!(" summary=\"{}\"", meta.summary),
                _ => String::new(),
            };
            legend_xml.push_str(&format!(
                "    <file id=\"{}\" path=\"{}\"{} />\n",
                id,
                file_path.to_string_lossy(),
                summary_attr
            ));
        }
    }
    legend_xml.push_str("  </legend>\n");

    let mut xml = String::new();
    xml.push_str("<repository>\n");
    xml.push_str(&legend_xml);

    let mut file_symbols: HashMap<PathBuf, Vec<petgraph::graph::NodeIndex>> = HashMap::new();
    for &idx in &subgraph.node_indices {
        if let Some(node) = graph.node_weight(idx) {
            let file_str = intern.resolve(&node.file);
            let file_path = PathBuf::from(file_str);
            file_symbols.entry(file_path).or_default().push(idx);
        }
    }

    for (file_path, symbols_indices) in file_symbols {
        let file_id = path_legend.get(&file_path).unwrap();
        let content_hash = file_hashes.get(&file_path).unwrap_or(&0);

        if let Some(&cached_hash) = client_cache_map.get(&file_path.to_string_lossy().to_string()) {
            if cached_hash == *content_hash {
                xml.push_str(&format!(
                    "  <file id=\"{}\" status=\"unchanged\" hash=\"{:x}\" />\n",
                    file_id, content_hash
                ));
                continue;
            }
        }

        xml.push_str(&format!("  <file id=\"{}\">\n", file_id));

        let mut sorted_indices = symbols_indices;
        sorted_indices.sort_by(|&a, &b| {
            let node_a = graph.node_weight(a).unwrap();
            let node_b = graph.node_weight(b).unwrap();
            (node_b.in_degree + node_b.out_degree).cmp(&(node_a.in_degree + node_a.out_degree))
        });

        for idx in sorted_indices {
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

            let calls_attr = if calls.is_empty() { String::new() } else { format!(" calls=\"{}\"", calls.join(",")) };
            let called_by_attr = if called_by.is_empty() { String::new() } else { format!(" called_by=\"{}\"", called_by.join(",")) };

            let tag_attr = if node.tags.is_empty() {
                String::new()
            } else {
                let tag_names: Vec<String> = node.tags.iter().map(|t| format!("{:?}", t)).collect();
                format!(" tag=\"{}\"", tag_names.join(","))
            };

            let signature = if opts.strip_bodies.unwrap_or(false) {
                format!("{};", node.signature.trim_end_matches('{').trim())
            } else {
                node.signature.clone()
            };

            let escaped_sig = signature
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");

            xml.push_str(&format!(
                "    <symbol name=\"{}\" type=\"{}\" lines=\"{}-{}\" loc=\"{}\" complexity=\"{}\" sig=\"{}\"{}{}{}/>\n",
                name, kind, node.line_start, node.line_end, node.loc, node.complexity, escaped_sig, calls_attr, called_by_attr, tag_attr
            ));
        }

        xml.push_str("  </file>\n");
    }

    xml.push_str("</repository>\n");
    xml
}
