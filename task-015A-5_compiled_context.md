# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 23

================================================================================

<!-- START_FILE: shua_code_visualizer\src\lib.rs -->
# FILE: lib.rs
**Relative Path**: `shua_code_visualizer\src\lib.rs`

pub mod broker;
pub mod graph;
pub mod mcp;
pub mod parser;
pub mod watch;


<!-- END_FILE: shua_code_visualizer\src\lib.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\main.rs -->
# FILE: main.rs
**Relative Path**: `shua_code_visualizer\src\main.rs`

use clap::Parser;
use schemars::schema_for;
use shua_code_visualizer::broker::ipc_client::IpcClient;
use shua_code_visualizer::broker::parent_link::{ExecutionMode, ParentLink};
use shua_code_visualizer::graph::store::CodeGraph;
use shua_code_visualizer::mcp::schema::{
    BlastRadiusArgs, FindCallersArgs, GraphEdge, GraphNode, ParseAstArgs, RenderGraphArgs,
    TopologyDeltaEvent, TopologyExportResponse,
};
use shua_code_visualizer::parser::parse_file;
use shua_code_visualizer::watch::hash_cache::HashCache;
use shua_code_visualizer::watch::watcher::CodeWatcher;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(name = "shua_code_visualizer")]
#[command(about = "horAIzon 3.0 AST scanner, code topology graph, metrics, and MCP server")]
struct Args {
    /// Export JSON Schemas for wire DTO contracts and MCP tool inputs to stdout
    #[arg(long)]
    export_schema: bool,

    /// Target workspace root directory to scan and watch
    #[arg(long, default_value = ".")]
    workspace_root: PathBuf,

    /// Path to persistent hash cache JSON index
    #[arg(long, default_value = ".hash_cache.json")]
    hash_cache: PathBuf,

    /// Governor RPC port for auto-registration
    #[arg(long, default_value = "50051")]
    governor_port: u16,

