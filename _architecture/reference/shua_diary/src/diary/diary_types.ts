/**
 * TypeScript interfaces for shua_diary database rows.
 * These are pure data shapes — zero business logic.
 * Maps directly to SQLite table columns.
 */

// ── diary_entries table ────────────────────────────────────────────

export interface DiaryEntry {
  id: string;           // UUID primary key
  userId: string;       // owner's user ID
  title: string;        // display title
  isPrivate: boolean;   // lock overlay if true
  aiProvider: string;   // "gemini" | "ollama" | "hybrid" | "n8n"
  lexoRank: string;     // LexoRank ordering string (e.g. "0|hzzzzz")
  createdAt: string;    // ISO 8601 timestamp
  updatedAt: string;    // ISO 8601 timestamp
  preview: string;      // first ~120 chars of body text, for the list card
  moodScore: number | null;
  energyScore: number | null;
  isGloballyElevated: boolean;
  loggedAt: string;
}


// ── diary_blocks table ─────────────────────────────────────────────

/**
 * BlockType — internal type identifiers stored in SQLite.
 * These map to SDUI type_ids via BLOCK_TYPE_MAP in sdui_screen_assembler.ts.
 * Never stored as integers — strings are human-readable in DB dumps.
 */
export type BlockType = string;

export interface DiaryBlock {
  id: string;           // UUID primary key
  entryId: string;      // FK → diary_entries.id
  blockType: BlockType; // content type — drives SDUI primitive selection
  content: string;      // raw text content (Markdown, checklist lines, code, etc.)
  lexoRank: string;     // LexoRank string — sort order within the entry
  sortOrder: number;    // integer fallback sort if lexoRank collides (rare)
  codeLanguage: string | null; // only set when blockType === 'code'
  createdAt: string;
  updatedAt: string;
}

// ── Hydration context shapes ───────────────────────────────────────

/** Context passed to SduiNodeBuilder.buildScreen() for diary_list */
export interface DiaryListContext {
  screen_id: string;    // "diary_list"
  diary_entries: Array<{
    id: string;
    title: string;
    preview: string;
    is_private: boolean;
    created_at: string;
    mood_score: number | null;
    energy_score: number | null;
    is_globally_elevated: boolean;
    logged_at: string;
  }>;
  username: string;
}


/** Context passed to SduiNodeBuilder.buildScreen() for diary_editor_{id} */
export interface DiaryEditorContext {
  entry_id: string;
  title: string;
  ai_provider: string;
  blocks: Array<{
    block_id: string;
    block_type: BlockType;
    content: string;
    code_language: string | null;
    lexo_rank: string;
  }>;
}
