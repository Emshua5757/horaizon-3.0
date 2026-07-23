// shua_governor — Zero-Copy Reverse Proxy Handler
// Architecture spec: _architecture/governor/phase10-governor-spec.md

use axum::{
    body::Body,
    extract::Request,
    http::{HeaderValue, Response, StatusCode, Uri},
};
use hyper_util::client::legacy::connect::HttpConnector;
use hyper_util::client::legacy::Client;
use hyper_util::rt::TokioExecutor;
use std::sync::OnceLock;

static HTTP_CLIENT: OnceLock<Client<HttpConnector, Body>> = OnceLock::new();

fn get_client() -> &'static Client<HttpConnector, Body> {
    HTTP_CLIENT.get_or_init(|| Client::builder(TokioExecutor::new()).build(HttpConnector::new()))
}

/// Forwards incoming Axum requests directly to upstream loopback microservices.
///
/// Zero-Copy: Streams raw TCP byte chunks directly between sockets without buffering in RAM.
pub async fn proxy_request(
    mut req: Request<Body>,
    target_base: &str,
) -> Result<Response<Body>, (StatusCode, String)> {
    let path_and_query = req
        .uri()
        .path_and_query()
        .map(|pq| pq.as_str())
        .unwrap_or("");

    let target_uri_str = format!("http://{}{}", target_base, path_and_query);
    let target_uri: Uri = target_uri_str
        .parse()
        .map_err(|e| (StatusCode::BAD_REQUEST, format!("Invalid proxy URI: {}", e)))?;

    // Update request URI to target upstream destination
    *req.uri_mut() = target_uri;

    // Append X-Forwarded-For header for client IP tracking
    req.headers_mut()
        .insert("x-forwarded-for", HeaderValue::from_static("127.0.0.1"));

    // Forward request via connection pool and return upstream stream directly
    match get_client().request(req).await {
        Ok(res) => Ok(res.map(Body::new)),
        Err(err) => Err((
            StatusCode::BAD_GATEWAY,
            format!("Upstream proxy connection failed: {}", err),
        )),
    }
}
