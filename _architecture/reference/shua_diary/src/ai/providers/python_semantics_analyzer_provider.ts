import { spawn } from 'child_process';
import { IAnalyzerProvider, AnalysisResult } from '../interfaces/i_analyzer';

export class PythonSemanticsAnalyzerProvider implements IAnalyzerProvider {
  /**
   * @param pythonScriptPath Path to analyze_sentiment.py
   */
  constructor(private pythonScriptPath: string) {}

  async analyze(content: string): Promise<AnalysisResult> {
    return new Promise((resolve, reject) => {
      const pythonProcess = spawn('python', [this.pythonScriptPath]);

      let stdoutData = '';
      let stderrData = '';

      // Write block text content directly to standard input to avoid shell arg limits
      pythonProcess.stdin.write(content);
      pythonProcess.stdin.end();

      pythonProcess.stdout.on('data', (data) => {
        stdoutData += data.toString();
      });

      pythonProcess.stderr.on('data', (data) => {
        stderrData += data.toString();
      });

      pythonProcess.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`Python process exited with code ${code}. Stderr: ${stderrData}`));
          return;
        }

        try {
          const result = JSON.parse(stdoutData.trim());
          
          // Map sentiment score from [0.0, 1.0] -> [-1.0, 1.0]
          const rawScore = Number(result.sentiment_score ?? 0.5);
          const sentimentScore = Math.max(-1.0, Math.min(1.0, (rawScore - 0.5) * 2));

          resolve({
            sentimentScore,
            isMilestone: false,
            milestoneTag: 'neutral', // Forced to neutral per architectural spec
            privacyTag: (result.privacy_tag === 'nsfw' ? 'nsfw' : 'sfw') as 'nsfw' | 'sfw',
            summary: '' // No LLM = no summary
          });
        } catch (parseError) {
          reject(new Error(`Failed to parse Python JSON output: "${stdoutData}". Error: ${parseError}`));
        }
      });
    });
  }
}
