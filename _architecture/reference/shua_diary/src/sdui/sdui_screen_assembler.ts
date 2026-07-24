import fs from 'fs';
import path from 'path';
import { SduiNodeBuilder } from './sdui_node_builder';
import { SduiBlueprintLoader } from './sdui_blueprint_loader';
import { SduiBlockRegistry } from './sdui_block_registry';
import { getDiaryRepository } from '../diary/diary_repository';
import { DiarySearchService } from '../diary/diary_search_service';
import {
  HBP_WIDGET, HBP_BEHAVIOR, HBP_CONTENT,
  HBP_DISPLAY_MODE, HBP_INTERACTIVE, HBP_BUTTON_VARIANT, HBP_COLOR_TOKEN, HBP_RPC,
} from '../models/HbpConstants';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * SduiScreenAssembler — owns the "which screen → which DB queries → which AST" logic.
 *
 * This is the only file that knows what screen_ids exist. The orchestrator routes
 * transport; the assembler routes content. Separation of concerns.
 *
 * Blueprints are loaded from `schemas/blueprints/diary/` subdirectory via
 * SduiBlueprintLoader.loadBlueprint('diary/diary') path notation.
 * Block nodes are assembled using SduiBlockRegistry (JSON-driven), not hardcoded maps.
 *
 * Returns a single root node object, or an array of root nodes (editor screen), ready
 * for encode(). Returns null on unknown screenId or DB error.
 */
export class SduiScreenAssembler {
  static async assemble(screenId: string, params: Record<string, any>): Promise<object | null> {
    try {
      if (screenId === 'diary_list') {
        return SduiScreenAssembler._assembleDiaryList(params);
      }

      if (screenId === 'diary_ai_config') {
        return SduiScreenAssembler._assembleDiaryAiConfig(params);
      }

      if (screenId === 'diary_ai_prompt') {
        return SduiScreenAssembler._assembleDiaryAiPromptModal(params);
      }

      if (screenId.startsWith('diary_options_')) {
        const entryId = screenId.replace('diary_options_', '');
        return SduiScreenAssembler._assembleDiaryOptionsModal(entryId);
      }

      if (screenId.startsWith('diary_block_picker_')) {
        const entryId = screenId.replace('diary_block_picker_', '');
        return SduiScreenAssembler._assembleDiaryBlockPicker(entryId);
      }

      if (screenId.startsWith('diary_editor_')) {
        const entryId = screenId.replace('diary_editor_', '');
        return SduiScreenAssembler._assembleDiaryEditor(entryId);
      }

      logger.error('sdui_screen_assembler', `Unknown screenId: '${screenId}'`, { tags: HBP_LOG_TAG.SDUI });
      return null;
    } catch (err) {
      logger.error('sdui_screen_assembler', `Failed to assemble '${screenId}': ${err}`, { tags: HBP_LOG_TAG.SDUI });
      return null;
    }
  }

  // ── Screen: diary_list ──────────────────────────────────────────

