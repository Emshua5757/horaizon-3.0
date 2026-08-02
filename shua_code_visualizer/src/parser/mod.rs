pub mod extractor;
pub mod registry;

use extractor::{LanguageExtractor, ParseResult};
use registry::dart::DartExtractor;
use registry::go::GoExtractor;
use registry::python::PythonExtractor;
use registry::rust::RustExtractor;
use registry::typescript::TypeScriptExtractor;

/// Supported target programming languages
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Language {
    Rust,
    Dart,
    Go,
    Python,
    TypeScript,
}

impl Language {
    /// Detects programming language from file extension
    pub fn from_file_path(path: &str) -> Option<Self> {
        if path.ends_with(".rs") {
            Some(Language::Rust)
        } else if path.ends_with(".dart") {
            Some(Language::Dart)
        } else if path.ends_with(".go") {
            Some(Language::Go)
        } else if path.ends_with(".py") {
            Some(Language::Python)
        } else if path.ends_with(".ts") || path.ends_with(".tsx") {
            Some(Language::TypeScript)
        } else {
            None
        }
    }
}

/// Parses a source code file using the matching Tree-sitter language extractor
pub fn parse_file(code: &str, file_path: &str, lang: Option<Language>) -> ParseResult {
    let language = lang.or_else(|| Language::from_file_path(file_path));

    match language {
        Some(Language::Rust) => RustExtractor.parse(code, file_path),
        Some(Language::Dart) => DartExtractor.parse(code, file_path),
        Some(Language::Go) => GoExtractor.parse(code, file_path),
        Some(Language::Python) => PythonExtractor.parse(code, file_path),
        Some(Language::TypeScript) => TypeScriptExtractor.parse(code, file_path),
        None => ParseResult::default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation, SideEffect};

    #[test]
    fn test_rust_parser_extraction() {
        let rust_code = r#"
            /// Calculate total price with tax
            pub fn calculate_total(price: f64, tax: f64) -> f64 {
                if price > 0.0 {
                    println!("Calculating...");
                    price + (price * tax)
                } else {
                    0.0
                }
            }

            struct OrderService;

            impl OrderService {
                pub fn process_order(&mut self, id: u32) {
                    calculate_total(10.0, 0.1);
                }
            }
        "#;

        let result = parse_file(rust_code, "src/orders.rs", Some(Language::Rust));
        assert_eq!(result.symbols.len(), 3);

        let calc_fn = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "calculate_total")
            .expect("calculate_total function not found");

        assert_eq!(calc_fn.kind, GraphNodeKind::Function);
        assert_eq!(calc_fn.complexity, 2);
        assert_eq!(calc_fn.intent, Some("Calculate total price with tax".to_string()));
        assert!(calc_fn.side_effects.contains(&SideEffect::Io));
        assert!(calc_fn.is_public);
        assert_eq!(calc_fn.params.len(), 2);

        // Verify call edge extraction has FULLY QUALIFIED caller name
        let call_edge = result
            .edges
            .iter()
            .find(|e| e.relation == Relation::Calls)
            .expect("Call edge from OrderService::process_order -> calculate_total not found");
        assert_eq!(call_edge.from, "OrderService::process_order");
        assert_eq!(call_edge.to, "calculate_total");
    }

    #[test]
    fn test_rust_test_attribute_detection() {
        let rust_code = r#"
            #[test]
            fn custom_unit_test() {
                assert_eq!(2 + 2, 4);
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.qualified_name, "custom_unit_test");
        assert!(fn_symbol.is_test, "#[test] attribute must mark symbol as is_test = true");
    }

    #[test]
    fn test_rust_nested_module_qualified_path() {
        let rust_code = r#"
            pub mod core {
                pub mod service {
                    pub struct Worker;

                    impl Worker {
                        pub fn run() {}
                    }
                }
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));

        let method = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "core::service::Worker::run")
            .expect("Nested qualified method core::service::Worker::run not found");

        assert_eq!(method.kind, GraphNodeKind::Function);
    }

    #[test]
    fn test_python_elif_complexity() {
        let py_code = r#"
            def evaluate(score):
                if score > 90:
                    return 'A'
                elif score > 80:
                    return 'B'
                elif score > 70:
                    return 'C'
                else:
                    return 'F'
        "#;

        let result = parse_file(py_code, "eval.py", Some(Language::Python));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 4); // 1 base + 1 if + 2 elifs
    }

    #[test]
    fn test_go_switch_complexity() {
        let go_code = r#"
            package main

            func classify(val int) string {
                switch val {
                case 1:
                    return "one"
                case 2:
                    return "two"
                default:
                    return "other"
                }
            }
        "#;

        let result = parse_file(go_code, "switch.go", Some(Language::Go));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 3); // 1 base + 2 cases
    }
}
