import { Server, Socket } from 'socket.io';
import { SduiStateVault } from './sdui_state_vault';
import { encode } from '@msgpack/msgpack';
import { SduiScreenAssembler } from './sdui_screen_assembler';
import { SduiActionHandler } from './sdui_action_handler';
import { SduiBlockRegistry } from './sdui_block_registry';
import { DiaryAiSession } from '../ai/diary_ai_session';
import { getDiaryRepository } from '../diary/diary_repository';
import { SduiBlueprintLoader } from './sdui_blueprint_loader';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

import { ISduiRpcHandler } from './sdui_rpc_handler';
import { RequestScreenHandler } from './handlers/request_screen';
import { GenerateFromNotesHandler } from './handlers/generate_from_notes';
import { ChatHandler } from './handlers/chat';
import { ApplyMutationsHandler } from './handlers/apply_mutations';
import { SemanticSearchHandler } from './handlers/semantic_search';
import { AnalyzeEntryHandler } from './handlers/analyze_entry';
import { GenerateSummaryHandler } from './handlers/generate_summary';
import { SaveAiConfigHandler } from './handlers/save_ai_config';

export class SduiOrchestrator {
  private io: Server;
  // Maps socket.id -> SduiStateVault
  private vaults: Map<string, SduiStateVault> = new Map();
  // Maps socket.id -> DiaryAiSession
  private sessions: Map<string, DiaryAiSession> = new Map();
  // $O(1)$ RPC registry map
  private rpcRegistry: Map<string, ISduiRpcHandler> = new Map();

  constructor(io: Server) {
    this.io = io;
    // Warm the block registry at startup — one fs.readFileSync, never again
    SduiBlockRegistry.load();
    this.registerHandlers();
    this.setupListeners();
    this.setupHotReloadWatcher();
  }

  private registerHandlers() {
    this.rpcRegistry.set('request_screen', new RequestScreenHandler());
    this.rpcRegistry.set('shua.diary.generate_from_notes', new GenerateFromNotesHandler());
    this.rpcRegistry.set('shua.diary.chat', new ChatHandler());
    this.rpcRegistry.set('shua.diary.apply_mutations', new ApplyMutationsHandler());
    this.rpcRegistry.set('shua.diary.semantic_search', new SemanticSearchHandler());
    this.rpcRegistry.set('shua.diary.analyze_entry', new AnalyzeEntryHandler());
    this.rpcRegistry.set('shua.diary.generate_summary', new GenerateSummaryHandler());
    this.rpcRegistry.set('shua.diary.save_ai_config', new SaveAiConfigHandler());
  }

  public updateSession(socketId: string, session: DiaryAiSession) {
    this.sessions.set(socketId, session);
  }

