import { IDiaryGeneratorProvider, DiaryBlueprint } from '../interfaces/i_diary_generator';
import { AiRateLimiter } from '../rate_limiter';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class GeminiGeneratorProvider implements IDiaryGeneratorProvider {
  constructor(
    private apiKey: string,
    private modelName: string,
    private rateLimiter: AiRateLimiter
  ) {}

  async generateFromNotes(rawNotes: string, style: string): Promise<DiaryBlueprint> {
    if (!this.apiKey) throw new Error('Gemini API key is not configured.');

    const prompt = `You are J.O.S.H. (Journaling, Optimization, & Semantic Heuristic), an advanced personal systems co-pilot created by Joshua.
Your task is to take raw user notes, thoughts, or bullet points, and generate a structured, premium personal diary blueprint.
Raw notes: "${rawNotes}"
Style format: "${style}" (e.g., reflective, productivity, milestone, gratitude, fitness_nutrition, finance, intellectual, travel, or dream).

The blueprint must consist of a main title, suggested alternative titles, metadata, and a series of structured content blocks.
Supported block types for blocks:
- "body": Standard paragraphs of text.
- "heading_1": Main section headers.
- "heading_2": Sub-section headers.
- "heading_3": Inner-section headers.
- "quote": Reflective thoughts or key takeaways.
- "caption": Small annotation text.
- "code": Code snippets (for scripts or code examples).
- "checklist": Interactive checklist item (one item per block).
- "bullets": Bulleted list item (one item per block).
- "numbers": Numbered list item (one item per block).
- "divider": Section separator (content should be empty).
- "mood_rating": A numeric score or description.

You MUST respond ONLY with a raw, valid JSON block matching the schema contract. Do NOT include markdown code blocks, backticks, quotes, or preamble.
Schema Contract:
{
  "title": "string (the main chosen title)",
  "suggestedTitles": ["string", "string", "string"],
  "blocks": [
    { "blockType": "body" | "heading_1" | "heading_2" | "heading_3" | "quote" | "caption" | "code" | "checklist" | "bullets" | "numbers" | "divider" | "mood_rating", "content": "string" }
  ],
  "metadata": {
    "mood": "happy" | "neutral" | "stressed",
    "category": "software_engineering" | "personal" | "career" | "milestone" | "gratitude" | "fitness_nutrition" | "finance" | "intellectual" | "travel" | "dream",
    "priority": 1 | 2 | 3
  }
}`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:generateContent?key=${this.apiKey}`;

    return this.rateLimiter.execute(async () => {
      logger.info('gemini_generator_provider', `Generating blueprint using: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            responseMimeType: 'application/json'
          }
        })
      });

      if (!response.ok) {
        throw new Error(`Gemini HTTP error status: ${response.status}`);
      }

      const data: any = await response.json();
      const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';

      const cleanJson = replyText.replace(/```json/gi, '').replace(/```/g, '').trim();
      const parsed = JSON.parse(cleanJson) as DiaryBlueprint;

      return parsed;
    });
  }

  async *generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string> {
    if (!this.apiKey) throw new Error('Gemini API key is not configured.');

    const prompt = `You are J.O.S.H. (Journaling, Optimization, & Semantic Heuristic), an advanced personal systems co-pilot created by Joshua.
Generate a structured, template-rich personal diary blueprint about: "${rawNotes}".
Style format: "${style}" (reflective, productivity, milestone, gratitude, fitness_nutrition, finance, intellectual, travel, or dream).
Stream your raw Markdown response directly. Do not include metadata or JSON structures in this streaming channel.`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:streamGenerateContent?key=${this.apiKey}`;

    const response = await this.rateLimiter.execute(async () => {
      logger.info('gemini_generator_provider', `Starting stream using: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      return fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.7 }
        })
      });
    });

    if (!response.ok || !response.body) {
      throw new Error(`Gemini streaming HTTP error status: ${response.status}`);
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value, { stream: true });
        buffer += chunk;

        let match;
        let lastIndex = 0;
        const regex = /"text"\s*:\s*"((?:[^"\\]|\\.)*)"/g;

        while ((match = regex.exec(buffer)) !== null) {
          try {
            const rawString = match[1];
            const content = JSON.parse(`"${rawString}"`);
            yield content;
          } catch (e) {}
          lastIndex = regex.lastIndex;
        }

        if (lastIndex > 0) {
          buffer = buffer.substring(lastIndex);
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}
