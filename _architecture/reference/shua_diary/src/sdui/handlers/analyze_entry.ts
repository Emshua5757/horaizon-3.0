import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { encode } from '@msgpack/msgpack';

export class AnalyzeEntryHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const params = ctx.params;
    const socket = ctx.socket;
    const rawPayload = ctx.rawPayload;
    const session = ctx.session;

    const entryId = params.entry_id as string;
    const blocks = params.blocks as any[] ?? [];
    session.analysisWorker.enqueue(entryId, blocks);

    const responsePayload = {
      0: 0,
      1: { status: 'queued' },
      3: rawPayload.transaction_id
    };
    socket.emit('rpc_response', encode(responsePayload));
    return { status: 'queued' };
  }
}
