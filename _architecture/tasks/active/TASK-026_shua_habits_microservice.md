# TASK-026 — `shua_habits` Habit Tracker Microservice (Native Data API)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Planned |
| **Phase** | Phase 5 |
| **Type** | AI-executable |
| **Language** | TypeScript (Node.js / Express + WebSocket + `better-sqlite3`) |
| **Target** | `shua_modules/shua_habits/` |
| **Blocks** | TASK-027 (Flutter Habits Screen) |
| **Prerequisites** | TASK-004 (HBP v2 Broker), TASK-007 (AppConfig), TASK-022 (Governor Media Vault), ADR-001 |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/contracts/hbp/hbp_v2_spec.md` |

---

## Architectural Directives

> [!IMPORTANT]
> **ADR-001 is LAW**: `shua_habits` is a **pure data API**. Zero UI logic, zero blueprints, zero SDUI.
>
> This is a **separate microservice** from `shua_diary` — it has its own SQLite database (`shua_habits.db`), its own HBP v2 namespace (`habit.*`), and its own port. It is registered with `shua_governor` like all other microservices.
>
> The habit tracker image in the user's reference shows a monthly grid tracker with weekly completion bars and donut progress rings. This visual complexity lives **entirely in Flutter** (TASK-027). The backend only stores habit definitions, daily check-ins, and aggregated streak data.

> [!NOTE]
> **Why a separate microservice (not inside shua_diary)?**
>
> - Habits are **structured daily records** with streak calculations, frequency rules (daily/weekly), and completion heatmaps — fundamentally different from free-form diary entries.
> - Keeping them separate avoids polluting the diary SQLite schema with habit-specific tables and the diary HBP namespace with habit-specific operations.
> - Follows the horAIzon 3.0 micro-service pattern (each concern = its own process).
> - Future: `shua_habits` can be connected to `shua_gym` for fitness habit tracking without cross-module coupling.

---

## Data Models

```typescript
// Habit definition
export interface Habit {
  id: string;           // UUID PK
  userId: string;
  name: string;         // "Drink 3L Water"
  description: string;
  category: string;     // 'health' | 'learning' | 'fitness' | 'mindfulness' | 'custom'
  frequency: HabitFrequency; // 'daily' | 'weekly' | 'custom'
  targetCount: number;  // Times per frequency period (default: 1)
  color: string;        // Hex color for the habit card/bar
  emoji: string;        // Single emoji icon
  isActive: boolean;
  order: number;        // Manual sort order (integer, reorderable)
  createdAt: string;
  updatedAt: string;
}

export type HabitFrequency = 'daily' | 'weekly' | 'custom';

// Daily completion log
export interface HabitLog {
  id: string;           // UUID PK
  habitId: string;      // FK -> habits.id ON DELETE CASCADE
  userId: string;
  loggedDate: string;   // ISO 8601 date (YYYY-MM-DD), NOT datetime
  completedCount: number; // Actual count (0 = not done, >= targetCount = done)
  notes: string;        // Optional completion note
  createdAt: string;
}

// Computed streak data (returned by habit.stats — not stored)
export interface HabitStreak {
  habitId: string;
  currentStreak: number;    // Current consecutive-day streak
  longestStreak: number;    // All-time longest streak
  completionRate30d: number; // 0.0 - 1.0 completion rate for last 30 days
  totalCompleted: number;   // All-time completed count
}