  private setupHotReloadWatcher() {
    SduiBlueprintLoader.events.on('blueprint_changed', (cachedPath: string) => {
      logger.info('sdui_orchestrator', `Blueprint changed, resolving affected screen patterns for: ${cachedPath}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.LIFECYCLE });
      
      const affectedPatterns: string[] = [];
      if (cachedPath === 'diary/diary') {
        affectedPatterns.push('diary_list', 'diary_ai_config');
      } else if (cachedPath === 'diary/diary_editor' || cachedPath.startsWith('block:')) {
        affectedPatterns.push('diary_editor_*', 'diary_block_picker_*');
      } else if (cachedPath === 'diary/diary_block_picker') {
        affectedPatterns.push('diary_block_picker_*');
      } else if (cachedPath === 'diary/diary_options') {
        affectedPatterns.push('diary_options_*');
      } else {
        // Fallback: reload everything if it's an unknown/global blueprint
        affectedPatterns.push('*');
      }

      for (const pattern of affectedPatterns) {
        logger.info('sdui_orchestrator', `Broadcasting hot_reload for screen pattern: ${pattern}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.NETWORK });
        const payload = encode({
          screenIdPattern: pattern
        });
        this.io.emit('hot_reload', payload);
      }
    });
  }

  private setupListeners() {
    this.io.on('connection', (socket: Socket) => {
      logger.info('sdui_orchestrator', `Client connected: ${socket.id}`, { tags: HBP_LOG_TAG.NETWORK | HBP_LOG_TAG.LIFECYCLE });
      this.vaults.set(socket.id, new SduiStateVault());

      // Pre-warm the session with the connected user config
      const userId = (socket.handshake.query.userId as string) || 'default';
      const config = getDiaryRepository().getAiProviderConfig(userId);
      this.sessions.set(socket.id, DiaryAiSession.create(config as any, socket));

      socket.on('disconnect', () => {
        logger.info('sdui_orchestrator', `Client disconnected: ${socket.id}`, { tags: HBP_LOG_TAG.NETWORK | HBP_LOG_TAG.LIFECYCLE });
        this.vaults.delete(socket.id);
        
        const session = this.sessions.get(socket.id);
        if (session) {
          session.analysisWorker.cancelPendingForSocket();
          this.sessions.delete(socket.id);
        }
      });

      // Unified event for receiving RPCs from Flutter
      socket.on('rpc', (data: any) => {
        this.handleRpc(socket, data);
      });
    });
  }

  private async handleRpc(socket: Socket, data: any) {
    const method = data.method as string;
    const params  = data.params ?? {};
    
    logger.debug('sdui_orchestrator', `handleRpc: socket=${socket.id} method=${method}`, { tags: HBP_LOG_TAG.SDUI, telemetry: { method } });

    // Retrieve or instantiate active AI session
    let session = this.sessions.get(socket.id);
    if (!session) {
      const userId = (params.user_id as string) || (socket.handshake.query.userId as string) || 'default';
      const config = getDiaryRepository().getAiProviderConfig(userId);
      session = DiaryAiSession.create(config as any, socket);
      this.sessions.set(socket.id, session);
    }

    const handler = this.rpcRegistry.get(method);
    if (handler) {
      try {
        await handler.handle({
          socket,
          session,
          params,
          transactionId: data.transaction_id,
          rawPayload: data,
          orchestrator: this,
        });
      } catch (err: any) {
        logger.error('sdui_orchestrator', `RPC handler error for method '${method}': ${err?.message}`, { tags: HBP_LOG_TAG.SDUI });
        const errorPayload = {
          0: 1, // ERROR status
          2: err?.message || 'RPC execution failed',
          3: data.transaction_id
        };
        socket.emit('rpc_response', encode(errorPayload));
      }
    } else if (method.startsWith('shua.')) {
      // All other shua.* methods are write/mutate actions — route to action handler
      SduiActionHandler.handle(socket, method, params);
    } else {
      logger.warn('sdui_orchestrator', `Unknown RPC method: '${method}'`, { tags: HBP_LOG_TAG.SDUI });
    }
  }

  public async sendReplacePayload(socket: Socket, screenId: string, params: Record<string, any>) {
    try {
      // SduiScreenAssembler owns the routing logic and DB fetching.
      // It returns a root AST node (or array of root nodes).
      const payload = await SduiScreenAssembler.assemble(screenId, params);
      if (!payload) {
        logger.error('sdui_orchestrator', `SduiScreenAssembler returned null for screen: ${screenId}`, { tags: HBP_LOG_TAG.SDUI });
        return;
      }

      if (screenId.startsWith('diary_editor_')) {
        // Verbose block dump — DEBUG level, suppressed in production (LOG_MIN_LEVEL=3)
        const entryId = screenId.replace('diary_editor_', '');
        const repo = getDiaryRepository();
        const entryData = repo.getEntryWithBlocks(entryId);
        if (entryData) {
          for (const b of entryData.blocks) {
            logger.debug('sdui_orchestrator', `Block: id=${b.id} type=${b.blockType}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
          }
        } else {
          logger.debug('sdui_orchestrator', `No blocks found for entry: ${entryId}`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.DATABASE });
        }
      }

      // Flutter's SduiTransport._parseList() expects a top-level List.
      // Wrap the root node in an array if it is a single object.
      const arrayPayload = Array.isArray(payload) ? payload : [payload];

      const binaryPayload = encode(arrayPayload);
      socket.emit(`replace_${screenId}`, binaryPayload);
      logger.info('sdui_orchestrator', `Sent replace payload for '${screenId}'`, { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.PERF, telemetry: { screenId, bytes: binaryPayload.byteLength } });
    } catch (e: any) {
      logger.error('sdui_orchestrator', `Error sending replace payload for '${screenId}': ${e?.message}`, { tags: HBP_LOG_TAG.SDUI });
    }
  }
}
