/**
 * AiRateLimiter
 * 
 * A token-bucket rate limiter protecting against API quota breaches.
 * Originally built for Gemini free tier (15 RPM), but made instantiable
 * in V4 to support per-provider, per-session rate limits (e.g. limiting
 * local Ollama concurrent generations to prevent Pi 5 OOM crashes).
 * 
 * Queues requests internally and executes them serially, never dropping them.
 */
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';
export class AiRateLimiter {
  private tokens: number;
  private lastRefill = Date.now();
  private readonly refillIntervalMs: number;
  
  // Global serial execution queue to preserve request ordering
  private queue: Promise<any> = Promise.resolve();

  /**
   * @param rpmCeiling Target requests per minute (e.g., 15 for Gemini Free Tier)
   * @param burstMax Maximum tokens allowed to accumulate (defaults to 5)
   */
  constructor(private rpmCeiling: number = 15, private burstMax: number = 5) {
    this.tokens = burstMax;
    // e.g. 15 RPM = 1 token every 4000ms
    this.refillIntervalMs = Math.floor(60000 / this.rpmCeiling);
  }

  /**
   * Refills the targeted bucket based on elapsed time math.
   */
  private refill(): void {
    const now = Date.now();
    const elapsed = now - this.lastRefill;
    if (elapsed >= this.refillIntervalMs) {
      const newTokens = Math.floor(elapsed / this.refillIntervalMs);
      this.tokens = Math.min(
        this.burstMax,
        this.tokens + newTokens
      );
      this.lastRefill = now - (elapsed % this.refillIntervalMs);
    }
  }

  /**
   * Enqueues and executes an async operation protected under rate limiting bounds.
   */
  async execute<T>(task: () => Promise<T>): Promise<T> {
    const resultPromise = this.queue.then(async () => {
      while (true) {
        this.refill();

        if (this.tokens > 0) {
          this.tokens--;
          logger.debug('rate_limiter', `Token consumed. Bucket: ${this.tokens}/${this.burstMax}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.PERF });
          return task();
        }

        const waitTime = this.refillIntervalMs - (Date.now() - this.lastRefill);
        logger.warn('rate_limiter', `429 Pre-emption: Bucket exhausted. Holding execution queue for ${Math.max(10, waitTime)}ms...`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.PERF, telemetry: { waitMs: Math.max(10, waitTime) } });
        await new Promise((resolve) => setTimeout(resolve, Math.max(10, waitTime)));
      }
    });

    this.queue = resultPromise.then(
      () => {},
      () => {}
    );

    return resultPromise;
  }
}
