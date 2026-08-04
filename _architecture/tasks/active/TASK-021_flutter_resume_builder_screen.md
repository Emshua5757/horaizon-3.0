# TASK-021 — `client_flutter` Native Resume Builder & Live PDF Preview Screen

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Planned |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/resume/` |
| **Blocks** | None |
| **Prerequisites** | TASK-010 (GoRouter & Material 3 theme), TASK-020 (`shua_resume`), TASK-022 (Governor Media Vault) |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/contracts/hbp/hbp_v2_spec.md`, `_architecture/contracts/hbp/API_REFERENCE.md` |

---

## Architectural Directives (READ BEFORE WRITING A SINGLE LINE)

> [!IMPORTANT]
> **ADR-001 is LAW**: 100% native Flutter Dart widgets. Zero SDUI, zero blueprint parsing.
>
> Mental model: **widget calls provider calls HBP v2 RPC**. Three hops, all typed.
>
> **HBP v2 client is already implemented** at `client_flutter/lib/core/hbp/`:
> - `hbp_client.dart` — WebSocket connection, reconnect, heartbeat
> - `hbp_frame.dart` — MessagePack envelope encode/decode
> - `hbp_client_provider.dart` — Riverpod provider
>
> Do NOT create new WebSocket connections or HTTP REST clients.

> [!NOTE]
> **Jaccard scoring runs CLIENT-SIDE in Dart** — not via RPC.
>
> The Jaccard keyword match percentage shown on the Compile screen is computed entirely in Flutter using a Dart port of the `Tokenize` + `JaccardSimilarity` functions from the Go backend. This avoids burdening the Pi 5 with rapid RPC calls as the user types. The Pi 5 only does Jaccard when `tailor: true` is sent in `resume.compile` — for the definitive server-side filtered result that gets embedded in the PDF.

---

## Screen Architecture (`client_flutter/lib/features/resume/`)

```
lib/features/resume/
├── resume_screen.dart                    # Tab shell: Editor / Compile / History bottom nav
├── screens/
│   ├── resume_editor_screen.dart         # 7-tab CRUD matrix editor
│   ├── resume_compile_screen.dart        # JD input, live Jaccard gauge, template picker, compile
│   └── resume_history_screen.dart        # Compiled PDF history list + pdfx viewer
├── widgets/
│   ├── resume_section_tab.dart           # Generic tab container (title, ListView, FAB)
│   ├── work_item_card.dart               # Work experience inline expand-to-edit card
│   ├── project_item_card.dart            # Project inline expand-to-edit card
│   ├── skill_chip_row.dart               # Skill group + keyword chips (tap to edit)
│   ├── education_item_card.dart          # Education inline expand-to-edit card
│   ├── certificate_item_card.dart        # Certificate inline expand-to-edit card
│   ├── award_item_card.dart              # Award inline expand-to-edit card
│   ├── jaccard_score_gauge.dart          # Animated arc gauge: 0-100% match (client-side)
│   ├── template_picker.dart              # Horizontal chip selector: Default/Modern/Minimalist
│   └── compile_progress_overlay.dart     # Full-screen shimmer overlay during PDF compilation
├── providers/
│   ├── resume_matrix_provider.dart       # AsyncNotifier: fetch + mutate ResumeMatrixDto
│   ├── resume_compile_provider.dart      # StateNotifier: compile state machine
│   └── resume_history_provider.dart      # AsyncNotifier: fetch history list
└── utils/
    └── jaccard_dart.dart                 # Client-side Jaccard implementation (pure Dart)
```

---

## GoRouter Routes

Add to existing GoRouter config (TASK-010):

| Route | Screen | Notes |
| :--- | :--- | :--- |
| `/resume` | `ResumeScreen` | Tab shell — replaces current stub |
| `/resume/editor` | direct tab | Tab index 0 inside `ResumeScreen` |
| `/resume/compile` | direct tab | Tab index 1 inside `ResumeScreen` |
| `/resume/history` | direct tab | Tab index 2 inside `ResumeScreen` |

Navigation between tabs is LOCAL state in `ResumeScreen` — NOT GoRouter push. Avoids rebuild cost and preserves scroll position within each tab.

---

