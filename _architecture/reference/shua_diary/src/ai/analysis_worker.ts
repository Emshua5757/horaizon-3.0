import { Socket } from 'socket.io';
import { IAnalyzerProvider, AnalysisResult } from './interfaces/i_analyzer';
import { SduiDeltaEmitter } from '../sdui/sdui_delta_emitter';
import { getDiaryRepository } from '../diary/diary_repository';
import { HBP_BEHAVIOR, HBP_CONTENT, HBP_COLOR_TOKEN } from '../models/HbpConstants';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

interface PendingJob {
  entryId: string;
  blocks: Array<{ blockType: string; content: string }>;
}

type AnalysisStatus =
  | { state: 'queued' }
  | { state: 'processing' }
  | { state: 'done'; result: AnalysisResult }
  | { state: 'error'; result: AnalysisResult };

/**
 * Background worker that processes the offline-first analysis queue.
 *
 * Architecture:
 * - Instantiated per-session (per socket connection).
 * - Maintains an in-memory FIFO job queue.
 * - Executes one job at a time (Bulkhead pattern) to avoid GPU/CPU memory spikes
 *   on the 8GB Pi 5 ceiling.
 * - Emits a WebSocket delta patch upon completion, updating the Flutter UI instantly.
 * - Stores completed results in a bounded LRU-like result cache (capped at 50
 *   entries, FIFO eviction) so clients can query historical states if they reconnect.
 */
export class AnalysisWorker {
  private queue: PendingJob[] = [];
  private isProcessing = false;
  private isCancelled = false;

  private readonly MAX_CACHE_SIZE = 50;
  private resultCache = new Map<string, AnalysisStatus>();
  private cacheInsertionOrder: string[] = [];

  constructor(
    private readonly socket: Socket,
    private readonly analyzerProvider: IAnalyzerProvider
  ) {}

