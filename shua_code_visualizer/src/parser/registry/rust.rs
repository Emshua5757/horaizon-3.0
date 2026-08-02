use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct RustExtractor;

/// Resolves full qualified symbol name (e.g. `core::service::Worker::run`) by traversing mod & impl ancestors
fn resolve_rust_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut prefixes = Vec::new();
    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "impl_item" {
            if let Some(type_node) = p.child_by_field_name("type") {
                if let Ok(type_name) = type_node.utf8_text(code.as_bytes()) {
                    let clean_type = type_name.split('<').next().unwrap_or("").trim();
                    prefixes.push(clean_type.to_string());
                }
            }
        } else if p.kind() == "mod_item" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(mod_name) = name_node.utf8_text(code.as_bytes()) {
                        prefixes.push(mod_name.trim().to_string());
                    }
                }
            }
        }
        parent = p.parent();
    }

    prefixes.reverse();
    if prefixes.is_empty() {
        name
    } else {
        format!("{}::{}", prefixes.join("::"), name)
    }
}

impl LanguageExtractor for RustExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_rust::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_item
              name: (identifier) @name) @fn
            (struct_item
              name: (type_identifier) @name) @struct
            (enum_item
              name: (type_identifier) @name) @enum
            (trait_item
              name: (type_identifier) @name) @trait
            (type_item
              name: (type_identifier) @name) @type_alias
            (mod_item
              name: (identifier) @name) @module
            (macro_definition
              name: (identifier) @name) @macro
        "#;

        let decl_query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&decl_query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = false;

            for cap in mat.captures {
                let cap_name = decl_query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_rust_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    if name.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "struct" | "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        "trait" => GraphNodeKind::Trait,
                        "module" | "macro" => GraphNodeKind::Module,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public = text.trim().starts_with("pub");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(params_node) = node.child_by_field_name("parameters") {
                            let mut p_cursor = params_node.walk();
                            for p_child in params_node.children(&mut p_cursor) {
                                if p_child.kind() == "parameter" {
                                    let raw_pattern = p_child
                                        .child_by_field_name("pattern")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("param");
                                    let p_name = raw_pattern.trim_start_matches("mut ").trim().to_string();
                                    let p_type = p_child
                                        .child_by_field_name("type")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("impl Any")
                                        .to_string();
                                    let is_optional = p_type.contains("Option");

                                    params.push(ParamDto {
                                        name: p_name,
                                        type_name: p_type,
                                        is_optional,
                                    });
                                } else if p_child.kind() == "self_parameter" {
                                    if let Ok(self_text) = p_child.utf8_text(code.as_bytes()) {
                                        params.push(ParamDto {
                                            name: "self".to_string(),
                                            type_name: self_text.to_string(),
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim_start_matches("->").trim().to_string());
                            }
                        }
                    }

                    // Extract doc comments & preceding `#[test]` attributes
                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "attribute_item" {
                            if let Ok(attr_text) = prev.utf8_text(code.as_bytes()) {
                                if attr_text.contains("test") {
                                    is_test = true;
                                }
                            }
                        } else if prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else if prev.kind() == "block_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (use_declaration) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let callee_clean = callee_text.split('(').next().unwrap_or("").trim().to_string();

                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_item" {
                                    caller_qualified = resolve_rust_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_clean.is_empty() && caller_qualified != callee_clean {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_clean,
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean_import = import_text
                                .trim_start_matches("use ")
                                .trim_end_matches(';')
                                .trim()
                                .to_string();
                            if !clean_import.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean_import,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}