## Client-Side Jaccard (`utils/jaccard_dart.dart`)

> [!IMPORTANT]
> This is a pure Dart port of `pkg/ai/tailor.go:Tokenize` + `JaccardSimilarity`. Keep it functionally identical to the Go version so scores are consistent.

```dart
/// Tokenizes text into a lowercase word set, removing stopwords.
/// O(n) where n = word count.
Set<String> tokenize(String text) {
  const stopwords = {'the','a','an','and','or','but','in','on','at','to','for','of','with','is','are','was','were','be','been','being','have','has','had','do','does','did','will','would','could','should','may','might','shall','can','need','dare','ought','used'};
  return text
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.length > 2 && !stopwords.contains(w))
    .toSet();
}

/// Jaccard similarity: |A ∩ B| / |A ∪ B|.
/// O(|A| + |B|).
double jaccardSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 0.0;
  final intersection = a.intersection(b).length;
  final union = a.union(b).length;
  return intersection / union;
}

/// Computes live Jaccard score between a job description and the resume text.
/// Call this in the Compile screen with debounce — NOT on every keystroke.
double scoreResumeAgainstJd(ResumeMatrixDto matrix, String jobDesc) {
  // Concatenate all resume text: work highlights, project descriptions, skill keywords
  final resumeText = StringBuffer();
  for (final w in matrix.work) { resumeText.writeAll(w.highlights, ' '); }
  for (final p in matrix.projects) { resumeText.write(p.description); resumeText.writeAll(p.highlights, ' '); }
  for (final s in matrix.skills) { resumeText.writeAll(s.keywords, ' '); }
  final setA = tokenize(resumeText.toString());
  final setB = tokenize(jobDesc);
  return jaccardSimilarity(setA, setB);
}
```

**Usage in `resume_compile_screen.dart`**:
```dart
// Debounce 400ms after last keystroke
ref.listen(jdTextProvider, (_, jd) {
  final matrix = ref.read(resumeMatrixProvider).valueOrNull;
  if (matrix == null || jd.trim().isEmpty) return;
  final score = scoreResumeAgainstJd(matrix, jd);
  ref.read(liveJaccardScoreProvider.notifier).state = score;
});
```

**Time Complexity**: O(n + m) where n = resume token count, m = JD token count.
**Space Complexity**: O(n + m) for the two token sets.

---

## Screen 1 — Resume Matrix Editor (`resume_editor_screen.dart`)

### Layout

`DefaultTabController` with 7 tabs:

| Tab | Section | CRUD |
| :--- | :--- | :--- |
| Basics | `resume_basics` | Single-record form (name, label, email, phone, url, summary, location) |
| Experience | `resume_work` | List + add + inline-edit + swipe-delete |
| Projects | `resume_projects` | List + add + inline-edit + swipe-delete |
| Skills | `resume_skills` | List + add + inline-edit + swipe-delete |
| Education | `resume_education` | List + add + inline-edit + swipe-delete |
| Certs | `resume_certificates` | List + add + inline-edit + swipe-delete |
| Awards | `resume_awards` | List + add + inline-edit + swipe-delete |

### Interaction Pattern

- **Inline expansion**: Tapping an item card expands it with `AnimatedContainer` into an edit form. No navigation push — all inline to minimize round-trip latency.
- **Debounced auto-save**: 800ms after last keystroke, call `resume.matrix.update` `upsert`. Show a 300ms green check icon animation on the card header on save success.
- **Add**: `FloatingActionButton` at bottom-right inserts a blank card in expanded edit mode.
- **Delete**: Swipe-to-dismiss (`Dismissible`) triggers `resume.matrix.update` `delete` + removes card from list with animation.
- **Optimistic UI**: Apply local state update immediately on add/delete. Revert if RPC returns an error.
- **Empty states**: Each tab shows an illustrated empty state widget when the section has no items (e.g. "No projects yet — tap + to add one").

### HBP v2 Data Flow (`resume_matrix_provider.dart`)

