pub use crate::graph::store::{AppState, InternKey, Language};
use crate::parser::ast::get_parser;
use crate::parser::resolver::{resolve_import, ResolvedTarget};
use std::path::Path;
use tree_sitter::{Query, QueryCursor};

/// Extracts raw import targets and the specific symbols imported
pub fn extract_imports(
    file: &Path,
    source: &[u8],
    lang: Language,
    _state: &AppState,
) -> Vec<(ResolvedTarget, Vec<InternKey>)> {
    let mut parser = match get_parser(lang) {
        Some(p) => p,
        None => return Vec::new(),
    };

    let tree = match parser.parse(source, None) {
        Some(t) => t,
        None => return Vec::new(),
    };

    let root_node = tree.root_node();

    // Query strings to match import statements and targets
    let query_str = match lang {
        Language::Rust => {
            r#"
            (use_declaration
              argument: [
                (use_path) @path
                (use_list) @list
              ])
        "#
        }
        Language::TypeScript => {
            r#"
            (import_statement
              source: (string) @source)
            (import_specifier
              name: (identifier) @name)
        "#
        }
        Language::Python => {
            r#"
            (import_from_statement
              module_name: (dotted_name) @source)
            (import_statement
              name: (dotted_name) @source)
        "#
        }
        Language::Dart => {
            r#"
            (import_specification
              path: (string_literal) @source)
        "#
        }
        Language::Go => {
            r#"
            (import_spec
              path: (import_path) @source)
        "#
        }
    };

    let ts_lang = crate::parser::ast::get_tree_sitter_language(lang);

    let query = match Query::new(&ts_lang, query_str) {
        Ok(q) => q,
        Err(_) => return Vec::new(),
    };

    let mut cursor = QueryCursor::new();
    let matches = cursor.matches(&query, root_node, source);

    let mut imports = Vec::new();

    for mat in matches {
        for cap in mat.captures {
            let cap_name = query.capture_names()[cap.index as usize];
            let node = cap.node;

            if cap_name == "source" || cap_name == "path" {
                if let Ok(text) = node.utf8_text(source) {
                    // Clean target (strip quotes for TS/Dart string literals)
                    let clean_target = text.trim_matches(|c| c == '\'' || c == '"');

                    let resolved = resolve_import(file, clean_target, lang);
                    imports.push((resolved, Vec::new()));
                }
            }
        }
    }

    imports
}

/// Extracts callee identifiers (call sites) in the file
pub fn extract_call_sites(
    _file: &Path,
    source: &[u8],
    lang: Language,
    state: &AppState,
) -> Vec<(u32, InternKey)> {
    let mut parser = match get_parser(lang) {
        Some(p) => p,
        None => return Vec::new(),
    };

    let tree = match parser.parse(source, None) {
        Some(t) => t,
        None => return Vec::new(),
    };

    let root_node = tree.root_node();

    let query_str = match lang {
        Language::Rust => {
            r#"
            (call_expression
              function: [
                (identifier) @callee
                (scoped_identifier) @callee
                (field_expression field: (field_identifier) @callee)
              ])
        "#
        }
        Language::TypeScript => {
            r#"
            (call_expression
              function: [
                (identifier) @callee
                (member_expression) @callee
              ])
            (new_expression
              [
                (identifier) @callee
                (type_identifier) @callee
                (member_expression) @callee
              ])
            (pair
              value: [
                (identifier) @callee
                (member_expression) @callee
              ])
            (array
              [
                (identifier) @callee
                (member_expression) @callee
              ])
        "#
        }
        Language::Python => {
            r#"
            (call
              function: [
                (identifier) @callee
                (attribute) @callee
              ])
            (list (identifier) @callee)
            (tuple (identifier) @callee)
            (pair value: (identifier) @callee)
        "#
        }
        Language::Dart => {
            r#"
            (identifier) @callee
            (unconditional_assignable_selector (identifier) @callee)
            (new_expression
              (type_identifier) @callee)
            (constructor_invocation
              (type_identifier) @callee)
            (const_object_expression
              (type_identifier) @callee)
        "#
        }
        Language::Go => {
            r#"
            (call_expression
              function: [
                (identifier) @callee
                (selector_expression) @callee
              ])
        "#
        }
    };

    let ts_lang = crate::parser::ast::get_tree_sitter_language(lang);

    let query = match Query::new(&ts_lang, query_str) {
        Ok(q) => q,
        Err(e) => {
            tracing::error!(subsystem = "parser", error = ?e, "Failed to compile callgraph query");
            return Vec::new();
        }
    };

    let mut cursor = QueryCursor::new();
    let matches = cursor.matches(&query, root_node, source);

    let mut callees = Vec::new();

    for mat in matches {
        for cap in mat.captures {
            let node = cap.node;
            if let Ok(text) = node.utf8_text(source) {
                let mut intern = state.intern.write().unwrap();
                let key = intern.get_or_intern(text);
                let line = node.range().start_point.row as u32;
                callees.push((line, key));

                // 6.9 RPC Cross-Module Edge check
                if text == "sendRpc" || text == "sendRpcWithResponse" {
                    if let Some(rpc_name) = find_first_string_literal_in_ancestor(node, source) {
                        let rpc_key = intern.get_or_intern(&rpc_name);
                        callees.push((line, rpc_key));
                    }
                }
            }
        }
    }

    callees
}