    /// Export rendered topology graph JSON to file path and exit
    #[arg(long)]
    export_graph: Option<PathBuf>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    if args.export_schema {
        println!("=== GraphNode Schema ===");
        let schema = schema_for!(GraphNode);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== GraphEdge Schema ===");
        let schema = schema_for!(GraphEdge);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== TopologyExportResponse Schema ===");
        let schema = schema_for!(TopologyExportResponse);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== TopologyDeltaEvent Schema ===");
        let schema = schema_for!(TopologyDeltaEvent);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== ParseAstArgs Schema ===");
        let schema = schema_for!(ParseAstArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== RenderGraphArgs Schema ===");
        let schema = schema_for!(RenderGraphArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== BlastRadiusArgs Schema ===");
        let schema = schema_for!(BlastRadiusArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== FindCallersArgs Schema ===");
        let schema = schema_for!(FindCallersArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());
        return Ok(());
    }

    println!("============================================================");
    println!("  horAIzon 3.0 — shua_code_visualizer daemon starting...   ");
    println!("============================================================");
    println!("Workspace Root : {}", args.workspace_root.display());
    println!("Hash Cache     : {}", args.hash_cache.display());

    // 0. Auto-detect runtime execution mode (Standalone vs Managed Subprocess)
    let mode = ParentLink::detect_execution_mode();
    match &mode {
        ExecutionMode::Standalone => {
            println!("Execution Mode : Standalone (Run manually by user).");
            println!("               : Zero port scanning or governor connection attempts.");
        }
        ExecutionMode::ManagedSubprocess { parent_pid, ipc_port } => {
            println!("Execution Mode : Managed Subprocess (Parent PID: {}, IPC Port: {}).", parent_pid, ipc_port);
            println!("               : Lifetime linked to parent governor process.");
            ParentLink::spawn_parent_death_monitor(*parent_pid);
        }
    }

    // 1. Boot Sequence: Load persistent hash cache from disk & log diff
    let mut cache = HashCache::load_from_disk(&args.hash_cache).unwrap_or_default();

    println!("Scanning filesystem for source code changes...");
    let diff = cache.diff_directory(&args.workspace_root);
    println!(
        "Hash index status: {} added, {} modified, {} removed.",
        diff.added.len(),
        diff.modified.len(),
        diff.removed.len()
    );

    // 2. Perform complete boot scan of all valid source files to guarantee 100% graph coverage across restarts
    let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
    let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

    let mut parse_results = Vec::new();
    for entry in WalkDir::new(&args.workspace_root)
        .into_iter()
        .filter_entry(|e| {
            let name = e.file_name().to_string_lossy();
            !ignore_dirs.contains(&name.as_ref())
        })
        .filter_map(|e| e.ok())
    {
        if entry.file_type().is_file() {
            if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                if valid_extensions.contains(&ext) {
                    let path_str = entry.path().to_string_lossy().to_string();
                    if let Ok(code) = fs::read_to_string(entry.path()) {
                        let result = parse_file(&code, &path_str, None);
                        parse_results.push(result);
                    }
                }
            }
        }
    }

    let mut graph = CodeGraph::new();
    graph.build_from_parse_results(&parse_results);

    // 3. Save updated hash cache back to disk
    if let Err(e) = cache.save_to_disk(&args.hash_cache) {
        eprintln!("Warning: Failed to save hash cache to disk: {}", e);
    }

    println!(
        "CodeGraph initialized successfully: {} symbols (nodes), {} edges.",
        graph.graph.node_count(),
        graph.graph.edge_count()
    );

    if let Some(ref graph_out_path) = args.export_graph {
        let export = graph.render_subgraph(None, None);
        let json_text = serde_json::to_string_pretty(&export)?;
        fs::write(graph_out_path, json_text)?;
        println!("Topology graph exported successfully to: {}", graph_out_path.display());
        return Ok(());
    }

    let shared_graph = Arc::new(Mutex::new(graph));

    // 4. Start IPC Broker loop if in Managed Subprocess mode
    let delta_tx = if let ExecutionMode::ManagedSubprocess { ipc_port, .. } = mode {
        Some(IpcClient::start_ipc_loop(ipc_port, Arc::clone(&shared_graph)).await)
    } else {
        None
    };

    // 5. Start live file watcher
    let mut watcher_opt = match CodeWatcher::new(&args.workspace_root) {
        Ok(w) => {
            println!("Live CodeWatcher daemon started successfully.");
            Some(w)
        }
        Err(e) => {
            eprintln!(
                "Warning: File watcher failed to start ({}); falling back to read-only query mode.",
                e
            );
            None
        }
    };

    println!("shua_code_visualizer core engine ready. Entering event loop...");

    // 6. Event loop: poll watcher patches (if active) and service queries
    loop {
        if let Some(ref mut watcher) = watcher_opt {
            let mut g = shared_graph.lock().await;
            while let Some(delta) = watcher.poll_and_apply_patch(&mut g) {
                println!(
                    "Incremental patch applied: {:?} '{}' (affected symbols: {})",
                    delta.change_type,
                    delta.file_path,
                    delta.affected_node_ids.len()
                );
                if let Some(ref tx) = delta_tx {
                    let _ = tx.send(delta);
                }
            }
        }

        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    }
}


<!-- END_FILE: shua_code_visualizer\src\main.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\ipc_client.rs -->
# FILE: ipc_client.rs
**Relative Path**: `shua_code_visualizer\src\broker\ipc_client.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::handler::McpHandler;
use crate::mcp::schema::TopologyDeltaEvent;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::sync::Arc;
use tokio::sync::{mpsc, Mutex};
use tokio::time::{sleep, Duration};
use tokio_tungstenite::{connect_async, tungstenite::Message};

pub struct IpcClient;

impl IpcClient {
    /// Connects to parent governor IPC WebSocket server, auto-registers tools, and enters duplex message loop.
    /// Returns an MPSC sender for broadcasting live TopologyDeltaEvents over the IPC connection.
    pub async fn start_ipc_loop(
        ipc_port: u16,
        graph: Arc<Mutex<CodeGraph>>,
    ) -> mpsc::UnboundedSender<TopologyDeltaEvent> {
        let (tx, mut rx) = mpsc::unbounded_channel::<TopologyDeltaEvent>();
        let url = format!("ws://127.0.0.1:{}", ipc_port);

        tokio::spawn(async move {
            loop {
                println!("Connecting to parent governor IPC socket at {}...", url);
                match connect_async(&url).await {
                    Ok((ws_stream, _)) => {
                        println!("HBP v2 IPC connection established with parent governor.");
                        let (mut write, mut read) = ws_stream.split();

                        // 1. Send registration frame
                        let reg_frame = serde_json::json!({
                            "op": "governor.mcp.register",
                            "scope": "code",
                            "tools": [
                                "code_parse_ast",
                                "code_render_graph",
                                "code_blast_radius",
                                "code_find_callers",
                                "code_find_dead_code",
                                "code_find_god_functions",
                                "code_check_contract_drift"
                            ]
                        });

                        if let Ok(reg_text) = serde_json::to_string(&reg_frame) {
                            let _ = write.send(Message::Text(reg_text)).await;
                        }

                        // 2. Duplex event & message loop using tokio::select!
                        loop {
                            tokio::select! {
                                // Incoming IPC frames from parent governor
                                msg = read.next() => {
                                    match msg {
                                        Some(Ok(Message::Text(text))) => {
                                            if let Ok(val) = serde_json::from_str::<Value>(&text) {
                                                if val["op"] == "mcp.tool_call" {
                                                    let tool_name = val["tool"].as_str().unwrap_or("");
                                                    let args = &val["args"];
                                                    let req_id = val["id"].clone();

                                                    let mut g = graph.lock().await;
                                                    let mut handler = McpHandler::new(&mut g, None);
                                                    let res = handler.handle_tool_call(tool_name, args);

                                                    let resp_frame = match res {
                                                        Ok(result_val) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "ok",
                                                            "result": result_val
                                                        }),
                                                        Err(err_msg) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "error",
                                                            "error": err_msg
                                                        }),
                                                    };

                                                    if let Ok(resp_text) = serde_json::to_string(&resp_frame) {
                                                        let _ = write.send(Message::Text(resp_text)).await;
                                                    }
                                                } else {
                                                    println!("Received unhandled HBP IPC op: '{}'", val["op"].as_str().unwrap_or("unknown"));
                                                }
                                            }
                                        }
                                        Some(Ok(_)) => {}
                                        Some(Err(e)) => {
                                            eprintln!("Governor IPC read error: {}", e);
                                            break;
                                        }
                                        None => {
                                            println!("Governor IPC connection closed by remote.");
                                            break;
                                        }
                                    }
                                }

                                // Outgoing TopologyDeltaEvents from live watcher
                                delta_opt = rx.recv() => {
                                    if let Some(event) = delta_opt {
                                        let push_frame = serde_json::json!({
                                            "op": "changed",
                                            "event": event
                                        });

                                        if let Ok(push_text) = serde_json::to_string(&push_frame) {
                                            if let Err(e) = write.send(Message::Text(push_text)).await {
                                                eprintln!("Failed to push TopologyDeltaEvent to governor: {}", e);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!(
                            "Governor IPC connection failed ({}); retrying in 3 seconds...",
                            e
                        );
                    }
                }
                sleep(Duration::from_secs(3)).await;
            }
        });

        tx
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_ipc_client_channel_creation() {
        let graph = Arc::new(Mutex::new(CodeGraph::new()));
        let tx = IpcClient::start_ipc_loop(59999, graph).await;

        let sample_event = TopologyDeltaEvent {
            file_path: "src/lib.rs".to_string(),
            change_type: crate::mcp::schema::ChangeType::Modified,
            affected_node_ids: vec!["src/lib.rs:foo".to_string()],
        };

        assert!(tx.send(sample_event).is_ok());
    }
}


<!-- END_FILE: shua_code_visualizer\src\broker\ipc_client.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\broker\mod.rs`

pub mod ipc_client;
pub mod parent_link;


<!-- END_FILE: shua_code_visualizer\src\broker\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\parent_link.rs -->
# FILE: parent_link.rs
**Relative Path**: `shua_code_visualizer\src\broker\parent_link.rs`

use std::env;
use std::time::Duration;
use tokio::time::sleep;

/// Runtime execution mode auto-detected from environment
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionMode {
    /// Standalone mode (run directly by human user on Windows or CLI). Zero network scanning.
    Standalone,
    /// Managed subprocess mode (spawned by shua_governor). Linked lifetime & active HBP IPC connection.
    ManagedSubprocess { parent_pid: u32, ipc_port: u16 },
}

pub struct ParentLink;

impl ParentLink {
    /// Detects execution mode by inspecting environment for SHUA_GOVERNOR_PID and SHUA_GOVERNOR_IPC_PORT
    pub fn detect_execution_mode() -> ExecutionMode {
        let pid_var = env::var("SHUA_GOVERNOR_PID").ok();
        let port_var = env::var("SHUA_GOVERNOR_IPC_PORT").ok();

        match (pid_var, port_var) {
            (Some(pid_str), Some(port_str)) => {
                if let (Ok(parent_pid), Ok(ipc_port)) = (pid_str.parse::<u32>(), port_str.parse::<u16>()) {
                    ExecutionMode::ManagedSubprocess { parent_pid, ipc_port }
                } else {
                    ExecutionMode::Standalone
                }
            }
            _ => ExecutionMode::Standalone,
        }
    }

    /// Spawns a background task monitoring parent_pid. If parent process terminates, self-terminates.
    pub fn spawn_parent_death_monitor(parent_pid: u32) {
        tokio::spawn(async move {
            loop {
                sleep(Duration::from_secs(1)).await;
                if !is_process_alive(parent_pid) {
                    eprintln!(
                        "Parent governor process (PID {}) terminated. Self-terminating shua_code_visualizer.",
                        parent_pid
                    );
                    std::process::exit(0);
                }
            }
        });
    }
}

/// Checks if a process PID is currently alive on OS
#[cfg(target_os = "windows")]
fn is_process_alive(pid: u32) -> bool {
    use windows_sys::Win32::Foundation::CloseHandle;
    use windows_sys::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION};

    unsafe {
        let handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if handle == 0 {
            false
        } else {
            CloseHandle(handle);
            true
        }
    }
}

#[cfg(not(target_os = "windows"))]
fn is_process_alive(pid: u32) -> bool {
    unsafe { libc::kill(pid as libc::pid_t, 0) == 0 }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_standalone_mode_when_env_unset() {
        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(mode, ExecutionMode::Standalone);
    }

    #[test]
    fn test_detect_managed_mode_when_env_set() {
        env::set_var("SHUA_GOVERNOR_PID", "12345");
        env::set_var("SHUA_GOVERNOR_IPC_PORT", "7700");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(
            mode,
            ExecutionMode::ManagedSubprocess {
                parent_pid: 12345,
                ipc_port: 7700
            }
        );

        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");
    }
}


<!-- END_FILE: shua_code_visualizer\src\broker\parent_link.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\graph\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\graph\mod.rs`

pub mod store;


<!-- END_FILE: shua_code_visualizer\src\graph\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\graph\store.rs -->
# FILE: store.rs
**Relative Path**: `shua_code_visualizer\src\graph\store.rs`

use crate::mcp::schema::{ChangeType, GraphEdge, GraphNode, TopologyDeltaEvent, TopologyExportResponse};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, ParseResult};
use crate::parser::parse_file;
use petgraph::stable_graph::{NodeIndex, StableDiGraph};
use petgraph::visit::{EdgeRef, IntoEdgeReferences};
use std::collections::{HashMap, HashSet};

/// Checks if string matches module path target respecting boundary delimiters (`/`, `::`, `.`)
fn is_module_match(file: &str, qualified_name: &str, target: &str) -> bool {
    let check = |s: &str| {
        if s == target {
            return true;
        }
        if s.starts_with(target) {
            let remainder = &s[target.len()..];
            remainder.starts_with('/') || remainder.starts_with("::") || remainder.starts_with('.')
        } else {
            false
        }
    };
    check(file) || check(qualified_name)
}

/// In-memory graph resolution engine backed by `petgraph::stable_graph::StableDiGraph`
pub struct CodeGraph {
    pub graph: StableDiGraph<GraphNode, GraphEdge>,
    pub index: HashMap<String, NodeIndex>,
}

impl Default for CodeGraph {
    fn default() -> Self {
        Self::new()
    }
}

impl CodeGraph {
    /// Initializes an empty `CodeGraph`
    pub fn new() -> Self {
        Self {
            graph: StableDiGraph::new(),
            index: HashMap::new(),
        }
    }

    /// Adds or updates an extracted symbol node in the graph
    pub fn add_symbol(&mut self, sym: ExtractedSymbol) -> NodeIndex {
        let node_payload = GraphNode {
            id: sym.id,
            kind: sym.kind,
            qualified_name: sym.qualified_name.clone(),
            file: sym.file,
            line: sym.line,
            params: sym.params,
            return_type: sym.return_type,
            complexity: sym.complexity,
            side_effects: sym.side_effects,
            intent: sym.intent,
            loc: sym.loc,
            is_public: sym.is_public,
            is_test: sym.is_test,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
        };

        if let Some(&existing_idx) = self.index.get(&sym.qualified_name) {
            if let Some(weight) = self.graph.node_weight_mut(existing_idx) {
                *weight = node_payload;
            }
            existing_idx
        } else {
            let idx = self.graph.add_node(node_payload);
            self.index.insert(sym.qualified_name, idx);
            idx
        }
    }

    /// Adds a relationship edge, failing closed (safely dropping) if callee target is unresolved
    pub fn add_edge(&mut self, edge: ExtractedEdge) -> bool {
        let from_idx = match self.index.get(&edge.from) {
            Some(&idx) => idx,
            None => return false,
        };

        // Fail-closed check: drop edge if callee `to` symbol cannot be resolved
        let to_idx = match self.index.get(&edge.to) {
            Some(&idx) => idx,
            None => return false,
        };

        let edge_payload = GraphEdge {
            from: edge.from,
            to: edge.to,
            relation: edge.relation,
        };

        self.graph.add_edge(from_idx, to_idx, edge_payload);
        true
    }

    /// Populates the graph from multiple parser results and computes initial fan_in / fan_out metrics
    pub fn build_from_parse_results(&mut self, results: &[ParseResult]) {
        self.graph.clear();
        self.index.clear();

        for res in results {
            for sym in &res.symbols {
                self.add_symbol(sym.clone());
            }
        }

        for res in results {
            for edge in &res.edges {
                self.add_edge(edge.clone());
            }
        }

        self.update_degree_metrics();
    }

    /// Safely removes all symbols and connected edges belonging to a file path without corrupting node indices
    pub fn remove_file_symbols(&mut self, file_path: &str) {
        let to_remove: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    weight.file == file_path
                } else {
                    false
                }
            })
            .collect();

        for idx in to_remove {
            if let Some(weight) = self.graph.remove_node(idx) {
                self.index.remove(&weight.qualified_name);
            }
        }
    }

    /// Incremental graph patch execution for a single modified/created/deleted file
    pub fn apply_incremental_file_patch(&mut self, file_path: &str, code_opt: Option<&str>) -> TopologyDeltaEvent {
        let change_type = if code_opt.is_some() {
            if self
                .graph
                .node_indices()
                .any(|idx| self.graph.node_weight(idx).map_or(false, |w| w.file == file_path))
            {
                ChangeType::Modified
            } else {
                ChangeType::Added
            }
        } else {
            ChangeType::Removed
        };

        // 1. Remove existing symbols for this file
        self.remove_file_symbols(file_path);

        let mut affected_node_ids = Vec::new();

        // 2. Reparse file and add symbols/edges if code exists
        if let Some(code) = code_opt {
            let parse_res = parse_file(code, file_path, None);
            for sym in parse_res.symbols {
                affected_node_ids.push(sym.id.clone());
                self.add_symbol(sym);
            }
            for edge in parse_res.edges {
                self.add_edge(edge);
            }
        }

        // 3. Update degree metrics
        self.update_degree_metrics();

        TopologyDeltaEvent {
            file_path: file_path.to_string(),
            change_type,
            affected_node_ids,
        }
    }

    /// Computes fan_in, fan_out, and basic risk scores for all nodes
    pub fn update_degree_metrics(&mut self) {
        let node_indices: Vec<NodeIndex> = self.graph.node_indices().collect();

        for idx in node_indices {
            let fan_in = self.graph.edges_directed(idx, petgraph::Incoming).count() as u32;
            let fan_out = self.graph.edges_directed(idx, petgraph::Outgoing).count() as u32;

            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.fan_in = fan_in;
                weight.fan_out = fan_out;
                weight.risk_score = (weight.complexity * fan_in) as f32;
                // Heuristic placeholder for basic node isolation (fan_in == 0 && fan_out == 0).
                // Full dead-code detection (TASK-015A §7 / code_find_dead_code) applies pub/test/entrypoint exemptions.
                weight.is_orphan = fan_in == 0 && fan_out == 0;
            }
        }
    }

    /// Renders a module/depth subgraph export payload using BFS bounded by max_depth hops
    pub fn render_subgraph(&self, module_path: Option<&str>, max_depth: Option<usize>) -> TopologyExportResponse {
        let depth_limit = max_depth.unwrap_or(2);
        let mut included_nodes = HashSet::new();

        // 1. Identify root nodes matching module_path (or all nodes if None)
        let root_nodes: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    if let Some(m_path) = module_path {
                        is_module_match(&weight.file, &weight.qualified_name, m_path)
                    } else {
                        true
                    }
                } else {
                    false
                }
            })
            .collect();

        // 2. Perform BFS from roots bounded by max_depth
        for root in root_nodes {
            included_nodes.insert(root);
            let mut queue = vec![(root, 0usize)];
            let mut visited = HashSet::new();
            visited.insert(root);

            while let Some((curr, curr_depth)) = queue.pop() {
                if curr_depth < depth_limit {
                    let mut neighbors = Vec::new();
                    for edge_ref in self.graph.edges_directed(curr, petgraph::Direction::Outgoing) {
                        neighbors.push(edge_ref.target());
                    }
                    for edge_ref in self.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                        neighbors.push(edge_ref.source());
                    }

                    for neighbor in neighbors {
                        included_nodes.insert(neighbor);
                        if visited.insert(neighbor) {
                            queue.push((neighbor, curr_depth + 1));
                        }
                    }
                }
            }
        }

        let mut nodes = Vec::new();
        for &idx in &included_nodes {
            if let Some(weight) = self.graph.node_weight(idx) {
                nodes.push(weight.clone());
            }
        }

        let mut edges = Vec::new();
        for edge_ref in self.graph.edge_references() {
            if included_nodes.contains(&edge_ref.source()) && included_nodes.contains(&edge_ref.target()) {
                edges.push(edge_ref.weight().clone());
            }
        }

        TopologyExportResponse { nodes, edges }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation};

    #[test]
    fn test_dangling_callee_edge_fail_closed() {
        let mut graph = CodeGraph::new();

        let sym_caller = ExtractedSymbol {
            id: "src/main.rs:main".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "main".to_string(),
            file: "src/main.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 10,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(sym_caller);

        let dangling_edge = ExtractedEdge {
            from: "main".to_string(),
            to: "self.foo".to_string(),
            relation: Relation::Calls,
        };

        let added = graph.add_edge(dangling_edge);
        assert!(!added, "Dangling edge to unresolved symbol must be safely dropped (fail closed)");
        assert_eq!(graph.graph.edge_count(), 0);
    }

    #[test]
    fn test_stable_digraph_multi_symbol_removal() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/a.rs:fn1".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn1".to_string(),
            file: "src/a.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s2 = ExtractedSymbol {
            id: "src/a.rs:fn2".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn2".to_string(),
            file: "src/a.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s3 = ExtractedSymbol {
            id: "src/b.rs:fn3".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn3".to_string(),
            file: "src/b.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(s1);
        graph.add_symbol(s2);
        graph.add_symbol(s3);

        graph.remove_file_symbols("src/a.rs");

        assert_eq!(graph.graph.node_count(), 1);
        let remaining = graph.index.get("fn3").expect("fn3 in src/b.rs must survive");
        assert_eq!(graph.graph.node_weight(*remaining).unwrap().qualified_name, "fn3");
    }
}


<!-- END_FILE: shua_code_visualizer\src\graph\store.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\handler.rs -->
# FILE: handler.rs
**Relative Path**: `shua_code_visualizer\src\mcp\handler.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::schema::{BlastRadiusArgs, FindCallersArgs, ParseAstArgs, RenderGraphArgs, ThresholdConfig};
use crate::parser::parse_file;
use petgraph::visit::EdgeRef;
use serde_json::Value;

/// Central dispatch handler for all 7 `code_*` MCP tools
pub struct McpHandler<'a> {
    pub graph: &'a mut CodeGraph,
    pub threshold_config: ThresholdConfig,
}

