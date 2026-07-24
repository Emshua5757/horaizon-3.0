import { SduiBlockRegistry } from '../../sdui/sdui_block_registry';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export interface JbcMutation {
  action: 'UPDATE' | 'DELETE' | 'INSERT';
  id?: string;
  type?: string;
  content?: string;
  afterId?: string;
}

export class JbcTranslator {
  /**
   * Postel's Law Self-Healing string post-processor.
   * Cleans redundant LLM-generated prefixes and wraps quotes/brackets cleanly.
   */
  private static selfHealLine(line: string): string {
    line = line.trim();
    
    // 0. Clean delete mutations
    if (line.startsWith("D:")) {
      let uuid = line.substring(2).trim();
      if (uuid.startsWith("<") && uuid.endsWith(">")) {
        uuid = uuid.substring(1, uuid.length - 1).trim();
      }
      return `D:${uuid}`;
    }
    
    // 1. Clean update mutations
    else if (line.startsWith("U:")) {
      const payload = line.substring(2);
      const firstPipe = payload.indexOf('|');
      if (firstPipe !== -1) {
        let uuid = payload.substring(0, firstPipe).trim();
        let content = payload.substring(firstPipe + 1).trim();
        
        // Strip angle brackets if present on UUID
        if (uuid.startsWith("<") && uuid.endsWith(">")) {
          uuid = uuid.substring(1, uuid.length - 1).trim();
        }
        // Trim "content=" prefix if present
        if (content.startsWith("content=")) {
          content = content.substring(8).trim();
        }
        // Strip outer double quotes if present
        if (content.startsWith('"') && content.endsWith('"')) {
          content = content.substring(1, content.length - 1).trim();
        }
        return `U:${uuid}|${content}`;
      }
    }
    
    // 2. Clean insert mutations
    else if (line.startsWith("I:")) {
      const payload = line.substring(2);
      const firstPipe = payload.indexOf('|');
      if (firstPipe !== -1) {
        let afterId = payload.substring(0, firstPipe).trim();
        const remainder = payload.substring(firstPipe + 1).trim();
        const secondPipe = remainder.indexOf('|');
        if (secondPipe !== -1) {
          let bType = remainder.substring(0, secondPipe).trim();
          let content = remainder.substring(secondPipe + 1).trim();
          
          // Strip angle brackets on afterId
          if (afterId.startsWith("<") && afterId.endsWith(">")) {
            afterId = afterId.substring(1, afterId.length - 1).trim();
          }
          // Strip angle brackets on block type
          if (bType.startsWith("<") && bType.endsWith(">")) {
            bType = bType.substring(1, bType.length - 1).trim();
          }
          // Trim "type=" prefix if present
          if (bType.startsWith("type=")) {
            bType = bType.substring(5).trim();
          }
          // Trim "content=" prefix if present
          if (content.startsWith("content=")) {
            content = content.substring(8).trim();
          }
          // Strip outer double quotes if present
          if (content.startsWith('"') && content.endsWith('"')) {
            content = content.substring(1, content.length - 1).trim();
          }
          return `I:${afterId}|${bType}|${content}`;
        }
      }
    }
    
    return line;
  }

