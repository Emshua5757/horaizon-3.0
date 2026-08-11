import { WebSocket } from 'ws';
import { JBC_MCP_TOOLS } from './jbc_mcp_tools';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

const GOVERNOR_IPC_WS = process.env.GOVERNOR_IPC_WS ?? 'ws://127.0.0.1:7701/ipc';

export class JbcMcpServer {
  private ws: WebSocket | null = null;

  connectAndRegister(): void {
    try {
      this.ws = new WebSocket(GOVERNOR_IPC_WS);

      this.ws.on('open', () => {
        logger.info('jbc_mcp_server', 'Connected to Governor IPC WebSocket port 7701', {
          tags: HBP_LOG_TAG.NETWORK | HBP_LOG_TAG.AI,
        });

        // Register shua.diary module & MCP tool manifest
        const payload = {
          op: 'governor.mcp.register',
          module_id: 'shua.diary',
          version: '3.0.0',
          scope: 'diary',
          tools: JBC_MCP_TOOLS,
        };

        this.ws?.send(JSON.stringify(payload));
      });

      this.ws.on('error', (_err) => {
        // Governor may be offline in dev — fail softly
        this.ws = null;
      });

      this.ws.on('close', () => {
        this.ws = null;
      });
    } catch {
      // Ignore IPC connection errors when running standalone
    }
  }

  close(): void {
    this.ws?.close();
  }
}
