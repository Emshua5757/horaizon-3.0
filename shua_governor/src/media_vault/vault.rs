use anyhow::{Context, Result};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tracing::{info, warn};

use super::registry::{MediaAsset, VaultRegistry};

/// Config loaded from config.toml [media_vault] section.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct MediaVaultConfig {
    pub root_path: String,
    pub http_port: u16,
    pub max_file_size_mb: u64,
}

impl Default for MediaVaultConfig {
    fn default() -> Self {
        Self {
            root_path: "/var/lib/horaizon/vault".to_string(),
            http_port: 7702,
            max_file_size_mb: 256,
        }
    }
}

/// Upload result returned to callers.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadResult {
    pub sha256_hash: String,
    pub url: String,
    pub file_size: u64,
    /// True if a duplicate — ref_count was incremented rather than a new file written.
    pub deduplicated: bool,
}

/// The MediaVault manages content-addressed binary storage on the Pi 5 filesystem.
///
/// # Layout
/// ```
/// {root_path}/{module}/{sha256[0..2]}/{sha256}.{ext}
/// ```
///
/// # Time Complexity
/// - `store`: O(n) for SHA256 computation (n = file bytes); O(1) for path construction.
/// - `get_asset`: O(1) registry lookup.
/// - `delete`: O(1) registry + O(1) filesystem unlink.
///
/// # Space Complexity
/// - O(n) for n stored unique files; O(1) per request.
pub struct MediaVault {
    pub config: MediaVaultConfig,
    pub registry: Arc<VaultRegistry>,
    pi5_ip: String,
}

impl MediaVault {
    /// Create a new MediaVault. `db_path` must point to the governor activity.db.
    pub fn new(config: MediaVaultConfig, db_path: &Path) -> Result<Self> {
        let registry = Arc::new(
            VaultRegistry::open(db_path)
                .context("Failed to open VaultRegistry in activity.db")?,
        );

        // Create module subdirectories
        for module in &["resume", "diary", "shared"] {
            let dir = PathBuf::from(&config.root_path).join(module);
            std::fs::create_dir_all(&dir).with_context(|| {
                format!("Failed to create vault module dir {}", dir.display())
            })?;
        }

        // Detect Pi 5 / local IP for URL construction (prefer tailscale, fallback to localhost)
        let pi5_ip = detect_ip();

        info!(
            subsystem = "media_vault",
            root = %config.root_path,
            http_port = config.http_port,
            max_file_mb = config.max_file_size_mb,
            pi5_ip = %pi5_ip,
            "MediaVault initialized"
        );

        Ok(Self {
            config,
            registry,
            pi5_ip,
        })
    }

    /// Store file bytes. Returns an `UploadResult` with SHA256 and HTTP URL.
    ///
    /// If the same content already exists (same SHA256), the file is NOT written
    /// again — the ref_count is incremented and `deduplicated: true` is returned.
    pub fn store(
        &self,
        module: &str,
        file_name: &str,
        mime_type: &str,
        data: &[u8],
        uploaded_by: &str,
    ) -> Result<UploadResult> {
        let max_bytes = self.config.max_file_size_mb * 1024 * 1024;
        if data.len() as u64 > max_bytes {
            return Err(anyhow::anyhow!(
                "File too large: {} bytes (max {} MB)",
                data.len(),
                self.config.max_file_size_mb
            ));
        }

        // Compute SHA256 — O(n) where n = data length
        let hash = compute_sha256(data);

        // Derive extension from file_name
        let ext = Path::new(file_name)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("bin");

        // Content-addressed path: {root}/{module}/{hash[0..2]}/{hash}.{ext}
        let bucket = &hash[..2];
        let bucket_dir = PathBuf::from(&self.config.root_path)
            .join(module)
            .join(bucket);
        let file_path = bucket_dir.join(format!("{hash}.{ext}"));

        // Registry insert-or-increment — determines if file already existed
        let newly_inserted = self.registry.insert_or_increment(
            &hash,
            module,
            &file_path.to_string_lossy(),
            file_name,
            mime_type,
            data.len() as i64,
            uploaded_by,
        )?;

        if newly_inserted {
            // Write to disk only for new files
            std::fs::create_dir_all(&bucket_dir)
                .with_context(|| format!("Failed to create bucket dir {}", bucket_dir.display()))?;
            std::fs::write(&file_path, data)
                .with_context(|| format!("Failed to write file {}", file_path.display()))?;
            info!(
                subsystem = "media_vault",
                sha256 = %hash,
                module = module,
                file = %file_path.display(),
                bytes = data.len(),
                "File stored to vault"
            );
        }

        let url = self.build_url(module, &hash, ext);

        Ok(UploadResult {
            sha256_hash: hash,
            url,
            file_size: data.len() as u64,
            deduplicated: !newly_inserted,
        })
    }

