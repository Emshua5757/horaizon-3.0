use std::path::Path;
pub use crate::graph::store::{SymbolNode, SymbolKind, Visibility, Language, AppState, SymbolTag};

pub mod rust;
pub mod typescript;
pub mod python;
pub mod dart;
pub mod go;

use rust::RustExtractor;
use typescript::TypeScriptExtractor;
use python::PythonExtractor;
use dart::DartExtractor;
use go::GoExtractor;

pub fn extract_declarations(
    file: &Path,
    source: &[u8],
    lang: Language,
    state: &AppState,
) -> Vec<SymbolNode> {
    crate::logging::log_verbose("registry", &format!("Starting declaration extraction for '{}' (language: {:?})", file.display(), lang));
    let extractor: Box<dyn DeclarationExtractor> = match lang {
        Language::Rust => Box::new(RustExtractor),
        Language::TypeScript => Box::new(TypeScriptExtractor),
        Language::Python => Box::new(PythonExtractor),
        Language::Dart => Box::new(DartExtractor),
        Language::Go => Box::new(GoExtractor),
    };
    let symbols = extractor.extract(file, source, state);
    
    crate::logging::log_verbose("registry", &format!("Completed extraction for '{}'. Found {} symbols:", file.display(), symbols.len()));
    {
        let intern = state.intern.read().unwrap();
        for sym in &symbols {
            let name_str = intern.resolve(&sym.name);
            crate::logging::log_verbose(
                "registry",
                &format!(
                    "  Symbol: '{}' ({:?}) | lines {}-{} | LOC: {} | Complexity: {} | tags: {:?}",
                    name_str, sym.kind, sym.line_start, sym.line_end, sym.loc, sym.complexity, sym.tags
                ),
            );
        }
    }
    symbols
}

trait DeclarationExtractor {
    fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>;
}

fn compute_cyclomatic_complexity(source: &[u8], lang: Language, node: tree_sitter::Node) -> u32 {
    let mut count = 0;
    
    fn walk(node: tree_sitter::Node, lang: Language, source: &[u8], count: &mut u32) {
        let kind = node.kind();
        let mut increment = false;
        
        match lang {
            Language::Rust => {
                if matches!(
                    kind,
                    "if_expression"
                        | "for_expression"
                        | "while_expression"
                        | "loop_expression"
                        | "match_arm"
                        | "try_expression"
                ) {
                    increment = true;
                }
            }
            Language::TypeScript => {
                if matches!(
                    kind,
                    "if_statement"
                        | "for_statement"
                        | "for_in_statement"
                        | "while_statement"
                        | "do_statement"
                        | "switch_case"
                ) {
                    increment = true;
                } else if kind == "binary_expression" {
                    if let Some(op_node) = node.child_by_field_name("operator") {
                        if let Ok(op_text) = op_node.utf8_text(source) {
                            if op_text == "&&" || op_text == "||" || op_text == "??" {
                                increment = true;
                            }
                        }
                    }
                }
            }
            Language::Python => {
                if matches!(kind, "if_statement" | "for_statement" | "while_statement" | "except_clause") {
                    increment = true;
                } else if kind == "elif_clause" {
                    increment = true;
                }
            }
            Language::Dart => {
                if matches!(
                    kind,
                    "if_statement"
                        | "for_statement"
                        | "while_statement"
                        | "switch_case"
                        | "catch_clause"
                ) {
                    increment = true;
                }
            }
            Language::Go => {
                if matches!(
                    kind,
                    "if_statement"
                        | "for_statement"
                        | "expression_case"
                        | "communication_case"
                ) {
                    increment = true;
                } else if kind == "binary_expression" {
                    if let Some(op_node) = node.child_by_field_name("operator") {
                        if let Ok(op_text) = op_node.utf8_text(source) {
                            if op_text == "&&" || op_text == "||" {
                                increment = true;
                            }
                        }
                    }
                }
            }
        }
        
        if increment {
            *count += 1;
        }
        
        let mut cursor = node.walk();
        for child in node.children(&mut cursor) {
            walk(child, lang, source, count);
        }
    }
    
    walk(node, lang, source, &mut count);
    1 + count
}

fn infer_side_effects(source_text: &str, language: Language) -> Vec<SymbolTag> {
    let mut tags = Vec::new();
    
    // 1. Async check (goroutines, channels, promises)
    if source_text.contains("async") || source_text.contains(".await") || source_text.contains("Promise<") || source_text.contains("go ") || source_text.contains("chan ") || source_text.contains("<-") {
        tags.push(SymbolTag::Async);
    }
    
    // 2. Mutates State check
    let mut mutates = false;
    match language {
        Language::Rust => {
            if source_text.contains("&mut self") || source_text.contains("mut ") {
                mutates = true;
            }
        }
        Language::TypeScript => {
            if source_text.contains("this.") && (source_text.contains(" = ") || source_text.contains("++") || source_text.contains("--") || source_text.contains(".push(")) {
                mutates = true;
            }
        }
        Language::Dart => {
            if source_text.contains("setState(") || (source_text.contains("this.") && (source_text.contains(" = ") || source_text.contains("++"))) {
                mutates = true;
            }
        }
        Language::Python => {
            if source_text.contains("self.") && (source_text.contains(" = ") || source_text.contains("+=") || source_text.contains(".append(")) {
                mutates = true;
            }
            if source_text.contains("global ") || source_text.contains("nonlocal ") {
                mutates = true;
            }
        }
        Language::Go => {
            if (source_text.contains("func (") && source_text.contains("*")) || source_text.contains(" = ") {
                mutates = true;
            }
        }
    }
    if mutates {
        tags.push(SymbolTag::MutatesState);
    }
    
    // 3. I/O check
    let io_keywords = &[
        "std::fs", "std::io", "File::", "read_to_string", "write_all", "println!", "print!",
        "console.log", "logger.", "console.error", "console.warn", "fetch(", "http", "socket",
        "print(", "gLog.", "socketManager.", "sqlite", "conn.execute", "sql!", "db."
    ];
    if io_keywords.iter().any(|&kw| source_text.contains(kw)) {
        tags.push(SymbolTag::Io);
    }
    
    // 4. Panic/Throw check
    if source_text.contains("panic!") || source_text.contains("panic(") || source_text.contains("assert!") || source_text.contains("throw ") || source_text.contains(".unwrap()") || source_text.contains(".expect(") || source_text.contains("raise ") {
        tags.push(SymbolTag::CanPanic);
    }
    
    // 5. Purity check
    if !mutates && !tags.contains(&SymbolTag::Io) && !tags.contains(&SymbolTag::CanPanic) {
        tags.push(SymbolTag::Pure);
    }
    
    tags
}
