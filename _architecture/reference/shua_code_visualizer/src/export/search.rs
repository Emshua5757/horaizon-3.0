use std::collections::HashMap;
use petgraph::graph::NodeIndex;
pub use crate::graph::store::AppState;

pub struct SearchResult {
    pub node_idx: NodeIndex,
    pub score: f32,
}

pub fn search_bm25(query: &str, state: &AppState) -> Vec<SearchResult> {
    let graph = state.graph.read().unwrap();
    let intern = state.intern.read().unwrap();

    let mut results = Vec::new();
    let query_terms: Vec<String> = query
        .to_lowercase()
        .split(|c: char| !c.is_alphanumeric())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .collect();

    if query_terms.is_empty() {
        return results;
    }

    let mut doc_tfs = HashMap::new();
    let mut doc_lens = HashMap::new();
    let mut dfs = HashMap::new();
    let mut total_len = 0;
    let n = graph.node_count();

    if n == 0 {
        return results;
    }

    for idx in graph.node_indices() {
        if let Some(node) = graph.node_weight(idx) {
            let label = intern.resolve(&node.name).to_lowercase();
            let sig = node.signature.to_lowercase();
            
            let doc_text = format!("{} {}", label, sig);
            let terms: Vec<&str> = doc_text
                .split(|c: char| !c.is_alphanumeric())
                .filter(|s| !s.is_empty())
                .collect();

            let doc_len = terms.len();
            doc_lens.insert(idx, doc_len);
            total_len += doc_len;

            let mut tfs = HashMap::new();
            for term in terms {
                *tfs.entry(term.to_string()).or_insert(0) += 1;
            }

            for term in tfs.keys() {
                *dfs.entry(term.clone()).or_insert(0) += 1;
            }

            doc_tfs.insert(idx, tfs);
        }
    }

    let avgdl = (total_len as f32) / (n as f32);
    let k1 = 1.2;
    let b = 0.75;

    for (idx, tfs) in doc_tfs {
        let mut score = 0.0;
        let doc_len = *doc_lens.get(&idx).unwrap_or(&0) as f32;

        for term in &query_terms {
            if let Some(&tf) = tfs.get(term) {
                let df = *dfs.get(term).unwrap_or(&0);
                
                let idf = ((n as f32 - df as f32 + 0.5) / (df as f32 + 0.5) + 1.0).ln();
                let tf_f = tf as f32;
                let term_score = idf * (tf_f * (k1 + 1.0)) / (tf_f + k1 * (1.0 - b + b * (doc_len / avgdl)));
                score += term_score;
            }
        }

        if score > 0.0 {
            results.push(SearchResult { node_idx: idx, score });
        }
    }

    results.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));
    results
}
