use std::path::Path;
use rayon::prelude::*;
use walkdir::WalkDir;
pub use crate::graph::store::{AppState, Language};
use crate::parser::ast::detect_language;
use crate::parser::registry::extract_declarations;
use crate::logging::{log_status, log_verbose};

pub fn run_full_scan(root: &Path, state: &AppState) {
    let mut paths = Vec::new();
    let walker = WalkDir::new(root).follow_links(false).into_iter();

    // Collect paths synchronously and filter ignored directories/extensions
    for entry in walker.filter_entry(|e| {
        let name = e.file_name().to_str().unwrap_or("");
        if name.starts_with(".venv") || name == "venv" {
            return false;
        }
        !matches!(
            name,
            ".git"
                | ".github"
                | ".vscode"
                | ".gemini"
                | ".dart_tool"
                | ".pub-cache"
                | "node_modules"
                | "target"
                | "build"
                | "bin"
                | "obj"
                | "dist"
                | "out"
                | ".gradle"
                | ".idea"
        )
    }) {
        if let Ok(e) = entry {
            if e.file_type().is_file() {
                let p = e.path().to_path_buf();
                let file_name = p.file_name().and_then(|f| f.to_str()).unwrap_or("");
                let is_generated = file_name.ends_with(".g.dart")
                    || file_name.ends_with(".freezed.dart")
                    || file_name.to_lowercase() == "hbp_constants.go"
                    || file_name.to_lowercase() == "hbp_constants.py"
                    || file_name.to_lowercase() == "hbpconstants.cs"
                    || file_name.to_lowercase() == "hbpconstants.java"
                    || file_name.to_lowercase() == "hbpconstants.ts";
                if !is_generated {
                    if detect_language(&p).is_some() {
                        paths.push(p);
                    }
                }
            }
        }
    }

    tracing::info!(
        subsystem = "parser",
        count = paths.len(),
        "Collected files to process in parallel."
    );

    let verbose = crate::logging::VERBOSE_LOGGING.load(std::sync::atomic::Ordering::Relaxed);
    let centralized = crate::logging::CENTRALIZED_LOGGING.load(std::sync::atomic::Ordering::Relaxed);

    if verbose && !centralized {
        log_status("parser", &format!("Step 1: Processing {} files sequentially (verbose mode)...", paths.len()));
        paths.iter().for_each(|p| {
            log_verbose("parser", &format!("  Scanning: {}", p.display()));
            parse_and_index_file(p, state);
        });
    } else {
        log_status("parser", &format!("Step 1: Processing {} files in parallel...", paths.len()));
        paths.par_iter().for_each(|p| {
            log_verbose("parser", &format!("  Scanning: {}", p.display()));
            parse_and_index_file(p, state);
        });
    }

    log_status("parser", "Step 2: Resolving edges...");
    crate::parser::callgraph::resolve_edges(state);
    
    log_status("parser", "Step 3: Computing centrality...");
    crate::parser::analyzer::compute_centrality(state);
    
    log_status("parser", "Step 4: Extracting API routes...");
    crate::debug::routes_map::extract_api_routes(state);
    
    log_status("parser", "Step 5: Detecting cycles...");
    crate::parser::analyzer::detect_cycles(state);
    
    log_status("parser", "Step 6: Detecting trait implementations...");
    crate::parser::analyzer::detect_trait_method_impls(state);
    
    log_status("parser", "Step 7: Detecting framework invocations...");
    crate::parser::analyzer::detect_framework_invoked(state);
    
    log_status("parser", "Step 8: Detecting serde callbacks...");
    crate::parser::analyzer::detect_serde_callbacks(state);
    
    log_status("parser", "Step 9: Detecting entry points...");
    crate::parser::analyzer::detect_entry_points(state);
    
    log_status("parser", "Step 10: Assigning tags (including side-effects and test linkages)...");
    crate::parser::analyzer::assign_tags(state);
    
    log_status("parser", "Scan complete!");

    let (node_count, edge_count) = {
        let graph = state.graph.read().unwrap();
        (graph.node_count(), graph.edge_count())
    };
    tracing::info!(
        subsystem = "parser",
        node_count,
        edge_count,
        "Finished full cold scan."
    );
}