fn find_string_literal(node: tree_sitter::Node, source: &[u8]) -> Option<String> {
    let kind = node.kind();
    if kind == "string" || kind == "string_literal" {
        if let Ok(text) = node.utf8_text(source) {
            return Some(text.trim_matches('\'').trim_matches('"').to_string());
        }
    }
    let mut cursor = node.walk();
    for child in node.children(&mut cursor) {
        if let Some(s) = find_string_literal(child, source) {
            return Some(s);
        }
    }
    None
}

fn find_first_string_literal_in_ancestor(node: tree_sitter::Node, source: &[u8]) -> Option<String> {
    let mut current = node;
    for _ in 0..4 {
        if let Some(parent) = current.parent() {
            let p_kind = parent.kind();
            if p_kind == "expression_statement" || p_kind == "call_expression" || p_kind == "postfix_expression" || p_kind == "expression" {
                if let Some(lit) = find_string_literal(parent, source) {
                    return Some(lit);
                }
                break;
            }
            current = parent;
        } else {
            break;
        }
    }
    None
}

/// Extracts static type reference identifiers in the file
pub fn extract_type_references(
    _file: &Path,
    source: &[u8],
    lang: Language,
    state: &AppState,
) -> Vec<(u32, InternKey)> {
    let mut parser = match get_parser(lang) {
        Some(p) => p,
        None => return Vec::new(),
    };

    let tree = match parser.parse(source, None) {
        Some(t) => t,
        None => return Vec::new(),
    };

    let root_node = tree.root_node();

    let query_str = match lang {
        Language::Rust => {
            r#"
            (type_identifier) @type
        "#
        }
        Language::TypeScript => {
            r#"
            (type_identifier) @type
        "#
        }
        Language::Python => {
            r#"
            (type) @type
        "#
        }
        Language::Dart => {
            r#"
            (type_identifier) @type
        "#
        }
        Language::Go => {
            r#"
            (type_identifier) @type
        "#
        }
    };

    let ts_lang = crate::parser::ast::get_tree_sitter_language(lang);

    let query = match Query::new(&ts_lang, query_str) {
        Ok(q) => q,
        Err(_) => return Vec::new(),
    };

    let mut cursor = QueryCursor::new();
    let matches = cursor.matches(&query, root_node, source);

    let mut types = Vec::new();

    for mat in matches {
        for cap in mat.captures {
            let node = cap.node;
            if let Ok(text) = node.utf8_text(source) {
                let mut intern = state.intern.write().unwrap();
                let key = intern.get_or_intern(text);
                let line = node.range().start_point.row as u32;
                types.push((line, key));
            }
        }
    }

    types
}

pub fn resolve_edges(state: &AppState) {
    let (symbol_map, suffix_map) = {
        let graph = state.graph.read().unwrap();
        let intern = state.intern.read().unwrap();
        build_symbol_indices(&graph, &intern)
    };
    resolve_call_edges(state, &symbol_map, &suffix_map);
    resolve_type_ref_edges(state, &symbol_map, &suffix_map);
    deduplicate_edges(state);
}

