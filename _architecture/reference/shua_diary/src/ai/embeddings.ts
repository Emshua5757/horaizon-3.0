import { getDiaryRepository } from '../diary/diary_repository';
import { logger, HBP_LOG_TAG } from '../lib/governor_logger';

/**
 * Generates a semantic embedding vector for a given text.
 * Calls Google Gemini or Ollama if configured, or falls back to a deterministic 384-dimensional vector.
 * The generated vector is normalized (unit length), making dot product equivalent to cosine similarity.
 */
export async function getEmbedding(text: string, userId: string): Promise<number[]> {
  const repo = getDiaryRepository();
  const config = repo.getAiProviderConfig(userId);

  if (config.provider === 'gemini' && config.geminiApiKey) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${config.geminiApiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: { parts: [{ text }] } })
      });
      if (res.ok) {
        const json: any = await res.json();
        return json.embedding.values;
      }
    } catch (e) {
      logger.warn('embeddings', `Gemini API failed, using fallback: ${e}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
    }
  } else if (config.provider === 'ollama') {
    try {
      // Build Ollama embedding endpoint from the chat URL
      const baseUrl = config.ollamaUrl.replace('/api/chat', '').replace('/api/generate', '');
      const url = `${baseUrl}/api/embeddings`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: config.ollamaModel, prompt: text })
      });
      if (res.ok) {
        const json: any = await res.json();
        return json.embedding;
      }
    } catch (e) {
      logger.warn('embeddings', `Ollama API failed, using fallback: ${e}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
    }
  }

  // Fallback: Deterministic mock embedding (384-dim normalized vector based on string hash)
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash = (hash << 5) - hash + text.charCodeAt(i);
    hash |= 0;
  }
  const vector: number[] = [];
  let currentSeed = Math.abs(hash || 1);
  for (let i = 0; i < 384; i++) {
    currentSeed = (currentSeed * 16807) % 2147483647;
    vector.push((currentSeed / 2147483647) * 2 - 1);
  }
  // Normalize vector
  let norm = 0;
  for (const val of vector) norm += val * val;
  norm = Math.sqrt(norm);
  return vector.map(val => val / (norm || 1));
}

/**
 * Computes the cosine similarity (dot product of two unit vectors) between A and B.
 */
export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  let dotProduct = 0;
  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
  }
  return dotProduct;
}
