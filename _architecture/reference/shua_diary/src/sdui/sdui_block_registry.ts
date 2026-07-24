import * as fs from 'fs';
import * as path from 'path';
import { HBP_CODE_LANG } from '../models/HbpConstants';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * BlockTypeSpec — the parsed, ready-to-use form of one entry in block registry.
 * Integer keys are pre-converted from strings at load time — zero parse cost per block render.
 */
export interface BlockTypeSpec {
  sduiTypeId: number;
  behaviors: Record<number, number | boolean | number[]>;   // applied to content primitive
  wrapperBehaviors: Record<number, number | boolean | number[]>; // applied to outer Container
  contentKey: number | null;
  defaultContentMap?: Record<number, any>;
  allowCodeLanguage: boolean;
  label: string;
  icon: string;
  description: string;
  defaultContent: string | null;
  systemOwned?: boolean;
  isAiEditable?: boolean;
  deleted?: boolean;
  id?: string;
  version?: string;
}

/**
 * SduiBlockRegistry — loads block blueprints from schemas/blueprints/diary/blocks/ at startup.
 *
 * Design:
 *  - Singleton: directory scan at startup, cached in-memory.
 *  - O(1) lookup by string blockType key and string block ID.
 *  - Unknown blockType falls back to a safe body text spec rather than throwing.
 */
export class SduiBlockRegistry {
  private static _registry: Map<string, BlockTypeSpec> | null = null;
  private static _registryById: Map<string, BlockTypeSpec> | null = null;
  private static readonly _BLOCKS_DIR = path.resolve(
    __dirname, '..', '..', '..', '..', 'schemas', 'blueprints', 'diary', 'blocks'
  );

  /**
   * Load and parse the registry from the blocks directory.
   */
  static load(): void {
    if (SduiBlockRegistry._registry !== null) return;

    SduiBlockRegistry._registry = new Map();
    SduiBlockRegistry._registryById = new Map();

    if (!fs.existsSync(SduiBlockRegistry._BLOCKS_DIR)) {
      logger.error('sdui_block_registry', `Blocks directory not found: ${SduiBlockRegistry._BLOCKS_DIR}`, { tags: HBP_LOG_TAG.SDUI });
      return;
    }

    try {
      const files = fs.readdirSync(SduiBlockRegistry._BLOCKS_DIR);
      const regex = /^block_(\d+)_(v\d+)_(.+?)(?:\.deleted)?\.json$/;

      for (const file of files) {
        const match = file.match(regex);
        if (!match) continue;

        const [_, idStr, versionStr, nameStr] = match;
        const isDeleted = file.includes('.deleted.json');

        const filePath = path.join(SduiBlockRegistry._BLOCKS_DIR, file);
        const raw = fs.readFileSync(filePath, 'utf-8');
        const json = JSON.parse(raw);
        const meta = json._meta || {};
        const node = json.node || {};

        // Parse content key: explicit _meta.content_key takes priority over heuristic
        // inference, which is unreliable because V8 sorts integer-string keys numerically
        // regardless of their order in the source JSON.
        // Example bug: { "2": "", "5": "" } → Object.keys → ['2','5'] → infers key=2 (PLACEHOLDER)
        //              even when key 5 (SRC) is the intended saveable slot.
        let contentKey: number | null = null;
        if (meta.content_key !== undefined) {
          const explicitKey = parseInt(meta.content_key, 10);
          if (!isNaN(explicitKey)) contentKey = explicitKey;
        } else if (node['4'] && typeof node['4'] === 'object') {
          const keys = Object.keys(node['4']);
          if (keys.length > 0) {
            const parsedKey = parseInt(keys[0], 10);
            if (!isNaN(parsedKey)) contentKey = parsedKey;
          }
        }

        // Convert behaviors keys
        const behaviors: Record<number, any> = {};
        if (node['3']) {
          for (const [k, v] of Object.entries(node['3'])) {
            behaviors[parseInt(k, 10)] = v;
          }
        }

        // Convert wrapper behaviors keys
        const wrapperBehaviors: Record<number, any> = {};
        if (meta.wrapper_behaviors) {
          for (const [k, v] of Object.entries(meta.wrapper_behaviors)) {
            wrapperBehaviors[parseInt(k, 10)] = v;
          }
        }

        // Map the entire content node['4'] for static keys preservation
        const defaultContentMap: Record<number, any> = {};
        if (node['4'] && typeof node['4'] === 'object') {
          for (const [k, v] of Object.entries(node['4'])) {
            defaultContentMap[parseInt(k, 10)] = v;
          }
        }

        const spec: BlockTypeSpec = {
          sduiTypeId: node['0'] !== undefined ? parseInt(node['0'], 10) : 1,
          behaviors,
          wrapperBehaviors,
          contentKey,
          defaultContentMap,
          allowCodeLanguage: meta.allow_code_language === true,
          label: meta.label || nameStr,
          icon: meta.icon || 'widgets',
          description: meta.description || '',
          defaultContent: meta.default_content !== undefined ? meta.default_content : null,
          systemOwned: meta.system_owned === true,
          isAiEditable: meta.is_ai_editable !== false,
          deleted: isDeleted,
          id: idStr,
          version: versionStr,
        };

        // Cache in maps
        SduiBlockRegistry._registry.set(nameStr, spec);
        SduiBlockRegistry._registryById.set(idStr, spec);
      }
    } catch (e) {
      logger.error('sdui_block_registry', `Failed to scan or parse blocks: ${e}`, { tags: HBP_LOG_TAG.SDUI });
    }

    logger.info('sdui_block_registry', `Loaded ${SduiBlockRegistry._registry.size} block types.`, {
      tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE,
      telemetry: { blockCount: SduiBlockRegistry._registry.size },
    });
  }