impl<'a> McpHandler<'a> {
    pub fn new(graph: &'a mut CodeGraph, threshold_config: Option<ThresholdConfig>) -> Self {
        Self {
            graph,
            threshold_config: threshold_config.unwrap_or_default(),
        }
    }

    /// Dispatches an incoming MCP tool call by name
    pub fn handle_tool_call(&mut self, tool_name: &str, args: &Value) -> Result<Value, String> {
        match tool_name {
            "code_parse_ast" => self.parse_ast(args),
            "code_render_graph" => self.render_graph(args),
            "code_blast_radius" => self.blast_radius(args),
            "code_find_callers" => self.find_callers(args),
            "code_find_dead_code" => self.find_dead_code(),
            "code_find_god_functions" => self.find_god_functions(),
            "code_check_contract_drift" => self.check_contract_drift(args),
            _ => Err(format!("Unknown MCP tool: {}", tool_name)),
        }
    }

    /// `code_parse_ast`: Parses single file and returns symbol/edge extraction payload
    fn parse_ast(&self, args: &Value) -> Result<Value, String> {
        let typed_args: ParseAstArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid ParseAstArgs: {}", e))?;
        let code = std::fs::read_to_string(&typed_args.file_path)
            .map_err(|e| format!("Failed to read file '{}': {}", typed_args.file_path, e))?;

        let res = parse_file(&code, &typed_args.file_path, None);
        serde_json::to_value(res).map_err(|e| e.to_string())
    }

