import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';
import { encode } from '@msgpack/msgpack';

export class GenerateSummaryHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const params = ctx.params;
    const socket = ctx.socket;
    const rawPayload = ctx.rawPayload;

    const content = params.content as string ?? '';
    const title = params.title as string ?? 'Untitled';
    
    logger.info('sdui_orchestrator', `generate_summary [MOCK]: Generating summary for: "${title}"`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.AI });
    const summary = `Processed analysis of "${title}". This session centers on structured journaling and semantic organization.`;
    
    const responsePayload = {
      0: 0,
      1: summary,
      3: rawPayload.transaction_id
    };
    socket.emit('rpc_response', encode(responsePayload));
    return summary;
  }
}
