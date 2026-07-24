import { IAnalyzerProvider, AnalysisResult } from '../interfaces/i_analyzer';
import { AiRateLimiter } from '../rate_limiter';
import { logger, HBP_LOG_TAG } from '../../lib/governor_logger';

export class GeminiAnalyzerProvider implements IAnalyzerProvider {
  constructor(
    private apiKey: string,
    private modelName: string,
    private rateLimiter: AiRateLimiter
  ) {}

  async analyze(content: string): Promise<AnalysisResult> {
    if (!this.apiKey) {
      logger.warn('gemini_analyzer_provider', 'API key is missing.', { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      throw new Error('Gemini API key is not configured.');
    }

    const wordCount = content.split(/\s+/).filter(Boolean).length;
    logger.info('gemini_analyzer_provider', `Preparing unified single-query analysis for ${wordCount} words...`, { tags: HBP_LOG_TAG.AI, telemetry: { wordCount } });

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

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:generateContent?key=${this.apiKey}`;

    const requestBody = {
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }]
        }
      ],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: 'application/json'
      }
    };

    return this.rateLimiter.execute(async () => {
      logger.info('gemini_analyzer_provider', `Sending API request to model: ${this.modelName}`, { tags: HBP_LOG_TAG.AI | HBP_LOG_TAG.NETWORK });
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 20000); // 20s fail-safe timeout

      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(requestBody),
          signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          throw new Error(`Gemini HTTP error status: ${response.status}`);
        }

        const data: any = await response.json();
        const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';

        // Strip backticks or markdown JSON wraps if model accidentally returned them
        const cleanJson = replyText.replace(/```json/gi, '').replace(/```/g, '').trim();
        const parsed = JSON.parse(cleanJson);

        const analysisResult: AnalysisResult = {
          sentimentScore: Number(parsed.sentimentScore ?? 0.0),
          isMilestone: Boolean(parsed.isMilestone ?? false),
          milestoneTag: (parsed.milestoneTag ?? 'neutral') as 'achievement' | 'neutral' | 'stress_alert',
          privacyTag: (parsed.privacyTag === 'nsfw' ? 'nsfw' : 'sfw') as 'nsfw' | 'sfw',
          summary: String(parsed.summary ?? '')
        };

        // Clamp the sentimentScore between -1.0 and 1.0 just to be safe
        analysisResult.sentimentScore = Math.max(-1.0, Math.min(1.0, analysisResult.sentimentScore));

        logger.info('gemini_analyzer_provider', 'Analysis succeeded.', {
          tags: HBP_LOG_TAG.AI,
          telemetry: { sentiment: analysisResult.sentimentScore, milestone: analysisResult.isMilestone },
        });
        return analysisResult;
      } catch (err) {
        clearTimeout(timeoutId);
        throw err;
      }
    });
  }
}
