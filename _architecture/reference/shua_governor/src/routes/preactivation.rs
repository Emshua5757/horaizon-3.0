// shua_governor — Dynamic Pre-Activation SDUI Sheet Route Handler
// Generates module-specific pre-boot configuration dialogs (e.g. AI Provider choice for shua_diary)
// Pure SDUI-4 architecture: 0% hardcoding in Flutter shell.

use axum::{
    extract::{Path, State},
    http::{header, HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use crate::routes::dashboard::AppState;
use serde_json::Value;

/// GET /api/governor/preactivation/:module_id
///
/// Returns an SDUI-4 layout tree (bottom sheet modal) tailored for configuring
/// the specified module prior to starting its process in cgroups.
pub async fn get_preactivation_sheet(
    State(state): State<AppState>,
    Path(module_id): Path<String>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let registry_guard = state.registry.read().await;

    let entry = registry_guard.get(&module_id).ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            format!("Module '{}' not found in registry", module_id),
        )
    })?;

    // Construct dynamic SDUI-4 pre-activation layout payload
    let payload = match module_id.as_str() {
        "shua_diary" => build_diary_preactivation_payload(&entry.display_name, &module_id),
        _ => build_generic_preactivation_payload(&entry.display_name, &module_id),
    };

    let accept_header = headers
        .get(header::ACCEPT)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    if accept_header.contains("application/msgpack") {
        let bytes = rmp_serde::to_vec(&payload).map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("MsgPack serialization failed: {}", e),
            )
        })?;
        Ok((
            StatusCode::OK,
            [(header::CONTENT_TYPE, "application/msgpack")],
            bytes,
        )
            .into_response())
    } else {
        Ok(Json(payload).into_response())
    }
}

/// Builds SDUI layout tree for shua_diary AI engine configuration pre-boot sheet.
fn build_diary_preactivation_payload(display_name: &str, module_id: &str) -> Value {
    serde_json::json!([
        {
            "0": 6, // Container
            "id": format!("preactivation_{}:root", module_id),
            "3": {
                "10": 0, // LAYOUT_DIRECTION: Vertical
                "30": [24.0, 24.0, 36.0, 24.0], // PADDING
                "20": 11, // BACKGROUND_COLOR: surfaceContainer
                "21": 24.0 // BORDER_RADIUS
            },
            "2": [
                // Header Row: Title & Close Button
                {
                    "0": 6,
                    "id": format!("preactivation_{}:header", module_id),
                    "3": { "10": 1, "11": 3, "12": 2, "31": [0.0, 0.0, 12.0, 0.0] },
                    "2": [
                        {
                            "0": 1,
                            "id": format!("preactivation_{}:title", module_id),
                            "3": { "100": 1, "101": 2, "95": 0 },
                            "4": { "0": format!("Activate {}", display_name) }
                        },
                        {
                            "0": 3,
                            "id": format!("preactivation_{}:close_btn", module_id),
                            "3": { "112": 3, "70": { "0": 3 } }, // DISMISS
                            "4": { "3": "close" }
                        }
                    ]
                },
                // Subtitle
                {
                    "0": 1,
                    "3": { "100": 3, "95": 0, "97": 17, "31": [0.0, 0.0, 20.0, 0.0] },
                    "4": { "0": "Select the active execution pipeline suite for this session." }
                },
                // Option 1: Gemini Cloud
                build_provider_card(module_id, "gemini", "Cloud Mode", "Gemini API (Free Tier, Token-Bucket Rate-Limited)", "auto_awesome", COLORS_PRIMARY),
                // Option 2: Ollama Local (Pi 5)
                build_provider_card(module_id, "ollama", "Local Mode", "Ollama LLM (Offline-First, Hermes 3 & Qwen 2.5)", "memory", COLORS_SECONDARY),
                // Option 3: Hybrid Smart Route
                build_provider_card(module_id, "hybrid", "Hybrid Mode", "Python IPC Analyzer & Ollama Chat Assistant", "alt_route", COLORS_TERTIARY),
                // Option 4: Custom Mode / n8n
                build_provider_card(module_id, "n8n", "Custom Mode", "External webhooks & multi-agent orchestration", "hub", COLORS_OUTLINE)
            ]
        }
    ])
}