  /**
   * Get the spec for a block type (by name or by ID).
   */
  static get(blockType: string): BlockTypeSpec {
    SduiBlockRegistry._ensureLoaded();

    const spec = SduiBlockRegistry._registry!.get(blockType) || SduiBlockRegistry._registryById!.get(blockType);
    if (spec) {
      if (spec.deleted) {
        // Return a graceful "retired block" fallback spec
        return {
          sduiTypeId: 1, // MarkdownEditor
          behaviors: {
            100: 2, // Quote style
            95: 0, // Read-only
            97: 15, // Error/warning text color
          },
          wrapperBehaviors: {
            20: 7, // Secondary container
            21: 8.0,
            30: [12.0, 16.0, 12.0, 16.0],
            31: [4.0, 0, 4.0, 0],
          },
          contentKey: 0,
          defaultContentMap: { 0: 'This block design has been retired.' },
          allowCodeLanguage: false,
          label: 'Retired Block',
          icon: 'unpublished',
          description: 'This block design has been retired.',
          defaultContent: 'This block design has been retired.',
          systemOwned: true,
          isAiEditable: false,
        };
      }
      return spec;
    }

    logger.warn('sdui_block_registry', `Unknown blockType/ID '${blockType}', falling back to 'body'.`, { tags: HBP_LOG_TAG.SDUI });
    return SduiBlockRegistry._registry!.get('body')!;
  }

  /**
   * Returns all active block types as an ordered array.
   */
  static all(): Array<{ blockType: string; spec: BlockTypeSpec }> {
    SduiBlockRegistry._ensureLoaded();
    return Array.from(SduiBlockRegistry._registry!.entries())
      .filter(([_, spec]) => !spec.deleted)
      .map(([blockType, spec]) => ({
        blockType,
        spec,
      }));
  }

  static getAiEditableTypes(): string[] {
    SduiBlockRegistry._ensureLoaded();
    return Array.from(SduiBlockRegistry._registry!.entries())
      .filter(([_, spec]) => spec.isAiEditable && !spec.systemOwned && !spec.deleted)
      .map(([blockType]) => blockType);
  }

  static getSystemOwnedTypes(): string[] {
    SduiBlockRegistry._ensureLoaded();
    return Array.from(SduiBlockRegistry._registry!.entries())
      .filter(([_, spec]) => (spec.systemOwned || !spec.isAiEditable) && !spec.deleted)
      .map(([blockType]) => blockType);
  }

  static isAiEditable(blockType: string): boolean {
    SduiBlockRegistry._ensureLoaded();
    const spec = SduiBlockRegistry._registry!.get(blockType) || SduiBlockRegistry._registryById!.get(blockType);
    if (!spec) return false;
    return spec.isAiEditable !== false && spec.systemOwned !== true && !spec.deleted;
  }

  static isSystemOwned(blockType: string): boolean {
    SduiBlockRegistry._ensureLoaded();
    const spec = SduiBlockRegistry._registry!.get(blockType) || SduiBlockRegistry._registryById!.get(blockType);
    if (!spec) return true; // If not registered, treat as forbidden/system-owned for LLM edits
    return spec.systemOwned === true || spec.isAiEditable === false || spec.deleted === true;
  }

