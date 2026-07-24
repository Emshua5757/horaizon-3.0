// Mode 1: Generate full diary structure from raw user notes (paste-to-diary)
export interface DiaryBlueprint {
  title: string;
  suggestedTitles: string[];     // 3 alternatives from LLM
  blocks: Array<{ blockType: string; content: string }>;
  metadata: { mood: string; category: string; priority: number };
}

export interface IDiaryGeneratorProvider {
  generateFromNotes(
    rawNotes: string,
    style: string,                // 'reflective' | 'productivity' | 'milestone' | etc.
  ): Promise<DiaryBlueprint>;
  generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>;
}
