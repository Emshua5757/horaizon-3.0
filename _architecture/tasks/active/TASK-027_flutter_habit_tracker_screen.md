# TASK-027 — `client_flutter` Habit Tracker Screen & Monthly Analytics

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Planned |
| **Phase** | Phase 5 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/habits/` |
| **Blocks** | Nothing |
| **Prerequisites** | TASK-010 (GoRouter + Material 3 theme), TASK-026 (`shua_habits` Microservice), ADR-001 |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/contracts/hbp/hbp_v2_spec.md` |

---

## Architectural Directives

> [!IMPORTANT]
> **ADR-001 is LAW**: All UI is 100% native Flutter Dart widgets.
>
> The reference habit tracker image (Excel-style grid with bar charts, donut progress rings, and weekly completion stats) is the **visual design target**. This complexity is implemented entirely in Flutter using:
> - `CustomPainter` for the bar charts and donut rings
> - `GridView` for the monthly habit grid
> - Riverpod `AsyncNotifier` for all state
> - HBP v2 `habit.*` RPC calls to `shua_habits` microservice (TASK-026)

---

## Screen Architecture

```
client_flutter/lib/features/habits/
├── habit_home_screen.dart          # Main screen: today's habits + quick log
├── habit_monthly_screen.dart       # Monthly grid view with analytics
├── habit_editor_screen.dart        # Create/Edit habit definition
├── widgets/
│   ├── habit_card.dart             # Habit row with checkbox and streak badge
│   ├── habit_bar_chart.dart        # Weekly completion bar chart (CustomPainter)
│   ├── habit_donut_ring.dart       # Circular progress ring (CustomPainter)
│   ├── habit_monthly_grid.dart     # Monthly calendar grid showing completion dots
│   ├── habit_streak_badge.dart     # Flame icon + streak count badge
│   ├── habit_completion_row.dart   # "X / Y completed today" summary row
│   └── habit_category_chip.dart    # Colored category label chip
└── providers/
    ├── habit_today_provider.dart   # AsyncNotifier: habit.today RPC
    ├── habit_monthly_provider.dart # AsyncNotifier: habit.monthly RPC
    ├── habit_list_provider.dart    # AsyncNotifier: habit.list RPC
    └── habit_stats_provider.dart   # AsyncNotifier: habit.stats RPC
```

**Time Complexity**: O(H) render pass for H active habits on the home screen. Monthly grid render O(D) for D days in month.
**Space Complexity**: O(H * D) for monthly completion map cached in Riverpod.

---

## Navigation (GoRouter)

| Route | Screen |
| :--- | :--- |
| `/habits` | `HabitHomeScreen` (today view) |
| `/habits/monthly` | `HabitMonthlyScreen` (analytics grid) |
| `/habits/new` | `HabitEditorScreen` (create) |
| `/habits/:id/edit` | `HabitEditorScreen` (edit) |

Add `/habits` as a top-level route in the existing GoRouter shell alongside `/diary`, `/resume`, etc.

---

## `HabitHomeScreen` Design

Modeled after the reference habit tracker image:

### Layout (top to bottom):
1. **Header Row**: Month + Year title, left/right arrows to navigate months, "Today" chip
2. **Completion Summary Row**: `HabitCompletionRow` — "X / Y habits completed today" with a thin linear progress bar
3. **Habit List** (`ListView.builder`):
   - Each row = `HabitCard`:
     - Emoji + habit name (left)
     - `HabitStreakBadge` (🔥 N days)
     - Checkbox or increment counter (right)
     - Tapping checkbox → calls `habit.log` RPC with optimistic local state update
4. **FAB**: `+` → `/habits/new`
5. **Analytics Button** (bottom right): → navigates to `/habits/monthly`

### Quick Log Interaction:
- Tapping a habit's checkbox triggers optimistic UI update immediately (checkbox ticks)
- `habit.log` RPC fires in background
- On error → revert and show snackbar: "Failed to log — tap to retry"

