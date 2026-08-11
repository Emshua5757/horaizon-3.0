# TASK-019B — `client_flutter` Certification Roadmap Screen

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/diary/certifications/` |
| **Blocks** | Nothing |
| **Prerequisites** | TASK-010 (GoRouter + Material 3 theme), TASK-017B (Certification Roadmap API), TASK-019 (Diary baseline) |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/contracts/hbp/hbp_v2_spec.md` |

---

## Architectural Directives

> [!IMPORTANT]
> **ADR-001 is LAW**: All UI is 100% native Flutter Dart widgets. Zero SDUI.
>
> This feature has a **dedicated top-level navigation destination** alongside `/diary` — it is not a sub-screen buried inside the diary. The certification roadmap is a first-class feature the user will visit daily while actively grinding for AWS/DevOps exams.

---

## Navigation Structure

| Route | Screen | Entry Point |
| :--- | :--- | :--- |
| `/certs` | `CertDashboardScreen` | Top-level nav destination |
| `/certs/roadmap` | `CertRoadmapScreen` | Full timeline view |
| `/certs/:id` | `CertDetailScreen` | Cert detail with resources & progress |
| `/certs/:id/resources` | `CertResourcesScreen` | Resource list + progress editor |
| `/certs/:id/invest` | `CertInvestmentScreen` | Add investment for this cert |
| `/certs/investments` | `InvestmentSummaryScreen` | Total spend tracker |
| `/certs/new` | `CertEditorScreen` | Create new cert record |
| `/certs/:id/edit` | `CertEditorScreen` | Edit cert record |

---

## Screen Architecture

```
client_flutter/lib/features/certifications/
├── cert_dashboard_screen.dart      # Command center: countdown, roadmap summary, spend
├── cert_roadmap_screen.dart        # Visual timeline of all certs ordered by roadmap_order
├── cert_detail_screen.dart         # Full cert detail: status, resources, progress, exam info
├── cert_resources_screen.dart      # Study resource list + per-resource progress sliders
├── cert_investment_screen.dart     # Add/view investments for a cert
├── investment_summary_screen.dart  # Total spend vs budget, grouped by type and cert
├── cert_editor_screen.dart         # Create/edit CertEntry form
├── widgets/
│   ├── cert_dashboard_card.dart        # "Next exam in X days" hero countdown card
│   ├── cert_roadmap_node.dart          # Single node in the timeline (status-colored)
│   ├── cert_roadmap_connector.dart     # Vertical line connecting roadmap nodes
│   ├── cert_status_chip.dart           # Planned / Studying / Scheduled / Passed / Failed
│   ├── cert_progress_ring.dart         # Circular progress for overall cert readiness %
│   ├── cert_resource_card.dart         # Resource link card with progress slider
│   ├── cert_resource_type_icon.dart    # Icon by resource type (course/video/book/etc.)
│   ├── cert_investment_tile.dart       # Investment line item (PHP amount, type, date)
│   ├── cert_spend_chart.dart           # Bar chart: spend by cert (CustomPainter)
│   ├── cert_exam_countdown.dart        # Large countdown widget (D days, HH:MM:SS)
│   └── cert_score_display.dart         # Achieved / passing score gauge (post-exam)
└── providers/
    ├── cert_dashboard_provider.dart    # CertDashboardStats from diary.cert.dashboard
    ├── cert_roadmap_provider.dart      # Ordered CertEntry[] from diary.cert.roadmap
    ├── cert_detail_provider.dart       # CertEntry + resources + progress summary
    ├── cert_resource_provider.dart     # CertResource[] for a cert + progress state
    ├── cert_investment_provider.dart   # InvestmentSummary from diary.cert.investment.summary
    └── cert_editor_provider.dart       # Form state for create/edit
```

**Time Complexity**: O(C) roadmap render for C certs. O(R) resource list for R resources per cert.
**Space Complexity**: O(C + R + I) for certs, resources, and investments cached in Riverpod.

---

## `CertDashboardScreen` — Command Center

The screen the user opens every morning to know: *"Am I on track for my AWS exam?"*

### Layout (top to bottom):

**1. Hero Countdown Card** (`CertExamCountdown`)
- Full-width card with gradient background (AWS orange/yellow for AWS certs, DevOps blue for DevOps)
- "AWS SAA-C03 Exam" — large cert name
- **"23 Days Left"** — very large font countdown to `exam_scheduled_at`
- Sub-label: exam date + time + "Online Proctored"
- Action chip: "📅 Registration Link" → opens `exam_registration_url` in browser
- If no exam scheduled: "Schedule Exam" button → opens `exam_registration_url`

