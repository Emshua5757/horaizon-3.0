import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';
import { DiaryEntry, DiaryBlock, BlockType, BlockConflictError } from './diary_types';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * DiaryRepository — all SQLite interactions for shua_diary v3.0.
 *
 * Uses better-sqlite3 (synchronous) deliberately:
 *   - V8 cannot do true async I/O for SQLite — async wrappers defer on the
 *     libuv thread pool, adding overhead with no real parallelism gain.
 *   - Synchronous calls on the main thread are ~2x faster for queries < 1ms.
 *   - Zero GC pressure: no Promise objects allocated per query.
 *
 * Performance invariant: no query in this file is O(N) without a covering index.
 *
 * Time Complexity: O(log N) per entry/block lookup (indexed by user_id+lexo_rank).
 * Space Complexity: O(N) for N diary blocks.
 */
export class DiaryRepository {
  private db: Database.Database;

  constructor(dbPath?: string) {
    const resolvedPath = dbPath ?? path.join(__dirname, '..', '..', 'data', 'shua_diary.db');
    const parentDir = path.dirname(resolvedPath);
    if (!fs.existsSync(parentDir)) {
      fs.mkdirSync(parentDir, { recursive: true });
    }

    this.db = new Database(resolvedPath);
    this.db.pragma('journal_mode = WAL');   // WAL: concurrent reads, non-blocking writes
    this.db.pragma('foreign_keys = ON');
    this.db.pragma('synchronous = NORMAL'); // Safe on Pi 5 SSD; faster than FULL

    this._ensureSchema();
    logger.info('diary_repository', 'SQLite database open and schema verified', {
      tags: HBP_LOG_TAG.LIFECYCLE | HBP_LOG_TAG.DATABASE,
      telemetry: { db_path: resolvedPath },
    });
  }

  // ── Schema bootstrap ──────────────────────────────────────────────────────

