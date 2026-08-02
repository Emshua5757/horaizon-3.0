use std::path::{Path, PathBuf};
pub use crate::graph::store::AppState;

#[derive(Debug, serde::Serialize)]
pub struct BoundaryViolation {
    pub source: PathBuf,
    pub target: PathBuf,
}

fn get_module_root(path: &Path) -> Option<String> {
    let mut comps = path.components();
    let first = comps.next()?.as_os_str().to_str()?;
    if first == "shua_modules" {
        let second = comps.next()?.as_os_str().to_str()?;
        Some(second.to_string())
    } else {
        Some(first.to_string())
    }
}

pub fn find_boundary_violations(state: &AppState) -> Vec<BoundaryViolation> {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut violations = Vec::new();

    for edge_idx in graph.edge_indices() {
        if let Some((source_idx, target_idx)) = graph.edge_endpoints(edge_idx) {
            let source_node = graph.node_weight(source_idx);
            let target_node = graph.node_weight(target_idx);

            if let (Some(src), Some(tgt)) = (source_node, target_node) {
                let src_file = intern.resolve(&src.file);
                let tgt_file = intern.resolve(&tgt.file);
                let src_path = PathBuf::from(src_file);
                let tgt_path = PathBuf::from(tgt_file);

                let src_root = get_module_root(&src_path);
                let tgt_root = get_module_root(&tgt_path);

                if src_root != tgt_root {
                    let is_private = tgt_path.components().any(|c| {
                        let s = c.as_os_str().to_string_lossy();
                        s == "internal" || s == "private"
                    });

                    if is_private {
                        violations.push(BoundaryViolation {
                            source: src_path,
                            target: tgt_path,
                        });
                    }
                }
            }
        }
    }

    violations
}
