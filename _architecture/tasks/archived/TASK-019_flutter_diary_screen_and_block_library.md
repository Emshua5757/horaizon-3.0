# TASK-019 — `client_flutter` Diary Screen & Native Block Widget Library

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/diary/` |
| **Blocks** | Nothing |
| **Prerequisites** | TASK-010 (GoRouter & Material 3 theme), TASK-017 (`shua_diary` Data API), TASK-018 (AI Session), ADR-001 |
| **References** | `_architecture/decisions/ADR-001_native_over_sdui.md`, `_architecture/reference/old schema/sdui_spec.json`, `_architecture/reference/shua_diary.md` |

---

## Architectural Directives (READ BEFORE WRITING A SINGLE LINE)

> [!IMPORTANT]
> **ADR-001 is LAW**: All UI is 100% native Flutter Dart widgets. Zero SDUI hydration, zero blueprint parsing.
>
> **What the horAIzon 2.0 SDUI blocks become in v3.0:**
> - In 2.0, `SduiBlockRegistry` held 40 widget type IDs. The server sent blueprint JSON and the client rendered it dynamically.
> - In 3.0, every block type becomes a **hardcoded native Dart widget** inside `lib/features/diary/widgets/blocks/`.
> - The backend (`shua_diary`) stores `block_type` as a string in SQLite (`diary_blocks.block_type`). The Flutter client reads this string and renders the corresponding `DiaryBlockWidget` subclass. That's it. No dynamic hydration engine.
>
> **Block type string values** (stored in `diary_blocks.block_type` column) map to:

| `block_type` string | Native Flutter Widget Class | Notes |
| :--- | :--- | :--- |
| `markdown` | `DiaryMarkdownBlock` | Rich text / Markdown paragraph |
| `code` | `DiaryCodeBlock` | Syntax-highlighted code snippet |
| `button` | `DiaryButtonBlock` | Tappable action button |
| `checkbox` | `DiaryCheckboxBlock` | Checklist item with toggle |
| `chip` | `DiaryChipBlock` | Tag / metadata chip |
| `container` | `DiaryContainerBlock` | Styled card / box container |
| `grid` | `DiaryGridBlock` | Multi-column grid layout |
| `list_editor` | `DiaryListEditorBlock` | Editable bullet/numbered list |
| `list_view` | `DiaryListViewBlock` | Scrollable list of items |
| `ordinal_slider` | `DiaryOrdinalSliderBlock` | Star or segmented mood/energy rating |
| `slider` | `DiarySliderBlock` | Continuous value slider |
| `progress` | `DiaryProgressBlock` | Linear / circular progress bar |
| `radio` | `DiaryRadioBlock` | Single-select radio group |
| `shimmer` | `DiaryShimmerBlock` | Skeleton loading placeholder |
| `table` | `DiaryTableBlock` | Structured data table |
| `text_input` | `DiaryTextInputBlock` | Single/multi-line text field |
| `toggle` | `DiaryToggleBlock` | Boolean switch/toggle |
| `heatmap` | `DiaryHeatmapBlock` | Activity / mood heatmap grid |
| `map` | `DiaryMapBlock` | GPS location / map pin |
| `drawing` | `DiaryDrawingBlock` | Canvas sketch / handwriting pad |
| `audio` | `DiaryAudioBlock` | Voice note / audio player |
| `video` | `DiaryVideoBlock` | Video clip player |
| `image` | `DiaryImageBlock` | Pi 5 Media Vault image viewer |
| `stl` | `DiarySTLBlock` | 3D STL mesh preview |
| `chart` | `DiaryChartBlock` | Line / bar / pie chart |
| `gauge` | `DiaryGaugeBlock` | Circular metric gauge |
| `timeline` | `DiaryTimelineBlock` | Chronological event timeline |
| `document` | `DiaryDocumentBlock` | PDF / file attachment viewer |
| `carousel` | `DiaryCarouselBlock` | Multi-image slide carousel |
| `html` | `DiaryHtmlBlock` | Sanitized HTML content |
| `date_picker` | `DiaryDatePickerBlock` | Date selection widget |
| `time_picker` | `DiaryTimePickerBlock` | Time selector widget |
| `divider` | `DiaryDividerBlock` | Visual horizontal separator |
| `spacer` | `DiarySpacerBlock` | Layout spacing |
| `expansion` | `DiaryExpansionBlock` | Collapsible accordion section |
| `wrap` | `DiaryWrapBlock` | Auto-wrapping flow container |

> [!NOTE]
> **Excluded from diary blocks** (these belong to the Flutter app shell, not diary content):
> - `Terminal` → `client_flutter` app-level `TerminalScreen` (for governor log output display).
> - `Dropdown` → Used as a Flutter widget inside forms (e.g. settings), not a diary block.
> - `ModuleCard` → Used in `DashboardScreen` for module launcher cards.
> - `HyperGraph` → Lives in `code_visualizer` feature screen (TASK-016), not diary.

---

## Block Picker Screen (Block Gallery)

> [!NOTE]
> The user explicitly requests a **Block Picker / Block Gallery** feature — a dedicated UI screen or bottom sheet showing all available block types grouped by category. When adding a block to a diary entry, the user selects from this gallery rather than typing a command.

**`DiaryBlockPickerBottomSheet`** (`lib/features/diary/widgets/block_picker.dart`):
- Displays all 36 diary block types in a `GridView` grouped by category tabs.
- Categories: `Text & Input`, `Layout`, `Controls`, `Media`, `Data & Charts`, `Misc`.
- Tapping a block type inserts a new block of that type at the cursor position in the editor.

---

## Screen Architecture (`lib/features/diary/`)

```
lib/features/diary/
├── diary_list_screen.dart          # Entry list: search, mood filter, heatmap row
├── diary_editor_screen.dart        # Vertical ReorderableListView of DiaryBlockWidgets
├── widgets/
│   ├── block_picker.dart           # Block Picker gallery bottom sheet (36 types)
│   ├── ai_assistant_drawer.dart    # AI chat drawer (JBC mutations, entry generation)
│   └── blocks/
│       ├── diary_block_widget.dart # Abstract base DiaryBlockWidget class
│       ├── diary_markdown_block.dart
│       ├── diary_code_block.dart
│       ├── diary_button_block.dart
│       ├── diary_checkbox_block.dart
│       ├── diary_chip_block.dart
│       ├── diary_container_block.dart
│       ├── diary_grid_block.dart
│       ├── diary_list_editor_block.dart
│       ├── diary_list_view_block.dart
│       ├── diary_ordinal_slider_block.dart
│       ├── diary_slider_block.dart
│       ├── diary_progress_block.dart
│       ├── diary_radio_block.dart
│       ├── diary_shimmer_block.dart
│       ├── diary_table_block.dart
│       ├── diary_text_input_block.dart
│       ├── diary_toggle_block.dart
│       ├── diary_heatmap_block.dart
│       ├── diary_map_block.dart
│       ├── diary_drawing_block.dart
│       ├── diary_audio_block.dart
│       ├── diary_video_block.dart
│       ├── diary_image_block.dart
│       ├── diary_stl_block.dart
│       ├── diary_chart_block.dart
│       ├── diary_gauge_block.dart
│       ├── diary_timeline_block.dart
│       ├── diary_document_block.dart
│       ├── diary_carousel_block.dart
│       ├── diary_html_block.dart
│       ├── diary_date_picker_block.dart
│       ├── diary_time_picker_block.dart
│       ├── diary_divider_block.dart
│       ├── diary_spacer_block.dart
│       ├── diary_expansion_block.dart
│       └── diary_wrap_block.dart
└── providers/
    ├── diary_list_provider.dart    # AsyncNotifier fetching entry list from shua_diary API
    ├── active_entry_provider.dart  # Active entry blocks + local edit state + LexoRank reorder
    └── diary_search_provider.dart  # Full-text search query state
