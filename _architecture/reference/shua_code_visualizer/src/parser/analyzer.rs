pub use crate::graph::store::{AppState, SymbolTag, SymbolKind, Language};
use tree_sitter::{Query, QueryCursor};
use crate::parser::ast::get_parser;

pub fn compute_centrality(state: &AppState) {
    let mut graph = state.graph.write().unwrap();
    let node_indices: Vec<_> = graph.node_indices().collect();

    for idx in node_indices {
        let in_degree = graph.edges_directed(idx, petgraph::Incoming).count() as u32;
        let out_degree = graph.edges_directed(idx, petgraph::Outgoing).count() as u32;
        
        if let Some(node) = graph.node_weight_mut(idx) {
            node.in_degree = in_degree;
            node.out_degree = out_degree;
        }
    }
}

pub fn detect_cycles(state: &AppState) {
    let mut graph = state.graph.write().unwrap();
    
    let mut func_graph = petgraph::graph::DiGraph::<petgraph::graph::NodeIndex, ()>::new();
    let mut node_map = std::collections::HashMap::new();
    
    for idx in graph.node_indices() {
        if let Some(node) = graph.node_weight(idx) {
            if matches!(node.kind, SymbolKind::Function) {
                let f_idx = func_graph.add_node(idx);
                node_map.insert(idx, f_idx);
            }
        }
    }
    
    use petgraph::visit::EdgeRef;
    for edge in graph.edge_references() {
        let source = edge.source();
        let target = edge.target();
        if let (Some(&s), Some(&t)) = (node_map.get(&source), node_map.get(&target)) {
            if matches!(edge.weight().dep_type, crate::graph::store::DependencyType::Calls) {
                func_graph.add_edge(s, t, ());
            }
        }
    }
    
    let sccs = petgraph::algo::tarjan_scc(&func_graph);
    for scc in sccs {
        if scc.len() > 1 {
            for f_idx in scc {
                let graph_idx = func_graph[f_idx];
                if let Some(node) = graph.node_weight_mut(graph_idx) {
                    node.is_cycle = true;
                    if !node.tags.contains(&SymbolTag::Cycle) {
                        node.tags.push(SymbolTag::Cycle);
                    }
                }
            }
        }
    }
}