**2. Roadmap Mini-Preview Row** (horizontal scrollable)
- Compact chips: each cert as a small `CertStatusChip` pill in `roadmap_order`
- Active cert highlighted; passed certs have a checkmark; planned are grey
- "View Full Roadmap →" tapping navigates to `CertRoadmapScreen`

**3. Today's Study Goal Card**
- "Active cert: AWS SAA-C03"
- `CertProgressRing` — circular progress showing overall study readiness %
- Sub-breakdown list: each resource with its progress bar
  - "✅ Udemy Course — 78% (112/145 sections)"
  - "🔄 Tutorials Dojo Practice Exams — 23%"
  - "⬜ AWS Whitepapers — 0%"
- "Open Resources →" navigates to `CertResourcesScreen`

**4. Investment Summary Strip**
- "Total Invested: ₱12,450" — running total
- "This month: ₱3,200"
- "Tap to view full breakdown" → `InvestmentSummaryScreen`

**5. Quick Actions Row**
- `[+ Log Study Session]` → opens resource progress update bottom sheet
- `[+ Add Cert]` → navigates to `CertEditorScreen`
- `[+ Log Expense]` → opens investment add bottom sheet

---

## `CertRoadmapScreen` — Visual Timeline

A vertical chronological timeline of all certifications ordered by `roadmap_order`.

### Layout:

```
[Passed ✓] CompTIA A+            ────  2025-03-14
            │
[Passed ✓] CompTIA Network+       ────  2025-06-01
            │
[ACTIVE  ] AWS Cloud Practitioner  ────  Exam: 2026-09-15  (35 days)
            │                           ████████░░ 78% ready
[Planned ] AWS SAA-C03             ────  After Cloud Practitioner
            │
[Planned ] AWS DevOps Engineer Pro ────  Target: Q1 2027
            │
[Planned ] HashiCorp Terraform     ────  Target: Q2 2027
```

Each node (`CertRoadmapNode`) shows:
- Status icon: ✅ passed, 🔄 studying, 📅 scheduled, 🎯 planned, ❌ failed
- Cert name + issuer badge
- Date (passed date, exam date, or target quarter)
- Progress ring (only for `studying` / `exam_scheduled` status)
- "Start Studying" / "View Details" / "Reschedule" context action

Nodes are connected by `CertRoadmapConnector` vertical lines colored by status.

**Drag to reorder** — long-press a node to drag it to a different position in the roadmap. Fires `diary.cert.reorder` on drop.

---

## `CertDetailScreen` — Full Cert View

Tabbed screen with 4 tabs:

### Tab 1: Overview
- Cert name, issuer, exam code, category chip
- Status chip (large, colored)
- `CertProgressRing` — overall readiness %
- "Days Until Exam" countdown (if scheduled)
- Exam info card: date/time, venue type, registration link button
- Score display (if exam attempted): achieved score / passing score
- Notes section (markdown-rendered)
- "Edit" FAB

### Tab 2: Study Resources (`CertResourcesScreen`)
Grouped by priority:

**Must-Do (Priority 1)**
- `CertResourceCard` for each resource:
  - Resource type icon (`CertResourceTypeIcon`)
  - Title + platform label
  - URL → opens in browser
  - "Free" or "₱X" label
  - Estimated hours: `{N}h`
  - **Progress Slider** (0–100%) — user drags to update
  - "Last studied: 2 days ago"
  - Notes text field (inline edit)

**Recommended (Priority 2)** — collapsible section

**Optional (Priority 3)** — collapsible section

**[+ Add Resource]** button at bottom → inline form to add new resource

### Tab 3: Investments
- List of `CertInvestmentTile` for this cert only
- Running total for this cert: "₱3,450 invested"
- `[+ Log Expense]` FAB → bottom sheet form

### Tab 4: Timeline/Notes
- Chronological log of status changes (auto-generated from `updated_at` transitions)
- "Started Studying: Aug 11, 2026"
- "Exam Scheduled: Sep 15, 2026"
- User's freeform `notes` in a markdown editor

---

## `InvestmentSummaryScreen` — Self-Investment Tracker

> [!NOTE]
> This screen is personal — the user is funding this entirely from data annotation income. The design should feel empowering: every peso is an investment in their future.

