import express from 'express';
import cors from 'cors';
import http from 'http';
import { Server } from 'socket.io';
import { SduiOrchestrator } from './sdui/sdui_orchestrator';
import { startMonthlySynthesisLoop } from './ai/monthly_synthesis';
import { SduiScreenAssembler } from './sdui/sdui_screen_assembler';
import { logger, HBP_LOG_TAG } from './lib/governor_logger';

const app = express();
const PORT = process.env.PORT || 3000;

let isPayloadReady = false;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.io
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(cors());

// Health check endpoint — returns 503 while pre-warming SDUI blueprints & payloads so Governor holds 'Starting' state
app.get('/health', (req, res) => {
  if (!isPayloadReady) {
    return res.status(503).json({ status: 'prewarming_payloads', ready: false });
  }
  res.status(200).json({ status: 'ok', ready: true, service: 'shua_diary_sdui4_orchestrator' });
});

server.listen(PORT, async () => {
  logger.info('server', `SDUI-4 Node.js Orchestrator listening on port ${PORT}`, {
    tags: HBP_LOG_TAG.LIFECYCLE,
    telemetry: { port: PORT },
  });
  logger.info('server', 'WebSocket Server bound to HTTP Server.', { tags: HBP_LOG_TAG.LIFECYCLE | HBP_LOG_TAG.NETWORK });

  // Initialize SDUI Orchestrator & pre-warm block registries/blueprints
  const orchestrator = new SduiOrchestrator(io);
  startMonthlySynthesisLoop();

  try {
    logger.info('sdui_prewarm', "Pre-warming initial 'diary_list' layout payload...", { tags: HBP_LOG_TAG.SDUI });
    await SduiScreenAssembler.assemble('diary_list', {});
    logger.info('sdui_prewarm', 'Layout payload successfully pre-warmed.', { tags: HBP_LOG_TAG.SDUI | HBP_LOG_TAG.PERF });
  } catch (e) {
    logger.error('sdui_prewarm', `Pre-warming payload failed: ${e}`, { tags: HBP_LOG_TAG.SDUI });
  }

  isPayloadReady = true;
  logger.info('server', 'Microservice fully initialized. Readiness set to 200 OK.', { tags: HBP_LOG_TAG.LIFECYCLE });

  // Phase 11.11 — Notify the Governor that this module is fully ready.
  // Fire-and-forget: never block startup, never throw on network failure.
  const governorUrl = process.env.GOVERNOR_URL ?? 'http://127.0.0.1:3000';
  fetch(`${governorUrl}/api/internal/ready/shua_diary`, { method: 'POST' })
    .then(() => logger.info('server', 'Notified Governor: Starting → Active', { tags: HBP_LOG_TAG.LIFECYCLE }))
    .catch(() => { /* Governor unreachable — supervisor health-check will promote us */ });
});
