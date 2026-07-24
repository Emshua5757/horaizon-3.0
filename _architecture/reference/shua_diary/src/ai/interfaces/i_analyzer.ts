// Mode 3: Background sentiment + milestone + privacy analysis
export interface AnalysisResult {
  sentimentScore: number;       // -1.0 to 1.0 (V4 normalized, was 0.0-1.0 in V3)
  isMilestone: boolean;
  milestoneTag: 'achievement' | 'neutral' | 'stress_alert';
  privacyTag: 'sfw' | 'nsfw';
  summary: string;              // NEW in V4 — 1-2 sentence AI summary for diary card preview
}

export interface IAnalyzerProvider {
  analyze(text: string): Promise<AnalysisResult>;
}