pub fn parse_and_index_file(file_path: &Path, state: &AppState) {
    let lang = match detect_language(file_path) {
        Some(l) => l,
        None => return,
    };

    let source = match std::fs::read(file_path) {
        Ok(s) => s,
        Err(_) => return,
    };

    let declarations = extract_declarations(file_path, &source, lang, state);

    let raw_imports = crate::parser::callgraph::extract_imports(file_path, &source, lang, state);
    let call_sites = crate::parser::callgraph::extract_call_sites(file_path, &source, lang, state);
    let type_refs = crate::parser::callgraph::extract_type_references(file_path, &source, lang, state);

    let mut metadata_imports = Vec::new();
    for (target, symbols) in raw_imports {
        if let crate::parser::resolver::ResolvedTarget::LocalFile(path) = target {
            let symbol_names = {
                let intern = state.intern.read().unwrap();
                symbols.iter().map(|&k| intern.resolve(&k).to_string()).collect()
            };
            metadata_imports.push((path, symbol_names));
        }
    }

    let call_site_names = {
        let intern = state.intern.read().unwrap();
        call_sites.iter().map(|&(line, k)| (line, intern.resolve(&k).to_string())).collect()
    };

    let type_ref_names = {
        let intern = state.intern.read().unwrap();
        type_refs.iter().map(|&(line, k)| (line, intern.resolve(&k).to_string())).collect()
    };

    let summary = extract_file_summary(&source, lang);

    {
        let mut file_meta = state.file_metadata.write().unwrap();
        file_meta.insert(file_path.to_path_buf(), crate::graph::store::FileMetadata {
            imports: metadata_imports,
            call_sites: call_site_names,
            type_references: type_ref_names,
            summary,
        });
    }

    state.upsert_file_symbols(file_path.to_path_buf(), declarations, Vec::new());
}

fn extract_file_summary(source: &[u8], lang: Language) -> String {
    let content = match std::str::from_utf8(source) {
        Ok(s) => s,
        Err(_) => return String::new(),
    };

    let mut summary = String::new();

    match lang {
        Language::Rust | Language::TypeScript | Language::Dart | Language::Go => {
            let mut in_block = false;
            for line in content.lines() {
                let trimmed = line.trim();
                if trimmed.starts_with("/**") || trimmed.starts_with("/*!") {
                    in_block = true;
                    let doc = trimmed.trim_start_matches("/**").trim_start_matches("/*!").trim();
                    if !doc.is_empty() {
                        summary.push_str(doc);
                    }
                    if trimmed.ends_with("*/") {
                        break;
                    }
                } else if in_block {
                    if trimmed.ends_with("*/") {
                        let doc = trimmed.trim_end_matches("*/").trim().trim_start_matches('*').trim();
                        if !doc.is_empty() {
                            if !summary.is_empty() {
                                summary.push(' ');
                            }
                            summary.push_str(doc);
                        }
                        break;
                    } else {
                        let doc = trimmed.trim_start_matches('*').trim();
                        if !doc.is_empty() {
                            if !summary.is_empty() {
                                summary.push(' ');
                            }
                            summary.push_str(doc);
                        }
                    }
                } else if trimmed.starts_with("//") {
                    let doc = trimmed.trim_start_matches("//!").trim_start_matches("///").trim_start_matches("//").trim();
                    if !doc.is_empty() {
                        if !summary.is_empty() {
                            summary.push(' ');
                        }
                        summary.push_str(doc);
                    }
                } else if !trimmed.is_empty() {
                    break;
                }
            }
        }
        Language::Python => {
            let mut lines = content.lines().map(|l| l.trim()).filter(|l| !l.is_empty());
            if let Some(first_line) = lines.next() {
                if first_line.starts_with("\"\"\"") || first_line.starts_with("'''") {
                    let quote = if first_line.starts_with("\"\"\"") { "\"\"\"" } else { "'''" };
                    let mut doc = first_line.trim_start_matches(quote).to_string();
                    if doc.ends_with(quote) {
                        summary = doc.trim_end_matches(quote).trim().to_string();
                    } else {
                        for line in lines {
                            if line.ends_with(quote) {
                                let part = line.trim_end_matches(quote).trim();
                                if !part.is_empty() {
                                    if !doc.is_empty() {
                                        doc.push(' ');
                                    }
                                    doc.push_str(part);
                                }
                                break;
                            } else {
                                if !line.is_empty() {
                                    if !doc.is_empty() {
                                        doc.push(' ');
                                    }
                                    doc.push_str(line);
                                }
                            }
                        }
                        summary = doc;
                    }
                }
            }
        }
    }

    if summary.chars().count() > 200 {
        summary = format!("{}...", summary.chars().take(197).collect::<String>());
    }
    summary.replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;")
}
