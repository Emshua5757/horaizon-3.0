use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use walkdir::WalkDir;
use xxhash_rust::xxh64::xxh64;

/// Result of diffing current disk state against persisted hash index
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FileDiffResult {
    pub added: Vec<String>,
    pub modified: Vec<String>,
    pub removed: Vec<String>,
}

/// Disk-persisted file content hash index for incremental re-parsing
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HashCache {
    pub hashes: HashMap<String, u64>,
}

impl HashCache {
    pub fn new() -> Self {
        Self {
            hashes: HashMap::new(),
        }
    }

    /// Computes the xxh64 hash of raw file bytes
    pub fn compute_hash(bytes: &[u8]) -> u64 {
        xxh64(bytes, 0)
    }

    /// Loads persisted hash cache from disk
    pub fn load_from_disk(path: &Path) -> Result<Self, std::io::Error> {
        if !path.exists() {
            return Ok(Self::new());
        }
        let content = fs::read_to_string(path)?;
        let cache: HashCache = serde_json::from_str(&content)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        Ok(cache)
    }

    /// Persists current hash cache to disk
    pub fn save_to_disk(&self, path: &Path) -> Result<(), std::io::Error> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        fs::write(path, json)?;
        Ok(())
    }

    /// Scans directory and returns diff against cache (added, modified, removed)
    pub fn diff_directory(&mut self, root_dir: &Path) -> FileDiffResult {
        let mut current_files = HashMap::new();
        let mut diff = FileDiffResult::default();

        let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
        let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

        for entry in WalkDir::new(root_dir)
            .into_iter()
            .filter_entry(|e| {
                let name = e.file_name().to_string_lossy();
                !ignore_dirs.contains(&name.as_ref())
            })
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_file() {
                if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                    if valid_extensions.contains(&ext) {
                        let path_str = entry.path().to_string_lossy().to_string();
                        if let Ok(bytes) = fs::read(entry.path()) {
                            let hash = Self::compute_hash(&bytes);
                            current_files.insert(path_str.clone(), hash);

                            match self.hashes.get(&path_str) {
                                Some(&old_hash) => {
                                    if old_hash != hash {
                                        diff.modified.push(path_str);
                                    }
                                }
                                None => {
                                    diff.added.push(path_str);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Find removed files
        for old_path in self.hashes.keys() {
            if !current_files.contains_key(old_path) {
                diff.removed.push(old_path.clone());
            }
        }

        self.hashes = current_files;
        diff
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_hash_reproducibility() {
        let text = b"fn main() { println!(\"Hello World\"); }";
        let h1 = HashCache::compute_hash(text);
        let h2 = HashCache::compute_hash(text);
        assert_ne!(h1, 0);
        assert_eq!(h1, h2);
    }
}
