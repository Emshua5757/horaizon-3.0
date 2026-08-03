use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct TypeScriptExtractor;

/// Resolves full qualified symbol name (e.g. `ApiClient.fetchData`) by traversing class/interface ancestors
fn resolve_typescript_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_declaration" || p.kind() == "interface_declaration" {
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

impl LanguageExtractor for TypeScriptExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_typescript::language_typescript();
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
            (method_definition
              name: (property_identifier) @name) @fn
            (class_declaration
              name: (type_identifier) @name) @class
            (interface_declaration
              name: (type_identifier) @name) @interface
            (type_alias_declaration
              name: (type_identifier) @name) @type_alias
            (enum_declaration
              name: (identifier) @name) @enum
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
            let mut is_test = file_path.contains(".test.")
                || file_path.contains(".spec.")
                || file_path.contains("/__tests__/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_typescript_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.rsplit('.').next().unwrap_or("");
                    if last_segment == "it"
                        || last_segment == "test"
                        || last_segment.starts_with("test")
                    {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "interface" => GraphNodeKind::Interface,
                        "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public =
                            text.trim().starts_with("export") || text.trim().starts_with("public");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "required_parameter"
                                    || p_child.kind() == "optional_parameter"
                                {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let is_optional = p_child.kind() == "optional_parameter"
                                            || p_text.contains('?');
                                        let parts: Vec<&str> = p_text.split(':').collect();
                                        let p_name = parts[0].trim_matches('?').trim().to_string();
                                        let p_type = if parts.len() > 1 {
                                            parts[1].trim().to_string()
                                        } else {
                                            "any".to_string()
                                        };

                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type =
                                    Some(ret_text.trim_start_matches(':').trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim()
                                        .lines()
                                        .map(|l| l.trim().trim_start_matches('*').trim())
                                        .filter(|l| !l.is_empty() && !l.starts_with('@'))
                                        .collect::<Vec<&str>>()
                                        .join(" ");
                                    if !clean.is_empty() {
                                        doc_lines.push(clean);
                                    }
                                }
                            }
                        } else if prev.kind() != "export_specifier" {
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
              function: (_) @callee) @call_stmt
            (import_statement) @import
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
                                if p.kind() == "function_declaration"
                                    || p.kind() == "method_definition"
                                {
                                    caller_qualified = resolve_typescript_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty()
                                && !callee_text.is_empty()
                                && caller_qualified != callee_text
                            {
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