fn build_symbol_indices(
    graph: &petgraph::graph::DiGraph<crate::graph::store::SymbolNode, crate::graph::store::DependencyEdge>,
    intern: &lasso::Rodeo,
) -> (
    std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>>,
    std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>>,
) {
    let mut symbol_map: std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>> =
        std::collections::HashMap::new();
    let mut suffix_map: std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>> =
        std::collections::HashMap::new();

    for idx in graph.node_indices() {
        if let Some(node) = graph.node_weight(idx) {
            let name_str = intern.resolve(&node.name).to_string();
            symbol_map.entry(name_str.clone()).or_default().push(idx);

            let clean_name = name_str.split("::").last().unwrap_or(&name_str);
            let clean_name = clean_name
                .split('.')
                .last()
                .unwrap_or(clean_name)
                .to_string();
            suffix_map.entry(clean_name).or_default().push(idx);
        }
    }
    (symbol_map, suffix_map)
}

fn resolve_call_edges(
    state: &AppState,
    symbol_map: &std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>>,
    suffix_map: &std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>>,
) {
    crate::logging::log_verbose("callgraph", "Resolving call edges...");
    let file_index = state.file_index.read().unwrap();
    let file_metadata = state.file_metadata.read().unwrap();
    let intern = state.intern.read().unwrap();
    let mut graph = state.graph.write().unwrap();

    for (file_path, meta) in file_metadata.iter() {
        let caller_nodes = match file_index.get(file_path) {
            Some(nodes) => nodes,
            None => continue,
        };

        for &(line, ref call) in &meta.call_sites {
            let parts: Vec<&str> = if call.contains("::") {
                call.split("::").collect()
            } else if call.contains('.') {
                call.split('.').collect()
            } else {
                vec![call.as_str()]
            };

            let last_part = parts.last().cloned().unwrap_or(call.as_str());
            let matching_indices = symbol_map
                .get(call)
                .or_else(|| symbol_map.get(last_part))
                .or_else(|| suffix_map.get(call))
                .or_else(|| suffix_map.get(last_part));

            if let Some(target_indices) = matching_indices {
                let mut resolved_target = None;

                for &target_idx in target_indices {
                    if let Some(target_node) = graph.node_weight(target_idx) {
                        let target_name = intern.resolve(&target_node.name);

                        // 6.8 Registry Dispatch constructor matching for Dart / TypeScript (check constructor first)
                        if target_node.language == Language::Dart && target_name == &format!("{}.{}", call, call) {
                            resolved_target = Some(target_idx);
                            break;
                        }
                        if target_node.language == Language::TypeScript && target_name == &format!("{}.constructor", call) {
                            resolved_target = Some(target_idx);
                            break;
                        }

                        if target_name == *call {
                            resolved_target = Some(target_idx);
                            break;
                        }

                        if parts.len() > 1 {
                            let target_file_str = intern.resolve(&target_node.file);
                            let target_file_path = std::path::Path::new(target_file_str);
                            let file_stem = target_file_path
                                .file_stem()
                                .and_then(|s| s.to_str())
                                .unwrap_or("");

                            if target_name == last_part && parts.iter().any(|&p| p == file_stem) {
                                resolved_target = Some(target_idx);
                                break;
                            }

                            if parts.iter().all(|&p| target_name.contains(p)) {
                                resolved_target = Some(target_idx);
                                break;
                            }
                        }
                    }
                }

                if resolved_target.is_none() {
                    for (imported_file, _) in &meta.imports {
                        for &target_idx in target_indices {
                            if let Some(target_node) = graph.node_weight(target_idx) {
                                let target_file_str = intern.resolve(&target_node.file);
                                let target_file_normalized =
                                    target_file_str.to_lowercase().replace('\\', "/");
                                let imported_file_normalized = imported_file
                                    .to_string_lossy()
                                    .to_lowercase()
                                    .replace('\\', "/");
                                if target_file_normalized == imported_file_normalized {
                                    resolved_target = Some(target_idx);
                                    break;
                                }
                              }
                        }
                        if resolved_target.is_some() {
                            break;
                        }
                    }
                }

                if resolved_target.is_none() {
                    for &target_idx in target_indices {
                        if caller_nodes.contains(&target_idx) {
                            resolved_target = Some(target_idx);
                            break;
                        }
                    }
                }

                if resolved_target.is_none() && target_indices.len() == 1 {
                    resolved_target = Some(target_indices[0]);
                }

                if let Some(target_idx) = resolved_target {
                    let mut specific_caller = None;
                    for &caller_idx in caller_nodes {
                        if let Some(node) = graph.node_weight(caller_idx) {
                            if node.line_start <= line && line <= node.line_end {
                                match specific_caller {
                                    None => {
                                        specific_caller =
                                            Some((caller_idx, node.line_end - node.line_start))
                                    }
                                    Some((_, best_range)) => {
                                        let current_range = node.line_end - node.line_start;
                                        if current_range < best_range {
                                            specific_caller = Some((caller_idx, current_range));
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let Some((caller_idx, _)) = specific_caller {
                        if caller_idx != target_idx {
                            if !graph.contains_edge(caller_idx, target_idx) {
                                let caller_name = intern.resolve(&graph.node_weight(caller_idx).unwrap().name).to_string();
                                let target_name = intern.resolve(&graph.node_weight(target_idx).unwrap().name).to_string();
                                crate::logging::log_verbose("callgraph", &format!("Linked call: {} -> {} at line {} in {}", caller_name, target_name, line, file_path.display()));
                                graph.add_edge(
                                    caller_idx,
                                    target_idx,
                                    crate::graph::store::DependencyEdge {
                                        dep_type: crate::graph::store::DependencyType::Calls,
                                        symbols: Vec::new(),
                                    },
                                );
                            }
                        }
                    } else {
                        // Top-level call site: link from the first symbol in the same file as caller fallback
                        if let Some(&caller_idx) = caller_nodes.first() {
                            if caller_idx != target_idx {
                                if !graph.contains_edge(caller_idx, target_idx) {
                                    let caller_name = intern.resolve(&graph.node_weight(caller_idx).unwrap().name).to_string();
                                    let target_name = intern.resolve(&graph.node_weight(target_idx).unwrap().name).to_string();
                                    crate::logging::log_verbose("callgraph", &format!("Linked top-level call: {} (via file scope fallback) -> {} at line {} in {}", caller_name, target_name, line, file_path.display()));
                                    graph.add_edge(
                                        caller_idx,
                                        target_idx,
                                        crate::graph::store::DependencyEdge {
                                            dep_type: crate::graph::store::DependencyType::Calls,
                                            symbols: Vec::new(),
                                        },
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

fn resolve_type_ref_edges(
    state: &AppState,
    symbol_map: &std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>>,
    suffix_map: &std::collections::HashMap<String, Vec<petgraph::graph::NodeIndex>>,
) {
    crate::logging::log_verbose("callgraph", "Resolving type reference edges...");
    let file_index = state.file_index.read().unwrap();
    let file_metadata = state.file_metadata.read().unwrap();
    let intern = state.intern.read().unwrap();
    let mut graph = state.graph.write().unwrap();

    for (file_path, meta) in file_metadata.iter() {
        let caller_nodes = match file_index.get(file_path) {
            Some(nodes) => nodes,
            None => continue,
        };

        for &(line, ref type_ref) in &meta.type_references {
            let matching_indices = symbol_map
                .get(type_ref)
                .or_else(|| suffix_map.get(type_ref));

            if let Some(target_indices) = matching_indices {
                let mut resolved_target = None;

                for &target_idx in target_indices {
                    if let Some(target_node) = graph.node_weight(target_idx) {
                        let target_name = intern.resolve(&target_node.name);
                        if target_name == *type_ref {
                            resolved_target = Some(target_idx);
                            break;
                        }
                    }
                }

                if resolved_target.is_none() {
                    for (imported_file, _) in &meta.imports {
                        for &target_idx in target_indices {
                            if let Some(target_node) = graph.node_weight(target_idx) {
                                let target_file_str = intern.resolve(&target_node.file);
                                let target_file_normalized =
                                    target_file_str.to_lowercase().replace('\\', "/");
                                let imported_file_normalized = imported_file
                                    .to_string_lossy()
                                    .to_lowercase()
                                    .replace('\\', "/");
                                if target_file_normalized == imported_file_normalized {
                                    resolved_target = Some(target_idx);
                                    break;
                                }
                            }
                        }
                        if resolved_target.is_some() {
                            break;
                        }
                    }
                }

                if resolved_target.is_none() {
                    for &target_idx in target_indices {
                        if caller_nodes.contains(&target_idx) {
                            resolved_target = Some(target_idx);
                            break;
                        }
                    }
                }

                if resolved_target.is_none() && target_indices.len() == 1 {
                    resolved_target = Some(target_indices[0]);
                }

                if let Some(target_idx) = resolved_target {
                    let mut specific_caller = None;
                    for &caller_idx in caller_nodes {
                        if let Some(node) = graph.node_weight(caller_idx) {
                            if node.line_start <= line && line <= node.line_end {
                                match specific_caller {
                                    None => {
                                        specific_caller =
                                            Some((caller_idx, node.line_end - node.line_start))
                                    }
                                    Some((_, best_range)) => {
                                        let current_range = node.line_end - node.line_start;
                                        if current_range < best_range {
                                            specific_caller = Some((caller_idx, current_range));
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let Some((caller_idx, _)) = specific_caller {
                        if caller_idx != target_idx {
                            if !graph.contains_edge(caller_idx, target_idx) {
                                let caller_name = intern.resolve(&graph.node_weight(caller_idx).unwrap().name).to_string();
                                let target_name = intern.resolve(&graph.node_weight(target_idx).unwrap().name).to_string();
                                crate::logging::log_verbose("callgraph", &format!("Linked instantiation: {} -> {} (via type reference '{}') at line {} in {}", caller_name, target_name, type_ref, line, file_path.display()));
                                graph.add_edge(
                                    caller_idx,
                                    target_idx,
                                    crate::graph::store::DependencyEdge {
                                        dep_type: crate::graph::store::DependencyType::Instantiates,
                                        symbols: Vec::new(),
                                    },
                                );
                            }
                        }
                    }
                }
            }
        }
    }
}

fn deduplicate_edges(state: &AppState) {
    crate::logging::log_verbose("callgraph", "Deduplicating graph edges...");
    let mut graph = state.graph.write().unwrap();
    let initial_count = graph.edge_count();
    let mut edges_to_keep = std::collections::HashSet::new();
    let mut edges_to_remove = Vec::new();

    use petgraph::visit::EdgeRef;
    for edge in graph.edge_references() {
        let source = edge.source();
        let target = edge.target();
        let dep_type = edge.weight().dep_type;
        
        let key = (source, target, dep_type);
        if !edges_to_keep.insert(key) {
            edges_to_remove.push(edge.id());
        }
    }

    let removed_count = edges_to_remove.len();
    edges_to_remove.sort_by(|a, b| b.cmp(a));
    for edge_idx in edges_to_remove {
        graph.remove_edge(edge_idx);
    }
    crate::logging::log_verbose("callgraph", &format!("Deduplicated edges: removed {} duplicate edges. Final edge count: {}", removed_count, initial_count - removed_count));
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::ast::get_parser;
    use crate::graph::store::Language;

    #[test]
    fn test_dart_method_call_ast() {
        let code = "void foo() { var btn = Button(_addRow); var btn2 = Button(onPressed: _addColumn); }";
        let mut parser = get_parser(Language::Dart).unwrap();
        let tree = parser.parse(code, None).unwrap();
        let root_node = tree.root_node();
        
        let query_str = r#"
            (identifier) @callee
            (unconditional_assignable_selector (identifier) @callee)
            (new_expression
              (type_identifier) @callee)
            (constructor_invocation
              (type_identifier) @callee)
            (const_object_expression
              (type_identifier) @callee)
        "#;
        
        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::Dart);
        let query = Query::new(&ts_lang, query_str).unwrap();
        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, root_node, code.as_bytes());
        
        let mut results = Vec::new();
        for mat in matches {
            for cap in mat.captures {
                let text = cap.node.utf8_text(code.as_bytes()).unwrap();
                results.push(text.to_string());
            }
        }
        
        assert!(results.contains(&"_addRow".to_string()), "Should find _addRow, found {:?}", results);
        assert!(results.contains(&"_addColumn".to_string()), "Should find _addColumn, found {:?}", results);
    }
}
