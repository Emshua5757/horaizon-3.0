import { RadixTrie, SearchMatchDetail } from '../utils/RadixTrie';
import { DiaryEntry, DiaryBlock } from './diary_types';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * DiarySearchService — singleton in-memory search index over diary entry titles,
 * heading blocks, and tag_cloud blocks.
 *
 * Architecture contract:
 *   - The trie is NEVER mutated mid-keystroke (not on save_block).
 *   - Reconciliation is pull-based: called by _assembleDiaryList each time the
 *     diary list screen is loaded. This is the only moment freshness matters.
 *   - FTS5 (diary_blocks_fts) handles deep block content search and BM25 ranking.
 *     This service provides fast O(k) prefix/fuzzy matching for titles + tags.
 *
 * Indexed block types (light — text-bearing identity fields only):
 *   body | heading_1 | heading_2 | heading_3 | quote | caption |
 *   tag_cloud | bullet_list | numbered_list | code | toggle_section
 *
 * Block types intentionally excluded from the trie:
 *   divider, mood_rating, energy_slider, progress_tracker, date_log, time_log,
 *   checkbox_single, data_table, timeline_entry, chart_block, html_embed,
 *   document_attach, poll_choice, dropdown_select, map_pin
 *   (these contain integers, dates, or binary data — not useful for prefix search)
 */

/** Block types whose content is indexed into the RadixTrie. */
const INDEXABLE_BLOCK_TYPES = new Set<string>([
  'body', 'heading_1', 'heading_2', 'heading_3',
  'quote', 'caption', 'tag_cloud',
  'bullet_list', 'numbered_list', 'code', 'toggle_section',
]);

/** Minimum token length to index. Avoids polluting trie with stop-word noise. */
const MIN_TOKEN_LENGTH = 2;

/**
 * Tokenize a text string into lowercase word tokens.
 * Splits on whitespace and common punctuation (comma, period, colon, etc.).
 * Deduplicates within the returned set.
 */
