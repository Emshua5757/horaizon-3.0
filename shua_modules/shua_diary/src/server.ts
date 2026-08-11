import express from 'express';
import http from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { encode, decode } from '@msgpack/msgpack';
import { getDiaryRepository } from './diary/diary_repository';
import { CertRepository } from './certs/cert_repository';
import { logger, HBP_LOG_TAG } from './lib/governor_logger';
import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

// ── Constants ─────────────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT ?? '3001', 10);
const GOVERNOR_URL = process.env.GOVERNOR_URL ?? 'http://127.0.0.1:7700';
const USER_ID = 'shua'; // Single-user system

// HBP v2 message type codes (matches hbp_v2_spec.md)
const MSG_REQUEST  = 1;
const MSG_RESPONSE = 2;
const MSG_PING     = 4;
const MSG_PONG     = 5;
const MSG_ERROR    = 6;

// ── Singletons ────────────────────────────────────────────────────────────────
const diaryRepo = getDiaryRepository();

// Share the same DB connection for cert repository
const dbPath = path.join(__dirname, '..', 'data', 'shua_diary.db');
if (!fs.existsSync(path.dirname(dbPath))) {
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
}
const sharedDb = new Database(dbPath);
const certRepo  = new CertRepository(sharedDb);

// ── Express HTTP server (health check only) ────────────────────────────────
const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'shua_diary', version: '3.0.0' });
});

const server = http.createServer(app);

// ── WebSocket HBP v2 dispatcher ────────────────────────────────────────────
const wss = new WebSocketServer({ server });

// Track connected clients keyed by subscribed entry_id for live entry.updated events
const entrySubscribers = new Map<string, Set<WebSocket>>();

function subscribeToEntry(ws: WebSocket, entryId: string): void {
  if (!entrySubscribers.has(entryId)) {
    entrySubscribers.set(entryId, new Set());
  }
  entrySubscribers.get(entryId)!.add(ws);
}

function unsubscribeFromAll(ws: WebSocket): void {
  for (const [, clients] of entrySubscribers) {
    clients.delete(ws);
  }
}

/** Broadcast shua.diary.entry.updated event to all clients watching that entry except the sender. */
function broadcastEntryUpdated(sender: WebSocket, entryId: string, blockId: string, version: number): void {
  const clients = entrySubscribers.get(entryId);
  if (!clients) return;

  const payload = encode({ entry_id: entryId, block_id: blockId, version });
  const frame = encode({
    v: 2, t: 3, id: crypto.randomUUID(),
    mod: 'shua.diary', op: 'entry.updated',
    ts: Date.now(), p: payload,
  });

  for (const client of clients) {
    if (client !== sender && client.readyState === WebSocket.OPEN) {
      client.send(frame);
    }
  }
}

/** Send a success response frame. */
function sendOk(ws: WebSocket, requestId: string, op: string, payload: unknown): void {
  ws.send(encode({
    v: 2, t: MSG_RESPONSE, id: requestId,
    mod: 'shua.diary', op, ts: Date.now(),
    p: encode(payload),
  }));
}

/** Send an error response frame. */
function sendError(ws: WebSocket, requestId: string, op: string, code: number, message: string): void {
  ws.send(encode({
    v: 2, t: MSG_ERROR, id: requestId,
    mod: 'shua.diary', op, ts: Date.now(),
    p: encode({}),
    err: { code, category: 6, message }, // category 6 = Internal
  }));
}

wss.on('connection', (ws) => {
  logger.info('server', 'WebSocket client connected', { tags: HBP_LOG_TAG.NETWORK });

  ws.on('close', () => {
    unsubscribeFromAll(ws);
    logger.info('server', 'WebSocket client disconnected', { tags: HBP_LOG_TAG.NETWORK });
  });

  ws.on('error', (err) => {
    logger.error('server', `WebSocket error: ${err.message}`, { tags: HBP_LOG_TAG.NETWORK });
  });

  ws.on('message', (data) => {
    let frame: any;
    try {
      frame = decode(data as Buffer);
    } catch {
      logger.warn('server', 'Received non-MessagePack frame — ignored', { tags: HBP_LOG_TAG.NETWORK });
      return;
    }

    // Handle PING → PONG immediately
    if (frame.t === MSG_PING) {
      ws.send(encode({ v: 2, t: MSG_PONG, id: frame.id, mod: 'shua.diary', op: '', ts: Date.now(), p: encode({}) }));
      return;
    }

    if (frame.t !== MSG_REQUEST) return;

    const reqId: string = frame.id ?? crypto.randomUUID();
    const op: string = `${frame.mod ?? ''}.${frame.op ?? ''}`.replace(/^\./, '');

    let payload: any = {};
    if (frame.p && frame.p.length > 0) {
      try { payload = decode(frame.p); } catch { /* empty payload */ }
    }

    // If client specifies an entry it wants live updates on, subscribe it
    if (payload.subscribe_entry_id) {
      subscribeToEntry(ws, payload.subscribe_entry_id);
    }

    dispatch(ws, reqId, op, payload).catch((err) => {
      logger.error('server', `Handler error for op '${op}': ${err?.message ?? err}`, {
        tags: HBP_LOG_TAG.NETWORK,
        telemetry: { op, error: String(err) },
      });
      sendError(ws, reqId, op, 500, `Internal error: ${err?.message ?? err}`);
    });
  });
});

