import { IDiaryGeneratorProvider, DiaryBlueprint } from '../interfaces/i_diary_generator';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class OllamaGeneratorProvider implements IDiaryGeneratorProvider {
  constructor(
    private ollamaUrl: string,
    private modelName: string
  ) {}

  async generateFromNotes(rawNotes: string, style: string): Promise<DiaryBlueprint> {
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

    const isChatEndpoint = this.ollamaUrl.endsWith('/chat');
    const body = isChatEndpoint
      ? {
          model: this.modelName,
          messages: [{ role: 'user', content: prompt }],
          stream: false,
          options: { temperature: 0.7 }
        }
      : {
          model: this.modelName,
          prompt: prompt,
          stream: false,
          options: { temperature: 0.7 }
        };

    logger.info('ollama_generator_provider', `Querying Ollama: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
    const response = await fetch(this.ollamaUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    if (!response.ok) {
      throw new Error(`Ollama HTTP error status: ${response.status}`);
    }

    const data: any = await response.json();
    const replyText = (data.response || data.message?.content || '').trim();

    const cleanJson = replyText.replace(/```json/gi, '').replace(/```/g, '').trim();
    const parsed = JSON.parse(cleanJson) as DiaryBlueprint;

    return parsed;
  }

  async *generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string> {
    const prompt = `You are J.O.S.H. (Journaling, Optimization, & Semantic Heuristic), an advanced personal systems co-pilot created by Joshua.
Generate a structured, template-rich personal diary blueprint about: "${rawNotes}".
Style format: "${style}" (reflective, productivity, milestone, gratitude, fitness_nutrition, finance, intellectual, travel, or dream).
Stream your raw Markdown response directly. Do not include metadata or JSON structures in this streaming channel.`;

    const isChatEndpoint = this.ollamaUrl.endsWith('/chat');
    const body = isChatEndpoint
      ? {
          model: this.modelName,
          messages: [{ role: 'user', content: prompt }],
          stream: true,
          options: { temperature: 0.7 }
        }
      : {
          model: this.modelName,
          prompt: prompt,
          stream: true,
          options: { temperature: 0.7 }
        };

    logger.info('ollama_generator_provider', `Querying stream: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
    const response = await fetch(this.ollamaUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    if (!response.ok || !response.body) {
      throw new Error(`Ollama streaming HTTP error status: ${response.status}`);
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

        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const parsed = JSON.parse(line);
            const content = parsed.response || parsed.message?.content;
            if (content) {
              yield content;
            }
          } catch (e) {
            // Keep buffer if line is not complete JSON
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}
