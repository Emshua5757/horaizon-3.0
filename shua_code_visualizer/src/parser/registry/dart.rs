use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

extern "C" {
    fn tree_sitter_dart_orchard() -> *const tree_sitter::ffi::TSLanguage;
}

pub struct DartExtractor;

/// Resolves full qualified symbol name (e.g. `UserWidget.renderUser`) by traversing class/mixin ancestors
fn resolve_dart_qualified_name(node: Node, code: &str) -> String {
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
        if p.kind() == "class_definition" || p.kind() == "mixin_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for DartExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let _ = tree_sitter_dart_orchard::LANGUAGE;
        let language = unsafe { tree_sitter::Language::from_raw(tree_sitter_dart_orchard()) };

        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (class_definition
              name: (identifier) @name) @class
            (mixin_declaration
              name: (identifier) @name) @class
            (extension_declaration
              name: (identifier) @name) @class
            (enum_declaration
              name: (identifier) @name) @enum
            (method_signature
              (function_signature name: (identifier) @name)) @fn
            (method_signature
              (constructor_signature name: (identifier) @name)) @fn
            (function_signature
              name: (identifier) @name) @fn
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
            let mut is_public = true;
            let mut is_test = file_path.contains("_test.dart") || file_path.contains("/test/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_dart_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    is_public = !name.split('.').last().unwrap_or("").starts_with('_');
                    if name == "main" {
                        is_test = false;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let mut target_node = node;
                    if kind == GraphNodeKind::Function {
                        let mut curr = node;
                        while let Some(p) = curr.parent() {
                            if p.kind() == "class_definition" || p.kind() == "program" {
                                break;
                            }
                            target_node = p;
                            curr = p;
                        }
                    }

                    let range = target_node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = target_node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), target_node);

                        if let Some(ret_child) = target_node.child_by_field_name("type") {
                            if let Ok(ret_text) = ret_child.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(formal_params) = target_node.child_by_field_name("parameters") {
                            let mut p_cursor = formal_params.walk();
                            for p_child in formal_params.children(&mut p_cursor) {
                                if p_child.kind() == "formal_parameter" || p_child.kind() == "simple_formal_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts.last().unwrap().to_string(), parts[0..parts.len() - 1].join(" "))
                                        } else {
                                            (p_text.to_string(), "dynamic".to_string())
                                        };

                                        let is_optional = p_text.contains('?') || p_text.contains('{') || p_text.contains('[');
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = target_node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "documentation_comment" || prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
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

        // Extract Dart call site edges by matching AST call identifiers to enclosing line ranges
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (identifier) @callee
            (import_or_export) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        let line = node.range().start_point.row as u32 + 1;
                        if let Some(caller_sym) = symbols.iter().find(|s| line >= s.line && line <= s.line + s.loc) {
                            if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                                let callee_clean = callee_text.trim().to_string();
                                if !callee_clean.is_empty()
                                    && caller_sym.qualified_name != callee_clean
                                    && !caller_sym.qualified_name.ends_with(&format!(".{}", callee_clean))
                                    && callee_clean.chars().next().map_or(false, |c| c.is_alphabetic() || c == '_')
                                    && !["if", "else", "for", "while", "return", "var", "final", "const", "super", "this", "true", "false", "null", "dynamic", "void", "int", "double", "String", "bool", "List", "Map", "Set"].contains(&callee_clean.as_str())
                                {
                                    let edge = ExtractedEdge {
                                        from: caller_sym.qualified_name.clone(),
                                        to: callee_clean,
                                        relation: Relation::Calls,
                                    };
                                    if edge_set.insert(edge.clone()) {
                                        edges.push(edge);
                                    }
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
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
