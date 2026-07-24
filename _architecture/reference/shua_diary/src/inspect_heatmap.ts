/**
 * inspect_heatmap.ts — Verify the heatmap data pipeline.
 * Runs _assembleDiaryList logic directly and prints the cell array.
 *
 * Run: npx ts-node src/inspect_heatmap.ts
 */
import { getDiaryRepository } from './diary/diary_repository';

const repo = getDiaryRepository();
const userId = 'default';

// Replicate the exact logic from SduiScreenAssembler._assembleDiaryList
const now = new Date();
const targetDate = new Date(now.getFullYear(), now.getMonth(), 1);
const year = targetDate.getFullYear();
const month = targetDate.getMonth();
const lastDay = new Date(year, month + 1, 0).getDate();
const startWeekday = new Date(year, month, 1).getDay();

const timeline = repo.getMoodTimeline(userId, 0);
console.log(`\n[Heatmap] getMoodTimeline returned ${timeline.length} entries:\n`);
timeline.forEach(t => console.log(`  date=${t.date}  mood=${t.moodScore}`));

const moodSums = new Map<number, number>();
const moodCounts = new Map<number, number>();
for (const item of timeline) {
  if (item.date && item.moodScore !== null) {
    const d = new Date(item.date);
    if (!isNaN(d.getTime())) {
      const dateKey = d.getDate();
      moodSums.set(dateKey, (moodSums.get(dateKey) ?? 0) + item.moodScore);
      moodCounts.set(dateKey, (moodCounts.get(dateKey) ?? 0) + 1);
    }
  }
}

const cells: Array<{ key: string | null; val: number | null; lbl: string }> = [];

// Weekday padding
for (let i = 0; i < startWeekday; i++) {
  cells.push({ key: null, val: null, lbl: '' });
}

// Calendar days
let daysWithMood = 0;
for (let day = 1; day <= lastDay; day++) {
  const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  const sum = moodSums.get(day);
  const count = moodCounts.get(day);
  const val = (sum !== undefined && count !== undefined) ? sum / count : null;
  if (val !== null) daysWithMood++;
  cells.push({ key: dateStr, val, lbl: String(day) });
}

// Trailing padding
const remainder = cells.length % 7;
if (remainder > 0) {
  for (let i = 0; i < 7 - remainder; i++) {
    cells.push({ key: null, val: null, lbl: '' });
  }
}

console.log(`\n[Heatmap] Month: ${year}-${String(month + 1).padStart(2, '0')}`);
console.log(`[Heatmap] Calendar days: ${lastDay}, start weekday: ${startWeekday}`);
console.log(`[Heatmap] Total cells (with padding): ${cells.length} (expected: ${Math.ceil((startWeekday + lastDay) / 7) * 7})`);
console.log(`[Heatmap] Days with mood data: ${daysWithMood}`);
console.log(`\n[Heatmap] Cell grid preview (days with data marked with ★):\n`);

// Print a 7-column calendar view
const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
console.log(dayNames.map(d => d.padStart(6)).join(''));
for (let i = 0; i < cells.length; i += 7) {
  const row = cells.slice(i, i + 7);
  const line = row.map(c => {
    if (!c.lbl) return '      ';
    const mood = c.val !== null ? (c.val > 0 ? '+' : '') + c.val.toFixed(2) : '  ---';
    return `${String(c.lbl).padStart(2)}${c.val !== null ? '★' : ' '}${mood}`.padStart(6);
  }).join(' ');
  console.log(line);
}

// Verify no null key collision
const nonNullKeys = cells.filter(c => c.key !== null).map(c => c.key!);
const uniqueKeys = new Set(nonNullKeys);
console.log(`\n[Heatmap] ✅ Key uniqueness: ${uniqueKeys.size}/${nonNullKeys.length} unique`);
console.log(`[Heatmap] ✅ Cells JSON length: ${JSON.stringify(cells).length} bytes`);
console.log(`[Heatmap] ✅ Double-sided (has negatives): ${cells.some(c => c.val !== null && c.val < 0)}`);
