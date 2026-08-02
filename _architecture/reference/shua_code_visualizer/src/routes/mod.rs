pub mod graph;
pub mod export;
pub mod scan;
pub mod debug;

use axum::Json;
use axum::extract::State;
use crate::graph::store::AppState;

#[derive(serde::Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub module: &'static str,
    pub graph_nodes: usize,
    pub graph_edges: usize,
    pub ram_mb: u32,
}

pub async fn health_check(State(state): State<AppState>) -> Json<HealthResponse> {
    let graph = state.graph.read().unwrap();
    let graph_nodes = graph.node_count();
    let graph_edges = graph.edge_count();
    
    let ram_mb = get_rss_mb();

    Json(HealthResponse {
        status: "ok",
        module: "shua_code_visualizer",
        graph_nodes,
        graph_edges,
        ram_mb,
    })
}

fn get_rss_mb() -> u32 {
    #[cfg(target_os = "linux")]
    {
        if let Ok(statm) = std::fs::read_to_string("/proc/self/statm") {
            if let Some(pages_str) = statm.split_whitespace().nth(1) {
                if let Ok(pages) = pages_str.parse::<usize>() {
                    return ((pages * 4096) / 1024 / 1024) as u32;
                }
            }
        }
    }
    15
}