  private static _assembleDiaryList(params: Record<string, any>): object {
    const repo = getDiaryRepository();
    const userId = (params.userId as string) ?? 'default';
    const query = (params.search_query as string) ?? '';

    // ── Fast path: pre-ranked entries from the hybrid search action handler ─
    // When _searchDiary has already done the full FTS5+Trie merge + snippet
    // enrichment, it passes the result as _prebuiltEntries to skip the DB
    // re-query. We still need allEntries for heatmap computation, but we skip
    // the trie reconcile and entry-filter logic entirely.
    const prebuiltEntries = params._prebuiltEntries as import('../diary/diary_types').DiaryEntry[] | undefined;

    // ── Pull-based Trie Reconciliation ─────────────────────────────────────
    // Runs on every list load UNLESS we have prebuilt entries (search path).
    // Fetches lightweight metadata (id + updated_at) and reconciles the trie —
    // re-indexing only stale or new entries.
    const allEntries = repo.getEntriesList(userId);
    if (!prebuiltEntries) {
      const entryMeta = allEntries.map(e => ({ id: e.id, updatedAt: e.updatedAt }));
      DiarySearchService.getInstance().reconcile(
        entryMeta,
        (entryId) => repo.getEntryBlocks(entryId),
        allEntries,
      );
    }

    // ── Entry list resolution ───────────────────────────────────────────────
    let entries: import('../diary/diary_types').DiaryEntry[];
    if (prebuiltEntries) {
      // Pre-ranked by the hybrid search pipeline — use directly.
      entries = prebuiltEntries;
    } else if (query.trim()) {
      const qLen = query.trim().length;
      const maxDistance = qLen <= 4 ? 0 : qLen <= 7 ? 1 : 2;
      const trieHits = DiarySearchService.getInstance().search(query.trim(), maxDistance);
      const trieEntryIds = new Set(Object.keys(trieHits));
      // Fall back to FTS5 result if trie has no hits (content-only match)
      entries = trieEntryIds.size > 0
        ? allEntries.filter(e => trieEntryIds.has(e.id))
        : repo.searchEntries(userId, query.trim());
    } else {
      entries = allEntries;
    }

    logger.debug('sdui_screen_assembler', `Loaded ${entries.length} entries for user '${userId}'`, {
      tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE,
      telemetry: { count: entries.length, userId, query: query || undefined },
    });

    // Compute target month mood timeline averages and padding layout
    const now = new Date();
    const targetDate = new Date(now.getFullYear(), now.getMonth(), 1);
    const year = targetDate.getFullYear();
    const month = targetDate.getMonth();
    const lastDay = new Date(year, month + 1, 0).getDate();
    const startWeekday = new Date(year, month, 1).getDay();

    const timeline = repo.getMoodTimeline(userId, 0);
    const moodSums = new Map<number, number>();
    const moodCounts = new Map<number, number>();
    for (const item of timeline) {
      if (item.date && item.moodScore !== null) {
        const d = new Date(item.date);
        if (!isNaN(d.getTime())) {
          const dateKey = d.getDate();
          moodSums.set(dateKey, (moodSums.get(dateKey) ?? 0) + item.moodScore);
          moodCounts.set(dateKey, (moodCounts.get(dateKey) ?? 0) + 1);
        }
      }
    }

    const cells: Array<{ key: string | null; val: number | null; lbl: string }> = [];

    // Weekday start padding
    for (let i = 0; i < startWeekday; i++) {
      cells.push({ key: null, val: null, lbl: '' });
    }

    // Calendar days
    for (let day = 1; day <= lastDay; day++) {
      const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      const sum = moodSums.get(day);
      const count = moodCounts.get(day);
      const val = (sum !== undefined && count !== undefined) ? sum / count : null;
      cells.push({
        key: dateStr,
        val: val,
        lbl: String(day)
      });
    }

    // Weekday end padding to complete final grid row
    const remainder = cells.length % 7;
    if (remainder > 0) {
      for (let i = 0; i < 7 - remainder; i++) {
        cells.push({ key: null, val: null, lbl: '' });
      }
    }

    const context = {
      screen_id: 'diary_list',
      username: userId,
      heatmap_cells: JSON.stringify(cells),
      heatmap_headers: JSON.stringify({ cols: ['S', 'M', 'T', 'W', 'T', 'F', 'S'] }),
      diary_entries: entries.map(e => ({
        id: e.id,
        username: userId,
        title: e.title,
        preview: e.preview,
        is_private: e.isPrivate,
        created_at: e.createdAt,
        mood_score: e.moodScore,
        energy_score: e.energyScore,
        is_globally_elevated: e.isGloballyElevated,
        logged_at: e.loggedAt,
        sentiment_label: e.moodScore !== null ? `Mood: ${e.moodScore.toFixed(1)}` : 'Unanalyzed',
        sentiment_icon: e.moodScore !== null
          ? (e.moodScore < -0.2 ? 'sentiment_dissatisfied' : e.moodScore > 0.2 ? 'sentiment_satisfied' : 'sentiment_neutral')
          : 'help_outline',
        sentiment_color: e.moodScore !== null
          ? (e.moodScore < -0.2 ? HBP_COLOR_TOKEN.ERROR : e.moodScore > 0.2 ? HBP_COLOR_TOKEN.PRIMARY : HBP_COLOR_TOKEN.SECONDARY)
          : HBP_COLOR_TOKEN.OUTLINE,
        is_private_int: e.isPrivate ? 1 : 0,
        lock_icon: e.isPrivate ? 'lock' : 'lock_open',
        next_privacy_state: !e.isPrivate,
      })),
    };

    return SduiNodeBuilder.buildScreen('diary/diary', 'diary_list', context);
  }