### Layout:

**Hero Total Card**
- "Total Self-Investment" — large number: ₱XX,XXX
- Subtitle: "AWS & DevOps Certification Journey"

**By Type Bar Chart** (`CertSpendChart`, CustomPainter)
- Horizontal bar chart: Exam Fees | Courses | Books | Equipment | Other
- Each bar colored distinctly with PHP amount label

**By Cert Breakdown**
- Accordion list: each cert → total invested + itemized expense list

**All Transactions** (recent-first)
- `CertInvestmentTile` list: description, type chip, date, amount in PHP
- Long-press → delete

**[+ Log Expense]** FAB

---

## `CertEditorScreen` — Create/Edit Form

| Field | Widget | Notes |
| :--- | :--- | :--- |
| `name` | `TextFormField` | Required |
| `issuer` | `TextFormField` | Required |
| `exam_code` | `TextFormField` | e.g. "SAA-C03" |
| `category` | `SegmentedButton` | AWS / DevOps / Security / AI-ML / General |
| `status` | `SegmentedButton` | Planned / Studying / Scheduled / Passed / Failed |
| `roadmap_order` | Auto-assigned (append) + drag reorder on roadmap |  |
| `exam_scheduled_at` | `DateTimePicker` | Only if status = scheduled |
| `exam_registration_url` | `TextFormField` | Pearson VUE / PSI link |
| `exam_venue` | `SegmentedButton` | Online Proctored / Test Center |
| `passing_score` | `TextFormField` (number) | e.g. 720 |
| `achieved_score` | `TextFormField` (number) | Only if passed/failed |
| `issued_at` | `DatePicker` | Only if passed |
| `expires_at` | `DatePicker` + "Never expires" toggle | |
| `credential_url` | `TextFormField` | Credly link |
| `notes` | `TextFormField` (multiline) | Tips, resources discovered, lessons learned |
| `vault_doc_hash` | File picker → governor vault upload | Certificate PDF |

---

## `DiaryCertificationBlock` Widget (Diary Integration)

Used inside `DiaryEditorScreen` for `block_type = 'certification'`:

```dart
// lib/features/diary/widgets/blocks/diary_certification_block.dart
class DiaryCertificationBlock extends DiaryBlockWidget {
  // content JSON: { cert_id: string, display_mode: 'card'|'badge'|'progress_card' }

  // badge: Compact chip — cert name + status chip, taps to /certs/:id
  // card: Full card — name, exam countdown, progress ring
  // progress_card: Study session log card — resource progress bars + "Update Progress" button
}
```

---

## Riverpod: Key Provider Pattern

```dart
// cert_dashboard_provider.dart
@riverpod
class CertDashboardNotifier extends _$CertDashboardNotifier {
  Future<CertDashboardDto> build() async {
    final hbp = ref.read(hbpClientProvider);
    final r = await hbp.call('diary.cert.dashboard', {'user_id': 'shua'});
    return CertDashboardDto.fromJson(r);
  }
}

// cert_resource_provider.dart — with optimistic progress update
@riverpod
class CertResourceNotifier extends _$CertResourceNotifier {
  Future<void> updateProgress(String resourceId, int percent) async {
    // 1. Optimistic: update local state immediately
    // 2. Fire diary.cert.progress.save RPC
    // 3. On error: revert + show snackbar
  }
}
```

---

## Acceptance Criteria

- [ ] `CertDashboardScreen` shows correct next-exam countdown and overall progress
- [ ] `CertRoadmapScreen` renders all certs as a vertical timeline ordered by `roadmap_order`
- [ ] Drag-to-reorder on roadmap fires `diary.cert.reorder` and persists order
- [ ] `CertDetailScreen` has all 4 tabs functioning (Overview, Resources, Investments, Timeline)
- [ ] Resource progress sliders update via `diary.cert.progress.save` with optimistic UI
- [ ] "Open Resource" URL taps open the link in the device browser
- [ ] `InvestmentSummaryScreen` shows correct totals and `CertSpendChart` bar chart
- [ ] `[+ Log Expense]` bottom sheet saves investments correctly in PHP
- [ ] `CertEditorScreen` validates all required fields before saving
- [ ] `DiaryCertificationBlock` renders in all 3 display modes within the diary editor
- [ ] All routes in GoRouter are registered and navigate correctly
- [ ] `0` Dart analysis errors or lint warnings (`flutter analyze`)
