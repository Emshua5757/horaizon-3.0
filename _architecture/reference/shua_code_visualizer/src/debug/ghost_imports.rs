use std::path::PathBuf;
pub use crate::graph::store::AppState;

#[derive(Debug, serde::Serialize)]
pub struct GhostImportReport {
    pub importer: PathBuf,
    pub imported: PathBuf,
    pub symbol_count: usize,
}

pub fn find_ghost_imports(state: &AppState) -> Vec<GhostImportReport> {
    let file_metadata = state.file_metadata.read().unwrap();
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut reports = Vec::new();

    for (importer_path, metadata) in file_metadata.iter() {
        for (imported_path, _imported_symbols) in &metadata.imports {
            let mut exported_symbols = Vec::new();
            for idx in graph.node_indices() {
                if let Some(node) = graph.node_weight(idx) {
                    let file_str = intern.resolve(&node.file);
                    if PathBuf::from(file_str) == *imported_path {
                        let name_str = intern.resolve(&node.name);
                        exported_symbols.push(name_str.to_string());
                    }
                }
            }

            if exported_symbols.is_empty() {
                continue;
            }

            let is_used = exported_symbols.iter().any(|sym| {
                metadata.call_sites.iter().any(|(_, call)| call == sym)
            });

            if !is_used {
                reports.push(GhostImportReport {
                    importer: importer_path.clone(),
                    imported: imported_path.clone(),
                    symbol_count: exported_symbols.len(),
                });
            }
        }
    }

    reports.sort_by(|a, b| b.symbol_count.cmp(&a.symbol_count));
    reports
}