  // ── Screen: diary_editor_{entryId} ─────────────────────────────

  private static _assembleDiaryEditor(entryId: string): object {
    const repo = getDiaryRepository();
    const entryData = repo.getEntryWithBlocks(entryId);

    if (!entryData) {
      return {
        '0': HBP_WIDGET.MARKDOWNEDITOR,
        'id': `diary_editor_${entryId}:not_found`,
        '3': { [HBP_BEHAVIOR.DISPLAY_MODE]: HBP_DISPLAY_MODE.BODY, [HBP_BEHAVIOR.INTERACTIVE_MODE]: HBP_INTERACTIVE.READONLY },
        '4': { [HBP_CONTENT.VALUE]: 'Entry not found.' },
      };
    }

    const { entry, blocks } = entryData;

    // 1. Load blueprint and clone
    const blueprint = SduiBlueprintLoader.loadBlueprint('diary/diary_editor');
    const screenTemplate = blueprint['diary_editor'];
    if (!screenTemplate) {
      throw new Error(`[SduiScreenAssembler] Screen 'diary_editor' not found in blueprint`);
    }
    const screenNode = JSON.parse(JSON.stringify(screenTemplate));

    // 2. Find raw blocks_list to extract template before hydration (since hydration strips 'template')
    const blocksListIdRaw = 'diary_editor_{{entry_id}}:blocks_list';
    const blocksListRaw = findNodeById(screenNode, blocksListIdRaw);
    if (!blocksListRaw) {
      throw new Error(`[SduiScreenAssembler] blocks_list container not found in raw blueprint`);
    }
    const templateNode = blocksListRaw.template;
    if (!templateNode) {
      throw new Error(`[SduiScreenAssembler] template block wrapper not found in blocks_list raw blueprint`);
    }

    // 3. Hydrate the root shell node
    const hydratedScreen = SduiNodeBuilder.hydrateNode(screenNode, {
      entry_id: entryId,
      title: entry.title,
    });

    // 4. Find hydrated blocks_list container
    const blocksListIdHydrated = `diary_editor_${entryId}:blocks_list`;
    const blocksList = findNodeById(hydratedScreen, blocksListIdHydrated);
    if (!blocksList) {
      throw new Error(`[SduiScreenAssembler] blocks_list container not found in hydrated blueprint`);
    }

    // Ensure children array exists and is empty
    blocksList['2'] = [];

    // 5. Populate and hydrate polymorphic children blocks
    for (const block of blocks) {
      // Clone wrapper template
      const wrapperClone = JSON.parse(JSON.stringify(templateNode));

      // Retrieve spec from block registry
      const spec = SduiBlockRegistry.get(block.blockType);

      // Merge wrapperBehaviors
      wrapperClone['3'] = {
        ...(wrapperClone['3'] || {}),
        ...spec.wrapperBehaviors,
      };

      // Hydrate the wrapper clone (resolves IDs and general fields)
      const hydratedWrapper = SduiNodeBuilder.hydrateNode(wrapperClone, {
        entry_id: entryId,
        block_id: block.id,
      });

      // Generate content node (fully resolved and populated)
      const { contentNode } = SduiBlockRegistry.buildContentNode(
        block.blockType,
        block.id,
        entryId,
        block.content,
        block.codeLanguage,
      );

      // Replace placeholder content child inside hydrated wrapper
      if (hydratedWrapper['2'] && Array.isArray(hydratedWrapper['2'])) {
        const targetId = `diary_editor_${entryId}:block_${block.id}:content`;
        let contentIndex = hydratedWrapper['2'].findIndex((child: any) => child && child.id === targetId);
        if (contentIndex === -1) {
          contentIndex = 1; // Fallback to index 1
        }

        const templateChild = hydratedWrapper['2'][contentIndex];
        if (templateChild && templateChild['3']) {
          const templateFlex = templateChild['3']['14'];
          if (templateFlex !== undefined) {
            contentNode['3'] = {
              ...(contentNode['3'] || {}),
              '14': templateFlex,
            };
          }
        }
        hydratedWrapper['2'][contentIndex] = contentNode;
      }

      blocksList['2'].push(hydratedWrapper);
    }

    return hydratedScreen;
  }

