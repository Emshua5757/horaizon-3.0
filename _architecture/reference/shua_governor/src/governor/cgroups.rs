// shua_governor — Linux cgroups v2 Controller Module
// Phase 10: V4 SDUI Rewrite | Architecture spec: _architecture/governor/phase10-governor-spec.md

use std::path::PathBuf;

#[cfg(target_os = "linux")]
use std::sync::atomic::{AtomicBool, Ordering};

#[cfg(target_os = "linux")]
const CGROUP_BASE: &str = "/sys/fs/cgroup/shua";

#[cfg(not(target_os = "linux"))]
const CGROUP_BASE: &str = "./mock_cgroup/shua";

#[cfg(target_os = "linux")]
static USE_MOCK_CGROUP: AtomicBool = AtomicBool::new(false);
#[cfg(target_os = "linux")]
static CGROUP_WARN_LOGGED: AtomicBool = AtomicBool::new(false);

/// Helper function to build directory paths and ensure cgroup folders exist.
pub async fn ensure_cgroup_dir(module_id: &str) -> Result<PathBuf, Box<dyn std::error::Error + Send + Sync>> {
    #[cfg(target_os = "linux")]
    {
        if USE_MOCK_CGROUP.load(Ordering::Relaxed) {
            let mut fallback = PathBuf::from("./mock_cgroup/shua");
            fallback.push(module_id);
            tokio::fs::create_dir_all(&fallback).await?;
            return Ok(fallback);
        }
    }

    let mut path = PathBuf::from(CGROUP_BASE);
    path.push(module_id);

    if let Err(e) = tokio::fs::create_dir_all(&path).await {
        // Fallback to local mock folder on Linux if /sys/fs/cgroup root permission is restricted
        #[cfg(target_os = "linux")]
        {
            USE_MOCK_CGROUP.store(true, Ordering::Relaxed);
            if !CGROUP_WARN_LOGGED.swap(true, Ordering::Relaxed) {
                tracing::warn!(subsystem = "cgroups", "Failed to create cgroup at '{}': {}. Falling back to mock cgroup (subsequent warnings suppressed).", path.display(), e);
            }
            let mut fallback = PathBuf::from("./mock_cgroup/shua");
            fallback.push(module_id);
            tokio::fs::create_dir_all(&fallback).await?;
            return Ok(fallback);
        }
        #[cfg(not(target_os = "linux"))]
        return Err(Box::new(e));
    }

    Ok(path)
}

/// Freezes execution of a module via cgroups v2 (writes "1" to cgroup.freeze).
pub async fn freeze(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let mut path = ensure_cgroup_dir(module_id).await?;
    path.push("cgroup.freeze");
    tokio::fs::write(&path, "1").await?;
    Ok(())
}

/// Unfreezes execution of a module via cgroups v2 (writes "0" to cgroup.freeze).
pub async fn unfreeze(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let mut path = ensure_cgroup_dir(module_id).await?;
    path.push("cgroup.freeze");
    tokio::fs::write(&path, "0").await?;
    Ok(())
}

/// Assigns an operating system Process ID (PID) to a module's cgroup container.
#[cfg(not(target_os = "linux"))]
pub async fn assign_pid(module_id: &str, pid: u32) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let mut path = ensure_cgroup_dir(module_id).await?;
    path.push("cgroup.procs");
    let content = format!("{}\n", pid);
    tokio::fs::write(&path, content).await?;
    Ok(())
}

/// Reads current RAM consumption in bytes for a running process from /proc/{pid}/status.
///
/// Uses Linux procfs VmRSS (Resident Set Size) — works without root privileges,
/// no cgroup hierarchy required. Provides the same granularity as `memory.current`.
/// O(lines in /proc/{pid}/status) ≈ O(1) since the file is always ~50 lines.
pub async fn read_proc_memory_bytes(pid: u32) -> u64 {
    #[cfg(target_os = "linux")]
    {
        let path = format!("/proc/{}/status", pid);
        if let Ok(content) = tokio::fs::read_to_string(&path).await {
            for line in content.lines() {
                if line.starts_with("VmRSS:") {
                    // Format: "VmRSS:     24316 kB"
                    if let Some(kb_str) = line.split_whitespace().nth(1) {
                        if let Ok(kb) = kb_str.parse::<u64>() {
                            return kb * 1024; // kB → bytes
                        }
                    }
                }
            }
        }
        0
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = pid;
        10_485_760 // 10MB mock readout on non-Linux
    }
}


/// Falls back to procfs VmRSS if cgroup path doesn't exist or is mocked.
pub async fn read_memory_bytes(module_id: &str, _pid: Option<u32>) -> Result<u64, Box<dyn std::error::Error + Send + Sync>> {
    #[cfg(target_os = "linux")]
    {
        if USE_MOCK_CGROUP.load(Ordering::Relaxed) {
            if let Some(p) = _pid {
                let ram = read_proc_memory_bytes(p).await;
                if ram > 0 {
                    return Ok(ram);
                }
            }
        }
    }

    let mut path = ensure_cgroup_dir(module_id).await?;
    path.push("memory.current");

    if !path.exists() {
        #[cfg(target_os = "linux")]
        {
            if let Some(p) = _pid {
                let ram = read_proc_memory_bytes(p).await;
                if ram > 0 {
                    return Ok(ram);
                }
            }
        }
        tokio::fs::write(&path, "10485760\n").await?; // Default 10MB mock readout
    }

    let content = tokio::fs::read_to_string(&path).await?;
    let bytes = content.trim().parse::<u64>()?;
    Ok(bytes)
}

