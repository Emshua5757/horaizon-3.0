# TASK-017 — `shua_diary` Node.js Microservice Port & Pi 5 Media Vault (Native Data API)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | TypeScript (Node.js / Express + WebSocket) + SQLite (`better-sqlite3`) |
| **Target** | `shua_modules/shua_diary/` |
| **Blocks** | TASK-018, TASK-019 |
| **Prerequisites** | TASK-004 (HBP v2 Broker), TASK-007 (AppConfig), ADR-001 |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/reference/shua_diary.md` |

---

## Architectural Directives (READ BEFORE WRITING A SINGLE LINE)

> [!IMPORTANT]
> **NO SDUI. NO BLUEPRINTS. NO SCREEN ASSEMBLERS.**
>
> In horAIzon 2.0, `shua_diary` contained an entire `src/sdui/` directory with `SduiOrchestrator`, `SduiBlockRegistry`, `SduiScreenAssembler`, `SduiBlueprintLoader`, and `SduiNodeBuilder`. All of this is **completely deleted** in horAIzon 3.0.
>
> **In horAIzon 3.0, `shua_diary` is ONLY:**
> 1. A SQLite data persistence layer for diary entries, blocks, and media assets.
> 2. A WebSocket/HBP v2 RPC server exposing clean typed data DTOs.
> 3. A Pi 5 Deduplicated Media Vault for content-addressable file storage.
>
> **UI rendering is entirely the responsibility of `client_flutter` (TASK-019). The backend has zero UI concerns.**

> [!NOTE]
> **Online-Only Architecture — No Offline Sync**:
> - No local offline database on phone/laptop clients. No queued-change Lamport clock sync for disconnected clients.
> - The Pi 5 SQLite database (`shua_diary.db`) is the single source of truth at all times.
> - All clients interact directly over LAN/Tailscale while connected.
>
> **Simultaneous Multi-Device Editing (e.g. laptop + phone editing at the same time)**:
> - This IS supported and requires lightweight concurrency control.
> - Strategy: **Per-block optimistic versioning**. Each `diary_block` row has a `version INTEGER` column (starts at 1, incremented on every update).
> - On `diary.block.save`, the client sends its last-known `version`. Server compares with DB version:
>   - If versions match → accept write, increment `version`, broadcast `diary.block.updated` event to all connected clients for that entry.
>   - If versions differ → reject write, return `{ error: 'conflict', latest: DiaryBlock }` so the client can refresh and retry.
> - This is NOT Lamport timestamp sync. It is simple per-block optimistic locking. No CRDT, no operation queues.

---

## Source Code Port Strategy

The user will provide the original horAIzon 2.0 `shua_diary` Node.js source code. When porting:
- **KEEP**: `src/diary/diary_repository.ts`, `src/diary/diary_types.ts`, `src/diary/diary_search_service.ts`
- **KEEP**: `src/ai/` directory (used in TASK-018)
- **KEEP**: `src/lib/governor_logger.ts` (update to HBP v2 connection)
- **DELETE ENTIRELY**: `src/sdui/` directory and all its contents
- **DELETE**: `SduiOrchestrator`, `SduiBlockRegistry`, `SduiScreenAssembler`, `SduiBlueprintLoader`, `SduiNodeBuilder`
- **REWRITE**: `src/server.ts` — remove Socket.IO SDUI event handlers; replace with clean WebSocket/HTTP data API endpoints

---

## Target File Structure

```
shua_modules/shua_diary/
├── src/
│   ├── server.ts                        # Express + WebSocket entrypoint (port from config.toml)
│   ├── diary/
│   │   ├── diary_repository.ts          # SQLite ORM (LexoRank ordering, FTS5, media_assets)
│   │   ├── diary_types.ts               # DiaryEntry, DiaryBlock, MediaAsset DTOs
│   │   └── diary_search_service.ts      # In-memory RadixTrie full-text search engine
│   ├── media/
│   │   └── media_vault.ts               # Pi 5 Deduplicated Media Vault (SHA256 content-addressable)
│   ├── ai/                              # Implemented in TASK-018
│   │   └── ...
│   └── lib/
│       └── governor_logger.ts           # HBP v2 telemetry emitter → shua_governor port 7700
├── db_debug.py                          # Developer SQLite REPL tool (keep from 2.0)
└── package.json
```

---

## SQLite Schema (`DiaryRepository._ensureSchema`)

All schema migrations run on startup. Tables:

```sql
-- Diary entries
CREATE TABLE IF NOT EXISTS diary_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL DEFAULT 'shua',
  title TEXT NOT NULL DEFAULT '',
  mood INTEGER,
  lexo_rank TEXT NOT NULL,
  is_private INTEGER NOT NULL DEFAULT 0,
  analysis_preview TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Diary blocks (ordered by lexo_rank string sort)
