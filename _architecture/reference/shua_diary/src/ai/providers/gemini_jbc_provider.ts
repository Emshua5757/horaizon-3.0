import { IJbcChatProvider, DiaryStateSnapshot, JbcPlanResult, JbcIntent } from '../interfaces/i_jbc_chat';
import { JbcTranslator } from '../jbc/jbc_translator';
import { AiRateLimiter } from '../rate_limiter';
import { SduiBlockRegistry } from '../../sdui/sdui_block_registry';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class GeminiJbcProvider implements IJbcChatProvider {
  constructor(
    private apiKey: string,
    private modelName: string,
    private rateLimiter: AiRateLimiter
  ) {}

  /**
   * Stage 1: Deterministic JBC bytecode planner (temperature 0.0)
   */
  async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult> {
    if (!this.apiKey) throw new Error('Gemini API key is not configured.');

    // 1. Resolve positional references (e.g. "block 1", "#2") to real UUIDs
    const resolvedPrompt = this.resolvePositionalRefs(prompt, state.blocks);

    // 2. Serialize the current active diary blocks for the LLM context
    const blocksContent = state.blocks.length === 0
      ? '(The diary entry is currently empty.)'
      : JbcTranslator.serializeDiaryState(state.blocks);

    const editableTypes = SduiBlockRegistry.getAiEditableTypes().join(', ');
    const systemTypes = SduiBlockRegistry.getSystemOwnedTypes().join(', ');

    const plannerSystemPrompt = `You are the J.O.S.H. Bytecode (JBC) compiler integrated into the S.H.U.A. Diary Engine. Your sole objective is to translate a user's natural language refactoring instruction into a minimal, deterministic, pipe-separated bytecode stream that represents precise block-level mutations.

Bytecode Instruction Schema:
  I:<after_uuid>|<block_type>|<content>   Insert a new block after the given block UUID. Use 'top' to insert at position 0.
  U:<block_uuid>|<content>                Update an existing block's content by its UUID.
  D:<block_uuid>                          Delete a block by its UUID.

Valid AI-editable block types:
  ${editableTypes}

CRITICAL RULES:
  1. Output ONLY valid bytecode instructions, separated by newlines.
  2. Do NOT output markdown, prose, explanations, comments, or apologies.
  3. Do NOT generate I, U, or D instructions for system blocks:
     ${systemTypes}
  4. Reference blocks by their exact UUID. Never invent or guess a UUID.
  5. If the user's request requires no mutations (greetings, questions, summaries,
     read requests, praise, out-of-scope requests, or system commands), output exactly: NO_OP
  6. Multiple instructions must be on separate lines with no blank lines between them.`;

    const userMessage = `Title: ${state.entryTitle}\n${blocksContent.trim()}\n\nUser Request: "${resolvedPrompt}"\n\nOutput JBC bytecode now:`;

    const plannerUrl = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:generateContent?key=${this.apiKey}`;

    return this.rateLimiter.execute(async () => {
      logger.info('gemini_jbc_provider', `Querying JBC Planner: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      const response = await fetch(plannerUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            { role: 'user', parts: [{ text: `${plannerSystemPrompt}\n\n${userMessage}` }] }
          ],
          generationConfig: { temperature: 0.0 }
        })
      });

      if (!response.ok) {
        throw new Error(`Gemini Planner HTTP error status: ${response.status}`);
      }

      const data: any = await response.json();
      const rawBytecode = (data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || 'NO_OP').trim();
      logger.debug('gemini_jbc_provider', `Planner JBC output:\n${rawBytecode}`, { tags: HBP_LOG_TAG.AI });

      const { intent: parsedIntent, mutations } = JbcTranslator.parse(rawBytecode, state.blocks);

      // Determine the final intent heuristic
      let resolvedIntent: JbcIntent = 'CONVERSE';
      const lowerPrompt = prompt.toLowerCase();

      if (parsedIntent === 'MUTATE') {
        resolvedIntent = 'MUTATE';
      } else if (
        lowerPrompt.includes('comprehensive') ||
        lowerPrompt.includes('suggest') ||
        lowerPrompt.includes('template') ||
        lowerPrompt.includes('outline') ||
        lowerPrompt.includes('blueprint') ||
        lowerPrompt.includes('expand') ||
        lowerPrompt.includes('write') ||
        lowerPrompt.includes('fill')
      ) {
        resolvedIntent = 'SUGGEST_TEMPLATE';
      } else if (rawBytecode === 'NO_OP') {
        resolvedIntent = 'NO_OP';
      }

      // If resolved as NO_OP but user requested suggestions, upgrade to CONVERSE/SUGGEST
      if (resolvedIntent === 'NO_OP' && !lowerPrompt.includes('no_op')) {
        resolvedIntent = lowerPrompt.includes('template') ? 'SUGGEST_TEMPLATE' : 'CONVERSE';
      }

      const mutationsSummary = resolvedIntent === 'MUTATE' && mutations.length > 0
        ? JbcTranslator.translate(rawBytecode, state.blocks)
        : '';

      return {
        intent: resolvedIntent,
        rawBytecode,
        mutations,
        mutationsSummary
      };
    });
  }

  /**
   * Stage 2: Streaming conversational presenter (temperature 0.7)
   */
  async *presentJbcStream(
    prompt: string,
    planResult: JbcPlanResult,
    history: Array<{ role: 'user' | 'assistant'; content: string }>,
    state: DiaryStateSnapshot
  ): AsyncIterable<string> {
    if (!this.apiKey) throw new Error('Gemini API key is not configured.');

    // 1. Prepend JBC trace for debug visibility
    yield `[JBC_TRACE: ${planResult.rawBytecode.replace(/\n/g, '↵')}]`;

    // 2. Stream actions tags if mutations are active
    let actionTags = '';
    if (planResult.intent === 'MUTATE' && planResult.mutations.length > 0) {
      planResult.mutations.forEach(mut => {
        if (mut.action === 'DELETE') {
          actionTags += `[ACTION: DELETE_BLOCK {"id": "${mut.id}"}] `;
        } else if (mut.action === 'UPDATE') {
          actionTags += `[ACTION: UPDATE_BLOCK ${JSON.stringify({ id: mut.id, content: mut.content })}] `;
        } else if (mut.action === 'INSERT') {
          actionTags += `[ACTION: INSERT_BLOCK ${JSON.stringify({ type: mut.type, content: mut.content, afterId: mut.afterId })}] `;
        }
      });
      if (actionTags) {
        yield actionTags + '\n';
      }
      if (planResult.mutationsSummary) {
        yield planResult.mutationsSummary + '\n\n';
      }
    }

    // 3. Build system instructions for presenter stage
    const blocksContent = state.blocks.length === 0
      ? '(The diary entry is currently empty.)'
      : JbcTranslator.serializeDiaryState(state.blocks);

    let presenterSystemPrompt = '';
    if (planResult.intent === 'MUTATE') {
      presenterSystemPrompt = `You are J.O.S.H. (Journaling, Optimization, & Semantic Heuristic), an advanced diary co-pilot.
Our planning agent staged database changes. The visual diff of mutations:
${planResult.mutationsSummary}

Discuss this refactoring plan with Joshua: "${prompt}"

Guidelines:
* Keep your explanation focused strictly on the technical or architectural reasoning.
* Do NOT list, print, repeat, or summarize the exact changes that the JbcTranslator has already formatted.
* Do NOT emit any [ACTION: ...] tags yourself; the backend handles this transparently in the headers/actions stream.
* Keep it concise and peer-to-peer.`;
    } else if (planResult.intent === 'SUGGEST_TEMPLATE') {
      presenterSystemPrompt = `You are J.O.S.H. (Journaling, Optimization, & Semantic Heuristic), an advanced personal diary co-pilot.
### CURRENT DIARY CONTEXT:
Title: ${state.entryTitle}
${blocksContent}

User Request: "${prompt}"

Your task is to:
1. Suggest a beautiful, template-rich Markdown blueprint inside a single code block starting with \`\`\`josh_template and ending with \`\`\`.
2. Expand on every section with highly detailed prompts. Do not be brief.`;
    } else {
      presenterSystemPrompt = `You are J.O.S.H. (Journaling, Optimization, & Semantic Heuristic), an advanced personal systems architect co-pilot created by Joshua.
You have access to the current diary entry.
### CURRENT DIARY CONTEXT:
Title: ${state.entryTitle}
${blocksContent}

Respond to the user's conversational query: "${prompt}".
Discourse Guidelines:
- Maintain a highly technical, helpful, peer-to-peer discourse. Skip generic greetings.
- Enforce extreme optimization and explain architectural choices, memory layouts, and algorithmic Big-O complexities where relevant. Applying the Socratic Method to drop hints and encourage thinking is highly encouraged!
- Do NOT emit any [ACTION: ...] tags. Do NOT wrap conversational answers inside josh_template.`;
    }

    const streamerUrl = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:streamGenerateContent?key=${this.apiKey}`;

    const contents = history.map(h => ({
      role: h.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: h.content }]
    }));
    contents.push({ role: 'user', parts: [{ text: `${presenterSystemPrompt}\n\nUser Message: ${prompt}` }] });

    const response = await this.rateLimiter.execute(async () => {
      logger.info('gemini_jbc_provider', `Streaming chat response via: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      return fetch(streamerUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents, generationConfig: { temperature: 0.7 } })
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

  /**
   * Summary generation (also used to populate the ai_summary block)
   */
  async generateSummary(entryContent: string, entryTitle: string): Promise<string> {
    if (!this.apiKey) throw new Error('Gemini API key is not configured.');

    const wordCount = entryContent.split(/\s+/).filter(Boolean).length;
    const containsBisaya = /kat-on|bisaya|dili|nindot|kapoy|samok|nagool|gikulbaan/i.test(entryContent);

    const prompt = `Digest this diary entry:
Title: "${entryTitle}"
Content:
"${entryContent}"

Generate a highly structured summary including length and a professional evaluation of the content.
Return the output using this exact Markdown schema:
### 🤖 J.O.S.H. (Journaling, Orchestration, & Semantic Heuristic):
*   **Length**: ${wordCount} words analyzed.
*   **Highlights**: [Write 1 key highlight of the entry content here]
*   **Localization**: ${containsBisaya ? "Detected Visayan dialect hints. Agglutinative stemming parsed successfully." : "Standard language mode."}
*   **Summary**: [Write a concise, professional 1-2 sentence summary of what the user wrote and any progress made]

Do NOT output anything else besides this exact Markdown block. No backticks, no markdown fence codes. Start directly with '### 🤖'.`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:generateContent?key=${this.apiKey}`;

    return this.rateLimiter.execute(async () => {
      logger.info('gemini_jbc_provider', `generateSummary model: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.2 }
        })
      });

      if (!response.ok) {
        throw new Error(`Gemini HTTP error status: ${response.status}`);
      }

      const data: any = await response.json();
      return data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';
    });
  }

  /**
   * Helper to rewrite positional references to real UUIDs.
   */
  private resolvePositionalRefs(prompt: string, blocks: any[]): string {
    if (blocks.length === 0) return prompt;

    let resolved = prompt;
    const indexToUuid: Record<number, string> = {};
    blocks.forEach((b, i) => {
      indexToUuid[i + 1] = b.id; // 1-indexed
    });

    const ordinals: Record<string, number> = {
      first: 1, second: 2, third: 3, fourth: 4, fifth: 5,
      sixth: 6, seventh: 7, eighth: 8, ninth: 9, tenth: 10,
    };

    // 1. Ordinal synonyms
    resolved = resolved.replace(
      /\b(?:the\s+)?(first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\s+(?:block|header|heading|paragraph|section|element|item|list|checkbox)\b/gi,
      (match, word) => {
        const idx = ordinals[word.toLowerCase()];
        return idx ? (indexToUuid[idx] ?? match) : match;
      }
    );

    // 2. Numeric synonyms
    resolved = resolved.replace(
      /\b(?:block|header|heading|paragraph|section|element|item|list|checkbox)\s+(?:number\s+|#)?(\d+)\b/gi,
      (match, n) => indexToUuid[parseInt(n, 10)] ?? match
    );

    // 3. Standalone pound reference: "#1"
    resolved = resolved.replace(
      /\b#(\d+)\b/g,
      (match, n) => indexToUuid[parseInt(n, 10)] ?? match
    );

    return resolved;
  }
}