```dart
class ResumeMatrixNotifier extends AsyncNotifier<ResumeMatrixDto> {
  @override
  Future<ResumeMatrixDto> build() async {
    final hbp = ref.read(hbpClientProvider);
    final resp = await hbp.request(mod: 'shua.resume', op: 'matrix.get', payload: Uint8List(0));
    return ResumeMatrixDto.fromMsgpack(resp.payload);
  }

  Future<void> upsertSection(String section, Map<String, dynamic> item) async {
    // Optimistic: update local state immediately
    state = AsyncData(_applyUpsert(state.requireValue, section, item));
    // Background RPC
    final hbp = ref.read(hbpClientProvider);
    final resp = await hbp.request(
      mod: 'shua.resume', op: 'matrix.update',
      payload: msgpack.encode({'section': section, 'action': 'upsert', 'item': item}),
    );
    if (!resp.ok) ref.invalidateSelf(); // Revert on error
  }

  Future<void> deleteItem(String section, String id) async {
    state = AsyncData(_applyDelete(state.requireValue, section, id));
    final hbp = ref.read(hbpClientProvider);
    await hbp.request(
      mod: 'shua.resume', op: 'matrix.update',
      payload: msgpack.encode({'section': section, 'action': 'delete', 'id': id}),
    );
  }
}
```

---

## Screen 2 — AI Tailoring & Compile (`resume_compile_screen.dart`)

### Layout (top to bottom)

1. **Job Description `TextField`** — multiline, fills top ~40% of screen. Label: "Paste job description". On `onChanged`, debounce 400ms, run `scoreResumeAgainstJd` client-side, update `liveJaccardScoreProvider`.

2. **`JaccardScoreGauge`** — animated arc gauge (0–100%). Updates live as user types. Color interpolation:
   - 0–30%: red `#E53935`
   - 31–60%: amber `#FFA000`
   - 61–100%: green `#43A047`
   - Label text: `"Match: {score}%"` + sub-label `"(live keyword analysis)"`.

3. **`TemplatePicker`** — horizontal chip row: `Default` / `Modern` / `Minimalist`. Selected chip has solid fill. Stores in local `useState<String>('default')`.

4. **AI Enhancement `SwitchListTile`** — "Enable Ollama AI Enhancement". Toggles `ai_enhance` flag. Shows a sub-text: "Uses Pi 5 Ollama to rewrite bullet points for the job description." Disabled by default.

5. **"Compile PDF" `ElevatedButton`** — full-width. Icon: `Icons.picture_as_pdf`. On tap:
   - Show `CompileProgressOverlay` (animated shimmer card + "Compiling on Pi 5..." + elapsed time `Ticker`).
   - Dispatch `resume.compile` RPC with 120s timeout.
   - On success: hide overlay, navigate to History tab, auto-select the new exhibit.
   - On error: hide overlay, show `SnackBar` with error message.

6. **Last Compile Result** — if a `ResumeCompileResponseDto` is cached in `resume_compile_provider`, show a tappable card at the bottom: `"Last PDF: {date} — {template} — {score}%"` → taps into History tab.

### `CompileProgressOverlay`

Full-screen overlay (`ColoredBox` + `Column`):
- Shimmer loading card animation.
- Text: "Compiling on Pi 5..."
- `StreamBuilder` on elapsed seconds ticker.
- If `ai_enhance == true`: additional text "AI enhancement in progress..."
- Cancel button: sends nothing — just dismisses overlay locally (compile continues on Pi 5; result arrives when done).

---

## Screen 3 — PDF History & Viewer (`resume_history_screen.dart`)

### History List

`ListView.builder` from `resume_history_provider`. Each `ListTile`:
- **Leading**: `Icon(Icons.picture_as_pdf, color: Colors.red)`
- **Title**: `"{template_name} — {compiled_at_formatted}"` (e.g. "Modern — Aug 4, 2026")
- **Subtitle**: Jaccard score badge if non-null (e.g. "Match: 72%") + duration (e.g. "1.2s")
- **Trailing**: `IconButton(Icons.download)` + `IconButton(Icons.share)`

Tapping an item expands a PDF viewer panel below the list (on wide screens: side-by-side split view; on narrow screens: pushes to a detail page).

### PDF Viewer

```dart
// Load from Governor Media Vault HTTP server (port 7702 — range-request capable)
final pdfController = PdfController(
  document: PdfDocument.openUri(Uri.parse(exhibit.vaultUrl)),
);
PdfView(controller: pdfController)
```

