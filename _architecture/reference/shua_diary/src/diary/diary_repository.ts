import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { DiaryEntry, DiaryBlock, BlockType } from './diary_types';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * DiaryRepository — all SQLite interactions for shua_diary.
 *
 * Uses better-sqlite3 (synchronous) deliberately:
 *   - V8 can't do true async I/O for SQLite anyway — the async wrappers just defer on the
 *     libuv thread pool, adding overhead with no real parallelism gain.
 *   - Synchronous calls on the main thread are ~2x faster than async equivalents for
 *     small read queries (< 1ms on Pi 5 SSD).
 *   - Zero GC pressure: no Promise objects allocated per query.
 *
 * Performance invariant: no query in this file is O(N) without a covering index.
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
    this.db.pragma('journal_mode = WAL');   // WAL mode: concurrent reads, non-blocking writes
    this.db.pragma('foreign_keys = ON');
    this.db.pragma('synchronous = NORMAL'); // Safe on Pi 5 SSD; faster than FULL
    this._ensureSchema();
  }

  // ── Schema bootstrap ─────────────────────────────────────────────

  private _ensureSchema(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS diary_entries (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL,
        title       TEXT NOT NULL DEFAULT 'Untitled',
        is_private  INTEGER NOT NULL DEFAULT 0,
        ai_provider TEXT NOT NULL DEFAULT 'gemini',
        lexo_rank   TEXT NOT NULL DEFAULT '0|hzzzzz:',
        preview     TEXT NOT NULL DEFAULT '',
        mood_score  REAL,
        energy_score REAL,
        is_globally_elevated INTEGER NOT NULL DEFAULT 0,
        logged_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
        created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
        updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
      );

      CREATE INDEX IF NOT EXISTS idx_entries_user_rank
        ON diary_entries(user_id, lexo_rank);

      CREATE TABLE IF NOT EXISTS diary_blocks (
        id            TEXT PRIMARY KEY,
        entry_id      TEXT NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
        block_type    TEXT NOT NULL DEFAULT 'body',
        content       TEXT NOT NULL DEFAULT '',
        lexo_rank     TEXT NOT NULL,
        sort_order    INTEGER NOT NULL DEFAULT 0,
        code_language TEXT,
        created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
        updated_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
      );

      CREATE INDEX IF NOT EXISTS idx_blocks_entry_rank
        ON diary_blocks(entry_id, lexo_rank);

      CREATE TABLE IF NOT EXISTS module_config (
        module_id   TEXT NOT NULL,
        user_id     TEXT NOT NULL,
        config_json TEXT NOT NULL,
        PRIMARY KEY (module_id, user_id)
      );

      CREATE TABLE IF NOT EXISTS shua_diary_embeddings (
        block_id    TEXT PRIMARY KEY REFERENCES diary_blocks(id) ON DELETE CASCADE,
        embedding   BLOB NOT NULL
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

      -- Triggers for FTS sync (diary_entries)
      CREATE TRIGGER IF NOT EXISTS diary_entries_ai AFTER INSERT ON diary_entries BEGIN
        INSERT INTO diary_entries_fts(id, title, preview) VALUES (new.id, new.title, new.preview);
      END;

      CREATE TRIGGER IF NOT EXISTS diary_entries_ad AFTER DELETE ON diary_entries BEGIN
        DELETE FROM diary_entries_fts WHERE id = old.id;
      END;

      CREATE TRIGGER IF NOT EXISTS diary_entries_au AFTER UPDATE ON diary_entries BEGIN
        UPDATE diary_entries_fts SET title = new.title, preview = new.preview WHERE id = new.id;
      END;

      -- Triggers for FTS sync (diary_blocks)
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

    // bootstrap missing columns for existing databases
    try { this.db.exec("ALTER TABLE diary_entries ADD COLUMN mood_score REAL;"); } catch(e) {}
    try { this.db.exec("ALTER TABLE diary_entries ADD COLUMN energy_score REAL;"); } catch(e) {}
    try { this.db.exec("ALTER TABLE diary_entries ADD COLUMN yawa_elevation INTEGER NOT NULL DEFAULT 0;"); } catch(e) {} // Legacy check
    try { this.db.exec("ALTER TABLE diary_entries ADD COLUMN is_globally_elevated INTEGER NOT NULL DEFAULT 0;"); } catch(e) {}
    try { this.db.exec("ALTER TABLE diary_entries ADD COLUMN logged_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'));"); } catch(e) {}

    // Backfill FTS tables if they are empty
    try {
      const entriesCount = this.db.prepare("SELECT COUNT(*) as count FROM diary_entries_fts").get() as { count: number };
      if (entriesCount.count === 0) {
        this.db.exec(`
          INSERT INTO diary_entries_fts(id, title, preview)
          SELECT id, title, preview FROM diary_entries;
        `);
      }
    } catch (e) {
      logger.error('diary_repository', `Failed to backfill diary_entries_fts: ${e}`, { tags: HBP_LOG_TAG.DATABASE });
    }

    try {
      const blocksCount = this.db.prepare("SELECT COUNT(*) as count FROM diary_blocks_fts").get() as { count: number };
      if (blocksCount.count === 0) {
        this.db.exec(`
          INSERT INTO diary_blocks_fts(id, content)
          SELECT id, content FROM diary_blocks;
        `);
      }
    } catch (e) {
      logger.error('diary_repository', `Failed to backfill diary_blocks_fts: ${e}`, { tags: HBP_LOG_TAG.DATABASE });
    }
  }

  // ── Prepared statement cache ──────────────────────────────────────
  // Lazy-initialized once, reused for zero allocation on repeat calls.

  private _stmts: Record<string, Database.Statement> = {};

  private stmt(name: string, sql: string): Database.Statement {
    if (!this._stmts[name]) {
      this._stmts[name] = this.db.prepare(sql);
    }
    return this._stmts[name];
  }

  // ── Read queries ──────────────────────────────────────────────────

  /**
   * Get all diary entries for a user, ordered by lexo_rank ascending.
   * O(log N) via idx_entries_user_rank.
   */
  getEntriesList(userId: string): DiaryEntry[] {
    const rows = this.stmt('getEntriesList',
      `SELECT id, user_id, title, is_private, ai_provider, lexo_rank, preview, mood_score, energy_score, is_globally_elevated, logged_at, created_at, updated_at
       FROM diary_entries
       WHERE user_id = ?
       ORDER BY lexo_rank ASC`
    ).all(userId) as any[];

    return rows.map(row => this._mapEntry(row));
  }

  /**
   * Get a single entry by ID.
   */
  getEntry(entryId: string): DiaryEntry | null {
    const row = this.stmt('getEntry',
      `SELECT id, user_id, title, is_private, ai_provider, lexo_rank, preview, mood_score, energy_score, is_globally_elevated, logged_at, created_at, updated_at
       FROM diary_entries WHERE id = ?`
    ).get(entryId) as any | undefined;

    return row ? this._mapEntry(row) : null;
  }

  /**
   * Get an entry and all its blocks in one database context to prevent N+1 queries.
   */
  getEntryWithBlocks(entryId: string): { entry: DiaryEntry; blocks: DiaryBlock[] } | null {
    const entry = this.getEntry(entryId);
    if (!entry) return null;
    const blocks = this.getEntryBlocks(entryId);
    return { entry, blocks };
  }

  /**
   * Get target month timeline of entries to display in mood heatmap.
   */
  getMoodTimeline(userId: string, monthOffset: number = 0): Array<{ date: string; moodScore: number | null }> {
    const now = new Date();
    const targetDate = new Date(now.getFullYear(), now.getMonth() + monthOffset, 1);
    const year = targetDate.getFullYear();
    const month = targetDate.getMonth();

    const startDate = `${year}-${String(month + 1).padStart(2, '0')}-01T00:00:00Z`;
    const lastDay = new Date(year, month + 1, 0).getDate();
    const endDate = `${year}-${String(month + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}T23:59:59Z`;

    const rows = this.stmt('getMoodTimeline',
      `SELECT logged_at, mood_score 
       FROM diary_entries 
       WHERE user_id = ? AND logged_at >= ? AND logged_at <= ?
       ORDER BY logged_at ASC`
    ).all(userId, startDate, endDate) as any[];

    return rows.map(r => ({
      date: r.logged_at,
      moodScore: r.mood_score !== null ? Number(r.mood_score) : null
    }));
  }

  /**
   * Get all blocks for an entry, sorted by lexo_rank ascending.
   * O(log N) via idx_blocks_entry_rank.
   */
  getEntryBlocks(entryId: string): DiaryBlock[] {
    const rows = this.stmt('getEntryBlocks',
      `SELECT id, entry_id, block_type, content, lexo_rank, sort_order, code_language, created_at, updated_at
       FROM diary_blocks
       WHERE entry_id = ?
       ORDER BY lexo_rank ASC, sort_order ASC`
    ).all(entryId) as any[];

    return rows.map(row => this._mapBlock(row));
  }

  // ── Write queries ──────────────────────────────────────────────────

  /**
   * Create a new diary entry.
   * Returns the created entry including server-generated timestamps.
   */
  createEntry(
    userId: string, 
    title: string, 
    aiProvider: string = 'gemini', 
    moodScore?: number, 
    energyScore?: number, 
    isGloballyElevated: boolean = false, 
    loggedAt?: string
  ): DiaryEntry {
    const id = this._uuid();
    // Place at end of list by default — caller can reorder via reorderEntry() immediately after
    const lexoRank = this._nextLexoRank(userId);
    const resolvedLoggedAt = loggedAt ?? new Date().toISOString();

    this.stmt('createEntry',
      `INSERT INTO diary_entries(id, user_id, title, ai_provider, lexo_rank, mood_score, energy_score, is_globally_elevated, logged_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).run(
      id, 
      userId, 
      title, 
      aiProvider, 
      lexoRank, 
      moodScore !== undefined ? moodScore : null, 
      energyScore !== undefined ? energyScore : null, 
      isGloballyElevated ? 1 : 0, 
      resolvedLoggedAt
    );

    return this.getEntry(id)!;
  }

  /**
   * Create a new block inside an entry.
   * afterLexoRank: if provided, inserts immediately after that rank; otherwise appends.
   */
  createBlock(entryId: string, blockType: BlockType, afterLexoRank?: string): DiaryBlock {
    const id = this._uuid();
    const lexoRank = afterLexoRank
      ? this._lexoRankAfter(entryId, afterLexoRank)
      : this._nextBlockLexoRank(entryId);

    const sortOrder = this._nextSortOrder(entryId);

    this.stmt('createBlock',
      `INSERT INTO diary_blocks(id, entry_id, block_type, content, lexo_rank, sort_order)
       VALUES (?, ?, ?, ?, ?, ?)`
    ).run(id, entryId, blockType, '', lexoRank, sortOrder);

    return this.getEntryBlocks(entryId).find(b => b.id === id)!;
  }

  /**
   * Update block content. Also refreshes entry preview if this is the first body block.
   * Fire-and-forget from the client's perspective — no response needed.
   */
  updateBlock(blockId: string, content: string): void {
    this.stmt('updateBlock',
      `UPDATE diary_blocks SET content = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(content, blockId);

    // Refresh preview on the parent entry if applicable
    this._refreshPreview(blockId);
  }

  /**
   * Delete a block by ID.
   */
  deleteBlock(blockId: string): void {
    this.stmt('deleteBlock',
      `DELETE FROM diary_blocks WHERE id = ?`
    ).run(blockId);
  }

  /**
   * Update the lexo_rank of a block for drag-and-drop reordering.
   * Accepts the pre-computed new rank directly.
   * O(1) — single row update by PK.
   */
  reorderBlock(blockId: string, newLexoRank: string): void {
    this.stmt('reorderBlock',
      `UPDATE diary_blocks SET lexo_rank = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(newLexoRank, blockId);
  }

  /**
   * Compute and persist a new lexo_rank for `blockId` given its new neighbors.
   * Called after a drag-reorder from Flutter, which sends neighbor IDs instead
   * of a pre-computed rank (Flutter must never own LexoRank logic).
   *
   * @param entryId        Parent entry ID (used by _lexoRankAfter scope)
   * @param blockId        Block being moved
   * @param beforeBlockId  Block now above the moved block (null = moved to top)
   * @param afterBlockId   Block now below the moved block (null = moved to bottom)
   *
   * Rank computation:
   *   - afterBlockId is null  → block is at end → _nextBlockLexoRank (append)
   *   - beforeBlockId is null → block is at top → rank = midpoint between '' and first block rank
   *   - Both present          → _lexoRankAfter(entryId, beforeBlock.lexoRank)
   *
   * O(1) per case (single PK lookups + rank math).
   */
  reorderBlockByNeighbors(
    entryId: string,
    blockId: string,
    beforeBlockId: string | null,
    afterBlockId: string | null,
  ): void {
    let newRank: string;

    if (afterBlockId === null && beforeBlockId === null) {
      // Edge case: only one block in the list — no-op
      return;
    }

    if (afterBlockId === null) {
      // Moved to the very end
      newRank = this._nextBlockLexoRank(entryId);
    } else if (beforeBlockId === null) {
      // Moved to the very top — rank = midpoint before the first block
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
        // Midpoint between '' (before all) and the first block's suffix
        newRank = prefix + DiaryRepository._midRankSuffix('', hiSuffix);
      }
    } else {
      // Middle insertion: rank sits between beforeBlock and afterBlock
      const beforeRow = this.stmt('blockRankById',
        `SELECT lexo_rank FROM diary_blocks WHERE id = ?`
      ).get(beforeBlockId) as { lexo_rank: string } | undefined;

      if (!beforeRow) {
        logger.error('diary_repository', `reorderBlockByNeighbors: beforeBlockId '${beforeBlockId}' not found`, { tags: HBP_LOG_TAG.DATABASE });
        return;
      }
      newRank = this._lexoRankAfter(entryId, beforeRow.lexo_rank);
    }

    this.reorderBlock(blockId, newRank);
    logger.debug('diary_repository', `Reordered block ${blockId} → rank: ${newRank}`, { tags: HBP_LOG_TAG.DATABASE });
  }

  /**
   * Get the lexo_rank of a single block by ID. O(1) PK lookup.
   */
  getBlockLexoRank(blockId: string): string | null {
    const row = this.stmt('blockRankById',
      `SELECT lexo_rank FROM diary_blocks WHERE id = ?`
    ).get(blockId) as { lexo_rank: string } | undefined;
    return row?.lexo_rank ?? null;
  }

  /**
   * Get the entry_id for a given block. O(1) PK lookup.
   * Used by SduiActionHandler.reorder_block to resolve the entry scope
   * for lexo_rank computation without requiring the client to pass entry_id.
   */
  getEntryIdForBlock(blockId: string): string | null {
    const row = this.stmt('entryIdForBlockPublic',
      `SELECT entry_id FROM diary_blocks WHERE id = ?`
    ).get(blockId) as { entry_id: string } | undefined;
    return row?.entry_id ?? null;
  }

  /**
   * Toggle private/public on a diary entry.
   */
  setPrivate(entryId: string, isPrivate: boolean): void {
    this.stmt('setPrivate',
      `UPDATE diary_entries SET is_private = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(isPrivate ? 1 : 0, entryId);
  }

  /**
   * Update mood and energy score on a diary entry.
   */
  updateEntryMood(entryId: string, moodScore: number | null, energyScore: number | null): void {
    this.stmt('updateEntryMood',
      `UPDATE diary_entries SET mood_score = ?, energy_score = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(moodScore, energyScore, entryId);
  }

  /**
   * Update mood score and preview (summary) on a diary entry.
   */
  updateEntryAnalysis(entryId: string, moodScore: number | null, preview: string | null): void {
    this.stmt('updateEntryAnalysis',
      `UPDATE diary_entries SET mood_score = ?, preview = COALESCE(?, preview), updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(moodScore, preview, entryId);
  }

  /**
   * Update the title of a diary entry.
   */
  updateEntryTitle(entryId: string, title: string): void {
    this.stmt('updateEntryTitle',
      `UPDATE diary_entries SET title = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(title, entryId);
  }

  /**
   * Set is_globally_elevated flag on a diary entry.
   */
  setGloballyElevated(entryId: string, isGloballyElevated: boolean): void {
    this.stmt('setGloballyElevated',
      `UPDATE diary_entries SET is_globally_elevated = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(isGloballyElevated ? 1 : 0, entryId);
  }

  /**
   * Delete a diary entry and all its blocks (CASCADE handles blocks).
   */
  deleteEntry(entryId: string): void {
    this.stmt('deleteEntry',
      `DELETE FROM diary_entries WHERE id = ?`
    ).run(entryId);
  }

  // ── Private helpers ────────────────────────────────────────────────

  /** Maps a raw SQLite row to DiaryEntry interface. */
  private _mapEntry(row: any): DiaryEntry {
    return {
      id:          row.id,
      userId:      row.user_id,
      title:       row.title,
      isPrivate:   row.is_private === 1,
      aiProvider:  row.ai_provider,
      lexoRank:    row.lexo_rank,
      preview:     row.preview,
      moodScore:   row.mood_score !== null && row.mood_score !== undefined ? Number(row.mood_score) : null,
      energyScore: row.energy_score !== null && row.energy_score !== undefined ? Number(row.energy_score) : null,
      isGloballyElevated: row.is_globally_elevated === 1,
      loggedAt:    row.logged_at,
      createdAt:   row.created_at,
      updatedAt:   row.updated_at,
    };
  }

  /** Maps a raw SQLite row to DiaryBlock interface. */
  private _mapBlock(row: any): DiaryBlock {
    return {
      id:           row.id,
      entryId:      row.entry_id,
      blockType:    row.block_type as BlockType,
      content:      row.content,
      lexoRank:     row.lexo_rank,
      sortOrder:    row.sort_order,
      codeLanguage: row.code_language ?? null,
      createdAt:    row.created_at,
      updatedAt:    row.updated_at,
    };
  }

  // ── LexoRank helpers ────────────────────────────────────────────────────
  //
  // We use base-26 (chars 'a'–'z') for the rank suffix after '0|hzzzzz:'.
  // This gives O(1) append-to-end and O(1) midpoint insertion without
  // degeneration. The prefix '0|hzzzzz:' is kept for backwards compatibility
  // with the original entry rows already in the database.
  //
  // Example sequence:  :n  →  :z  →  :zn  →  :zz  →  :zzn …
  // Midpoint of ':n' and ':z' → ':t'  (clean single-char, never degenerates)

  private static readonly RANK_CHARS = 'abcdefghijklmnopqrstuvwxyz';
  private static readonly RANK_MIN   = 'a';
  private static readonly RANK_MID   = 'n';
  private static readonly RANK_MAX   = 'z';

  /**
   * Generates a suffix lexicographically greater than the given one.
   * Monotonic base-26 character increment. O(1) space, O(1) average time.
   */
  private static _nextRankSuffix(suffix: string): string {
    if (!suffix) return DiaryRepository.RANK_MID;
    const lastChar = suffix[suffix.length - 1];
    if (lastChar < DiaryRepository.RANK_MAX) {
      const nextChar = String.fromCharCode(lastChar.charCodeAt(0) + 1);
      return suffix.slice(0, -1) + nextChar;
    } else {
      return suffix + DiaryRepository.RANK_MID;
    }
  }

  /**
   * Returns the lexicographic midpoint string between two base-26 suffix strings.
   */
  private static _midRankSuffix(lo: string, hi: string | undefined): string {
    const CHARS = DiaryRepository.RANK_CHARS;
    const len = Math.max(lo.length, hi?.length ?? 0);

    for (let i = 0; i < len + 1; i++) {
      const loChar = i < lo.length ? CHARS.indexOf(lo[i]) : -1;
      const hiChar = i < (hi?.length ?? 0) ? CHARS.indexOf(hi![i]) : CHARS.length;

      const gap = hiChar - loChar - 1;
      if (gap > 0) {
        const midIdx = loChar + 1 + Math.floor(gap / 2);
        return lo.slice(0, i) + CHARS[midIdx];
      }
    }

    return lo + DiaryRepository.RANK_MID;
  }

  /** Rank for the next entry appended to a user's list. */
  private _nextLexoRank(userId: string): string {
    const last = this.stmt('lastEntryRank',
      `SELECT lexo_rank FROM diary_entries WHERE user_id = ? ORDER BY lexo_rank DESC LIMIT 1`
    ).get(userId) as { lexo_rank: string } | undefined;

    const prefix = '0|hzzzzz:';
    if (!last) return prefix + DiaryRepository.RANK_MID;
    const suffix = last.lexo_rank.startsWith(prefix)
      ? last.lexo_rank.slice(prefix.length)
      : last.lexo_rank;
    return prefix + DiaryRepository._nextRankSuffix(suffix);
  }

  /** Rank for a block appended to the end of an entry's block list. */
  private _nextBlockLexoRank(entryId: string): string {
    const last = this.stmt('lastBlockRank',
      `SELECT lexo_rank FROM diary_blocks WHERE entry_id = ? ORDER BY lexo_rank DESC LIMIT 1`
    ).get(entryId) as { lexo_rank: string } | undefined;

    const prefix = '0|hzzzzz:';
    if (!last) return prefix + DiaryRepository.RANK_MID;
    const suffix = last.lexo_rank.startsWith(prefix)
      ? last.lexo_rank.slice(prefix.length)
      : last.lexo_rank;
    return prefix + DiaryRepository._nextRankSuffix(suffix);
  }

  /**
   * Rank for a block inserted immediately after `afterRank`.
   */
  private _lexoRankAfter(entryId: string, afterRank: string): string {
    const next = this.stmt('nextBlockRankAfter',
      `SELECT lexo_rank FROM diary_blocks
       WHERE entry_id = ? AND lexo_rank > ?
       ORDER BY lexo_rank ASC LIMIT 1`
    ).get(entryId, afterRank) as { lexo_rank: string } | undefined;

    const prefix = '0|hzzzzz:';
    const loSuffix = afterRank.startsWith(prefix) ? afterRank.slice(prefix.length) : afterRank;
    const hiSuffix = next?.lexo_rank.startsWith(prefix)
      ? next.lexo_rank.slice(prefix.length)
      : next?.lexo_rank;

    let mid: string;
    if (hiSuffix === undefined) {
      mid = DiaryRepository._nextRankSuffix(loSuffix);
    } else {
      mid = DiaryRepository._midRankSuffix(loSuffix, hiSuffix);
    }
    return prefix + mid;
  }

  private _nextSortOrder(entryId: string): number {
    const row = this.stmt('maxSortOrder',
      `SELECT COALESCE(MAX(sort_order), -1) as max_ord FROM diary_blocks WHERE entry_id = ?`
    ).get(entryId) as { max_ord: number };
    return row.max_ord + 1;
  }

  getEntryUserIdForBlock(blockId: string): string | null {
    const row = this.stmt('getEntryUserIdForBlock',
      `SELECT e.user_id FROM diary_entries e
       JOIN diary_blocks b ON b.entry_id = e.id
       WHERE b.id = ?`
    ).get(blockId) as { user_id: string } | undefined;
    return row?.user_id ?? null;
  }

  private _refreshPreview(blockId: string): void {
    // Find the entry for this block, grab the first body block's content as preview
    const row = this.stmt('entryIdForBlock',
      `SELECT entry_id FROM diary_blocks WHERE id = ?`
    ).get(blockId) as { entry_id: string } | undefined;

    if (!row) return;

    const firstBody = this.stmt('firstBodyBlock',
      `SELECT content FROM diary_blocks
       WHERE entry_id = ? AND block_type IN ('body', 'quote')
       ORDER BY lexo_rank ASC LIMIT 1`
    ).get(row.entry_id) as { content: string } | undefined;

    const preview = firstBody ? firstBody.content.slice(0, 120) : '';

    this.stmt('updatePreview',
      `UPDATE diary_entries SET preview = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
       WHERE id = ?`
    ).run(preview, row.entry_id);
  }

  getBlockSearchDetails(blockId: string): { blockId: string; content: string; blockType: string; entryId: string; entryTitle: string } | null {
    const row = this.stmt('getBlockSearchDetails',
      `SELECT b.id, b.content, b.block_type, b.entry_id, e.title as entry_title
       FROM diary_blocks b
       JOIN diary_entries e ON e.id = b.entry_id
       WHERE b.id = ?`
    ).get(blockId) as any | undefined;

    return row ? {
      blockId: row.id,
      content: row.content,
      blockType: row.block_type,
      entryId: row.entry_id,
      entryTitle: row.entry_title
    } : null;
  }

  /** RFC 4122 v4 UUID using crypto.randomUUID() — available in Node 14.17+ */
  private _uuid(): string {
    return crypto.randomUUID();
  }

  getModuleConfig(userId: string, moduleId: string): Record<string, any> | null {
    const row = this.stmt('getModuleConfig',
      `SELECT config_json FROM module_config WHERE module_id = ? AND user_id = ?`
    ).get(moduleId, userId) as { config_json: string } | undefined;

    if (!row) return null;
    try {
      return JSON.parse(row.config_json);
    } catch {
      return null;
    }
  }

  saveModuleConfig(userId: string, moduleId: string, config: Record<string, any>): void {
    const jsonStr = JSON.stringify(config);
    this.stmt('saveModuleConfig',
      `INSERT INTO module_config (module_id, user_id, config_json)
       VALUES (?, ?, ?)
       ON CONFLICT (module_id, user_id) DO UPDATE SET config_json = excluded.config_json`
    ).run(moduleId, userId, jsonStr);
  }

  getAiProviderConfig(userId: string): Record<string, any> {
    const config = this.getModuleConfig(userId, 'shua_diary');
    
    return {
      provider: process.env.SHUA_AI_PROVIDER ?? config?.provider ?? process.env.ANALYZER_PROVIDER ?? 'gemini',
      geminiApiKey: config?.geminiApiKey ?? process.env.GEMINI_API_KEY ?? '',
      geminiModel: config?.geminiModel ?? process.env.GEMINI_MODEL ?? 'gemini-2.5-flash',
      ollamaUrl: config?.ollamaUrl ?? process.env.OLLAMA_URL ?? 'http://127.0.0.1:11434/api/chat',
      ollamaModel: config?.ollamaModel ?? process.env.OLLAMA_SENTIMENT_MODEL ?? 'qwen2.5:7b',
      n8nUrl: config?.n8nUrl ?? process.env.N8N_URL ?? 'http://127.0.0.1:5678',
      pythonScriptPath: config?.pythonScriptPath ?? process.env.PYTHON_SCRIPT_PATH ?? path.join(__dirname, '..', '..', 'scripts', 'analyze_sentiment.py')
    };
  }


  saveBlockEmbedding(blockId: string, embedding: number[]): void {
    const floatArray = new Float32Array(embedding);
    const buffer = Buffer.from(floatArray.buffer, floatArray.byteOffset, floatArray.byteLength);
    this.stmt('saveBlockEmbedding',
      `INSERT INTO shua_diary_embeddings (block_id, embedding)
       VALUES (?, ?)
       ON CONFLICT (block_id) DO UPDATE SET embedding = excluded.embedding`
    ).run(blockId, buffer);
  }

  getBlockEmbedding(blockId: string): number[] | null {
    const row = this.stmt('getBlockEmbedding',
      `SELECT embedding FROM shua_diary_embeddings WHERE block_id = ?`
    ).get(blockId) as { embedding: Buffer } | undefined;

    if (!row) return null;
    const floatArray = new Float32Array(row.embedding.buffer, row.embedding.byteOffset, row.embedding.byteLength / 4);
    return Array.from(floatArray);
  }

  getAllEmbeddings(): Array<{ blockId: string; embedding: number[] }> {
    const rows = this.db.prepare(
      `SELECT block_id, embedding FROM shua_diary_embeddings`
    ).all() as Array<{ block_id: string; embedding: Buffer }>;

    return rows.map(r => {
      const floatArray = new Float32Array(r.embedding.buffer, r.embedding.byteOffset, r.embedding.byteLength / 4);
      return {
        blockId: r.block_id,
        embedding: Array.from(floatArray)
      };
    });
  }

  /**
   * Search for diary entries matching the query string in entry title or block contents.
   * Uses SQLite FTS5 index prefix matching for high-performance lookup.
   */
  searchEntries(userId: string, query: string): DiaryEntry[] {
    const terms = query.trim().split(/\s+/).filter(Boolean);
    if (terms.length === 0) return [];

    // Transform search query terms into prefix matcher format e.g. "term*"
    const ftsQuery = terms.map(term => `${term}*`).join(' AND ');

    const rows = this.db.prepare(`
      SELECT DISTINCT e.id, e.user_id, e.title, e.is_private, e.ai_provider, e.lexo_rank, e.preview, e.mood_score, e.energy_score, e.is_globally_elevated, e.logged_at, e.created_at, e.updated_at
      FROM diary_entries e
      LEFT JOIN diary_blocks b ON b.entry_id = e.id
      WHERE e.user_id = ? AND (
        e.id IN (SELECT id FROM diary_entries_fts WHERE diary_entries_fts MATCH ?)
        OR
        b.id IN (SELECT id FROM diary_blocks_fts WHERE diary_blocks_fts MATCH ?)
      )
      ORDER BY e.lexo_rank ASC
    `).all(userId, ftsQuery, ftsQuery) as any[];

    return rows.map(row => this._mapEntry(row));
  }

  /**
   * Fetch FTS5 snippets for the first matching block of each given entry ID.
   * Uses SQLite FTS5 snippet() with markdown bold delimiters so Flutter can
   * render matched words in bold in the search result preview.
   *
   * Returns a Map<entryId, snippetText>. Only entries that have a matching
   * block in diary_blocks_fts will appear in the map.
   *
   * @param entryIds  The entry IDs to fetch snippets for.
   * @param ftsQuery  The FTS5 match expression (e.g. "arch*").
   */
  getSnippetsForEntries(entryIds: string[], ftsQuery: string): Map<string, string> {
    const result = new Map<string, string>();
    if (entryIds.length === 0 || !ftsQuery.trim()) return result;

    // For each entry, find the first matching block and extract a snippet.
    // We query per entry to avoid a cross-product with a large IN clause and
    // to guarantee we get the best-matching block per entry (not any block).
    // On Pi 5 SSD at personal diary scale (<10k blocks) this is sub-millisecond.
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
        if (row?.snip) {
          result.set(entryId, row.snip);
        }
      } catch {
        // FTS5 can throw on malformed queries — skip gracefully
      }
    }

    return result;
  }


  getEntryCount(userId: string): number {
    const row = this.stmt('getEntryCount',
      `SELECT COUNT(*) as count FROM diary_entries WHERE user_id = ?`
    ).get(userId) as { count: number } | undefined;
    return row?.count ?? 0;
  }

  /** Graceful shutdown — call when process exits. */
  close(): void {
    this.db.close();
  }
}

// Singleton instance shared across the process lifetime.
// better-sqlite3 connections are not thread-safe but Node.js is single-threaded,
// so one shared connection is both safe and optimal.
let _repoInstance: DiaryRepository | null = null;

export function getDiaryRepository(): DiaryRepository {
  if (!_repoInstance) {
    _repoInstance = new DiaryRepository();
  }
  return _repoInstance;
}