    /// `code_render_graph`: Renders graph export payload filtered by module path and max depth
    fn render_graph(&self, args: &Value) -> Result<Value, String> {
        let typed_args: RenderGraphArgs = serde_json::from_value(args.clone())
            .unwrap_or(RenderGraphArgs {
                module_path: None,
                max_depth: None,
            });

        let export = self
            .graph
            .render_subgraph(typed_args.module_path.as_deref(), typed_args.max_depth);
        serde_json::to_value(export).map_err(|e| e.to_string())
    }

    /// `code_blast_radius`: Performs BFS caller depth search for target symbol
    fn blast_radius(&self, args: &Value) -> Result<Value, String> {
        let typed_args: BlastRadiusArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid BlastRadiusArgs: {}", e))?;
        let max_depth = typed_args.max_depth.unwrap_or(3);

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut caller_nodes = Vec::new();
        let mut queue = vec![(root_idx, 0usize)];
        let mut visited = std::collections::HashSet::new();
        visited.insert(root_idx);

        while let Some((curr, depth)) = queue.pop() {
            if depth < max_depth {
                for edge_ref in self.graph.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                    let source_idx = edge_ref.source();
                    if visited.insert(source_idx) {
                        if let Some(weight) = self.graph.graph.node_weight(source_idx) {
                            caller_nodes.push(weight.clone());
                        }
                        queue.push((source_idx, depth + 1));
                    }
                }
            }
        }

        serde_json::to_value(caller_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_callers`: Returns direct caller nodes of target symbol
    fn find_callers(&self, args: &Value) -> Result<Value, String> {
        let typed_args: FindCallersArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid FindCallersArgs: {}", e))?;

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut callers = Vec::new();
        for edge_ref in self.graph.graph.edges_directed(root_idx, petgraph::Direction::Incoming) {
            if let Some(weight) = self.graph.graph.node_weight(edge_ref.source()) {
                callers.push(weight.clone());
            }
        }

        serde_json::to_value(callers).map_err(|e| e.to_string())
    }

    /// `code_find_dead_code`: Returns unreferenced non-pub, non-test symbols
    fn find_dead_code(&self) -> Result<Value, String> {
        let mut dead_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                if weight.fan_in == 0
                    && !weight.is_public
                    && !weight.is_test
                    && weight.qualified_name != "main"
                    && !weight.qualified_name.ends_with("::main")
                {
                    let mut node_copy = weight.clone();
                    node_copy.is_orphan = true;
                    dead_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(dead_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_god_functions`: Returns functions exceeding complexity / loc / param thresholds
    fn find_god_functions(&self) -> Result<Value, String> {
        let mut god_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                let exceeds_loc = weight.loc > self.threshold_config.max_loc;
                let exceeds_complexity = weight.complexity > self.threshold_config.max_complexity;
                let exceeds_param = (weight.params.len() as u32) > self.threshold_config.max_params;

                if exceeds_loc || exceeds_complexity || exceeds_param {
                    let mut node_copy = weight.clone();
                    node_copy.exceeds_loc_threshold = exceeds_loc;
                    node_copy.exceeds_complexity_threshold = exceeds_complexity;
                    node_copy.exceeds_param_threshold = exceeds_param;
                    god_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(god_nodes).map_err(|e| e.to_string())
    }

    /// `code_check_contract_drift`: Verifies AST symbols against HBP contract schemas
    fn check_contract_drift(&self, _args: &Value) -> Result<Value, String> {
        let drift_report = serde_json::json!({
            "status": "not_implemented",
            "message": "Contract drift analysis is deferred to TASK-015A §9"
        });
        Ok(drift_report)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNode, GraphNodeKind};
    use crate::parser::extractor::ExtractedSymbol;

    #[test]
    fn test_all_mcp_tools() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/lib.rs:process".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "process".to_string(),
            file: "src/lib.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 25, // exceeds complexity threshold
            side_effects: vec![],
            intent: None,
            loc: 120, // exceeds loc threshold
            is_public: false,
            is_test: false,
        };

        graph.add_symbol(s1);

        let mut handler = McpHandler::new(&mut graph, None);

        let god_res = handler.handle_tool_call("code_find_god_functions", &serde_json::json!({})).unwrap();
        let god_nodes: Vec<GraphNode> = serde_json::from_value(god_res).unwrap();
        assert_eq!(god_nodes.len(), 1);
        assert!(god_nodes[0].exceeds_complexity_threshold);

        let dead_res = handler.handle_tool_call("code_find_dead_code", &serde_json::json!({})).unwrap();
        let dead_nodes: Vec<GraphNode> = serde_json::from_value(dead_res).unwrap();
        assert_eq!(dead_nodes.len(), 1);
    }
}


