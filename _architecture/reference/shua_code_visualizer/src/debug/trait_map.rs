use tree_sitter::{Query, QueryCursor};
pub use crate::graph::store::{AppState, InternKey, Language};
use crate::parser::ast::detect_language;

#[derive(Debug, serde::Serialize)]
pub struct TraitMap {
    pub edges: Vec<(InternKey, InternKey)>,
}

pub fn extract_trait_map(state: &AppState) -> TraitMap {
    let file_metadata = state.file_metadata.read().unwrap();
    let mut edges = Vec::new();

    for (file_path, _) in file_metadata.iter() {
        let lang = match detect_language(file_path) {
            Some(l) => l,
            None => continue,
        };

        if lang != Language::Rust {
            continue;
        }

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

        let query_str = r#"
            (impl_item
              trait: (type_identifier) @trait
              type: (type_identifier) @struct)
        "#;

        let ts_lang = tree_sitter_rust::language();
        if let Ok(query) = Query::new(&ts_lang, query_str) {
            let mut cursor = QueryCursor::new();
            let matches = cursor.matches(&query, root_node, source.as_slice());

            for mat in matches {
                let mut trait_name = String::new();
                let mut struct_name = String::new();

                for cap in mat.captures {
                    let cap_name = query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "trait" {
                        if let Ok(text) = node.utf8_text(source.as_slice()) {
                            trait_name = text.to_string();
                        }
                    } else if cap_name == "struct" {
                        if let Ok(text) = node.utf8_text(source.as_slice()) {
                            struct_name = text.to_string();
                        }
                    }
                }

                if !trait_name.is_empty() && !struct_name.is_empty() {
                    let mut intern = state.intern.write().unwrap();
                    let t_key = intern.get_or_intern(trait_name);
                    let s_key = intern.get_or_intern(struct_name);
                    edges.push((t_key, s_key));
                }
            }
        }
    }

    TraitMap { edges }
}
