import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class RequestScreenHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const screenId = ctx.params.screenId as string;
    logger.info('sdui_orchestrator', `request_screen: ${screenId}`, { tags: HBP_LOG_TAG.SDUI });
    await ctx.orchestrator.sendReplacePayload(ctx.socket, screenId, ctx.params);
    return { success: true };
  }
}
