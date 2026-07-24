import { Socket } from 'socket.io';
import { getDiaryRepository } from '../diary/diary_repository';
import { DiarySearchService } from '../diary/diary_search_service';
import { SduiDeltaEmitter } from './sdui_delta_emitter';
import { BlockType, DiaryEntry } from '../diary/diary_types';
import { HBP_RPC } from '../models/HbpConstants';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * SduiActionHandler — routes all inbound action RPCs from Flutter to the data layer.
 *
 * Called by SduiOrchestrator for any RPC that is NOT a `request_screen`.
 * These are write/mutate operations initiated by user interactions in Flutter.
 *
 * Optimization notes:
 *  - `save_block` is truly fire-and-forget — no response emitted. DB write is
 *    ~0.1ms synchronous on Pi 5 SSD. Flutter's StateVault already has the value.
 *  - `delete_block` and `create_block` DO emit delta events — the client tree
 *    must be updated since nodes are added/removed (not just content-patched).
 *  - `reorder_block` is fire-and-forget — the client already moved the node
 *    optimistically on drag-end. We only persist the new lexo_rank.
 *  - All methods are static — zero instance allocation per RPC.
 */
export class SduiActionHandler {
  /**
   * Main dispatch method. The orchestrator calls this with the raw RPC payload.
   *
   * @param socket   - The originating client socket (for delta emit responses)
   * @param method   - String method name from the RPC payload
   * @param params   - Params object from the RPC payload
   */
  static handle(socket: Socket, method: string, params: Record<string, any>): void {
    switch (method) {
      case 'shua.diary.save_block':
        SduiActionHandler._saveBlock(params);
        break;

      case 'shua.diary.save_title':
        SduiActionHandler._saveTitle(socket, params);
        break;

      case 'shua.diary.reorder_block':
        SduiActionHandler._reorderBlock(params);
        break;

      case 'shua.diary.delete_block':
        SduiActionHandler._deleteBlock(socket, params);
        break;

      case 'shua.diary.create_block':
        SduiActionHandler._createBlock(socket, params);
        break;

      case 'shua.diary.create_entry':
        SduiActionHandler._createEntry(socket, params);
        break;

      case 'shua.diary.delete_entry':
        SduiActionHandler._deleteEntry(socket, params);
        break;

      case 'shua.diary.set_private':
        SduiActionHandler._setPrivate(socket, params);
        break;

      case 'shua.diary.search':
        SduiActionHandler._searchDiary(socket, params).catch((err: any) => {
          logger.error('sdui_action_handler', `search: Unhandled error: ${err?.message}`, { tags: HBP_LOG_TAG.SDUI });
        });
        break;

      case 'shua.diary.get_blocks':
        SduiActionHandler._getBlocks(socket, params);
        break;

      case 'shua.diary.get_monthly_synthesis':
        SduiActionHandler._getMonthlySynthesis(socket, params);
        break;

      default:
        logger.warn('sdui_action_handler', `Unknown method: '${method}'`, { tags: HBP_LOG_TAG.SDUI });
    }
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  /**
   * save_title — persist entry title updates.
   *
   * Expected params: { entry_id: string, title: string }
   */
  private static _saveTitle(socket: Socket, params: Record<string, any>): void {
    const { entry_id, title } = params;
    if (!entry_id || title === undefined) {
      logger.error('sdui_action_handler', 'save_title: Missing entry_id or title', { tags: HBP_LOG_TAG.SDUI });
      return;
    }
    getDiaryRepository().updateEntryTitle(entry_id as string, title as string);
    logger.info('sdui_action_handler', `save_title: Updated title for entry ${entry_id} to: '${title}'`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });

    // Emit patch for the title in the editor screen
    const editorScreenId = `diary_editor_${entry_id}`;
    const editorTitleNodeId = `${editorScreenId}:title`;
    SduiDeltaEmitter.emitPatch(socket, editorScreenId, editorTitleNodeId, undefined, {
      0: title,
    });

    // Re-assemble and emit full replace for diary_list in background
    const entry = getDiaryRepository().getEntry(entry_id as string);
    const userId = entry ? entry.userId : 'default';

    const { SduiScreenAssembler } = require('./sdui_screen_assembler');
    SduiScreenAssembler.assemble('diary_list', { userId }).then((payload: object | null) => {
      if (!payload) return;
      const { encode } = require('@msgpack/msgpack');
      const arrayPayload = Array.isArray(payload) ? payload : [payload];
      socket.emit('replace_diary_list', encode(arrayPayload));
      logger.info('sdui_action_handler', 'save_title: Emitted replace_diary_list with updated title.', { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
    }).catch((err: any) => {
      logger.error('sdui_action_handler', `save_title: Failed to re-assemble diary_list: ${err?.message}`, { tags: HBP_LOG_TAG.SDUI });
    });
  }

  /**
   * save_block — persist debounced text content from Flutter.
   * No response needed. Flutter StateVault is already up-to-date.
   *
   * Expected params: { block_id: string, content: string }
   */
  private static _saveBlock(params: Record<string, any>): void {
    const { block_id, content } = params;
    if (!block_id || content === undefined) {
      logger.error('sdui_action_handler', 'save_block: Missing block_id or content', { tags: HBP_LOG_TAG.SDUI });
      return;
    }
    const repo = getDiaryRepository();
    repo.updateBlock(block_id as string, content as string);

    // Asynchronously generate and save semantic vector embedding in background
    const userId = repo.getEntryUserIdForBlock(block_id as string) || 'default';
    const { getEmbedding } = require('../ai/embeddings');
    getEmbedding(content as string, userId)
      .then((embedding: number[]) => {
        repo.saveBlockEmbedding(block_id as string, embedding);
        logger.debug('sdui_action_handler', `save_block: Embedding saved for block ${block_id}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      })
      .catch((err: any) => {
        logger.error('sdui_action_handler', `save_block: Failed to generate embedding for block ${block_id}: ${err?.message}`, { tags: HBP_LOG_TAG.AI });
      });
  }

  /**
   * reorder_block — compute and persist new lexo_rank from neighbor IDs.
   *
   * Flutter sends {block_id, before_block_id, after_block_id} — it has no
   * knowledge of LexoRank. The repository owns all rank computation.
   * Fire-and-forget: no emit — Flutter already moved the node optimistically.
   *
   * Expected params:
   *   { block_id: string, before_block_id: string | null, after_block_id: string | null }
   */
  private static _reorderBlock(params: Record<string, any>): void {
    const { block_id, before_block_id, after_block_id } = params;
    if (!block_id) {
      logger.error('sdui_action_handler', 'reorder_block: Missing block_id', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    const repo = getDiaryRepository();

    // Resolve the entry_id — required by _lexoRankAfter() for scope
    const entryId = repo.getEntryIdForBlock(block_id as string);
    if (!entryId) {
      logger.error('sdui_action_handler', `reorder_block: block '${block_id}' has no parent entry`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
      return;
    }

    repo.reorderBlockByNeighbors(
      entryId,
      block_id as string,
      (before_block_id as string | null) ?? null,
      (after_block_id as string | null) ?? null,
    );
    // No emit — Flutter already moved the node optimistically
  }

  /**
   * delete_block — remove block from DB, emit remove delta to client.
   * The client needs the delta because the node must disappear from its tree.
   *
   * Expected params: { block_id: string, entry_id: string }
   */
  private static _deleteBlock(socket: Socket, params: Record<string, any>): void {
    const { block_id, entry_id } = params;
    if (!block_id || !entry_id) {
      logger.error('sdui_action_handler', 'delete_block: Missing block_id or entry_id', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    getDiaryRepository().deleteBlock(block_id as string);
    logger.info('sdui_action_handler', `delete_block: Deleted block ID ${block_id} from entry ${entry_id}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });

    // Emit remove delta for the block wrapper node
    const screenId = `diary_editor_${entry_id}`;
    const wrapperId = `diary_editor_${entry_id}:block_${block_id}:wrapper`;
    SduiDeltaEmitter.emitRemove(socket, screenId, wrapperId);
  }

  /**
   * create_block — persist new block to DB, then emit a full replace of the
   * diary editor screen.
   *
   * WHY full replace instead of insert delta:
   *   The insert delta approach required a valid `after_node_id` from the
   *   block picker. In practice the picker passes an empty string (append mode),
   *   which caused the recursive tree search to no-op silently. A full replace
   *   is simpler, always correct, and consistent with create_entry / delete_entry.
   *
   * Expected params: {
   *   entry_id: string,
   *   block_type: BlockType,
   *   after_lexo_rank?: string,  // rank of the block to insert after (DB ordering)
   * }
   */
  private static _createBlock(socket: Socket, params: Record<string, any>): void {
    const { entry_id, block_type, after_lexo_rank } = params;
    if (!entry_id || !block_type) {
      logger.error('sdui_action_handler', 'create_block: Missing entry_id or block_type', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    // Persist to DB (synchronous, ~0.1ms on SSD)
    getDiaryRepository().createBlock(
      entry_id as string,
      block_type as BlockType,
      after_lexo_rank as string | undefined,
    );

    // Full replace — reassemble the diary editor screen with the new block list
    // and push it to Flutter. Flutter's _onFullReplace listener will update _localNodes.
    const screenId = `diary_editor_${entry_id}`;
    const { SduiScreenAssembler } = require('./sdui_screen_assembler');
    SduiScreenAssembler.assemble(screenId, params).then((payload: object | null) => {
      if (!payload) {
        logger.error('sdui_action_handler', `create_block: Assembler returned null for ${screenId}`, { tags: HBP_LOG_TAG.SDUI });
        return;
      }
      const { encode } = require('@msgpack/msgpack');
      socket.emit(`replace_${screenId}`, encode(Array.isArray(payload) ? payload : [payload]));
      logger.info('sdui_action_handler', `create_block: Emitted replace for ${screenId}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
    }).catch((err: any) => {
      logger.error('sdui_action_handler', `create_block: Failed to assemble ${screenId}: ${err?.message}`, { tags: HBP_LOG_TAG.SDUI });
    });
  }

  /**
   * delete_entry — hard-delete an entry and all its blocks (CASCADE in DB).
   * Emits a remove delta targeting the entry card node in diary_list,
   * then also emits a full replace of diary_list to refresh heatmap + count.
   *
   * Expected params: { entry_id: string, user_id: string }
   */
  private static _deleteEntry(socket: Socket, params: Record<string, any>): void {
    const { entry_id, user_id } = params;
    if (!entry_id) {
      logger.error('sdui_action_handler', 'delete_entry: Missing entry_id', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    getDiaryRepository().deleteEntry(entry_id as string);
    logger.info('sdui_action_handler', `delete_entry: Deleted entry ID ${entry_id} for user ${user_id || 'default'}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });

    // 1. Optimistic node removal — immediately vanish the card from the list
    const cardWrapperId = `diary_list:entry_card_${entry_id}`;
    SduiDeltaEmitter.emitRemove(socket, 'diary_list', cardWrapperId);

    // 2. Full replace to update heatmap and any aggregate counts
    const userId = (user_id as string) || 'default';
    const { SduiScreenAssembler } = require('./sdui_screen_assembler');
    SduiScreenAssembler.assemble('diary_list', { userId }).then((payload: object | null) => {
      if (!payload) return;
      const { encode } = require('@msgpack/msgpack');
      socket.emit('replace_diary_list', encode(Array.isArray(payload) ? payload : [payload]));
    });
  }

  /**
   * search — hybrid FTS5 + RadixTrie search pipeline.
   *
   * Pipeline:
   *   1. Adaptive Levenshtein threshold selection based on query length.
   *   2. RadixTrie search (sync, O(k), zero I/O) — matches titles + tags + headings.
   *   3. FTS5 search (sync SQLite, but yielded to avoid blocking event loop) — matches all block content.
   *   4. Ranked merge: score = (trieHit ? 100 : 0) + (1 / (ftsRank + 1)) * 50
   *      Trie title/tag hits always surface above FTS5-only body content hits.
   *   5. Snippet enrichment:
   *      - Trie hits: prefix preview with tag emoji + matched word.
   *      - FTS5 hits: replace preview with SQLite snippet() for contextual bold excerpts.
   *   6. Emit ranked, enriched list via replace_diary_list.
   *
   * Expected params: { search_query: string, user_id: string }
   *
   * Complexity:
   *   - Trie search:  O(k) where k = query length.
   *   - FTS5 search:  O(log N) via FTS5 inverted index.
   *   - Merge:        O(M log M) where M = combined result count.
   *   - Snippet fetch: O(hits) per-entry prepared stmt, sub-ms each on Pi 5 SSD.
   */
  private static async _searchDiary(socket: Socket, params: Record<string, any>): Promise<void> {
    const query = ((params.search_query as string) ?? (params.query as string) ?? '').trim();
    const userId = (params.user_id as string) || 'default';

    if (!query) {
      // Empty query — emit full unfiltered list
      const { SduiScreenAssembler } = require('./sdui_screen_assembler');
      const payload = await SduiScreenAssembler.assemble('diary_list', { userId });
      if (!payload) return;
      const { encode } = require('@msgpack/msgpack');
      socket.emit('replace_diary_list', encode(Array.isArray(payload) ? payload : [payload]));
      return;
    }

    const repo = getDiaryRepository();

    // ── 1. Adaptive Levenshtein distance threshold ─────────────────────────
    const qLen = query.length;
    const maxDistance = qLen <= 4 ? 0 : qLen <= 7 ? 1 : 2;

    // ── 2. Trie search (synchronous, O(k), zero I/O) ──────────────────────
    const trieMatches = DiarySearchService.getInstance().search(query, maxDistance);
    const trieEntryIds = new Set(Object.keys(trieMatches));

    // ── 3. FTS5 search (synchronous SQLite, yielded async) ────────────────
    // Yield to event loop so WebSocket keepalives are not starved during the DB call.
    const ftsResults: DiaryEntry[] = await Promise.resolve(repo.searchEntries(userId, query));
    // FTS5 result is ordered by BM25 rank (best first). We use position as a
    // rank proxy: ftsRank = 0 (best match) .. N-1 (worst match).
    const ftsRankMap = new Map<string, number>(ftsResults.map((e, i) => [e.id, i]));

    // ── 4. Merge ──────────────────────────────────────────────────
    // Union of trie + FTS5 entry IDs, scored and sorted descending.
    const allEntryIds = new Set<string>([
      ...trieEntryIds,
      ...ftsResults.map(e => e.id),
    ]);

    // Build a lookup map for full entry objects from both sources
    const entryMap = new Map<string, DiaryEntry>();
    // Populate from FTS5 results first
    for (const e of ftsResults) entryMap.set(e.id, e);
    // Fill any trie-only hits (entries that matched title/tag but not block content)
    if (trieEntryIds.size > 0) {
      const trieOnlyIds = [...trieEntryIds].filter(id => !entryMap.has(id));
      if (trieOnlyIds.length > 0) {
        const trieOnlyEntries = repo.getEntriesList(userId).filter(e => trieEntryIds.has(e.id));
        for (const e of trieOnlyEntries) entryMap.set(e.id, e);
      }
    }

    // Score each entry
    interface ScoredEntry { entry: DiaryEntry; score: number; }
    const scored: ScoredEntry[] = [];
    for (const entryId of allEntryIds) {
      const entry = entryMap.get(entryId);
      if (!entry) continue;

      const trieBonus   = trieEntryIds.has(entryId) ? 100 : 0;
      const ftsRank     = ftsRankMap.get(entryId);
      // Normalize FTS5 rank to 0-50 range (position 0 = 50pts, higher positions decay)
      const ftsScore    = ftsRank !== undefined ? Math.max(0, 50 - ftsRank) : 0;
      const score       = trieBonus + ftsScore;

      scored.push({ entry, score });
    }

    scored.sort((a, b) => b.score - a.score);

    // ── 5. Snippet enrichment ────────────────────────────────────────
    const ftsQuery = query.trim().split(/\s+/).filter(Boolean).map(t => `${t}*`).join(' AND ');
    const ftsOnlyIds = scored
      .filter(s => !trieEntryIds.has(s.entry.id) && ftsRankMap.has(s.entry.id))
      .map(s => s.entry.id);
    const snippets = repo.getSnippetsForEntries(ftsOnlyIds, ftsQuery);

    // Apply preview enrichment in-place
    for (const { entry } of scored) {
      const trieHit = trieEntryIds.has(entry.id);
      if (trieHit) {
        // Pick the best (lowest distance) matched word from the trie
        const matches = trieMatches[entry.id] ?? [];
        if (matches.length > 0) {
          const best = matches.reduce((a, b) => a.distance <= b.distance ? a : b);
          const prefixLabel = best.distance === 0 ? 'Match' : 'Almost a Match';
          if (best.blockId.startsWith('__title__')) {
            entry.preview = `🏷️ ${prefixLabel}: ${best.word} — ${entry.preview}`;
          } else {
            const blockDetails = repo.getBlockSearchDetails(best.blockId);
            const contentToShow = blockDetails?.content ? blockDetails.content.trim() : entry.preview;
            entry.preview = `🏷️ ${prefixLabel}: ${best.word} — ${contentToShow}`;
          }
        }
      } else {
        // FTS5-only hit: use snippet as preview if available
        const snip = snippets.get(entry.id);
        if (snip) entry.preview = snip;
      }
    }

    // ── 6. Assemble the list screen with enriched, ranked entries ─────────
    const { SduiScreenAssembler } = require('./sdui_screen_assembler');
    const payload = await SduiScreenAssembler.assemble('diary_list', {
      userId,
      _prebuiltEntries: scored.map(s => s.entry),
    });

    if (!payload) return;
    const { encode } = require('@msgpack/msgpack');
    socket.emit('replace_diary_list', encode(Array.isArray(payload) ? payload : [payload]));
    logger.info('sdui_action_handler', `search: Merged trie(${trieEntryIds.size}) + FTS5(${ftsResults.length}) → ${scored.length} results for query: '${query}'`, {
      tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE,
    });
  }

  /**
   * create_entry — create a new diary entry, emit full replace of diary_list.
   * This is the only action that triggers a full screen replace (not a delta),
   * because the list card order and count have changed.
   *
   * Expected params: { user_id: string, title: string, ai_provider?: string }
   */
  private static _createEntry(socket: Socket, params: Record<string, any>): void {
    const { user_id, title, ai_provider } = params;
    if (!user_id || !title) {
      logger.error('sdui_action_handler', 'create_entry: Missing user_id or title', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    getDiaryRepository().createEntry(
      user_id as string,
      title as string,
      ai_provider as string | undefined,
    );
    logger.info('sdui_action_handler', `create_entry: Created entry '${title}' for user ${user_id}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });

    // Full screen replace — import assembler inline to avoid circular dep at module level
    const { SduiScreenAssembler } = require('./sdui_screen_assembler');
    SduiScreenAssembler.assemble('diary_list', { userId: user_id }).then((payload: object | null) => {
      if (!payload) return;
      const { encode } = require('@msgpack/msgpack');
      const arrayPayload = Array.isArray(payload) ? payload : [payload];
      socket.emit('replace_diary_list', encode(arrayPayload));
      logger.info('sdui_action_handler', `create_entry: Emitted replace_diary_list for user ${user_id}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
    });
  }

  /**
   * set_private — toggle privacy lock on an entry.
   * Emits a patch delta to update just the lock button icon on the diary_list card.
   *
   * Expected params: { entry_id: string, is_private: boolean }
   */
  private static _setPrivate(socket: Socket, params: Record<string, any>): void {
    const { entry_id, is_private } = params;
    if (!entry_id || is_private === undefined) {
      logger.error('sdui_action_handler', 'set_private: Missing entry_id or is_private', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    getDiaryRepository().setPrivate(entry_id as string, is_private as boolean);
    logger.info('sdui_action_handler', `set_private: Set privacy for entry ${entry_id} to: ${is_private}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });

    const lockBtnNodeId = `diary_list:entry_card_${entry_id}:lock_btn`;
    SduiDeltaEmitter.emitPatch(socket, 'diary_list', lockBtnNodeId, {
      70: { "0": 1, "1": 114, "4": { "entry_id": entry_id, "is_private": !is_private } }
    }, {
      3: is_private ? 'lock' : 'lock_open',
    });
  }

  /**
   * get_blocks — assemble blocks for diary editor and send full replace screen payload.
   *
   * Expected params: { entry_id: string }
   */
  private static _getBlocks(socket: Socket, params: Record<string, any>): void {
    const { entry_id } = params;
    if (!entry_id) {
      logger.error('sdui_action_handler', 'get_blocks: Missing entry_id', { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    const screenId = `diary_editor_${entry_id}`;
    const { SduiScreenAssembler } = require('./sdui_screen_assembler');
    SduiScreenAssembler.assemble(screenId, params).then((payload: object | null) => {
      if (!payload) return;
      const { encode } = require('@msgpack/msgpack');
      const arrayPayload = Array.isArray(payload) ? payload : [payload];
      socket.emit(`replace_${screenId}`, encode(arrayPayload));
      logger.info('sdui_action_handler', `get_blocks: Sent replace for '${screenId}'`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
    }).catch((err: any) => {
      logger.error('sdui_action_handler', `get_blocks: Failed to assemble ${screenId}: ${err?.message}`, { tags: HBP_LOG_TAG.SDUI });
    });
  }

  /**
   * get_monthly_synthesis — trigger monthly synthesis for a user, then reassemble diary_list.
   *
   * Expected params: { user_id?: string }
   */
  private static _getMonthlySynthesis(socket: Socket, params: Record<string, any>): void {
    const userId = (params.user_id as string) || 'default';
    
    const { checkAndSynthesizeForUser } = require('../ai/monthly_synthesis');
    checkAndSynthesizeForUser(userId).then((entryId: string | null) => {
      logger.info('sdui_action_handler', `get_monthly_synthesis: Done for user ${userId}. Entry ID: ${entryId}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      
      const { SduiScreenAssembler } = require('./sdui_screen_assembler');
      return SduiScreenAssembler.assemble('diary_list', { userId });
    }).then((payload: object | null) => {
      if (!payload) return;
      const { encode } = require('@msgpack/msgpack');
      const arrayPayload = Array.isArray(payload) ? payload : [payload];
      socket.emit('replace_diary_list', encode(arrayPayload));
      logger.info('sdui_action_handler', 'get_monthly_synthesis: Sent replace payload for diary_list', { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
    }).catch((err: any) => {
      logger.error('sdui_action_handler', `get_monthly_synthesis: Failed: ${err?.message}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
    });
  }
}
