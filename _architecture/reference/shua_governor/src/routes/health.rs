// shua_governor — Health Check Route Handler
// Architecture spec: _architecture/governor/phase10-governor-spec.md

use axum::Json;
use serde_json::{json, Value};

pub async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "ok",
        "service": "shua_governor"
    }))
}
