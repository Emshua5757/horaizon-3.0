import { Socket } from 'socket.io';
import { DiaryAiSession } from '../ai/diary_ai_session';

export interface SduiRpcContext {
  socket: Socket;
  session: DiaryAiSession;
  params: any;
  transactionId?: string;
  rawPayload: any;
  orchestrator: any; // Back-reference to call sendReplacePayload or other methods
}

export interface ISduiRpcHandler {
  handle(ctx: SduiRpcContext): Promise<any>;
}
