use std::path::{Path, PathBuf};
pub use crate::graph::store::Language;
use crate::logging::log_verbose;

#[derive(Debug, Clone, PartialEq, Eq, Hash, serde::Serialize)]
pub enum ResolvedTarget {
    LocalFile(PathBuf),
    ExternalCrate(String),
}

/// Normalizes path by resolving dot components logically
pub fn clean_path(path: &Path) -> PathBuf {
    use std::path::Component;
    let mut out = PathBuf::new();
    for comp in path.components() {
        match comp {
            Component::ParentDir => {
                out.pop();
            }
            Component::CurDir => {}
            _ => {
                out.push(comp);
            }
        }
    }
    out
}

pub fn resolve_import(source_file: &Path, raw_target: &str, lang: Language) -> ResolvedTarget {
    let result = if raw_target.starts_with('.') || raw_target.starts_with('/') {
        let parent = source_file.parent().unwrap_or_else(|| Path::new("."));
        let joined = parent.join(raw_target);
        let normalized = clean_path(&joined);

        let extensions = match lang {
            Language::Rust => vec!["rs"],
            Language::TypeScript => vec!["ts", "tsx", "js", "jsx"],
            Language::Python => vec!["py"],
            Language::Dart => vec!["dart"],
            Language::Go => vec!["go"],
        };

        if normalized.is_file() {
            ResolvedTarget::LocalFile(normalized)
        } else {
            let mut resolved = None;
            for ext in &extensions {
                let with_ext = normalized.with_extension(ext);
                if with_ext.is_file() {
                    resolved = Some(ResolvedTarget::LocalFile(with_ext));
                    break;
                }
            }

            if resolved.is_none() && normalized.is_dir() {
                match lang {
                    Language::Rust => {
                        let mod_rs = normalized.join("mod.rs");
                        if mod_rs.is_file() {
                            resolved = Some(ResolvedTarget::LocalFile(mod_rs));
                        }
                    }
                    Language::TypeScript => {
                        for ext in &["ts", "tsx", "js"] {
                            let index_file = normalized.join(format!("index.{}", ext));
                            if index_file.is_file() {
                                resolved = Some(ResolvedTarget::LocalFile(index_file));
                                break;
                            }
                        }
                    }
                    Language::Python => {
                        let init_py = normalized.join("__init__.py");
                        if init_py.is_file() {
                            resolved = Some(ResolvedTarget::LocalFile(init_py));
                        }
                    }
                    Language::Dart | Language::Go => {}
                }
            }

            resolved.unwrap_or_else(|| ResolvedTarget::LocalFile(normalized))
        }
    } else {
        ResolvedTarget::ExternalCrate(raw_target.to_string())
    };

    log_verbose(
        "resolver",
        &format!(
            "Resolved import '{}' in '{}' -> {:?}",
            raw_target,
            source_file.display(),
            result
        ),
    );
    result
}
