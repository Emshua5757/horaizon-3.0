# Repository Export

### C:\horAIzon_2.0\shua_governor\src\logging\listener.rs (184 lines)

#### read_until_newline (Function)
```rust
// Lines 190-202 (13 LOC | Complexity 4) | used by 2 callers | [Async, MutatesState, Io]
async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
//  â³ Called by: harvest_socket_stream, harvest_pipe
```

#### harvest_socket_stream (Function)
```rust
// Lines 88-174 (87 LOC | Complexity 13) | used by 1 callers | [Async, MutatesState, Io]
async fn harvest_socket_stream<S>(stream: S, log_tx: mpsc::Sender<LogEntry>)
//  â³ Calls: BorrowedLogEntry, LogEntry, read_until_newline, wrap_socket_raw_line, log_min_level
//  â³ Called by: start_log_ipc_listener
```

#### wrap_socket_raw_line (Function)
```rust
// Lines 176-188 (13 LOC | Complexity 1) | used by 1 callers | [Io]
fn wrap_socket_raw_line(line: &str) -> LogEntry
//  â³ Calls: LogEntry
//  â³ Called by: harvest_socket_stream
```

#### start_log_ipc_listener (Function)
```rust
// Lines 16-86 (71 LOC | Complexity 12) | used by 1 callers | [Async, Io]
pub async fn start_log_ipc_listener(log_tx: mpsc::Sender<LogEntry>)
//  â³ Calls: LogEntry, harvest_socket_stream
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_governor\src\routes\sse_metrics.rs (61 lines)

#### ModuleMetrics (Struct)
```rust
// Lines 35-42 (8 LOC | Complexity 1) | used by 2 callers
pub struct ModuleMetrics
//  â³ Called by: MetricsSnapshot, start_supervisor_loop
```

#### MetricsSnapshot (Struct)
```rust
// Lines 47-62 (16 LOC | Complexity 1) | used by 4 callers
pub struct MetricsSnapshot
//  â³ Calls: ModuleMetrics
//  â³ Called by: stream_metrics, main, AppState, start_supervisor_loop
```

#### stream_metrics (Function)
```rust
// Lines 79-115 (37 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn stream_metrics(
//  â³ Calls: MetricsSnapshot, AppState
```

### C:\horAIzon_2.0\shua_governor\src\governor\registry.rs (138 lines)

#### RegistryManifest (Struct)
```rust
// Lines 185-187 (3 LOC | Complexity 1) | used by 1 callers
struct RegistryManifest
//  â³ Calls: ModuleEntry
//  â³ Called by: load_from_json
```

#### default_shimmer_style (Function)
```rust
// Lines 114-116 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_shimmer_style() -> String
```

#### default_state (Function)
```rust
// Lines 118-120 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_state() -> ModuleState
//  â³ Calls: ModuleState
```

#### ModuleEntry (Struct)
```rust
// Lines 47-108 (62 LOC | Complexity 1) | used by 3 callers
pub struct ModuleEntry
//  â³ Calls: ModuleState
//  â³ Called by: RegistryManifest, load_from_json, inject_module_telemetry
```

#### SystemMetrics (Struct)
```rust
// Lines 145-157 (13 LOC | Complexity 1) | used by 1 callers
pub struct SystemMetrics
//  â³ Called by: start_supervisor_loop
```

#### default_host (Function)
```rust
// Lines 110-112 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_host() -> String
```

#### load_from_json (Function)
```rust
// Lines 179-191 (13 LOC | Complexity 3) | used by 1 callers | [Async, Io]
pub async fn load_from_json(
//  â³ Calls: RegistryManifest, ModuleEntry
//  â³ Called by: main
```

#### ModuleState (Enum)
```rust
// Lines 13-31 (19 LOC | Complexity 1) | used by 4 callers
pub enum ModuleState
//  â³ Called by: display_state, default_state, ModuleEntry, start_supervisor_loop
```

#### new_registry (Function)
```rust
// Lines 133-135 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn new_registry() -> ModuleRegistry
//  â³ Called by: main
```

#### new_system_metrics (Function)
```rust
// Lines 162-164 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn new_system_metrics() -> SharedSystemMetrics
//  â³ Called by: main
```

#### default_exec_cmd (Function)
```rust
// Lines 122-124 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_exec_cmd() -> String
```

#### display_state (Function)
```rust
// Lines 167-176 (10 LOC | Complexity 7) | used by 2 callers | [Pure]
pub fn display_state(state: &ModuleState) -> String
//  â³ Calls: ModuleState
//  â³ Called by: inject_module_telemetry, start_supervisor_loop
```

### C:\horAIzon_2.0\shua_governor\src\governor\media_gc.rs (316 lines)

#### run_backup_sync (Function)
```rust
// Lines 360-372 (13 LOC | Complexity 2) | used by 1 callers | [Async, Io]
pub async fn run_backup_sync(config: &BackupConfig, _source_dir: &Path, _db_path: &Path)
//  â³ Calls: BackupConfig
//  â³ Called by: test_run_backup_sync_disabled
```

#### test_run_backup_sync_disabled (Function)
```rust
// Lines 395-402 (8 LOC | Complexity 1) | used by 0 callers | [Async, Pure]
async fn test_run_backup_sync_disabled()
//  â³ Calls: BackupConfig, run_backup_sync
```

#### refresh_disk_stats (Function)
```rust
// Lines 78-193 (116 LOC | Complexity 7) | used by 1 callers | [Async, MutatesState, Io]
async fn refresh_disk_stats(
//  â³ Called by: start_disk_monitor_loop
```

#### GcGuard::drop (Function)
```rust
// Lines 20-22 (3 LOC | Complexity 1) | used by 2 callers | [TraitMethod, MutatesState]
fn drop(&mut self)
//  â³ Called by: upload_progress_sse, start_supervisor_loop
```

#### start_gc_loop (Function)
```rust
// Lines 200-205 (6 LOC | Complexity 2) | used by 1 callers | [Async, Pure]
pub async fn start_gc_loop(media_dir: Arc<PathBuf>, db: Arc<Mutex<Connection>>)
//  â³ Calls: run_garbage_collection
//  â³ Called by: main
```

#### run_garbage_collection (Function)
```rust
// Lines 211-344 (134 LOC | Complexity 21) | used by 1 callers | [Async, MutatesState, Io, HighComplexity]
pub async fn run_garbage_collection(media_dir: &Path, db: &Arc<Mutex<Connection>>)
//  â³ Called by: start_gc_loop
```

#### GcGuard (Struct)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers
struct GcGuard;
```

#### start_disk_monitor_loop (Function)
```rust
// Lines 67-76 (10 LOC | Complexity 2) | used by 1 callers | [Async, Pure]
pub async fn start_disk_monitor_loop(
//  â³ Calls: refresh_disk_stats
//  â³ Called by: main
```

#### BackupConfig (Struct)
```rust
// Lines 351-355 (5 LOC | Complexity 1) | used by 2 callers
pub struct BackupConfig
//  â³ Called by: test_run_backup_sync_disabled, run_backup_sync
```

#### MediaStats (Struct)
```rust
// Lines 43-50 (8 LOC | Complexity 1) | used by 0 callers
pub struct MediaStats
```

#### new_media_stats (Function)
```rust
// Lines 54-56 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn new_media_stats() -> SharedMediaStats
//  â³ Called by: main
```

#### start_subconscious_embedder_loop (Function)
```rust
// Lines 380-388 (9 LOC | Complexity 2) | used by 1 callers | [Async, Pure]
pub async fn start_subconscious_embedder_loop(_db: Arc<Mutex<Connection>>)
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_governor\src\logging\flush.rs (164 lines)

#### flush_loop (Function)
```rust
// Lines 79-214 (136 LOC | Complexity 19) | used by 1 callers | [Async, MutatesState, Io]
pub async fn flush_loop(
//  â³ Calls: LogEntry, ensure_schema, resolved_db_path
//  â³ Called by: main
```

#### resolved_db_path (Function)
```rust
// Lines 30-35 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
fn resolved_db_path() -> &'static str
//  â³ Called by: flush_loop
```

#### ensure_schema (Function)
```rust
// Lines 47-68 (22 LOC | Complexity 1) | used by 1 callers | [Io]
fn ensure_schema(conn: &Connection) -> rusqlite::Result<()>
//  â³ Called by: flush_loop
```

### C:\horAIzon_2.0\shua_governor\src\logging\entry.rs (220 lines)

#### Visitor::visit_map (Function)
```rust
// Lines 80-154 (75 LOC | Complexity 23) | used by 0 callers | [TraitMethod, MutatesState, HighComplexity]
fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
//  â³ Calls: BorrowedLogEntry, Visitor::Key
```

#### BorrowedLogEntry::Visitor (Struct)
```rust
// Lines 69-71 (3 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
struct Visitor<'a>
//  â³ Called by: BorrowedLogEntry::deserialize
```

#### log_min_level (Function)
```rust
// Lines 32-37 (6 LOC | Complexity 1) | used by 3 callers | [Pure]
pub fn log_min_level() -> u8
//  â³ Called by: ingest_log, harvest_socket_stream, harvest_pipe
```

#### LogEntry::from (Function)
```rust
// Lines 183-195 (13 LOC | Complexity 1) | used by 6 callers | [TraitMethod, Pure]
fn from(b: BorrowedLogEntry<'a>) -> Self
//  â³ Calls: LogEntry, BorrowedLogEntry
//  â³ Called by: try_forward, query_logs, ensure_cgroup_dir, serve_file, main, control_module
```

#### LogEntry (Struct)
```rust
// Lines 170-180 (11 LOC | Complexity 1) | used by 11 callers | [CorePrimitive]
pub struct LogEntry
//  â³ Called by: flush_loop, LogEntry::from, ChannelLogger::on_event, ChannelLogger::new, ChannelLogger, main, AppState, wrap_socket_raw_line, harvest_socket_stream, start_log_ipc_listener, wrap_raw_line
```

#### BorrowedLogEntry (Struct)
```rust
// Lines 52-62 (11 LOC | Complexity 1) | used by 6 callers
pub struct BorrowedLogEntry<'a>
//  â³ Called by: ingest_log, LogEntry::from, Visitor::visit_map, BorrowedLogEntry::deserialize, harvest_socket_stream, harvest_pipe
```

#### BorrowedLogEntry::deserialize (Function)
```rust
// Lines 65-158 (94 LOC | Complexity 23) | used by 0 callers | [TraitMethod, MutatesState, HighComplexity]
fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
//  â³ Calls: BorrowedLogEntry, BorrowedLogEntry::Visitor
```

#### Visitor::expecting (Function)
```rust
// Lines 76-78 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result
```

#### Visitor::Key (Enum)
```rust
// Lines 96-99 (4 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
enum Key<'b>
//  â³ Called by: Visitor::visit_map
```

### C:\horAIzon_2.0\shua_governor\src\governor\supervisor.rs (165 lines)

#### start_supervisor_loop (Function)
```rust
// Lines 29-193 (165 LOC | Complexity 12) | used by 1 callers | [Async, MutatesState, Io, CanPanic, HighComplexity]
pub async fn start_supervisor_loop(
//  â³ Calls: SystemMetrics, ModuleMetrics, ModuleState, MetricsSnapshot, GcGuard::drop, display_state, read_cgroup_cpu_usec, read_memory_bytes
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_governor\src\routes\dashboard.rs (216 lines)

#### get_console (Function)
```rust
// Lines 149-181 (33 LOC | Complexity 4) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn get_console(
//  â³ Calls: AppState
```

#### AppState (Struct)
```rust
// Lines 21-47 (27 LOC | Complexity 1) | used by 27 callers | [CorePrimitive]
pub struct AppState
//  â³ Calls: LogEntry, MetricsSnapshot
//  â³ Called by: infer, ingest_log, stream_logs, query_logs, get_preactivation_sheet, media_stats, serve_file, chunk_finalize, chunk_receive, chunk_init, upload_file, stream_metrics, handle_delete, handle_put, handle_get, handle_propfind, dav_handler, main, get_console, get_dashboard, mark_ready, handle_ws_proxy, ws_proxy_wildcard_handler, ws_proxy_handler, control_module, fallback_proxy_handler, create_router
```

#### inject_module_telemetry (Function)
```rust
// Lines 188-244 (57 LOC | Complexity 8) | used by 1 callers | [MutatesState]
fn inject_module_telemetry(
//  â³ Calls: ModuleEntry, display_state
//  â³ Called by: get_dashboard
```

#### get_dashboard (Function)
```rust
// Lines 49-147 (99 LOC | Complexity 14) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn get_dashboard(
//  â³ Calls: AppState, inject_module_telemetry
```

### C:\horAIzon_2.0\shua_governor\src\logging\bridge.rs (98 lines)

#### Visitor::record_str (Function)
```rust
// Lines 57-65 (9 LOC | Complexity 3) | used by 0 callers | [TraitMethod, MutatesState]
fn record_str(&mut self, field: &tracing::field::Field, value: &str)
```

#### ChannelLogger (Struct)
```rust
// Lines 9-11 (3 LOC | Complexity 1) | used by 0 callers
pub struct ChannelLogger
//  â³ Calls: LogEntry
```

#### Visitor::record_debug (Function)
```rust
// Lines 48-56 (9 LOC | Complexity 3) | used by 0 callers | [TraitMethod, MutatesState]
fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug)
```

#### ChannelLogger::on_event (Function)
```rust
// Lines 30-92 (63 LOC | Complexity 11) | used by 0 callers | [TraitMethod, MutatesState]
fn on_event(&self, event: &tracing::Event<'_>, _ctx: Context<'_, S>)
//  â³ Calls: LogEntry, ChannelLogger::Visitor, ChannelLogger::new
```

#### ChannelLogger::Visitor (Struct)
```rust
// Lines 42-46 (5 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
struct Visitor
//  â³ Called by: ChannelLogger::on_event
```

#### ChannelLogger::enabled (Function)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 0 callers | [TraitMethod, Pure]
fn enabled(&self, metadata: &tracing::Metadata<'_>, _ctx: Context<'_, S>) -> bool
```

#### ChannelLogger::new (Function)
```rust
// Lines 14-16 (3 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
pub fn new(tx: mpsc::Sender<LogEntry>) -> Self
//  â³ Calls: LogEntry
//  â³ Called by: ChannelLogger::on_event
```

### C:\horAIzon_2.0\shua_governor\src\governor\cgroups.rs (243 lines)

#### read_cgroup_cpu_usec (Function)
```rust
// Lines 244-284 (41 LOC | Complexity 11) | used by 1 callers | [Async, MutatesState, Io, CanPanic]
pub async fn read_cgroup_cpu_usec(module_id: &str, pid: Option<u32>) -> u64
//  â³ Calls: ensure_cgroup_dir, read_proc_cpu_usec
//  â³ Called by: start_supervisor_loop
```

#### ensure_cgroup_dir (Function)
```rust
// Lines 20-52 (33 LOC | Complexity 6) | used by 7 callers | [Async, MutatesState]
pub async fn ensure_cgroup_dir(module_id: &str) -> Result<PathBuf, Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: LogEntry::from
//  â³ Called by: read_cgroup_cpu_usec, kill, read_memory_bytes, assign_pid, unfreeze, freeze, control_module
```

#### read_cpu_temp_celsius (Function)
```rust
// Lines 197-209 (13 LOC | Complexity 3) | used by 1 callers | [Async, Io]
pub async fn read_cpu_temp_celsius() -> f32
//  â³ Called by: test_cpu_temp_non_linux
```

#### read_proc_cpu_usec (Function)
```rust
// Lines 221-239 (19 LOC | Complexity 4) | used by 1 callers | [Async, Io]
async fn read_proc_cpu_usec(pid: u32) -> u64
//  â³ Called by: read_cgroup_cpu_usec
```

#### assign_pid (Function)
```rust
// Lines 72-78 (7 LOC | Complexity 3) | used by 1 callers | [Async, MutatesState]
pub async fn assign_pid(module_id: &str, pid: u32) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: ensure_cgroup_dir
//  â³ Called by: control_module
```

#### read_system_cpu_pct (Function)
```rust
// Lines 159-190 (32 LOC | Complexity 6) | used by 0 callers | [Async, MutatesState, Io, PotentialDeadCode]
pub async fn read_system_cpu_pct() -> f32
//  â³ Calls: read_stat_fields
```

#### kill (Function)
```rust
// Lines 213-218 (6 LOC | Complexity 3) | used by 1 callers | [Async, MutatesState]
pub async fn kill(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: ensure_cgroup_dir
//  â³ Called by: control_module
```

#### read_proc_memory_bytes (Function)
```rust
// Lines 85-108 (24 LOC | Complexity 6) | used by 1 callers | [Async, Io]
pub async fn read_proc_memory_bytes(pid: u32) -> u64
//  â³ Called by: read_memory_bytes
```

#### read_memory_bytes (Function)
```rust
// Lines 112-144 (33 LOC | Complexity 11) | used by 2 callers | [Async, MutatesState, Io]
pub async fn read_memory_bytes(module_id: &str, _pid: Option<u32>) -> Result<u64, Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: ensure_cgroup_dir, read_proc_memory_bytes
//  â³ Called by: test_mock_cgroups, start_supervisor_loop
```

#### test_cpu_temp_non_linux (Function)
```rust
// Lines 299-303 (5 LOC | Complexity 1) | used by 0 callers | [Async, CanPanic]
async fn test_cpu_temp_non_linux()
//  â³ Calls: read_cpu_temp_celsius
```

#### read_stat_fields (Function)
```rust
// Lines 162-173 (12 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
async fn read_stat_fields() -> Option<(u64, u64)>
//  â³ Called by: read_system_cpu_pct
```

#### unfreeze (Function)
```rust
// Lines 63-68 (6 LOC | Complexity 3) | used by 1 callers | [Async, MutatesState]
pub async fn unfreeze(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: ensure_cgroup_dir
//  â³ Called by: control_module
```

#### freeze (Function)
```rust
// Lines 55-60 (6 LOC | Complexity 3) | used by 2 callers | [Async, MutatesState]
pub async fn freeze(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: ensure_cgroup_dir
//  â³ Called by: test_mock_cgroups, control_module
```

#### test_mock_cgroups (Function)
```rust
// Lines 291-296 (6 LOC | Complexity 1) | used by 0 callers | [Async, CanPanic]
async fn test_mock_cgroups()
//  â³ Calls: read_memory_bytes, freeze
```

### C:\horAIzon_2.0\shua_governor\src\routes\mod.rs (96 lines)

#### fallback_proxy_handler (Function)
```rust
// Lines 104-131 (28 LOC | Complexity 4) | used by 0 callers | [Async, Pure, PotentialDeadCode]
async fn fallback_proxy_handler(
//  â³ Calls: AppState, proxy_request
```

#### track_performance_timing (Function)
```rust
// Lines 32-56 (25 LOC | Complexity 2) | used by 0 callers | [Async, MutatesState, PotentialDeadCode]
async fn track_performance_timing(req: Request, next: Next) -> Response
```

#### create_router (Function)
```rust
// Lines 59-101 (43 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn create_router(state: AppState) -> Router
//  â³ Calls: AppState
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_governor\src\routes\health.rs (6 lines)

#### health_check (Function)
```rust
// Lines 6-11 (6 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn health_check() -> Json<Value>
```

### C:\horAIzon_2.0\shua_governor\src\routes\media_dav.rs (317 lines)

#### handle_delete (Function)
```rust
// Lines 336-376 (41 LOC | Complexity 5) | used by 1 callers | [Async, Io]
async fn handle_delete(
//  â³ Calls: AppState
//  â³ Called by: dav_handler
```

#### handle_put (Function)
```rust
// Lines 290-330 (41 LOC | Complexity 3) | used by 1 callers | [Async, Pure]
async fn handle_put(
//  â³ Calls: AppState, process_upload_bytes
//  â³ Called by: dav_handler
```

#### handle_get (Function)
```rust
// Lines 227-284 (58 LOC | Complexity 5) | used by 1 callers | [Async, Pure]
async fn handle_get(
//  â³ Calls: AppState
//  â³ Called by: dav_handler
```

#### build_propfind_response (Function)
```rust
// Lines 29-81 (53 LOC | Complexity 2) | used by 1 callers | [MutatesState]
fn build_propfind_response(entries: &[DavEntry], base_url: &str) -> String
//  â³ Calls: DavEntry
//  â³ Called by: handle_propfind
```

#### html_escape (Function)
```rust
// Lines 83-88 (6 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
fn html_escape(s: &str) -> String
```

#### dav_handler (Function)
```rust
// Lines 106-157 (52 LOC | Complexity 8) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn dav_handler(
//  â³ Calls: AppState, handle_delete, handle_put, handle_get, handle_propfind, is_loopback
```

#### handle_propfind (Function)
```rust
// Lines 163-221 (59 LOC | Complexity 10) | used by 1 callers | [Async, MutatesState, Io]
async fn handle_propfind(
//  â³ Calls: DavEntry, AppState, build_propfind_response
//  â³ Called by: dav_handler
```

#### DavEntry (Struct)
```rust
// Lines 94-100 (7 LOC | Complexity 1) | used by 2 callers
struct DavEntry
//  â³ Called by: handle_propfind, build_propfind_response
```

### C:\horAIzon_2.0\shua_governor\src\routes\manifest.rs (17 lines)

#### get_manifest (Function)
```rust
// Lines 6-22 (17 LOC | Complexity 3) | used by 0 callers | [Async, Io, ApiRoute]
pub async fn get_manifest() -> impl IntoResponse
```

### C:\horAIzon_2.0\shua_governor\src\routes\module_control.rs (398 lines)

#### harvest_pipe (Function)
```rust
// Lines 264-380 (117 LOC | Complexity 19) | used by 1 callers | [Async, MutatesState]
async fn harvest_pipe<R>(
//  â³ Calls: BorrowedLogEntry, read_until_newline, wrap_raw_line, module_id_to_u8, log_min_level
//  â³ Called by: control_module
```

#### wrap_raw_line (Function)
```rust
// Lines 414-432 (19 LOC | Complexity 3) | used by 1 callers | [Io]
fn wrap_raw_line(line: &str, module_u8: u8, is_stderr: bool) -> Option<LogEntry>
//  â³ Calls: LogEntry
//  â³ Called by: harvest_pipe
```

#### control_module (Function)
```rust
// Lines 27-246 (220 LOC | Complexity 21) | used by 0 callers | [Async, MutatesState, CanPanic, ApiRoute, HighComplexity]
pub async fn control_module(
//  â³ Calls: AppState, kill, unfreeze, freeze, assign_pid, harvest_pipe, LogEntry::from, ensure_cgroup_dir
```

#### module_id_to_u8 (Function)
```rust
// Lines 436-450 (15 LOC | Complexity 12) | used by 1 callers | [Pure]
fn module_id_to_u8(id: &str) -> u8
//  â³ Called by: harvest_pipe
```

#### read_until_newline (Function)
```rust
// Lines 384-410 (27 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, Io, PotentialDeadCode]
async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
```

### C:\horAIzon_2.0\shua_governor\src\routes\module_ready.rs (39 lines)

#### mark_ready (Function)
```rust
// Lines 31-69 (39 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn mark_ready(
//  â³ Calls: AppState
```

### C:\horAIzon_2.0\shua_governor\src\proxy\ws_proxy.rs (85 lines)

#### pipe_sockets (Function)
```rust
// Lines 52-107 (56 LOC | Complexity 18) | used by 1 callers | [Async, MutatesState, Io]
async fn pipe_sockets(client: WebSocket, module_id: String, upstream_port: u16)
//  â³ Called by: handle_ws_proxy
```

#### ws_proxy_wildcard_handler (Function)
```rust
// Lines 25-31 (7 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn ws_proxy_wildcard_handler(
//  â³ Calls: AppState, handle_ws_proxy
```

#### handle_ws_proxy (Function)
```rust
// Lines 33-47 (15 LOC | Complexity 1) | used by 2 callers | [Async, Io]
async fn handle_ws_proxy(
//  â³ Calls: AppState, pipe_sockets
//  â³ Called by: ws_proxy_wildcard_handler, ws_proxy_handler
```

#### ws_proxy_handler (Function)
```rust
// Lines 17-23 (7 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn ws_proxy_handler(
//  â³ Calls: AppState, handle_ws_proxy
```

### C:\horAIzon_2.0\shua_governor\src\main.rs (288 lines)

#### main (Function)
```rust
// Lines 28-315 (288 LOC | Complexity 9) | used by 0 callers | [EntryPoint, Async, MutatesState, Io, CanPanic, HighComplexity]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: AppState, MetricsSnapshot, LogEntry, create_router, start_subconscious_embedder_loop, start_gc_loop, start_disk_monitor_loop, start_supervisor_loop, new_media_stats, LogEntry::from, new_system_metrics, load_from_json, new_registry, start_log_ipc_listener, flush_loop
```

### C:\horAIzon_2.0\shua_governor\src\routes\media.rs (712 lines)

#### is_loopback (Function)
```rust
// Lines 68-81 (14 LOC | Complexity 1) | used by 2 callers | [Pure]
fn is_loopback(headers: &HeaderMap) -> bool
//  â³ Called by: verify_auth, dav_handler
```

#### ThumbnailQuery (Struct)
```rust
// Lines 688-690 (3 LOC | Complexity 1) | used by 1 callers
pub struct ThumbnailQuery
//  â³ Called by: serve_file
```

#### is_allowed_mime (Function)
```rust
// Lines 55-62 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
fn is_allowed_mime(mime: &str) -> bool
//  â³ Called by: process_upload_bytes
```

#### upload_file (Function)
```rust
// Lines 273-344 (72 LOC | Complexity 12) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn upload_file(
//  â³ Calls: AppState, process_upload_bytes, verify_auth
```

#### chunk_init (Function)
```rust
// Lines 358-452 (95 LOC | Complexity 4) | used by 0 callers | [Async, Io, ApiRoute]
pub async fn chunk_init(
//  â³ Calls: UploadState, ProgressEvent, ChunkInitRequest, AppState, verify_auth
```

#### verify_auth (Function)
```rust
// Lines 84-96 (13 LOC | Complexity 4) | used by 5 callers | [Pure]
fn verify_auth(headers: &HeaderMap) -> Result<(), Response>
//  â³ Calls: is_loopback
//  â³ Called by: media_stats, chunk_finalize, chunk_receive, chunk_init, upload_file
```

#### serve_file (Function)
```rust
// Lines 692-797 (106 LOC | Complexity 12) | used by 0 callers | [Async, MutatesState, Io, CanPanic, ApiRoute]
pub async fn serve_file(
//  â³ Calls: ThumbnailQuery, AppState, LogEntry::from
```

#### UploadState (Struct)
```rust
// Lines 41-45 (5 LOC | Complexity 1) | used by 1 callers
struct UploadState
//  â³ Calls: ProgressEvent
//  â³ Called by: chunk_init
```

#### chunk_finalize (Function)
```rust
// Lines 515-648 (134 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, ApiRoute]
pub async fn chunk_finalize(
//  â³ Calls: ProgressEvent, AppState, process_upload_bytes, verify_auth
```

#### ChunkInitRequest (Struct)
```rust
// Lines 352-356 (5 LOC | Complexity 1) | used by 1 callers
pub struct ChunkInitRequest
//  â³ Called by: chunk_init
```

#### media_stats (Function)
```rust
// Lines 803-818 (16 LOC | Complexity 2) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn media_stats(
//  â³ Calls: AppState, verify_auth
```

#### ProgressEvent (Struct)
```rust
// Lines 34-39 (6 LOC | Complexity 1) | used by 4 callers
pub struct ProgressEvent
//  â³ Called by: chunk_finalize, chunk_receive, chunk_init, UploadState
```

#### chunk_receive (Function)
```rust
// Lines 459-508 (50 LOC | Complexity 6) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn chunk_receive(
//  â³ Calls: ProgressEvent, AppState, verify_auth
```

#### upload_progress_sse (Function)
```rust
// Lines 654-680 (27 LOC | Complexity 3) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn upload_progress_sse(
//  â³ Calls: GcGuard::drop
```

#### process_upload_bytes (Function)
```rust
// Lines 110-267 (158 LOC | Complexity 22) | used by 3 callers | [Async, MutatesState, Io, HighComplexity]
pub async fn process_upload_bytes(
//  â³ Calls: is_allowed_mime
//  â³ Called by: chunk_finalize, upload_file, handle_put
```

### C:\horAIzon_2.0\shua_governor\src\routes\logs.rs (133 lines)

#### LogQueryParams (Struct)
```rust
// Lines 42-49 (8 LOC | Complexity 1) | used by 1 callers
pub struct LogQueryParams
//  â³ Called by: query_logs
```

#### query_logs (Function)
```rust
// Lines 51-101 (51 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, Io, ApiRoute]
pub async fn query_logs(
//  â³ Calls: LogQueryParams, AppState, LogEntry::from
```

#### LogStreamParams (Struct)
```rust
// Lines 108-111 (4 LOC | Complexity 1) | used by 1 callers
pub struct LogStreamParams
//  â³ Called by: stream_logs
```

#### stream_logs (Function)
```rust
// Lines 113-146 (34 LOC | Complexity 7) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn stream_logs(
//  â³ Calls: LogStreamParams, AppState
```

#### ingest_log (Function)
```rust
// Lines 165-200 (36 LOC | Complexity 6) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn ingest_log(
//  â³ Calls: BorrowedLogEntry, AppState, log_min_level
```

### C:\horAIzon_2.0\shua_governor\src\proxy\handler.rs (34 lines)

#### get_client (Function)
```rust
// Lines 15-17 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
fn get_client() -> &'static Client<HttpConnector, Body>
```

#### proxy_request (Function)
```rust
// Lines 22-52 (31 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
pub async fn proxy_request(
//  â³ Calls: get_client
//  â³ Called by: fallback_proxy_handler
```

### C:\horAIzon_2.0\shua_governor\src\sdui\node.rs (90 lines)

#### test_sdui_node_construction (Function)
```rust
// Lines 103-107 (5 LOC | Complexity 1) | used by 0 callers | [CanPanic]
fn test_sdui_node_construction()
//  â³ Calls: SduiNode::new
```

#### SduiNode (Struct)
```rust
// Lines 11-19 (9 LOC | Complexity 1) | used by 1 callers
pub struct SduiNode
//  â³ Called by: SduiNode::with_child
```

#### SduiNode::new (Function)
```rust
// Lines 23-33 (11 LOC | Complexity 1) | used by 2 callers | [Pure, TraitMethod]
pub fn new(node_type: i32) -> Self
//  â³ Called by: test_sdui_node_builders, test_sdui_node_construction
```

#### SduiNode::with_child (Function)
```rust
// Lines 48-51 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState, TraitMethod]
pub fn with_child(mut self, child: SduiNode) -> Self
//  â³ Calls: SduiNode
//  â³ Called by: test_sdui_node_builders
```

#### SduiNode::with_content (Function)
```rust
// Lines 42-45 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState, TraitMethod]
pub fn with_content(mut self, key: i32, val: impl Into<Value>) -> Self
//  â³ Called by: test_sdui_node_builders
```

#### test_sdui_node_builders (Function)
```rust
// Lines 110-122 (13 LOC | Complexity 1) | used by 0 callers | [CanPanic]
fn test_sdui_node_builders()
//  â³ Calls: SduiNode::with_child, SduiNode::with_content, SduiNode::with_behavior, SduiNode::new
```

#### SduiNode::serialize (Function)
```rust
// Lines 56-95 (40 LOC | Complexity 17) | used by 0 callers | [TraitMethod, MutatesState]
fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
```

#### SduiNode::with_behavior (Function)
```rust
// Lines 36-39 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState, TraitMethod]
pub fn with_behavior(mut self, key: i32, val: impl Into<Value>) -> Self
//  â³ Called by: test_sdui_node_builders
```

### C:\horAIzon_2.0\shua_governor\src\routes\ai_proxy.rs (112 lines)

#### get_client (Function)
```rust
// Lines 46-48 (3 LOC | Complexity 1) | used by 2 callers | [Pure]
fn get_client() -> &'static Client<HttpConnector, Body>
//  â³ Called by: try_forward, proxy_request
```

#### error_response (Function)
```rust
// Lines 170-172 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
fn error_response(status: StatusCode, code: &str) -> Response
//  â³ Called by: infer
```

#### try_forward (Function)
```rust
// Lines 141-167 (27 LOC | Complexity 6) | used by 1 callers | [Async, Io]
async fn try_forward(url: &str, body: Value) -> Result<Response, String>
//  â³ Calls: get_client, LogEntry::from
//  â³ Called by: infer
```

#### infer (Function)
```rust
// Lines 57-135 (79 LOC | Complexity 9) | used by 0 callers | [Async, MutatesState, Io, ApiRoute]
pub async fn infer(
//  â³ Calls: AppState, try_forward, error_response
```

### C:\horAIzon_2.0\shua_governor\src\routes\preactivation.rs (222 lines)

#### build_diary_preactivation_payload (Function)
```rust
// Lines 61-110 (50 LOC | Complexity 1) | used by 1 callers | [Pure]
fn build_diary_preactivation_payload(display_name: &str, module_id: &str) -> Value
//  â³ Called by: get_preactivation_sheet
```

#### build_provider_card (Function)
```rust
// Lines 117-215 (99 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
fn build_provider_card(module_id: &str, provider_key: &str, title: &str, subtitle: &str, icon: &str, accent_token: i64) -> Value
```

#### build_generic_preactivation_payload (Function)
```rust
// Lines 217-247 (31 LOC | Complexity 1) | used by 1 callers | [Pure]
fn build_generic_preactivation_payload(display_name: &str, module_id: &str) -> Value
//  â³ Called by: get_preactivation_sheet
```

#### get_preactivation_sheet (Function)
```rust
// Lines 17-58 (42 LOC | Complexity 6) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn get_preactivation_sheet(
//  â³ Calls: AppState, build_generic_preactivation_payload, build_diary_preactivation_payload
```


