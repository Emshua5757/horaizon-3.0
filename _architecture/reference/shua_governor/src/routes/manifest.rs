use axum::{
    http::{header, StatusCode},
    response::IntoResponse,
};
use tokio::fs::read_to_string;

pub async fn get_manifest() -> impl IntoResponse {
    let path = "schemas/module_registry.json";

    match read_to_string(path).await {
        Ok(content) => (
            StatusCode::OK,
            [(header::CONTENT_TYPE, "application/json")],
            content,
        )
            .into_response(),
        Err(err) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Failed to read manifest: {}", err),
        )
            .into_response(),
    }
}