  private _ensureSchema(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS diary_entries (
        id                  TEXT PRIMARY KEY,
        user_id             TEXT NOT NULL DEFAULT 'shua',
        title               TEXT NOT NULL DEFAULT 'Untitled',
        is_private          INTEGER NOT NULL DEFAULT 0,
        ai_provider         TEXT NOT NULL DEFAULT 'ollama',
        lexo_rank           TEXT NOT NULL DEFAULT '0|hzzzzz:',
        preview             TEXT NOT NULL DEFAULT '',
        mood_score          REAL,
        energy_score        REAL,
        is_globally_elevated INTEGER NOT NULL DEFAULT 0,
        logged_at           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
        created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
        updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
      );

      CREATE INDEX IF NOT EXISTS idx_entries_user_rank
        ON diary_entries(user_id, lexo_rank);

      CREATE INDEX IF NOT EXISTS idx_entries_logged_at
        ON diary_entries(user_id, logged_at DESC);

      CREATE TABLE IF NOT EXISTS diary_blocks (
        id          TEXT PRIMARY KEY,
        entry_id    TEXT NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
        block_type  TEXT NOT NULL DEFAULT 'markdown',
        content     TEXT NOT NULL DEFAULT '{}',
        lexo_rank   TEXT NOT NULL,
        version     INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
        updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
      );

      CREATE INDEX IF NOT EXISTS idx_blocks_entry_rank
        ON diary_blocks(entry_id, lexo_rank);

      CREATE TABLE IF NOT EXISTS module_config (
        user_id     TEXT NOT NULL,
        module_id   TEXT NOT NULL,
        config_json TEXT NOT NULL,
        PRIMARY KEY (user_id, module_id)
      );

      -- FTS5 Virtual Tables
      CREATE VIRTUAL TABLE IF NOT EXISTS diary_entries_fts USING fts5(
        id UNINDEXED,
        title,
        preview
      );

      CREATE VIRTUAL TABLE IF NOT EXISTS diary_blocks_fts USING fts5(
        id UNINDEXED,
        content
      );

      -- Triggers: keep FTS in sync with diary_entries
      CREATE TRIGGER IF NOT EXISTS diary_entries_ai AFTER INSERT ON diary_entries BEGIN
        INSERT INTO diary_entries_fts(id, title, preview) VALUES (new.id, new.title, new.preview);
      END;
      CREATE TRIGGER IF NOT EXISTS diary_entries_ad AFTER DELETE ON diary_entries BEGIN
        DELETE FROM diary_entries_fts WHERE id = old.id;
      END;
      CREATE TRIGGER IF NOT EXISTS diary_entries_au AFTER UPDATE ON diary_entries BEGIN
        UPDATE diary_entries_fts SET title = new.title, preview = new.preview WHERE id = new.id;
      END;

      -- Triggers: keep FTS in sync with diary_blocks
      CREATE TRIGGER IF NOT EXISTS diary_blocks_ai AFTER INSERT ON diary_blocks BEGIN
        INSERT INTO diary_blocks_fts(id, content) VALUES (new.id, new.content);
      END;
      CREATE TRIGGER IF NOT EXISTS diary_blocks_ad AFTER DELETE ON diary_blocks BEGIN
        DELETE FROM diary_blocks_fts WHERE id = old.id;
      END;
      CREATE TRIGGER IF NOT EXISTS diary_blocks_au AFTER UPDATE ON diary_blocks BEGIN
        UPDATE diary_blocks_fts SET content = new.content WHERE id = new.id;
      END;
    `);

    // Backfill FTS tables for any existing database rows (migration safety)
    this._backfillFts();
  }

  private _backfillFts(): void {
    try {
      const eCount = this.db.prepare('SELECT COUNT(*) as c FROM diary_entries_fts').get() as { c: number };
      if (eCount.c === 0) {
        this.db.exec(`INSERT INTO diary_entries_fts(id, title, preview) SELECT id, title, preview FROM diary_entries;`);
      }
    } catch { /* FTS table may be fresh */ }

    try {
      const bCount = this.db.prepare('SELECT COUNT(*) as c FROM diary_blocks_fts').get() as { c: number };
      if (bCount.c === 0) {
        this.db.exec(`INSERT INTO diary_blocks_fts(id, content) SELECT id, content FROM diary_blocks;`);
      }
    } catch { /* FTS table may be fresh */ }
  }

  // ── Prepared statement cache ──────────────────────────────────────────────
  // Lazy-initialized once, reused for zero allocation on repeat calls.

  private _stmts: Record<string, Database.Statement> = {};

  private stmt(name: string, sql: string): Database.Statement {
    if (!this._stmts[name]) {
      this._stmts[name] = this.db.prepare(sql);
    }
    return this._stmts[name];
  }

  // ── Read queries ──────────────────────────────────────────────────────────

  /**
   * Get all diary entries for a user, ordered by lexo_rank ascending.
   * Globally elevated entries are moved to the front by a secondary sort.
   * O(log N) via idx_entries_user_rank.
   */
  getEntriesList(userId: string): DiaryEntry[] {
    const rows = this.stmt('getEntriesList',
      `SELECT id, user_id, title, is_private, ai_provider, lexo_rank, preview,
              mood_score, energy_score, is_globally_elevated, logged_at, created_at, updated_at
       FROM diary_entries
       WHERE user_id = ?
       ORDER BY is_globally_elevated DESC, lexo_rank ASC`
    ).all(userId) as any[];
    return rows.map(r => this._mapEntry(r));
  }

  /** Get a single entry by ID. O(1) PK lookup. */
  getEntry(entryId: string): DiaryEntry | null {
    const row = this.stmt('getEntry',
      `SELECT id, user_id, title, is_private, ai_provider, lexo_rank, preview,
              mood_score, energy_score, is_globally_elevated, logged_at, created_at, updated_at
       FROM diary_entries WHERE id = ?`
    ).get(entryId) as any | undefined;
    return row ? this._mapEntry(row) : null;
  }

  /** Get an entry and all its blocks — avoids N+1 queries. */
  getEntryWithBlocks(entryId: string): { entry: DiaryEntry; blocks: DiaryBlock[] } | null {
    const entry = this.getEntry(entryId);
    if (!entry) return null;
    return { entry, blocks: this.getEntryBlocks(entryId) };
  }

  /** Get all blocks for an entry sorted by lexo_rank ASC. O(log N) via index. */
  getEntryBlocks(entryId: string): DiaryBlock[] {
    const rows = this.stmt('getEntryBlocks',
      `SELECT id, entry_id, block_type, content, lexo_rank, version, created_at, updated_at
       FROM diary_blocks WHERE entry_id = ? ORDER BY lexo_rank ASC`
    ).all(entryId) as any[];
    return rows.map(r => this._mapBlock(r));
  }

  /** Get mood timeline for a calendar month. O(log N) via idx_entries_logged_at. */
  getMoodTimeline(userId: string, monthOffset: number = 0): Array<{ date: string; moodScore: number | null }> {
    const now = new Date();
    const target = new Date(now.getFullYear(), now.getMonth() + monthOffset, 1);
    const y = target.getFullYear();
    const m = target.getMonth();
    const startDate = `${y}-${String(m + 1).padStart(2, '0')}-01T00:00:00Z`;
    const lastDay = new Date(y, m + 1, 0).getDate();
    const endDate = `${y}-${String(m + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}T23:59:59Z`;

    const rows = this.stmt('getMoodTimeline',
      `SELECT logged_at, mood_score FROM diary_entries
       WHERE user_id = ? AND logged_at >= ? AND logged_at <= ?
       ORDER BY logged_at ASC`
    ).all(userId, startDate, endDate) as any[];

    return rows.map(r => ({
      date: r.logged_at,
      moodScore: r.mood_score !== null ? Number(r.mood_score) : null,
    }));
  }

  /** Get total entry count for a user. O(1) via index. */
  getEntryCount(userId: string): number {
    const row = this.stmt('getEntryCount',
      `SELECT COUNT(*) as count FROM diary_entries WHERE user_id = ?`
    ).get(userId) as { count: number } | undefined;
    return row?.count ?? 0;
  }

  /** Get entry_id for a block. O(1) PK lookup. */
  getEntryIdForBlock(blockId: string): string | null {
    const row = this.stmt('entryIdForBlock',
      `SELECT entry_id FROM diary_blocks WHERE id = ?`
    ).get(blockId) as { entry_id: string } | undefined;
    return row?.entry_id ?? null;
  }

  /** Get lexo_rank of a block. O(1) PK lookup. */
  getBlockLexoRank(blockId: string): string | null {
    const row = this.stmt('blockRankById',
      `SELECT lexo_rank FROM diary_blocks WHERE id = ?`
    ).get(blockId) as { lexo_rank: string } | undefined;
    return row?.lexo_rank ?? null;
  }

  // ── Write queries ─────────────────────────────────────────────────────────

  /** Create a new diary entry appended to the user's list. */
  createEntry(
    userId: string,
    title: string,
    aiProvider: string = 'ollama',
    moodScore?: number,
    energyScore?: number,
    isGloballyElevated: boolean = false,
    loggedAt?: string,
  ): DiaryEntry {
    const id = crypto.randomUUID();
    const lexoRank = this._nextLexoRank(userId);
    const resolvedLoggedAt = loggedAt ?? new Date().toISOString();

    this.stmt('createEntry',
      `INSERT INTO diary_entries(id, user_id, title, ai_provider, lexo_rank, mood_score, energy_score, is_globally_elevated, logged_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).run(
      id, userId, title, aiProvider, lexoRank,
      moodScore ?? null, energyScore ?? null,
      isGloballyElevated ? 1 : 0,
      resolvedLoggedAt,
    );

    logger.info('diary_repository', `Entry created: ${id}`, {
      tags: HBP_LOG_TAG.DATABASE,
      telemetry: { entry_id: id, user_id: userId },
    });

    return this.getEntry(id)!;
  }

  /** Update mutable fields of a diary entry. */
  updateEntry(
    entryId: string,
    fields: Partial<Pick<DiaryEntry, 'title' | 'isPrivate' | 'isGloballyElevated' | 'loggedAt' | 'aiProvider'>>,
  ): DiaryEntry | null {
    const sets: string[] = [];
    const vals: unknown[] = [];

    if (fields.title !== undefined)              { sets.push('title = ?');               vals.push(fields.title); }
    if (fields.isPrivate !== undefined)          { sets.push('is_private = ?');          vals.push(fields.isPrivate ? 1 : 0); }
    if (fields.isGloballyElevated !== undefined) { sets.push('is_globally_elevated = ?'); vals.push(fields.isGloballyElevated ? 1 : 0); }
    if (fields.loggedAt !== undefined)           { sets.push('logged_at = ?');           vals.push(fields.loggedAt); }
    if (fields.aiProvider !== undefined)         { sets.push('ai_provider = ?');         vals.push(fields.aiProvider); }

    if (sets.length === 0) return this.getEntry(entryId);

    sets.push("updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')");
    vals.push(entryId);

    this.stmt(`updateEntry_${sets.join('|')}`,
      `UPDATE diary_entries SET ${sets.join(', ')} WHERE id = ?`
    ).run(...vals);

    logger.info('diary_repository', `Entry updated: ${entryId}`, {
      tags: HBP_LOG_TAG.DATABASE,
      telemetry: { entry_id: entryId, fields: Object.keys(fields) },
    });

    return this.getEntry(entryId);
  }

  /** Update mood and energy score (called by AI pipeline, TASK-018). */
  updateEntryMood(entryId: string, moodScore: number | null, energyScore: number | null): void {
    this.stmt('updateEntryMood',
      `UPDATE diary_entries SET mood_score = ?, energy_score = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(moodScore, energyScore, entryId);
  }

  /** Delete entry (CASCADE deletes blocks). O(1). */
  deleteEntry(entryId: string): void {
    this.stmt('deleteEntry', `DELETE FROM diary_entries WHERE id = ?`).run(entryId);
    logger.info('diary_repository', `Entry deleted: ${entryId}`, { tags: HBP_LOG_TAG.DATABASE });
  }

  // ── Block Write Queries ───────────────────────────────────────────────────

  /** Create a new block. Appends to end or inserts after afterLexoRank. */
  createBlock(entryId: string, blockType: BlockType, afterLexoRank?: string): DiaryBlock {
    const id = crypto.randomUUID();
    const lexoRank = afterLexoRank
      ? this._lexoRankAfter(entryId, afterLexoRank)
      : this._nextBlockLexoRank(entryId);

    this.stmt('createBlock',
      `INSERT INTO diary_blocks(id, entry_id, block_type, content, lexo_rank, version)
       VALUES (?, ?, ?, '{}', ?, 1)`
    ).run(id, entryId, blockType, lexoRank);

    return this.getEntryBlocks(entryId).find(b => b.id === id)!;
  }

  /**
   * Update block content with optimistic version locking.
   * Returns the updated block on success, or BlockConflictError if version mismatches.
   */
  updateBlockContent(
    blockId: string,
    content: string,
    clientVersion: number,
  ): DiaryBlock | BlockConflictError {
    const current = this.stmt('getBlockForUpdate',
      `SELECT id, entry_id, block_type, content, lexo_rank, version, created_at, updated_at
       FROM diary_blocks WHERE id = ?`
    ).get(blockId) as any | undefined;

    if (!current) {
      // Block was deleted — caller should handle as not-found
      throw new Error(`Block ${blockId} not found`);
    }

    if (current.version !== clientVersion) {
      logger.warn('diary_repository', `Version conflict on block ${blockId}`, {
        tags: HBP_LOG_TAG.DATABASE,
        telemetry: { client_version: clientVersion, server_version: current.version },
      });
      return { error: 'conflict', latest: this._mapBlock(current) };
    }

    const newVersion = current.version + 1;

    this.stmt('updateBlockContent',
      `UPDATE diary_blocks
       SET content = ?, version = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(content, newVersion, blockId);

    this._refreshPreview(blockId);

    return this._mapBlock(
      this.stmt('getBlockById',
        `SELECT id, entry_id, block_type, content, lexo_rank, version, created_at, updated_at
         FROM diary_blocks WHERE id = ?`
      ).get(blockId) as any
    );
  }

  /** Delete a block. O(1). */
  deleteBlock(blockId: string): void {
    this.stmt('deleteBlock', `DELETE FROM diary_blocks WHERE id = ?`).run(blockId);
  }

  /** Reorder a block using neighbor IDs (Flutter sends neighbors, server computes rank). */
  reorderBlockByNeighbors(
    entryId: string,
    blockId: string,
    beforeBlockId: string | null,
    afterBlockId: string | null,
  ): void {
    let newRank: string;

    if (afterBlockId === null && beforeBlockId === null) return; // Single block, no-op

    if (afterBlockId === null) {
      newRank = this._nextBlockLexoRank(entryId);
    } else if (beforeBlockId === null) {
      const firstRow = this.stmt('firstBlockRank',
        `SELECT lexo_rank FROM diary_blocks WHERE entry_id = ? ORDER BY lexo_rank ASC LIMIT 1`
      ).get(entryId) as { lexo_rank: string } | undefined;

      const prefix = '0|hzzzzz:';
      if (!firstRow) {
        newRank = prefix + DiaryRepository.RANK_MID;
      } else {
        const hiSuffix = firstRow.lexo_rank.startsWith(prefix)
          ? firstRow.lexo_rank.slice(prefix.length)
          : firstRow.lexo_rank;
        newRank = prefix + DiaryRepository._midRankSuffix('', hiSuffix);
      }
    } else {
      const beforeRow = this.stmt('blockRankById',
        `SELECT lexo_rank FROM diary_blocks WHERE id = ?`
      ).get(beforeBlockId) as { lexo_rank: string } | undefined;

      if (!beforeRow) {
        logger.error('diary_repository', `reorderBlockByNeighbors: beforeBlockId '${beforeBlockId}' not found`, {
          tags: HBP_LOG_TAG.DATABASE,
        });
        return;
      }
      newRank = this._lexoRankAfter(entryId, beforeRow.lexo_rank);
    }

    this.stmt('reorderBlock',
      `UPDATE diary_blocks SET lexo_rank = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(newRank, blockId);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /**
   * Full-text search using FTS5 prefix matching.
   * O(K) where K = result set size.
   */
  searchEntries(userId: string, query: string): DiaryEntry[] {
    const terms = query.trim().split(/\s+/).filter(Boolean);
    if (terms.length === 0) return [];

    const ftsQuery = terms.map(t => `${t}*`).join(' AND ');

    const rows = this.db.prepare(`
      SELECT DISTINCT e.id, e.user_id, e.title, e.is_private, e.ai_provider, e.lexo_rank,
             e.preview, e.mood_score, e.energy_score, e.is_globally_elevated, e.logged_at, e.created_at, e.updated_at
      FROM diary_entries e
      LEFT JOIN diary_blocks b ON b.entry_id = e.id
      WHERE e.user_id = ? AND (
        e.id IN (SELECT id FROM diary_entries_fts WHERE diary_entries_fts MATCH ?)
        OR
        b.id IN (SELECT id FROM diary_blocks_fts WHERE diary_blocks_fts MATCH ?)
      )
      ORDER BY e.is_globally_elevated DESC, e.lexo_rank ASC
    `).all(userId, ftsQuery, ftsQuery) as any[];

    return rows.map(r => this._mapEntry(r));
  }

  /** FTS5 snippet extraction for search result previews. */
  getSnippetsForEntries(entryIds: string[], ftsQuery: string): Map<string, string> {
    const result = new Map<string, string>();
    if (entryIds.length === 0 || !ftsQuery.trim()) return result;

    const snippetStmt = this.db.prepare(`
      SELECT b.entry_id,
             snippet(diary_blocks_fts, 1, '**', '**', '...', 15) as snip
      FROM diary_blocks_fts
      JOIN diary_blocks b ON b.id = diary_blocks_fts.id
      WHERE b.entry_id = ? AND diary_blocks_fts MATCH ?
      ORDER BY rank
      LIMIT 1
    `);

    for (const entryId of entryIds) {
      try {
        const row = snippetStmt.get(entryId, ftsQuery) as { entry_id: string; snip: string } | undefined;
        if (row?.snip) result.set(entryId, row.snip);
      } catch { /* skip malformed FTS queries */ }
    }
    return result;
  }

  // ── Module Config ─────────────────────────────────────────────────────────

  getModuleConfig(userId: string, moduleId: string): Record<string, unknown> | null {
    const row = this.stmt('getModuleConfig',
      `SELECT config_json FROM module_config WHERE user_id = ? AND module_id = ?`
    ).get(userId, moduleId) as { config_json: string } | undefined;
    if (!row) return null;
    try { return JSON.parse(row.config_json); } catch { return null; }
  }

  saveModuleConfig(userId: string, moduleId: string, config: Record<string, unknown>): void {
    this.stmt('saveModuleConfig',
      `INSERT INTO module_config(user_id, module_id, config_json) VALUES (?, ?, ?)
       ON CONFLICT(user_id, module_id) DO UPDATE SET config_json = excluded.config_json`
    ).run(userId, moduleId, JSON.stringify(config));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  private _mapEntry(row: any): DiaryEntry {
    return {
      id:                 row.id,
      userId:             row.user_id,
      title:              row.title,
      isPrivate:          row.is_private === 1,
      aiProvider:         row.ai_provider,
      lexoRank:           row.lexo_rank,
      preview:            row.preview,
      moodScore:          row.mood_score !== null && row.mood_score !== undefined ? Number(row.mood_score) : null,
      energyScore:        row.energy_score !== null && row.energy_score !== undefined ? Number(row.energy_score) : null,
      isGloballyElevated: row.is_globally_elevated === 1,
      loggedAt:           row.logged_at,
      createdAt:          row.created_at,
      updatedAt:          row.updated_at,
    };
  }

  private _mapBlock(row: any): DiaryBlock {
    return {
      id:        row.id,
      entryId:   row.entry_id,
      blockType: row.block_type as BlockType,
      content:   row.content,
      lexoRank:  row.lexo_rank,
      version:   row.version,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  private _refreshPreview(blockId: string): void {
    const blockRow = this.stmt('entryIdForBlockRefresh',
      `SELECT entry_id FROM diary_blocks WHERE id = ?`
    ).get(blockId) as { entry_id: string } | undefined;
    if (!blockRow) return;

    const firstBody = this.stmt('firstBodyBlock',
      `SELECT content FROM diary_blocks
       WHERE entry_id = ? AND block_type IN ('markdown', 'text_input')
       ORDER BY lexo_rank ASC LIMIT 1`
    ).get(blockRow.entry_id) as { content: string } | undefined;

    // content is JSON — try to extract text field, fall back to raw slice
    let previewText = '';
    if (firstBody) {
      try {
        const parsed = JSON.parse(firstBody.content);
        previewText = (parsed.text ?? parsed.value ?? firstBody.content).slice(0, 120);
      } catch {
        previewText = firstBody.content.slice(0, 120);
      }
    }

    this.stmt('updatePreview',
      `UPDATE diary_entries SET preview = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(previewText, blockRow.entry_id);
  }

  // ── LexoRank helpers ──────────────────────────────────────────────────────
  //
  // Base-26 (chars 'a'–'z') suffix after '0|hzzzzz:' prefix.
  // O(1) append and O(1) midpoint insertion without degeneration.

  private static readonly RANK_CHARS = 'abcdefghijklmnopqrstuvwxyz';
  private static readonly RANK_MID   = 'n';
  private static readonly RANK_MAX   = 'z';

  private static _nextRankSuffix(suffix: string): string {
    if (!suffix) return DiaryRepository.RANK_MID;
    const last = suffix[suffix.length - 1];
    if (last < DiaryRepository.RANK_MAX) {
      return suffix.slice(0, -1) + String.fromCharCode(last.charCodeAt(0) + 1);
    }
    return suffix + DiaryRepository.RANK_MID;
  }

  private static _midRankSuffix(lo: string, hi: string | undefined): string {
    const CHARS = DiaryRepository.RANK_CHARS;
    const len = Math.max(lo.length, hi?.length ?? 0);
    for (let i = 0; i < len + 1; i++) {
      const loIdx = i < lo.length     ? CHARS.indexOf(lo[i])  : -1;
      const hiIdx = i < (hi?.length ?? 0) ? CHARS.indexOf(hi![i]) : CHARS.length;
      const gap = hiIdx - loIdx - 1;
      if (gap > 0) return lo.slice(0, i) + CHARS[loIdx + 1 + Math.floor(gap / 2)];
    }
    return lo + DiaryRepository.RANK_MID;
  }

  private _nextLexoRank(userId: string): string {
    const last = this.stmt('lastEntryRank',
      `SELECT lexo_rank FROM diary_entries WHERE user_id = ? ORDER BY lexo_rank DESC LIMIT 1`
    ).get(userId) as { lexo_rank: string } | undefined;
    const prefix = '0|hzzzzz:';
    if (!last) return prefix + DiaryRepository.RANK_MID;
    const suffix = last.lexo_rank.startsWith(prefix) ? last.lexo_rank.slice(prefix.length) : last.lexo_rank;
    return prefix + DiaryRepository._nextRankSuffix(suffix);
  }

  private _nextBlockLexoRank(entryId: string): string {
    const last = this.stmt('lastBlockRank',
      `SELECT lexo_rank FROM diary_blocks WHERE entry_id = ? ORDER BY lexo_rank DESC LIMIT 1`
    ).get(entryId) as { lexo_rank: string } | undefined;
    const prefix = '0|hzzzzz:';
    if (!last) return prefix + DiaryRepository.RANK_MID;
    const suffix = last.lexo_rank.startsWith(prefix) ? last.lexo_rank.slice(prefix.length) : last.lexo_rank;
    return prefix + DiaryRepository._nextRankSuffix(suffix);
  }

  private _lexoRankAfter(entryId: string, afterRank: string): string {
    const next = this.stmt('nextBlockRankAfter',
      `SELECT lexo_rank FROM diary_blocks WHERE entry_id = ? AND lexo_rank > ? ORDER BY lexo_rank ASC LIMIT 1`
    ).get(entryId, afterRank) as { lexo_rank: string } | undefined;

    const prefix = '0|hzzzzz:';
    const loSuffix = afterRank.startsWith(prefix) ? afterRank.slice(prefix.length) : afterRank;
    const hiSuffix = next?.lexo_rank.startsWith(prefix)
      ? next.lexo_rank.slice(prefix.length)
      : next?.lexo_rank;

    const mid = hiSuffix === undefined
      ? DiaryRepository._nextRankSuffix(loSuffix)
      : DiaryRepository._midRankSuffix(loSuffix, hiSuffix);

    return prefix + mid;
  }

  /** Graceful shutdown — close DB connection cleanly. */
  close(): void {
    this.db.close();
    logger.info('diary_repository', 'SQLite database closed', { tags: HBP_LOG_TAG.LIFECYCLE });
  }
}

// ── Singleton ─────────────────────────────────────────────────────────────────
// better-sqlite3 connections are not thread-safe but Node.js is single-threaded,
// so one shared connection is both safe and optimal.

let _instance: DiaryRepository | null = null;

export function getDiaryRepository(): DiaryRepository {
  if (!_instance) _instance = new DiaryRepository();
  return _instance;
}
