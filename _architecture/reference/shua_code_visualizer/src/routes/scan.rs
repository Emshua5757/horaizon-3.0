use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use crate::graph::store::AppState;
use std::path::PathBuf;

#[derive(serde::Deserialize)]
pub struct ScanRequest {
    pub path: String,
}

#[derive(serde::Serialize)]
pub struct ScanResponse {
    pub status: String,
    pub path: String,
}

pub async fn trigger_scan(
    State(state): State<AppState>,
    Json(payload): Json<ScanRequest>,
) -> (StatusCode, Json<ScanResponse>) {
    let target_path = PathBuf::from(&payload.path);
    let workspace_root = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));

    let target_canonical = target_path.canonicalize().unwrap_or(target_path.clone());
    let workspace_canonical = workspace_root.canonicalize().unwrap_or(workspace_root);

    if !target_canonical.starts_with(&workspace_canonical) {
        return (
            StatusCode::FORBIDDEN,
            Json(ScanResponse {
                status: "error: path outside workspace root".to_string(),
                path: payload.path,
            }),
        );
    }

    let state_clone = state.clone();
    let target_clone = target_canonical.clone();
    tokio::task::spawn_blocking(move || {
        crate::parser::scanner::run_full_scan(&target_clone, &state_clone);
    });

    (
        StatusCode::ACCEPTED,
        Json(ScanResponse {
            status: "scanning".to_string(),
            path: target_canonical.to_string_lossy().to_string(),
        }),
    )
}
