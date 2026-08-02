pub mod blast_radius;
pub mod xml;
pub mod search;
pub mod markdown;
pub mod json;
pub mod git_diff;

#[derive(Debug, Clone, serde::Deserialize)]
pub struct ExportOptions {
    pub focus: Option<String>,
    pub depth: Option<usize>,
    pub strip_bodies: Option<bool>,
    pub pub_only: Option<bool>,
    pub keep_structs: Option<bool>,
    pub keep_docs: Option<bool>,
    pub format: Option<String>,
    pub git_diff: Option<bool>,
    pub client_cache: Option<String>,
    pub query: Option<String>,
}
