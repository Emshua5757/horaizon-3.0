// shua_governor — Module Readiness Callback Route
// Phase 11.6: Booting Sync | Spec: _architecture/tasks/horaizon-revamp_task.md
//
// Design intent:
//   The Governor spawns a module process and immediately sets state = Starting.
//   Flutter renders the "Booting" shimmer for the module card.
//   When the module's HTTP server is fully bound (e.g. after Node.js listen()),
//   the module fires POST /api/internal/ready/:id here.
//   The Governor transitions Starting → Active only on this signal.
//
//   The supervisor health-check loop remains active as a fallback:
//   if a module never calls /ready (older modules, crashes before bind),
//   the health check at 200 OK will still promote it to Active.

use crate::routes::dashboard::AppState;
use crate::governor::registry::ModuleState;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
};

/// POST /api/internal/ready/:module_id
///
/// Called by a managed module once its HTTP server is fully bound and ready
/// to serve traffic. Transitions the module state from Starting → Active.
///
/// Returns:
///   204 No Content  — state promoted to Active
///   404 Not Found   — module ID not in registry
///   409 Conflict    — module not in Starting state (already Active, Stopped, etc.)
pub async fn mark_ready(
    State(state): State<AppState>,
    Path(module_id): Path<String>,
) -> impl IntoResponse {
    let mut guard = state.registry.write().await;

    let entry = match guard.get_mut(&module_id) {
        Some(e) => e,
        None => {
            tracing::warn!(subsystem = "module_ready", module_id = %module_id, "ready called for unknown module");
            return StatusCode::NOT_FOUND;
        }
    };

    if entry.state != ModuleState::Starting {
        // Idempotent: if already Active, silently accept (module may send duplicate)
        if entry.state == ModuleState::Active {
            return StatusCode::NO_CONTENT;
        }
        tracing::warn!(
            subsystem = "module_ready",
            module_id = %module_id,
            state = ?entry.state,
            "ready called but module state is invalid"
        );
        return StatusCode::CONFLICT;
    }

    entry.state = ModuleState::Active;
    entry.ready_callback = true;

    tracing::info!(
        subsystem = "module_ready",
        module_id = %module_id,
        "Module self-reported READY → Active (bypassed health-check polling)"
    );

    StatusCode::NO_CONTENT
}