const COLORS_PRIMARY: i64 = 1;      // PRIMARY
const COLORS_SECONDARY: i64 = 5;    // SECONDARY
const COLORS_TERTIARY: i64 = 7;     // SECONDARY_CONTAINER
const COLORS_OUTLINE: i64 = 13;     // OUTLINE

fn build_provider_card(module_id: &str, provider_key: &str, title: &str, subtitle: &str, icon: &str, accent_token: i64) -> Value {
    let start_url = format!("/api/governor/control/{}/start?provider={}", module_id, provider_key);
    serde_json::json!({
        "0": 6, // Container card
        "id": format!("preactivation_{}:card_{}", module_id, provider_key),
        "3": {
            "10": 1, // Horizontal row
            "12": 2, // Center cross alignment
            "30": [14.0, 16.0, 14.0, 16.0],
            "31": [0.0, 0.0, 12.0, 0.0],
            "20": 0, // Surface background
            "21": 14.0,
            "22": 1.0,
            "23": accent_token
        },
        "2": [
            // Left block: Icon and Text Info (Horizontal Row)
            {
                "0": 6,
                "id": format!("preactivation_{}:card_{}_info", module_id, provider_key),
                "3": {
                    "10": 1, // Horizontal row
                    "12": 2, // Center cross alignment
                    "14": 1 // Flex: 1 to fill available width
                },
                "2": [
                    {
                        "0": 3,
                        "id": format!("preactivation_{}:card_{}_icon", module_id, provider_key),
                        "3": {
                            "112": 3, // variant: icon_only
                            "96": accent_token
                        },
                        "4": {
                            "3": icon
                        }
                    },
                    {
                        "0": 6,
                        "id": format!("preactivation_{}:card_{}_spacer", module_id, provider_key),
                        "3": {
                            "32": 12.0 // width: 12px spacer
                        }
                    },
                    {
                        "0": 6,
                        "id": format!("preactivation_{}:card_{}_texts", module_id, provider_key),
                        "3": {
                            "10": 0, // Vertical column
                            "12": 0  // Cross-align: start
                        },
                        "2": [
                            {
                                "0": 1, // Title
                                "id": format!("preactivation_{}:card_{}_title", module_id, provider_key),
                                "3": {
                                    "100": 1, // Heading
                                    "101": 4, // h4 size
                                    "95": 0 // Read-only
                                },
                                "4": {
                                    "0": title
                                }
                            },
                            {
                                "0": 1, // Subtitle
                                "id": format!("preactivation_{}:card_{}_sub", module_id, provider_key),
                                "3": {
                                    "100": 3, // Caption size
                                    "95": 0 // Read-only
                                },
                                "4": {
                                    "0": subtitle
                                }
                            }
                        ]
                    }
                ]
            },
            // Right block: Action Button
            {
                "0": 3,
                "id": format!("preactivation_{}:card_{}_action", module_id, provider_key),
                "3": {
                    "112": 0, // variant: elevated
                    "96": accent_token,
                    "70": {
                        "0": 2, // Navigate action
                        "3": start_url
                    }
                },
                "4": {
                    "1": "Select",
                    "3": "arrow_forward"
                }
            }
        ]
    })
}

fn build_generic_preactivation_payload(display_name: &str, module_id: &str) -> Value {
    let start_url = format!("/api/governor/control/{}/start", module_id);
    serde_json::json!([
        {
            "0": 6,
            "id": format!("preactivation_{}:root", module_id),
            "3": {
                "10": 0,
                "30": [20.0, 20.0, 32.0, 20.0],
                "20": 11,
                "21": 20.0
            },
            "2": [
                {
                    "0": 1,
                    "3": { "100": 1, "101": 2 },
                    "4": { "0": format!("Start {}", display_name) }
                },
                {
                    "0": 3,
                    "id": format!("preactivation_{}:confirm_btn", module_id),
                    "3": {
                        "112": 0,
                        "70": { "0": 2, "3": start_url }
                    },
                    "4": { "1": "Confirm Start", "3": "play_arrow" }
                }
            ]
        }
    ])
}