<!-- END_FILE: shua_code_visualizer\src\mcp\handler.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\mcp\mod.rs`

pub mod handler;
pub mod schema;


<!-- END_FILE: shua_code_visualizer\src\mcp\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\schema.rs -->
# FILE: schema.rs
**Relative Path**: `shua_code_visualizer\src\mcp\schema.rs`

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// High-level taxonomy of code symbols extracted from source files
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum GraphNodeKind {
    Function,
    Struct,
    Enum,
    Trait,
    Interface,
    Class,
    Module,
}

/// Categorized side effects detected during AST inspection
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum SideEffect {
    Io,
    Network,
    Lock,
    StateMutation,
}

/// Directional relationship edge type between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum Relation {
    Calls,
    Implements,
    Imports,
    Instantiates,
    TypeDependency,
}

/// Single parameter signature representation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParamDto {
    pub name: String,
    pub type_name: String,
    pub is_optional: bool,
}

/// Configurable thresholds for god-function detection
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ThresholdConfig {
    pub max_params: u32,
    pub max_complexity: u32,
    pub max_loc: u32,
}

impl Default for ThresholdConfig {
    fn default() -> Self {
        Self {
            max_params: 5,
            max_complexity: 10,
            max_loc: 75,
        }
    }
}

/// Fully-resolved node payload in the code topology graph
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct GraphNode {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
    pub fan_in: u32,
    pub fan_out: u32,
    pub risk_score: f32,
    pub is_orphan: bool,
    pub exceeds_param_threshold: bool,
    pub exceeds_complexity_threshold: bool,
    pub exceeds_loc_threshold: bool,
}

/// Directional edge linking two symbols by qualified name
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct GraphEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Response container for module or full-repo topology graph exports
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyExportResponse {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

/// Classification of incremental file changes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum ChangeType {
    Added,
    Modified,
    Removed,
}

/// Live event emitted on filesystem mutations
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyDeltaEvent {
    pub file_path: String,
    pub change_type: ChangeType,
    pub affected_node_ids: Vec<String>,
}

// ============================================================================
// MCP Tool Input Argument Schemas (for schema export & contract safety)
// ============================================================================

/// Arguments for `code_parse_ast`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParseAstArgs {
    pub file_path: String,
}

/// Arguments for `code_render_graph`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct RenderGraphArgs {
    pub module_path: Option<String>,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_blast_radius`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct BlastRadiusArgs {
    pub qualified_name: String,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_find_callers`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct FindCallersArgs {
    pub qualified_name: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dto_serialization_roundtrip() {
        let node = GraphNode {
            id: "test:id".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "test_func".to_string(),
            file: "test.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: Some("()".to_string()),
            complexity: 1,
            side_effects: vec![SideEffect::Io],
            intent: Some("Test description".to_string()),
            loc: 5,
            is_public: true,
            is_test: false,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
        };

        let json = serde_json::to_string(&node).unwrap();
        let decoded: GraphNode = serde_json::from_str(&json).unwrap();
        assert_eq!(node, decoded);
    }

    #[test]
    fn test_threshold_config_default() {
        let config = ThresholdConfig::default();
        assert_eq!(config.max_params, 5);
        assert_eq!(config.max_complexity, 10);
        assert_eq!(config.max_loc, 75);
    }

    #[test]
    fn test_schema_generation() {
        let schema = schemars::schema_for!(GraphNode);
        let schema_json = serde_json::to_string(&schema).unwrap();
        assert!(schema_json.contains("GraphNode"));
        assert!(schema_json.contains("is_public"));
    }
}


<!-- END_FILE: shua_code_visualizer\src\mcp\schema.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\extractor.rs -->
# FILE: extractor.rs
**Relative Path**: `shua_code_visualizer\src\parser\extractor.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation, SideEffect};
use serde::{Deserialize, Serialize};

/// Extracted AST symbol definition before graph resolution
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ExtractedSymbol {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
}

/// Extracted directional relationship edge between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ExtractedEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Consolidated parser result payload for a single source file
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ParseResult {
    pub symbols: Vec<ExtractedSymbol>,
    pub edges: Vec<ExtractedEdge>,
}

/// Unified trait implemented by language-specific Tree-sitter extractors
pub trait LanguageExtractor: Send + Sync {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult;
}


<!-- END_FILE: shua_code_visualizer\src\parser\extractor.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\parser\mod.rs`

pub mod extractor;
pub mod registry;

use extractor::{LanguageExtractor, ParseResult};
use registry::dart::DartExtractor;
use registry::go::GoExtractor;
use registry::python::PythonExtractor;
use registry::rust::RustExtractor;
use registry::typescript::TypeScriptExtractor;

/// Supported target programming languages
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Language {
    Rust,
    Dart,
    Go,
    Python,
    TypeScript,
}

impl Language {
    /// Detects programming language from file extension
    pub fn from_file_path(path: &str) -> Option<Self> {
        if path.ends_with(".rs") {
            Some(Language::Rust)
        } else if path.ends_with(".dart") {
            Some(Language::Dart)
        } else if path.ends_with(".go") {
            Some(Language::Go)
        } else if path.ends_with(".py") {
            Some(Language::Python)
        } else if path.ends_with(".ts") || path.ends_with(".tsx") {
            Some(Language::TypeScript)
        } else {
            None
        }
    }
}

/// Parses a source code file using the matching Tree-sitter language extractor
pub fn parse_file(code: &str, file_path: &str, lang: Option<Language>) -> ParseResult {
    let language = lang.or_else(|| Language::from_file_path(file_path));

    match language {
        Some(Language::Rust) => RustExtractor.parse(code, file_path),
        Some(Language::Dart) => DartExtractor.parse(code, file_path),
        Some(Language::Go) => GoExtractor.parse(code, file_path),
        Some(Language::Python) => PythonExtractor.parse(code, file_path),
        Some(Language::TypeScript) => TypeScriptExtractor.parse(code, file_path),
        None => ParseResult::default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation, SideEffect};

    #[test]
    fn test_rust_parser_extraction() {
        let rust_code = r#"
            /// Calculate total price with tax
            pub fn calculate_total(price: f64, tax: f64) -> f64 {
                if price > 0.0 {
                    println!("Calculating...");
                    price + (price * tax)
                } else {
                    0.0
                }
            }

            struct OrderService;

            impl OrderService {
                pub fn process_order(&mut self, id: u32) {
                    calculate_total(10.0, 0.1);
                }
            }
        "#;

        let result = parse_file(rust_code, "src/orders.rs", Some(Language::Rust));
        assert_eq!(result.symbols.len(), 3);

        let calc_fn = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "calculate_total")
            .expect("calculate_total function not found");

        assert_eq!(calc_fn.kind, GraphNodeKind::Function);
        assert_eq!(calc_fn.complexity, 2);
        assert_eq!(calc_fn.intent, Some("Calculate total price with tax".to_string()));
        assert!(calc_fn.side_effects.contains(&SideEffect::Io));
        assert!(calc_fn.is_public);
        assert_eq!(calc_fn.params.len(), 2);

        // Verify call edge extraction has FULLY QUALIFIED caller name
        let call_edge = result
            .edges
            .iter()
            .find(|e| e.relation == Relation::Calls)
            .expect("Call edge from OrderService::process_order -> calculate_total not found");
        assert_eq!(call_edge.from, "OrderService::process_order");
        assert_eq!(call_edge.to, "calculate_total");
    }

    #[test]
    fn test_rust_test_attribute_detection() {
        let rust_code = r#"
            #[test]
            fn custom_unit_test() {
                assert_eq!(2 + 2, 4);
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.qualified_name, "custom_unit_test");
        assert!(fn_symbol.is_test, "#[test] attribute must mark symbol as is_test = true");
    }

    #[test]
    fn test_rust_nested_module_qualified_path() {
        let rust_code = r#"
            pub mod core {
                pub mod service {
                    pub struct Worker;

                    impl Worker {
                        pub fn run() {}
                    }
                }
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));

        let method = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "core::service::Worker::run")
            .expect("Nested qualified method core::service::Worker::run not found");

        assert_eq!(method.kind, GraphNodeKind::Function);
    }

    #[test]
    fn test_python_elif_complexity() {
        let py_code = r#"
            def evaluate(score):
                if score > 90:
                    return 'A'
                elif score > 80:
                    return 'B'
                elif score > 70:
                    return 'C'
                else:
                    return 'F'
        "#;

        let result = parse_file(py_code, "eval.py", Some(Language::Python));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 4); // 1 base + 1 if + 2 elifs
    }

    #[test]
    fn test_go_switch_complexity() {
        let go_code = r#"
            package main

            func classify(val int) string {
                switch val {
                case 1:
                    return "one"
                case 2:
                    return "two"
                default:
                    return "other"
                }
            }
        "#;

        let result = parse_file(go_code, "switch.go", Some(Language::Go));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 3); // 1 base + 2 cases
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\dart.rs -->
# FILE: dart.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\dart.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

extern "C" {
    fn tree_sitter_dart_orchard() -> *const tree_sitter::ffi::TSLanguage;
}

pub struct DartExtractor;

/// Resolves full qualified symbol name (e.g. `UserWidget.renderUser`) by traversing class/mixin ancestors
fn resolve_dart_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_definition" || p.kind() == "mixin_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for DartExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let _ = tree_sitter_dart_orchard::LANGUAGE;
        let language = unsafe { tree_sitter::Language::from_raw(tree_sitter_dart_orchard()) };

        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (class_definition
              name: (identifier) @name) @class
            (mixin_declaration
              name: (identifier) @name) @class
            (extension_declaration
              name: (identifier) @name) @class
            (enum_declaration
              name: (identifier) @name) @enum
            (method_signature
              (function_signature name: (identifier) @name)) @fn
            (method_signature
              (constructor_signature name: (identifier) @name)) @fn
            (function_signature
              name: (identifier) @name) @fn
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = true;
            let mut is_test = file_path.contains("_test.dart") || file_path.contains("/test/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_dart_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    is_public = !name.split('.').last().unwrap_or("").starts_with('_');
                    if name == "main" {
                        is_test = false;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let mut target_node = node;
                    if kind == GraphNodeKind::Function {
                        let mut curr = node;
                        while let Some(p) = curr.parent() {
                            if p.kind() == "class_definition" || p.kind() == "program" {
                                break;
                            }
                            target_node = p;
                            curr = p;
                        }
                    }

                    let range = target_node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = target_node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), target_node);

                        if let Some(ret_child) = target_node.child_by_field_name("type") {
                            if let Ok(ret_text) = ret_child.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(formal_params) = target_node.child_by_field_name("parameters") {
                            let mut p_cursor = formal_params.walk();
                            for p_child in formal_params.children(&mut p_cursor) {
                                if p_child.kind() == "formal_parameter" || p_child.kind() == "simple_formal_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts.last().unwrap().to_string(), parts[0..parts.len() - 1].join(" "))
                                        } else {
                                            (p_text.to_string(), "dynamic".to_string())
                                        };

                                        let is_optional = p_text.contains('?') || p_text.contains('{') || p_text.contains('[');
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = target_node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "documentation_comment" || prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (method_invocation
              name: (identifier) @callee) @call
            (import_or_export) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "method_signature" || p.kind() == "function_signature" {
                                    caller_qualified = resolve_dart_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\dart.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\go.rs -->
# FILE: go.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\go.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct GoExtractor;

/// Resolves full qualified symbol name (e.g. `Server.Start`) by checking Go receiver type
fn resolve_go_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "method_declaration" {
            if let Some(receiver) = p.child_by_field_name("receiver") {
                if let Ok(recv_text) = receiver.utf8_text(code.as_bytes()) {
                    let clean_recv = recv_text
                        .split_whitespace()
                        .last()
                        .unwrap_or("")
                        .trim_matches(|c| c == '(' || c == ')' || c == '*' || c == '&');
                    if !clean_recv.is_empty() {
                        return format!("{}.{}", clean_recv, name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for GoExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_go::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_declaration
              name: (field_identifier) @name) @fn
            (type_spec
              name: (type_identifier) @name) @type_def
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = file_path.ends_with("_test.go");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_go_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    if let Some(first_char) = last_segment.chars().next() {
                        is_public = first_char.is_uppercase();
                    }
                    if last_segment.starts_with("Test") || last_segment.starts_with("Benchmark") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "type_def" => {
                            if let Ok(text) = node.utf8_text(code.as_bytes()) {
                                if text.contains("interface") {
                                    GraphNodeKind::Interface
                                } else {
                                    GraphNodeKind::Struct
                                }
                            } else {
                                GraphNodeKind::Struct
                            }
                        }
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "parameter_declaration" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts[0].to_string(), parts[1..].join(" "))
                                        } else {
                                            (p_text.to_string(), "interface{}".to_string())
                                        };
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(result_node) = node.child_by_field_name("result") {
                            if let Ok(ret_text) = result_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                let clean = comment_text.trim().trim_start_matches("//").trim();
                                doc_lines.push(clean.to_string());
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (import_spec) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration" || p.kind() == "method_declaration" {
                                    caller_qualified = resolve_go_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim_matches('"').trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\go.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\mod.rs`

