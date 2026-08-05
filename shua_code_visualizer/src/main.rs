use clap::Parser;
use schemars::schema_for;
use shua_code_visualizer::broker::ipc_client::IpcClient;
use shua_code_visualizer::broker::parent_link::{ExecutionMode, ParentLink};
use shua_code_visualizer::graph::store::CodeGraph;
use shua_code_visualizer::logging::HbpLogLayer;
use shua_code_visualizer::mcp::schema::{
    BlastRadiusArgs, FindCallersArgs, GraphEdge, GraphNode, ParseAstArgs, ReadFileArgs,
    RenderGraphArgs, TopologyDeltaEvent, TopologyExportResponse,
};
use shua_code_visualizer::parser::parse_file;
use shua_code_visualizer::watch::hash_cache::HashCache;
use shua_code_visualizer::watch::watcher::CodeWatcher;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing_subscriber::prelude::*;
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
    // Initialise tracing subscriber with HbpLogLayer → governor telemetry +
    // fmt layer for stdout visibility via SSH.
    let hbp_layer = HbpLogLayer::new();
    let fmt_layer = tracing_subscriber::fmt::layer()
        .with_target(false)
        .with_level(true)
        .compact();
    tracing_subscriber::registry()
        .with(hbp_layer)
        .with(fmt_layer)
        .init();

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

        println!("\n=== ReadFileArgs Schema ===");
        let schema = schema_for!(ReadFileArgs);
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

    tracing::info!(
        subsystem = "main",
        "============================================================"
    );
    tracing::info!(
        subsystem = "main",
        "  horAIzon 3.0 — shua_code_visualizer daemon starting...  "
    );
    tracing::info!(
        subsystem = "main",
        "============================================================"
    );
    tracing::info!(subsystem = "main", workspace_root = %args.workspace_root.display(), "Workspace root");
    tracing::info!(subsystem = "main", hash_cache = %args.hash_cache.display(), "Hash cache path");

    // 0. Auto-detect runtime execution mode (Standalone vs Managed Subprocess)
    let mode = ParentLink::detect_execution_mode();
    match &mode {
        ExecutionMode::Standalone => {
            tracing::info!(subsystem = "main", "Execution Mode: Standalone (run manually by user). Zero port scanning or governor connection attempts.");
        }
        ExecutionMode::ManagedSubprocess {
            parent_pid,
            ipc_port,
        } => {
            tracing::info!(
                subsystem = "main",
                parent_pid = parent_pid,
                ipc_port = ipc_port,
                "Execution Mode: Managed Subprocess. Lifetime linked to parent governor."
            );
            ParentLink::spawn_parent_death_monitor(*parent_pid);
        }
    }

    // 1. Boot Sequence: Load persistent hash cache from disk & log diff
    let mut cache = HashCache::load_from_disk(&args.hash_cache).unwrap_or_default();

    tracing::info!(
        subsystem = "main",
        "Scanning filesystem for source code changes..."
    );
    let diff = cache.diff_directory(&args.workspace_root);
    tracing::info!(
        subsystem = "main",
        added = diff.added.len(),
        modified = diff.modified.len(),
        removed = diff.removed.len(),
        "Hash index status"
    );

    // 2. Perform complete boot scan of all valid source files
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
        tracing::warn!(subsystem = "main", error = %e, "Failed to save hash cache to disk");
    }

    tracing::info!(
        subsystem = "main",
        nodes = graph.graph.node_count(),
        edges = graph.graph.edge_count(),
        "CodeGraph initialized successfully"
    );

    if let Some(ref graph_out_path) = args.export_graph {
        let export = graph.render_subgraph(None, None);
        let json_text = serde_json::to_string_pretty(&export)?;
        fs::write(graph_out_path, json_text)?;
        tracing::info!(subsystem = "main", path = %graph_out_path.display(), "Topology graph exported successfully");
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
            tracing::info!(
                subsystem = "watcher",
                "Live CodeWatcher daemon started successfully"
            );
            Some(w)
        }
        Err(e) => {
            tracing::warn!(subsystem = "watcher", error = %e, "File watcher failed to start — falling back to read-only query mode");
            None
        }
    };

    tracing::info!(
        subsystem = "main",
        "shua_code_visualizer core engine ready. Entering event loop..."
    );

    // 6. Event loop: poll watcher patches (if active) and service queries
    loop {
        if let Some(ref mut watcher) = watcher_opt {
            let mut g = shared_graph.lock().await;
            while let Some(delta) = watcher.poll_and_apply_patch(&mut g) {
                tracing::info!(
                    subsystem = "watcher",
                    file = %delta.file_path,
                    change = ?delta.change_type,
                    affected_symbols = delta.affected_node_ids.len(),
                    "Incremental patch applied"
                );
                if let Some(ref tx) = delta_tx {
                    let _ = tx.send(delta);
                }
            }
        }

        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    }
}
