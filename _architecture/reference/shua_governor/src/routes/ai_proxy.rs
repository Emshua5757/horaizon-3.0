// shua_governor — Phase 14: Hybrid AI Proxy Route
//
// POST /api/ai/infer
//
// Dual-tier inference proxy:
//   Tier 1 (primary)  → Laptop GPU node (Tailscale, resolved from module_registry.json "ai_offload")
//   Tier 2 (fallback) → Pi 5 local Ollama (127.0.0.1:11434)
//
// On Tier 1 failure (timeout / connection refused), automatically falls back to Tier 2.
// On the Tier 2 path, injects "keep_alive": 0 into the request body to force immediate
// model weight eviction after inference — prevents OOM on the Pi 5's 8GB RAM ceiling.
//
// Architecture spec: _architecture/ai-spec.md
// Tailnet IPs: Pi 5 = 100.67.11.0 | Laptop = 100.90.83.12 | Phone = 100.111.230.72

use axum::{
    body::Body,
    extract::State,
    http::{Request, StatusCode, Uri},
    response::{IntoResponse, Response},
    Json,
};
use hyper_util::client::legacy::connect::HttpConnector;
use hyper_util::client::legacy::Client;
use hyper_util::rt::TokioExecutor;
use serde_json::{json, Value};
use std::sync::OnceLock;
use tokio::time::{timeout, Duration};

use super::dashboard::AppState;

/// 8-second timeout per tier. Tight enough that a dead laptop node fails fast
/// without blocking the Flutter UI. The Pi 5 fallback always resolves locally.
const INFER_TIMEOUT_SECS: u64 = 8;

/// Pi 5 local Ollama loopback — always present when the Governor is running.
const LOCAL_OLLAMA_ADDR: &str = "127.0.0.1:11434";

/// Ollama inference endpoint path.
const OLLAMA_GENERATE_PATH: &str = "/api/generate";

// ── Connection Pool ────────────────────────────────────────────────────────────
// Reuse the same hyper client pattern as proxy/handler.rs — static OnceLock pool,
// zero allocation per request. HttpConnector resolves both loopback and Tailscale IPs.
static HTTP_CLIENT: OnceLock<Client<HttpConnector, Body>> = OnceLock::new();

fn get_client() -> &'static Client<HttpConnector, Body> {
    HTTP_CLIENT.get_or_init(|| Client::builder(TokioExecutor::new()).build(HttpConnector::new()))
}

// ── Handler ────────────────────────────────────────────────────────────────────

/// POST /api/ai/infer
///
/// Resolves the `ai_offload` target from the module registry, proxies to Ollama's
/// /api/generate with an 8s timeout, and streams NDJSON response back to the Flutter client.
/// Falls back to the Pi 5 local Ollama on Tier 1 failure, injecting keep_alive=0.
pub async fn infer(
    State(state): State<AppState>,
    req: Request<Body>,
) -> impl IntoResponse {
    // ── 1. Resolve Tier 1 host:port from the registry ─────────────────────────
    let tier1_addr: Option<String> = {
        let registry = state.registry.read().await;
        registry
            .get("ai_offload")
            .map(|m| format!("{}:{}", m.host, m.port))
    };

    // ── 2. Buffer the request body once ───────────────────────────────────────
    // Body is not Clone — we must read it before we can branch on tier.
    let body_bytes = match axum::body::to_bytes(req.into_body(), usize::MAX).await {
        Ok(b) => b,
        Err(e) => {
            tracing::error!(subsystem = "ai_proxy", error = %e, "Failed to read request body");
            return error_response(StatusCode::BAD_REQUEST, "failed_to_read_body");
        }
    };

    // Parse body JSON. We may need to mutate it for the Tier 2 keep_alive injection.
    let body_json: Value = serde_json::from_slice(&body_bytes).unwrap_or(Value::Null);

    // ── 3. Tier 1: Laptop GPU via Tailscale ───────────────────────────────────
    if let Some(addr) = tier1_addr {
        let url = format!("http://{}{}", addr, OLLAMA_GENERATE_PATH);
        tracing::debug!(subsystem = "ai_proxy", tier = 1, %url, "Attempting laptop GPU node");

        let tier1_body = body_json.clone();
        match try_forward(&url, tier1_body).await {
            Ok(response) => return response,
            Err(e) => {
                tracing::warn!(
                    subsystem = "ai_proxy",
                    tier = 1,
                    error = %e,
                    "Laptop GPU unreachable — falling back to Pi 5 local Ollama"
                );
            }
        }
    } else {
        tracing::warn!(
            subsystem = "ai_proxy",
            "ai_offload not found in registry — skipping Tier 1"
        );
    }

    // ── 4. Tier 2: Pi 5 local Ollama (keep_alive injection) ──────────────────
    // Inject keep_alive=0: forces immediate model eviction from VRAM/RAM after inference.
    // Default Ollama behaviour holds the model in memory for 5 minutes, which exhausts
    // the Pi 5's shared 8GB pool and triggers OOM panics under cgroup v2 pressure.
    let mut tier2_body = body_json;
    if let Value::Object(ref mut map) = tier2_body {
        map.insert("keep_alive".to_string(), json!(0));
    }

    let fallback_url = format!("http://{}{}", LOCAL_OLLAMA_ADDR, OLLAMA_GENERATE_PATH);
    tracing::debug!(
        subsystem = "ai_proxy",
        tier = 2,
        %fallback_url,
        "Routing to Pi 5 local Ollama with keep_alive=0"
    );

    match try_forward(&fallback_url, tier2_body).await {
        Ok(response) => response,
        Err(e) => {
            tracing::error!(
                subsystem = "ai_proxy",
                tier = 2,
                error = %e,
                "Both AI tiers unreachable"
            );
            error_response(StatusCode::SERVICE_UNAVAILABLE, "ai_offload_unreachable")
        }
    }
}

// ── Internal helpers ───────────────────────────────────────────────────────────

/// Builds and sends a POST to `url` with `body` as JSON.
/// Returns the upstream Response on success, or an error string on timeout/connection failure.
async fn try_forward(url: &str, body: Value) -> Result<Response, String> {
    let body_bytes = serde_json::to_vec(&body)
        .map_err(|e| format!("JSON serialization error: {}", e))?;

    let uri: Uri = url
        .parse()
        .map_err(|e| format!("Invalid URI {}: {}", url, e))?;

    let hyper_req = axum::http::Request::builder()
        .method("POST")
        .uri(uri)
        .header("Content-Type", "application/json")
        .body(Body::from(body_bytes))
        .map_err(|e| format!("Failed to build request: {}", e))?;

    let send_future = get_client().request(hyper_req);

    let upstream_resp = timeout(Duration::from_secs(INFER_TIMEOUT_SECS), send_future)
        .await
        .map_err(|_| format!("Timeout after {}s reaching {}", INFER_TIMEOUT_SECS, url))?
        .map_err(|e| format!("Connection error to {}: {}", url, e))?;

    // Convert hyper response to Axum response — map the body type.
    let (parts, body) = upstream_resp.into_parts();
    let axum_body = Body::new(body);
    Ok(Response::from_parts(parts, axum_body))
}

/// Returns a structured JSON error response.
fn error_response(status: StatusCode, code: &str) -> Response {
    (status, Json(json!({ "error": code, "code": status.as_u16() }))).into_response()
}