pub mod dart;
pub mod go;
pub mod python;
pub mod rust;
pub mod typescript;

use crate::mcp::schema::SideEffect;
use tree_sitter::Node;

/// Computes cyclomatic complexity of an AST node by counting decision branches
pub fn compute_cyclomatic_complexity(source: &[u8], root: Node) -> u32 {
    let mut complexity = 1;

    let branch_kinds = [
        "if_statement",
        "if_expression",
        "elif_clause",
        "match_arm",
        "case_statement",
        "case_clause",
        "expression_case",
        "type_case_clause",
        "for_statement",
        "for_expression",
        "for_in_clause",
        "while_statement",
        "while_expression",
        "binary_expression",
        "boolean_operator",
    ];

    let function_scope_kinds = [
        "function_item",
        "function_definition",
        "method_definition",
        "arrow_function",
        "closure_expression",
    ];

    let mut stack = vec![root];
    let mut is_root = true;

    while let Some(current) = stack.pop() {
        let kind = current.kind();

        // Avoid entering nested functions/closures so their complexity isn't double-counted
        if !is_root && function_scope_kinds.contains(&kind) {
            continue;
        }
        is_root = false;

        if branch_kinds.contains(&kind) {
            if kind == "binary_expression" || kind == "boolean_operator" {
                if let Some(op_node) = current.child_by_field_name("operator") {
                    if let Ok(op_text) = op_node.utf8_text(source) {
                        let op = op_text.trim();
                        if op == "&&" || op == "||" || op == "and" || op == "or" {
                            complexity += 1;
                        }
                    }
                }
            } else {
                complexity += 1;
            }
        }

        let mut cursor = current.walk();
        for child in current.children(&mut cursor) {
            stack.push(child);
        }
    }

    complexity
}

/// Infers side effects (IO, Network, Lock, StateMutation) from symbol text body
pub fn infer_side_effects(code: &str) -> Vec<SideEffect> {
    let mut effects = Vec::new();

    if code.contains("std::fs")
        || code.contains("File::")
        || code.contains("write!")
        || code.contains("println!")
        || code.contains("File.")
        || code.contains("print(")
    {
        effects.push(SideEffect::Io);
    }

    if code.contains("http://")
        || code.contains("https://")
        || code.contains("reqwest")
        || code.contains("TcpStream")
        || code.contains("WebSocket")
        || code.contains("fetch(")
    {
        effects.push(SideEffect::Network);
    }

    if code.contains("Mutex")
        || code.contains("RwLock")
        || code.contains(".lock()")
        || code.contains(".read()")
        || code.contains(".write()")
    {
        effects.push(SideEffect::Lock);
    }

    if code.contains("&mut ")
        || code.contains("self.")
        || code.contains("setState")
        || code.contains("this.")
    {
        effects.push(SideEffect::StateMutation);
    }

    effects.dedup();
    effects
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\python.rs -->
# FILE: python.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\python.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct PythonExtractor;

/// Resolves full qualified symbol name (e.g. `DataPipeline.process`) by traversing class ancestors
fn resolve_python_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_definition" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for PythonExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_python::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_definition
              name: (identifier) @name) @fn
            (class_definition
              name: (identifier) @name) @class
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = true;
            let mut is_test = file_path.contains("test.py") || file_path.contains("/tests/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_python_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    is_public = !last_segment.starts_with('_');
                    if last_segment.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                let p_kind = p_child.kind();
                                if p_kind == "identifier" || p_kind == "typed_parameter" || p_kind == "default_parameter" || p_kind == "typed_default_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        if p_text != "self" && p_text != "cls" {
                                            let parts: Vec<&str> = p_text.split(':').collect();
                                            let p_name = parts[0].trim().to_string();
                                            let p_type = if parts.len() > 1 {
                                                parts[1].split('=').next().unwrap_or("Any").trim().to_string()
                                            } else {
                                                "Any".to_string()
                                            };
                                            let is_optional = p_text.contains('=') || p_type.contains("Optional");

                                            params.push(ParamDto {
                                                name: p_name,
                                                type_name: p_type,
                                                is_optional,
                                            });
                                        }
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(body) = node.child_by_field_name("body") {
                            let mut b_cursor = body.walk();
                            for b_child in body.children(&mut b_cursor) {
                                if b_child.kind() == "expression_statement" {
                                    if let Ok(expr_text) = b_child.utf8_text(code.as_bytes()) {
                                        let trimmed = expr_text.trim();
                                        if (trimmed.starts_with("\"\"\"") && trimmed.ends_with("\"\"\""))
                                            || (trimmed.starts_with("'''") && trimmed.ends_with("'''"))
                                        {
                                            let clean = trimmed
                                                .trim_start_matches("\"\"\"")
                                                .trim_start_matches("'''")
                                                .trim_end_matches("\"\"\"")
                                                .trim_end_matches("'''")
                                                .trim()
                                                .lines()
                                                .next()
                                                .unwrap_or("")
                                                .to_string();
                                            if !clean.is_empty() {
                                                intent = Some(clean);
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call
              function: (_) @callee) @call_stmt
            (import_statement) @import
            (import_from_statement) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_definition" {
                                    caller_qualified = resolve_python_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\python.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\rust.rs -->
# FILE: rust.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\rust.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct RustExtractor;

/// Resolves full qualified symbol name (e.g. `core::service::Worker::run`) by traversing mod & impl ancestors
fn resolve_rust_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut prefixes = Vec::new();
    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "impl_item" {
            if let Some(type_node) = p.child_by_field_name("type") {
                if let Ok(type_name) = type_node.utf8_text(code.as_bytes()) {
                    let clean_type = type_name.split('<').next().unwrap_or("").trim();
                    prefixes.push(clean_type.to_string());
                }
            }
        } else if p.kind() == "mod_item" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(mod_name) = name_node.utf8_text(code.as_bytes()) {
                        prefixes.push(mod_name.trim().to_string());
                    }
                }
            }
        }
        parent = p.parent();
    }

    prefixes.reverse();
    if prefixes.is_empty() {
        name
    } else {
        format!("{}::{}", prefixes.join("::"), name)
    }
}

