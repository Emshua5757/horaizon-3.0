import { getDiaryRepository } from '../diary/diary_repository';
import { BlockType } from '../diary/diary_types';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * JBC (Joshua Brain Copilot) MCP Tool Definitions & Execution Handlers.
 * Complies with _architecture/contracts/mcp/mcp_master_spec.md.
 */

export interface McpToolDefinition {
  name: string;
  description: string;
  scope: string;
  timeout_s: number;
  input_schema: Record<string, unknown>;
}

export const JBC_MCP_TOOLS: McpToolDefinition[] = [
  {
    name: 'diary_create_block',
    description: 'Inserts a new native block widget (markdown, code, image, checklist, chart, etc.) into a diary entry.',
    scope: 'diary',
    timeout_s: 10,
    input_schema: {
      type: 'object',
      properties: {
        entry_id: { type: 'string', description: 'UUID of target diary entry' },
        block_type: { type: 'string', description: 'Block widget type' },
        content: { type: 'object', description: 'Block content map' },
        after_lexo_rank: { type: 'string', description: 'Optional LexoRank to insert after' },
      },
      required: ['entry_id', 'block_type'],
    },
  },
  {
    name: 'diary_update_block',
    description: 'Updates content of an existing block in a diary entry.',
    scope: 'diary',
    timeout_s: 10,
    input_schema: {
      type: 'object',
      properties: {
        block_id: { type: 'string', description: 'UUID of block to update' },
        content: { type: 'object', description: 'Updated block content map' },
        version: { type: 'integer', description: 'Current client version for optimistic locking' },
      },
      required: ['block_id', 'content'],
    },
  },
  {
    name: 'diary_delete_block',
    description: 'Deletes a block from a diary entry by block ID.',
    scope: 'diary',
    timeout_s: 5,
    input_schema: {
      type: 'object',
      properties: {
        block_id: { type: 'string', description: 'UUID of block to delete' },
      },
      required: ['block_id'],
    },
  },
  {
    name: 'diary_reorder_blocks',
    description: 'Reorders a block using neighbor block IDs in an entry.',
    scope: 'diary',
    timeout_s: 5,
    input_schema: {
      type: 'object',
      properties: {
        entry_id: { type: 'string' },
        block_id: { type: 'string' },
        before_block_id: { type: 'string' },
        after_block_id: { type: 'string' },
      },
      required: ['entry_id', 'block_id'],
    },
  },
  {
    name: 'diary_synthesize_notes',
    description: 'Converts raw text notes or voice transcripts into structured diary entry blocks.',
    scope: 'diary',
    timeout_s: 15,
    input_schema: {
      type: 'object',
      properties: {
        entry_id: { type: 'string' },
        raw_text: { type: 'string', description: 'Raw notes or transcript' },
      },
      required: ['entry_id', 'raw_text'],
    },
  },
  {
    name: 'diary_analyze_entry',
    description: 'Analyzes entry text and updates mood score (1-10) and energy level.',
    scope: 'diary',
    timeout_s: 15,
    input_schema: {
      type: 'object',
      properties: {
        entry_id: { type: 'string' },
        mood_score: { type: 'number', description: 'Mood score 1.0 to 10.0' },
        energy_score: { type: 'number', description: 'Energy level 1.0 to 10.0' },
      },
      required: ['entry_id', 'mood_score'],
    },
  },
  {
    name: 'diary_elevate_memory',
    description: 'Elevates a diary entry / milestone insight to the Global Identity Matrix across all AI scopes.',
    scope: 'diary',
    timeout_s: 5,
    input_schema: {
      type: 'object',
      properties: {
        entry_id: { type: 'string', description: 'UUID of entry to elevate' },
      },
      required: ['entry_id'],
    },
  },
];

/** Execute an MCP tool call by tool name. */
export async function executeJbcTool(name: string, args: Record<string, any>): Promise<unknown> {
  const repo = getDiaryRepository();
  const traceId = crypto.randomUUID().slice(0, 8);

  logger.info('jbc_mcp_tools', `Executing MCP tool: ${name}`, {
    tags: HBP_LOG_TAG.AI,
    telemetry: { tool: name, trace_id: traceId },
    traceId,
  });

  switch (name) {
    case 'diary_create_block': {
      const block = repo.createBlock(args.entry_id, args.block_type as BlockType, args.after_lexo_rank);
      if (args.content) {
        repo.updateBlockContent(block.id, JSON.stringify(args.content), block.version);
      }
      return { success: true, block: repo.getEntryBlocks(args.entry_id).find(b => b.id === block.id) };
    }

    case 'diary_update_block': {
      const version = args.version ?? 1;
      const res = repo.updateBlockContent(args.block_id, JSON.stringify(args.content), version);
      return { success: true, result: res };
    }

    case 'diary_delete_block': {
      repo.deleteBlock(args.block_id);
      return { success: true, deleted_id: args.block_id };
    }

    case 'diary_reorder_blocks': {
      repo.reorderBlockByNeighbors(args.entry_id, args.block_id, args.before_block_id ?? null, args.after_block_id ?? null);
      return { success: true };
    }

    case 'diary_synthesize_notes': {
      const text: string = args.raw_text ?? '';
      const lines = text.split('\n').filter(l => l.trim().length > 0);
      const createdBlocks = [];

      for (const line of lines) {
        if (line.trim().startsWith('- [ ]') || line.trim().startsWith('- [x]')) {
          const checked = line.includes('[x]');
          const label = line.replace(/^-\s*\[[ x]\]\s*/, '');
          const b = repo.createBlock(args.entry_id, 'checkbox');
          repo.updateBlockContent(b.id, JSON.stringify({ label, checked }), b.version);
          createdBlocks.push(b.id);
        } else {
          const b = repo.createBlock(args.entry_id, 'markdown');
          repo.updateBlockContent(b.id, JSON.stringify({ text: line }), b.version);
          createdBlocks.push(b.id);
        }
      }
      return { success: true, created_count: createdBlocks.length };
    }

    case 'diary_analyze_entry': {
      repo.updateEntryMood(args.entry_id, args.mood_score ?? null, args.energy_score ?? null);
      return { success: true, entry_id: args.entry_id, mood_score: args.mood_score, energy_score: args.energy_score };
    }

    case 'diary_elevate_memory': {
      const updated = repo.updateEntry(args.entry_id, { isGloballyElevated: true });
      return { success: true, entry: updated };
    }

    default:
      throw new Error(`Unknown JBC MCP tool: ${name}`);
  }
}
