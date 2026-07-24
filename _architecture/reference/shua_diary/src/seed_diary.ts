/**
 * seed_diary.ts — Development data seeder for shua_diary.
 *
 * Creates a month of realistic diary entries across June 2026, with:
 *   - Varied mood_score (-1.0 → 1.0) spread across different calendar days
 *     so the heatmap renders real color gradients.
 *   - Every block type populated with correctly structured JSON / content formatting.
 *   - A mix of public and private entries.
 *
 * Run with:  npx ts-node src/seed_diary.ts
 */

import path from 'path';
import Database from 'better-sqlite3';
import crypto from 'crypto';

const DB_PATH = path.join(__dirname, '..', 'data', 'shua_diary.db');
const USER_ID = 'default';
const SEED_PREFIX = '[SEED]';

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ── Helpers ───────────────────────────────────────────────────────────────────

function uuid(): string {
  return crypto.randomUUID();
}

/** Simple base-26 LexoRank generator for seeder use. */
function makeRank(n: number): string {
  const prefix = '0|hzzzzz:';
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  let result = '';
  let num = n + 13; // offset past midpoint
  do {
    result = chars[num % 26] + result;
    num = Math.floor(num / 26) - 1;
  } while (num >= 0);
  return prefix + result;
}

/** Inserts a diary entry row directly. */
function insertEntry(params: {
  id: string;
  title: string;
  preview: string;
  moodScore: number | null;
  energyScore: number | null;
  isPrivate: number;
  loggedAt: string;
  lexoRank: string;
}): void {
  db.prepare(`
    INSERT OR IGNORE INTO diary_entries
      (id, user_id, title, is_private, ai_provider, lexo_rank, preview, mood_score, energy_score, is_globally_elevated, logged_at)
    VALUES (?, ?, ?, ?, 'gemini', ?, ?, ?, ?, 0, ?)
  `).run(
    params.id,
    USER_ID,
    params.title,
    params.isPrivate,
    params.lexoRank,
    params.preview,
    params.moodScore,
    params.energyScore,
    params.loggedAt,
  );
}

