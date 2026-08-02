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