Package: `pdfx` — supports HTTP URIs and range requests. **Do NOT use `syncfusion_flutter_pdfviewer`**.

### Download & Share

```dart
// Download to device
Future<void> downloadPdf(String vaultUrl, String fileName) async {
  final response = await http.get(Uri.parse(vaultUrl));
  final dir = await getDownloadsDirectory();  // Windows
  // Android: getExternalStorageDirectory()
  final file = File('${dir!.path}/$fileName');
  await file.writeAsBytes(response.bodyBytes);
}

// Share via platform share sheet
Future<void> sharePdf(String vaultUrl, String fileName) async {
  final response = await http.get(Uri.parse(vaultUrl));
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/$fileName')..writeAsBytesSync(response.bodyBytes);
  await Share.shareXFiles([XFile(tempFile.path)], text: 'My Resume — $fileName');
}
```

---

## Dart DTOs

DTOs live in `lib/features/resume/` — NOT in a global models folder.

```dart
// resume_matrix_dto.dart
class ResumeMatrixDto {
  final BasicsDto basics;
  final List<WorkItemDto> work;
  final List<EducationDto> education;
  final List<ProjectItemDto> projects;
  final List<SkillDto> skills;
  final List<CertificateDto> certificates;
  final List<AwardDto> awards;
  factory ResumeMatrixDto.fromMsgpack(Uint8List bytes) { ... }
  Map<String, dynamic> toMap() { ... }
}

// resume_compile_response_dto.dart
class ResumeCompileResponseDto {
  final String exhibitId;    // SHA256 hash
  final String vaultUrl;     // http://{pi5}:7702/vault/resume/...
  final int durationMs;
  final double? tailorScore; // null if tailor == false
  factory ResumeCompileResponseDto.fromMsgpack(Uint8List bytes) { ... }
  // Index-keyed decode per API_REFERENCE.md ResumeCompileResponse struct
}

// resume_history_item_dto.dart
class ResumeHistoryItemDto {
  final String exhibitId;
  final String vaultUrl;
  final String templateId;
  final String jobDesc;
  final double? tailorScore;
  final bool aiEnhanced;
  final int durationMs;
  final DateTime compiledAt;
}
```

---

## pubspec.yaml Dependencies to Add

```yaml
dependencies:
  pdfx: ^2.7.0           # PDF rendering from HTTP URI (range-request capable)
  share_plus: ^10.0.0    # Platform share sheet
  http: ^1.2.0           # Simple HTTP GET for PDF download (already likely present)
```

Do NOT add `syncfusion_flutter_pdfviewer` (heavy, commercial license required).

---

## Offline / Connectivity UX

- If `hbpClientProvider` reports `disconnected` state, show a persistent amber banner at the top: `"Pi 5 offline — Resume data unavailable"`.
- Editor tabs show cached data (last successful load from Riverpod state) with a `[Offline]` badge on the app bar.
- Compile button is disabled when offline with tooltip: `"Connect to Pi 5 to compile"`.

---

## Acceptance Criteria

- [ ] `/resume` tab shell loads with Editor / Compile / History tabs
- [ ] Basics tab displays Joshua B. Ygot profile data fetched from `shua_resume`
- [ ] Editing a work item auto-saves after 800ms; green check animation fires; RPC confirms persist
- [ ] Swipe-to-dismiss on a work item deletes it optimistically then confirms via RPC
- [ ] Pasting a JD updates `JaccardScoreGauge` within 500ms via client-side Dart Jaccard (no RPC)
- [ ] Jaccard gauge color transitions: red < 30%, amber 30–60%, green > 60%
- [ ] "Compile PDF" dispatches `resume.compile` RPC; `CompileProgressOverlay` shows elapsed time
- [ ] Compiled PDF renders in `pdfx` viewer loaded from vault URL `http://{pi5}:7702/vault/resume/...`
- [ ] Download button saves PDF to `getDownloadsDirectory()` (Windows) / `getExternalStorageDirectory()` (Android)
- [ ] All 3 templates selectable in picker and correctly passed to compile RPC
- [ ] Offline banner appears when HBP client disconnects; compile button disables
- [ ] `flutter analyze` — 0 errors, 0 warnings