  private static _assembleDiaryAiConfig(params: Record<string, any>): object {
    const repo = getDiaryRepository();
    const userId = (params.userId as string) ?? 'default';
    const config = repo.getAiProviderConfig(userId);

    const provider = config.provider || 'gemini';

    const context = {
      screen_id: 'diary_ai_config',
      provider_gemini: provider === 'gemini',
      provider_ollama: provider === 'ollama',
      provider_python_semantics: provider === 'python_semantics',
      provider_n8n: provider === 'n8n',
      geminiApiKey: config.geminiApiKey || '',
      geminiModel: config.geminiModel || '',
      ollamaUrl: config.ollamaUrl || '',
      ollamaModel: config.ollamaModel || '',
      pythonScriptPath: config.pythonScriptPath || '',
    };

    return SduiNodeBuilder.buildScreen('diary/diary', 'diary_ai_config', context);
  }

  /**
   * Assembles the block-picker bottom sheet for a given entry.
   *
   * Loads diary_block_picker.json blueprint and hydrates:
   *   {{entry_id}}      — the entry to insert blocks into
   *   {{after_node_id}} — the wrapper node to insert after (empty = append to end)
   *
   * The Wrap of Chips each fire create_block (RPC 112) with block_type + entry_id
   * already baked into the action params — no server-side logic needed per-chip.
   *
   * Performance: O(1) — single file read (cached by SduiBlueprintLoader), then
   * one JSON.parse + JSON.stringify clone + string template replace pass.
   */
  private static _assembleDiaryBlockPicker(entryId: string, afterNodeId: string = ''): object {
    // 1. Load blueprint and clone
    const blueprint = SduiBlueprintLoader.loadBlueprint('diary/diary_block_picker');
    const screenTemplate = blueprint['diary_block_picker'];
    if (!screenTemplate) {
      throw new Error(`[SduiScreenAssembler] Screen 'diary_block_picker' not found in blueprint`);
    }
    const pickerNode = JSON.parse(JSON.stringify(screenTemplate));

    // 2. Scan all active blocks from registry.
    // The picker shows ALL non-deleted blocks — users have full authoring control.
    // system_owned is NOT a visibility gate here; it only restricts AI from autonomously
    // creating/modifying those blocks. That enforcement lives in the AI pipeline
    // (SduiBlockRegistry.isSystemOwned / getAiEditableTypes), not in the picker.
    const activeBlocks = SduiBlockRegistry.all(); // Array of { blockType, spec }
    const allBlockNames = new Set(activeBlocks.map(b => b.blockType));

    // Keep track of which block types we have already placed in the categorized wraps
    const placedNames = new Set<string>();

    // Helper to filter chips in any Wrap node (type 37) — keeps only known block types.
    const filterAndTrackWrap = (node: any) => {
      if (node && node['0'] === 37 && Array.isArray(node['2'])) {
        node['2'] = node['2'].filter((chip: any) => {
          const params = chip?.['3']?.['70']?.['4'];
          const blockType = params?.['block_type'];
          if (blockType && allBlockNames.has(blockType)) {
            placedNames.add(blockType);
            return true;
          }
          return false;
        });
      }
    };

    // Recursively traverse the picker tree to filter existing wraps
    const traverse = (node: any) => {
      if (!node || typeof node !== 'object') return;
      filterAndTrackWrap(node);

      if (node['2'] && Array.isArray(node['2'])) {
        for (const child of node['2']) {
          traverse(child);
        }
      }
    };

    traverse(pickerNode);

    // 3. Find any active blocks not covered by the static blueprint categories — append as "Others"
    const remainingBlocks = activeBlocks.filter(b => !placedNames.has(b.blockType));

    if (remainingBlocks.length > 0) {
      // Create a divider, a header, and a Wrap of chips for "Others"
      const rootChildren = pickerNode['2'] || [];

      // Divider
      rootChildren.push({ '0': 34 }); // Divider

      // Category Header
      rootChildren.push({
        '0': 1, // MarkdownEditor / Text
        '3': { 100: 3, 95: 0, 96: 1, 31: [0, 8.0, 8.0, 0] }, // caption, outline variant
        '4': { 0: '⚙️  Others' }
      });

      // Wrap of chips
      const otherChips = remainingBlocks.map(b => ({
        '0': 5, // Chip
        'id': `diary_block_picker:chip_${b.blockType}`,
        '3': {
          113: 3, // ChipMode.SUGGESTION
          70: {
            0: 1, // RPC_CALL
            1: 112, // create_block
            4: {
              block_type: b.blockType,
              entry_id: '{{entry_id}}'
            }
          }
        },
        '4': {
          1: b.spec.label,
          3: b.spec.icon
        }
      }));

      rootChildren.push({
        '0': 37, // Wrap
        '3': { 114: 8.0, 115: 8.0, 31: [0, 0, 4.0, 0] },
        '2': otherChips
      });
    }

    // 4. Finally build and hydrate the screen node
    return SduiNodeBuilder.hydrateNode(pickerNode, {
      entry_id: entryId,
      after_node_id: afterNodeId,
    });
  }