```

---

## Data Contract with `shua_diary` Backend

The Flutter client consumes plain JSON DTOs from `shua_diary` over WebSocket/HBP v2.

### `DiaryEntryDto`
```json
{
  "id": "uuid",
  "title": "string",
  "mood": "number | null",
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string"
}
```

### `DiaryBlockDto`
```json
{
  "id": "uuid",
  "entry_id": "uuid",
  "block_type": "string",
  "content": "string (JSON-encoded block data)",
  "lexo_rank": "string",
  "version": "integer"
}
```

The `content` field is a JSON string whose schema is specific to each `block_type`. The Flutter `DiaryBlockWidget` subclass for that `block_type` owns the schema of its own `content` field.

> [!NOTE]
> **Simultaneous Multi-Device Conflict Handling**:
> - The client always sends `version` on `diary.block.save`.
> - If the server responds with `{ error: 'conflict', latest: DiaryBlockDto }`, the `active_entry_provider` must refresh that block from `latest` and can optionally show a snackbar: *"Block updated from another device."*
> - This is a simple optimistic lock — no CRDT, no Lamport clocks, no offline queue.

---

## Acceptance Criteria

- [ ] `DiaryListScreen` displays entry list with mood filter and heatmap row
- [ ] `DiaryEditorScreen` renders all 36 block types from the type table above
- [ ] `DiaryBlockPickerBottomSheet` shows all 36 block types in a gallery with group tabs
- [ ] Re-ordering blocks sends LexoRank updates to `shua_diary` WebSocket API
- [ ] Media blocks (`image`, `audio`, `video`) fetch from Pi 5 Media Vault
- [ ] AI assistant drawer sends prompt to TASK-018 JBC endpoint and applies block mutations
- [ ] `0` Dart analysis errors or lint warnings (`flutter analyze`)
