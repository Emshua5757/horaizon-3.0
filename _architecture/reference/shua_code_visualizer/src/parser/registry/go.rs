use std::path::Path;
use tree_sitter::{Query, QueryCursor};
use crate::graph::store::{SymbolNode, SymbolKind, Visibility, Language, AppState};
use crate::parser::ast::get_parser;
use super::{DeclarationExtractor, compute_cyclomatic_complexity, infer_side_effects};

pub struct GoExtractor;

impl DeclarationExtractor for GoExtractor {
    fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode> {
        let mut parser = match get_parser(Language::Go) {
            Some(p) => p,
            None => return Vec::new(),
        };

        let tree = match parser.parse(source, None) {
            Some(t) => t,
            None => return Vec::new(),
        };

        let query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_declaration
              receiver: (parameter_list
                (parameter_declaration
                  type: [
                    (pointer_type (type_identifier) @receiver_type)
                    (type_identifier) @receiver_type
                  ]))
              name: (field_identifier) @name) @method
            (type_spec
              name: (type_identifier) @name
              type: (struct_type)) @struct
            (type_spec
              name: (type_identifier) @name
              type: (interface_type)) @interface
        "#;

        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::Go);
        let query = match Query::new(&ts_lang, query_str) {
            Ok(q) => q,
            Err(_) => return Vec::new(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), source);
        let mut symbols = Vec::new();
        let content_hash = xxhash_rust::xxh64::xxh64(source, 0);

        for mat in matches {
            let mut symbol_name = String::new();
            let mut receiver_name = String::new();
            let mut kind = SymbolKind::Function;
            let mut line_start = 0;
            let mut line_end = 0;
            let mut complexity = 1;
            let mut signature = String::new();
            let mut visibility = Visibility::Private;
            let mut fn_text = String::new();
            let mut main_node = None;

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                match cap_name {
                    "name" => {
                        if let Ok(text) = node.utf8_text(source) {
                            symbol_name = text.to_string();
                        }
                    }
                    "receiver_type" => {
                        if let Ok(text) = node.utf8_text(source) {
                            receiver_name = text.to_string();
                        }
                    }
                    "fn" | "method" | "struct" | "interface" => {
                        main_node = Some(node);
                        kind = match cap_name {
                            "struct" => SymbolKind::Struct,
                            "interface" => SymbolKind::Interface,
                            _ => SymbolKind::Function,
                        };
                        let range = node.range();
                        line_start = range.start_point.row as u32;
                        line_end = range.end_point.row as u32;
                    }
                    _ => {}
                }
            }

            if let Some(node) = main_node {
                // If it is a method, prefix name with receiver type (e.g. ResumeHandler.Compile)
                if !receiver_name.is_empty() && kind == SymbolKind::Function {
                    symbol_name = format!("{}.{}", receiver_name, symbol_name);
                }

                if kind == SymbolKind::Function {
                    complexity = compute_cyclomatic_complexity(source, Language::Go, node);
                }

                if let Ok(text) = node.utf8_text(source) {
                    let first_line = text.lines().next().unwrap_or("").trim_end();
                    signature = if first_line.ends_with('{') {
                        first_line.trim_end_matches('{').trim().to_string()
                    } else {
                        first_line.to_string()
                    };

                    fn_text = text.to_string();
                }

                // Go visibility is determined by capitalized first character of name
                // (Methods are qualified, check the actual method name part after the dot)
                let name_to_check = if symbol_name.contains('.') {
                    symbol_name.split('.').last().unwrap_or(&symbol_name)
                } else {
                    &symbol_name
                };

                if let Some(first_char) = name_to_check.chars().next() {
                    if first_char.is_uppercase() {
                        visibility = Visibility::Public;
                    }
                }

                if !symbol_name.is_empty() {
                    let mut intern = state.intern.write().unwrap();
                    let name_key = intern.get_or_intern(&symbol_name);
                    let file_key = intern.get_or_intern(file.to_string_lossy().as_ref());
                    let id_key = intern.get_or_intern(format!("{}:{}", file.to_string_lossy(), symbol_name));

                    let mut tags = Vec::new();
                    if kind == SymbolKind::Function && !fn_text.is_empty() {
                        tags.extend(infer_side_effects(&fn_text, Language::Go));
                    }

                    symbols.push(SymbolNode {
                        id: id_key,
                        name: name_key,
                        file: file_key,
                        kind,
                        line_start,
                        line_end,
                        loc: line_end.saturating_sub(line_start) + 1,
                        complexity,
                        visibility,
                        signature,
                        in_degree: 0,
                        out_degree: 0,
                        is_cycle: false,
                        tags,
                        language: Language::Go,
                        content_hash,
                    });
                }
            }
        }

        symbols
    }
}
