import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';
import { getDiaryRepository } from '../../diary/diary_repository';
import { encode } from '@msgpack/msgpack';

export class SemanticSearchHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const params = ctx.params;
    const socket = ctx.socket;
    const rawPayload = ctx.rawPayload;

    const query = params.query as string;
    const userId = (params.user_id as string) || (socket.handshake.query.userId as string) || 'default';
    if (!query) {
      throw new Error('Query string is required');
    }

    const { getEmbedding, cosineSimilarity } = require('../../ai/embeddings');
    const queryVector = await getEmbedding(query, userId);

    const repo = getDiaryRepository();
    const allEmbeddings = repo.getAllEmbeddings();

    const results: Array<{
      blockId: string;
      entryId: string;
      entryTitle: string;
      blockType: string;
      content: string;
      similarity: number;
    }> = [];

    for (const item of allEmbeddings) {
      const sim = cosineSimilarity(queryVector, item.embedding);
      if (sim > 0.15) {
        const details = repo.getBlockSearchDetails(item.blockId);
        if (details) {
          results.push({
            blockId: item.blockId,
            entryId: details.entryId,
            entryTitle: details.entryTitle,
            blockType: details.blockType,
            content: details.content,
            similarity: sim
          });
        }
      }
    }

    results.sort((a, b) => b.similarity - a.similarity);
    const topResults = results.slice(0, 10);

    const responsePayload = {
      0: 0,
      1: topResults,
      3: rawPayload.transaction_id
    };
    socket.emit('rpc_response', encode(responsePayload));
    return topResults;
  }
}