---

## `HabitMonthlyScreen` Design

Reference: The Excel-style habit tracker image with colored bars, monthly grid, and weekly donut rings.

### Layout:
1. **Month Selector**: Left/right arrows + month-year label
2. **Weekly Bar Charts** (`HabitBarChart` × 4-5 weeks):
   - Each week shows a colored vertical bar per habit
   - Bar height = weekly completion rate (0–100%)
   - Color matches habit's defined color
   - Matches the reference image's weekly columns visual
3. **Monthly Grid** (`HabitMonthlyGrid`):
   - Header: Habit names (rows) vs. dates 1–31 (columns)
   - Cell: filled dot if completed, empty if not, greyed if habit not yet started
   - Matches the reference image's day-by-day checkmark grid
4. **Weekly Progress Donuts** (`HabitDonutRing` × 4-5):
   - One donut per week showing overall weekly completion %
   - Matches the reference image's weekly progress donuts at the bottom

### Weekly Completion Status Row:
```
WEEK 1: 70/70  |  WEEK 2: 45/70  |  WEEK 3: 41/70  |  WEEK 4: 41/70
```
Exact visual match to reference image's "Weekly Completion Status" row.

---

## `HabitEditorScreen` Design

Form fields:

| Field | Widget |
| :--- | :--- |
| `name` | `TextFormField` (required) |
| `emoji` | Emoji picker bottom sheet |
| `color` | Color picker row (Material 3 colors) |
| `category` | `SegmentedButton`: Health / Learning / Fitness / Mindfulness / Custom |
| `frequency` | `SegmentedButton`: Daily / Weekly |
| `target_count` | `Stepper` widget: 1–10 (default 1) |
| `description` | `TextFormField` (optional, multiline) |

---

## `HabitBarChart` (CustomPainter)

```dart
class HabitBarChart extends StatelessWidget {
  final List<double> weeklyRates; // 0.0 to 1.0 per day in the week
  final Color color;
  // Renders bars matching the reference image aesthetic:
  // - Rounded top corners
  // - Gradient fill (light at top, saturated at bottom)
  // - Percentage label above each bar
  // Uses CustomPainter: O(7) draw calls per chart (one per day)
}
```

---

## `HabitDonutRing` (CustomPainter)

```dart
class HabitDonutRing extends StatelessWidget {
  final double completionRate; // 0.0 to 1.0
  final Color color;
  // Renders the circular progress donut from reference image
  // Center label: "64.29%" (formatted percentage)
  // Arc drawn with CustomPainter using canvas.drawArc
  // O(1) draw call
}
```

---

## Riverpod Integration

```dart
// habit_today_provider.dart
@riverpod
class HabitTodayNotifier extends _$HabitTodayNotifier {
  Future<HabitTodayDto> build() async {
    final hbp = ref.read(hbpClientProvider);
    final response = await hbp.call('habit.today', {'user_id': 'shua'});
    return HabitTodayDto.fromJson(response);
  }

  Future<void> logHabit(String habitId, int count) async {
    // Optimistic state update first
    // Then fire habit.log RPC
    // On error: revert + show snackbar
  }
}
```

---

## Acceptance Criteria

- [ ] `HabitHomeScreen` displays all active habits with today's completion status
- [ ] Tapping a habit checkbox logs completion via `habit.log` with optimistic update
- [ ] Streak badges display correct current streak count from `habit.stats`
- [ ] `HabitMonthlyScreen` renders weekly bar charts matching reference image design
- [ ] Monthly grid shows correct completion dots for all days in selected month
- [ ] Weekly donut rings show correct completion percentages
- [ ] `HabitEditorScreen` creates and edits habits correctly (all fields save via `habit.save`)
- [ ] Habits marked inactive are hidden from home screen but visible in a separate "Archived" tab
- [ ] `0` Dart analysis errors or lint warnings (`flutter analyze`)
