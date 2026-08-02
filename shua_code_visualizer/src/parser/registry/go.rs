use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct GoExtractor;

/// Resolves full qualified symbol name (e.g. `Server.Start`) by checking Go receiver type
fn resolve_go_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "method_declaration" {
            if let Some(receiver) = p.child_by_field_name("receiver") {
                if let Ok(recv_text) = receiver.utf8_text(code.as_bytes()) {
                    let clean_recv = recv_text
                        .split_whitespace()
                        .last()
                        .unwrap_or("")
                        .trim_matches(|c| c == '(' || c == ')' || c == '*' || c == '&');
                    if !clean_recv.is_empty() {
                        return format!("{}.{}", clean_recv, name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for GoExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_go::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_declaration
              name: (field_identifier) @name) @fn
            (type_spec
              name: (type_identifier) @name) @type_def
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
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
            let mut is_test = file_path.ends_with("_test.go");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_go_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    if let Some(first_char) = last_segment.chars().next() {
                        is_public = first_char.is_uppercase();
                    }
                    if last_segment.starts_with("Test") || last_segment.starts_with("Benchmark") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "type_def" => {
                            if let Ok(text) = node.utf8_text(code.as_bytes()) {
                                if text.contains("interface") {
                                    GraphNodeKind::Interface
                                } else {
                                    GraphNodeKind::Struct
                                }
                            } else {
                                GraphNodeKind::Struct
                            }
                        }
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "parameter_declaration" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts[0].to_string(), parts[1..].join(" "))
                                        } else {
                                            (p_text.to_string(), "interface{}".to_string())
                                        };
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(result_node) = node.child_by_field_name("result") {
                            if let Ok(ret_text) = result_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                let clean = comment_text.trim().trim_start_matches("//").trim();
                                doc_lines.push(clean.to_string());
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
            (import_spec) @import
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
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration" || p.kind() == "method_declaration" {
                                    caller_qualified = resolve_go_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim_matches('"').trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
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
