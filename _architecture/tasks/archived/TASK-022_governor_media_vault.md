# TASK-022 — `shua_governor` Pi 5 Media Vault & File Distribution Server

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Rust (shua_governor extension) |
| **Target** | `shua_governor/src/media_vault/` |
| **Blocks** | None |
| **Enables** | TASK-020 (resume PDF storage), TASK-017 (diary media), future modules |
| **Prerequisites** | TASK-004 (HBP v2 Broker running) |
| **References** | `_architecture/contracts/hbp/hbp_v2_spec.md`, `_architecture/contracts/hbp/API_REFERENCE.md`, `_architecture/contracts/mcp/mcp_master_spec.md` |

---

## Why This Exists

> [!IMPORTANT]
> Every shua module (resume, diary, gym, crypto) needs to store and retrieve binary files: PDFs, images, audio, video, and documents. Without a centralized solution, each module would implement its own HTTP file server on its own port — creating port sprawl, duplicated code, and no unified file browsing from the Flutter client.
>
> **TASK-022 adds the Pi 5 Media Vault directly into `shua_governor`**, making the governor the single media distributor for the entire horAIzon 3.0 system. Submodules write files to the vault via IPC. The Flutter client reads files via HBP v2 RPC operations and a static HTTP file server spawned by the governor.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        shua_governor                             │
│                                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌───────────────────┐   │
│  │  HBP v2      │   │  Media Vault │   │  Static HTTP      │   │
│  │  Broker      │   │  (SQLite +   │   │  File Server      │   │
│  │  :7700       │   │  filesystem) │   │  :7702            │   │
│  └──────┬───────┘   └──────┬───────┘   └────────┬──────────┘   │
│         │                  │                     │              │
│         └──────────────────┤                     │              │
│                 vault.* RPC│            GET /vault/{sha256}     │
└─────────────────────────────────────────────────────────────────┘
         ▲                   ▲                     ▲
         │ HBP v2            │ IPC (7701)          │ HTTP GET
   Flutter client      Submodules              Flutter client
                     (resume, diary)          (PDF viewer, image)
```

**Port assignments**:
- `:7700` — HBP v2 WebSocket broker (existing, unchanged)
- `:7701` — JSON IPC listener for submodule registration (existing, unchanged)
- `:7702` — NEW: Static HTTP file server for media vault binary access

**Time Complexity**: O(1) per file read/write (SHA256 hash lookup, direct file path construction).
**Space Complexity**: O(n) for n stored files; O(1) per request.

---

## Vault File System Layout (Pi 5)

```
/var/lib/horaizon/vault/
├── resume/
│   └── {sha256[0..2]}/
│       └── {sha256}.pdf
├── diary/
│   ├── {sha256[0..2]}/
│   │   ├── {sha256}.jpg
│   │   ├── {sha256}.mp4
│   │   └── {sha256}.opus
└── shared/
    └── {sha256[0..2]}/
        └── {sha256}.{ext}
```

- **Root**: `/var/lib/horaizon/vault/` (configurable via `config.toml`)
- **Subdirectory bucketing**: First 2 hex chars of SHA256 to avoid filesystem inode limits (same strategy as Git objects, diary media vault TASK-017)
- **No filename collision possible** — file identity is content-addressed by SHA256.

---

## Target File Structure (Governor Extensions)

```
shua_governor/src/
└── media_vault/
    ├── mod.rs                 # pub use; module declarations
    ├── vault.rs               # MediaVault struct: store, retrieve, delete, list
    ├── registry.rs            # SQLite-backed VaultRegistry: media_assets table in activity.db
    ├── http_server.rs         # Tokio HTTP static file server on port 7702
    └── dispatcher_ext.rs      # Handler for vault.* HBP v2 RPC operations in Dispatcher
