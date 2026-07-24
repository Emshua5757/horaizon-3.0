import { ISduiRpcHandler, SduiRpcContext } from '../sdui_rpc_handler';
import { logger } from '../../lib/governor_logger';
import { getDiaryRepository } from '../../diary/diary_repository';
import { DiaryAiSession } from '../../ai/diary_ai_session';
import { encode } from '@msgpack/msgpack';

export class SaveAiConfigHandler implements ISduiRpcHandler {
  async handle(ctx: SduiRpcContext): Promise<any> {
    const params = ctx.params;
    const socket = ctx.socket;
    const rawPayload = ctx.rawPayload;

    const userId = (params.user_id as string) || (socket.handshake.query.userId as string) || 'default';
    const config = params.config as Record<string, any>;

    let provider = 'gemini';
    if (config.provider_ollama === true || config.provider_ollama === 'true') {
      provider = 'ollama';
    } else if (config.provider_python_semantics === true || config.provider_python_semantics === 'true') {
      provider = 'python_semantics';
    } else if (config.provider_n8n === true || config.provider_n8n === 'true') {
      provider = 'n8n';
    }

    const finalConfig = {
      provider,
      geminiApiKey: config.geminiApiKey ?? '',
      geminiModel: config.geminiModel ?? '',
      ollamaUrl: config.ollamaUrl ?? '',
      ollamaModel: config.ollamaModel ?? '',
      pythonScriptPath: config.pythonScriptPath ?? '',
    };

    getDiaryRepository().saveModuleConfig(userId, 'shua_diary', finalConfig);
    
    // Reload session config dynamically via back-reference
    const newConfig = getDiaryRepository().getAiProviderConfig(userId);
    ctx.orchestrator.updateSession(socket.id, DiaryAiSession.create(newConfig as any, socket));

    const responsePayload = {
      0: 0,
      1: { success: true },
      3: rawPayload.transaction_id
    };
    socket.emit('rpc_response', encode(responsePayload));
    return { success: true };
  }
}