    /// Store file from Base64-encoded string (used by submodule IPC calls).
    pub fn store_base64(
        &self,
        module: &str,
        file_name: &str,
        mime_type: &str,
        data_base64: &str,
        uploaded_by: &str,
    ) -> Result<UploadResult> {
        let data = BASE64
            .decode(data_base64)
            .context("Invalid Base64 in vault.upload IPC call")?;
        self.store(module, file_name, mime_type, &data, uploaded_by)
    }

    /// Fetch asset metadata by SHA256.
    pub fn get_asset(&self, sha256: &str) -> Result<Option<MediaAsset>> {
        self.registry.get(sha256)
    }

    /// List assets with optional module filter and pagination.
    pub fn list_assets(
        &self,
        module_filter: Option<&str>,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<MediaAsset>, u32)> {
        self.registry.list(module_filter, page, page_size)
    }

    /// Delete an asset. Decrements ref_count; physically unlinks the file only
    /// when ref_count reaches 0. The registry DELETE and file unlink are performed
    /// atomically inside the registry transaction.
    ///
    /// Returns `(new_ref_count, physically_deleted)`.
    pub fn delete_asset(&self, sha256: &str) -> Result<(i64, bool)> {
        let (new_rc, path_to_delete) = self.registry.decrement_ref(sha256)?;

        if let Some(path) = path_to_delete {
            match std::fs::remove_file(&path) {
                Ok(_) => {
                    info!(
                        subsystem = "media_vault",
                        sha256 = %sha256,
                        path = %path.display(),
                        "File physically deleted from vault (ref_count = 0)"
                    );
                    return Ok((0, true));
                }
                Err(e) => {
                    warn!(
                        subsystem = "media_vault",
                        sha256 = %sha256,
                        path = %path.display(),
                        error = %e,
                        "Registry row deleted but file unlink failed (may already be missing)"
                    );
                    return Ok((0, false));
                }
            }
        }

        Ok((new_rc, false))
    }

    /// Build the HTTP URL for a stored file.
    pub fn build_url(&self, module: &str, sha256: &str, ext: &str) -> String {
        let bucket = &sha256[..2];
        format!(
            "http://{}:{}/vault/{}/{}/{}.{}",
            self.pi5_ip, self.config.http_port, module, bucket, sha256, ext
        )
    }
}

/// Compute SHA256 hex string of bytes. O(n).
fn compute_sha256(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

/// Detect the host IP — tries Tailscale range first, falls back to 127.0.0.1.
fn detect_ip() -> String {
    // On Pi 5, the Tailscale IP is typically in 100.x.x.x range.
    // We read the governor config or fall back to localhost.
    // This is best-effort — production should set this via config.toml.
    if let Ok(output) = std::process::Command::new("hostname").arg("-I").output() {
        let ips = String::from_utf8_lossy(&output.stdout);
        for ip in ips.split_whitespace() {
            if ip.starts_with("100.") {
                // Tailscale IP
                return ip.to_string();
            }
        }
        // First non-loopback IP
        for ip in ips.split_whitespace() {
            if ip != "127.0.0.1" {
                return ip.to_string();
            }
        }
    }
    "127.0.0.1".to_string()
}
