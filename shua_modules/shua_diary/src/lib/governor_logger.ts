// shua_diary — Governor Logger v3.0
// Binary HBP structured log emitter over TCP loopback to shua_governor port 5001.
// Ported from horAIzon 2.0 governor_logger.ts — SDUI tag removed.
//
// Zero-overhead fast-path: level gate check BEFORE any allocation.
// If level < MIN_LOG_LEVEL, returns immediately with zero heap pressure.

import { encode } from '@msgpack/msgpack';
import * as net from 'net';

// ─────────────────────────────────────────────────────────────────────────────
// HBP Log Level constants (mirrors LEVEL_* in entry.rs and HbpLogLevel in Dart)
// ─────────────────────────────────────────────────────────────────────────────
export const HBP_LOG_LEVEL = Object.freeze({
  TRACE:    1,
  DEBUG:    2,
  INFO:     3,
  WARN:     4,
  ERROR:    5,
  CRITICAL: 6,
} as const);

// 24-bit bitmask log tag constants (mirrors HbpLogTag in hbp_constants.g.dart)
export const HBP_LOG_TAG = Object.freeze({
  SYSTEM:    1,
  LIFECYCLE: 2,
  NETWORK:   4,
  DATABASE:  8,
  PERF:      32,
  SECURITY:  64,
  AI:        128,
} as const);

// Module ID for shua_diary (mirrors HBP_MODULE in Rust/Dart)
const MODULE_ID_SHUA_DIARY = 3; // shua.diary module ID

// ─────────────────────────────────────────────────────────────────────────────
// TCP Loopback Socket to Governor log listener (port 5001)
// ─────────────────────────────────────────────────────────────────────────────
const LOG_SOCKET_PORT = 5001;

let socket: net.Socket | null = null;
let isConnecting = false;
const pendingQueue: Buffer[] = [];
const MAX_PENDING_QUEUE = 500;

function connectSocket(): void {
  if (socket || isConnecting) return;
  isConnecting = true;

  const s = new net.Socket();
  s.unref(); // Allow event loop to exit even with open socket
  s.setKeepAlive(true, 5000);

  s.once('connect', () => {
    socket = s;
    isConnecting = false;
    // Flush queued logs from bootstrap phase
    while (pendingQueue.length > 0) {
      const frame = pendingQueue.shift();
      if (frame) s.write(frame);
    }
  });

  const onError = (_err: Error) => {
    socket = null;
    isConnecting = false;
    setTimeout(connectSocket, 5000).unref(); // Retry after 5s
  };

  s.on('error', onError);
  s.once('close', () => {
    socket = null;
    isConnecting = false;
    setTimeout(connectSocket, 5000).unref();
  });

  s.connect(LOG_SOCKET_PORT, '127.0.0.1');
}

// Initiate connection immediately on module load
connectSocket();

// ─────────────────────────────────────────────────────────────────────────────
// Emitter Gate
// ─────────────────────────────────────────────────────────────────────────────
const MIN_LOG_LEVEL: number = parseInt(process.env.LOG_MIN_LEVEL ?? '3', 10);

// HBP frame magic bytes
const HBP_MAGIC_H  = 0x48; // 'H'
const HBP_MAGIC_B  = 0x42; // 'B'
const HBP_TYPE_LOG = 0x12; // Type: LOG = 18

// ─────────────────────────────────────────────────────────────────────────────
// Core log() function
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Emits a structured binary HBP log frame to the Governor socket.
 *
 * @param level      - HBP_LOG_LEVEL integer (1=TRACE … 6=CRITICAL)
 * @param subsystem  - Sub-component label (e.g. 'diary_repository', 'cert_repository')
 * @param msg        - Human-readable event description
 * @param tags       - Optional 24-bit bitmask of HBP_LOG_TAG values (default 0)
 * @param telemetry  - Optional key-value performance data
 * @param traceId    - Optional 8-char hex correlation ID for cross-module tracing
 */
export function log(
  level: number,
  subsystem: string,
  msg: string,
  tags: number = 0,
  telemetry?: Record<string, unknown>,
  traceId?: string,
): void {
  // ── 1. Emitter Gate (O(1) integer compare — zero allocation fast path) ──
  if (level < MIN_LOG_LEVEL) return;

  // ── 2. Build integer-keyed payload ────────────────────────────────────
  const payload: Record<string, unknown> = {
    '0': Date.now(),            // ts:        u64 Unix ms
    '1': level,                 // level:     u8
    '2': MODULE_ID_SHUA_DIARY,  // module:    u8  = 3 (shua.diary)
    '3': subsystem,             // subsystem: string
    '4': msg,                   // msg:       string
    '5': tags,                  // tags:      u32 bitmask
  };

  if (telemetry !== undefined) payload['7'] = telemetry;
  if (traceId   !== undefined) payload['8'] = traceId;

  // ── 3. Encode + write to socket ───────────────────────────────────────
  try {
    const msgpackBytes = encode(payload);

    // 12-byte HBP header
    const header = Buffer.alloc(12, 0);
    header.writeUInt8(HBP_MAGIC_H, 0);
    header.writeUInt8(HBP_MAGIC_B, 1);
    header.writeUInt8(HBP_TYPE_LOG, 3);
    header.writeUInt32BE(msgpackBytes.length, 8);

    const frame = Buffer.concat([header, msgpackBytes]);

    if (socket && !socket.destroyed) {
      socket.write(frame, (err) => {
        if (err && pendingQueue.length < MAX_PENDING_QUEUE) {
          pendingQueue.push(frame);
        }
      });
    } else {
      if (pendingQueue.length < MAX_PENDING_QUEUE) {
        pendingQueue.push(frame);
      }
    }
  } catch {
    // Logger must NEVER throw or crash the application thread.
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience wrappers
// ─────────────────────────────────────────────────────────────────────────────

export const logger = {
  trace: (sub: string, msg: string, opts?: { tags?: number; telemetry?: Record<string, unknown>; traceId?: string }) =>
    log(HBP_LOG_LEVEL.TRACE, sub, msg, opts?.tags, opts?.telemetry, opts?.traceId),
  debug: (sub: string, msg: string, opts?: { tags?: number; telemetry?: Record<string, unknown>; traceId?: string }) =>
    log(HBP_LOG_LEVEL.DEBUG, sub, msg, opts?.tags, opts?.telemetry, opts?.traceId),
  info: (sub: string, msg: string, opts?: { tags?: number; telemetry?: Record<string, unknown>; traceId?: string }) =>
    log(HBP_LOG_LEVEL.INFO, sub, msg, opts?.tags, opts?.telemetry, opts?.traceId),
  warn: (sub: string, msg: string, opts?: { tags?: number; telemetry?: Record<string, unknown>; traceId?: string }) =>
    log(HBP_LOG_LEVEL.WARN, sub, msg, opts?.tags, opts?.telemetry, opts?.traceId),
  error: (sub: string, msg: string, opts?: { tags?: number; telemetry?: Record<string, unknown>; traceId?: string }) =>
    log(HBP_LOG_LEVEL.ERROR, sub, msg, opts?.tags, opts?.telemetry, opts?.traceId),
  critical: (sub: string, msg: string, opts?: { tags?: number; telemetry?: Record<string, unknown>; traceId?: string }) =>
    log(HBP_LOG_LEVEL.CRITICAL, sub, msg, opts?.tags, opts?.telemetry, opts?.traceId),
};