/** Inserts a block row with a given lexo_rank suffix index. */
function insertBlock(entryId: string, blockType: string, content: string, rankIdx: number, codeLanguage?: string): void {
  const id = uuid();
  const rank = makeRank(rankIdx);
  db.prepare(`
    INSERT OR IGNORE INTO diary_blocks
      (id, entry_id, block_type, content, lexo_rank, sort_order, code_language)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(id, entryId, blockType, content, rank, rankIdx, codeLanguage ?? null);
}

// ── WIPE ALL PREVIOUS DATA ───────────────────────────────────────────────────

console.log('[Seeder] Erasing all existing diary entries and blocks...');
db.prepare('DELETE FROM diary_blocks').run();
db.prepare('DELETE FROM diary_entries').run();
db.prepare('DELETE FROM diary_entries_fts').run();

// ── Entry definitions ─────────────────────────────────────────────────────────
// June 2026. mood_score range: -1.0 (very negative) to 1.0 (very positive).

type EntryDef = {
  title: string;
  day: number;      // day of June 2026
  mood: number | null;
  energy: number | null;
  isPrivate: number;
  preview: string;
  blocks: Array<{ type: string; content: string; lang?: string }>;
};

const entries: EntryDef[] = [
  // ── Day 1 — Great start to the month ──────────────────────────────────────
  {
    title: `${SEED_PREFIX} June Kickoff 🚀`,
    day: 1,
    mood: 0.85,
    energy: 0.9,
    isPrivate: 0,
    preview: 'Started the month strong. Shipped the SDUI-4 block registry and tested all 31 primitives.',
    blocks: [
      { type: 'heading_1', content: 'June Kickoff' },
      { type: 'body', content: 'Started the month strong. Shipped the SDUI-4 block registry and tested all 31 primitives. The architecture feels solid — every screen is now purely JSON-driven from Node.js.' },
      { type: 'checklist', content: '- [x] Ship block registry\n- [x] Test 31 primitives\n- [x] Push to GitHub\n- [ ] Write integration tests' },
      { type: 'mood_rating', content: '4.5' },
      { type: 'energy_slider', content: '9' },
      { type: 'tag_cloud', content: '# sdui4\n# flutter\n# architecture\n# milestone' },
    ],
  },

  // ── Day 3 — Deep work day ────────────────────────────────────────────────
  {
    title: `${SEED_PREFIX} Deep Work — Transport Layer`,
    day: 3,
    mood: 0.6,
    energy: 0.7,
    isPrivate: 0,
    preview: 'Spent 6 hours on the MessagePack transport layer. Binary framing is tight.',
    blocks: [
      { type: 'heading_1', content: 'Deep Work — Transport Layer' },
      { type: 'heading_2', content: 'What I built today' },
      { type: 'body', content: 'Spent 6 hours on the MessagePack transport layer. Binary framing is tight — 3x smaller payloads than JSON.' },
      { type: 'code', content: 'const payload = encode(nodes);\nsocket.emit("screen_data", payload);\n// avg 1041 bytes for diary_editor vs ~3.2KB JSON', lang: 'typescript' },
      { type: 'quote', content: 'Premature optimization is the root of all evil — but so is ignoring your Pi 5 RAM ceiling.' },
      { type: 'progress_tracker', content: '72' },
      { type: 'timeline_entry', content: '[{"title":"Started transport redesign","desc":"Drafting MsgPack buffer structure","date":"09:00"},{"title":"MsgPack integration working","desc":"Socket.io connection encoding works","date":"12:30"},{"title":"Delta patch tested","desc":"Verified with local state updates","date":"16:00"}]' },
    ],
  },

  // ── Day 5 — Low energy, frustrated ────────────────────────────────────────
  {
    title: `${SEED_PREFIX} Debugging Hell`,
    day: 5,
    mood: -0.4,
    energy: 0.3,
    isPrivate: 0,
    preview: 'Spent 4 hours on a subtle Riverpod rebuild storm. Fixed it but exhausted.',
    blocks: [
      { type: 'heading_1', content: 'Debugging Hell' },
      { type: 'body', content: 'Spent 4 hours on a subtle Riverpod rebuild storm. The StateVault scoping was wrong — `.select()` was missing on every node consumer, causing the entire tree to rebuild on any single vault write. Fixed it but exhausted.' },
      { type: 'checklist', content: '- [x] Identify rebuild root cause\n- [x] Add .select() to all vault reads\n- [ ] Write regression test\n- [ ] Document the pattern in arch docs' },
      { type: 'mood_rating', content: '2.0' },
      { type: 'energy_slider', content: '3' },
      { type: 'bullet_list', content: '- StateVault needs scoped selectors\n- Never use raw watch() on vault without .select()\n- Add this to the SDUI-4 primitives spec' },
    ],
  },

  // ── Day 7 — Recovery + planning ───────────────────────────────────────────
  {
    title: `${SEED_PREFIX} Weekly Review`,
    day: 7,
    mood: 0.3,
    energy: 0.55,
    isPrivate: 0,
    preview: 'Weekly review. Heatmap is coming together. Need to verify the mood timeline pipeline.',
    blocks: [
      { type: 'heading_1', content: 'Weekly Review — Week 1' },
      { type: 'data_table', content: '[["Metric","Target","Actual"],["Entries written","5","4"],["Blocks created","20","31"],["Bugs fixed","3","5"],["Lines of code","400","712"]]' },
      { type: 'body', content: 'Slower than expected but quality is high. The diary module is nearly feature-complete. Below is the productivity graph showing commits per day.' },
      { type: 'chart_block', content: '[{"x":"Mon","y":5},{"x":"Tue","y":8},{"x":"Wed","y":3},{"x":"Thu","y":6},{"x":"Fri","y":12}]' },
      { type: 'progress_tracker', content: '65' },
      { type: 'mood_rating', content: '3.5' },
      { type: 'tag_cloud', content: '# review\n# planning\n# diary\n# sdui4' },
    ],
  },

  // ── Day 10 — Very positive, milestone ──────────────────────────────────────
  {
    title: `${SEED_PREFIX} First Live SDUI Screen 🎉`,
    day: 10,
    mood: 0.95,
    energy: 0.95,
    isPrivate: 0,
    preview: 'The diary list screen is fully live on-device. Real data from SQLite, rendered entirely by SDUI-4.',
    blocks: [
      { type: 'heading_1', content: 'First Live SDUI-4 Screen!' },
      { type: 'body', content: 'The diary list screen is fully live on-device. Real data from SQLite, rendered entirely by SDUI-4 nodes. No Flutter code knows what a "diary entry" is — it just renders nodes. This is the architecture we designed.' },
      { type: 'mood_rating', content: '5.0' },
      { type: 'energy_slider', content: '10' },
      { type: 'heading_2', content: 'What worked' },
      { type: 'bullet_list', content: '- Zero Flutter screen code for diary\n- MessagePack payload under 2KB\n- Heatmap renders from real mood scores' },
      { type: 'checkbox_single', content: '{"label":"Heatmap data pipeline verification completed","checked":true}' },
      { type: 'tag_cloud', content: '# milestone\n# sdui4\n# flutter\n# live' },
    ],
  },

  // ── Day 12 — Map + location ───────────────────────────────────────────────
  {
    title: `${SEED_PREFIX} Visit to the Park`,
    day: 12,
    mood: 0.7,
    energy: 0.8,
    isPrivate: 0,
    preview: 'Took a break from coding. Walked to the park, cleared my head.',
    blocks: [
      { type: 'heading_1', content: 'Visit to the Park' },
      { type: 'body', content: 'Took a break from coding. Walked to the park, cleared my head. The project was starting to feel overwhelming so I needed some air.' },
      { type: 'map_pin', content: '{"lat":14.5995,"lng":120.9842,"label":"Luneta Park, Manila"}' },
      { type: 'mood_rating', content: '4.0' },
      { type: 'energy_slider', content: '8' },
      { type: 'caption', content: 'Rule: one outdoor break per 3 days of deep work sessions.' },
    ],
  },

  // ── Day 14 — Private entry, negative mood ─────────────────────────────────
  {
    title: `${SEED_PREFIX} Frustrations (Private)`,
    day: 14,
    mood: -0.7,
    energy: 0.2,
    isPrivate: 1,
    preview: 'Private: rough day. Deployment failed twice. Team sync was unproductive.',
    blocks: [
      { type: 'heading_1', content: 'Rough Day' },
      { type: 'body', content: 'Deployment failed twice. The build pipeline had a silent env var regression. Spent 3 hours debugging something that should have taken 20 minutes. I need better CI checks.' },
      { type: 'mood_rating', content: '1.5' },
      { type: 'energy_slider', content: '2' },
      { type: 'checklist', content: '- [ ] Fix CI env var validation\n- [ ] Add pre-deploy health check\n- [ ] Write post-mortem' },
    ],
  },

  // ── Day 16 — Code-heavy entry ─────────────────────────────────────────────
  {
    title: `${SEED_PREFIX} LexoRank Deep Dive`,
    day: 16,
    mood: 0.5,
    energy: 0.65,
    isPrivate: 0,
    preview: 'Deep dive into LexoRank algorithm for block ordering. Base-26 midpoint is elegant.',
    blocks: [
      { type: 'heading_1', content: 'LexoRank Deep Dive' },
      { type: 'body', content: 'The key insight: never store absolute integer positions. Store lexicographic rank strings that can always be bisected without renumbering siblings.' },
      { type: 'heading_2', content: 'The midpoint algorithm' },
      { type: 'code', content: 'function midRankSuffix(lo: string, hi: string | undefined): string {\n  const CHARS = "abcdefghijklmnopqrstuvwxyz";\n  const len = Math.max(lo.length, hi?.length ?? 0);\n  for (let i = 0; i < len + 1; i++) {\n    const loChar = i < lo.length ? CHARS.indexOf(lo[i]) : -1;\n    const hiChar = i < (hi?.length ?? 0) ? CHARS.indexOf(hi![i]) : CHARS.length;\n    const gap = hiChar - loChar - 1;\n    if (gap > 0) {\n      return lo.slice(0, i) + CHARS[loChar + 1 + Math.floor(gap / 2)];\n    }\n  }\n  return lo + "n"; // append midpoint char\n}', lang: 'typescript' },
      { type: 'quote', content: 'This algorithm never degenerates — every insertion finds a valid midpoint in O(k) where k = rank string length.' },
      { type: 'data_table', content: '[["Operation","Rank"],["Insert at top","0|hzzzzz:g"],["Insert at bottom","0|hzzzzz:o"],["Insert in middle","0|hzzzzz:k"]]' },
    ],
  },

  // ── Day 18 — Multimedia / audio day ──────────────────────────────────────
  {
    title: `${SEED_PREFIX} Voice Notes Session`,
    day: 18,
    mood: 0.4,
    energy: 0.6,
    isPrivate: 0,
    preview: 'Tried using voice notes for architectural brainstorming instead of typing.',
    blocks: [
      { type: 'heading_1', content: 'Voice Notes Experiment' },
      { type: 'body', content: 'Tried using voice memos for architectural brainstorming instead of typing notes. Spoke about the Governor module design for 20 minutes. Need to transcribe.' },
      { type: 'audio_note', content: '{"url":"","duration":1200,"label":"Governor architecture brainstorm"}' },
      { type: 'heading_2', content: 'Key ideas from the session' },
      { type: 'bullet_list', content: '- Rust Governor owns process control via cgroups\n- All SDUI served through Axum reverse proxy\n- Flutter connects only to port 3000\n- Module URLs: /api/diary/* → Node.js 3001' },
      { type: 'toggle_section', content: '{"title":"Deferred items","body":"- JBC integration panel\\n- Multi-user sync\\n- Semantic search UI","icon":"expand_more","radius":8,"expanded":false}' },
      { type: 'date_log', content: '2026-06-18' },
      { type: 'time_log', content: '14:30' },
    ],
  },

  // ── Day 20 — Slightly negative, mid-sprint fatigue ────────────────────────
  {
    title: `${SEED_PREFIX} Mid-Sprint Fatigue`,
    day: 20,
    mood: -0.2,
    energy: 0.4,
    isPrivate: 0,
    preview: 'Hitting mid-sprint fatigue. Output is slower. Need to pace better.',
    blocks: [
      { type: 'heading_1', content: 'Mid-Sprint Reality Check' },
      { type: 'body', content: 'Hitting the mid-sprint wall. Output quality is still high but pace has dropped. I need to be better about pacing. The diary module took longer than planned.' },
      { type: 'energy_slider', content: '4' },
      { type: 'mood_rating', content: '3.0' },
      { type: 'poll_choice', content: '{"label":"Need rest","checked":true,"group":"fatigue_poll"}' },
      { type: 'poll_choice', content: '{"label":"Need coffee","checked":false,"group":"fatigue_poll"}' },
      { type: 'poll_choice', content: '{"label":"Need to ship small","checked":false,"group":"fatigue_poll"}' },
      { type: 'dropdown_select', content: '{"label":"Pacing Action","options":["Need rest","Need coffee","Ship small"],"value":"Need rest"}' },
      { type: 'checkbox_single', content: '{"label":"Acknowledge burnout symptoms","checked":false}' },
    ],
  },

  // ── Day 22 — Recovery, refocus ────────────────────────────────────────────
  {
    title: `${SEED_PREFIX} Refocus Session`,
    day: 22,
    mood: 0.45,
    energy: 0.7,
    isPrivate: 0,
    preview: 'Took half a day off, came back refreshed. Prioritized the heatmap pipeline.',
    blocks: [
      { type: 'heading_1', content: 'Refocus After Rest' },
      { type: 'body', content: 'Took half a day off, came back fresh. Prioritized clearly: heatmap pipeline first, then Phase 9 screen migrations.' },
      { type: 'heading_2', content: 'Priority matrix' },
      { type: 'data_table', content: '[["Task","Priority","Effort"],["Heatmap verify","High","Low"],["Settings screen","High","Medium"],["Chat screen","Medium","Medium"],["Rust Governor","Critical","High"]]' },
      { type: 'progress_tracker', content: '78' },
      { type: 'numbered_list', content: '1. Heatmap data verification\n2. Settings page migration\n3. Chat screen migration\n4. Rust Governor rewrite' },
      { type: 'tag_cloud', content: '# planning\n# phase9\n# refocus' },
    ],
  },

  // ── Day 23 — Strong day, reorder block shipped ────────────────────────────
  {
    title: `${SEED_PREFIX} Reorder Block Shipped ✅`,
    day: 23,
    mood: 0.8,
    energy: 0.85,
    isPrivate: 0,
    preview: 'Shipped drag-and-drop block reordering. LexoRank stays server-side, Flutter sends neighbor IDs only.',
    blocks: [
      { type: 'heading_1', content: 'Reorder Block — Shipped!' },
      { type: 'body', content: 'The reorder_block feature is live. The key architectural decision: Flutter never computes LexoRank — it only sends neighbor block IDs. The server owns all ordering logic. This keeps the Flutter client truly dumb and the module boundary clean.' },
      { type: 'heading_2', content: 'Protocol' },
      { type: 'code', content: '// Flutter sends:\n{ block_id: "uuid", before_block_id: "uuid|null", after_block_id: "uuid|null" }\n\n// Server computes:\nreorderBlockByNeighbors(entryId, blockId, beforeId, afterId)\n// → _lexoRankAfter() or _midRankSuffix() depending on position', lang: 'typescript' },
      { type: 'mood_rating', content: '4.5' },
      { type: 'energy_slider', content: '8' },
      { type: 'heading_2', content: 'Server logs confirm' },
      { type: 'html_embed', content: '<pre style="font-family:monospace;font-size:12px">[DiaryRepository] Reordered block → rank: 0|hzzzzz:g\n[DiaryRepository] Reordered block → rank: 0|hzzzzz:o</pre>' },
      { type: 'checkbox_single', content: '{"label":"Reorder block shipped successfully","checked":true}' },
      { type: 'tag_cloud', content: '# reorder\n# lexorank\n# shipped\n# sdui4' },
    ],
  },
];

// ── Insert all entries ────────────────────────────────────────────────────────

console.log(`[Seeder] Inserting ${entries.length} diary entries for user '${USER_ID}'...`);

entries.forEach((entry, entryIdx) => {
  const entryId = uuid();
  const day = String(entry.day).padStart(2, '0');
  const loggedAt = `2026-06-${day}T10:${String(entryIdx * 3 % 60).padStart(2, '0')}:00Z`;

  insertEntry({
    id: entryId,
    title: entry.title,
    preview: entry.preview,
    moodScore: entry.mood,
    energyScore: entry.energy,
    isPrivate: entry.isPrivate,
    loggedAt,
    lexoRank: makeRank(entryIdx),
  });

  entry.blocks.forEach((block, blockIdx) => {
    insertBlock(entryId, block.type, block.content, blockIdx, block.lang);
  });

  console.log(`  [${entryIdx + 1}/${entries.length}] "${entry.title}" (day ${entry.day}, mood=${entry.mood}) — ${entry.blocks.length} blocks`);
});

// ── FTS sync ─────────────────────────────────────────────────────────────────
try {
  db.exec(`
    INSERT OR REPLACE INTO diary_entries_fts(id, title, preview)
    SELECT id, title, preview FROM diary_entries WHERE title LIKE '${SEED_PREFIX}%';
  `);
  console.log('[Seeder] FTS index refreshed.');
} catch (e) {
  console.warn('[Seeder] FTS sync failed (non-fatal):', e);
}

db.close();
console.log(`\n✅ Done. ${entries.length} entries seeded across June 2026.`);
