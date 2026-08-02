use std::path::PathBuf;
use std::collections::HashSet;
use tree_sitter::{Query, QueryCursor};
pub use crate::graph::store::{AppState, InternKey, SymbolTag, Language};
use crate::parser::ast::detect_language;

#[derive(Debug, Clone, serde::Serialize)]
pub enum HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    UNKNOWN,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct RouteNode {
    pub method: HttpMethod,
    pub path: String,
    pub handler_symbol: InternKey,
    pub file: PathBuf,
}

pub fn extract_api_routes(state: &AppState) -> Vec<RouteNode> {
    let file_metadata = state.file_metadata.read().unwrap();
    let mut routes = Vec::new();
    let mut handler_names = HashSet::new();

    for (file_path, _) in file_metadata.iter() {
        let lang = match detect_language(file_path) {
            Some(l) => l,
            None => continue,
        };

        let source = match std::fs::read(file_path) {
            Ok(s) => s,
            Err(_) => continue,
        };

        let mut parser = match crate::parser::ast::get_parser(lang) {
            Some(p) => p,
            None => continue,
        };

        let tree = match parser.parse(&source, None) {
            Some(t) => t,
            None => continue,
        };

        let root_node = tree.root_node();

        if lang == Language::Rust {
            let query_str = r#"
                (call_expression
                  function: (field_expression
                    field: (field_identifier) @method_field)
                  arguments: (arguments
                    (string_literal) @path
                    (call_expression
                      arguments: (arguments
                        [
                          (identifier) @handler
                          (scoped_identifier) @handler
                        ]
                      ))
                  ))
            "#;

            let ts_lang = tree_sitter_rust::language();
            if let Ok(query) = Query::new(&ts_lang, query_str) {
                let mut cursor = QueryCursor::new();
                let matches = cursor.matches(&query, root_node, source.as_slice());

                for mat in matches {
                    let mut path = String::new();
                    let mut is_route = false;
                    let mut handler_name = String::new();

                    for cap in mat.captures {
                        let cap_name = query.capture_names()[cap.index as usize];
                        let node = cap.node;

                        if cap_name == "method_field" {
                            if let Ok(text) = node.utf8_text(source.as_slice()) {
                                if text == "route" {
                                    is_route = true;
                                }
                            }
                        } else if cap_name == "path" {
                            if let Ok(text) = node.utf8_text(source.as_slice()) {
                                path = text.trim_matches('"').to_string();
                            }
                        } else if cap_name == "handler" {
                            if let Ok(text) = node.utf8_text(source.as_slice()) {
                                handler_name = text.split("::").last().unwrap_or(text).to_string();
                            }
                        }
                    }

                    if is_route && !path.is_empty() {
                        let mut intern = state.intern.write().unwrap();
                        let handler_key = intern.get_or_intern(&handler_name);
                        handler_names.insert(handler_name.clone());
                        routes.push(RouteNode {
                            method: HttpMethod::GET,
                            path,
                            handler_symbol: handler_key,
                            file: file_path.clone(),
                        });
                    }
                }
            }
        }

        if lang == Language::TypeScript {
            let query_str = r#"
                (method_definition
                  (decorator
                    name: (identifier) @method
                    arguments: (arguments (string_literal) @path))
                  name: (property_identifier) @handler)
            "#;

            let ts_lang = tree_sitter_typescript::language_typescript();
            if let Ok(query) = Query::new(&ts_lang, query_str) {
                let mut cursor = QueryCursor::new();
                let matches = cursor.matches(&query, root_node, source.as_slice());

                for mat in matches {
                    let mut method_str = String::new();
                    let mut path = String::new();
                    let mut handler_name = String::new();

                    for cap in mat.captures {
                        let cap_name = query.capture_names()[cap.index as usize];
                        let node = cap.node;

                        if cap_name == "method" {
                            if let Ok(text) = node.utf8_text(source.as_slice()) {
                                method_str = text.to_string();
                            }
                        } else if cap_name == "path" {
                            if let Ok(text) = node.utf8_text(source.as_slice()) {
                                path = text.trim_matches(|c| c == '\'' || c == '"').to_string();
                            }
                        } else if cap_name == "handler" {
                            if let Ok(text) = node.utf8_text(source.as_slice()) {
                                handler_name = text.to_string();
                            }
                        }
                    }

                    let method = match method_str.as_str() {
                        "Get" => HttpMethod::GET,
                        "Post" => HttpMethod::POST,
                        "Put" => HttpMethod::PUT,
                        "Delete" => HttpMethod::DELETE,
                        "Patch" => HttpMethod::PATCH,
                        _ => HttpMethod::UNKNOWN,
                    };

                    if !matches!(method, HttpMethod::UNKNOWN) && !path.is_empty() {
                        let mut intern = state.intern.write().unwrap();
                        let handler_key = intern.get_or_intern(&handler_name);
                        handler_names.insert(handler_name.clone());
                        routes.push(RouteNode {
                            method,
                            path,
                            handler_symbol: handler_key,
                            file: file_path.clone(),
                        });
                    }
                }
            }
        }
    }

    let mut graph = state.graph.write().unwrap();
    let intern = state.intern.read().unwrap();
    for node_idx in graph.node_indices() {
        if let Some(node) = graph.node_weight_mut(node_idx) {
            let symbol_name = intern.resolve(&node.name);
            let clean_name = symbol_name.split('.').last().unwrap_or(symbol_name);
            let clean_name = clean_name.split("::").last().unwrap_or(clean_name);
            if handler_names.contains(clean_name) {
                if !node.tags.contains(&SymbolTag::ApiRoute) {
                    node.tags.push(SymbolTag::ApiRoute);
                }
            }
        }
    }

    routes
}
