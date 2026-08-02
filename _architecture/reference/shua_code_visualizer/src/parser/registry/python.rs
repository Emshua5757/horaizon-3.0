use std::path::Path;
use tree_sitter::{Query, QueryCursor};
use crate::graph::store::{SymbolNode, SymbolKind, Visibility, Language, AppState};
use crate::parser::ast::get_parser;
use super::{DeclarationExtractor, compute_cyclomatic_complexity, infer_side_effects};

pub struct PythonExtractor;

impl DeclarationExtractor for PythonExtractor {
    fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode> {
        let mut parser = match get_parser(Language::Python) {
            Some(p) => p,
            None => return Vec::new(),
        };

        let tree = match parser.parse(source, None) {
            Some(t) => t,
            None => return Vec::new(),
        };

        let query_str = r#"
            (function_definition
              name: (identifier) @name) @fn
            (class_definition
              name: (identifier) @name) @class
        "#;

        let ts_lang = crate::parser::ast::get_tree_sitter_language(Language::Python);
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
            let mut kind = SymbolKind::Function;
            let mut line_start = 0;
            let mut line_end = 0;
            let mut complexity = 1;
            let mut signature = String::new();
            let mut visibility = Visibility::Private;
            let mut fn_text = String::new();

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Ok(text) = node.utf8_text(source) {
                        let mut qualified_name = text.to_string();
                        let mut parent = node.parent();
                        while let Some(p) = parent {
                            if p.kind() == "class_definition" {
                                if let Some(name_node) = p.child_by_field_name("name") {
                                    if name_node.id() != node.id() {
                                        if let Ok(class_name) = name_node.utf8_text(source) {
                                            qualified_name = format!("{}.{}", class_name.trim(), qualified_name);
                                        }
                                    }
                                }
                                break;
                            }
                            parent = p.parent();
                        }
                        symbol_name = qualified_name;
                    }
                } else {
                    kind = match cap_name {
                        "class" => SymbolKind::Class,
                        _ => SymbolKind::Function,
                    };

                    let range = node.range();
                    line_start = range.start_point.row as u32;
                    line_end = range.end_point.row as u32;

                    if kind == SymbolKind::Function {
                        complexity = compute_cyclomatic_complexity(source, Language::Python, node);
                    }

                    if let Ok(text) = node.utf8_text(source) {
                        let first_line = text.lines().next().unwrap_or("").trim_end();
                        signature = if first_line.ends_with(':') {
                            first_line.trim_end_matches(':').trim().to_string()
                        } else {
                            first_line.to_string()
                        };
                        if kind == SymbolKind::Function {
                            fn_text = text.to_string();
                        }
                    }
                }
            }

            if !symbol_name.is_empty() {
                if !symbol_name.starts_with('_') {
                    visibility = Visibility::Public;
                }

                let mut intern = state.intern.write().unwrap();
                let name_key = intern.get_or_intern(&symbol_name);
                let file_key = intern.get_or_intern(file.to_string_lossy().as_ref());
                let id_key = intern.get_or_intern(format!("{}:{}", file.to_string_lossy(), symbol_name));

                let mut tags = Vec::new();
                if kind == SymbolKind::Function && !fn_text.is_empty() {
                    tags.extend(infer_side_effects(&fn_text, Language::Python));
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
                    language: Language::Python,
                    content_hash,
                });
            }
        }
        symbols
    }
}