CREATE TABLE IF NOT EXISTS diary_blocks (
  id TEXT PRIMARY KEY,
  entry_id TEXT NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
  block_type TEXT NOT NULL,     -- 'markdown' | 'code' | 'image' | etc. (see TASK-019 block type table)
  content TEXT NOT NULL DEFAULT '',  -- JSON string, schema owned by Flutter block widget
  lexo_rank TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,  -- Optimistic lock: incremented on every update
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Pi 5 deduplicated media vault
CREATE TABLE IF NOT EXISTS media_assets (
  sha256_hash TEXT PRIMARY KEY,
  file_path TEXT NOT NULL,      -- /var/lib/horaizon/media/{sha256[0..2]}/{sha256}.ext
  mime_type TEXT NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  ref_count INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

-- Module config (AI provider settings per user)
CREATE TABLE IF NOT EXISTS module_config (
  user_id TEXT NOT NULL,
  module_id TEXT NOT NULL,
  config_json TEXT NOT NULL,
  PRIMARY KEY (user_id, module_id)
);

-- Block vector embeddings for semantic search
CREATE TABLE IF NOT EXISTS block_embeddings (
  block_id TEXT PRIMARY KEY REFERENCES diary_blocks(id) ON DELETE CASCADE,
  embedding BLOB NOT NULL
);

-- FTS5 full-text search index
CREATE VIRTUAL TABLE IF NOT EXISTS diary_blocks_fts USING fts5(
  content, block_type, content='diary_blocks', content_rowid='rowid'
);
```

---

## WebSocket / HBP v2 RPC Operations

| Operation | Direction | Payload | Response |
| :--- | :--- | :--- | :--- |
| `diary.entry.list` | Client → Server | `{ user_id }` | `DiaryEntry[]` |
| `diary.entry.get` | Client → Server | `{ entry_id }` | `{ entry: DiaryEntry, blocks: DiaryBlock[] }` |
| `diary.entry.save` | Client → Server | `DiaryEntry (partial)` | `DiaryEntry` |
| `diary.entry.delete` | Client → Server | `{ entry_id }` | `{ ok: true }` |
| `diary.block.save` | Client → Server | `DiaryBlock (partial)` | `DiaryBlock` |
| `diary.block.delete` | Client → Server | `{ block_id }` | `{ ok: true }` |
| `diary.block.reorder` | Client → Server | `{ block_id, lexo_rank }` | `{ ok: true }` |
| `diary.search` | Client → Server | `{ query, user_id }` | `DiaryEntry[]` |
| `diary.media.upload` | Client → Server | multipart binary + metadata | `MediaAsset` |
| `diary.media.get` | Client → Server | `{ sha256_hash }` | binary stream |
| `diary.entry.updated` | Server → Client (broadcast) | `{ entry_id }` | (live update event) |

---

## Pi 5 Deduplicated Media Vault (`src/media/media_vault.ts`)

- **Storage path**: `/var/lib/horaizon/media/{sha256[0..2]}/{sha256}.{ext}`
- On upload: compute SHA256 of file bytes. If `media_assets` row exists → return existing record and increment `ref_count`. If new → write file to disk and create record.
- On delete of a block referencing media: decrement `ref_count`. If `ref_count === 0` → delete physical file from disk.

---

## Acceptance Criteria

- [ ] `src/sdui/` directory does NOT exist in horAIzon 3.0 codebase
- [ ] Server starts cleanly with `node dist/server.js`
- [ ] All 9 WebSocket RPC operations listed above respond correctly
- [ ] Media upload deduplicates by SHA256 correctly
- [ ] Telemetry logs emitted to `shua_governor` on startup and state changes
- [ ] `0` TypeScript compiler errors, `0` ESLint warnings
