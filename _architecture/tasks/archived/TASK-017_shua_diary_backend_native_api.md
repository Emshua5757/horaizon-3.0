# TASK-017 — `shua_diary` Node.js Microservice (Native Data API — v3.0 Rebuild)

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | TypeScript (Node.js / Express + WebSocket + `better-sqlite3`) |
| **Target** | `shua_modules/shua_diary/` |
| **Blocks** | TASK-017B (Certification Tracker schema), TASK-018 (AI/MCP), TASK-019 (Flutter UI) |
| **Prerequisites** | TASK-004 (HBP v2 Broker), TASK-007 (AppConfig), TASK-022 (Governor Media Vault — completed), ADR-001 |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/reference/shua_diary/`, `_architecture/contracts/hbp/hbp_v2_spec.md` |

---

## Architectural Directives (READ BEFORE WRITING A SINGLE LINE)

> [!IMPORTANT]
> **NO SDUI. NO BLUEPRINTS. NO SCREEN ASSEMBLERS.**
>
> In horAIzon 2.0, `shua_diary` contained `src/sdui/` with `SduiOrchestrator`, `SduiBlockRegistry`,
> `SduiScreenAssembler`, `SduiBlueprintLoader`, and `SduiNodeBuilder`. **All of this is completely deleted.**
>
> **In horAIzon 3.0, `shua_diary` is ONLY:**
> 1. A SQLite data persistence layer for diary entries, blocks, and certifications.
> 2. A WebSocket/HBP v2 RPC server exposing clean typed data DTOs.
> 3. A proxy for media — delegates all binary storage to `shua_governor` Media Vault (TASK-022 completed).
>
> **UI rendering is entirely the responsibility of `client_flutter` (TASK-019). Zero UI concerns here.**

> [!NOTE]
> **Media Storage: Governor Vault Only (TASK-022 is complete)**
>
> The `shua_governor` Media Vault (`src/media_vault/`) is already implemented on port 7702.
> `shua_diary` does **NOT** implement its own `media_vault.ts` or any file I/O.
>
> When a diary block needs to store an image, audio, or video:
> 1. Flutter client uploads binary directly to governor via `shua.governor.vault.upload` (HBP v2).
> 2. Governor responds with `{ sha256_hash, url }`.
> 3. Flutter saves the hash/url into the diary block's `content` JSON field.
> 4. `shua_diary` stores only the hash reference — zero binary data.
>
> **Hard architectural constraint: do not re-implement file storage in this microservice.**

> [!NOTE]
> **Online-Only Architecture — No Offline Sync**
>
> Pi 5 SQLite (`shua_diary.db`) is the single source of truth.
> All clients interact directly over LAN/Tailscale while connected.
> **Per-block optimistic versioning**: `version INTEGER` column on `diary_blocks`.
> Client sends `version` on save; server rejects with `{ error: 'conflict', latest: DiaryBlock }` if versions differ.

---

## What's New vs. horAIzon 2.0

| v2.0 (SDUI-4, TypeScript) | v3.0 (Native, TypeScript) |
| :--- | :--- |
| `src/sdui/` — 5 SDUI assembler files | **Deleted entirely** |
| Media vault in `src/media/media_vault.ts` | **Deleted — delegated to governor TASK-022** |
| Socket.IO transport | **Plain WebSocket + HBP v2 MessagePack** |
| No certification tracking | **NEW: `cert_entries` table (TASK-017B)** |
| `block_type` drove SDUI primitive selection | `block_type` string; Flutter renders native widget |
| LexoRank ordering | LexoRank ordering (kept) |
| FTS5 full-text search | FTS5 full-text search (kept) |

---

## Source Code Port Strategy

From `_architecture/reference/shua_diary/src/`:

- **KEEP & port**: `diary/diary_repository.ts` — strip SDUI context types, add `version` column
- **KEEP & port**: `diary/diary_types.ts` — update to v3.0 DTO shapes (remove SDUI references)
- **KEEP & port**: `diary/diary_search_service.ts` — no changes needed
- **KEEP & port**: `lib/governor_logger.ts` — update HBP v2 telemetry connection to governor :7700
- **DELETE ENTIRELY**: `src/sdui/` directory and all files within
- **DELETE**: `src/media/media_vault.ts`
- **REWRITE**: `src/server.ts` — plain WebSocket + HTTP data API (no Socket.IO, no SDUI event handlers)

---

## Target File Structure

```
shua_modules/shua_diary/
├── src/
│   ├── server.ts                          # Express + WebSocket entrypoint (port from config.toml)
│   ├── diary/
│   │   ├── diary_repository.ts            # SQLite ORM (LexoRank, FTS5, optimistic versioning)
│   │   ├── diary_types.ts                 # DiaryEntry, DiaryBlock DTOs (v3.0 clean)
│   │   └── diary_search_service.ts        # RadixTrie full-text search engine
│   ├── certs/
│   │   └── cert_repository.ts             # CertEntry CRUD (see TASK-017B)
│   ├── ai/                                # Implemented in TASK-018
│   │   └── ...
│   └── lib/
│       └── governor_logger.ts             # HBP v2 telemetry emitter -> shua_governor :7700
├── db_debug.py                            # Developer SQLite REPL (keep from 2.0)
├── package.json
└── tsconfig.json
```

**Time Complexity**: O(log N) per diary entry lookup (indexed by `user_id, lexo_rank`).
FTS5 search O(K) where K = result set size.
**Space Complexity**: O(N) for N diary blocks. Media is O(1) per block (hash reference only).

---

## SQLite Schema (`DiaryRepository._ensureSchema`)

```sql
-- Diary entries
CREATE TABLE IF NOT EXISTS diary_entries (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL DEFAULT 'shua',
  title           TEXT NOT NULL DEFAULT 'Untitled',
  is_private      INTEGER NOT NULL DEFAULT 0,
  ai_provider     TEXT NOT NULL DEFAULT 'ollama',
  lexo_rank       TEXT NOT NULL DEFAULT '0|hzzzzz:',
  preview         TEXT NOT NULL DEFAULT '',
  mood_score      REAL,
  energy_score    REAL,
  is_globally_elevated INTEGER NOT NULL DEFAULT 0,
  logged_at       TEXT NOT NULL,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_entries_user_rank
  ON diary_entries(user_id, lexo_rank);

-- Diary blocks (typed content blocks per entry)
CREATE TABLE IF NOT EXISTS diary_blocks (
  id           TEXT PRIMARY KEY,
  entry_id     TEXT NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
  block_type   TEXT NOT NULL DEFAULT 'markdown',
  content      TEXT NOT NULL DEFAULT '{}',    -- JSON string; schema owned by Flutter widget
  lexo_rank    TEXT NOT NULL,
  version      INTEGER NOT NULL DEFAULT 1,    -- Optimistic lock; increment on every update
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_blocks_entry_rank
  ON diary_blocks(entry_id, lexo_rank);

-- Block vector embeddings for semantic search (populated by TASK-018)
CREATE TABLE IF NOT EXISTS block_embeddings (
  block_id  TEXT PRIMARY KEY REFERENCES diary_blocks(id) ON DELETE CASCADE,
  embedding BLOB NOT NULL
);

-- FTS5 full-text search
CREATE VIRTUAL TABLE IF NOT EXISTS diary_blocks_fts
  USING fts5(content, block_type, content='diary_blocks', content_rowid='rowid');

-- Module config (AI provider preferences per user)
CREATE TABLE IF NOT EXISTS module_config (
  user_id     TEXT NOT NULL,
  module_id   TEXT NOT NULL,
  config_json TEXT NOT NULL,
  PRIMARY KEY (user_id, module_id)
);
```

> [!NOTE]
> `media_assets` table is NOT in `shua_diary.db`. It lives in `activity.db` inside `shua_governor` (TASK-022).
> Diary blocks that reference media store only the `sha256_hash` string in their `content` JSON.

---

## WebSocket / HBP v2 RPC Operations

| Operation | Direction | Payload | Response |
| :--- | :--- | :--- | :--- |
| `diary.entry.list` | Client → Server | `{ user_id }` | `DiaryEntry[]` |
| `diary.entry.get` | Client → Server | `{ entry_id }` | `{ entry: DiaryEntry, blocks: DiaryBlock[] }` |
| `diary.entry.save` | Client → Server | `DiaryEntry` (partial) | `DiaryEntry` |
| `diary.entry.delete` | Client → Server | `{ entry_id }` | `{ ok: true }` |
| `diary.block.save` | Client → Server | `DiaryBlock (partial)` + `version` | `DiaryBlock` OR `{ error: 'conflict', latest: DiaryBlock }` |
| `diary.block.delete` | Client → Server | `{ block_id }` | `{ ok: true }` |
| `diary.block.reorder` | Client → Server | `{ block_id, lexo_rank }` | `{ ok: true }` |
| `diary.search` | Client → Server | `{ query, user_id }` | `DiaryEntry[]` |
| `diary.entry.updated` | Server → Client (broadcast) | `{ entry_id }` | live sync for multi-device |

> [!NOTE]
> `diary.media.upload` and `diary.media.get` are **removed**. Media operations go directly to governor via `shua.governor.vault.upload` / `vault.get`.

---

## Acceptance Criteria

- [ ] `src/sdui/` directory does NOT exist anywhere in the v3.0 codebase
- [ ] `src/media/media_vault.ts` does NOT exist (delegated to governor TASK-022)
- [ ] Server starts cleanly: `node dist/server.js`
- [ ] All WebSocket RPC operations respond correctly with MessagePack payloads
- [ ] Optimistic versioning: `diary.block.save` returns `{ error: 'conflict', latest }` on version mismatch
- [ ] FTS5 `diary.search` returns results within 5ms for 1000-entry dataset on Pi 5
- [ ] Structured telemetry logs emitted to governor on all state changes and errors
- [ ] `0` TypeScript compiler errors, `0` ESLint warnings (`tsc --noEmit && eslint src/`)
