use axum::Json;
use axum::extract::State;
use crate::graph::store::AppState;
use crate::debug::ghost_imports::{find_ghost_imports, GhostImportReport};
use crate::debug::boundary::{find_boundary_violations, BoundaryViolation};
use crate::debug::routes_map::{extract_api_routes, RouteNode};
use crate::debug::trait_map::{extract_trait_map, TraitMap};

#[derive(serde::Serialize)]
pub struct DebugReport {
    pub ghost_imports: Vec<GhostImportReport>,
    pub boundary_violations: Vec<BoundaryViolation>,
    pub routes: Vec<RouteNode>,
    pub traits: TraitMap,
}

pub async fn debug_analysis(State(state): State<AppState>) -> Json<DebugReport> {
    // 1. Run the static analyzer steps to compute centrality, find cycle nodes, and tag symbols
    crate::parser::analyzer::compute_centrality(&state);
    crate::parser::analyzer::detect_cycles(&state);
    crate::parser::analyzer::assign_tags(&state);

    // 2. Extract metrics/reports
    let ghost_imports = find_ghost_imports(&state);
    let boundary_violations = find_boundary_violations(&state);
    let routes = extract_api_routes(&state);
    let traits = extract_trait_map(&state);

    Json(DebugReport {
        ghost_imports,
        boundary_violations,
        routes,
        traits,
    })
}