// ──────────────────────────────────────────────────────────────────────────────
// System-Level Telemetry Readers (Phase 11.7)
// ──────────────────────────────────────────────────────────────────────────────

/// Returns system-wide CPU utilisation (0.0–100.0) by sampling /proc/stat twice
/// with a 1-second gap and computing the fraction of non-idle jiffies.
///
/// Algorithm (O(1) — fixed number of CPU stat fields):
///   total  = user + nice + system + idle + iowait + irq + softirq + steal
///   busy   = total - idle - iowait
///   cpu %  = (busy_delta / total_delta) * 100
///
/// Non-Linux: returns a mock 5.0% so dev builds compile and run.
pub async fn read_system_cpu_pct() -> f32 {
    #[cfg(target_os = "linux")]
    {
        async fn read_stat_fields() -> Option<(u64, u64)> {
            let content = tokio::fs::read_to_string("/proc/stat").await.ok()?;
            let first_line = content.lines().next()?;
            // "cpu  user nice system idle iowait irq softirq steal guest guest_nice"
            let mut parts = first_line.split_whitespace();
            parts.next(); // skip "cpu"
            let vals: Vec<u64> = parts.filter_map(|s| s.parse().ok()).collect();
            if vals.len() < 4 { return None; }
            let idle  = vals[3] + vals.get(4).copied().unwrap_or(0); // idle + iowait
            let total: u64 = vals.iter().sum();
            Some((idle, total))
        }

        let t0 = read_stat_fields().await;
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        let t1 = read_stat_fields().await;

        if let (Some((idle0, total0)), Some((idle1, total1))) = (t0, t1) {
            let d_total = total1.saturating_sub(total0) as f32;
            let d_idle  = idle1.saturating_sub(idle0)   as f32;
            if d_total > 0.0 {
                return ((d_total - d_idle) / d_total * 100.0).clamp(0.0, 100.0);
            }
        }
        0.0
    }
    #[cfg(not(target_os = "linux"))]
    5.0_f32
}

/// Returns the RPi 5 CPU die temperature in °C.
/// Reads /sys/class/thermal/thermal_zone0/temp (integer millidegrees, no root needed).
///
/// O(1) — single file read, single integer parse.
/// Non-Linux: returns 45.0°C mock.
pub async fn read_cpu_temp_celsius() -> f32 {
    #[cfg(target_os = "linux")]
    {
        if let Ok(raw) = tokio::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp").await {
            if let Ok(millideg) = raw.trim().parse::<i32>() {
                return millideg as f32 / 1000.0;
            }
        }
        0.0
    }
    #[cfg(not(target_os = "linux"))]
    45.0_f32
}


/// Kills all processes in the module's cgroup via cgroups v2 (writes "1" to cgroup.kill).
pub async fn kill(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let mut path = ensure_cgroup_dir(module_id).await?;
    path.push("cgroup.kill");
    tokio::fs::write(&path, "1").await?;
    Ok(())
}

#[cfg(target_os = "linux")]
async fn read_proc_cpu_usec(pid: u32) -> u64 {
    let path = format!("/proc/{}/stat", pid);
    if let Ok(content) = tokio::fs::read_to_string(&path).await {
        if let Some(pos) = content.rfind(')') {
            let rest = &content[pos + 1..];
            let parts: Vec<&str> = rest.split_whitespace().collect();
            if parts.len() >= 15 {
                let utime: u64 = parts[11].parse().unwrap_or(0);
                let stime: u64 = parts[12].parse().unwrap_or(0);
                let cutime: u64 = parts[13].parse().unwrap_or(0);
                let cstime: u64 = parts[14].parse().unwrap_or(0);
                
                let total_jiffies = utime + stime + cutime + cstime;
                return total_jiffies * 10_000; // 1 jiffy = 10ms = 10,000 usec
            }
        }
    }
    0
}

/// Returns the CPU usage in microseconds for a cgroup.
/// On Linux: reads cpu.stat usage_usec. Falls back to procfs stat if cgroup fails.
/// On non-Linux: returns mock value based on SystemTime.
pub async fn read_cgroup_cpu_usec(module_id: &str, pid: Option<u32>) -> u64 {
    #[cfg(target_os = "linux")]
    {
        if USE_MOCK_CGROUP.load(Ordering::Relaxed) {
            if let Some(p) = pid {
                return read_proc_cpu_usec(p).await;
            }
        }

        let mut path = match ensure_cgroup_dir(module_id).await {
            Ok(p) => p,
            Err(_) => return 0,
        };
        path.push("cpu.stat");
        if let Ok(content) = tokio::fs::read_to_string(&path).await {
            for line in content.lines() {
                if line.starts_with("usage_usec") {
                    if let Some(val_str) = line.split_whitespace().nth(1) {
                        if let Ok(usec) = val_str.parse::<u64>() {
                            return usec;
                        }
                    }
                }
            }
        }
        
        if let Some(p) = pid {
            return read_proc_cpu_usec(p).await;
        }
        0
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = module_id;
        let _ = pid;
        use std::time::{SystemTime, UNIX_EPOCH};
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_micros() as u64;
        // Simulate a system running at 5% CPU: 50,000 usec of CPU time per wall-clock second
        now / 20
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_mock_cgroups() {
        let test_module = "test_diary";
        freeze(test_module).await.unwrap();
        let bytes = read_memory_bytes(test_module, None).await.unwrap();
        assert!(bytes > 0);
    }

    #[tokio::test]
    async fn test_cpu_temp_non_linux() {
        // On non-Linux (dev machine) this must return the mock value without panicking.
        let temp = read_cpu_temp_celsius().await;
        assert!(temp >= 0.0);
    }
}