  /**
   * Enqueues an entry for analysis.
   * Time complexity: O(N) dedup scan on queue (queue depth is capped at ~50 entries
   * in practice, so this is effectively O(1)).
   */
  enqueue(entryId: string, blocks: Array<{ blockType: string; content: string }>): void {
    if (this.isCancelled) return;

    // Dedup: replace stale job if same entryId is already queued
    const existingIdx = this.queue.findIndex((j) => j.entryId === entryId);
    if (existingIdx !== -1) {
      this.queue.splice(existingIdx, 1);
      logger.debug('analysis_worker', `Replaced stale job for entryId: ${entryId}`, { tags: HBP_LOG_TAG.AI });
    }

    this.queue.push({ entryId, blocks });
    this._setStatus(entryId, { state: 'queued' });

    logger.info('analysis_worker', `Enqueued entryId: ${entryId}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.PERF, telemetry: { entryId, queueDepth: this.queue.length } });

    if (!this.isProcessing) {
      this._processNext();
    }
  }

  getStatus(entryId: string): AnalysisStatus | null {
    return this.resultCache.get(entryId) ?? null;
  }

  get queueDepth(): number {
    return this.queue.length;
  }

  cancelPendingForSocket(): void {
    this.isCancelled = true;
    this.queue = [];
    logger.info('analysis_worker', 'Cancelled pending jobs for disconnected socket', { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.LIFECYCLE });
  }

  private _setStatus(entryId: string, status: AnalysisStatus): void {
    if (!this.resultCache.has(entryId)) {
      if (this.cacheInsertionOrder.length >= this.MAX_CACHE_SIZE) {
        const evict = this.cacheInsertionOrder.shift()!;
        this.resultCache.delete(evict);
        logger.debug('analysis_worker', `Evicted cache entry for entryId: ${evict}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.PERF });
      }
      this.cacheInsertionOrder.push(entryId);
    }
    this.resultCache.set(entryId, status);
  }

  private async _processNext(): Promise<void> {
    if (this.queue.length === 0 || this.isCancelled) {
      this.isProcessing = false;
      return;
    }

    this.isProcessing = true;
    const job = this.queue.shift()!;
    const { entryId, blocks } = job;

    this._setStatus(entryId, { state: 'processing' });
    logger.info('analysis_worker', `Processing entryId: ${entryId} — ${blocks.length} blocks`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.PERF, telemetry: { entryId, blockCount: blocks.length } });

    // Filter to analyzable text types (V4 schema names)
    const textTypes = new Set([
      'body', 'heading_1', 'heading_2', 'heading_3', 'quote'
    ]);

    const fullText = blocks
      .filter((b) => textTypes.has(b.blockType))
      .map((b) => b.content)
      .join('\n')
      .trim();

    if (!fullText) {
      logger.warn('analysis_worker', `No analyzable text for entryId: ${entryId}. Skipping.`, { tags: HBP_LOG_TAG.AI });
      const errorResult: AnalysisResult = {
        sentimentScore: 0.0,
        isMilestone: false,
        milestoneTag: 'neutral',
        privacyTag: 'sfw',
        summary: 'No content to analyze.',
      };
      try {
        getDiaryRepository().updateEntryAnalysis(entryId, errorResult.sentimentScore, errorResult.summary);
      } catch (dbErr) {
        logger.error('analysis_worker', `Failed to save error analysis to DB: ${dbErr}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      }
      this._setStatus(entryId, { state: 'error', result: errorResult });
      this._pushDelta(entryId, errorResult);
      this._processNext();
      return;
    }

    try {
      const result = await this.analyzerProvider.analyze(fullText);
      logger.info('analysis_worker', `Completed entryId: ${entryId}`, {
        tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.PERF,
        telemetry: { entryId, sentiment: result.sentimentScore, milestone: result.isMilestone },
      });

      try {
        getDiaryRepository().updateEntryAnalysis(entryId, result.sentimentScore, result.summary);
      } catch (dbErr) {
        logger.error('analysis_worker', `Failed to save analysis to DB for entryId: ${entryId}: ${dbErr}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      }

      this._setStatus(entryId, { state: 'done', result });
      this._pushDelta(entryId, result);
    } catch (err: any) {
      logger.error('analysis_worker', `Failed for entryId: ${entryId}: ${err?.message}`, { tags: HBP_LOG_TAG.AI });
      const errorResult: AnalysisResult = {
        sentimentScore: 0.0,
        isMilestone: false,
        milestoneTag: 'neutral',
        privacyTag: 'sfw',
        summary: 'Analysis failed.',
      };
      try {
        getDiaryRepository().updateEntryAnalysis(entryId, errorResult.sentimentScore, errorResult.summary);
      } catch (dbErr) {
        logger.error('analysis_worker', `Failed to save catch-error analysis to DB: ${dbErr}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.DATABASE });
      }
      this._setStatus(entryId, { state: 'error', result: errorResult });
      this._pushDelta(entryId, errorResult);
    }

    // Tail-recurse to drain remaining queue
    this._processNext();
  }

  private _pushDelta(entryId: string, result: AnalysisResult): void {
    if (this.isCancelled) return;

    // V4 architecture: push live delta to diary_list sentiment badge & preview nodes
    SduiDeltaEmitter.emitPatch(
      this.socket,
      'diary_list',
      `diary_list:entry_card_${entryId}:sentiment`,
      {
        [HBP_BEHAVIOR.ACCENT_COLOR_TOKEN]: result.sentimentScore < -0.2
          ? HBP_COLOR_TOKEN.ERROR
          : result.sentimentScore > 0.2
            ? HBP_COLOR_TOKEN.PRIMARY
            : HBP_COLOR_TOKEN.SECONDARY
      },
      {
        [HBP_CONTENT.LABEL]: result.milestoneTag !== 'neutral' ? `${result.milestoneTag}` : `Mood: ${result.sentimentScore.toFixed(1)}`,
        [HBP_CONTENT.ICON_NAME]: result.sentimentScore < -0.2 ? 'sentiment_dissatisfied' : result.sentimentScore > 0.2 ? 'sentiment_satisfied' : 'sentiment_neutral',
      }
    );

    SduiDeltaEmitter.emitPatch(
      this.socket,
      'diary_list',
      `diary_list:entry_card_${entryId}:preview`,
      undefined,
      {
        [HBP_CONTENT.VALUE]: result.summary
      }
    );
  }
}