  /**
   * Resolves numeric index or standalone pound ID refs (e.g. "1", "#1", "blk_1")
   * to their real UUID based on active blocks ordering.
   */
  private static resolveId(id: string, activeBlocks?: any[]): string {
    id = id.trim();
    if (!activeBlocks || activeBlocks.length === 0) return id;

    const match = id.match(/^(?:#|blk_)?(\d+)$/i);
    if (match) {
      const idx = parseInt(match[1], 10);
      const target = activeBlocks[idx - 1];
      if (target) {
        return target.id;
      }
    }
    return id;
  }

  /**
   * Translates a block of JBC bytecode string into a beautiful, human-readable
   * Markdown changes list so that the SLM Presentation Stage does not waste tokens.
   * Runs in sub-milliseconds on edge hardware.
   */
  static translate(bytecode: string, activeBlocks: any[]): string {
    const rawLines = bytecode.split('\n').map(l => l.trim()).filter(Boolean);
    let diffMarkdown = '\n### 🛠️ Proposed AI Refactoring Changes:\n';
    let changeCount = 0;

    for (const rawLine of rawLines) {
      const line = this.selfHealLine(rawLine);

      if (line.startsWith('D:')) {
        let id = line.substring(2).trim();
        id = this.resolveId(id, activeBlocks);
        const current = activeBlocks.find(b => b.id === id);
        const typeName = current?.blockType || 'block';
        
        // Zero-Trust: Skip if targeted block is a system type
        if (current && SduiBlockRegistry.isSystemOwned(current.blockType)) {
          logger.warn('jbc_translator', `[ZERO-TRUST] Blocked delete mutation on system block ID: ${id}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.SECURITY });
          continue;
        }

        const summary = current?.content ? (current.content.length > 50 ? `${current.content.substring(0, 50)}...` : current.content) : '(empty)';
        diffMarkdown += `*   **❌ Delete Block (${typeName})**: \`${summary}\`\n`;
        changeCount++;
      } else if (line.startsWith('U:')) {
        const payload = line.substring(2);
        const firstPipe = payload.indexOf('|');
        if (firstPipe !== -1) {
          let id = payload.substring(0, firstPipe).trim();
          id = this.resolveId(id, activeBlocks);
          const content = payload.substring(firstPipe + 1);
          const current = activeBlocks.find(b => b.id === id);
          
          // Zero-Trust: Skip if targeted block is a system type
          if (current && SduiBlockRegistry.isSystemOwned(current.blockType)) {
            logger.warn('jbc_translator', `[ZERO-TRUST] Blocked update mutation on system block ID: ${id}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.SECURITY });
            continue;
          }

          const typeName = current?.blockType || 'block';
          diffMarkdown += `*   **✏️ Edit Block (${typeName})**: \n`;
          diffMarkdown += `    *   *From*: \`${current?.content || '(empty)'}\`\n`;
          diffMarkdown += `    *   *To*: \`${content}\`\n`;
          changeCount++;
        }
      } else if (line.startsWith('I:')) {
        const payload = line.substring(2);
        const firstPipe = payload.indexOf('|');
        if (firstPipe !== -1) {
          let afterId = payload.substring(0, firstPipe).trim();
          afterId = this.resolveId(afterId, activeBlocks);
          const remainder = payload.substring(firstPipe + 1);
          const secondPipe = remainder.indexOf('|');
          if (secondPipe !== -1) {
            const typeName = remainder.substring(0, secondPipe).trim();
            const content = remainder.substring(secondPipe + 1);

            // Zero-Trust: Skip if block to insert is a system type
            if (SduiBlockRegistry.isSystemOwned(typeName)) {
              logger.warn('jbc_translator', `[ZERO-TRUST] Blocked insert mutation of system type: ${typeName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.SECURITY });
              continue;
            }

            diffMarkdown += `*   **➕ Insert New Block (${typeName})**: \`${content}\` `;
            if (afterId === '0' || afterId.toLowerCase() === 'top') {
              diffMarkdown += `➔ *at the absolute top*\n`;
            } else {
              diffMarkdown += `➔ *after block ID* \`${afterId.substring(0, 12)}...\`\n`;
            }
            changeCount++;
          }
        }
      }
    }

    if (changeCount === 0) return '';
    diffMarkdown += `\n*Tap **[Accept Changes]** at the bottom of the screen to commit these mutations.*`;
    return diffMarkdown;
  }

  /**
   * Parses JBC text into a structured array of mutation objects to be sent to the client.
   * Applies both Postel's Law Self-Healing and Zero-Trust block type gates.
   */
  static parse(bytecode: string, activeBlocks?: any[]): { intent: 'MUTATE' | 'SUGGEST_TEMPLATE' | 'CONVERSE' | 'NO_OP'; mutations: JbcMutation[] } {
    const rawLines = bytecode.split('\n').map(l => l.trim()).filter(Boolean);
    let intent: 'MUTATE' | 'SUGGEST_TEMPLATE' | 'CONVERSE' | 'NO_OP' = 'CONVERSE';
    const mutations: JbcMutation[] = [];

    for (const rawLine of rawLines) {
      const line = this.selfHealLine(rawLine);

      if (line === 'NO_OP') {
        intent = 'NO_OP';
      } else if (line.startsWith('D:')) {
        let id = line.substring(2).trim();
        id = this.resolveId(id, activeBlocks);
        if (id) {
          // Zero-Trust Gate
          if (activeBlocks) {
            const target = activeBlocks.find(b => b.id === id);
            if (target && SduiBlockRegistry.isSystemOwned(target.blockType)) {
              logger.warn('jbc_translator', `[ZERO-TRUST] Dropping DELETE mutation on system block ID: ${id}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.SECURITY });
              continue;
            }
          }
          mutations.push({
            action: 'DELETE',
            id
          });
        }
      } else if (line.startsWith('U:')) {
        const payload = line.substring(2);
        const firstPipe = payload.indexOf('|');
        if (firstPipe !== -1) {
          let id = payload.substring(0, firstPipe).trim();
          id = this.resolveId(id, activeBlocks);
          const content = payload.substring(firstPipe + 1);
          
          // Zero-Trust Gate
          if (activeBlocks) {
            const target = activeBlocks.find(b => b.id === id);
            if (target && SduiBlockRegistry.isSystemOwned(target.blockType)) {
              logger.warn('jbc_translator', `[ZERO-TRUST] Dropping UPDATE mutation on system block ID: ${id}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.SECURITY });
              continue;
            }
          }
          mutations.push({
            action: 'UPDATE',
            id,
            content
          });
        }
      } else if (line.startsWith('I:')) {
        const payload = line.substring(2);
        const firstPipe = payload.indexOf('|');
        if (firstPipe !== -1) {
          let afterId = payload.substring(0, firstPipe).trim();
          afterId = this.resolveId(afterId, activeBlocks);
          const remainder = payload.substring(firstPipe + 1);
          const secondPipe = remainder.indexOf('|');
          if (secondPipe !== -1) {
            const type = remainder.substring(0, secondPipe).trim();
            const content = remainder.substring(secondPipe + 1);

            // Zero-Trust Gate
            if (SduiBlockRegistry.isSystemOwned(type)) {
              logger.warn('jbc_translator', `[ZERO-TRUST] Dropping INSERT mutation of system type: ${type}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.SECURITY });
              continue;
            }

            mutations.push({
              action: 'INSERT',
              type,
              afterId,
              content
            });
          }
        }
      }
    }

    if (mutations.length > 0) {
      intent = 'MUTATE';
    }

    return { intent, mutations };
  }

  /**
   * Serializes the current active diary blocks into a clean, structured string
   * format expected by the Stage 1 Planner SLM, matching our training dataset.
   */
  static serializeDiaryState(blocks: any[]): string {
    let output = 'ACTIVE DIARY STATE:\n';
    if (!blocks || blocks.length === 0) {
      return 'ACTIVE DIARY STATE:\n  (empty)';
    }
    let idx = 1;
    for (const block of blocks) {
      const content = block.content || '';
      const preview = content.length > 65 ? content.substring(0, 65) + '...' : content;
      const cleanPreview = preview.replace(/"/g, '\\"');
      output += `  #${idx} [${block.id}] type=${block.blockType} | content="${cleanPreview}"\n`;
      idx++;
    }
    return output.trim();
  }
}
