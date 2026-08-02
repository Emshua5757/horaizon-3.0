use lasso::{Rodeo, Spur};
use petgraph::graph::{DiGraph, NodeIndex};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::RwLock;

pub type InternKey = Spur;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum SymbolKind {
    Function,
    Struct,
    Enum,
    Trait,
    Class,
    Interface,
    ExternalBoundary,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum Visibility {
    Public,
    Private,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum DependencyType {
    Imports,
    Instantiates,
    Calls,
    Implements,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum SymbolTag {
    CorePrimitive,
    PotentialDeadCode,
    HighComplexity,
    Cycle,
    ApiRoute,
    TraitMethod,
    EntryPoint,
    FrameworkInvoked,
    SerdeCallback,
    Pure,
    MutatesState,
    Io,
    Async,
    CanPanic,
    Tested,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum Language {
    Rust,
    TypeScript,
    Python,
    Dart,
    Go,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct SymbolNode {
    pub id: InternKey,
    pub name: InternKey,
    pub file: InternKey,
    pub kind: SymbolKind,
    pub line_start: u32,
    pub line_end: u32,
    pub loc: u32,
    pub complexity: u32,
    pub visibility: Visibility,
    pub signature: String,
    pub in_degree: u32,
    pub out_degree: u32,
    pub is_cycle: bool,
    pub tags: Vec<SymbolTag>,
    pub language: Language,
    pub content_hash: u64,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct DependencyEdge {
    pub dep_type: DependencyType,
    pub symbols: Vec<InternKey>,
}

#[derive(Clone, Debug)]
pub struct FileMetadata {
    pub imports: Vec<(PathBuf, Vec<String>)>,
    pub call_sites: Vec<(u32, String)>,
    pub type_references: Vec<(u32, String)>,
    pub summary: String,
}

#[derive(Clone)]
pub struct AppState {
    pub graph: Arc<RwLock<DiGraph<SymbolNode, DependencyEdge>>>,
    pub intern: Arc<RwLock<Rodeo>>,
    pub file_index: Arc<RwLock<HashMap<PathBuf, Vec<NodeIndex>>>>,
    pub file_metadata: Arc<RwLock<HashMap<PathBuf, FileMetadata>>>,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            graph: Arc::new(RwLock::new(DiGraph::new())),
            intern: Arc::new(RwLock::new(Rodeo::new())),
            file_index: Arc::new(RwLock::new(HashMap::new())),
            file_metadata: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Safely upsert all symbols of a file. Clears previous nodes associated with this file,
    /// and handles NodeIndex shifting to prevent petgraph index corruption.
    pub fn upsert_file_symbols(
        &self,
        file_path: PathBuf,
        new_nodes: Vec<SymbolNode>,
        _new_edges: Vec<(SymbolNode, SymbolNode, DependencyEdge)>,
    ) {
        let mut graph = self.graph.write().unwrap();
        let mut file_index = self.file_index.write().unwrap();

        // 1. Remove old nodes associated with this file.
        // Note: petgraph::remove_node shifts the last node of the graph into the deleted node's index.
        // We must update the index references in file_index for any shifted node to prevent index mismatch.
        if let Some(mut old_indices) = file_index.remove(&file_path) {
            old_indices.sort_by(|a, b| b.cmp(a));
            for idx in old_indices {
                // Check if the index is valid in the graph
                if graph.node_weight(idx).is_some() {
                    let last_idx = NodeIndex::new(graph.node_count() - 1);
                    graph.remove_node(idx);

                    // If the removed node was not the last node, the last node was shifted to idx
                    if idx != last_idx {
                        if let Some(_shifted_node) = graph.node_weight(idx) {
                            // Find the file path for the shifted node
                            // We need to resolve the interned path Spur back to string/PathBuf
                            // But since we are under write-lock, we can just scan the file_index maps
                            // and replace last_idx with idx in the vector.
                            for indices in file_index.values_mut() {
                                if let Some(pos) = indices.iter().position(|&x| x == last_idx) {
                                    indices[pos] = idx;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Insert new nodes
        let mut inserted_indices = Vec::new();
        for node in new_nodes {
            let idx = graph.add_node(node);
            inserted_indices.push(idx);
        }

        // Save newly created NodeIndexes for this file
        file_index.insert(file_path, inserted_indices);

        // 3. Insert new edges
        // (This will be called in Pass 2 of parsing. We will match symbols and add directed edges).
    }
}
