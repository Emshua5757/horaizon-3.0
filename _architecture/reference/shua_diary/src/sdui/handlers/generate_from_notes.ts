import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';
import { getDiaryRepository } from '../../diary/diary_repository';
import { encode } from '@msgpack/msgpack';

export class GenerateFromNotesHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const params = ctx.params;
    const socket = ctx.socket;
    const rawPayload = ctx.rawPayload;

    const rawNotes = (params.raw_notes || params.ai_prompt) as string ?? '';
    const style = params.style as string ?? 'reflective';

    logger.info('sdui_orchestrator', `generate_from_notes [MOCK]: Generating blueprint from notes (${rawNotes.length} chars)`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.AI });
    const blueprint = {
      title: `Optimized Entry: ${rawNotes.length > 30 ? rawNotes.substring(0, 30) + '...' : rawNotes}`,
      suggestedTitles: [
        `Deep Work Reflection`,
        `Systems Engineering Log`,
        `Self-Hosted AI Verification`
      ],
      blocks: [
        { blockType: 'heading_2', content: `J.O.S.H. Structured Entry` },
        { blockType: 'body', content: `Here is the processed transcript of your user notes:\n\n${rawNotes}` },
        { blockType: 'checklist', content: `- [ ] Finish Phase 10 Rust Governor\n- [ ] Complete full SDUI verification` }
      ],
      metadata: {
        mood: 'focused',
        category: 'software_engineering',
        priority: 2
      }
    };

    const repo = getDiaryRepository();
    const userId = (params.user_id as string) || (socket.handshake.query.userId as string) || 'default';
    
    logger.info('sdui_orchestrator', `generate_from_notes: Hydrating new entry for user: ${userId}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
    const newEntry = repo.createEntry(
      userId,
      blueprint.title,
      'gemini',
      0.8,
      0.7,
      false,
      new Date().toISOString()
    );

    for (const block of blueprint.blocks) {
      const newBlock = repo.createBlock(newEntry.id, block.blockType as any);
      repo.updateBlock(newBlock.id, block.content);
    }

    await ctx.orchestrator.sendReplacePayload(socket, 'diary_list', params);
    
    const responsePayload = {
      0: 0, // OK status
      1: blueprint, // data
      3: rawPayload.transaction_id
    };
    socket.emit('rpc_response', encode(responsePayload));
    return blueprint;
  }
}
