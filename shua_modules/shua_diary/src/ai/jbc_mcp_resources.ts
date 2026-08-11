import { getDiaryRepository } from '../diary/diary_repository';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * JBC MCP Resource Handlers.
 * Implements master spec `diary://` URI resource providers.
 */

export interface McpResourceDefinition {
  uri: string;
  name: string;
  description: string;
  mimeType: string;
}

export const JBC_MCP_RESOURCES: McpResourceDefinition[] = [
  {
    uri: 'diary://entries/latest',
    name: 'Latest Diary Entry',
    description: 'Returns the most recent diary entry with all native block contents.',
    mimeType: 'application/json',
  },
  {
    uri: 'diary://mood/timeline',
    name: 'Mood & Energy Timeline',
    description: 'Returns historical mood and energy ratings dataset.',
    mimeType: 'application/json',
  },
];

export async function readJbcResource(uri: string, userId: string = 'shua'): Promise<unknown> {
  const repo = getDiaryRepository();

  logger.info('jbc_mcp_resources', `Reading MCP resource: ${uri}`, {
    tags: HBP_LOG_TAG.AI,
    telemetry: { uri },
  });

  if (uri === 'diary://entries/latest') {
    const list = repo.getEntriesList(userId);
    if (list.length === 0) return null;
    return repo.getEntryWithBlocks(list[0].id);
  }

  if (uri.startsWith('diary://entries/')) {
    const entryId = uri.replace('diary://entries/', '');
    return repo.getEntryWithBlocks(entryId);
  }

  if (uri === 'diary://mood/timeline') {
    return repo.getMoodTimeline(userId, 0);
  }

  throw new Error(`Unknown JBC MCP resource URI: ${uri}`);
}