```

Add to `shua_governor/src/main.rs`:
```rust
mod media_vault;
// ... after dispatcher init:
// 13. Initialize Media Vault & HTTP file server
let vault = Arc::new(media_vault::vault::MediaVault::new(&app_config.media_vault));
tokio::spawn(async move {
    media_vault::http_server::serve(vault_clone, 7702).await;
});
```

Add to `AppConfig` / `config.toml`:
```toml
[media_vault]
root_path = "/var/lib/horaizon/vault"
http_port = 7702
max_file_size_mb = 256
```

---

## SQLite Schema (in `activity.db`)

```sql
-- Centralized media asset registry for all modules
CREATE TABLE IF NOT EXISTS media_assets (
  sha256_hash   TEXT    PRIMARY KEY,
  module        TEXT    NOT NULL,   -- "resume" | "diary" | "shared"
  file_path     TEXT    NOT NULL,   -- Absolute path on Pi 5 filesystem
  mime_type     TEXT    NOT NULL,
  file_name     TEXT    NOT NULL,   -- Original filename for display
  file_size     INTEGER NOT NULL,
  ref_count     INTEGER NOT NULL DEFAULT 1,
  uploaded_by   TEXT    NOT NULL DEFAULT 'shua',
  created_at    TEXT    NOT NULL,
  last_accessed TEXT    NOT NULL
);
```

**Deduplication**: Uploading a file that already exists (same SHA256) increments `ref_count` and returns the existing record immediately. No duplicate bytes stored.

**Ref-count lifecycle**:
- `vault.file.delete`: decrement `ref_count`. If `ref_count` reaches 0, unlink the physical file and delete the row — inside an atomic SQLite transaction.
- Nightly Dream Loop verifies `ref_count` integrity against filesystem.

---

## HBP v2 RPC Operations (new `shua.governor.vault.*` namespace)

These operations are handled directly by `shua_governor`'s Dispatcher — no forwarding to a submodule.

### `shua.governor.vault.upload`

**Direction**: Client or Submodule → Governor
**Use case**: Flutter app uploads a file (or `shua_resume` deposits a compiled PDF via IPC).

**Request payload**:
```msgpack
{
  "module":    str,   -- "resume" | "diary" | "shared"
  "file_name": str,   -- Original filename e.g. "resume_2026.pdf"
  "mime_type": str,   -- MIME type e.g. "application/pdf"
  "data":      bytes  -- Raw binary file content
}
```

**Response payload**:
```msgpack
{
  "sha256_hash": str,  -- Content-addressed ID
  "url":         str,  -- "http://{pi5_ip}:7702/vault/{module}/{sha256[0..2]}/{sha256}.{ext}"
  "file_size":   u32,
  "deduplicated": bool -- true if file already existed (ref_count incremented)
}
```

> [!NOTE]
> For `shua_resume`, `CompileTypst` returns `[]byte` PDF. The Go microservice sends a `vault.upload` IPC call to the governor, gets back the `sha256_hash` and `url`, and uses those in the `ResumeCompileResponse`. `shua_resume` does NOT write files to disk directly.

### `shua.governor.vault.get`

**Direction**: Client → Governor
**Use case**: Flutter fetches file metadata for PDF viewer or image display.

**Request payload**:
```msgpack
{ "sha256_hash": str }
```

**Response payload**:
```msgpack
{
  "sha256_hash": str,
  "url":         str,
  "mime_type":   str,
  "file_name":   str,
  "file_size":   u32
}
```

> [!TIP]
> For large files (PDF, video), the Flutter client uses the `url` field to fetch the binary content directly via HTTP GET on port 7702 — NOT through HBP v2. HBP v2 is only for metadata. This avoids MsgPack-encoding large binary payloads.

### `shua.governor.vault.list`

**Direction**: Client → Governor
**Use case**: Flutter File Explorer screen — browse all files on Pi 5.

**Request payload**:
```msgpack
{
  "module":   str?,   -- Filter by module ("resume" | "diary" | "shared" | nil = all)
  "page":     u32,
  "page_size": u32
}
```

**Response payload**:
```msgpack
{
  "items": [{
    "sha256_hash": str,
    "module":      str,
    "file_name":   str,
    "mime_type":   str,
    "file_size":   u32,
    "url":         str,
    "created_at":  str
  }],
  "total":    u32,
  "has_more": bool
}
```

### `shua.governor.vault.delete`

**Direction**: Client → Governor

**Request payload**:
```msgpack
{ "sha256_hash": str }
```

**Response payload**:
```msgpack
{ "ok": bool, "physically_deleted": bool }
```

---

## Submodule Upload via IPC (port 7701)

Submodules (like `shua_resume`) that need to deposit files into the vault use the JSON IPC channel:

```json
{
  "op": "vault.upload",
  "id": "uuid-of-call",
  "module": "resume",
  "file_name": "exhibit_2026.pdf",
  "mime_type": "application/pdf",
  "data_base64": "JVBERi0xLjQ..."
}
```

Response:
```json
{
  "id": "uuid-of-call",
  "status": "ok",
  "result": {
    "sha256_hash": "a3f2...",
    "url": "http://100.67.11.0:7702/vault/resume/a3/a3f2....pdf"
  }
}
```

`data_base64` is the file encoded as Base64 (standard JSON-safe encoding for binary over the JSON IPC channel).

---

## HTTP Static File Server (`media_vault/http_server.rs`)

Minimal Tokio/Hyper HTTP server on port 7702:

```
GET /vault/{module}/{sha256[0..2]}/{sha256}.{ext}
→ Stream file bytes with Content-Type header
→ Accept-Ranges: bytes (for PDF scrubbing and video seeking in Flutter)
→ Cache-Control: max-age=86400 (files are immutable — same SHA256 = same bytes)
```

**Range request support** is mandatory for:
- PDF viewers (`pdfx` uses HTTP range requests for large PDFs)
- Audio/video seeking in diary media blocks

**Security**: On Pi 5, port 7702 is only accessible over Tailscale (same as 7700). Not exposed to the public internet.

---

## Flutter Client Integration

### New HBP operations to register in `lib/core/hbp/`

```dart
// hbp_vault_operations.dart
const kVaultUpload = 'vault.upload';
const kVaultGet    = 'vault.get';
const kVaultList   = 'vault.list';
const kVaultDelete = 'vault.delete';
```

### Flutter File Explorer Screen (new feature)

```
client_flutter/lib/features/governor/
├── governor_screen.dart          # Existing governor screen
└── file_explorer_screen.dart     # NEW: Pi 5 File Explorer
```

**File Explorer UI** (`/governor/files`):
- `TabBar`: Resume | Diary | Shared | All
- `GridView` of file cards showing file icon (by MIME type), filename, size, date
- Tapping a file: opens inline viewer (PDF, image, audio player) or downloads
- Upload button: platform file picker → `vault.upload` RPC → success snackbar
- Long-press → context menu: Download, Delete, Copy Link

### `lib/features/resume/` — update PDF URL source

In `resume_compile_screen.dart`, the PDF URL now comes from `ResumeCompileResponse.pdf_url` which is already the governor vault URL (`http://{pi5}:7702/vault/resume/...`). No changes needed to the Riverpod provider — just ensure `pdfx` is configured to use that URL directly.

