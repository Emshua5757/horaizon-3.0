import { IJbcChatProvider, DiaryStateSnapshot, JbcPlanResult, JbcIntent } from '../interfaces/i_jbc_chat';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class N8nJbcProvider implements IJbcChatProvider {
  constructor(private n8nUrl: string) {}

  private checkConfig() {
    if (!this.n8nUrl || this.n8nUrl === 'http://127.0.0.1:5678' || this.n8nUrl.trim() === '') {
      throw new Error('n8n is not configured.');
    }
  }

  async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult> {
    this.checkConfig();
    try {
      const response = await fetch(`${this.n8nUrl}/webhook/diary/planner/refactor`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, diaryTitle: state.entryTitle, diaryBlocks: state.blocks })
      });

      if (!response.ok) {
        throw new Error(`[N8N PLANNER] Webhook returned HTTP ${response.status}`);
      }

      const data: any = await response.json();
      const payload = Array.isArray(data) ? data[0] : data;

      return {
        intent: (payload.intent || 'CONVERSE') as JbcIntent,
        rawBytecode: payload.rawBytecode || 'NO_OP',
        mutations: Array.isArray(payload.mutations) ? payload.mutations : [],
        mutationsSummary: payload.summary || ''
      };
    } catch (e: any) {
      logger.error('n8n_jbc_provider', `N8N planner error: ${e}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      return {
        intent: 'CONVERSE',
        rawBytecode: 'NO_OP',
        mutations: [],
        mutationsSummary: ''
      };
    }
  }

  async *presentJbcStream(
    prompt: string,
    planResult: JbcPlanResult,
    history: Array<{ role: 'user' | 'assistant'; content: string }>,
    state: DiaryStateSnapshot
  ): AsyncIterable<string> {
    this.checkConfig();
    const response = await fetch(`${this.n8nUrl}/webhook/diary/chat/stream`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt,
        planResult,
        history,
        diaryTitle: state.entryTitle,
        diaryBlocks: state.blocks
      })
    });

    if (!response.ok || !response.body) {
      throw new Error(`[N8N CHAT STREAM] Webhook returned HTTP ${response.status}`);
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
            const content = parsed.response || parsed.message?.content || parsed.content;
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

  async generateSummary(entryContent: string, entryTitle: string): Promise<string> {
    this.checkConfig();
    const response = await fetch(`${this.n8nUrl}/webhook/diary/summary`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: entryContent, title: entryTitle })
    });

    if (!response.ok) {
      throw new Error(`[N8N SUMMARY] Webhook returned HTTP ${response.status}`);
    }

    const data: any = await response.json();
    const payload = Array.isArray(data) ? data[0] : data;
    return payload.summary || '';
  }
}