  /**
   * Assembles the AI bolt-button prompt bottom sheet.
   *
   * Layout:
   *   [Title: \"Create with AI\"] [Close X]
   *   [Caption: style hint]
   *   [TextInput: raw_notes — multiline, bind_key: ai_prompt]
   *   [Row: [Cancel btn] [Generate btn → generate_from_notes RPC]]
   *
   * The Generate button fires action_type=RPC_CALL (1), method=115 (SHUA_DIARY_GENERATE_FROM_NOTES).
   * Params include bind_key 'ai_prompt' so Flutter reads the StateVault value at submit.
   *
   * This is assembled programmatically (not from a JSON blueprint) because it is a
   * purely static UI with no DB data binding — no blueprint file needed.
   */
  private static _assembleDiaryAiPromptModal(params: Record<string, any>): object {
    const userId = (params.user_id as string) ?? (params.userId as string) ?? 'default';

    return {
      '0': 6,   // Container
      'id': 'diary_ai_prompt:root',
      '3': {
        10: 0,   // LAYOUT_DIRECTION: vertical
        30: [20.0, 20.0, 32.0, 20.0],  // PADDING
        20: 11,  // BACKGROUND_COLOR: surfaceContainer
        21: 16.0,
      },
      '2': [
        // ── Header Row ───────────────────────────────────────────
        {
          '0': 6, 'id': 'diary_ai_prompt:header',
          '3': { 10: 1, 11: 1, 12: 1, 31: [0, 0, 16.0, 0] },
          '2': [
            {
              '0': 1, 'id': 'diary_ai_prompt:title',
              '3': { 100: 1, 101: 2, 95: 0 },
              '4': { 0: '✨ Create with AI' },
            },
            {
              '0': 3, 'id': 'diary_ai_prompt:close_btn',
              '3': { 112: 3, 70: { 0: 3 } },  // ICON_ONLY + DISMISS action
              '4': { 3: 'close' },
            },
          ],
        },
        // ── Subtitle ─────────────────────────────────────────────
        {
          '0': 1,
          '3': { 100: 3, 95: 0, 97: 17, 31: [0, 0, 12.0, 0] },
          '4': { 0: 'Describe your thoughts in any format — the AI will turn them into a structured entry.' },
        },
        // ── Notes Input ──────────────────────────────────────────
        {
          '0': 16, 'id': 'diary_ai_prompt:notes_input', // TextInput
          '3': {
            41: 4,    // INPUT_TYPE: MULTILINE
            95: 1,    // EDITABLE
            40: 'ai_prompt',  // BIND_KEY — StateVault reads this on submit
            33: 160.0,  // HEIGHT
            128: 6,   // MAX_LINES
            30: [12.0, 12.0, 12.0, 12.0],
          },
          '4': {
            2: 'e.g. "Went to the gym, feel tired but proud. Had a great sushi dinner with Mika..."',
          },
        },
        // ── Action Row ───────────────────────────────────────────
        {
          '0': 6,
          '3': { 10: 1, 11: 3, 12: 1, 114: 12.0, 31: [16.0, 0, 0, 0] },  // SPACE_BETWEEN row
          '2': [
            {
              '0': 3, 'id': 'diary_ai_prompt:cancel_btn',
              '3': { 112: 1, 70: { 0: 3 } },  // OUTLINED + DISMISS
              '4': { 1: 'Cancel' },
            },
            {
              '0': 3, 'id': 'diary_ai_prompt:generate_btn',
              '3': {
                112: 0,   // ELEVATED
                96: 1,    // ACCENT_COLOR_TOKEN: PRIMARY
                70: {
                  0: 11,  // ACTION_TYPE: SUBMIT_FORM
                  1: HBP_RPC.SHUA_DIARY_GENERATE_FROM_NOTES,
                  4: {
                    user_id: userId,
                    bind_keys: ['ai_prompt'],  // StateVault binds read on submit
                    style: 'reflective',
                  },
                },
              },
              '4': { 1: 'Generate Entry', 3: 'auto_awesome' },
            },
          ],
        },
      ],
    };
  }