  /**
   * Build a SDUI AST content node for a given block.
   */
  static buildContentNode(
    blockType: string,
    blockId: string,
    entryId: string,
    content: string,
    codeLang: string | null,
  ): { contentNode: Record<string, unknown>; wrapperBehaviors: Record<number, unknown> } {
    const spec = SduiBlockRegistry.get(blockType);

    // Merge static behaviors from registry with dynamic runtime ones
    const behaviors: Record<number, unknown> = { ...spec.behaviors };

    // Code language is the only dynamic behavior
    if (spec.allowCodeLanguage && codeLang) {
      const langKey = codeLang.toUpperCase() as keyof typeof HBP_CODE_LANG;
      behaviors[110] = HBP_CODE_LANG[langKey] ?? HBP_CODE_LANG.PYTHON;
    }

    const contentNode: Record<string, unknown> = {
      '0': spec.sduiTypeId,
      'id': `diary_editor_${entryId}:block_${blockId}:content`,
      '3': behaviors,
    };

    const contentMap: Record<number, any> = spec.defaultContentMap ? { ...spec.defaultContentMap } : {};
    
    if (blockType === 'toggle_section') {
      try {
        const parsed = JSON.parse(content);
        contentMap[1] = parsed.title ?? 'Section';
        contentMap[0] = parsed.body ?? '';
        if (parsed.icon) {
          contentMap[3] = parsed.icon;
        }
        if (parsed.radius !== undefined) {
          behaviors[21] = parsed.radius;
        }
      } catch (e) {
        contentMap[1] = 'Section';
        contentMap[0] = content || '';
      }
    } else if (blockType === 'checkbox_single') {
      try {
        const parsed = JSON.parse(content);
        contentMap[1] = parsed.label ?? 'Checkbox';
        contentMap[0] = parsed.checked === true || parsed.checked === 'true';
      } catch (e) {
        contentMap[1] = content || 'Checkbox';
        contentMap[0] = false;
      }
    } else if (blockType === 'poll_choice') {
      try {
        const parsed = JSON.parse(content);
        contentMap[1] = parsed.label ?? 'Option';
        contentMap[0] = parsed.checked === true || parsed.checked === 'true';
        behaviors[124] = parsed.group ?? 'poll_block';
      } catch (e) {
        contentMap[1] = content || 'Option';
        contentMap[0] = false;
        behaviors[124] = 'poll_block';
      }
    } else if (blockType === 'dropdown_select') {
      try {
        const parsed = JSON.parse(content);
        contentMap[1] = parsed.label ?? 'Select option';
        contentMap[6] = JSON.stringify(parsed.options ?? []);
        contentMap[0] = parsed.value ?? '';
      } catch (e) {
        contentMap[1] = 'Select option';
        contentMap[6] = JSON.stringify(['Option A', 'Option B', 'Option C']);
        contentMap[0] = content || '';
      }
    } else {
      if (spec.contentKey !== null) {
        contentMap[spec.contentKey] = content;
      }
    }
    contentNode['4'] = contentMap;

    return { contentNode, wrapperBehaviors: spec.wrapperBehaviors };
  }

  private static _watcherInitialized = false;

  private static _ensureWatcher(): void {
    if (SduiBlockRegistry._watcherInitialized) return;
    SduiBlockRegistry._watcherInitialized = true;

    if (!fs.existsSync(SduiBlockRegistry._BLOCKS_DIR)) {
      logger.warn('sdui_block_registry', `Directory not found: ${SduiBlockRegistry._BLOCKS_DIR}. Watcher disabled.`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
      return;
    }

    try {
      fs.watch(SduiBlockRegistry._BLOCKS_DIR, { recursive: true }, (eventType) => {
        SduiBlockRegistry._registry = null;
        SduiBlockRegistry._registryById = null;
        logger.info('sdui_block_registry', 'Blocks directory changed on disk. Invalidating cache for hot-reload.', { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
        // Emit event to notify orchestrator to broadcast hot_reload to client
        const { SduiBlueprintLoader } = require('./sdui_blueprint_loader');
        SduiBlueprintLoader.events.emit('blueprint_changed', 'block:*');
      });
      logger.info('sdui_block_registry', `Started filesystem watcher on: ${SduiBlockRegistry._BLOCKS_DIR}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
    } catch (err) {
      logger.error('sdui_block_registry', `Failed to start filesystem watcher: ${err}`, { tags: HBP_LOG_TAG.SDUI });
    }
  }

  private static _ensureLoaded(): void {
    SduiBlockRegistry._ensureWatcher();
    if (SduiBlockRegistry._registry === null) {
      SduiBlockRegistry.load();
    }
  }
}
