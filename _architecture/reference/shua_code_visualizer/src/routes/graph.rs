use axum::Json;
use axum::extract::State;
use crate::graph::store::AppState;

#[derive(serde::Serialize)]
pub struct GraphNode {
    pub id: String,
    pub label: String,
    pub language: String,
    pub loc: u32,
    #[serde(rename = "inDegree")]
    pub in_degree: u32,
    #[serde(rename = "outDegree")]
    pub out_degree: u32,
    pub weight: u32,
    #[serde(rename = "isCycleNode")]
    pub is_cycle_node: bool,
    #[serde(rename = "churnScore")]
    pub churn_score: u32,
    pub tags: Vec<String>,
}

#[derive(serde::Serialize)]
pub struct GraphLink {
    pub source: String,
    pub target: String,
    pub dep_type: String,
    pub symbols: Vec<String>,
}

#[derive(serde::Serialize)]
pub struct GraphPayload {
    pub nodes: Vec<GraphNode>,
    pub links: Vec<GraphLink>,
}

pub async fn get_graph(State(state): State<AppState>) -> Json<GraphPayload> {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut nodes = Vec::new();
    let mut links = Vec::new();

    for idx in graph.node_indices() {
        if let Some(node) = graph.node_weight(idx) {
            let id = intern.resolve(&node.id).to_string();
            let label = intern.resolve(&node.name).to_string();
            let language = format!("{:?}", node.language);
            let tags = node.tags.iter().map(|t| format!("{:?}", t)).collect();

            nodes.push(GraphNode {
                id,
                label,
                language,
                loc: node.loc,
                in_degree: node.in_degree,
                out_degree: node.out_degree,
                weight: node.in_degree + node.out_degree,
                is_cycle_node: node.is_cycle,
                churn_score: 0,
                tags,
            });
        }
    }

    for edge_idx in graph.edge_indices() {
        if let Some((source_idx, target_idx)) = graph.edge_endpoints(edge_idx) {
            if let (Some(src_node), Some(tgt_node)) = (graph.node_weight(source_idx), graph.node_weight(target_idx)) {
                let source = intern.resolve(&src_node.id).to_string();
                let target = intern.resolve(&tgt_node.id).to_string();
                if let Some(edge) = graph.edge_weight(edge_idx) {
                    let dep_type = format!("{:?}", edge.dep_type);
                    let symbols = edge.symbols.iter().map(|&s| intern.resolve(&s).to_string()).collect();

                    links.push(GraphLink {
                        source,
                        target,
                        dep_type,
                        symbols,
                    });
                }
            }
        }
    }

    Json(GraphPayload { nodes, links })
}