// ── Operation Dispatcher ──────────────────────────────────────────────────────

async function dispatch(ws: WebSocket, reqId: string, op: string, payload: any): Promise<void> {
  logger.debug('server', `RPC: ${op}`, { tags: HBP_LOG_TAG.NETWORK });

  switch (op) {

    // ── shua.diary.entry.* ───────────────────────────────────────────────────
    case 'shua.diary.entry.list': {
      const entries = diaryRepo.getEntriesList(USER_ID);
      sendOk(ws, reqId, op, entries);
      break;
    }

    case 'shua.diary.entry.get': {
      const result = diaryRepo.getEntryWithBlocks(payload.entry_id);
      if (!result) { sendError(ws, reqId, op, 404, 'Entry not found'); break; }
      sendOk(ws, reqId, op, result);
      break;
    }

    case 'shua.diary.entry.create': {
      const entry = diaryRepo.createEntry(
        USER_ID,
        payload.title ?? 'Untitled',
        payload.ai_provider ?? 'ollama',
        payload.mood_score ?? undefined,
        payload.energy_score ?? undefined,
        payload.is_globally_elevated ?? false,
        payload.logged_at ?? undefined,
      );
      sendOk(ws, reqId, op, entry);
      break;
    }

    case 'shua.diary.entry.save': {
      const updated = diaryRepo.updateEntry(payload.entry_id, {
        title:               payload.title,
        isPrivate:           payload.is_private,
        isGloballyElevated:  payload.is_globally_elevated,
        loggedAt:            payload.logged_at,
        aiProvider:          payload.ai_provider,
      });
      if (!updated) { sendError(ws, reqId, op, 404, 'Entry not found'); break; }
      sendOk(ws, reqId, op, updated);
      break;
    }

    case 'shua.diary.entry.delete': {
      diaryRepo.deleteEntry(payload.entry_id);
      sendOk(ws, reqId, op, { ok: true });
      break;
    }

    // ── shua.diary.block.* ───────────────────────────────────────────────────
    case 'shua.diary.block.save': {
      const { block_id, entry_id, block_type, content, version } = payload;

      if (!block_id || version === undefined) {
        // New block creation
        const newBlock = diaryRepo.createBlock(entry_id, block_type ?? 'markdown', payload.after_lexo_rank);
        sendOk(ws, reqId, op, newBlock);
        broadcastEntryUpdated(ws, entry_id, newBlock.id, newBlock.version);
        break;
      }

      // Existing block update with optimistic version check
      const result = diaryRepo.updateBlockContent(block_id, content ?? '{}', version);
      if ('error' in result) {
        sendError(ws, reqId, op, 409, JSON.stringify(result));
      } else {
        sendOk(ws, reqId, op, result);
        broadcastEntryUpdated(ws, diaryRepo.getEntryIdForBlock(block_id) ?? entry_id, block_id, result.version);
      }
      break;
    }

    case 'shua.diary.block.reorder': {
      diaryRepo.reorderBlockByNeighbors(
        payload.entry_id,
        payload.block_id,
        payload.before_block_id ?? null,
        payload.after_block_id ?? null,
      );
      sendOk(ws, reqId, op, { ok: true });
      break;
    }

    case 'shua.diary.block.delete': {
      const entryId = diaryRepo.getEntryIdForBlock(payload.block_id);
      diaryRepo.deleteBlock(payload.block_id);
      sendOk(ws, reqId, op, { ok: true });
      if (entryId) broadcastEntryUpdated(ws, entryId, payload.block_id, 0);
      break;
    }

    // ── shua.diary.search ────────────────────────────────────────────────────
    case 'shua.diary.search': {
      const entries = diaryRepo.searchEntries(USER_ID, payload.query ?? '');
      const entryIds = entries.map(e => e.id);
      const ftsQuery = (payload.query ?? '').trim().split(/\s+/).filter(Boolean).map((t: string) => `${t}*`).join(' AND ');
      const snippets = diaryRepo.getSnippetsForEntries(entryIds, ftsQuery);
      const results = entries.map(e => ({
        ...e,
        snippet: snippets.get(e.id) ?? null,
      }));
      sendOk(ws, reqId, op, results);
      break;
    }

    // ── shua.diary.memory.elevate ────────────────────────────────────────────
    case 'shua.diary.memory.elevate': {
      const updated = diaryRepo.updateEntry(payload.entry_id, { isGloballyElevated: true });
      sendOk(ws, reqId, op, updated ?? { ok: true });
      break;
    }

    // ── shua.diary.cert.* ────────────────────────────────────────────────────
    case 'shua.diary.cert.list': {
      const certs = certRepo.listAll(USER_ID, payload.status);
      sendOk(ws, reqId, op, certs);
      break;
    }

    case 'shua.diary.cert.get': {
      const cert = certRepo.getById(payload.cert_id);
      if (!cert) { sendError(ws, reqId, op, 404, 'Cert not found'); break; }
      const resources = certRepo.listResources(cert.id);
      const progress = certRepo.getCertTotalProgress(cert.id, USER_ID);
      sendOk(ws, reqId, op, { cert, resources, progress });
      break;
    }

    case 'shua.diary.cert.save': {
      const saved = certRepo.save({ ...payload, userId: USER_ID });
      sendOk(ws, reqId, op, saved);
      break;
    }

    case 'shua.diary.cert.delete': {
      certRepo.delete(payload.cert_id);
      sendOk(ws, reqId, op, { ok: true });
      break;
    }

    case 'shua.diary.cert.reorder': {
      certRepo.reorder(USER_ID, payload.cert_ids);
      sendOk(ws, reqId, op, { ok: true });
      break;
    }

    case 'shua.diary.cert.roadmap': {
      sendOk(ws, reqId, op, certRepo.getRoadmap(USER_ID));
      break;
    }

    case 'shua.diary.cert.dashboard': {
      sendOk(ws, reqId, op, certRepo.getDashboardStats(USER_ID));
      break;
    }

    case 'shua.diary.cert.expiring_soon': {
      sendOk(ws, reqId, op, certRepo.getExpiringSoon(USER_ID, payload.within_days ?? 30));
      break;
    }

    case 'shua.diary.cert.resource.list': {
      sendOk(ws, reqId, op, certRepo.listResources(payload.cert_id));
      break;
    }

    case 'shua.diary.cert.resource.save': {
      const saved = certRepo.saveResource({ ...payload, certId: payload.cert_id, title: payload.title, url: payload.url });
      sendOk(ws, reqId, op, saved);
      break;
    }

    case 'shua.diary.cert.resource.delete': {
      certRepo.deleteResource(payload.resource_id);
      sendOk(ws, reqId, op, { ok: true });
      break;
    }

    case 'shua.diary.cert.progress.save': {
      const saved = certRepo.saveProgress({
        ...payload,
        resourceId: payload.resource_id,
        userId: USER_ID,
      });
      sendOk(ws, reqId, op, saved);
      break;
    }

    case 'shua.diary.cert.progress.get': {
      const progress = certRepo.getCertTotalProgress(payload.cert_id, USER_ID);
      sendOk(ws, reqId, op, progress);
      break;
    }

    case 'shua.diary.cert.investment.list': {
      const investments = certRepo.listInvestments(USER_ID, payload.cert_id);
      sendOk(ws, reqId, op, investments);
      break;
    }

    case 'shua.diary.cert.investment.save': {
      const saved = certRepo.saveInvestment({
        ...payload, userId: USER_ID,
        description: payload.description, amountPhp: payload.amount_php, paidAt: payload.paid_at,
      });
      sendOk(ws, reqId, op, saved);
      break;
    }

    case 'shua.diary.cert.investment.delete': {
      certRepo.deleteInvestment(payload.investment_id);
      sendOk(ws, reqId, op, { ok: true });
      break;
    }

    case 'shua.diary.cert.investment.summary': {
      sendOk(ws, reqId, op, certRepo.getInvestmentSummary(USER_ID));
      break;
    }

    default:
      logger.warn('server', `Unknown op: '${op}'`, { tags: HBP_LOG_TAG.NETWORK });
      sendError(ws, reqId, op, 404, `Unknown operation: ${op}`);
  }
}

// ── Start server ──────────────────────────────────────────────────────────────

server.listen(PORT, async () => {
  logger.info('server', `shua_diary v3.0 listening on port ${PORT}`, {
    tags: HBP_LOG_TAG.LIFECYCLE,
    telemetry: { port: PORT },
  });

  // Notify governor: Starting → Active
  fetch(`${GOVERNOR_URL}/api/internal/ready/shua_diary`, { method: 'POST' })
    .then(() => logger.info('server', 'Notified Governor: Starting → Active', { tags: HBP_LOG_TAG.LIFECYCLE }))
    .catch(() => { /* Governor unreachable — health check will promote */ });
});

// ── Graceful shutdown ─────────────────────────────────────────────────────────
function shutdown(signal: string): void {
  logger.info('server', `Received ${signal} — shutting down`, { tags: HBP_LOG_TAG.LIFECYCLE });
  wss.close(() => {
    server.close(() => {
      diaryRepo.close();
      sharedDb.close();
      logger.info('server', 'shua_diary shutdown complete', { tags: HBP_LOG_TAG.LIFECYCLE });
      process.exit(0);
    });
  });
}

process.on('SIGINT',  () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