pub fn detect_trait_method_impls(state: &AppState) {
    let file_index = state.file_index.read().unwrap();
    let mut methods_to_tag = Vec::new();

    for path in file_index.keys() {
        if path.extension().map_or(false, |ext| ext == "rs") {
            if let Ok(source) = std::fs::read(path) {
                if let Some(mut parser) = get_parser(Language::Rust) {
                    if let Some(tree) = parser.parse(&source, None) {
                        let root_node = tree.root_node();
                        let query_str = r#"
                            (impl_item
                              trait: (_)? @trait_name
                              type: (_) @type_name
                              body: (declaration_list
                                (function_item name: (identifier) @method_name)))
                        "#;
                        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::Rust);
                        if let Ok(query) = Query::new(&ts_lang, query_str) {
                            let mut cursor = QueryCursor::new();
                            let matches = cursor.matches(&query, root_node, source.as_slice());
                            
                            for mat in matches {
                                let mut type_name = String::new();
                                let mut method_name = String::new();
                                let mut is_trait = false;

                                for cap in mat.captures {
                                    let cap_name = query.capture_names()[cap.index as usize];
                                    let node = cap.node;
                                    if cap_name == "type_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            type_name = text.split('<').next().unwrap_or("").trim().to_string();
                                        }
                                    } else if cap_name == "method_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            method_name = text.trim().to_string();
                                        }
                                    } else if cap_name == "trait_name" {
                                        is_trait = true;
                                    }
                                }

                                if !type_name.is_empty() && !method_name.is_empty() {
                                    let qualified_name = format!("{}::{}", type_name, method_name);
                                    methods_to_tag.push((qualified_name, is_trait));
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if !methods_to_tag.is_empty() {
        let intern = state.intern.read().unwrap();
        let mut graph = state.graph.write().unwrap();
        for (qualified_name, _is_trait) in methods_to_tag {
            if let Some(name_key) = intern.get(&qualified_name) {
                for node in graph.node_weights_mut() {
                    if node.name == name_key && node.language == Language::Rust {
                        if !node.tags.contains(&SymbolTag::TraitMethod) {
                            node.tags.push(SymbolTag::TraitMethod);
                        }
                    }
                }
            }
        }
    }
}

pub fn detect_framework_invoked(state: &AppState) {
    let file_index = state.file_index.read().unwrap();
    let mut methods_to_tag = Vec::new();

    const TS_FRAMEWORK_METHODS: &[&str] = &[
        "analyze",
        "generateFromNotes",
        "generateFromNotesStream",
        "compileJbc",
        "presentJbcStream",
        "constructor",
    ];

    const DART_LIFECYCLE_METHODS: &[&str] = &[
        "build",
        "initState",
        "dispose",
        "createState",
        "didChangeDependencies",
        "didUpdateWidget",
        "deactivate",
        "reassemble",
    ];

    for path in file_index.keys() {
        let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
        if ext == "ts" || ext == "tsx" || ext == "js" || ext == "jsx" {
            if let Ok(source) = std::fs::read(path) {
                if let Some(mut parser) = get_parser(Language::TypeScript) {
                    if let Some(tree) = parser.parse(&source, None) {
                        let root_node = tree.root_node();
                        
                        // First, implements clause interface check
                        let query_str = r#"
                            (class_declaration
                              name: (type_identifier) @class_name
                              (class_heritage
                                (implements_clause))
                              body: (class_body
                                (method_definition name: (property_identifier) @method_name)))
                        "#;
                        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::TypeScript);
                        if let Ok(query) = Query::new(&ts_lang, query_str) {
                            let mut cursor = QueryCursor::new();
                            let matches = cursor.matches(&query, root_node, source.as_slice());
                            for mat in matches {
                                let mut class_name = String::new();
                                let mut method_name = String::new();
                                for cap in mat.captures {
                                    let cap_name = query.capture_names()[cap.index as usize];
                                    let node = cap.node;
                                    if cap_name == "class_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            class_name = text.trim().to_string();
                                        }
                                    } else if cap_name == "method_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            method_name = text.trim().to_string();
                                        }
                                    }
                                }
                                if !class_name.is_empty() && !method_name.is_empty() {
                                    methods_to_tag.push((
                                        format!("{}.{}", class_name, method_name),
                                        Language::TypeScript,
                                        SymbolTag::TraitMethod,
                                    ));
                                }
                            }
                        }

                        // Second, browser events query (addEventListener / on)
                        let event_query_str = r#"
                            (call_expression
                              function: (member_expression
                                property: (property_identifier) @method)
                              arguments: (arguments
                                (string)
                                (identifier) @handler))
                        "#;
                        if let Ok(query) = Query::new(&ts_lang, event_query_str) {
                            let mut cursor = QueryCursor::new();
                            let matches = cursor.matches(&query, root_node, source.as_slice());
                            for mat in matches {
                                let mut method = String::new();
                                let mut handler = String::new();
                                for cap in mat.captures {
                                    let cap_name = query.capture_names()[cap.index as usize];
                                    let node = cap.node;
                                    if cap_name == "method" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            method = text.trim().to_string();
                                        }
                                    } else if cap_name == "handler" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            handler = text.trim().to_string();
                                        }
                                    }
                                }
                                if (method == "on" || method == "addEventListener") && !handler.is_empty() {
                                    methods_to_tag.push((
                                        handler,
                                        Language::TypeScript,
                                        SymbolTag::FrameworkInvoked,
                                    ));
                                }
                            }
                        }
                    }
                }
            }
        } else if ext == "dart" {
            if let Ok(source) = std::fs::read(path) {
                if let Some(mut parser) = get_parser(Language::Dart) {
                    if let Some(tree) = parser.parse(&source, None) {
                        let root_node = tree.root_node();
                        let query_str = r#"
                            (class_definition
                              name: (identifier) @class_name
                              body: (class_body
                                (method_signature
                                  name: (identifier) @method_name)))
                        "#;
                        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::Dart);
                        if let Ok(query) = Query::new(&ts_lang, query_str) {
                            let mut cursor = QueryCursor::new();
                            let matches = cursor.matches(&query, root_node, source.as_slice());
                            for mat in matches {
                                let mut class_name = String::new();
                                let mut method_name = String::new();
                                for cap in mat.captures {
                                    let cap_name = query.capture_names()[cap.index as usize];
                                    let node = cap.node;
                                    if cap_name == "class_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            class_name = text.trim().to_string();
                                        }
                                    } else if cap_name == "method_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            method_name = text.trim().to_string();
                                        }
                                    }
                                }
                                if !class_name.is_empty() && !method_name.is_empty() {
                                    if DART_LIFECYCLE_METHODS.contains(&method_name.as_str()) {
                                        methods_to_tag.push((
                                            format!("{}.{}", class_name, method_name),
                                            Language::Dart,
                                            SymbolTag::FrameworkInvoked,
                                        ));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let intern = state.intern.read().unwrap();
    let mut graph = state.graph.write().unwrap();

    const D3_CALLBACKS: &[&str] = &[
        "drag",
        "tick",
        "zoomed",
        "dragged",
        "ended",
        "mouseover",
        "mouseout",
        "click",
        "dblclick",
    ];

    for node in graph.node_weights_mut() {
        if node.language == Language::TypeScript {
            let node_name = intern.resolve(&node.name);
            let last_part = node_name.split('.').last().unwrap_or(node_name);
            if TS_FRAMEWORK_METHODS.contains(&last_part) || D3_CALLBACKS.contains(&last_part) {
                if !node.tags.contains(&SymbolTag::FrameworkInvoked) {
                    node.tags.push(SymbolTag::FrameworkInvoked);
                }
            }
        }
    }

    for (qualified_name, lang, tag) in methods_to_tag {
        if let Some(name_key) = intern.get(&qualified_name) {
            for node in graph.node_weights_mut() {
                if node.name == name_key && node.language == lang {
                    if !node.tags.contains(&tag) {
                        node.tags.push(tag);
                    }
                }
            }
        }
    }
}

pub fn detect_serde_callbacks(state: &AppState) {
    let file_index = state.file_index.read().unwrap();
    let mut callbacks_to_tag = Vec::new();

    for path in file_index.keys() {
        if path.extension().map_or(false, |ext| ext == "rs") {
            if let Ok(source) = std::fs::read(path) {
                if let Some(mut parser) = get_parser(Language::Rust) {
                    if let Some(tree) = parser.parse(&source, None) {
                        let root_node = tree.root_node();
                        let query_str = r#"
                            (attribute_item
                              (attribute
                                [
                                  (identifier) @attr_name
                                  (scoped_identifier) @attr_name
                                ]
                                (token_tree
                                  _ @key
                                  (string_literal) @val)))
                        "#;
                        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::Rust);
                        if let Ok(query) = Query::new(&ts_lang, query_str) {
                            let mut cursor = QueryCursor::new();
                            let matches = cursor.matches(&query, root_node, source.as_slice());
                            for mat in matches {
                                let mut attr_name = String::new();
                                let mut key = String::new();
                                let mut val = String::new();

                                for cap in mat.captures {
                                    let cap_name = query.capture_names()[cap.index as usize];
                                    let node = cap.node;
                                    if cap_name == "attr_name" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            attr_name = text.trim().to_string();
                                        }
                                    } else if cap_name == "key" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            key = text.trim().to_string();
                                        }
                                    } else if cap_name == "val" {
                                        if let Ok(text) = node.utf8_text(&source) {
                                            val = text.trim().trim_matches('"').trim().to_string();
                                        }
                                    }
                                }

                                if attr_name == "serde" && (key == "default" || key == "with") && !val.is_empty() {
                                    callbacks_to_tag.push(val);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if !callbacks_to_tag.is_empty() {
        let intern = state.intern.read().unwrap();
        let mut graph = state.graph.write().unwrap();
        for callback_name in callbacks_to_tag {
            if let Some(name_key) = intern.get(&callback_name) {
                for node in graph.node_weights_mut() {
                    if node.name == name_key && node.language == Language::Rust {
                        if !node.tags.contains(&SymbolTag::SerdeCallback) {
                            node.tags.push(SymbolTag::SerdeCallback);
                        }
                    }
                }
            }
        }
    }
}

pub fn detect_entry_points(state: &AppState) {
    let mut graph = state.graph.write().unwrap();
    let intern = state.intern.read().unwrap();
    let mut count = 0;
    for node in graph.node_weights_mut() {
        let name = intern.resolve(&node.name);
        if name == "main" && node.kind == SymbolKind::Function {
            if !node.tags.contains(&SymbolTag::EntryPoint) {
                node.tags.push(SymbolTag::EntryPoint);
                crate::logging::log_verbose("analyzer", &format!("Tagged entry point: '{}' in '{}'", name, intern.resolve(&node.file)));
                count += 1;
            }
        }
    }
    if count > 0 {
        crate::logging::log_verbose("analyzer", &format!("Detected and tagged {} entry points", count));
    }
}

pub fn detect_test_linkages(state: &AppState) {
    let mut symbol_names = Vec::new();
    {
        let graph = state.graph.read().unwrap();
        let intern = state.intern.read().unwrap();
        for idx in graph.node_indices() {
            if let Some(node) = graph.node_weight(idx) {
                if node.kind == SymbolKind::Function {
                    let name = intern.resolve(&node.name).to_string();
                    let last_part = name.split('.').last().unwrap_or(&name).to_string();
                    if last_part.len() > 3 && last_part != "build" && last_part != "main" {
                        symbol_names.push((idx, name, last_part));
                    }
                }
            }
        }
    }

    let file_metadata = state.file_metadata.read().unwrap();
    let mut test_files_content = Vec::new();
    for (file_path, _) in file_metadata.iter() {
        let path_str = file_path.to_string_lossy();
        if path_str.contains(".dart_tool") || path_str.contains(".git") || path_str.contains(".pub-cache") || path_str.contains("build/") || path_str.contains("target/") {
            continue;
        }
        let file_name = file_path.file_name()
            .map(|n| n.to_string_lossy().to_lowercase())
            .unwrap_or_default();
        let is_test_file = file_name.contains("test") 
            || file_name.contains("spec") 
            || file_path.components().any(|c| c.as_os_str() == "test" || c.as_os_str() == "tests");
            
        if is_test_file {
            if let Ok(source) = std::fs::read(file_path) {
                if let Ok(text) = String::from_utf8(source) {
                    test_files_content.push(text);
                }
            }
        }
    }

    if test_files_content.is_empty() {
        crate::logging::log_verbose("analyzer", "No test files found; skipping test coverage linkage.");
        return;
    }

    let mut tested_count = 0;
    let mut graph = state.graph.write().unwrap();
    for (idx, full_name, last_part) in symbol_names {
        let mut is_tested = false;
        for content in &test_files_content {
            if content.contains(&full_name) || content.contains(&last_part) {
                is_tested = true;
                break;
            }
        }
        if is_tested {
            if let Some(node) = graph.node_weight_mut(idx) {
                if !node.tags.contains(&SymbolTag::Tested) {
                    node.tags.push(SymbolTag::Tested);
                    crate::logging::log_verbose("analyzer", &format!("Symbol '{}' is covered by tests", full_name));
                    tested_count += 1;
                }
            }
        }
    }
    crate::logging::log_verbose("analyzer", &format!("Completed test linkage checks. Tagged {} covered symbols", tested_count));
}

pub fn assign_tags(state: &AppState) {
    detect_test_linkages(state);
    let mut graph = state.graph.write().unwrap();
    let node_indices: Vec<_> = graph.node_indices().collect();
    let intern = state.intern.read().unwrap();

    let mut core_primitive_count = 0;
    let mut high_complexity_count = 0;
    let mut dead_code_count = 0;

    for idx in node_indices {
        let (in_degree, is_exempt, loc, complexity, name_str) = {
            if let Some(node) = graph.node_weight(idx) {
                let name = intern.resolve(&node.name);
                let file_path = intern.resolve(&node.file);
                let is_test = name.starts_with("test_")
                    || name.contains("_test")
                    || file_path.contains("/tests/")
                    || file_path.contains("\\tests\\")
                    || file_path.contains("/test/")
                    || file_path.contains("\\test\\")
                    || file_path.ends_with("_test.rs")
                    || file_path.ends_with("_test.dart")
                    || file_path.ends_with("_test.ts")
                    || file_path.ends_with("test.py");
                let exempt = node.tags.contains(&SymbolTag::ApiRoute)
                    || node.tags.contains(&SymbolTag::TraitMethod)
                    || node.tags.contains(&SymbolTag::EntryPoint)
                    || node.tags.contains(&SymbolTag::FrameworkInvoked)
                    || node.tags.contains(&SymbolTag::SerdeCallback)
                    || node.kind == SymbolKind::Class
                    || node.kind == SymbolKind::Enum
                    || node.kind == SymbolKind::Interface
                    || node.kind == SymbolKind::Struct
                    || node.kind == SymbolKind::Trait
                    || is_test;
                (node.in_degree, exempt, node.loc, node.complexity, name.to_string())
            } else {
                continue;
            }
        };

        if let Some(node) = graph.node_weight_mut(idx) {
            if in_degree > 10 && !node.tags.contains(&SymbolTag::CorePrimitive) {
                node.tags.push(SymbolTag::CorePrimitive);
                crate::logging::log_verbose("analyzer", &format!("Symbol '{}' is a CorePrimitive (in_degree = {})", name_str, in_degree));
                core_primitive_count += 1;
            }

            if (complexity > 20 || loc > 150) && !node.tags.contains(&SymbolTag::HighComplexity) {
                node.tags.push(SymbolTag::HighComplexity);
                crate::logging::log_verbose("analyzer", &format!("Symbol '{}' has HighComplexity (loc = {}, complexity = {})", name_str, loc, complexity));
                high_complexity_count += 1;
            }

            if in_degree == 0 && !is_exempt {
                if !node.tags.contains(&SymbolTag::PotentialDeadCode) {
                    node.tags.push(SymbolTag::PotentialDeadCode);
                    crate::logging::log_verbose("analyzer", &format!("Symbol '{}' is flagged as PotentialDeadCode (in_degree = 0, not exempt)", name_str));
                    dead_code_count += 1;
                }
            } else {
                node.tags.retain(|t| *t != SymbolTag::PotentialDeadCode);
            }
        }
    }

    crate::logging::log_verbose(
        "analyzer",
        &format!(
            "Tag assignment summary: {} CorePrimitives, {} HighComplexity, {} PotentialDeadCode",
            core_primitive_count,
            high_complexity_count,
            dead_code_count
        ),
    );
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::graph::store::{AppState, SymbolTag};
    use crate::parser::scanner::parse_and_index_file;
    use std::path::PathBuf;

    #[test]
    fn test_regression_hardening() {
        let state = AppState::new();

        let rust_code = r#"
            struct ChannelLogger;
            impl Logger for ChannelLogger {
                fn on_event(&self) {}
            }

            #[serde(default = "default_host")]
            struct Config {
                host: String,
            }

            fn default_host() -> String {
                "localhost".to_string()
            }

            fn main() {}
        "#;
        let rust_file = PathBuf::from("temp_test_rust.rs");
        std::fs::write(&rust_file, rust_code).unwrap();
        
        parse_and_index_file(&rust_file, &state);

        let dart_code = r#"
            class MyWidget extends StatelessWidget {
                @override
                Widget build(BuildContext context) {
                    return Container();
                }
            }
        "#;
        let dart_file = PathBuf::from("temp_test_dart.dart");
        std::fs::write(&dart_file, dart_code).unwrap();
        parse_and_index_file(&dart_file, &state);

        detect_trait_method_impls(&state);
        detect_framework_invoked(&state);
        detect_serde_callbacks(&state);
        detect_entry_points(&state);
        assign_tags(&state);

        {
            let graph = state.graph.read().unwrap();
            let intern = state.intern.read().unwrap();
            
            let mut found_on_event = false;
            let mut found_default_host = false;
            let mut found_main = false;
            let mut found_build = false;

            for node in graph.node_weights() {
                let name = intern.resolve(&node.name);
                if name == "ChannelLogger::on_event" {
                    found_on_event = true;
                    assert!(node.tags.contains(&SymbolTag::TraitMethod));
                    assert!(!node.tags.contains(&SymbolTag::PotentialDeadCode));
                } else if name == "default_host" {
                    found_default_host = true;
                    assert!(node.tags.contains(&SymbolTag::SerdeCallback));
                    assert!(!node.tags.contains(&SymbolTag::PotentialDeadCode));
                } else if name == "main" {
                    found_main = true;
                    assert!(node.tags.contains(&SymbolTag::EntryPoint));
                    assert!(!node.tags.contains(&SymbolTag::PotentialDeadCode));
                } else if name == "MyWidget.build" {
                    found_build = true;
                    assert!(node.tags.contains(&SymbolTag::FrameworkInvoked) || node.tags.contains(&SymbolTag::TraitMethod));
                    assert!(!node.tags.contains(&SymbolTag::PotentialDeadCode));
                }
            }

            assert!(found_on_event, "Should find ChannelLogger::on_event");
            assert!(found_default_host, "Should find default_host");
            assert!(found_main, "Should find main");
            assert!(found_build, "Should find MyWidget.build");
        }

        let _ = std::fs::remove_file(rust_file);
        let _ = std::fs::remove_file(dart_file);
    }
}