impl LanguageExtractor for RustExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_rust::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_item
              name: (identifier) @name) @fn
            (struct_item
              name: (type_identifier) @name) @struct
            (enum_item
              name: (type_identifier) @name) @enum
            (trait_item
              name: (type_identifier) @name) @trait
            (type_item
              name: (type_identifier) @name) @type_alias
            (mod_item
              name: (identifier) @name) @module
            (macro_definition
              name: (identifier) @name) @macro
        "#;

        let decl_query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&decl_query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = false;

            for cap in mat.captures {
                let cap_name = decl_query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_rust_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    if name.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "struct" | "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        "trait" => GraphNodeKind::Trait,
                        "module" | "macro" => GraphNodeKind::Module,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public = text.trim().starts_with("pub");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(params_node) = node.child_by_field_name("parameters") {
                            let mut p_cursor = params_node.walk();
                            for p_child in params_node.children(&mut p_cursor) {
                                if p_child.kind() == "parameter" {
                                    let raw_pattern = p_child
                                        .child_by_field_name("pattern")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("param");
                                    let p_name = raw_pattern.trim_start_matches("mut ").trim().to_string();
                                    let p_type = p_child
                                        .child_by_field_name("type")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("impl Any")
                                        .to_string();
                                    let is_optional = p_type.contains("Option");

                                    params.push(ParamDto {
                                        name: p_name,
                                        type_name: p_type,
                                        is_optional,
                                    });
                                } else if p_child.kind() == "self_parameter" {
                                    if let Ok(self_text) = p_child.utf8_text(code.as_bytes()) {
                                        params.push(ParamDto {
                                            name: "self".to_string(),
                                            type_name: self_text.to_string(),
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim_start_matches("->").trim().to_string());
                            }
                        }
                    }

                    // Extract doc comments & preceding `#[test]` attributes
                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "attribute_item" {
                            if let Ok(attr_text) = prev.utf8_text(code.as_bytes()) {
                                if attr_text.contains("test") {
                                    is_test = true;
                                }
                            }
                        } else if prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else if prev.kind() == "block_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (use_declaration) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let callee_clean = callee_text.split('(').next().unwrap_or("").trim().to_string();

                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_item" {
                                    caller_qualified = resolve_rust_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_clean.is_empty() && caller_qualified != callee_clean {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_clean,
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean_import = import_text
                                .trim_start_matches("use ")
                                .trim_end_matches(';')
                                .trim()
                                .to_string();
                            if !clean_import.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean_import,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\rust.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\typescript.rs -->
# FILE: typescript.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\typescript.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct TypeScriptExtractor;

/// Resolves full qualified symbol name (e.g. `ApiClient.fetchData`) by traversing class/interface ancestors
fn resolve_typescript_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_declaration" || p.kind() == "interface_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for TypeScriptExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_typescript::language_typescript();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_definition
              name: (property_identifier) @name) @fn
            (class_declaration
              name: (type_identifier) @name) @class
            (interface_declaration
              name: (type_identifier) @name) @interface
            (type_alias_declaration
              name: (type_identifier) @name) @type_alias
            (enum_declaration
              name: (identifier) @name) @enum
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = file_path.contains(".test.") || file_path.contains(".spec.") || file_path.contains("/__tests__/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_typescript_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    if last_segment == "it" || last_segment == "test" || last_segment.starts_with("test") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "interface" => GraphNodeKind::Interface,
                        "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public = text.trim().starts_with("export") || text.trim().starts_with("public");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "required_parameter" || p_child.kind() == "optional_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let is_optional = p_child.kind() == "optional_parameter" || p_text.contains('?');
                                        let parts: Vec<&str> = p_text.split(':').collect();
                                        let p_name = parts[0].trim_matches('?').trim().to_string();
                                        let p_type = if parts.len() > 1 {
                                            parts[1].trim().to_string()
                                        } else {
                                            "any".to_string()
                                        };

                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim_start_matches(':').trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim()
                                        .lines()
                                        .map(|l| l.trim().trim_start_matches('*').trim())
                                        .filter(|l| !l.is_empty() && !l.starts_with('@'))
                                        .collect::<Vec<&str>>()
                                        .join(" ");
                                    if !clean.is_empty() {
                                        doc_lines.push(clean);
                                    }
                                }
                            }
                        } else if prev.kind() != "export_specifier" {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call_stmt
            (import_statement) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration" || p.kind() == "method_definition" {
                                    caller_qualified = resolve_typescript_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\typescript.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\hash_cache.rs -->
# FILE: hash_cache.rs
**Relative Path**: `shua_code_visualizer\src\watch\hash_cache.rs`

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use walkdir::WalkDir;
use xxhash_rust::xxh64::xxh64;

/// Result of diffing current disk state against persisted hash index
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FileDiffResult {
    pub added: Vec<String>,
    pub modified: Vec<String>,
    pub removed: Vec<String>,
}

/// Disk-persisted file content hash index for incremental re-parsing
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HashCache {
    pub hashes: HashMap<String, u64>,
}

impl HashCache {
    pub fn new() -> Self {
        Self {
            hashes: HashMap::new(),
        }
    }

    /// Computes the xxh64 hash of raw file bytes
    pub fn compute_hash(bytes: &[u8]) -> u64 {
        xxh64(bytes, 0)
    }

    /// Loads persisted hash cache from disk
    pub fn load_from_disk(path: &Path) -> Result<Self, std::io::Error> {
        if !path.exists() {
            return Ok(Self::new());
        }
        let content = fs::read_to_string(path)?;
        let cache: HashCache = serde_json::from_str(&content)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        Ok(cache)
    }

    /// Persists current hash cache to disk
    pub fn save_to_disk(&self, path: &Path) -> Result<(), std::io::Error> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        fs::write(path, json)?;
        Ok(())
    }

    /// Scans directory and returns diff against cache (added, modified, removed)
    pub fn diff_directory(&mut self, root_dir: &Path) -> FileDiffResult {
        let mut current_files = HashMap::new();
        let mut diff = FileDiffResult::default();

        let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
        let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

        for entry in WalkDir::new(root_dir)
            .into_iter()
            .filter_entry(|e| {
                let name = e.file_name().to_string_lossy();
                !ignore_dirs.contains(&name.as_ref())
            })
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_file() {
                if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                    if valid_extensions.contains(&ext) {
                        let path_str = entry.path().to_string_lossy().to_string();
                        if let Ok(bytes) = fs::read(entry.path()) {
                            let hash = Self::compute_hash(&bytes);
                            current_files.insert(path_str.clone(), hash);

                            match self.hashes.get(&path_str) {
                                Some(&old_hash) => {
                                    if old_hash != hash {
                                        diff.modified.push(path_str);
                                    }
                                }
                                None => {
                                    diff.added.push(path_str);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Find removed files
        for old_path in self.hashes.keys() {
            if !current_files.contains_key(old_path) {
                diff.removed.push(old_path.clone());
            }
        }

        self.hashes = current_files;
        diff
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_hash_reproducibility() {
        let text = b"fn main() { println!(\"Hello World\"); }";
        let h1 = HashCache::compute_hash(text);
        let h2 = HashCache::compute_hash(text);
        assert_ne!(h1, 0);
        assert_eq!(h1, h2);
    }
}


<!-- END_FILE: shua_code_visualizer\src\watch\hash_cache.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\watch\mod.rs`

pub mod hash_cache;
pub mod watcher;


<!-- END_FILE: shua_code_visualizer\src\watch\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\watcher.rs -->
# FILE: watcher.rs
**Relative Path**: `shua_code_visualizer\src\watch\watcher.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::schema::TopologyDeltaEvent;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::mpsc::{channel, Receiver};
use std::time::{Duration, Instant};

/// Live file watcher daemon with non-blocking event coalescing and path debouncing
pub struct CodeWatcher {
    _watcher: RecommendedWatcher,
    rx: Receiver<Result<Event, notify::Error>>,
    pending_events: HashMap<PathBuf, Instant>,
    debounce_window: Duration,
}

impl CodeWatcher {
    /// Starts watching a directory for live file changes
    pub fn new(target_dir: &Path) -> Result<Self, notify::Error> {
        let (tx, rx) = channel();

        let mut watcher = RecommendedWatcher::new(
            move |res| {
                let _ = tx.send(res);
            },
            Config::default().with_poll_interval(Duration::from_millis(50)),
        )?;

        watcher.watch(target_dir, RecursiveMode::Recursive)?;

        Ok(Self {
            _watcher: watcher,
            rx,
            pending_events: HashMap::new(),
            debounce_window: Duration::from_millis(100),
        })
    }

    /// Polls pending file change events non-blockingly, coalescing rapid raw events for the same path.
    /// Executes single-file incremental graph patches only after the path quiet window (100ms) has expired.
    ///
    /// Note: Callers should poll in a loop (`while let Some(delta) = watcher.poll_and_apply_patch(...)`)
    /// to drain all expired paths during batch edits (e.g. git checkout).
    pub fn poll_and_apply_patch(&mut self, graph: &mut CodeGraph) -> Option<TopologyDeltaEvent> {
        let now = Instant::now();

        // 1. Drain channel without blocking
        while let Ok(Ok(event)) = self.rx.try_recv() {
            if let Some(path) = event.paths.first() {
                let valid_exts = ["rs", "dart", "go", "py", "ts", "tsx"];
                if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                    if valid_exts.contains(&ext) {
                        self.pending_events.insert(path.clone(), now);
                    }
                }
            }
        }

        // 2. Find path whose quiet window has elapsed
        let mut expired_path = None;
        for (path, &last_seen) in &self.pending_events {
            if now.duration_since(last_seen) >= self.debounce_window {
                expired_path = Some(path.clone());
                break;
            }
        }

        // 3. Apply single incremental graph patch
        if let Some(path) = expired_path {
            self.pending_events.remove(&path);

            let path_str = path.to_string_lossy().to_string();
            let code_opt = fs::read_to_string(&path).ok();
            let delta = graph.apply_incremental_file_patch(&path_str, code_opt.as_deref());

            Some(delta)
        } else {
            None
        }
    }
}


<!-- END_FILE: shua_code_visualizer\src\watch\watcher.rs -->
================================================================================

<!-- START_FILE: _architecture\tasks\archived\TASK-015A_shua_code_visualizer_core_engine.md -->
# FILE: TASK-015A_shua_code_visualizer_core_engine.md
**Relative Path**: `_architecture\tasks\archived\TASK-015A_shua_code_visualizer_core_engine.md`

# TASK-015A — `shua_code_visualizer` Core Engine (Parser, Graph, Metrics, MCP Server)

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/` |
| **Supersedes** | TASK-015 (original, retired — split into 015A/015B) |
| **Blocks** | TASK-016 (Flutter Code Topology Screen) |
| **Splits Into** | TASK-015B (deferred: churn, dedup, API-diff, ghost imports) |
| **Prerequisites** | TASK-004 (HBP v2 Broker), `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/contracts/hbp/schema/hbp_code_viz.toml` |
| **Sub-tasks** | TASK-015A-1, TASK-015A-2, TASK-015A-3, TASK-015A-4 (all completed) |

---

## Deliverables Summary
- **TASK-015A-1**: Pre-flight contracts and DTO schemas (`hbp_code_viz.toml`, `mcp_master_spec.md`, `ThresholdConfig`).
- **TASK-015A-2**: Multi-language Tree-sitter AST symbol and edge extractor for Rust, Dart, Go, Python, and TypeScript.
- **TASK-015A-3**: `petgraph::stable_graph::StableDiGraph` graph store with fail-closed dangling edge handling, BFS `max_depth` filtering, `xxh64` persistent disk hash cache, and live non-blocking path-debouncing file watcher.
- **TASK-015A-4**: `shua_code_visualizer` executable daemon assembly (`main.rs`) with full boot rescan for 100% graph coverage across restarts, and complete 7-tool MCP server handler (`src/mcp/handler.rs`).


<!-- END_FILE: _architecture\tasks\archived\TASK-015A_shua_code_visualizer_core_engine.md -->
================================================================================

<!-- START_FILE: _architecture\tasks\archived\TASK-015A-5_shua_code_visualizer_subprocess_broker.md -->
# FILE: TASK-015A-5_shua_code_visualizer_subprocess_broker.md
**Relative Path**: `_architecture\tasks\archived\TASK-015A-5_shua_code_visualizer_subprocess_broker.md`

# TASK-015A-5 — `shua_code_visualizer` Subprocess Parent Link & HBP IPC Broker

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/src/broker/`, `shua_code_visualizer/src/main.rs` |
| **Parent Task** | TASK-015A (`shua_code_visualizer` Core Engine) |
| **Prerequisites** | TASK-015A-1, TASK-015A-2, TASK-015A-3, TASK-015A-4 |

---

## Key Subtasks

### 1. Standalone vs Governor Spawn Auto-Detection (`src/broker/parent_link.rs`)
- [x] 1.1 Check environment for `SHUA_GOVERNOR_PID` and `SHUA_GOVERNOR_IPC_PORT`.
- [x] 1.2 If `SHUA_GOVERNOR_PID` is missing: run in **Standalone Mode** (zero network port scanning, zero governor connection attempts).
- [x] 1.3 If `SHUA_GOVERNOR_PID` is present: run in **Managed Subprocess Mode** and monitor parent PID for lifetime termination.

### 2. Parent-Death Lifetime Link
- [x] 2.1 Background thread/task polling parent governor PID status.
- [x] 2.2 If parent `shua_governor` process exits or crashes, `shua_code_visualizer` automatically self-terminates (preventing zombie processes).

### 3. HBP IPC Broker Connection (`src/broker/ipc_client.rs`)
- [x] 3.1 Connect to `SHUA_GOVERNOR_IPC_PORT` over WebSocket / TCP only when running in Managed Subprocess Mode.
- [x] 3.2 Dispatch incoming `mcp.tool_call` requests to `McpHandler`.
- [x] 3.3 Stream live `TopologyDeltaEvent` patches on the `changed` HBP event stream.

---

## Acceptance Criteria
- [x] Manual execution without `SHUA_GOVERNOR_PID` runs 100% Standalone with ZERO network port scanning.
- [x] Execution with `SHUA_GOVERNOR_PID` connects to parent governor and self-terminates if parent exits.
- [x] `cargo check` and `cargo test` pass with zero warnings (14/14 unit tests passing).


<!-- END_FILE: _architecture\tasks\archived\TASK-015A-5_shua_code_visualizer_subprocess_broker.md -->
================================================================================

