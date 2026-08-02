pub mod dart;
pub mod go;
pub mod python;
pub mod rust;
pub mod typescript;

use crate::mcp::schema::SideEffect;
use tree_sitter::Node;

/// Computes cyclomatic complexity of an AST node by counting decision branches
pub fn compute_cyclomatic_complexity(source: &[u8], root: Node) -> u32 {
    let mut complexity = 1;

    let branch_kinds = [
        "if_statement",
        "if_expression",
        "elif_clause",
        "match_arm",
        "case_statement",
        "case_clause",
        "expression_case",
        "type_case_clause",
        "for_statement",
        "for_expression",
        "for_in_clause",
        "while_statement",
        "while_expression",
        "binary_expression",
        "boolean_operator",
    ];

    let function_scope_kinds = [
        "function_item",
        "function_definition",
        "method_definition",
        "arrow_function",
        "closure_expression",
    ];

    let mut stack = vec![root];
    let mut is_root = true;

    while let Some(current) = stack.pop() {
        let kind = current.kind();

        // Avoid entering nested functions/closures so their complexity isn't double-counted
        if !is_root && function_scope_kinds.contains(&kind) {
            continue;
        }
        is_root = false;

        if branch_kinds.contains(&kind) {
            if kind == "binary_expression" || kind == "boolean_operator" {
                if let Some(op_node) = current.child_by_field_name("operator") {
                    if let Ok(op_text) = op_node.utf8_text(source) {
                        let op = op_text.trim();
                        if op == "&&" || op == "||" || op == "and" || op == "or" {
                            complexity += 1;
                        }
                    }
                }
            } else {
                complexity += 1;
            }
        }

        let mut cursor = current.walk();
        for child in current.children(&mut cursor) {
            stack.push(child);
        }
    }

    complexity
}

/// Infers side effects (IO, Network, Lock, StateMutation) from symbol text body
pub fn infer_side_effects(code: &str) -> Vec<SideEffect> {
    let mut effects = Vec::new();

    if code.contains("std::fs")
        || code.contains("File::")
        || code.contains("write!")
        || code.contains("println!")
        || code.contains("File.")
        || code.contains("print(")
    {
        effects.push(SideEffect::Io);
    }

    if code.contains("http://")
        || code.contains("https://")
        || code.contains("reqwest")
        || code.contains("TcpStream")
        || code.contains("WebSocket")
        || code.contains("fetch(")
    {
        effects.push(SideEffect::Network);
    }

    if code.contains("Mutex")
        || code.contains("RwLock")
        || code.contains(".lock()")
        || code.contains(".read()")
        || code.contains(".write()")
    {
        effects.push(SideEffect::Lock);
    }

    if code.contains("&mut ")
        || code.contains("self.")
        || code.contains("setState")
        || code.contains("this.")
    {
        effects.push(SideEffect::StateMutation);
    }

    effects.dedup();
    effects
}
