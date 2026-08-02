use axum::extract::{State, Query};
use axum::response::Response;
use axum::http::{header, StatusCode};
use crate::graph::store::AppState;
use crate::export::ExportOptions;
use crate::export::blast_radius::{compute_subgraph, SubGraph};
use crate::export::search::search_bm25;
use crate::export::git_diff::get_modified_files;
use std::collections::HashSet;
use std::path::PathBuf;

pub async fn export_sdg(
    State(state): State<AppState>,
    Query(opts): Query<ExportOptions>,
) -> Response {
    let mut focus_nodes = HashSet::new();

    if let Some(ref focus_name) = opts.focus {
        let graph = state.graph.read().unwrap();
        let intern = state.intern.read().unwrap();
        for idx in graph.node_indices() {
            if let Some(node) = graph.node_weight(idx) {
                let name = intern.resolve(&node.name);
                if name == focus_name {
                    focus_nodes.insert(idx);
                }
            }
        }
    } else if let Some(ref search_query) = opts.query {
        let search_results = search_bm25(search_query, &state);
        for hit in search_results.iter().take(5) {
            focus_nodes.insert(hit.node_idx);
        }
    }

    if opts.git_diff.unwrap_or(false) {
        let workspace_root = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        let modified = get_modified_files(&workspace_root);
        let graph = state.graph.read().unwrap();
        let intern = state.intern.read().unwrap();

        for idx in graph.node_indices() {
            if let Some(node) = graph.node_weight(idx) {
                let file_str = intern.resolve(&node.file);
                let file_path = PathBuf::from(file_str);
                
                if modified.iter().any(|m| {
                    m.ends_with(&file_path) || file_path.ends_with(m)
                }) {
                    focus_nodes.insert(idx);
                }
            }
        }
    }

    let subgraph = if !focus_nodes.is_empty() {
        let depth = opts.depth.unwrap_or(2);
        let mut final_nodes = HashSet::new();
        let mut final_edges = HashSet::new();

        for start_idx in focus_nodes {
            let focus_name = {
                let graph = state.graph.read().unwrap();
                let intern = state.intern.read().unwrap();
                if let Some(node) = graph.node_weight(start_idx) {
                    intern.resolve(&node.name).to_string()
                } else {
                    continue;
                }
            };
            let sub = compute_subgraph(&focus_name, depth, &state);
            final_nodes.extend(sub.node_indices);
            final_edges.extend(sub.edge_indices);
        }

        SubGraph {
            node_indices: final_nodes,
            edge_indices: final_edges,
        }
    } else {
        let graph = state.graph.read().unwrap();
        let node_indices = graph.node_indices().collect();
        let edge_indices = graph.edge_indices().collect();
        SubGraph { node_indices, edge_indices }
    };

    let format = opts.format.clone().unwrap_or_else(|| "xml".to_string());
    let (content_type, body) = match format.as_str() {
        "markdown" | "md" => {
            ("text/markdown", crate::export::markdown::serialize(&subgraph, &opts, &state))
        }
        "json" => {
            ("application/json", crate::export::json::serialize(&subgraph, &opts, &state))
        }
        _ => {
            ("application/xml", crate::export::xml::serialize(&subgraph, &opts, &state))
        }
    };

    Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, content_type)
        .body(axum::body::Body::from(body))
        .unwrap()
}