function tokenize(text: string): Set<string> {
  const tokens = new Set<string>();
  for (const raw of text.split(/[\s,.:;!?()\[\]{}"'`\/\\|#@$%^&*+=~<>]+/)) {
    const t = raw.toLowerCase().trim();
    if (t.length >= MIN_TOKEN_LENGTH) {
      tokens.add(t);
    }
  }
  return tokens;
}

export class DiarySearchService {
  private static _instance: DiarySearchService | null = null;

  private trie: RadixTrie;

  /**
   * indexedWordsByBlock: blockId -> Set of words indexed for that block.
   * Used for surgical per-block removal (if a block is deleted mid-reconcile).
   */
  private indexedWordsByBlock: Map<string, Set<string>> = new Map();

  /**
   * indexedWordsByEntry: entryId -> Set of all words indexed for that entry
   * (union of title tokens + all block tokens).
   * Used for fast full-entry removal on ghost detection.
   */
  private indexedWordsByEntry: Map<string, Set<string>> = new Map();

  /**
   * lastIndexedAtByEntry: entryId -> Unix timestamp (ms) of the entry's
   * updated_at at the time it was last indexed.
   * O(1) staleness check -- compare against DB updated_at.
   */
  private lastIndexedAtByEntry: Map<string, number> = new Map();

  private constructor() {
    this.trie = new RadixTrie();
  }

  public static getInstance(): DiarySearchService {
    if (!DiarySearchService._instance) {
      DiarySearchService._instance = new DiarySearchService();
    }
    return DiarySearchService._instance;
  }

  // -- Public API --

  /**
   * Index a single diary entry and its blocks into the trie.
   * Performs a full remove-then-reindex if the entry was previously indexed
   * (safe to call repeatedly -- idempotent given same data).
   *
   * Indexed tokens:
   *   1. All tokens from entry.title
   *   2. All tokens from blocks whose blockType is in INDEXABLE_BLOCK_TYPES
   *
   * Complexity: O(W * k) where W = total word count, k = avg word length.
   */
  public indexEntry(entry: DiaryEntry, blocks: DiaryBlock[]): void {
    // Remove any existing index for this entry before re-indexing
    if (this.lastIndexedAtByEntry.has(entry.id)) {
      this.removeEntry(entry.id);
    }

    const entryWordSet = new Set<string>();

    // 1. Index title tokens
    for (const word of tokenize(entry.title)) {
      this.trie.insert(word, `__title__${entry.id}`, entry.id);
      entryWordSet.add(word);
    }

    // 2. Index indexable block tokens
    for (const block of blocks) {
      if (!INDEXABLE_BLOCK_TYPES.has(block.blockType)) continue;
      if (!block.content || block.content.trim().length === 0) continue;

      const blockWords = tokenize(block.content);
      for (const word of blockWords) {
        this.trie.insert(word, block.id, entry.id);
        entryWordSet.add(word);
      }

      this.indexedWordsByBlock.set(block.id, blockWords);
    }

    this.indexedWordsByEntry.set(entry.id, entryWordSet);
    this.lastIndexedAtByEntry.set(entry.id, Date.parse(entry.updatedAt));
  }

  /**
   * Remove all trie entries for a given diary entry.
   * Iterates the full word set for this entry and calls trie.remove() for each.
   *
   * Complexity: O(W * k) where W = word count for this entry, k = avg word length.
   */
  public removeEntry(entryId: string): void {
    const words = this.indexedWordsByEntry.get(entryId);
    if (!words) return;

    for (const word of words) {
      this.trie.remove(word, entryId);
    }

    // Clean up reverse-lookup maps
    this.indexedWordsByEntry.delete(entryId);
    this.lastIndexedAtByEntry.delete(entryId);
  }

  /**
   * Pull-based reconciliation against the current database snapshot.
   *
   * Algorithm (two passes, O(N)):
   *   Pass 1 -- Ghost deletion: entries in the trie that no longer exist in the DB.
   *   Pass 2 -- Stale/new detection: entries that are new or have updated_at > last indexed.
   *
   * The fetchBlocksFn callback is called ONLY for stale/new entries -- not for every
   * entry on every reconcile. On a typical list load where nothing changed, the
   * callback fires 0 times (amortized O(N) comparisons, O(0) block fetches).
   *
   * @param dbEntries       Lightweight metadata from DB: { id, updatedAt (ISO string) }[]
   * @param fetchBlocksFn   Callback to load blocks for a given entryId (synchronous)
   * @param fullEntries     Full DiaryEntry[] for re-indexing (same list, typed)
   */
  public reconcile(
    dbEntries: { id: string; updatedAt: string }[],
    fetchBlocksFn: (entryId: string) => DiaryBlock[],
    fullEntries: DiaryEntry[],
  ): void {
    // Build a fast O(1) lookup set for ghost detection
    const dbIdSet = new Set(dbEntries.map(e => e.id));

    // Pass 1: Ghost deletion -- indexed entries that are no longer in the DB
    let ghostCount = 0;
    for (const indexedId of Array.from(this.lastIndexedAtByEntry.keys())) {
      if (!dbIdSet.has(indexedId)) {
        this.removeEntry(indexedId);
        ghostCount++;
      }
    }

    if (ghostCount > 0) {
      logger.debug('diary_search_service', `Reconcile: removed ${ghostCount} ghost entries from trie`, {
        tags: HBP_LOG_TAG.DATABASE,
      });
    }

    // Build a fast lookup for full DiaryEntry objects (needed for re-index)
    const fullEntryMap = new Map<string, DiaryEntry>(fullEntries.map(e => [e.id, e]));

    // Pass 2: Stale/new detection
    let reindexCount = 0;
    for (const { id, updatedAt } of dbEntries) {
      const dbTimestamp = Date.parse(updatedAt);
      const indexedTimestamp = this.lastIndexedAtByEntry.get(id);

      const isNew = indexedTimestamp === undefined;
      const isStale = !isNew && dbTimestamp > indexedTimestamp!;

      if (isNew || isStale) {
        const fullEntry = fullEntryMap.get(id);
        if (!fullEntry) continue;

        const blocks = fetchBlocksFn(id);
        this.indexEntry(fullEntry, blocks);
        reindexCount++;
      }
    }

    if (reindexCount > 0) {
      logger.debug('diary_search_service', `Reconcile: re-indexed ${reindexCount} entries`, {
        tags: HBP_LOG_TAG.DATABASE,
      });
    }
  }

  /**
   * Search the trie for entries matching the query.
   *
   * Returns the raw SearchMatchDetail map so the caller can apply scoring/ranking.
   * The caller (SduiActionHandler._searchDiary) owns the merge logic with FTS5.
   *
   * @param query       The search query string.
   * @param maxDistance  Levenshtein distance threshold (0 = exact prefix only).
   */
  public search(query: string, maxDistance: number): { [entryId: string]: SearchMatchDetail[] } {
    if (!query || query.trim().length === 0) return {};
    return this.trie.searchWithMatches(query.trim().toLowerCase(), maxDistance);
  }

  /**
   * Returns the total number of entries currently indexed in the trie.
   * Useful for diagnostics / log assertions.
   */
  public get indexedEntryCount(): number {
    return this.lastIndexedAtByEntry.size;
  }
}
