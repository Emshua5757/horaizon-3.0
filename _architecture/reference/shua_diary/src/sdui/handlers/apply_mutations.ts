import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';
import { getDiaryRepository } from '../../diary/diary_repository';
import { encode } from '@msgpack/msgpack';

export class ApplyMutationsHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const params = ctx.params;
    const socket = ctx.socket;
    const rawPayload = ctx.rawPayload;

    const entryId = params.entry_id as string;
    const mutations = params.mutations as any[] ?? [];
    const repo = getDiaryRepository();

    logger.info('sdui_orchestrator', `apply_mutations: ${mutations.length} mutations for entry: ${entryId}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE, telemetry: { count: mutations.length, entryId } });

    for (const mutation of mutations) {
      if (mutation.action === 'DELETE') {
        logger.debug('sdui_orchestrator', `DELETE mutation for block ID: ${mutation.id}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
        repo.deleteBlock(mutation.id);
      } else if (mutation.action === 'UPDATE') {
        logger.debug('sdui_orchestrator', `UPDATE mutation for block ID: ${mutation.id}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
        repo.updateBlock(mutation.id, mutation.content);
      } else if (mutation.action === 'INSERT') {
        logger.debug('sdui_orchestrator', `INSERT mutation. afterId: ${mutation.afterId}, type: ${mutation.type}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
        
        let targetRank: string | undefined;
        if (mutation.afterId === 'top' || mutation.afterId === '0') {
          // Insert at the absolute top
          const firstRow = (repo as any).stmt('firstBlockRank',
            `SELECT lexo_rank FROM diary_blocks WHERE entry_id = ? ORDER BY lexo_rank ASC LIMIT 1`
          ).get(entryId) as { lexo_rank: string } | undefined;

          const prefix = '0|hzzzzz:';
          if (!firstRow) {
            targetRank = undefined; // append will use default rank
          } else {
            const hiSuffix = firstRow.lexo_rank.startsWith(prefix)
              ? firstRow.lexo_rank.slice(prefix.length)
              : firstRow.lexo_rank;
            const midSuffix = (repo.constructor as any)._midRankSuffix('', hiSuffix);
            targetRank = prefix + midSuffix;
          }
        } else {
          // Insert after target block ID
          const targetRankStr = repo.getBlockLexoRank(mutation.afterId);
          if (targetRankStr) {
            targetRank = (repo as any)._lexoRankAfter(entryId, targetRankStr);
          }
        }

        const newBlock = repo.createBlock(entryId, mutation.type, targetRank);
        if (mutation.content) {
          repo.updateBlock(newBlock.id, mutation.content);
        }
      }
    }

    // Silent request screen triggers a full screen replacement payload
    // which updates the editor UI instantly!
    await ctx.orchestrator.sendReplacePayload(socket, `diary_editor_${entryId}`, params);

    const responsePayload = {
      0: 0, // OK status
      1: { success: true },
      3: rawPayload.transaction_id
    };
    socket.emit('rpc_response', encode(responsePayload));
    return { success: true };
  }
}