// Monthly heatmap data for Flutter chart
export interface HabitMonthlyStats {
  habitId: string;
  month: string;          // YYYY-MM
  dailyCompletions: Record<string, number>; // { "2026-08-01": 1, "2026-08-03": 0, ... }
  weeklyCompletionRate: number[]; // Array of 4-5 weekly rates [0.0-1.0] for bar chart
  monthlyCompletionRate: number; // Overall month rate 0.0-1.0
}
```

---

## SQLite Schema (`shua_habits.db`)

```sql
-- Habit definitions
CREATE TABLE IF NOT EXISTS habits (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL DEFAULT 'shua',
  name          TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  category      TEXT NOT NULL DEFAULT 'custom',
  frequency     TEXT NOT NULL DEFAULT 'daily',    -- 'daily' | 'weekly' | 'custom'
  target_count  INTEGER NOT NULL DEFAULT 1,
  color         TEXT NOT NULL DEFAULT '#6750A4',  -- Material 3 primary purple
  emoji         TEXT NOT NULL DEFAULT '✅',
  is_active     INTEGER NOT NULL DEFAULT 1,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_habits_user_active
  ON habits(user_id, is_active, sort_order);

-- Daily completion log
CREATE TABLE IF NOT EXISTS habit_logs (
  id              TEXT PRIMARY KEY,
  habit_id        TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id         TEXT NOT NULL DEFAULT 'shua',
  logged_date     TEXT NOT NULL,      -- YYYY-MM-DD
  completed_count INTEGER NOT NULL DEFAULT 0,
  notes           TEXT NOT NULL DEFAULT '',
  created_at      TEXT NOT NULL,
  UNIQUE(habit_id, logged_date)       -- One log per habit per day
);

CREATE INDEX IF NOT EXISTS idx_logs_habit_date
  ON habit_logs(habit_id, logged_date DESC);

CREATE INDEX IF NOT EXISTS idx_logs_user_date
  ON habit_logs(user_id, logged_date DESC);
```

**Time Complexity**: O(log N) per log insertion (unique index). O(D) streak computation where D = days since habit started (bounded to 365d look-back).
**Space Complexity**: O(H * D) where H = number of habits, D = number of days tracked.

---

## Target File Structure

```
shua_modules/shua_habits/
├── src/
│   ├── server.ts                      # Express + WebSocket entrypoint (habit port in config.toml)
│   ├── habits/
│   │   ├── habit_repository.ts        # SQLite ORM: habits + habit_logs CRUD
│   │   ├── habit_types.ts             # Habit, HabitLog, HabitStreak, HabitMonthlyStats DTOs
│   │   └── streak_calculator.ts       # O(D) streak computation engine
│   └── lib/
│       └── governor_logger.ts         # HBP v2 telemetry emitter -> shua_governor :7700
├── package.json
└── tsconfig.json
```

---

## WebSocket / HBP v2 RPC Operations (`habit.*` namespace)

| Operation | Direction | Payload | Response |
| :--- | :--- | :--- | :--- |
| `habit.list` | Client → Server | `{ user_id }` | `Habit[]` |
| `habit.save` | Client → Server | `Habit` (partial) | `Habit` |
| `habit.delete` | Client → Server | `{ habit_id }` | `{ ok: true }` |
| `habit.reorder` | Client → Server | `{ habit_ids: string[] }` | `{ ok: true }` |
| `habit.log` | Client → Server | `{ habit_id, logged_date, completed_count, notes? }` | `HabitLog` |
| `habit.log.get` | Client → Server | `{ habit_id, date_from, date_to }` | `HabitLog[]` |
| `habit.stats` | Client → Server | `{ habit_id }` | `HabitStreak` |
| `habit.monthly` | Client → Server | `{ user_id, month }` | `HabitMonthlyStats[]` |
| `habit.today` | Client → Server | `{ user_id }` | `{ habits: Habit[], logs: HabitLog[] }` |

> [!NOTE]
> `habit.today` is the primary "home screen" call — returns all active habits plus today's logs in a single RPC to minimize round trips. This powers the main habit tracker view on app open.

---

## Streak Calculator (`streak_calculator.ts`)

```typescript
export function computeStreak(
  logs: HabitLog[],
  habit: Habit,
  asOf: Date = new Date()
): HabitStreak {
  // Sort logs descending by date (already indexed by DB)
  // Walk back day-by-day from asOf:
  //   - If log exists with completedCount >= targetCount → streak continues
  //   - First missing day → current streak ends
  // Track longest streak with second-pass forward scan
  // Compute 30d rate: completed_days_last_30 / 30
  // O(D) time where D = look-back window (max 365 days)
  // O(1) space: constant state variables
}
```

---

## `config.toml` Addition

```toml
[shua_habits]
port = 7705
db_path = "/var/lib/horaizon/shua_habits.db"
```

---

## Acceptance Criteria

- [ ] `shua_habits` microservice starts cleanly and registers with `shua_governor`
- [ ] All 9 HBP v2 `habit.*` RPC operations respond correctly with MessagePack payloads
- [ ] `habit.log` enforces unique constraint (one log per habit per day); upserts on duplicate
- [ ] `habit.stats` computes current streak correctly for 30-day dataset on Pi 5 in < 5ms
- [ ] `habit.today` returns all active habits + today's logs in a single RPC call
- [ ] `habit.monthly` returns daily completion map and weekly bar chart data for a given month
- [ ] Structured telemetry logs emitted to governor on all state changes
- [ ] `0` TypeScript compiler errors, `0` ESLint warnings (`tsc --noEmit && eslint src/`)
