import { JbcMutation } from '../jbc/jbc_translator';

// Mode 2: Two-stage JBC planner + conversational presenter
export interface DiaryStateSnapshot {
  entryId: string;
  entryTitle: string;
  blocks: Array<{ id: string; blockType: string; content: string }>;
}

export type JbcIntent = 'MUTATE' | 'SUGGEST_TEMPLATE' | 'CONVERSE' | 'NO_OP';

export interface JbcPlanResult {
  intent: JbcIntent;
  rawBytecode: string;
  mutations: JbcMutation[];
  mutationsSummary: string;  // human-readable diff from JbcTranslator.translate()
}

export interface IJbcChatProvider {
  // Stage 1: deterministic JBC bytecode planner (temperature 0.0)
  compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>;
  
  // Stage 2: streaming conversational presenter (temperature 0.7)
  presentJbcStream(
    prompt: string,
    planResult: JbcPlanResult,
    history: Array<{ role: 'user' | 'assistant'; content: string }>,
    state: DiaryStateSnapshot,
  ): AsyncIterable<string>;
  
  // Summary generation (also used to populate the ai_summary block)
  generateSummary(entryContent: string, entryTitle: string): Promise<string>;
}
