// shua_governor — Microservice Supervisor Loop
// Architecture spec: _architecture/governor/phase10-governor-spec.md
//
// Phase 11.7 additions: CPU jiffy diffing, per-module CPU %, die temperature.
// Phase 11.8 additions: broadcast::Sender<MetricsSnapshot> publish at end of each tick.

use std::collections::HashMap;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use hyper_util::client::legacy::connect::HttpConnector;
use hyper_util::client::legacy::Client;
use hyper_util::rt::TokioExecutor;
use axum::body::Body;
use tokio::sync::broadcast;
use crate::governor::{
    cgroups,
    registry::{ModuleRegistry, ModuleState, SharedSystemMetrics, SystemMetrics},
    media_gc::SharedMediaStats,
};
use crate::routes::sse_metrics::{MetricsSnapshot, ModuleMetrics};

/// Background supervisor loop — runs forever in a Tokio task.
///
/// Every ~2s tick (1s CPU sample window + 1s sleep):
///   1. Read /proc/stat jiffy diff for system-wide CPU %
///   2. Read thermal_zone0 for CPU die temperature
///   3. For each running module: read VmRSS + jiffy snapshot for CPU %
///   4. Write all results to SharedSystemMetrics (single write-lock, fast)
///   5. Build a MetricsSnapshot and publish to the broadcast channel (O(1) fan-out)
///   6. Probe each module's health endpoint → transition Starting → Active on 200 OK
pub async fn start_supervisor_loop(
    registry:        ModuleRegistry,
    system_metrics:  SharedSystemMetrics,
    metrics_tx:      broadcast::Sender<MetricsSnapshot>,
    media_stats:     SharedMediaStats,
) {
    let client: Client<HttpConnector, Body> = Client::builder(TokioExecutor::new()).build(HttpConnector::new());

    // Store previous CPU microsecond readings per module for telemetry diffing.
    // HashMap<module_id, prev_cpu_usec> — O(1) amortised insert/lookup.
    let mut prev_cpu_usec: std::collections::HashMap<String, u64> = std::collections::HashMap::new();

    loop {
        // 1. Gather modules to check under a quick read lock
        let modules_to_check: Vec<(String, Option<u32>, String, ModuleState)> = {
            let registry_guard = registry.read().await;
            registry_guard
                .values()
                .map(|e| (e.id.clone(), e.pid, e.health_endpoint.clone(), e.state.clone()))
                .collect()
        };

        // 2. Prepare concurrent check futures for each module
        let mut futures = Vec::new();
        for (id, pid, health_endpoint, state) in modules_to_check {
            let client = client.clone();
            futures.push(async move {
                // Read cgroups/procfs memory in parallel
                let ram_bytes = cgroups::read_memory_bytes(&id, pid).await.unwrap_or(0);

                // Read cgroups/procfs CPU time in parallel
                let current_cpu = cgroups::read_cgroup_cpu_usec(&id, pid).await;

                // Health check probe with timeout in parallel
                let mut next_state = state.clone();
                if state == ModuleState::Active || state == ModuleState::Starting {
                    if let Ok(uri) = health_endpoint.parse::<axum::http::Uri>() {
                        let req = axum::http::Request::builder()
                            .uri(uri)
                            .body(Body::empty())
                            .unwrap();

                        let check_fut = client.request(req);
                        match tokio::time::timeout(Duration::from_millis(500), check_fut).await {
                            Ok(Ok(res)) if res.status().is_success() => {
                                if state != ModuleState::Active {
                                    tracing::info!(subsystem = "supervisor", module_id = %id, "Module '{}' verified HEALTHY (Active).", id);
                                    next_state = ModuleState::Active;
                                }
                            }
                            _ => {
                                if state == ModuleState::Starting {
                                    tracing::debug!(subsystem = "supervisor", module_id = %id, "Module '{}' process spawned; awaiting HTTP readiness...", id);
                                } else {
                                    tracing::warn!(subsystem = "supervisor", module_id = %id, "Module '{}' health check FAILED. Marking Backoff.", id);
                                    next_state = ModuleState::Backoff { attempt: 1 };
                                }
                            }
                        }
                    }
                }

                (id, ram_bytes, current_cpu, state, next_state)
            });
        }

        // 3. Run system telemetry check and all module health/cgroup checks concurrently.
        // The read_system_cpu_pct takes exactly 1.0 second, so it bounds the total concurrent
        // execution time, naturally serving as our tick timer and eliminating sequential delays.
        let governor_pid = std::process::id();
        let ((sys_cpu_pct, temp_c), governor_ram, results) = tokio::join!(
            async {
                tokio::join!(
                    cgroups::read_system_cpu_pct(),
                    cgroups::read_cpu_temp_celsius(),
                )
            },
            cgroups::read_proc_memory_bytes(governor_pid),
            futures_util::future::join_all(futures)
        );

        // 4. Apply results under a quick write lock (holding for nanoseconds)
        let mut registry_guard = registry.write().await;

        const ELAPSED: f32 = 2.0;
        const NUM_CORES: f32 = 4.0;
        let total_capacity_usec = ELAPSED * 1_000_000.0 * NUM_CORES;

        for (id, ram_bytes, current_cpu, original_state, next_state) in results {
            if let Some(entry) = registry_guard.get_mut(&id) {
                entry.ram_bytes = ram_bytes;

                // Prevent race conditions where an external control action (e.g. stop/start)
                // modified the state in the registry during the asynchronous I/O check phase.
                if entry.state == original_state {
                    entry.state = next_state;
                } else {
                    tracing::debug!(
                        subsystem = "supervisor",
                        module_id = %id,
                        current = ?entry.state,
                        expected = ?original_state,
                        "Supervisor state transition bypassed (modified externally during tick)"
                    );
                }

                let prev = prev_cpu_usec.get(&id).copied().unwrap_or(current_cpu);
                let delta = current_cpu.saturating_sub(prev) as f32;
                entry.cpu_pct = (delta / total_capacity_usec * 100.0).clamp(0.0, 100.0);

                prev_cpu_usec.insert(id, current_cpu);
            }
        }

        // Compute system-level RSS total
        let module_ram: u64 = registry_guard.values().map(|e| e.ram_bytes).sum();
        let total_ram_bytes = governor_ram + module_ram;
        let ram_mb = total_ram_bytes as f64 / 1024.0 / 1024.0;
        let ram_pct = (ram_mb / 8192.0_f64).min(1.0_f64);

        // Build MetricsSnapshot for broadcast
        let modules: HashMap<String, ModuleMetrics> = registry_guard.iter().map(|(id, e)| {
            let mm = ModuleMetrics {
                state:   crate::governor::registry::display_state(&e.state),
                ram_mb:  e.ram_bytes as f64 / 1024.0 / 1024.0,
                cpu_pct: e.cpu_pct,
            };
            (id.clone(), mm)
        }).collect();

        let disk_used_pct = {
            let ms = media_stats.read().await;
            ms.disk_used_pct
        };

        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or(Duration::ZERO)
            .as_secs();

        let snapshot = MetricsSnapshot {
            ts,
            cpu_pct: sys_cpu_pct,
            temp_c,
            ram_mb,
            ram_pct,
            disk_used_pct,
            modules,
        };

        // Write to SharedSystemMetrics (read by dashboard route on hot path)
        {
            let mut sm = system_metrics.write().await;
            *sm = SystemMetrics { cpu_pct: sys_cpu_pct, temp_c, ram_mb, ram_pct };
        }

        // Drop the write lock before sending broadcast and sleeping
        drop(registry_guard);

        // Publish to SSE subscribers — errors mean no open connections, safely ignored
        let _ = metrics_tx.send(snapshot);

        tokio::time::sleep(Duration::from_secs(1)).await;
    }
}
