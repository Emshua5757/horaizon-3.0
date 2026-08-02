use std::path::Path;
use tree_sitter::Parser;
pub use crate::graph::store::Language;

extern "C" {
    fn tree_sitter_dart_orchard() -> *const tree_sitter::ffi::TSLanguage;
}

pub fn detect_language(path: &Path) -> Option<Language> {
    let ext = path.extension()?.to_str()?;
    match ext {
        "rs" => Some(Language::Rust),
        "ts" | "tsx" | "js" | "jsx" => Some(Language::TypeScript),
        "py" => Some(Language::Python),
        "dart" => Some(Language::Dart),
        "go" => Some(Language::Go),
        _ => None,
    }
}

pub fn get_tree_sitter_language(lang: Language) -> tree_sitter::Language {
    // Force linking of the tree-sitter-dart-orchard crate
    let _ = tree_sitter_dart_orchard::LANGUAGE;

    match lang {
        Language::Rust => tree_sitter_rust::language(),
        Language::TypeScript => tree_sitter_typescript::language_typescript(),
        Language::Python => tree_sitter_python::language(),
        Language::Dart => unsafe { tree_sitter::Language::from_raw(tree_sitter_dart_orchard()) },
        Language::Go => tree_sitter_go::language(),
    }
}

pub fn get_parser(lang: Language) -> Option<Parser> {
    let mut parser = Parser::new();
    let ts_lang = get_tree_sitter_language(lang);
    if parser.set_language(&ts_lang).is_ok() {
        Some(parser)
    } else {
        None
    }
}
