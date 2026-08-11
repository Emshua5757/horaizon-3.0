# TASK-019B — `client_flutter` Certification Tracker Screen

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/diary/certifications/` |
| **Blocks** | Nothing |
| **Prerequisites** | TASK-010 (GoRouter + Material 3 theme), TASK-017B (Certification Tracker API), TASK-019 (Diary screen baseline) |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/contracts/hbp/hbp_v2_spec.md` |

---

## Architectural Directives

> [!IMPORTANT]
> **ADR-001 is LAW**: All UI is 100% native Flutter Dart widgets. Zero SDUI.
>
> Certification data comes from `diary.cert.*` HBP v2 RPC operations on `shua_diary`.
> All state is typed Riverpod `AsyncNotifier`. The certification screen is a sub-feature of `diary` in the Flutter feature tree.

---

## Screens & Navigation

| Route | Screen | Description |
| :--- | :--- | :--- |
| `/diary/certs` | `CertListScreen` | Grid/list of all certifications grouped by status tab |
| `/diary/certs/new` | `CertEditorScreen` | Create new certification record |
| `/diary/certs/:id` | `CertDetailScreen` | Full cert detail with edit capability |

These routes are nested under the `/diary` GoRouter shell (existing). Add as child routes.

---

## Screen Architecture

```
client_flutter/lib/features/diary/certifications/
├── cert_list_screen.dart          # Tabbed list: Active | In Progress | Planned | Expired
├── cert_editor_screen.dart        # Create/Edit form for CertEntry fields
├── cert_detail_screen.dart        # Full detail view + PDF viewer link + edit button
├── widgets/
│   ├── cert_card.dart             # Compact card widget for list view
│   ├── cert_badge.dart            # Small badge widget (used in DiaryBlock embed)
│   ├── cert_status_chip.dart      # Colored chip: Active (green), Expired (red), etc.
│   ├── cert_expiry_banner.dart    # Warning banner if cert expires within 30 days
│   └── cert_stats_card.dart       # Summary card: total, by status, expiring soon
└── providers/
    ├── cert_list_provider.dart    # AsyncNotifier: fetch all certs from diary.cert.list
    ├── cert_detail_provider.dart  # AsyncNotifier: fetch single cert from diary.cert.get
    └── cert_stats_provider.dart   # AsyncNotifier: fetch stats from diary.cert.stats
```

**Time Complexity**: O(C) initial list load where C = number of certs. All subsequent interactions O(1) via cached Riverpod state.
**Space Complexity**: O(C) for C cert records in Riverpod state.

---

## `CertListScreen` Design

- **TabBar**: `Active` | `In Progress` | `Planned` | `Expired`
- **Stats Row at top**: Compact `CertStatsCard` showing counts per tab and "X expiring within 30 days"
- **Grid layout** (`GridView.builder`, 2 columns on phone, 3 on tablet):
  - Each cell: `CertCard` showing cert name, issuer, category chip, expiry date, status chip
  - Tapping a card → navigates to `CertDetailScreen`
- **FAB**: `+` button → navigates to `CertEditorScreen`
- **Expiry Warning**: `CertExpiryBanner` appears at top if any active cert expires within 30 days

---

## `CertEditorScreen` Design

Form fields mapping to `CertEntry`:

| Field | Widget | Notes |
| :--- | :--- | :--- |
| `name` | `TextFormField` | Required |
| `issuer` | `TextFormField` | Required |
| `status` | `SegmentedButton<CertStatus>` | Active / In Progress / Planned / Expired |
| `category` | `DropdownButtonFormField` | Cloud / Security / DevOps / AI-ML / General |
| `issued_at` | `DiaryDatePickerBlock` (reused widget) | Required |
| `expires_at` | `DiaryDatePickerBlock` + "No expiry" toggle | Optional |
| `credential_id` | `TextFormField` | Optional |
| `credential_url` | `TextFormField` | Optional; validate URL format |
| `notes` | `TextFormField` (multiline) | Optional; study tips, resources |
| `vault_doc_hash` | File picker → uploads to governor vault | Optional; attach certificate PDF |

Save button → calls `diary.cert.save` RPC → pops back to list on success.

---

## `DiaryCertificationBlock` Widget

This widget is used inside the `DiaryEditorScreen` when a block of type `certification` is encountered.

```dart
// lib/features/diary/widgets/blocks/diary_certification_block.dart
class DiaryCertificationBlock extends DiaryBlockWidget {
  // Reads 'cert_id' from block.content JSON
  // Calls cert_detail_provider to fetch CertEntry
  // Renders CertBadge widget in 'badge' mode (compact inline display)
  // Tapping → navigates to /diary/certs/:cert_id
}
```

---

## Riverpod Providers

```dart
// cert_list_provider.dart
@riverpod
class CertListNotifier extends _$CertListNotifier {
  Future<List<CertEntryDto>> build() async {
    final hbp = ref.read(hbpClientProvider);
    final response = await hbp.call('diary.cert.list', {'user_id': 'shua'});
    return (response['certs'] as List).map(CertEntryDto.fromJson).toList();
  }

  Future<void> saveCert(CertEntryDto cert) async { ... }
  Future<void> deleteCert(String certId) async { ... }
}
```

---

## Navigation Integration (GoRouter)

Add to existing diary GoRouter shell in `lib/app/router.dart`:

```dart
GoRoute(
  path: 'certs',
  builder: (_, __) => const CertListScreen(),
  routes: [
    GoRoute(path: 'new',  builder: (_, __) => const CertEditorScreen()),
    GoRoute(path: ':id',  builder: (c, s) => CertDetailScreen(certId: s.pathParameters['id']!)),
  ],
),
```

---

## Acceptance Criteria

- [ ] `CertListScreen` displays all certifications grouped by the 4-tab status filter
- [ ] `CertStatsCard` shows correct counts and "expiring within 30 days" count
- [ ] `CertExpiryBanner` appears when any active cert expires within 30 days
- [ ] `CertEditorScreen` validates all required fields before calling `diary.cert.save`
- [ ] Attaching a certificate PDF uploads to governor vault and stores `vault_doc_hash` in cert record
- [ ] `CertDetailScreen` shows full cert details with link to `credential_url` (opens in browser)
- [ ] `DiaryCertificationBlock` renders inline within `DiaryEditorScreen`
- [ ] Navigation flows correctly: List → Detail → Edit → back to List
- [ ] `0` Dart analysis errors or lint warnings (`flutter analyze`)