  /**
   * Assembles the diary options bottom-sheet for a given entry.
   *
   * Actions:
   *   - Sync & Analyze → RPC SHUA_DIARY_ANALYZE_ENTRY (117)
   *   - Export Markdown → RPC SHUA_DIARY_GENERATE_SUMMARY (118) — repurposed to trigger export
   *   - Delete Entry    → RPC SHUA_DIARY_DELETE_ENTRY (106)
   *   - Back (dismiss)  → action_type DISMISS (3)
   *
   * All built programmatically — no blueprint file needed (static UI, zero DB reads).
   */
  private static _assembleDiaryOptionsModal(entryId: string): object {
    const makeOptionRow = (
      id: string,
      icon: string,
      label: string,
      actionPayload: object,
      colorToken?: number,
    ) => ({
      '0': HBP_WIDGET.CONTAINER,
      'id': `diary_options_${entryId}:${id}_row`,
      '3': {
        [HBP_BEHAVIOR.LAYOUT_DIRECTION]: 1,   // HORIZONTAL
        [HBP_BEHAVIOR.CROSS_AXIS_ALIGNMENT]: 2, // CENTER
        [HBP_BEHAVIOR.PADDING]: [12.0, 16.0, 12.0, 16.0],
        [HBP_BEHAVIOR.BORDER_RADIUS]: 12.0,
        ...(colorToken !== undefined ? { [HBP_BEHAVIOR.BACKGROUND_COLOR]: 0 } : {}),
      },
      '2': [
        {
          '0': HBP_WIDGET.BUTTON,
          'id': `diary_options_${entryId}:${id}_btn`,
          '3': {
            [HBP_BEHAVIOR.BUTTON_VARIANT]: HBP_BUTTON_VARIANT.TEXT,
            [HBP_BEHAVIOR.FLEX]: 1,
            [HBP_BEHAVIOR.ACTION_PAYLOAD]: actionPayload,
            ...(colorToken !== undefined ? { [HBP_BEHAVIOR.ACCENT_COLOR_TOKEN]: colorToken } : {}),
          },
          '4': {
            [HBP_CONTENT.LABEL]: label,
            [HBP_CONTENT.ICON_NAME]: icon,
          },
        },
      ],
    });

    return {
      '0': HBP_WIDGET.CONTAINER,
      'id': `diary_options_${entryId}:root`,
      '3': {
        [HBP_BEHAVIOR.LAYOUT_DIRECTION]: 0,     // VERTICAL
        [HBP_BEHAVIOR.PADDING]: [16.0, 20.0, 32.0, 20.0],
        [HBP_BEHAVIOR.BACKGROUND_COLOR]: 11,    // SURFACE_CONTAINER
        [HBP_BEHAVIOR.BORDER_RADIUS]: 20.0,
      },
      '2': [
        // ── Header Row ───────────────────────────────────────────────
        {
          '0': HBP_WIDGET.CONTAINER,
          'id': `diary_options_${entryId}:header`,
          '3': {
            [HBP_BEHAVIOR.LAYOUT_DIRECTION]: 1,    // HORIZONTAL
            [HBP_BEHAVIOR.MAIN_AXIS_ALIGNMENT]: 3, // SPACEBETWEEN
            [HBP_BEHAVIOR.CROSS_AXIS_ALIGNMENT]: 2, // CENTER
            [HBP_BEHAVIOR.MARGIN]: [0, 0, 16.0, 0],
          },
          '2': [
            {
              '0': HBP_WIDGET.MARKDOWNEDITOR,
              'id': `diary_options_${entryId}:title`,
              '3': { [HBP_BEHAVIOR.DISPLAY_MODE]: HBP_DISPLAY_MODE.HEADING, [HBP_BEHAVIOR.HEADING_LEVEL]: 2, [HBP_BEHAVIOR.INTERACTIVE_MODE]: HBP_INTERACTIVE.READONLY },
              '4': { [HBP_CONTENT.VALUE]: 'Entry Options' },
            },
            {
              '0': HBP_WIDGET.BUTTON,
              'id': `diary_options_${entryId}:close_btn`,
              '3': { [HBP_BEHAVIOR.BUTTON_VARIANT]: HBP_BUTTON_VARIANT.ICON_ONLY, [HBP_BEHAVIOR.ACTION_PAYLOAD]: { 0: 3 } }, // DISMISS
              '4': { [HBP_CONTENT.ICON_NAME]: 'close' },
            },
          ],
        },
        // ── Sync & Analyze ──────────────────────────────────────────
        makeOptionRow(
          'sync',
          'cloud_sync',
          'Sync & Analyze Entry',
          { 0: 1, 1: HBP_RPC.SHUA_DIARY_ANALYZE_ENTRY, 4: { entry_id: entryId } },
        ),
        // ── Export Markdown ─────────────────────────────────────────
        makeOptionRow(
          'export',
          'file_upload',
          'Export as Markdown',
          { 0: 1, 1: HBP_RPC.SHUA_DIARY_GENERATE_SUMMARY, 4: { entry_id: entryId, export_mode: true } },
        ),
        // ── AI Model Configuration ──────────────────────────────────
        makeOptionRow(
          'ai_config',
          'settings_suggest',
          'AI Provider Config (Gemini / Ollama)',
          { 0: 2, 3: '/sdui_modal/diary_ai_config' },
        ),
        // ── Divider ─────────────────────────────────────────────────

        {
          '0': HBP_WIDGET.DIVIDER,
          'id': `diary_options_${entryId}:divider`,
          '3': { [HBP_BEHAVIOR.MARGIN]: [8.0, 0, 8.0, 0] },
        },
        // ── Delete Entry (destructive) ──────────────────────────────
        makeOptionRow(
          'delete',
          'delete_outline',
          'Delete Entry',
          { 0: 1, 1: HBP_RPC.SHUA_DIARY_DELETE_ENTRY, 4: { entry_id: entryId } },
          HBP_COLOR_TOKEN.ERROR,
        ),
      ],
    };
  }

}

// ── Pure helper functions ─────────────────────────────────────────────

function findNodeById(node: any, id: string): any {
  if (!node || typeof node !== 'object') return null;
  if (node.id === id) return node;

  if (Array.isArray(node)) {
    for (const child of node) {
      const found = findNodeById(child, id);
      if (found) return found;
    }
  } else if (node['2'] && Array.isArray(node['2'])) {
    for (const child of node['2']) {
      const found = findNodeById(child, id);
      if (found) return found;
    }
  }
  return null;
}