---

## MCP Resource Update (`mcp_master_spec.md`)

Add the following vault resources to the master MCP spec (to be documented separately in `_architecture/contracts/mcp/`):

```
vault://resume/{sha256}    → resume PDF exhibit metadata
vault://diary/{sha256}     → diary media asset metadata
vault://list               → paginated list of all vault files
```

---

## `config.toml` additions

```toml
[media_vault]
root_path   = "/var/lib/horaizon/vault"  # Pi 5 storage root
http_port   = 7702                        # Static file server port
max_file_size_mb = 256                    # Per-upload size limit
```

---

## Acceptance Criteria

- [ ] `shua_governor` starts media vault HTTP server on port 7702
- [ ] `vault.upload` RPC accepts PDF bytes from `shua_resume` via IPC and stores to `/var/lib/horaizon/vault/resume/`
- [ ] `vault.list` RPC returns paginated file list, filterable by module
- [ ] `vault.delete` decrements `ref_count`; physically unlinks file when `ref_count` reaches 0 — atomically
- [ ] HTTP GET `http://{pi5}:7702/vault/resume/{sha256}.pdf` serves file bytes with `Accept-Ranges: bytes` support
- [ ] Flutter `FileExplorerScreen` lists all vault files grouped by module tab
- [ ] PDF viewer in `ResumeHistoryScreen` loads PDF from vault HTTP URL successfully
- [ ] Deduplication: uploading identical bytes twice returns existing `sha256_hash` with `deduplicated: true`
- [ ] Nightly Dream Loop verifies ref-count integrity (scan `media_assets` table vs filesystem)
- [ ] `cargo build` — 0 errors, 0 warnings (`cargo clippy` — 0 issues)
