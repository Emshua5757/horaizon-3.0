import fs from 'fs';
import path from 'path';
import { EventEmitter } from 'events';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

// Memory cache: resolvedPath → Parsed JSON Blueprint
const blueprintCache: Map<string, any> = new Map();
// Watcher registry: absolute dir path → fs.FSWatcher
const watchedDirs: Map<string, fs.FSWatcher> = new Map();

const blueprintsRoot = path.join(__dirname, '..', '..', '..', '..', 'schemas', 'blueprints');

/**
 * Custom recursive directory watcher compatible with Linux (RPi 5).
 * Listens to subdirectory creation and JSON file updates.
 */
function watchDirectoryRecursive(dirPath: string, callback: (changedAbsPath: string) => void): void {
  if (watchedDirs.has(dirPath)) return;
  if (!fs.existsSync(dirPath)) return;

  try {
    const watcher = fs.watch(dirPath, { recursive: false }, (_eventType, filename) => {
      if (!filename) return;
      const fullPath = path.join(dirPath, filename);
      callback(fullPath);

      // If a new subdirectory is created, watch it as well
      try {
        if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
          watchDirectoryRecursive(fullPath, callback);
        }
      } catch (_) {}
    });

    watchedDirs.set(dirPath, watcher);
    logger.info('sdui_blueprint_loader', `Watcher registered for: ${dirPath}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });

    // Walk existing subdirectories recursively
    const files = fs.readdirSync(dirPath);
    for (const file of files) {
      const fullPath = path.join(dirPath, file);
      try {
        if (fs.statSync(fullPath).isDirectory()) {
          watchDirectoryRecursive(fullPath, callback);
        }
      } catch (_) {}
    }
  } catch (err) {
    logger.error('sdui_blueprint_loader', `Failed to watch directory ${dirPath}: ${err}`, { tags: HBP_LOG_TAG.SDUI });
  }
}

function ensureWatcher(dir: string): void {
  watchDirectoryRecursive(dir, (changedAbsPath) => {
    if (!changedAbsPath.endsWith('.json')) return;

    // Normalize to forward slashes for cross-platform consistency
    const changedAbs = changedAbsPath.replace(/\\/g, '/');

    // 1. Handle block cache invalidation (block:blockType)
    const blockMatch = changedAbs.match(/\/block_([^/]+)\.json$/);
    if (blockMatch) {
      const blockType = blockMatch[1];
      const cacheKey = `block:${blockType}`;
      if (blueprintCache.has(cacheKey)) {
        blueprintCache.delete(cacheKey);
        logger.info('sdui_blueprint_loader', `Cache invalidated for block: ${blockType}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
        SduiBlueprintLoader.events.emit('blueprint_changed', cacheKey);
      }
      return;
    }

    // 2. Handle screen blueprint cache invalidation
    for (const [cachedPath] of blueprintCache.entries()) {
      const cachedNormalized = cachedPath.replace(/\\/g, '/');
      if (changedAbs.endsWith(cachedNormalized + '.json') ||
          cachedNormalized === changedAbs) {
        blueprintCache.delete(cachedPath);
        logger.info('sdui_blueprint_loader', `Cache invalidated for: ${cachedPath}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
        SduiBlueprintLoader.events.emit('blueprint_changed', cachedPath);
      }
    }
  });
}

export class SduiBlueprintLoader {
  public static readonly events = new EventEmitter();

  /**
   * Loads a blueprint JSON file from `schemas/blueprints/`.
   *
   * Supports subdirectory paths using forward-slash notation:
   *   - loadBlueprint('diary')          → blueprints/diary.json   (legacy flat)
   *   - loadBlueprint('diary/diary')    → blueprints/diary/diary.json
   *   - loadBlueprint('diary/diary_editor') → blueprints/diary/diary_editor.json
   *
   * Results are cached in-memory. The fs.watch watcher invalidates
   * the cache on any .json change under the blueprints root.
   *
   * @param modulePath - Module name or slash-separated subpath (no extension)
   * @returns Parsed JSON object
   * @throws If the file does not exist or fails to parse
   */
  static loadBlueprint(modulePath: string): any {
    ensureWatcher(path.join(blueprintsRoot, 'diary'));

    if (blueprintCache.has(modulePath)) {
      return blueprintCache.get(modulePath);
    }

    // Support both 'diary' (flat legacy) and 'diary/diary' (subdirectory)
    const filePath = path.join(blueprintsRoot, ...modulePath.split('/')) + '.json';

    if (!fs.existsSync(filePath)) {
      throw new Error(
        `[SduiBlueprintLoader] Blueprint not found: '${modulePath}' at ${filePath}`
      );
    }

    try {
      let raw = fs.readFileSync(filePath, 'utf-8');
      if (raw.charCodeAt(0) === 0xFEFF) {
        raw = raw.slice(1);
      }
      const parsed = JSON.parse(raw);
      blueprintCache.set(modulePath, parsed);
      logger.info('sdui_blueprint_loader', `Loaded and cached: ${modulePath}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
      return parsed;
    } catch (e) {
      logger.error('sdui_blueprint_loader', `Failed to parse blueprint '${modulePath}': ${e}`, { tags: HBP_LOG_TAG.SDUI });
      throw e;
    }
  }

  /**
   * Loads a single block definition from `schemas/blueprints/diary/blocks/`.
   *
   * Block files are flat SDUI node definitions (type_id + behaviors + content).
   * They are NOT screen templates — they have no `{{}}` template bindings.
   * The block registry uses these as default structure references when
   * `SduiBlockRegistry.buildContentNode()` needs a base spec for a new block type.
   *
   * @param blockType - Block type string key (e.g. 'body', 'checklist', 'mood_rating')
   * @returns Parsed block definition or null if not found
   */
  static loadBlock(blockType: string): any | null {
    const cacheKey = `block:${blockType}`;

    // Ensure the blocks subdirectory is watched too
    const blocksDir = path.join(blueprintsRoot, 'diary', 'blocks');
    ensureWatcher(blocksDir);

    if (blueprintCache.has(cacheKey)) {
      return blueprintCache.get(cacheKey);
    }

    const filePath = path.join(blocksDir, `block_${blockType}.json`);
    if (!fs.existsSync(filePath)) {
      return null; // Not found is non-fatal — caller uses registry fallback
    }

    try {
      let raw = fs.readFileSync(filePath, 'utf-8');
      // Strip UTF-8 BOM if present
      if (raw.charCodeAt(0) === 0xFEFF) {
        raw = raw.slice(1);
      }
      const parsed = JSON.parse(raw);
      blueprintCache.set(cacheKey, parsed);
      logger.info('sdui_blueprint_loader', `Loaded block definition: block_${blockType}.json`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
      return parsed;
    } catch (e) {
      logger.error('sdui_blueprint_loader', `Failed to parse block file '${blockType}': ${e}`, { tags: HBP_LOG_TAG.SDUI });
      return null;
    }
  }

  /**
   * Manually invalidates the cache for a specific path.
   * Useful in tests or when hot-reloading a single file programmatically.
   */
  static invalidate(modulePath: string): void {
    if (blueprintCache.has(modulePath)) {
      blueprintCache.delete(modulePath);
      logger.info('sdui_blueprint_loader', `Manually invalidated: ${modulePath}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
    }
  }

  /**
   * Clears the entire blueprint cache. Use with caution in production.
   */
  static invalidateAll(): void {
    blueprintCache.clear();
    logger.info('sdui_blueprint_loader', 'Full cache cleared.', { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
  }
}

// Start watching the blueprints directory immediately on import
ensureWatcher(blueprintsRoot);
