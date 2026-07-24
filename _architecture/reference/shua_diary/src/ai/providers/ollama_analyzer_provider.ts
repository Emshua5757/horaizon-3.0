import { IAnalyzerProvider, AnalysisResult } from '../interfaces/i_analyzer';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class OllamaAnalyzerProvider implements IAnalyzerProvider {
  constructor(
    private ollamaUrl: string,
    private modelName: string,
    private fallbackProvider?: IAnalyzerProvider
  ) {}

  async analyze(content: string): Promise<AnalysisResult> {
    const wordCount = content.split(/\s+/).filter(Boolean).length;
    logger.info('ollama_analyzer_provider', `Sending single-query analysis to Ollama (${wordCount} words)...`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK, telemetry: { wordCount } });

    const prompt = `Analyze this personal journal entry:
"${content}"

Evaluate:
1. Overall Sentiment Score: a decimal number between -1.0 (highly negative) and 1.0 (highly positive). Enforce a calibrated Negativity Bias: damp neutral scores, but heavily amplify negative signals. If there is severe anxiety, sadness, rage, active loss, or critical burnout in ANY part of the text, pull the overall sentiment score heavily towards -1.0 to -0.4.
2. Milestone Check (isMilestone): is there any major completed breakthrough, career-defining achievement, or life-changing milestone described? (true/false)
3. Milestone Tag: "achievement" only if isMilestone is true; "neutral" if false; or "stress_alert" only if the entry expresses extreme anxiety, rage, critical burnout, or severe mental stress.
4. Content Sensitivity (privacyTag): does this entry contain highly personal, private, intimate, sensitive, or vulgar content? Output "nsfw" if ANY part of the text meets these conditions (even a single sentence, word, or topic is enough to taint the tag, i.e. sticky-OR logic); otherwise output "sfw".
5. Dynamic Summary: generate a clean 1-2 sentence professional, objective summary of the entry context to serve as a card preview.

You MUST respond ONLY with a raw, valid JSON block matching the schema contract. Do NOT include markdown code blocks, backticks, quotes, or preamble.
Schema Contract:
{ 
  "sentimentScore": number, 
  "isMilestone": boolean, 
  "milestoneTag": "achievement" | "neutral" | "stress_alert", 
  "privacyTag": "sfw" | "nsfw",
  "summary": "string"
}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 35000); // 35s timeout for local model

    try {
      // Determine if endpoint is /api/chat or /api/generate
      const isChatEndpoint = this.ollamaUrl.endsWith('/chat');
      const body = isChatEndpoint
        ? {
            model: this.modelName,
            messages: [{ role: 'user', content: prompt }],
            stream: false,
            options: { temperature: 0.0 }
          }
        : {
            model: this.modelName,
            prompt: prompt,
            stream: false,
            options: { temperature: 0.0 }
          };

      const response = await fetch(this.ollamaUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`Ollama HTTP error status: ${response.status}`);
      }

      const data: any = await response.json();
      const replyText = (data.response || data.message?.content || '').trim();

      // Strip markdown code fences if model accidentally injected them
      const cleanJson = replyText.replace(/```json/gi, '').replace(/```/g, '').trim();
      const parsed = JSON.parse(cleanJson);

      const analysisResult: AnalysisResult = {
        sentimentScore: Number(parsed.sentimentScore ?? 0.0),
        isMilestone: Boolean(parsed.isMilestone ?? false),
        milestoneTag: (parsed.milestoneTag ?? 'neutral') as 'achievement' | 'neutral' | 'stress_alert',
        privacyTag: (parsed.privacyTag === 'nsfw' ? 'nsfw' : 'sfw') as 'nsfw' | 'sfw',
        summary: String(parsed.summary ?? '')
      };

      // Clamp sentimentScore to safe limits
      analysisResult.sentimentScore = Math.max(-1.0, Math.min(1.0, analysisResult.sentimentScore));

      logger.info('ollama_analyzer_provider', 'Analysis succeeded.', {
        tags: HBP_LOG_TAG.AI,
        telemetry: { sentiment: analysisResult.sentimentScore, milestone: analysisResult.isMilestone },
      });
      return analysisResult;
    } catch (err) {
      clearTimeout(timeoutId);
      logger.warn('ollama_analyzer_provider', `Execution failed: ${err}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      
      if (this.fallbackProvider) {
        logger.info('ollama_analyzer_provider', 'Invoking semantic fallback provider...', { tags: HBP_LOG_TAG.AI });
        return this.fallbackProvider.analyze(content);
      }
      
      throw err;
    }
  }
}
