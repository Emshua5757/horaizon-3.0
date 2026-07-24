# Repository Export

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\trait_map.rs (76 lines)

#### TraitMap (Struct)
```rust
// Lines 5-7 (3 LOC | Complexity 1) | used by 2 callers
pub struct TraitMap
//  â³ Called by: extract_trait_map, DebugReport
```

#### extract_trait_map (Function)
```rust
// Lines 9-81 (73 LOC | Complexity 19) | used by 1 callers | [MutatesState, Io, CanPanic]
pub fn extract_trait_map(state: &AppState) -> TraitMap
//  â³ Calls: TraitMap, AppState, get_parser, detect_language
//  â³ Called by: debug_analysis
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\settings_page.dart (341 lines)

#### SettingsPage.build (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### _NetworkConfigCardState._saveSettings (Function)
```rust
// Lines 208-208 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveSettings()
//  â³ Called by: _NetworkConfigCardState
```

#### _NetworkConfigCardState (Class)
```rust
// Lines 180-335 (156 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _NetworkConfigCardState extends ConsumerState<_NetworkConfigCard>
//  â³ Calls: _NetworkConfigCard, _NetworkConfigCardState._saveSettings, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, ShuaDiaryBlocks.content, SduiFlexContext.of, ConfigNotifier.updateWorkspaceRoot, ConfigNotifier.updateGeminiApiKey, ConfigNotifier.updateOllamaModel, ConfigNotifier.updateOllamaUrl, ConfigNotifier.updateSyncBaseUrl, dispose, ConfigProvider.geminiApiKey, initState
//  â³ Called by: _NetworkConfigCard.createState
```

#### SettingsPage (Class)
```rust
// Lines 6-171 (166 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SettingsPage extends ConsumerWidget
//  â³ Calls: ThemeNotifier.updatePrimary, ThemeNotifier.updateSecondary, _NetworkConfigCard, ThemeNotifier.updateTextScale, ThemeNotifier.updateAnimationMs, SettingsPage._buildColorSwatch, AppThemeSeeds, ThemeNotifier.toggleBrightness, ShuaDiaryEntries.title, SduiFlexContext.of, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding
```

#### _NetworkConfigCardState.initState (Function)
```rust
// Lines 188-188 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _NetworkConfigCardState.build (Function)
```rust
// Lines 225-225 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SettingsPage._buildColorSwatch (Function)
```rust
// Lines 125-131 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildColorSwatch(
//  â³ Called by: SettingsPage
```

#### _NetworkConfigCard (Class)
```rust
// Lines 173-178 (6 LOC | Complexity 1) | used by 3 callers
class _NetworkConfigCard extends ConsumerStatefulWidget
//  â³ Called by: _NetworkConfigCardState, _NetworkConfigCard.createState, SettingsPage
```

#### _NetworkConfigCard.createState (Function)
```rust
// Lines 177-177 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_NetworkConfigCard> createState()
//  â³ Calls: _NetworkConfigCard, _NetworkConfigCardState
```

#### _NetworkConfigCardState.dispose (Function)
```rust
// Lines 199-199 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_map.dart (266 lines)

#### SduiMap.createState (Function)
```rust
// Lines 21-21 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiMap> createState()
//  â³ Calls: SduiMap, _SduiMapState
```

#### _SduiMapState.build (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiMapState.initState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiMapState (Class)
```rust
// Lines 24-270 (247 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiMapState extends ConsumerState<SduiMap>
//  â³ Calls: SduiMap, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onStateChange, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiMapState._buildMarkers, _SduiMapState._parseCoordinates, SduiNode.contentVal, SduiNode.behavior, ShuaDiaryBlocks.content, SduiFlexContext.of, SduiEventDispatcher.onAction, SduiIconRegistry, dispose, initState
//  â³ Called by: SduiMap.createState
```

#### _SduiMapState._buildMarkers (Function)
```rust
// Lines 75-75 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<Marker> _buildMarkers(BuildContext context, dynamic rawData, ThemeData theme, ColorScheme colorScheme)
//  â³ Called by: _SduiMapState
```

#### _SduiMapState.dispose (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiMap (Class)
```rust
// Lines 10-22 (13 LOC | Complexity 1) | used by 3 callers
class SduiMap extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiMapState, SduiMap.createState, SduiTypeRegistry
```

#### _SduiMapState._parseCoordinates (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
LatLng? _parseCoordinates(dynamic value)
//  â³ Called by: _SduiMapState
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\diary_ai_session.ts (95 lines)

#### DiaryAiSession.create (Function)
```rust
// Lines 40-73 (34 LOC | Complexity 5) | used by 5 callers | [MutatesState, Io, Tested]
static create(config: AiProviderConfig, socket: Socket): DiaryAiSession
//  â³ Calls: IAnalyzerProvider, IJbcChatProvider, IDiaryGeneratorProvider, AiProviderConfig, DiaryAiSession, AnalysisWorker, N8nJbcProvider, OllamaAnalyzerProvider, PythonSemanticsAnalyzerProvider, OllamaJbcProvider, OllamaGeneratorProvider, GeminiAnalyzerProvider, GeminiJbcProvider, GeminiGeneratorProvider
//  â³ Called by: SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, process_upload_bytes, checkAndSynthesizeForUser, SaveAiConfigHandler.handle
```

#### AiProviderConfig (Interface)
```rust
// Lines 19-27 (9 LOC | Complexity 1) | used by 1 callers
interface AiProviderConfig
//  â³ Called by: DiaryAiSession.create
```

#### DiaryAiSession.constructor (Function)
```rust
// Lines 33-38 (6 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
constructor(
//  â³ Calls: AnalysisWorker, IAnalyzerProvider, IJbcChatProvider, IDiaryGeneratorProvider
```

#### DiaryAiSession (Class)
```rust
// Lines 29-74 (46 LOC | Complexity 1) | used by 4 callers
class DiaryAiSession
//  â³ Calls: AiRateLimiter
//  â³ Called by: SduiOrchestrator.updateSession, SduiOrchestrator, SduiRpcContext, DiaryAiSession.create
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\debug.rs (25 lines)

#### DebugReport (Struct)
```rust
// Lines 9-14 (6 LOC | Complexity 1) | used by 1 callers
pub struct DebugReport
//  â³ Calls: TraitMap, RouteNode, BoundaryViolation, GhostImportReport
//  â³ Called by: debug_analysis
```

#### debug_analysis (Function)
```rust
// Lines 16-34 (19 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn debug_analysis(State(state): State<AppState>) -> Json<DebugReport>
//  â³ Calls: DebugReport, AppState, extract_trait_map, extract_api_routes, find_boundary_violations, find_ghost_imports, assign_tags, detect_cycles, compute_centrality
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\routes_map.rs (185 lines)

#### RouteNode (Struct)
```rust
// Lines 17-22 (6 LOC | Complexity 1) | used by 0 callers
pub struct RouteNode
//  â³ Calls: HttpMethod, RouteNode
```

#### extract_api_routes (Function)
```rust
// Lines 24-194 (171 LOC | Complexity 43) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn extract_api_routes(state: &AppState) -> Vec<RouteNode>
//  â³ Calls: RouteNode, AppState, SduiIconRegistry.contains, RadixTrie.insert, get_parser, detect_language
//  â³ Called by: debug_analysis, run_full_scan
```

#### HttpMethod (Enum)
```rust
// Lines 7-14 (8 LOC | Complexity 1) | used by 1 callers
pub enum HttpMethod
//  â³ Called by: RouteNode
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\test_inference.py (88 lines)

#### main (Function)
```rust
// Lines 20-107 (88 LOC | Complexity 8) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, ShuaDiaryEntries.title, plot, find_latest_weights
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\gemini_jbc_provider.ts (640 lines)

#### GeminiJbcProvider.resolvePositionalRefs (Function)
```rust
// Lines 297-333 (37 LOC | Complexity 5) | used by 1 callers | [Pure, TraitMethod]
private resolvePositionalRefs(prompt: string, blocks: any[]): string
//  â³ Called by: GeminiJbcProvider.compileJbc
```

#### GeminiJbcProvider.generateSummary (Function)
```rust
// Lines 251-292 (42 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(entryContent: string, entryTitle: string): Promise<string>
//  â³ Calls: AiRateLimiter.execute, test, filter, Error
```

#### GeminiJbcProvider (Class)
```rust
// Lines 6-334 (329 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class GeminiJbcProvider implements IJbcChatProvider
//  â³ Calls: IJbcChatProvider
//  â³ Called by: DiaryAiSession.create
```

#### GeminiJbcProvider.compileJbc (Function)
```rust
// Lines 16-114 (99 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot, JbcTranslator.translate, JbcTranslator.parse, AiRateLimiter.execute, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, JbcTranslator.serializeDiaryState, GeminiJbcProvider.resolvePositionalRefs, Error
```

#### GeminiJbcProvider.constructor (Function)
```rust
// Lines 7-11 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: AiRateLimiter
```

#### GeminiJbcProvider.presentJbcStream (Function)
```rust
// Lines 119-246 (128 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult, JbcTranslator.parse, AiRateLimiter.execute, JbcTranslator.serializeDiaryState, ShuaDiaryBlocks.content, Error
```

### C:\horAIzon_2.0\sdui3\sdui\sdui_registry.dart (1142 lines)

#### SduiRegistry._buildQuote (Function)
```rust
// Lines 595-595 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildQuote(String? id, Map<int, dynamic>? content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildShimmerLoader (Function)
```rust
// Lines 997-997 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildShimmerLoader(String? id, Map<int, dynamic>? behavior)
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildContainer (Function)
```rust
// Lines 855-859 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildContainer(
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildButton (Function)
```rust
// Lines 734-738 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildButton(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildCheckbox (Function)
```rust
// Lines 648-648 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildCheckbox(String? id, Map<int, dynamic>? content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._resolveEdgeInsets (Function)
```rust
// Lines 1033-1033 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static EdgeInsetsGeometry _resolveEdgeInsets(dynamic val)
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildToggle (Function)
```rust
// Lines 397-397 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildToggle(String? id, Map<int, dynamic>? content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildOrdinalSlider (Function)
```rust
// Lines 173-177 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildOrdinalSlider(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildCodeEditor (Function)
```rust
// Lines 612-616 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildCodeEditor(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildRadio (Function)
```rust
// Lines 677-677 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildRadio(String? id, Map<int, dynamic>? content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildListView (Function)
```rust
// Lines 906-910 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildListView(
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildHeading (Function)
```rust
// Lines 563-567 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildHeading(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry (Class)
```rust
// Lines 9-1057 (1049 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiRegistry
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState.shimmerAnimStyle, _SduiShimmerLoaderState.shimmerType, SduiGridView, SduiListView, SduiBlockRegistry.all, SduiProgressBar, ProgressMode, _SduiShimmerLoaderState.borderRadius, SduiContainer, SduiIconRegistry.contains, LogEntry::from, SduiRegistry.buildNode, SduiButton, SduiFlexContext.of, SduiRadio, SduiCheckbox, SduiCodeEditor, SduiQuote, SduiHeading, SduiMarkdownEditor, SduiTextInput, SduiIconButton, SduiChip, ChipMode, SduiToggle, SduiSlider, SliderMode, ShuaDiaryEntries.title, SduiTable, SduiListEditor, SduiIconRegistry.resolveOrNull, SduiIconRegistry, BulletStyle, ListStyle, SduiEventType, SduiEvent.recycled, SduiEvent, SduiEventDispatcher.dispatch, SduiEventDispatcher, SduiOrdinalSlider, SduiRegistry._resolveEdgeInsets, _SduiShimmerLoaderState.padding, SduiRegistry._buildListEditor, SduiRegistry._buildTable, SduiRegistry._buildShimmerLoader, SduiRegistry._buildProgressBar, SduiKeyboardType, SduiRegistry._buildTextInput, SduiRegistry._buildIconButton, SduiRegistry._buildChip, SduiRegistry._buildGridView, SduiRegistry._buildListView, SduiRegistry._buildContainer, SduiRegistry._buildRow, SduiRegistry._buildColumn, SduiRegistry._buildToggle, SduiRegistry._buildSlider, SduiRegistry._buildOrdinalSlider, SduiRegistry._buildRadio, SduiRegistry._buildCheckbox, SduiRegistry._buildCodeEditor, SduiRegistry._buildButton, SduiRegistry._buildIcon, SduiRegistry._buildQuote, SduiRegistry._buildHeading, SduiRegistry._buildMarkdownEditor, ShuaDiaryBlocks.content, SduiNode.behavior, BoundedRouteHistory.isEmpty
```

#### SduiRegistry._buildMarkdownEditor (Function)
```rust
// Lines 535-539 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildMarkdownEditor(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildGridView (Function)
```rust
// Lines 949-953 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildGridView(
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildTable (Function)
```rust
// Lines 285-289 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildTable(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildIcon (Function)
```rust
// Lines 706-710 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildIcon(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildChip (Function)
```rust
// Lines 417-421 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildChip(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildProgressBar (Function)
```rust
// Lines 889-893 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildProgressBar(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildSlider (Function)
```rust
// Lines 320-324 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildSlider(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildRow (Function)
```rust
// Lines 792-795 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildRow(
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry
```

#### SduiRegistry.buildNode (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget buildNode(Map<int, dynamic> node)
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildColumn (Function)
```rust
// Lines 770-770 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildColumn(List<dynamic>? childrenData, {Map<int, dynamic>? behavior})
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildListEditor (Function)
```rust
// Lines 236-240 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildListEditor(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildIconButton (Function)
```rust
// Lines 458-462 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildIconButton(
//  â³ Calls: SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

#### SduiRegistry._buildTextInput (Function)
```rust
// Lines 493-498 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
static Widget _buildTextInput(
//  â³ Calls: SduiKeyboardType, SduiNode.behavior, ShuaDiaryBlocks.content
//  â³ Called by: SduiRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\sdui_sandbox_screen.dart (291 lines)

#### _SduiSandboxScreenState._loadAll (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadAll()
//  â³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState.initState (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiSandboxScreenState._parseLegacyV4Format (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode _parseLegacyV4Format(Map<String, dynamic> map)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiSandboxScreenState
```

#### SduiSandboxScreen (Class)
```rust
// Lines 8-13 (6 LOC | Complexity 1) | used by 0 callers
class SduiSandboxScreen extends ConsumerStatefulWidget
//  â³ Calls: SduiSandboxScreen
```

#### _SduiSandboxScreenState._loadBlueprints (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Future<List<MapEntry<String, SduiNode>>> _loadBlueprints()
//  â³ Calls: SduiNode, _loadBlueprints
```

#### _SduiSandboxScreenState._buildBody (Function)
```rust
// Lines 159-159 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildBody(SduiEventDispatcher dispatcher)
//  â³ Calls: SduiEventDispatcher
//  â³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState (Class)
```rust
// Lines 15-291 (277 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiSandboxScreenState extends ConsumerState<SduiSandboxScreen>
//  â³ Calls: SduiSandboxScreen, generate, SduiFlexContext.of, SduiTypeRegistry, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiSandboxScreenState._buildBody, BoundedRouteHistory.isEmpty, ShuaDiaryEntries.title, c, ShuaDiaryBlocks.content, _SduiSandboxScreenState._parseIntMap, SduiNode, _SduiSandboxScreenState._parseLegacyV4Format, LogEntry::from, _loadBlueprints, _SduiSandboxScreenState._loadAll, initState
//  â³ Called by: SduiSandboxScreen.createState, SduiSandboxScreen, SduiSandboxScreen.createState
```

#### _SduiSandboxScreenState.build (Function)
```rust
// Lines 109-109 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiSandboxScreenState._parseIntMap (Function)
```rust
// Lines 83-83 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
dynamic _parseIntMap(dynamic value)
//  â³ Called by: _SduiSandboxScreenState
```

#### SduiSandboxScreen.createState (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSandboxScreen> createState()
//  â³ Calls: SduiSandboxScreen, _SduiSandboxScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\media_uploader.dart (552 lines)

#### MediaUploader.uploadFile (Function)
```rust
// Lines 107-111 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> uploadFile(
//  â³ Calls: MediaUploadResult
//  â³ Called by: MediaUploader
```

#### MediaUploader._deterministicId (Function)
```rust
// Lines 407-407 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _deterministicId(String filename, int size)
//  â³ Called by: MediaUploader
```

#### MediaUploadResult (Class)
```rust
// Lines 31-47 (17 LOC | Complexity 1) | used by 5 callers
class MediaUploadResult
//  â³ Calls: N8nAssistantProvider.baseUrl, MediaUploader
//  â³ Called by: MediaUploader._chunkedUpload, MediaUploader._simpleUpload, MediaUploader.uploadBytes, MediaUploader.uploadFile, MediaUploader
```

#### MediaUploader (Class)
```rust
// Lines 99-569 (471 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class MediaUploader
//  â³ Calls: dispose, SduiEventDispatcher.onStateChange, MediaUploader.uploadFile, ShuaDiaryBlocks.content, ShuaDiaryEntries.title, SduiFlexContext.of, MediaUploader._showError, c, UploadProgressEvent, DiaryRepository.close, MediaUploader._listenToSseProgress, MediaUploadException, MediaUploader._deterministicId, MediaUploadResult, MediaUploader._assertStatus, Response, MediaUploader._inferMime, MediaUploader._chunkedUpload, MediaUploader._simpleUpload, log, N8nAssistantProvider.baseUrl
//  â³ Called by: MediaUploadResult
```

#### MediaUploader._inferMime (Function)
```rust
// Lines 418-418 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _inferMime(String filename)
//  â³ Called by: MediaUploader
```

#### MediaUploader._assertStatus (Function)
```rust
// Lines 382-382 (1 LOC | Complexity 1) | used by 1 callers | [Io]
void _assertStatus(http.Response response)
//  â³ Calls: Response
//  â³ Called by: MediaUploader
```

#### MediaUploadException.toString (Function)
```rust
// Lines 73-73 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
String toString()
```

#### MediaUploader._chunkedUpload (Function)
```rust
// Lines 211-216 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> _chunkedUpload(
//  â³ Calls: MediaUploadResult
//  â³ Called by: MediaUploader
```

#### MediaUploadException (Class)
```rust
// Lines 67-74 (8 LOC | Complexity 1) | used by 1 callers
class MediaUploadException implements Exception
//  â³ Called by: MediaUploader
```

#### MediaUploader._simpleUpload (Function)
```rust
// Lines 167-173 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> _simpleUpload(
//  â³ Calls: MediaUploadResult
//  â³ Called by: MediaUploader
```

#### UploadProgressEvent (Class)
```rust
// Lines 49-61 (13 LOC | Complexity 1) | used by 2 callers
class UploadProgressEvent
//  â³ Called by: MediaUploader._listenToSseProgress, MediaUploader
```

#### MediaUploader._showError (Function)
```rust
// Lines 560-560 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showError(BuildContext context, String message)
//  â³ Called by: MediaUploader
```

#### MediaUploader.pickAndUploadWithUi (Function)
```rust
// Lines 438-446 (9 LOC | Complexity 1) | used by 5 callers | [Pure]
Future<void> pickAndUploadWithUi(
//  â³ Calls: SduiEventDispatcher
//  â³ Called by: _SduiHtmlViewerState, _SduiVideoState, _SduiAudioState, SduiImage, _SduiDocumentViewerState
```

#### MediaUploader.uploadBytes (Function)
```rust
// Lines 140-146 (7 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Future<MediaUploadResult> uploadBytes(
//  â³ Calls: MediaUploadResult
```

#### MediaUploader._listenToSseProgress (Function)
```rust
// Lines 322-325 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
void _listenToSseProgress(
//  â³ Calls: UploadProgressEvent
//  â³ Called by: MediaUploader
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_ordinal_slider.dart (310 lines)

#### _SduiOrdinalSliderState._labelFor (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _labelFor(double rating)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState._resolveIcon (Function)
```rust
// Lines 103-103 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
static IconData _resolveIcon(String name, IconVariant variant)
//  â³ Calls: IconVariant
//  â³ Called by: _SduiOrdinalSliderState, SduiIconNode, SduiNode, SduiNode.resolveIcon
```

#### SduiOrdinalSlider.createState (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiOrdinalSlider> createState()
//  â³ Calls: SduiOrdinalSlider, _SduiOrdinalSliderState
```

#### IconVariant (Enum)
```rust
// Lines 319-319 (1 LOC | Complexity 1) | used by 2 callers
enum IconVariant { filled, half, empty }
//  â³ Called by: _SduiOrdinalSliderState._resolveIcon, _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState.initState (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiOrdinalSliderState._handleTap (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _handleTap(int index, double tapX, double iconSize)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState._iconFor (Function)
```rust
// Lines 89-89 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IconData _iconFor(int index, double activeRating)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState.didUpdateWidget (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiOrdinalSlider oldWidget)
//  â³ Calls: SduiOrdinalSlider
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState.build (Function)
```rust
// Lines 137-137 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiOrdinalSliderState (Class)
```rust
// Lines 50-317 (268 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class _SduiOrdinalSliderState extends State<SduiOrdinalSlider>
//  â³ Calls: SduiOrdinalSlider, _SduiShimmerLoaderState.borderRadius, _SduiOrdinalSliderState._labelFor, _SduiOrdinalSliderState._handleTap, _SduiOrdinalSliderState._iconFor, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, generate, SduiFlexContext.of, IconVariant, _SduiOrdinalSliderState._resolveIcon, _SduiOrdinalSliderState.didUpdateWidget, initState, _SduiOrdinalSliderState
```

#### SduiOrdinalSlider (Class)
```rust
// Lines 16-48 (33 LOC | Complexity 1) | used by 0 callers
class SduiOrdinalSlider extends StatefulWidget
//  â³ Calls: SduiOrdinalSlider
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\parser\markdown_parser.go (275 lines)

#### parseYAML (Function)
```rust
// Lines 272-302 (31 LOC | Complexity 11) | used by 1 callers | [MutatesState]
func parseYAML(line string, basics *models.Basics)
//  â³ Calls: Basics
//  â³ Called by: ParseMarkdown
```

#### ParseMarkdown (Function)
```rust
// Lines 27-270 (244 LOC | Complexity 72) | used by 1 callers | [MutatesState, Tested, HighComplexity]
func ParseMarkdown(mdContent string) (*models.ResumeMatrix, error)
//  â³ Calls: Award, Certificate, Skill, ProjectItem, Education, WorkItem, ResumeMatrix, parseYAML
//  â³ Called by: TestParseMarkdown
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_chip.dart (78 lines)

#### SduiChip.build (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### SduiChip (Class)
```rust
// Lines 8-84 (77 LOC | Complexity 1) | used by 6 callers
class SduiChip extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiEventDispatcher.onStateChange, SduiEventDispatcher.onAction, SduiIconRegistry, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior
//  â³ Called by: _SduiChipState.didUpdateWidget, _SduiChipState, SduiChip.createState, SduiChip, SduiRegistry, SduiTypeRegistry
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_markdown_editor.dart (147 lines)

#### _SduiMarkdownEditorState._onTextChanged (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState.initState (Function)
```rust
// Lines 30-30 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiMarkdownEditorState.build (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiMarkdownEditorState.dispose (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiMarkdownEditor (Class)
```rust
// Lines 4-22 (19 LOC | Complexity 1) | used by 0 callers
class SduiMarkdownEditor extends StatefulWidget
//  â³ Calls: SduiMarkdownEditor
```

#### _SduiMarkdownEditorState.didUpdateWidget (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiMarkdownEditor oldWidget)
//  â³ Calls: SduiMarkdownEditor
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState (Class)
```rust
// Lines 24-145 (122 LOC | Complexity 1) | used by 0 callers
class _SduiMarkdownEditorState extends State<SduiMarkdownEditor>
//  â³ Calls: SduiMarkdownEditor, SduiNode.behavior, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, _SduiMarkdownEditorState._onTextChanged, SduiFlexContext.of, dispose, _SduiMarkdownEditorState.didUpdateWidget, initState, _SduiMarkdownEditorState
```

#### SduiMarkdownEditor.createState (Function)
```rust
// Lines 21-21 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiMarkdownEditor> createState()
//  â³ Calls: SduiMarkdownEditor, _SduiMarkdownEditorState
```

### C:\horAIzon_2.0\client_flutter\lib\app\auth\auth_provider.dart (77 lines)

#### AuthState (Class)
```rust
// Lines 7-29 (23 LOC | Complexity 1) | used by 5 callers
class AuthState
//  â³ Calls: DiagnosticResult, AuthStatus
//  â³ Called by: AuthNotifier.build, AuthState.copyWith, _PinEntryScreenState, _PinEntryScreenState._buildKey, AuthNotifier
```

#### AuthNotifier.build (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
AuthState build()
//  â³ Calls: AuthState, build
```

#### AuthNotifier.verifyPIN (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void verifyPIN(String pin)
//  â³ Called by: AuthNotifier
```

#### AuthNotifier.deleteDigit (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void deleteDigit()
//  â³ Called by: _PinEntryScreenState
```

#### AuthNotifier.enterDigit (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void enterDigit(String digit)
//  â³ Called by: _PinEntryScreenState
```

#### AuthNotifier (Class)
```rust
// Lines 31-74 (44 LOC | Complexity 1) | used by 1 callers
class AuthNotifier extends Notifier<AuthState>
//  â³ Calls: DiagnosticsHistoryNotifier.logResult, DiagnosticResult.failure, SystemEvents, DiagnosticResult.success, DiagnosticResult, BoundedRouteHistory.isEmpty, AuthNotifier.verifyPIN, AuthState.copyWith, AuthStatus, AuthState
//  â³ Called by: AuthStatus
```

#### AuthStatus (Enum)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 4 callers
enum AuthStatus { unauthenticated, authenticating, authenticated, error }
//  â³ Calls: AuthNotifier
//  â³ Called by: AuthState.copyWith, AuthState, AuthNotifier, _PinEntryScreenState
```

#### AuthState.copyWith (Function)
```rust
// Lines 18-22 (5 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
AuthState copyWith(
//  â³ Calls: DiagnosticResult, AuthStatus, AuthState
//  â³ Called by: AuthNotifier
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_table.dart (284 lines)

#### _SduiTableState._addRow (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _addRow()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._parseContent (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseContent()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._removeRow (Function)
```rust
// Lines 133-133 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _removeRow()
//  â³ Called by: _SduiTableState
```

#### SduiTable.createState (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiTable> createState()
//  â³ Calls: SduiTable, _SduiTableState
```

#### _SduiTableState._startCellEdit (Function)
```rust
// Lines 91-91 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _startCellEdit(int row, int col)
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._removeColumn (Function)
```rust
// Lines 141-141 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _removeColumn()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.didUpdateWidget (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiTable oldWidget)
//  â³ Calls: SduiTable
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._saveMatrix (Function)
```rust
// Lines 86-86 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveMatrix()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.dispose (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiTableState.initState (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiTableState.build (Function)
```rust
// Lines 152-152 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiTableState._saveCellEdit (Function)
```rust
// Lines 102-102 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveCellEdit()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._addColumn (Function)
```rust
// Lines 125-125 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _addColumn()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState (Class)
```rust
// Lines 25-274 (250 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class _SduiTableState extends State<SduiTable>
//  â³ Calls: SduiTable, _SduiShimmerLoaderState.padding, _SduiTableState._startCellEdit, generate, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiTableState._addColumn, _SduiTableState._removeColumn, _SduiTableState._addRow, _SduiTableState._removeRow, RadixTrie.remove, ShuaDiaryEntries.title, SduiFlexContext.of, _SduiTableState._saveMatrix, BoundedRouteHistory.isEmpty, dispose, _SduiTableState.didUpdateWidget, _SduiTableState._saveCellEdit, _SduiTableState._parseContent, initState, _SduiTableState
```

#### SduiTable (Class)
```rust
// Lines 3-23 (21 LOC | Complexity 1) | used by 0 callers
class SduiTable extends StatefulWidget
//  â³ Calls: ShuaDiaryEntries.title, SduiTable
```

### C:\horAIzon_2.0\scripts\search_gmail.py (177 lines)

#### decode_str (Function)
```rust
// Lines 38-49 (12 LOC | Complexity 4) | used by 1 callers | [Pure]
def decode_str(raw) -> str
//  â³ Calls: main
//  â³ Called by: fetch_emails
```

#### _HTMLTextExtractor.handle_endtag (Function)
```rust
// Lines 63-68 (6 LOC | Complexity 3) | used by 0 callers | [MutatesState, PotentialDeadCode]
def handle_endtag(self, tag)
```

#### search_keyword (Function)
```rust
// Lines 130-138 (9 LOC | Complexity 2) | used by 1 callers | [Pure]
def search_keyword(mail, keyword: str) -> list[str]
//  â³ Called by: main
```

#### write_results (Function)
```rust
// Lines 169-182 (14 LOC | Complexity 1) | used by 1 callers | [Pure]
def write_results(keyword: str, results: list[str]) -> str
//  â³ Called by: main
```

#### _HTMLTextExtractor.get_text (Function)
```rust
// Lines 74-78 (5 LOC | Complexity 1) | used by 1 callers | [MutatesState]
def get_text(self) -> str
//  â³ Called by: _html_to_text
```

#### _HTMLTextExtractor (Class)
```rust
// Lines 52-78 (27 LOC | Complexity 1) | used by 1 callers
class _HTMLTextExtractor(HTMLParser)
//  â³ Called by: _html_to_text
```

#### _HTMLTextExtractor.handle_starttag (Function)
```rust
// Lines 59-61 (3 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def handle_starttag(self, tag, attrs)
```

#### _html_to_text (Function)
```rust
// Lines 81-84 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
def _html_to_text(html: str) -> str
//  â³ Calls: _HTMLTextExtractor.get_text, _HTMLTextExtractor
//  â³ Called by: get_text_body
```

#### _HTMLTextExtractor.__init__ (Function)
```rust
// Lines 54-57 (4 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self)
//  â³ Calls: __init__
```

#### get_text_body (Function)
```rust
// Lines 87-112 (26 LOC | Complexity 7) | used by 1 callers | [Pure]
def get_text_body(msg) -> str
//  â³ Calls: _html_to_text, walk
//  â³ Called by: fetch_emails
```

#### format_email_block (Function)
```rust
// Lines 115-126 (12 LOC | Complexity 1) | used by 1 callers | [Pure]
def format_email_block(index: int, subject: str, sender: str,
//  â³ Called by: fetch_emails
```

#### _HTMLTextExtractor.handle_data (Function)
```rust
// Lines 70-72 (3 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def handle_data(self, data)
```

#### main (Function)
```rust
// Lines 185-210 (26 LOC | Complexity 3) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: write_results, fetch_emails, search_keyword
```

#### fetch_emails (Function)
```rust
// Lines 141-166 (26 LOC | Complexity 4) | used by 1 callers | [Io]
def fetch_emails(mail, ids: list, keyword: str) -> list[str]
//  â³ Calls: format_email_block, get_text_body, decode_str
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\semantic_search.ts (110 lines)

#### SemanticSearchHandler (Class)
```rust
// Lines 5-60 (56 LOC | Complexity 1) | used by 1 callers
class SemanticSearchHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### SemanticSearchHandler.handle (Function)
```rust
// Lines 6-59 (54 LOC | Complexity 7) | used by 0 callers | [Async, Io, CanPanic, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode, ShuaDiaryBlocks.content, ShuaDiaryBlocks.blockType, ShuaDiaryBlocks.entryId, DiaryRepository.getBlockSearchDetails, cosineSimilarity, DiaryRepository.getAllEmbeddings, getDiaryRepository, getEmbedding, Error
```

### C:\horAIzon_2.0\shua_modules\shua_diary\db_debug.py (267 lines)

#### cmd_add_entry (Function)
```rust
// Lines 215-236 (22 LOC | Complexity 1) | used by 1 callers | [Io]
def cmd_add_entry(conn)
//  â³ Calls: ok, ShuaDiaryEntries.title, now_iso, header
//  â³ Called by: c
```

#### now_iso (Function)
```rust
// Lines 55-56 (2 LOC | Complexity 1) | used by 4 callers | [Pure]
def now_iso() -> str
//  â³ Called by: cmd_set_mood, cmd_add_entry, cmd_edit_block_content, cmd_edit_title
```

#### err (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 9 callers | [Io]
def err(msg):       print(f"{RED}[XX]{RESET} {msg}")
//  â³ Called by: repl, cmd_raw_sql, cmd_set_mood, cmd_pick_entry, _JoshAutomatedGenerationDialogState, _DiaryListScreenState, _DiaryEditorContent, SduiSandboxScreen, SduiImage
```

#### cmd_schema (Function)
```rust
// Lines 260-271 (12 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_schema(conn)
//  â³ Calls: c, header
//  â³ Called by: c
```

#### repl (Function)
```rust
// Lines 317-353 (37 LOC | Complexity 8) | used by 1 callers | [Io, Cycle, Tested]
def repl()
//  â³ Calls: warn, DiaryRepository.close, ok, get_conn, c, err
//  â³ Called by: c
```

#### cmd_edit_block_content (Function)
```rust
// Lines 150-182 (33 LOC | Complexity 5) | used by 1 callers | [Io, Cycle]
def cmd_edit_block_content(conn)
//  â³ Calls: ok, now_iso, c, warn, cmd_pick_entry, header
//  â³ Called by: c
```

#### c (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 42 callers | [Pure, Cycle, CorePrimitive]
def c(text, color): return f"{color}{text}{RESET}"
//  â³ Calls: repl, cmd_raw_sql, cmd_schema, cmd_reset_all, cmd_delete_entry, cmd_add_entry, cmd_set_mood, cmd_edit_block_content, cmd_edit_title, cmd_pick_entry, cmd_list_blocks, cmd_list_entries
//  â³ Called by: _conv_block, SduiNode, repl, cmd_raw_sql, cmd_schema, cmd_delete_entry, cmd_edit_block_content, cmd_pick_entry, cmd_list_blocks, cmd_list_entries, _SduiSandboxScreenState, _conv_block, _SduiShimmerLoaderState._buildFeedRow, _SduiShimmerLoaderState._buildStatCard, _SduiShimmerLoaderState._buildChatBubble, _SduiShimmerLoaderState._buildMediaCard, _SduiShimmerLoaderState._buildListTile, _SduiShimmerLoaderState._buildParagraph, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildRectangle, load_kwh_samples, MediaUploader, SduiHeatmap, summarize, _SduiJbcPanelState, SduiImage, SduiCardNode, SduiColumnNode, SduiRowNode, SduiContainerNode, _SduiShimmerLoaderState._buildTerminalWindow, _SduiShimmerLoaderState._buildModuleCard, _SduiShimmerLoaderState._buildFeedRow, _SduiShimmerLoaderState._buildStatCard, _SduiShimmerLoaderState._buildChatBubble, _SduiShimmerLoaderState._buildMediaCard, _SduiShimmerLoaderState._buildListTile, _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildParagraph, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState._buildRectangle
```

#### warn (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 35 callers | [Io, CorePrimitive]
def warn(msg):      print(f"{YELLOW}[!!]{RESET} {msg}")
//  â³ Called by: SduiOrchestrator.handleRpc, OllamaAnalyzerProvider.analyze, repl, cmd_raw_sql, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title, cmd_pick_entry, cmd_list_blocks, cmd_list_entries, OllamaAssistantProvider.chatStream, OllamaAssistantProvider.generateTemplate, getEmbedding, SduiActionHandler.handle, AiRateLimiter.execute, GeminiAnalyzerProvider.analyze, JbcTranslator.parse, JbcTranslator.translate, AnalyzerService.analyze, uuid, GeminiRateLimiter.execute, SduiDeltaEmitter._emit, AnalysisWorker._processNext, GeminiAnalyzerProvider.analyze, SduiBlockRegistry._ensureWatcher, SduiBlockRegistry.get, JbcTranslator.parse, JbcTranslator.translate, OllamaAnalyzerProvider.analyze, GeminiAssistantProvider.chatStream, GeminiAssistantProvider.generateTemplate, checkAndSynthesizeForUser, SduiComposer.interpolate, AnalysisWorker._processNext
```

#### cmd_raw_sql (Function)
```rust
// Lines 274-296 (23 LOC | Complexity 6) | used by 1 callers | [Io, Cycle]
def cmd_raw_sql(conn)
//  â³ Calls: err, warn, c, header
//  â³ Called by: c
```

#### cmd_set_mood (Function)
```rust
// Lines 239-257 (19 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_set_mood(conn)
//  â³ Calls: ok, now_iso, err, cmd_pick_entry, header
//  â³ Called by: c
```

#### cmd_list_entries (Function)
```rust
// Lines 61-80 (20 LOC | Complexity 5) | used by 1 callers | [Io, Cycle]
def cmd_list_entries(conn)
//  â³ Calls: c, warn, header
//  â³ Called by: c
```

#### cmd_list_blocks (Function)
```rust
// Lines 83-106 (24 LOC | Complexity 4) | used by 1 callers | [Io, Cycle]
def cmd_list_blocks(conn, entry_id=None)
//  â³ Calls: c, warn, header
//  â³ Called by: c
```

#### header (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 14 callers | [Io, Tested, CorePrimitive]
def header(text):   print(f"\n{BOLD}{CYAN}{'='*60}{RESET}\n{BOLD}{CYAN}  {text}{RESET}\n{BOLD}{CYAN}{'='*60}{RESET}")
//  â³ Called by: GovernorLogger, cmd_raw_sql, cmd_schema, cmd_set_mood, cmd_add_entry, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title, cmd_list_blocks, cmd_list_entries, export_sdg, try_forward, log
```

#### cmd_edit_title (Function)
```rust
// Lines 132-147 (16 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_edit_title(conn)
//  â³ Calls: ok, now_iso, warn, cmd_pick_entry, header
//  â³ Called by: c
```

#### cmd_pick_entry (Function)
```rust
// Lines 109-129 (21 LOC | Complexity 6) | used by 5 callers | [Io, Cycle]
def cmd_pick_entry(conn) -> str | None
//  â³ Calls: err, c, warn
//  â³ Called by: c, cmd_set_mood, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title
```

#### cmd_reset_all (Function)
```rust
// Lines 201-212 (12 LOC | Complexity 2) | used by 1 callers | [Io]
def cmd_reset_all(conn)
//  â³ Calls: ok, warn, header
//  â³ Called by: c
```

#### get_conn (Function)
```rust
// Lines 46-52 (7 LOC | Complexity 1) | used by 1 callers | [Io]
def get_conn() -> sqlite3.Connection
//  â³ Calls: SduiSocketManager.connect
//  â³ Called by: repl
```

#### ok (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 25 callers | [Io, CorePrimitive]
def ok(msg):        print(f"{GREEN}[OK]{RESET} {msg}")
//  â³ Called by: repl, cmd_set_mood, cmd_add_entry, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title, main, handle_put, dav_handler, stream_logs, read_stat_fields, HbpLoggerLayer::new, flush_loop, log_min_level, run_garbage_collection, serve_file, chunk_finalize, chunk_receive, chunk_init, process_upload_bytes, is_loopback, get_console, get_dashboard, get_preactivation_sheet
```

#### cmd_delete_entry (Function)
```rust
// Lines 185-198 (14 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_delete_entry(conn)
//  â³ Calls: ok, c, cmd_pick_entry, warn, header
//  â³ Called by: c
```

### C:\horAIzon_2.0\scripts\find_all_sqlite.py (26 lines)

#### main (Function)
```rust
// Lines 3-28 (26 LOC | Complexity 7) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, walk
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_text_input.dart (197 lines)

#### _SduiTextInputState.initState (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiTextInputState._resolveKeyboardType (Function)
```rust
// Lines 107-107 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextInputType _resolveKeyboardType(int inputType)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.didUpdateWidget (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiTextInput oldWidget)
//  â³ Calls: SduiTextInput
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.build (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiTextInputState (Class)
```rust
// Lines 35-201 (167 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class _SduiTextInputState extends ConsumerState<SduiTextInput>
//  â³ Calls: SduiTextInput, _SduiTextInputState._onTextChanged, SduiIconRegistry, SduiInputType, _SduiTextInputState._resolveFormatters, _SduiTextInputState._resolveKeyboardType, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, SduiSocketManager.emitRpc, SduiEventDispatcher.onStateChange, dispose, _SduiTextInputState.didUpdateWidget, SduiNode.behavior, SduiNode.contentVal, _SduiTextInputState._bindKey, initState, _SduiTextInputState
```

#### SduiInputType (Class)
```rust
// Lines 12-19 (8 LOC | Complexity 1) | used by 1 callers
abstract final class SduiInputType
//  â³ Called by: _SduiTextInputState
```

#### SduiTextInput.createState (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiTextInput> createState()
//  â³ Calls: SduiTextInput, _SduiTextInputState
```

#### _SduiTextInputState._resolveFormatters (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<TextInputFormatter> _resolveFormatters(int inputType)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState._bindKey (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _bindKey
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.dispose (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiTextInput (Class)
```rust
// Lines 21-33 (13 LOC | Complexity 1) | used by 0 callers
class SduiTextInput extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiTextInput
```

#### _SduiTextInputState._onTextChanged (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiTextInputState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_heatmap.dart (328 lines)

#### SduiHeatmap._num (Function)
```rust
// Lines 329-329 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
double? _num(int key)
//  â³ Called by: SduiHeatmap
```

#### SduiHeatmap.build (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### SduiHeatmap (Class)
```rust
// Lines 11-334 (324 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiHeatmap extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.maxHeight, SduiHeatmap._resolveSize, SduiStyleResolver.resolveEdgeInsets, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, c, _SduiShimmerLoaderState.padding, SduiFlexContext.of, LogEntry::from, BoundedRouteHistory.isEmpty, log, SduiNode.behavior, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiHeatmap._num, SduiHeatmap._int, SduiNode.contentVal
//  â³ Called by: SduiTypeRegistry
```

#### SduiHeatmap._resolveSize (Function)
```rust
// Lines 316-316 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static double? _resolveSize(dynamic raw)
//  â³ Called by: SduiHeatmap
```

#### SduiHeatmap._int (Function)
```rust
// Lines 323-323 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
int? _int(int key)
//  â³ Called by: SduiHeatmap
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\training\analyze_ocr_dataset.py (117 lines)

#### main (Function)
```rust
// Lines 14-130 (117 LOC | Complexity 12) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, DiaryRepository.close, ShuaDiaryEntries.title
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\typescript.rs (194 lines)

#### TypeScriptExtractor::extract (Function)
```rust
// Lines 9-201 (193 LOC | Complexity 34) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

#### TypeScriptExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct TypeScriptExtractor;
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_radio.dart (119 lines)

#### SduiRadio.createState (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiRadio> createState()
//  â³ Calls: SduiRadio, _SduiRadioState
```

#### _SduiRadioState.initState (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SduiRadio (Class)
```rust
// Lines 2-20 (19 LOC | Complexity 1) | used by 0 callers
class SduiRadio extends StatefulWidget
//  â³ Calls: SduiRadio
```

#### _SduiRadioState (Class)
```rust
// Lines 22-116 (95 LOC | Complexity 1) | used by 0 callers
class _SduiRadioState extends State<SduiRadio>
//  â³ Calls: SduiRadio, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiFlexContext.of, dispose, _SduiRadioState.didUpdateWidget, initState, _SduiRadioState
```

#### _SduiRadioState.dispose (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiRadioState.didUpdateWidget (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiRadio oldWidget)
//  â³ Calls: SduiRadio
//  â³ Called by: _SduiRadioState
```

#### _SduiRadioState.build (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_governor\src\routes\media_dav.rs (317 lines)

#### DavEntry (Struct)
```rust
// Lines 94-100 (7 LOC | Complexity 1) | used by 2 callers
struct DavEntry
//  â³ Called by: handle_propfind, build_propfind_response
```

#### handle_put (Function)
```rust
// Lines 290-330 (41 LOC | Complexity 3) | used by 1 callers | [Async, Pure]
async fn handle_put(
//  â³ Calls: Response, AppState, process_upload_bytes, ok
//  â³ Called by: dav_handler
```

#### dav_handler (Function)
```rust
// Lines 106-157 (52 LOC | Complexity 8) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn dav_handler(
//  â³ Calls: Response, AppState, handle_delete, handle_put, handle_get, handle_propfind, is_loopback, ok
```

#### handle_propfind (Function)
```rust
// Lines 163-221 (59 LOC | Complexity 10) | used by 1 callers | [Async, MutatesState, Io]
async fn handle_propfind(
//  â³ Calls: DavEntry, Response, AppState, build_propfind_response
//  â³ Called by: dav_handler
```

#### html_escape (Function)
```rust
// Lines 83-88 (6 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
fn html_escape(s: &str) -> String
```

#### handle_get (Function)
```rust
// Lines 227-284 (58 LOC | Complexity 5) | used by 1 callers | [Async, Pure]
async fn handle_get(
//  â³ Calls: Response, AppState, ShuaDiaryBlocks.metadata
//  â³ Called by: dav_handler
```

#### build_propfind_response (Function)
```rust
// Lines 29-81 (53 LOC | Complexity 2) | used by 1 callers | [MutatesState]
fn build_propfind_response(entries: &[DavEntry], base_url: &str) -> String
//  â³ Calls: DavEntry
//  â³ Called by: handle_propfind
```

#### handle_delete (Function)
```rust
// Lines 336-376 (41 LOC | Complexity 5) | used by 1 callers | [Async, Io]
async fn handle_delete(
//  â³ Calls: Response, AppState
//  â³ Called by: dav_handler
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\utils\sdui_style_resolver.dart (52 lines)

#### SduiStyleResolver (Class)
```rust
// Lines 3-51 (49 LOC | Complexity 1) | used by 33 callers | [CorePrimitive]
class SduiStyleResolver
//  â³ Calls: SduiFlexContext.of, SduiBlockRegistry.all
//  â³ Called by: SduiButton, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, _SduiContainerState, _SduiCheckboxState, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, _SduiDrawingPadState, _SduiChartState, SduiTimePicker, SduiListView, SduiGauge, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSliderState, SduiGridView, _SduiAudioState, SduiToggle, _SduiRadioState, _SduiDropdownState, SduiChip, _SduiTextInputState, SduiRenderer, _SduiDocumentViewerState, _SduiCarouselState, _SduiShimmerLoaderState.padding, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState
```

#### SduiStyleResolver.resolveColor (Function)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 29 callers | [Pure, CorePrimitive]
static Color? resolveColor(BuildContext context, int? token)
//  â³ Called by: SduiButton, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, _SduiContainerState, _SduiCheckboxState, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, _SduiDrawingPadState, _SduiChartState, SduiTimePicker, SduiGauge, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSliderState, _SduiAudioState, SduiToggle, _SduiRadioState, _SduiDropdownState, SduiChip, _SduiTextInputState, _SduiDocumentViewerState, _SduiCarouselState, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState
```

#### SduiStyleResolver.resolveTextStyle (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static TextStyle? resolveTextStyle(BuildContext context, int? slot)
//  â³ Called by: _SduiMarkdownEditorState
```

#### SduiStyleResolver.resolveEdgeInsets (Function)
```rust
// Lines 14-14 (1 LOC | Complexity 1) | used by 10 callers | [Pure]
static EdgeInsetsGeometry? resolveEdgeInsets(dynamic val)
//  â³ Called by: _SduiContainerState, _SduiDividerState, _SduiHtmlViewerState, SduiListView, SduiHeatmap, SduiGridView, SduiRenderer, _SduiDocumentViewerState, _SduiCarouselState, _SduiShimmerLoaderState.padding
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\core\crnn_model.py (141 lines)

#### CRNN.__init__ (Function)
```rust
// Lines 51-77 (27 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self, num_classes: int = NUM_CLASSES, lstm_hidden: int = 128, lstm_dropout: float = 0.5)
//  â³ Calls: _conv_block, __init__
```

#### CRNN.forward (Function)
```rust
// Lines 79-90 (12 LOC | Complexity 1) | used by 0 callers | [MutatesState, Tested, PotentialDeadCode]
def forward(self, x)
```

#### _conv_block (Function)
```rust
// Lines 32-43 (12 LOC | Complexity 3) | used by 2 callers | [Pure]
def _conv_block(in_ch, out_ch, kernel=3, stride=1, padding=1, pool_h=True, pool_w=False)
//  â³ Calls: c
//  â³ Called by: CRNN.__init__, CRNN.__init__
```

#### ctc_greedy_decode (Function)
```rust
// Lines 96-116 (21 LOC | Complexity 4) | used by 8 callers | [Pure]
def ctc_greedy_decode(log_probs: torch.Tensor, custom_idx_to_char: dict = None) -> list[str]
//  â³ Called by: OCRReviewerApp.load_model_and_data, test, train, MobileEdgeEngine.process_image, MeterVisionEngine.run_ocr_crnn, train, train, train
```

#### CRNN (Class)
```rust
// Lines 45-90 (46 LOC | Complexity 1) | used by 8 callers
class CRNN(nn.Module)
//  â³ Called by: load_ocr_model, train, main, load_ocr_model, MeterVisionEngine.get_ocr_model, train, train, train
```

#### load_ocr_model (Function)
```rust
// Lines 124-146 (23 LOC | Complexity 4) | used by 4 callers | [MutatesState, Io]
def load_ocr_model(weights_path: str, device: str = None) -> CRNN
//  â³ Calls: SduiBlockRegistry.load, CRNN
//  â³ Called by: OCRReviewerApp.load_model_and_data, test, MobileEdgeEngine.process_image, run_confidence_audit
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_checkbox.dart (122 lines)

#### _SduiCheckboxState (Class)
```rust
// Lines 22-119 (98 LOC | Complexity 1) | used by 0 callers
class _SduiCheckboxState extends State<SduiCheckbox>
//  â³ Calls: SduiCheckbox, _SduiShimmerLoaderState.padding, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, dispose, _SduiCheckboxState.didUpdateWidget, initState, _SduiCheckboxState
```

#### SduiCheckbox.createState (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiCheckbox> createState()
//  â³ Calls: SduiCheckbox, _SduiCheckboxState
```

#### _SduiCheckboxState.didUpdateWidget (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiCheckbox oldWidget)
//  â³ Calls: SduiCheckbox
//  â³ Called by: _SduiCheckboxState
```

#### _SduiCheckboxState.initState (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SduiCheckbox (Class)
```rust
// Lines 2-20 (19 LOC | Complexity 1) | used by 0 callers
class SduiCheckbox extends StatefulWidget
//  â³ Calls: SduiCheckbox
```

#### _SduiCheckboxState.dispose (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiCheckboxState.build (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\blast_radius.rs (52 lines)

#### SubGraph (Struct)
```rust
// Lines 5-8 (4 LOC | Complexity 1) | used by 5 callers
pub struct SubGraph
//  â³ Called by: compute_subgraph, serialize, serialize, export_sdg, serialize
```

#### compute_subgraph (Function)
```rust
// Lines 10-57 (48 LOC | Complexity 13) | used by 1 callers | [MutatesState, CanPanic]
pub fn compute_subgraph(focus_name: &str, depth: usize, state: &AppState) -> SubGraph
//  â³ Calls: SubGraph, AppState, RadixTrie.insert, SduiIconRegistry.contains
//  â³ Called by: export_sdg
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_grid_view.dart (101 lines)

#### SduiGridView (Class)
```rust
// Lines 9-106 (98 LOC | Complexity 1) | used by 3 callers
class SduiGridView extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiRenderer, LogEntry::from, _SduiShimmerLoaderState.maxHeight, log, SduiNode.contentVal, SduiGridView._num, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, _SduiShimmerLoaderState.padding, SduiNode.behavior, SduiGridView._int
//  â³ Called by: SduiRegistry, SduiTypeRegistry, SduiGridView
```

#### SduiGridView._int (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
int? _int(int key)
//  â³ Called by: SduiGridView
```

#### SduiGridView.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiGridView._num (Function)
```rust
// Lines 101-101 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
double? _num(int key)
//  â³ Called by: SduiGridView
```

### C:\horAIzon_2.0\shua_governor\src\governor\cgroups.rs (243 lines)

#### read_memory_bytes (Function)
```rust
// Lines 112-144 (33 LOC | Complexity 11) | used by 2 callers | [Async, MutatesState, Io]
pub async fn read_memory_bytes(module_id: &str, _pid: Option<u32>) -> Result<u64, Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: Error, ensure_cgroup_dir, read_proc_memory_bytes, SduiBlockRegistry.load
//  â³ Called by: start_supervisor_loop, test_mock_cgroups
```

#### read_cgroup_cpu_usec (Function)
```rust
// Lines 244-284 (41 LOC | Complexity 11) | used by 1 callers | [Async, MutatesState, Io, CanPanic]
pub async fn read_cgroup_cpu_usec(module_id: &str, pid: Option<u32>) -> u64
//  â³ Calls: ensure_cgroup_dir, read_proc_cpu_usec, SduiBlockRegistry.load
//  â³ Called by: start_supervisor_loop
```

#### test_cpu_temp_non_linux (Function)
```rust
// Lines 299-303 (5 LOC | Complexity 1) | used by 0 callers | [Async, CanPanic]
async fn test_cpu_temp_non_linux()
//  â³ Calls: read_cpu_temp_celsius
```

#### kill (Function)
```rust
// Lines 213-218 (6 LOC | Complexity 3) | used by 1 callers | [Async, MutatesState, Tested]
pub async fn kill(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: Error, ensure_cgroup_dir
//  â³ Called by: control_module
```

#### test_mock_cgroups (Function)
```rust
// Lines 291-296 (6 LOC | Complexity 1) | used by 0 callers | [Async, CanPanic]
async fn test_mock_cgroups()
//  â³ Calls: read_memory_bytes, freeze
```

#### assign_pid (Function)
```rust
// Lines 72-78 (7 LOC | Complexity 3) | used by 1 callers | [Async, MutatesState]
pub async fn assign_pid(module_id: &str, pid: u32) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: Error, ensure_cgroup_dir
//  â³ Called by: control_module
```

#### unfreeze (Function)
```rust
// Lines 63-68 (6 LOC | Complexity 3) | used by 1 callers | [Async, MutatesState]
pub async fn unfreeze(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: Error, ensure_cgroup_dir
//  â³ Called by: control_module
```

#### read_system_cpu_pct (Function)
```rust
// Lines 159-190 (32 LOC | Complexity 6) | used by 0 callers | [Async, MutatesState, Io, PotentialDeadCode]
pub async fn read_system_cpu_pct() -> f32
//  â³ Calls: read_stat_fields
```

#### read_proc_cpu_usec (Function)
```rust
// Lines 221-239 (19 LOC | Complexity 4) | used by 1 callers | [Async, Io]
async fn read_proc_cpu_usec(pid: u32) -> u64
//  â³ Calls: collect
//  â³ Called by: read_cgroup_cpu_usec
```

#### ensure_cgroup_dir (Function)
```rust
// Lines 20-52 (33 LOC | Complexity 6) | used by 7 callers | [Async, MutatesState]
pub async fn ensure_cgroup_dir(module_id: &str) -> Result<PathBuf, Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: Error, LogEntry::from, SduiBlockRegistry.load
//  â³ Called by: read_cgroup_cpu_usec, kill, read_memory_bytes, assign_pid, unfreeze, freeze, control_module
```

#### read_stat_fields (Function)
```rust
// Lines 162-173 (12 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
async fn read_stat_fields() -> Option<(u64, u64)>
//  â³ Calls: collect, ok
//  â³ Called by: read_system_cpu_pct
```

#### freeze (Function)
```rust
// Lines 55-60 (6 LOC | Complexity 3) | used by 4 callers | [Async, MutatesState]
pub async fn freeze(module_id: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: Error, ensure_cgroup_dir
//  â³ Called by: HbpDiaryCodec, test_mock_cgroups, connectSocket, control_module
```

#### read_cpu_temp_celsius (Function)
```rust
// Lines 197-209 (13 LOC | Complexity 3) | used by 1 callers | [Async, Io]
pub async fn read_cpu_temp_celsius() -> f32
//  â³ Called by: test_cpu_temp_non_linux
```

#### read_proc_memory_bytes (Function)
```rust
// Lines 85-108 (24 LOC | Complexity 6) | used by 1 callers | [Async, Io]
pub async fn read_proc_memory_bytes(pid: u32) -> u64
//  â³ Called by: read_memory_bytes
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_text_input.dart (218 lines)

#### _SduiTextInputState._resolveEdgeInsets (Function)
```rust
// Lines 128-128 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
EdgeInsets? _resolveEdgeInsets(dynamic val)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState._resolveFormatters (Function)
```rust
// Lines 117-117 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<TextInputFormatter> _resolveFormatters()
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.didUpdateWidget (Function)
```rust
// Lines 75-75 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiTextInput oldWidget)
//  â³ Calls: SduiTextInput
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.dispose (Function)
```rust
// Lines 88-88 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiTextInputState.initState (Function)
```rust
// Lines 67-67 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiTextInputState._resolveKeyboardType (Function)
```rust
// Lines 104-104 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextInputType _resolveKeyboardType()
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.build (Function)
```rust
// Lines 195-195 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiKeyboardType (Class)
```rust
// Lines 10-16 (7 LOC | Complexity 1) | used by 4 callers
abstract final class SduiKeyboardType
//  â³ Called by: _SduiTextInputState, SduiRegistry._buildTextInput, SduiRegistry, SduiTextInput
```

#### _SduiTextInputState._resolveThemeColor (Function)
```rust
// Lines 150-150 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color? _resolveThemeColor(BuildContext context, String? token)
//  â³ Called by: _SduiTextInputState
```

#### SduiTextInput (Class)
```rust
// Lines 26-58 (33 LOC | Complexity 1) | used by 9 callers
class SduiTextInput extends StatefulWidget
//  â³ Calls: SduiKeyboardType
//  â³ Called by: _SduiTextInputState.didUpdateWidget, _SduiTextInputState, SduiTextInput.createState, _SduiTextInputState.didUpdateWidget, _SduiTextInputState, SduiTextInput.createState, SduiRegistry, SduiTextInput, SduiTypeRegistry
```

#### _SduiTextInputState._onTextChanged (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState (Class)
```rust
// Lines 60-227 (168 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiTextInputState extends State<SduiTextInput>
//  â³ Calls: SduiKeyboardType, SduiTextInput, _SduiTextInputState._onTextChanged, _SduiTextInputState._resolveEdgeInsets, _SduiTextInputState._resolveFormatters, _SduiTextInputState._resolveKeyboardType, _SduiTextInputState._resolveThemeColor, onError, SduiFlexContext.of, SduiIconRegistry.contains, SduiBlockRegistry.all, dispose, _SduiTextInputState.didUpdateWidget, initState
//  â³ Called by: SduiTextInput.createState, _SduiTextInputState, SduiTextInput.createState
```

#### SduiTextInput.createState (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiTextInput> createState()
//  â³ Calls: SduiTextInput, _SduiTextInputState
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_chip.dart (70 lines)

#### _SduiChipState.didUpdateWidget (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiChip oldWidget)
//  â³ Calls: SduiChip
//  â³ Called by: _SduiChipState
```

#### _SduiChipState.initState (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiChipState (Class)
```rust
// Lines 34-73 (40 LOC | Complexity 1) | used by 1 callers
class _SduiChipState extends State<SduiChip>
//  â³ Calls: ChipMode, SduiChip, _SduiChipState.didUpdateWidget, initState
//  â³ Called by: SduiChip.createState
```

#### SduiChip.createState (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiChip> createState()
//  â³ Calls: SduiChip, _SduiChipState
```

#### ChipMode (Class)
```rust
// Lines 6-10 (5 LOC | Complexity 1) | used by 3 callers
abstract final class ChipMode
//  â³ Called by: _SduiChipState, SduiChip, SduiRegistry
```

#### SduiChip (Class)
```rust
// Lines 12-32 (21 LOC | Complexity 1) | used by 0 callers
class SduiChip extends StatefulWidget
//  â³ Calls: ChipMode, SduiChip
```

#### _SduiChipState.build (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_governor\src\routes\dashboard.rs (216 lines)

#### AppState (Struct)
```rust
// Lines 21-47 (27 LOC | Complexity 1) | used by 66 callers | [CorePrimitive]
pub struct AppState
//  â³ Calls: LogEntry, MetricsSnapshot
//  â³ Called by: compute_subgraph, AppState, health_check, main, TypeScriptExtractor::extract, serialize, handle_delete, handle_put, handle_get, handle_propfind, dav_handler, serialize, deduplicate_edges, resolve_type_ref_edges, resolve_call_edges, resolve_edges, extract_type_references, extract_call_sites, extract_imports, handle_ws_proxy, ws_proxy_wildcard_handler, ws_proxy_handler, export_sdg, ingest_log, stream_logs, query_logs, infer, extract_api_routes, serialize, fallback_proxy_handler, create_router, get_graph, PythonExtractor::extract, stream_metrics, extract_trait_map, control_module, assign_tags, detect_test_linkages, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, detect_cycles, compute_centrality, GoExtractor::extract, DeclarationExtractor, extract_declarations, media_stats, serve_file, chunk_finalize, chunk_receive, chunk_init, upload_file, find_ghost_imports, mark_ready, RustExtractor::extract, DartExtractor::extract, get_console, get_dashboard, debug_analysis, find_boundary_violations, trigger_scan, parse_and_index_file, run_full_scan, get_preactivation_sheet, search_bm25
```

#### get_console (Function)
```rust
// Lines 149-181 (33 LOC | Complexity 4) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn get_console(
//  â³ Calls: AppState, SduiIconRegistry.contains, ok
```

#### get_dashboard (Function)
```rust
// Lines 49-147 (99 LOC | Complexity 14) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn get_dashboard(
//  â³ Calls: AppState, SduiIconRegistry.contains, ok, inject_module_telemetry
```

#### inject_module_telemetry (Function)
```rust
// Lines 188-244 (57 LOC | Complexity 8) | used by 1 callers | [MutatesState]
fn inject_module_telemetry(
//  â³ Calls: ModuleEntry, display_state
//  â³ Called by: get_dashboard
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_slider.dart (207 lines)

#### SduiSlider (Class)
```rust
// Lines 7-19 (13 LOC | Complexity 1) | used by 9 callers
class SduiSlider extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiSliderState.didUpdateWidget, _SduiSliderState, SduiSlider.createState, _SduiSliderState.didUpdateWidget, _SduiSliderState, SduiSlider.createState, SduiRegistry, SduiSlider, SduiTypeRegistry
```

#### _SduiSliderState.build (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiSliderState.didUpdateWidget (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiSlider oldWidget)
//  â³ Calls: SduiSlider
//  â³ Called by: _SduiSliderState
```

#### _SduiSliderState._normalize (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double _normalize(double raw, double min, double max, bool normalize)
//  â³ Called by: _SduiSliderState
```

#### SduiSlider.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSlider> createState()
//  â³ Calls: SduiSlider, _SduiSliderState
```

#### _SduiSliderState (Class)
```rust
// Lines 21-210 (190 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiSliderState extends ConsumerState<SduiSlider>
//  â³ Calls: SduiSlider, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, _SduiSliderState._normalize, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiNode.contentVal, _SduiSliderState.didUpdateWidget
//  â³ Called by: SduiSlider.createState, _SduiSliderState, SduiSlider.createState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_screen.dart (318 lines)

#### SduiScreen (Class)
```rust
// Lines 22-38 (17 LOC | Complexity 1) | used by 2 callers
class SduiScreen extends ConsumerStatefulWidget
//  â³ Calls: SduiSocketManager.getScreen, log
//  â³ Called by: _SduiScreenState, SduiScreen.createState
```

#### _SduiScreenState._resolveTitle (Function)
```rust
// Lines 166-166 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _resolveTitle()
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState._onFullReplace (Function)
```rust
// Lines 160-160 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFullReplace(List<SduiNode> nodes)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState.dispose (Function)
```rust
// Lines 131-131 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiScreenState._findNodeByIdSuffix (Function)
```rust
// Lines 186-186 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode? _findNodeByIdSuffix(List<SduiNode> nodes, String suffix)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState (Class)
```rust
// Lines 40-322 (283 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiScreenState extends ConsumerState<SduiScreen>
//  â³ Calls: SduiSocketManager, SduiStateVault, SduiEventDispatcher, SduiScreen, SduiRenderer, SduiBlueprintLoader.invalidate, ShuaDiaryBlocks.content, SduiNode, SduiShimmerLoader, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, ShuaDiaryBlocks.entryId, SduiJbcPanel, _SduiScreenState._resolveTitle, ShuaDiaryEntries.title, SduiNode.contentVal, _SduiScreenState._findNodeByIdSuffix, SduiTransport.applyDelta, SduiTransport, dispose, SduiSocketManager.evictCache, SduiStateVault.releaseScope, SduiEventDispatcher.flushPending, SduiSocketManager.listenForConnect, SduiSocketManager.reRequestScreen, log, SduiFlexContext.of, SduiSocketManager.listenForHotReload, _SduiScreenState._onFullReplace, SduiSocketManager.listenForReplace, _SduiScreenState._onPatchDelta, SduiSocketManager.listenForPatches, initState
//  â³ Called by: SduiScreen.createState
```

#### _SduiScreenState._onPatchDelta (Function)
```rust
// Lines 153-153 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onPatchDelta(dynamic rawDelta)
//  â³ Called by: _SduiScreenState
```

#### SduiScreen.createState (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiScreen> createState()
//  â³ Calls: SduiScreen, _SduiScreenState
```

#### _SduiScreenState.build (Function)
```rust
// Lines 198-198 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiScreenState._buildBody (Function)
```rust
// Lines 235-239 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildBody(
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState.initState (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiScreenState._buildNodeList (Function)
```rust
// Lines 303-307 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildNodeList(
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\interfaces\i_diary_generator.ts (18 lines)

#### IDiaryGeneratorProvider.generateFromNotesStream (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>
```

#### DiaryBlueprint (Interface)
```rust
// Lines 1-6 (6 LOC | Complexity 1) | used by 3 callers
interface DiaryBlueprint
//  â³ Called by: OllamaGeneratorProvider.generateFromNotes, GeminiGeneratorProvider.generateFromNotes, IDiaryGeneratorProvider.generateFromNotes
```

#### IDiaryGeneratorProvider.generateFromNotes (Function)
```rust
// Lines 9-12 (4 LOC | Complexity 1) | used by 0 callers | [Async, Pure, FrameworkInvoked]
generateFromNotes(
//  â³ Calls: DiaryBlueprint
```

#### IDiaryGeneratorProvider (Interface)
```rust
// Lines 8-14 (7 LOC | Complexity 1) | used by 4 callers
interface IDiaryGeneratorProvider
//  â³ Called by: DiaryAiSession.create, DiaryAiSession.constructor, OllamaGeneratorProvider, GeminiGeneratorProvider
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\ConfigProvider.ts (143 lines)

#### ConfigProvider.n8nUrl (Function)
```rust
// Lines 53-55 (3 LOC | Complexity 2) | used by 0 callers | [Io, PotentialDeadCode]
static get n8nUrl(): string
```

#### ConfigProvider.ollamaStreamerModel (Function)
```rust
// Lines 39-41 (3 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
static get ollamaStreamerModel(): string
```

#### ConfigProvider.assistantProvider (Function)
```rust
// Lines 71-73 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
static get assistantProvider(): string
```

#### ConfigProvider.ollamaSummarizerModel (Function)
```rust
// Lines 22-24 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
static get ollamaSummarizerModel(): string
```

#### ConfigProvider (Class)
```rust
// Lines 2-105 (104 LOC | Complexity 1) | used by 0 callers
class ConfigProvider
```

#### ConfigProvider.geminiAssistantModel (Function)
```rust
// Lines 102-104 (3 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
static get geminiAssistantModel(): string
```

#### ConfigProvider.analyzerProvider (Function)
```rust
// Lines 62-64 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
static get analyzerProvider(): string
```

#### ConfigProvider.n8nAssistantBaseUrl (Function)
```rust
// Lines 79-81 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
static get n8nAssistantBaseUrl(): string
```

#### ConfigProvider.pythonScriptPath (Function)
```rust
// Lines 46-48 (3 LOC | Complexity 2) | used by 1 callers | [Pure]
static get pythonScriptPath(): string
//  â³ Called by: PythonSemanticsAnalyzerProvider.analyze
```

#### ConfigProvider.geminiAnalyzerModel (Function)
```rust
// Lines 94-96 (3 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
static get geminiAnalyzerModel(): string
```

#### ConfigProvider.ollamaSentimentModel (Function)
```rust
// Lines 15-17 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
static get ollamaSentimentModel(): string
```

#### ConfigProvider.geminiApiKey (Function)
```rust
// Lines 86-88 (3 LOC | Complexity 2) | used by 4 callers | [Pure]
static get geminiApiKey(): string
//  â³ Called by: _NetworkConfigCardState, ConfigNotifier, ConfigState.copyWith, ConfigState
```

#### ConfigProvider.ollamaPlannerModel (Function)
```rust
// Lines 31-33 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
static get ollamaPlannerModel(): string
```

#### ConfigProvider.ollamaUrl (Function)
```rust
// Lines 7-9 (3 LOC | Complexity 2) | used by 0 callers | [Io, Tested, PotentialDeadCode]
static get ollamaUrl(): string
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\dataset_summary.py (173 lines)

#### get_filename (Function)
```rust
// Lines 48-52 (5 LOC | Complexity 1) | used by 3 callers | [Pure]
def get_filename(task)
//  â³ Called by: StandaloneWebAppHandler.do_POST, StandaloneWebAppHandler.do_POST, summarize
```

#### extract_labels (Function)
```rust
// Lines 36-46 (11 LOC | Complexity 5) | used by 1 callers | [Pure]
def extract_labels(task)
//  â³ Called by: summarize
```

#### summarize (Function)
```rust
// Lines 54-205 (152 LOC | Complexity 25) | used by 1 callers | [Io, HighComplexity]
def summarize(json_path=None)
//  â³ Calls: c, extract_labels, get_filename, SduiBlockRegistry.load, get_latest_export
//  â³ Called by: get_latest_export
```

#### get_latest_export (Function)
```rust
// Lines 30-34 (5 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def get_latest_export()
//  â³ Calls: summarize
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\diagnostic_result.dart (141 lines)

#### DiagnosticResult.isCritical (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get isCritical
//  â³ Calls: DiagnosticSeverity
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticResult.success (Function)
```rust
// Lines 53-56 (4 LOC | Complexity 1) | used by 7 callers | [Pure, Tested]
factory DiagnosticResult.success(T data,
//  â³ Called by: _DiaryListScreenState, DiagnosticResult.DiagnosticResult, TelemetryProfile, _DiaryEditorContent, BoundedRouteHistory, ThemeNotifier, AuthNotifier
```

#### DiagnosticResult.isFailure (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get isFailure
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticResult (Class)
```rust
// Lines 16-122 (107 LOC | Complexity 1) | used by 21 callers | [CorePrimitive]
class DiagnosticResult<T>
//  â³ Calls: SystemDiagnostic, OccurrenceEntry
//  â³ Called by: DiagnosticResult.copyWith, DiagnosticsHistoryNotifier, DiagnosticsHistoryNotifier.logResult, DiagnosticsHistoryNotifier._truncate, DiagnosticsState.copyWith, DiagnosticsState, AuthState.copyWith, AuthState, _TerminalLine, _SduiTerminalState._buildLogList, _SduiTerminalState._buildHeader, _SduiTerminalState, _SduiTerminalState._copyLogs, _SduiTerminalState._severityColor, _SduiTerminalState._getFilteredLogs, DiagnosticResult.DiagnosticResult, DiagnosticResult.DiagnosticResult, TelemetryProfile, BoundedRouteHistory, ThemeNotifier, AuthNotifier
```

#### DiagnosticResult.DiagnosticResult (Function)
```rust
// Lines 53-56 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory DiagnosticResult.success(T data,
//  â³ Calls: SystemDiagnostic, DiagnosticResult.success, DiagnosticResult
```

#### DiagnosticResult.latencyMs (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get latencyMs
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticResult.toString (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
String toString()
```

#### DiagnosticResult.DiagnosticResult (Function)
```rust
// Lines 70-73 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory DiagnosticResult.failure(SystemDiagnostic diagnostic,
//  â³ Calls: SystemDiagnostic, DiagnosticResult.failure, DiagnosticResult
```

#### OccurrenceEntry (Class)
```rust
// Lines 3-11 (9 LOC | Complexity 1) | used by 3 callers
class OccurrenceEntry
//  â³ Called by: DiagnosticResult.copyWith, DiagnosticResult, DiagnosticsHistoryNotifier
```

#### DiagnosticResult.copyWith (Function)
```rust
// Lines 96-100 (5 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DiagnosticResult<T> copyWith(
//  â³ Calls: OccurrenceEntry, DiagnosticResult
```

#### DiagnosticResult.failure (Function)
```rust
// Lines 70-73 (4 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
factory DiagnosticResult.failure(SystemDiagnostic diagnostic,
//  â³ Called by: DiagnosticResult.DiagnosticResult, TelemetryProfile, AuthNotifier
```

### C:\horAIzon_2.0\tools\sync_contracts.py (1341 lines)

#### _emit_dart_enum_class (Function)
```rust
// Lines 323-330 (8 LOC | Complexity 3) | used by 1 callers | [Pure]
def _emit_dart_enum_class(class_name: str, doc: str, values_dict: dict) -> list
//  â³ Calls: _to_screaming_snake
//  â³ Called by: generate_dart
```

#### _write_or_print (Function)
```rust
// Lines 163-175 (13 LOC | Complexity 2) | used by 6 callers | [Io]
def _write_or_print(filepath: str, content: str, dry_run: bool, lang: str)
//  â³ Calls: _ensure_dir
//  â³ Called by: generate_go, generate_python, generate_typescript, generate_csharp, generate_java, generate_dart
```

#### _emit_ts_const (Function)
```rust
// Lines 757-764 (8 LOC | Complexity 3) | used by 1 callers | [Pure]
def _emit_ts_const(const_name: str, doc: str, values_dict: dict) -> list
//  â³ Calls: _to_screaming_snake
//  â³ Called by: generate_typescript
```

#### _write_block (Function)
```rust
// Lines 1183-1195 (13 LOC | Complexity 4) | used by 1 callers | [Pure]
def _write_block(comment: str, items: dict, prefix: str)
//  â³ Calls: _to_pascal_case
//  â³ Called by: generate_go
```

#### _to_pascal_case (Function)
```rust
// Lines 192-199 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
def _to_pascal_case(name: str) -> str
//  â³ Called by: _write_block
```

#### generate_typescript (Function)
```rust
// Lines 672-811 (140 LOC | Complexity 18) | used by 3 callers | [Io]
def generate_typescript(schema: dict, dry_run: bool)
//  â³ Calls: _write_or_print, _emit_ts_const, _rpc_methods, _to_screaming_snake
//  â³ Called by: main, delete_primitive, request_primitive
```

#### generate_dart (Function)
```rust
// Lines 206-518 (313 LOC | Complexity 36) | used by 3 callers | [Io, HighComplexity]
def generate_dart(schema: dict, dry_run: bool)
//  â³ Calls: _write_or_print, ShuaDiaryEntries.title, _emit_dart_enum_class, _rpc_methods, _to_screaming_snake
//  â³ Called by: main, delete_primitive, request_primitive
```

#### validate_schema (Function)
```rust
// Lines 77-151 (75 LOC | Complexity 21) | used by 1 callers | [Pure, HighComplexity]
def validate_schema(schema: dict) -> list[str]
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 1313-1417 (105 LOC | Complexity 19) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: generate_go, generate_python, generate_typescript, generate_csharp, generate_java, generate_dart, validate_schema, load_schema, delete_primitive, request_primitive
```

#### delete_primitive (Function)
```rust
// Lines 923-966 (44 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io]
def delete_primitive(primitive_name: str, category: str)
//  â³ Calls: run, generate_typescript, generate_csharp, generate_java, generate_python, generate_dart, SduiStateVault.dump, load_schema
//  â³ Called by: main
```

#### _to_screaming_snake (Function)
```rust
// Lines 184-189 (6 LOC | Complexity 1) | used by 7 callers | [Pure]
def _to_screaming_snake(name: str) -> str
//  â³ Called by: _write_class, _emit_ts_const, generate_typescript, generate_csharp, generate_java, _emit_dart_enum_class, generate_dart
```

#### generate_go (Function)
```rust
// Lines 1168-1306 (139 LOC | Complexity 4) | used by 1 callers | [Io]
def generate_go(schema: dict, dry_run: bool)
//  â³ Calls: _write_or_print, _rpc_methods, _write_block
//  â³ Called by: main
```

#### request_primitive (Function)
```rust
// Lines 817-920 (104 LOC | Complexity 15) | used by 1 callers | [MutatesState, Io]
def request_primitive(primitive_name: str, category: str, is_human: bool = False)
//  â³ Calls: run, generate_typescript, generate_csharp, generate_java, generate_python, generate_dart, SduiStateVault.dump, SduiBlockRegistry.load, load_schema
//  â³ Called by: main
```

#### load_schema (Function)
```rust
// Lines 62-74 (13 LOC | Complexity 4) | used by 3 callers | [CanPanic]
def load_schema() -> dict
//  â³ Calls: deep_merge, SduiBlockRegistry.load
//  â³ Called by: main, delete_primitive, request_primitive
```

#### deep_merge (Function)
```rust
// Lines 55-60 (6 LOC | Complexity 3) | used by 1 callers | [Pure]
def deep_merge(target: dict, source: dict)
//  â³ Calls: main
//  â³ Called by: load_schema
```

#### generate_java (Function)
```rust
// Lines 525-593 (69 LOC | Complexity 15) | used by 3 callers | [Io]
def generate_java(schema: dict, dry_run: bool)
//  â³ Calls: _write_or_print, _rpc_methods, _to_screaming_snake
//  â³ Called by: main, delete_primitive, request_primitive
```

#### generate_python (Function)
```rust
// Lines 974-1161 (188 LOC | Complexity 8) | used by 3 callers | [Io, CanPanic, HighComplexity]
def generate_python(schema: dict, dry_run: bool)
//  â³ Calls: _write_or_print, _rpc_methods, _write_class
//  â³ Called by: main, delete_primitive, request_primitive
```

#### _ensure_dir (Function)
```rust
// Lines 158-160 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
def _ensure_dir(filepath: str)
//  â³ Called by: _write_or_print
```

#### _rpc_methods (Function)
```rust
// Lines 178-181 (4 LOC | Complexity 1) | used by 6 callers | [Pure]
def _rpc_methods(schema: dict) -> dict
//  â³ Called by: generate_go, generate_python, generate_typescript, generate_csharp, generate_java, generate_dart
```

#### generate_csharp (Function)
```rust
// Lines 600-665 (66 LOC | Complexity 16) | used by 3 callers | [Io]
def generate_csharp(schema: dict, dry_run: bool)
//  â³ Calls: _write_or_print, _rpc_methods, _to_screaming_snake
//  â³ Called by: main, delete_primitive, request_primitive
```

#### _write_class (Function)
```rust
// Lines 1001-1016 (16 LOC | Complexity 5) | used by 1 callers | [Pure]
def _write_class(class_name: str, comment: str, items: dict, prefix: str = "")
//  â³ Calls: _to_screaming_snake
//  â³ Called by: generate_python
```

### C:\horAIzon_2.0\shua_governor\src\proxy\ws_proxy.rs (85 lines)

#### ws_proxy_wildcard_handler (Function)
```rust
// Lines 25-31 (7 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn ws_proxy_wildcard_handler(
//  â³ Calls: Response, AppState, handle_ws_proxy
```

#### pipe_sockets (Function)
```rust
// Lines 52-107 (56 LOC | Complexity 18) | used by 1 callers | [Async, MutatesState, Io]
async fn pipe_sockets(client: WebSocket, module_id: String, upstream_port: u16)
//  â³ Called by: handle_ws_proxy
```

#### ws_proxy_handler (Function)
```rust
// Lines 17-23 (7 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn ws_proxy_handler(
//  â³ Calls: Response, AppState, handle_ws_proxy
```

#### handle_ws_proxy (Function)
```rust
// Lines 33-47 (15 LOC | Complexity 1) | used by 2 callers | [Async, Io]
async fn handle_ws_proxy(
//  â³ Calls: Response, AppState, pipe_sockets
//  â³ Called by: ws_proxy_wildcard_handler, ws_proxy_handler
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_toggle.dart (63 lines)

#### SduiToggle.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### SduiToggle (Class)
```rust
// Lines 7-68 (62 LOC | Complexity 1) | used by 0 callers
class SduiToggle extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, ChatPanelOpenNotifier.toggle, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiNode.contentVal, SduiToggle
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\middleware\msgpack_middleware.ts (39 lines)

#### Response.msgpack (Function)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
msgpack(data: any): void
//  â³ Called by: GovernorLogger, msgpackMiddleware
```

#### msgpackMiddleware (Function)
```rust
// Lines 17-51 (35 LOC | Complexity 5) | used by 0 callers | [Io, PotentialDeadCode]
function msgpackMiddleware(req: Request, res: Response, next: NextFunction)
//  â³ Calls: Response, Response.msgpack, LogEntry::from, MessagePackCodec.encode
```

#### Response (Interface)
```rust
// Lines 5-7 (3 LOC | Complexity 1) | used by 19 callers | [CorePrimitive]
interface Response
//  â³ Called by: handle_delete, handle_put, handle_get, handle_propfind, dav_handler, proxy_request, handle_ws_proxy, ws_proxy_wildcard_handler, ws_proxy_handler, export_sdg, error_response, try_forward, msgpackMiddleware, fallback_proxy_handler, track_performance_timing, MediaUploader._assertStatus, verify_auth, MediaUploader, SduiEventDispatcher
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_shimmer_loader.dart (362 lines)

#### _SduiShimmerLoaderState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiShimmerLoaderState._buildModuleCard (Function)
```rust
// Lines 201-201 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildModuleCard(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.shimmerType (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
int get shimmerType
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry, _SduiShimmerLoaderState, SduiShimmerLoader, SduiSandboxScreen, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._circle (Function)
```rust
// Lines 105-105 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Widget _circle(Color color, double diameter)
//  â³ Called by: _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildCircle
```

#### _SduiShimmerLoaderState._buildFeedRow (Function)
```rust
// Lines 189-189 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildFeedRow(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### SduiShimmerLoader (Class)
```rust
// Lines 5-19 (15 LOC | Complexity 1) | used by 9 callers
class SduiShimmerLoader extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiShimmerLoaderState, SduiShimmerLoader.createState, _SduiShimmerLoaderState, SduiShimmerLoader.createState, SduiRegistry, SduiShimmerLoader, SduiModuleCard, _SduiScreenState, SduiTypeRegistry
```

#### _SduiShimmerLoaderState._animated (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _animated(Widget child, Color baseColor)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.borderRadius (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 65 callers | [Pure, CorePrimitive]
double get borderRadius
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiCodeEditorState, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, _SduiContainerState, _SduiMarkdownEditorState, _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, _DiaryListScreenState, _SduiCheckboxState, SduiRegistry, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, SduiStlViewer, _SduiHeadingState, _SduiShimmerLoaderState, SduiShimmerLoader, _SduiDrawingPadState, _SduiCodeEditorState, _SduiChartState, SduiTimePicker, _CoPilotBubbleState, _JoshCoPilotPanelState, _DiaryEditorContent, SduiGauge, SduiSandboxScreen, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSpacerState, _ActionChip, _TelemetryChip, SduiModuleCard, SduiProgressBar, _SduiAudioState, SduiToggle, _SduiOrdinalSliderState, _SduiRadioState, _SduiRadioState, _NetworkConfigCardState, _SduiDropdownState, _SduiJbcPanelState, SduiImage, SduiContainer, _SduiWrapState, _SduiListEditorState, _SduiTableState, _SduiDocumentViewerState, SduiCardNode, SduiContainerNode, _SduiCarouselState, _SduiShimmerLoaderState._buildRectangle, _SduiShimmerLoaderState, _SduiCheckboxState, _SduiMapState, _FilterChip, _SuccessRateBadge, _TerminalLineState, _SduiTerminalState, _SduiTimelineState, SduiButton, _SduiMarkdownEditorState, _PinEntryScreenState
```

#### _SduiShimmerLoaderState._buildParagraph (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildParagraph(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildMediaCard (Function)
```rust
// Lines 151-151 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMediaCard(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._rect (Function)
```rust
// Lines 92-92 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Widget _rect(Color color, {double? height, double radius = 8.0, double widthFactor = 1.0})
//  â³ Called by: _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildRectangle
```

#### SduiShimmerLoader.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiShimmerLoader> createState()
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildListTile (Function)
```rust
// Lines 130-130 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildListTile(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.lastLineWidthPct (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
double get lastLineWidthPct
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry, _SduiShimmerLoaderState, SduiShimmerLoader, SduiSandboxScreen, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.padding (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 76 callers | [Pure, Tested, CorePrimitive]
EdgeInsetsGeometry get padding
//  â³ Calls: SduiNode.behavior, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver
//  â³ Called by: _SduiCodeEditorState, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, AdaptiveShell, _SduiContainerState, _SduiMarkdownEditorState, _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, _DiaryListScreenState, _SduiCheckboxState, SduiRegistry, _SduiSandboxScreenState, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, SduiStlViewer, _SduiHeadingState, _SduiShimmerLoaderState, SduiShimmerLoader, _SduiDrawingPadState, _SduiCodeEditorState, _SduiChartState, SduiTimePicker, _CoPilotBubbleState, _JoshCoPilotPanelState, _DiaryEditorContent, SduiListView, SduiGauge, SduiSandboxScreen, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSpacerState, _ActionChip, _TelemetryChip, SduiModuleCard, SduiProgressBar, SduiGridView, _SduiAudioState, SduiToggle, _SduiOrdinalSliderState, _SduiRadioState, _SduiScreenState, _SduiRadioState, _NetworkConfigCardState, SettingsPage, _SduiDropdownState, _SduiJbcPanelState, SduiImage, SduiContainer, _SduiWrapState, _SduiListEditorState, SduiListView, SduiRenderer, _SduiTableState, _SduiDocumentViewerState, _SduiQuoteState, SduiCardNode, SduiContainerNode, _SduiCarouselState._buildEmpty, _SduiCarouselState, SduiTypeRegistry, _SduiShimmerLoaderState, _SduiCheckboxState, _SduiMapState, _FilterChip, _SuccessRateBadge, _TerminalLineState, _SduiTerminalState, _SduiTimelineState, SduiButton, _SduiMarkdownEditorState, SduiGridView, _PinEntryScreenState
```

#### _SduiShimmerLoaderState._buildTerminalWindow (Function)
```rust
// Lines 241-241 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTerminalWindow(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState (Class)
```rust
// Lines 21-343 (323 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiShimmerLoaderState extends State<SduiShimmerLoader> with SingleTickerProviderStateMixin
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState._animated, _SduiShimmerLoaderState._buildRectangle, _SduiShimmerLoaderState._buildTerminalWindow, _SduiShimmerLoaderState._buildModuleCard, _SduiShimmerLoaderState._buildFeedRow, _SduiShimmerLoaderState._buildStatCard, _SduiShimmerLoaderState._buildChatBubble, _SduiShimmerLoaderState._buildMediaCard, _SduiShimmerLoaderState._buildParagraph, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState.shimmerType, SduiFlexContext.of, SduiBlockRegistry.all, _SduiShimmerLoaderState._buildListTile, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState._circle, _SduiShimmerLoaderState.lastLineWidthPct, c, _SduiShimmerLoaderState._rect, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.lineCount, generate, _SduiShimmerLoaderState.borderRadius, dispose, _SduiShimmerLoaderState.shimmerAnimStyle, initState
//  â³ Called by: _SduiShimmerLoaderState, SduiShimmerLoader.createState, SduiShimmerLoader.createState
```

#### _SduiShimmerLoaderState.dispose (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiShimmerLoaderState.maxHeight (Function)
```rust
// Lines 30-30 (1 LOC | Complexity 1) | used by 14 callers | [Pure, CorePrimitive]
double? get maxHeight
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiContainerState, SduiRegistry, _SduiShimmerLoaderState, SduiShimmerLoader, SduiListView, SduiSandboxScreen, SduiHeatmap, SduiGridView, SduiListView, _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState._buildRectangle, _SduiTerminalState, SduiGridView
```

#### _SduiShimmerLoaderState._buildCircle (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildCircle(Color c)
//  â³ Calls: _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState._circle, c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildChatBubble (Function)
```rust
// Lines 163-163 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildChatBubble(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.lineCount (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
int get lineCount
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry, _SduiShimmerLoaderState, SduiShimmerLoader, SduiSandboxScreen, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.shimmerAnimStyle (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
int get shimmerAnimStyle
//  â³ Calls: SduiNode.behavior
//  â³ Called by: SduiRegistry, _SduiShimmerLoaderState, SduiShimmerLoader, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildRectangle (Function)
```rust
// Lines 113-113 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildRectangle(Color c)
//  â³ Calls: _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState._rect, c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.build (Function)
```rust
// Lines 314-314 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiShimmerLoaderState._buildStatCard (Function)
```rust
// Lines 177-177 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStatCard(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

### C:\horAIzon_2.0\tools\explain_blueprint.py (187 lines)

#### format_behavior_value (Function)
```rust
// Lines 98-108 (11 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
def format_behavior_value(name, val, color_tokens, enums)
//  â³ Calls: format_color
```

#### is_prompt_last (Function)
```rust
// Lines 172-175 (4 LOC | Complexity 2) | used by 1 callers | [Pure]
def is_prompt_last(is_last, prefix_override)
//  â³ Called by: print_node
```

#### print_node (Function)
```rust
// Lines 110-170 (61 LOC | Complexity 11) | used by 1 callers | [Io]
def print_node(node, tables, indent="", is_last=True, prefix_override=None)
//  â³ Calls: format_behavior_value, is_prompt_last
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 177-215 (39 LOC | Complexity 7) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: print_node, SduiBlockRegistry.load, build_lookup_tables, load_contracts
```

#### load_contracts (Function)
```rust
// Lines 23-40 (18 LOC | Complexity 4) | used by 0 callers | [Io, PotentialDeadCode]
def load_contracts()
//  â³ Calls: main, SduiBlockRegistry.load
```

#### build_lookup_tables (Function)
```rust
// Lines 42-86 (45 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def build_lookup_tables(contracts)
```

#### format_color (Function)
```rust
// Lines 88-96 (9 LOC | Complexity 4) | used by 0 callers | [Pure, PotentialDeadCode]
def format_color(val, color_tokens)
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\core\crnn_model.py (139 lines)

#### CRNN.forward (Function)
```rust
// Lines 79-90 (12 LOC | Complexity 1) | used by 0 callers | [MutatesState, Tested, PotentialDeadCode]
def forward(self, x)
```

#### _conv_block (Function)
```rust
// Lines 33-42 (10 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def _conv_block(in_ch, out_ch, kernel=3, stride=1, padding=1, pool_h=True)
//  â³ Calls: c
```

#### CRNN.__init__ (Function)
```rust
// Lines 51-77 (27 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self, num_classes: int = NUM_CLASSES, lstm_hidden: int = 128, lstm_dropout: float = 0.5)
//  â³ Calls: _conv_block, __init__
```

#### ctc_greedy_decode (Function)
```rust
// Lines 96-116 (21 LOC | Complexity 4) | used by 0 callers | [Pure, PotentialDeadCode]
def ctc_greedy_decode(log_probs: torch.Tensor, custom_idx_to_char: dict = None) -> list[str]
```

#### CRNN (Class)
```rust
// Lines 45-90 (46 LOC | Complexity 1) | used by 0 callers
class CRNN(nn.Module)
```

#### load_ocr_model (Function)
```rust
// Lines 124-146 (23 LOC | Complexity 4) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
def load_ocr_model(weights_path: str, device: str = None) -> CRNN
//  â³ Calls: SduiBlockRegistry.load, CRNN
```

### C:\horAIzon_2.0\shua_governor\src\routes\mod.rs (96 lines)

#### track_performance_timing (Function)
```rust
// Lines 32-56 (25 LOC | Complexity 2) | used by 0 callers | [Async, MutatesState, PotentialDeadCode]
async fn track_performance_timing(req: Request, next: Next) -> Response
//  â³ Calls: Response, RadixTrie.insert, run
```

#### fallback_proxy_handler (Function)
```rust
// Lines 104-131 (28 LOC | Complexity 4) | used by 0 callers | [Async, Pure, PotentialDeadCode]
async fn fallback_proxy_handler(
//  â³ Calls: Response, AppState, proxy_request
```

#### create_router (Function)
```rust
// Lines 59-101 (43 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn create_router(state: AppState) -> Router
//  â³ Calls: AppState
//  â³ Called by: main
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_code_editor.dart (419 lines)

#### _SduiCodeEditorState.didUpdateWidget (Function)
```rust
// Lines 245-245 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiCodeEditor oldWidget)
//  â³ Calls: SduiCodeEditor
//  â³ Called by: _SduiCodeEditorState
```

#### SduiCodeEditor (Class)
```rust
// Lines 201-219 (19 LOC | Complexity 1) | used by 0 callers
class SduiCodeEditor extends StatefulWidget
//  â³ Calls: SduiCodeEditor
```

#### _SduiCodeEditorState.dispose (Function)
```rust
// Lines 260-260 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SyntaxHighlightingController.buildTextSpan (Function)
```rust
// Lines 137-137 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing})
//  â³ Called by: _SduiCodeEditorState
```

#### _SduiCodeEditorState.build (Function)
```rust
// Lines 275-275 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiCodeEditorState._onTextChanged (Function)
```rust
// Lines 267-267 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiCodeEditorState
```

#### _SduiCodeEditorState.initState (Function)
```rust
// Lines 228-228 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SyntaxRules (Class)
```rust
// Lines 4-18 (15 LOC | Complexity 1) | used by 0 callers
class SyntaxRules
//  â³ Calls: SyntaxRules
```

#### _SduiCodeEditorState (Class)
```rust
// Lines 221-419 (199 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class _SduiCodeEditorState extends State<SduiCodeEditor>
//  â³ Calls: SduiCodeEditor, SyntaxHighlightingController.buildTextSpan, SduiNode.behavior, _SduiCodeEditorState._onTextChanged, _SduiShimmerLoaderState.padding, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, dispose, _SduiCodeEditorState.didUpdateWidget, SyntaxHighlightingController, initState, _SduiCodeEditorState
```

#### SduiCodeEditor.createState (Function)
```rust
// Lines 218-218 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiCodeEditor> createState()
//  â³ Calls: SduiCodeEditor, _SduiCodeEditorState
```

#### SyntaxHighlightingController (Class)
```rust
// Lines 21-199 (179 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SyntaxHighlightingController extends TextEditingController
//  â³ Calls: SduiFlexContext.of, BoundedRouteHistory.isEmpty, SyntaxRules, SyntaxHighlightingController
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_list_editor.dart (741 lines)

#### _SduiListEditorState._resolveContainerColor (Function)
```rust
// Lines 317-317 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveContainerColor(ThemeData theme)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._resolveAccentColor (Function)
```rust
// Lines 304-304 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveAccentColor(ThemeData theme)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._serialize (Function)
```rust
// Lines 181-181 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _serialize()
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._loadFromContent (Function)
```rust
// Lines 157-157 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _loadFromContent(String content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: _SduiListEditorState
```

#### SduiListEditor.createState (Function)
```rust
// Lines 96-96 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiListEditor> createState()
//  â³ Calls: SduiListEditor, _SduiListEditorState
```

#### _SduiListEditorState._onEnterPressed (Function)
```rust
// Lines 234-234 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onEnterPressed(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._onBackspaceOnEmpty (Function)
```rust
// Lines 242-242 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onBackspaceOnEmpty(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildProgressHeader (Function)
```rust
// Lines 411-411 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildProgressHeader(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.build (Function)
```rust
// Lines 339-339 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiListEditorState.didUpdateWidget (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiListEditor oldWidget)
//  â³ Calls: SduiListEditor
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._parseHex (Function)
```rust
// Lines 285-285 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Color? _parseHex(String token)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildHeaderRow (Function)
```rust
// Lines 379-379 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHeaderRow(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _ListItem (Class)
```rust
// Lines 100-114 (15 LOC | Complexity 1) | used by 0 callers
class _ListItem
//  â³ Calls: dispose, _ListItem
```

#### ListStyle (Class)
```rust
// Lines 7-20 (14 LOC | Complexity 1) | used by 0 callers
abstract final class ListStyle
//  â³ Calls: ListStyle
```

#### _SduiListEditorState._persistChange (Function)
```rust
// Lines 212-212 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _persistChange()
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.initState (Function)
```rust
// Lines 125-125 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiListEditorState._buildFooterActions (Function)
```rust
// Lines 693-693 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildFooterActions(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### BulletStyle (Class)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 0 callers
abstract final class BulletStyle
//  â³ Calls: BulletStyle
```

#### _SduiListEditorState._appendNewItem (Function)
```rust
// Lines 203-203 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _appendNewItem({int? afterIndex})
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._toggleChecked (Function)
```rust
// Lines 228-228 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _toggleChecked(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState (Class)
```rust
// Lines 117-748 (632 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class _SduiListEditorState extends State<SduiListEditor>
//  â³ Calls: BulletStyle, SduiListEditor, _SduiListEditorState._onEnterPressed, _SduiListEditorState._onBackspaceOnEmpty, _SduiListEditorState._selectRadio, _SduiListEditorState._toggleChecked, _SduiListEditorState._resolveContainerColor, _SduiListEditorState._buildTagChip, SduiIconRegistry.contains, _SduiListEditorState._buildFooterActions, _SduiListEditorState._buildItemRow, _SduiListEditorState._buildProgressHeader, _SduiListEditorState._buildHeaderRow, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiListEditorState._buildTagReadMode, _SduiListEditorState._resolveAccentColor, SduiFlexContext.of, _SduiListEditorState._parseHex, _SduiListEditorState._persistChange, RadixTrie.insert, ListStyle, _ListItem, ShuaDiaryBlocks.content, SduiStateVault.clear, dispose, _SduiListEditorState._serialize, _SduiListEditorState.didUpdateWidget, _SduiListEditorState._appendNewItem, BoundedRouteHistory.isEmpty, _SduiListEditorState._loadFromContent, initState, _SduiListEditorState
```

#### _SduiListEditorState._buildItemRow (Function)
```rust
// Lines 543-543 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildItemRow(ThemeData theme, Color accentColor, int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildTagReadMode (Function)
```rust
// Lines 468-468 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTagReadMode(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.dispose (Function)
```rust
// Lines 147-147 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiListEditorState._buildTagChip (Function)
```rust
// Lines 525-525 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTagChip(ThemeData theme, Color accentColor, String tag)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._selectRadio (Function)
```rust
// Lines 260-260 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _selectRadio(int index)
//  â³ Called by: _SduiListEditorState
```

#### _ListItem.dispose (Function)
```rust
// Lines 110-110 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiListEditor (Class)
```rust
// Lines 47-97 (51 LOC | Complexity 1) | used by 0 callers
class SduiListEditor extends StatefulWidget
//  â³ Calls: BulletStyle, ListStyle, SduiListEditor
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_orchestrator.ts (320 lines)

#### SduiOrchestrator.constructor (Function)
```rust
// Lines 30-37 (8 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor(io: Server)
//  â³ Calls: SduiOrchestrator.setupHotReloadWatcher, SduiOrchestrator.setupListeners, SduiOrchestrator.registerHandlers, SduiBlockRegistry.load
```

#### SduiOrchestrator.handleRpc (Function)
```rust
// Lines 110-151 (42 LOC | Complexity 8) | used by 1 callers | [Async, MutatesState, Io]
private async handleRpc(socket: Socket, data: any)
//  â³ Calls: warn, MessagePackCodec.encode, SduiActionHandler.handle, SduiStateVault.set, DiaryAiSession.create, getDiaryRepository, DiaryRepository.getAiProviderConfig, SduiStateVault.get
//  â³ Called by: SduiOrchestrator.setupListeners
```

#### SduiOrchestrator.updateSession (Function)
```rust
// Lines 50-52 (3 LOC | Complexity 1) | used by 1 callers | [Io]
public updateSession(socketId: string, session: DiaryAiSession)
//  â³ Calls: DiaryAiSession, SduiStateVault.set
//  â³ Called by: SaveAiConfigHandler.handle
```

#### SduiOrchestrator.setupHotReloadWatcher (Function)
```rust
// Lines 54-80 (27 LOC | Complexity 7) | used by 1 callers | [MutatesState, Io]
private setupHotReloadWatcher()
//  â³ Calls: MessagePackCodec.encode
//  â³ Called by: SduiOrchestrator.constructor
```

#### SduiOrchestrator (Class)
```rust
// Lines 21-188 (168 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiOrchestrator
//  â³ Calls: ISduiRpcHandler, DiaryAiSession, SduiStateVault
```

#### SduiOrchestrator.sendReplacePayload (Function)
```rust
// Lines 153-187 (35 LOC | Complexity 5) | used by 3 callers | [Async, Io]
public async sendReplacePayload(socket: Socket, screenId: string, params: Record<string, any>)
//  â³ Calls: MessagePackCodec.encode, ShuaSyncQueue.payload, DiaryRepository.getEntryWithBlocks, getDiaryRepository, SduiScreenAssembler.assemble
//  â³ Called by: GenerateFromNotesHandler.handle, RequestScreenHandler.handle, ApplyMutationsHandler.handle
```

#### SduiOrchestrator.setupListeners (Function)
```rust
// Lines 82-108 (27 LOC | Complexity 3) | used by 1 callers | [MutatesState, Io]
private setupListeners()
//  â³ Calls: SduiOrchestrator.handleRpc, AnalysisWorker.cancelPendingForSocket, SduiStateVault.get, DiaryAiSession.create, getDiaryRepository, DiaryRepository.getAiProviderConfig, SduiStateVault, SduiStateVault.set
//  â³ Called by: SduiOrchestrator.constructor
```

#### SduiOrchestrator.registerHandlers (Function)
```rust
// Lines 39-48 (10 LOC | Complexity 1) | used by 1 callers | [Pure]
private registerHandlers()
//  â³ Calls: SaveAiConfigHandler, GenerateSummaryHandler, AnalyzeEntryHandler, SemanticSearchHandler, ApplyMutationsHandler, ChatHandler, GenerateFromNotesHandler, RequestScreenHandler, SduiStateVault.set
//  â³ Called by: SduiOrchestrator.constructor
```

### C:\horAIzon_2.0\shua_modules\shua_diary\start_diary.py (106 lines)

#### is_port_in_use (Function)
```rust
// Lines 6-8 (3 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
def is_port_in_use(port)
//  â³ Calls: main
```

#### main (Function)
```rust
// Lines 10-112 (103 LOC | Complexity 17) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: is_port_in_use
```

### C:\horAIzon_2.0\tools\detect_flutter_logs.py (207 lines)

#### clean_code (Function)
```rust
// Lines 17-150 (134 LOC | Complexity 32) | used by 2 callers | [Pure, HighComplexity]
def clean_code(code: str) -> str
//  â³ Calls: main, ThemeCompiler.compile
//  â³ Called by: check_file, check_file
```

#### main (Function)
```rust
// Lines 176-225 (50 LOC | Complexity 12) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: check_file, walk
```

#### check_file (Function)
```rust
// Lines 152-174 (23 LOC | Complexity 5) | used by 2 callers | [Pure]
def check_file(filepath: str) -> list
//  â³ Calls: clean_code
//  â³ Called by: main, main
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_progress_bar.dart (100 lines)

#### SduiProgressBar (Class)
```rust
// Lines 7-105 (99 LOC | Complexity 1) | used by 3 callers
class SduiProgressBar extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiNode.contentVal
//  â³ Called by: SduiRegistry, SduiProgressBar, SduiTypeRegistry
```

#### SduiProgressBar.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

### C:\horAIzon_2.0\sdui3\sdui\sdui_screen.dart (89 lines)

#### _SduiDashboardScreenState.dispose (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiDashboardScreen.createState (Function)
```rust
// Lines 14-14 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDashboardScreen> createState()
//  â³ Calls: SduiDashboardScreen, _SduiDashboardScreenState
```

#### SduiDashboardScreen (Class)
```rust
// Lines 10-15 (6 LOC | Complexity 1) | used by 2 callers
class SduiDashboardScreen extends ConsumerStatefulWidget
//  â³ Called by: _SduiDashboardScreenState, SduiDashboardScreen.createState
```

#### _SduiDashboardScreenState.initState (Function)
```rust
// Lines 21-21 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiDashboardScreenState.build (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiDashboardScreenState (Class)
```rust
// Lines 17-95 (79 LOC | Complexity 1) | used by 1 callers
class _SduiDashboardScreenState extends ConsumerState<SduiDashboardScreen>
//  â³ Calls: SduiDashboardScreen, build, SduiNode, ShuaSyncQueue.payload, SduiFlexContext.of, dispose, initState
//  â³ Called by: SduiDashboardScreen.createState
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\system_diagnostics.dart (40 lines)

#### DiagnosticSeverity (Enum)
```rust
// Lines 1-10 (10 LOC | Complexity 1) | used by 6 callers
enum DiagnosticSeverity
//  â³ Called by: SystemDiagnostic, _SduiTerminalState, SystemEvents, DiagnosticResult.isCritical, TelemetryProfile, DiagnosticsHistoryNotifier
```

#### SystemEvents (Class)
```rust
// Lines 23-45 (23 LOC | Complexity 1) | used by 3 callers
class SystemEvents
//  â³ Calls: DiagnosticSeverity, SystemDiagnostic
//  â³ Called by: BoundedRouteHistory, ThemeNotifier, AuthNotifier
```

#### SystemDiagnostic (Class)
```rust
// Lines 13-19 (7 LOC | Complexity 1) | used by 5 callers
class SystemDiagnostic
//  â³ Calls: DiagnosticSeverity
//  â³ Called by: DiagnosticResult.DiagnosticResult, DiagnosticResult.DiagnosticResult, DiagnosticResult, SystemEvents, TelemetryProfile
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_screen_assembler.ts (1297 lines)

#### SduiScreenAssembler._assembleDiaryBlockPicker (Function)
```rust
// Lines 341-440 (100 LOC | Complexity 14) | used by 1 callers | [Io, CanPanic]
private static _assembleDiaryBlockPicker(entryId: string, afterNodeId: string = ''): object
//  â³ Calls: ShuaDiaryBlocks.entryId, SduiNodeBuilder.hydrateNode, ShuaDiaryBlocks.blockType, filter, SduiScreenAssembler.traverse, SduiBlockRegistry.all, Error, SduiBlueprintLoader.loadBlueprint
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler (Class)
```rust
// Lines 26-664 (639 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiScreenAssembler
```

#### SduiScreenAssembler._assembleDiaryAiConfig (Function)
```rust
// Lines 305-326 (22 LOC | Complexity 8) | used by 1 callers | [Pure]
private static _assembleDiaryAiConfig(params: Record<string, any>): object
//  â³ Calls: SduiNodeBuilder.buildScreen, DiaryRepository.getAiProviderConfig, getDiaryRepository
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler.makeOptionRow (Function)
```rust
// Lines 555-587 (33 LOC | Complexity 1) | used by 1 callers | [Pure]
const makeOptionRow = (
//  â³ Called by: SduiScreenAssembler._assembleDiaryOptionsModal
```

#### SduiScreenAssembler._assembleDiaryEditor (Function)
```rust
// Lines 199-303 (105 LOC | Complexity 16) | used by 1 callers | [Io, CanPanic]
private static _assembleDiaryEditor(entryId: string): object
//  â³ Calls: SduiBlockRegistry.buildContentNode, SduiBlockRegistry.get, ShuaDiaryEntries.title, ShuaDiaryBlocks.entryId, SduiNodeBuilder.hydrateNode, findNodeById, Error, SduiBlueprintLoader.loadBlueprint, DiaryRepository.getEntryWithBlocks, getDiaryRepository
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler._assembleDiaryOptionsModal (Function)
```rust
// Lines 554-662 (109 LOC | Complexity 1) | used by 1 callers | [Pure]
private static _assembleDiaryOptionsModal(entryId: string): object
//  â³ Calls: ShuaDiaryBlocks.entryId, SduiScreenAssembler.makeOptionRow
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler._assembleDiaryList (Function)
```rust
// Lines 66-195 (130 LOC | Complexity 18) | used by 1 callers | [Io, Tested]
private static _assembleDiaryList(params: Record<string, any>): object
//  â³ Calls: SduiNodeBuilder.buildScreen, ShuaSyncQueue.createdAt, ShuaDiaryEntries.title, EpisodicMemories.userId, SduiBlockRegistry.get, DiaryRepository.getMoodTimeline, DiaryRepository.searchEntries, filter, DiarySearchService.search, DiaryRepository.getEntryBlocks, DiarySearchService.getInstance, DiarySearchService.reconcile, ShuaSyncQueue.id, DiaryRepository.getEntriesList, getDiaryRepository
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler.traverse (Function)
```rust
// Lines 377-386 (10 LOC | Complexity 6) | used by 1 callers | [Pure]
const traverse = (node: any) =>
//  â³ Calls: SduiScreenAssembler.filterAndTrackWrap
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker
```

#### SduiScreenAssembler.filterAndTrackWrap (Function)
```rust
// Lines 362-374 (13 LOC | Complexity 6) | used by 1 callers | [Pure]
const filterAndTrackWrap = (node: any) =>
//  â³ Calls: filter
//  â³ Called by: SduiScreenAssembler.traverse
```

#### SduiScreenAssembler.assemble (Function)
```rust
// Lines 27-62 (36 LOC | Complexity 7) | used by 8 callers | [Async, Io, Tested]
static async assemble(screenId: string, params: Record<string, any>): Promise<object | null>
//  â³ Calls: SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryOptionsModal, SduiScreenAssembler._assembleDiaryAiPromptModal, SduiScreenAssembler._assembleDiaryAiConfig, SduiScreenAssembler._assembleDiaryList
//  â³ Called by: SduiOrchestrator.sendReplacePayload, SduiActionHandler._getMonthlySynthesis, SduiActionHandler._getBlocks, SduiActionHandler._createEntry, SduiActionHandler._searchDiary, SduiActionHandler._deleteEntry, SduiActionHandler._createBlock, SduiActionHandler._saveTitle
```

#### findNodeById (Function)
```rust
// Lines 668-684 (17 LOC | Complexity 11) | used by 1 callers | [Pure]
function findNodeById(node: any, id: string): any
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor
```

#### SduiScreenAssembler._assembleDiaryAiPromptModal (Function)
```rust
// Lines 457-539 (83 LOC | Complexity 3) | used by 1 callers | [Pure]
private static _assembleDiaryAiPromptModal(params: Record<string, any>): object
//  â³ Calls: EpisodicMemories.userId
//  â³ Called by: SduiScreenAssembler.assemble
```

### C:\horAIzon_2.0\shua_governor\src\logging\entry.rs (220 lines)

#### Visitor::Key (Enum)
```rust
// Lines 96-99 (4 LOC | Complexity 1) | used by 2 callers | [TraitMethod]
enum Key<'b>
//  â³ Called by: Visitor::visit_map, SduiRenderer
```

#### Visitor::expecting (Function)
```rust
// Lines 76-78 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result
```

#### Visitor::visit_map (Function)
```rust
// Lines 80-154 (75 LOC | Complexity 23) | used by 0 callers | [TraitMethod, MutatesState, HighComplexity]
fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
//  â³ Calls: BorrowedLogEntry, Visitor::Key, Error
```

#### LogEntry::from (Function)
```rust
// Lines 183-195 (13 LOC | Complexity 1) | used by 43 callers | [TraitMethod, Pure, CorePrimitive]
fn from(b: BorrowedLogEntry<'a>) -> Self
//  â³ Calls: LogEntry, BorrowedLogEntry, collect
//  â³ Called by: SduiNode, SduiStateVault, main, _SduiContainerState, HbpDiaryCodec.decodeSyncPayload, RadixTrie.searchWithMatches, _JoshAutomatedGenerationDialogState, LocalDatabase, main, serialize, SduiRegistry, _SduiSandboxScreenState, DiaryRepository.getAllEmbeddings, DiaryRepository.getBlockEmbedding, DiaryRepository.saveBlockEmbedding, serialize, export_sdg, DiarySearchService.reconcile, query_logs, try_forward, DiagnosticsHistoryNotifier, _JoshCoPilotPanelState, SduiListView, msgpackMiddleware, ensure_cgroup_dir, SduiSandboxScreen, SduiHeatmap, SduiGridView, SduiTransport, control_module, _SduiJbcPanelState, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, SduiBlockRegistry.all, test_regression_hardening, SduiEventDispatcher, serve_file, find_ghost_imports, SduiSocketManager, find_boundary_violations, trigger_scan, SduiShuaGridNode, _PinEntryScreenState
```

#### BorrowedLogEntry::Visitor (Struct)
```rust
// Lines 69-71 (3 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
struct Visitor<'a>
//  â³ Called by: BorrowedLogEntry::deserialize
```

#### BorrowedLogEntry::deserialize (Function)
```rust
// Lines 65-158 (94 LOC | Complexity 23) | used by 4 callers | [TraitMethod, MutatesState, HighComplexity]
fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
//  â³ Calls: BorrowedLogEntry, BorrowedLogEntry::Visitor, Error
//  â³ Called by: MessagePackCodec, SduiTransport, _SduiJbcPanelState, SduiSocketManager
```

#### log_min_level (Function)
```rust
// Lines 32-37 (6 LOC | Complexity 1) | used by 3 callers | [Pure]
pub fn log_min_level() -> u8
//  â³ Calls: ok
//  â³ Called by: harvest_socket_stream, ingest_log, harvest_pipe
```

#### LogEntry (Struct)
```rust
// Lines 170-180 (11 LOC | Complexity 1) | used by 13 callers | [CorePrimitive]
pub struct LogEntry
//  â³ Called by: main, wrap_socket_raw_line, harvest_socket_stream, start_log_ipc_listener, submitLog, LogEntry, wrap_raw_line, flush_loop, LogEntry::from, ChannelLogger::on_event, ChannelLogger::new, ChannelLogger, AppState
```

#### BorrowedLogEntry (Struct)
```rust
// Lines 52-62 (11 LOC | Complexity 1) | used by 6 callers
pub struct BorrowedLogEntry<'a>
//  â³ Called by: harvest_socket_stream, ingest_log, harvest_pipe, LogEntry::from, Visitor::visit_map, BorrowedLogEntry::deserialize
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\core\engine.py (415 lines)

#### MeterVisionEngine.get_ocr_model (Function)
```rust
// Lines 30-45 (16 LOC | Complexity 3) | used by 1 callers | [Io]
def get_ocr_model(cls)
//  â³ Calls: SduiBlockRegistry.load, CRNN
//  â³ Called by: MeterVisionEngine.run_ocr_crnn
```

#### MeterVisionEngine.get_model (Function)
```rust
// Lines 18-27 (10 LOC | Complexity 3) | used by 2 callers | [Io]
def get_model(cls, weights_path: str, fallback_path: str = "yolo11n.pt")
//  â³ Called by: YOLOMeterBackend.__init__, StandaloneWebAppHandler.get_model
```

#### MeterVisionEngine (Class)
```rust
// Lines 9-223 (215 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class MeterVisionEngine
```

#### MeterVisionEngine.run_ocr_crnn (Function)
```rust
// Lines 48-85 (38 LOC | Complexity 2) | used by 1 callers | [Pure]
def run_ocr_crnn(cls, img_bgr: np.ndarray) -> str
//  â³ Calls: ctc_greedy_decode, MeterVisionEngine.get_ocr_model
//  â³ Called by: MeterVisionEngine.process_image
```

#### MeterVisionEngine.process_image (Function)
```rust
// Lines 88-223 (136 LOC | Complexity 13) | used by 1 callers | [Io]
def process_image(cls, model, image_bytes: bytes, conf_threshold: float = 0.10)
//  â³ Calls: plot, MeterVisionEngine.run_ocr_crnn
//  â³ Called by: StandaloneWebAppHandler.do_POST
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\n8n\N8nAssistantProvider.ts (269 lines)

#### N8nAssistantProvider.baseUrl (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 4 callers | [Pure, TraitMethod]
private get baseUrl(): string { return ConfigProvider.n8nAssistantBaseUrl; }
//  â³ Called by: MediaUploader, MediaUploadResult, SduiEventDispatcher, _SduiDocumentViewerState
```

#### N8nAssistantProvider.generateSummary (Function)
```rust
// Lines 68-82 (15 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(content: string): Promise<string>
//  â³ Calls: Error
```

#### N8nAssistantProvider.generateTemplateStream (Function)
```rust
// Lines 52-64 (13 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateTemplateStream(topic: string, style: string): Promise<any>
//  â³ Calls: Error
```

#### N8nAssistantProvider.plannerRefactor (Function)
```rust
// Lines 117-160 (44 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async plannerRefactor(
//  â³ Calls: Error
```

#### N8nAssistantProvider (Class)
```rust
// Lines 19-161 (143 LOC | Complexity 1) | used by 1 callers
class N8nAssistantProvider implements IAssistantProvider
//  â³ Calls: IAssistantProvider
//  â³ Called by: AssistantService.getProvider
```

#### N8nAssistantProvider.chatStream (Function)
```rust
// Lines 86-113 (28 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async chatStream(
//  â³ Calls: Error
```

#### N8nAssistantProvider.generateTemplate (Function)
```rust
// Lines 24-48 (25 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateTemplate(
//  â³ Calls: Error
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\ghost_imports.rs (46 lines)

#### GhostImportReport (Struct)
```rust
// Lines 4-8 (5 LOC | Complexity 1) | used by 2 callers
pub struct GhostImportReport
//  â³ Called by: find_ghost_imports, DebugReport
```

#### find_ghost_imports (Function)
```rust
// Lines 10-50 (41 LOC | Complexity 8) | used by 1 callers | [MutatesState, CanPanic]
pub fn find_ghost_imports(state: &AppState) -> Vec<GhostImportReport>
//  â³ Calls: GhostImportReport, AppState, LogEntry::from
//  â³ Called by: debug_analysis
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_list_view.dart (103 lines)

#### SduiListView (Class)
```rust
// Lines 9-108 (100 LOC | Complexity 1) | used by 3 callers
class SduiListView extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiRenderer, LogEntry::from, _SduiShimmerLoaderState.maxHeight, BoundedRouteHistory.isEmpty, log, SduiNode.contentVal, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, _SduiShimmerLoaderState.padding, SduiNode.behavior, SduiListView._num, SduiListView._int
//  â³ Called by: SduiRegistry, SduiListView, SduiTypeRegistry
```

#### SduiListView.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiListView._num (Function)
```rust
// Lines 103-103 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
double? _num(int key)
//  â³ Called by: SduiListView
```

#### SduiListView._int (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
int? _int(int key)
//  â³ Called by: SduiListView
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\interfaces\i_jbc_chat.ts (34 lines)

#### IJbcChatProvider.compileJbc (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Async, Pure, FrameworkInvoked]
compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot
```

#### IJbcChatProvider.generateSummary (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 0 callers | [Async, Pure, PotentialDeadCode]
generateSummary(entryContent: string, entryTitle: string): Promise<string>
```

#### IJbcChatProvider (Interface)
```rust
// Lines 18-32 (15 LOC | Complexity 1) | used by 5 callers
interface IJbcChatProvider
//  â³ Called by: GeminiJbcProvider, DiaryAiSession.create, DiaryAiSession.constructor, N8nJbcProvider, OllamaJbcProvider
```

#### DiaryStateSnapshot (Interface)
```rust
// Lines 3-7 (5 LOC | Complexity 1) | used by 8 callers
interface DiaryStateSnapshot
//  â³ Called by: IJbcChatProvider.presentJbcStream, IJbcChatProvider.compileJbc, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc
```

#### IJbcChatProvider.presentJbcStream (Function)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult
```

#### JbcPlanResult (Interface)
```rust
// Lines 11-16 (6 LOC | Complexity 1) | used by 8 callers
interface JbcPlanResult
//  â³ Calls: JbcMutation
//  â³ Called by: IJbcChatProvider.presentJbcStream, IJbcChatProvider.compileJbc, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_divider.dart (214 lines)

#### _SduiDividerState (Class)
```rust
// Lines 23-221 (199 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDividerState extends ConsumerState<SduiDivider>
//  â³ Calls: SduiDivider, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onStateChange, ShuaSyncQueue.payload, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiDivider.createState
```

#### SduiDivider.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDivider> createState()
//  â³ Calls: SduiDivider, _SduiDividerState
```

#### _SduiDividerState.build (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiDivider (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 3 callers
class SduiDivider extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDividerState, SduiDivider.createState, SduiTypeRegistry
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_shimmer_loader.dart (312 lines)

#### _SduiShimmerLoaderState._buildListTile (Function)
```rust
// Lines 197-197 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildListTile(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildCircle (Function)
```rust
// Lines 170-170 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildCircle(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.initState (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiShimmerLoaderState._animated (Function)
```rust
// Lines 86-86 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _animated(Widget child, Color baseColor)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildMediaCard (Function)
```rust
// Lines 219-219 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMediaCard(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### SduiShimmerLoader.createState (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiShimmerLoader> createState()
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._circle (Function)
```rust
// Lines 150-150 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _circle(Color color, double diameter)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildFeedRow (Function)
```rust
// Lines 269-269 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildFeedRow(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### SduiShimmerLoader (Class)
```rust
// Lines 24-48 (25 LOC | Complexity 1) | used by 0 callers
class SduiShimmerLoader extends StatefulWidget
//  â³ Calls: _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState.shimmerAnimStyle, _SduiShimmerLoaderState.shimmerType, SduiShimmerLoader
```

#### _SduiShimmerLoaderState.build (Function)
```rust
// Lines 284-284 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiShimmerLoaderState._rect (Function)
```rust
// Lines 131-136 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _rect(
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildChatBubble (Function)
```rust
// Lines 236-236 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildChatBubble(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.dispose (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiShimmerLoaderState (Class)
```rust
// Lines 50-316 (267 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class _SduiShimmerLoaderState extends State<SduiShimmerLoader>
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState._animated, _SduiShimmerLoaderState._buildRectangle, _SduiShimmerLoaderState._buildFeedRow, _SduiShimmerLoaderState._buildStatCard, _SduiShimmerLoaderState._buildChatBubble, _SduiShimmerLoaderState._buildMediaCard, _SduiShimmerLoaderState._buildParagraph, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState.shimmerType, SduiFlexContext.of, _SduiShimmerLoaderState._buildListTile, _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.lineCount, generate, _SduiShimmerLoaderState._circle, _SduiShimmerLoaderState.maxHeight, c, _SduiShimmerLoaderState._rect, _SduiShimmerLoaderState.borderRadius, dispose, _SduiShimmerLoaderState.shimmerAnimStyle, initState, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildRectangle (Function)
```rust
// Lines 161-161 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildRectangle(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildParagraph (Function)
```rust
// Lines 177-177 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildParagraph(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildStatCard (Function)
```rust
// Lines 251-251 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStatCard(Color c)
//  â³ Calls: c
//  â³ Called by: _SduiShimmerLoaderState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_timeline.dart (686 lines)

#### TimelineHorizontalTrackPainter (Class)
```rust
// Lines 640-674 (35 LOC | Complexity 1) | used by 2 callers
class TimelineHorizontalTrackPainter extends CustomPainter
//  â³ Calls: TimelineTrackPainter.paint
//  â³ Called by: TimelineHorizontalTrackPainter.shouldRepaint, _SduiTimelineState
```

#### _SduiTimelineState._buildEmptyState (Function)
```rust
// Lines 558-558 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiTimelineState
```

#### TimelineTrackPainter (Class)
```rust
// Lines 604-638 (35 LOC | Complexity 1) | used by 2 callers
class TimelineTrackPainter extends CustomPainter
//  â³ Calls: TimelineTrackPainter.paint
//  â³ Called by: TimelineTrackPainter.shouldRepaint, _SduiTimelineState
```

#### _SduiTimelineState._buildHorizontalTimeline (Function)
```rust
// Lines 437-442 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHorizontalTimeline(
//  â³ Called by: _SduiTimelineState
```

#### SduiTimeline.createState (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiTimeline> createState()
//  â³ Calls: SduiTimeline, _SduiTimelineState
```

#### _SduiTimelineState._buildVerticalTimeline (Function)
```rust
// Lines 346-351 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildVerticalTimeline(
//  â³ Called by: _SduiTimelineState
```

#### TimelineHorizontalTrackPainter.paint (Function)
```rust
// Lines 652-652 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Calls: TimelineTrackPainter.paint
```

#### TimelineHorizontalTrackPainter.shouldRepaint (Function)
```rust
// Lines 669-669 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool shouldRepaint(covariant TimelineHorizontalTrackPainter oldDelegate)
//  â³ Calls: TimelineHorizontalTrackPainter, TimelineTrackPainter.shouldRepaint
```

#### _SduiTimelineState.dispose (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiTimelineState._buildNodeIcon (Function)
```rust
// Lines 528-528 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildNodeIcon(SduiTimelineEvent event, Color accentColor, ColorScheme colorScheme)
//  â³ Calls: SduiTimelineEvent
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState._parseFromTextLines (Function)
```rust
// Lines 152-152 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseFromTextLines(String text)
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState._parseData (Function)
```rust
// Lines 107-107 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseData()
//  â³ Called by: _SduiTimelineState
```

#### SduiTimelineEvent.fromMap (Function)
```rust
// Lines 594-594 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiTimelineEvent.fromMap(Map<dynamic, dynamic> map)
//  â³ Called by: SduiTimelineEvent.SduiTimelineEvent, _SduiTimelineState
```

#### _SduiTimelineState._getRawDataString (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getRawDataString()
//  â³ Called by: _SduiTimelineState
```

#### SduiTimelineEvent (Class)
```rust
// Lines 581-602 (22 LOC | Complexity 1) | used by 4 callers
class SduiTimelineEvent
//  â³ Calls: ShuaDiaryEntries.title
//  â³ Called by: _SduiTimelineState._buildNodeIcon, _SduiTimelineState._formatEventsToText, SduiTimelineEvent.SduiTimelineEvent, _SduiTimelineState
```

#### SduiTimelineEvent.SduiTimelineEvent (Function)
```rust
// Lines 594-594 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiTimelineEvent.fromMap(Map<dynamic, dynamic> map)
//  â³ Calls: SduiTimelineEvent.fromMap, SduiTimelineEvent
```

#### SduiTimeline (Class)
```rust
// Lines 14-26 (13 LOC | Complexity 1) | used by 4 callers
class SduiTimeline extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTimelineState.didUpdateWidget, _SduiTimelineState, SduiTimeline.createState, SduiTypeRegistry
```

#### TimelineTrackPainter.paint (Function)
```rust
// Lines 616-616 (1 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Called by: TimelineHorizontalTrackPainter, TimelineHorizontalTrackPainter.paint, TimelineTrackPainter
```

#### _SduiTimelineState.didUpdateWidget (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiTimeline oldWidget)
//  â³ Calls: SduiTimeline
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState.build (Function)
```rust
// Lines 197-197 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### TimelineTrackPainter.shouldRepaint (Function)
```rust
// Lines 633-633 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
bool shouldRepaint(covariant TimelineTrackPainter oldDelegate)
//  â³ Calls: TimelineTrackPainter
//  â³ Called by: TimelineHorizontalTrackPainter.shouldRepaint
```

#### _SduiTimelineState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiTimelineState._formatEventsToText (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatEventsToText(List<SduiTimelineEvent> events)
//  â³ Calls: SduiTimelineEvent
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState (Class)
```rust
// Lines 28-579 (552 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiTimelineState extends ConsumerState<SduiTimeline>
//  â³ Calls: SduiTimeline, SduiIconRegistry, TimelineHorizontalTrackPainter, _SduiTimelineState._buildNodeIcon, TimelineTrackPainter, generate, SduiEventDispatcher.onStateChange, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiTimelineState._buildVerticalTimeline, _SduiTimelineState._buildHorizontalTimeline, _SduiTimelineState._buildEmptyState, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, BoundedRouteHistory.isEmpty, _SduiTimelineState._parseFromTextLines, _SduiTimelineState._formatEventsToText, ShuaDiaryEntries.title, SduiTimelineEvent.fromMap, SduiTimelineEvent, SduiNode.contentVal, SduiNode.behavior, dispose, _SduiTimelineState.didUpdateWidget, _SduiTimelineState._getRawDataString, _SduiTimelineState._parseData, initState
//  â³ Called by: SduiTimeline.createState
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\adapters\standalone_web_app.py (167 lines)

#### StandaloneWebAppHandler.do_POST (Function)
```rust
// Lines 50-106 (57 LOC | Complexity 7) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
def do_POST(self)
//  â³ Calls: MobileEdgeEngine.process_image, StandaloneWebAppHandler.get_model, get_filename, walk, MessagePackCodec.encode
```

#### _load_template (Function)
```rust
// Lines 22-26 (5 LOC | Complexity 2) | used by 1 callers | [Pure]
def _load_template()
//  â³ Calls: run_server, RadixTrie.insert
//  â³ Called by: _load_template
```

#### StandaloneWebAppHandler (Class)
```rust
// Lines 30-106 (77 LOC | Complexity 1) | used by 1 callers
class StandaloneWebAppHandler(BaseHTTPRequestHandler)
//  â³ Called by: run_server
```

#### StandaloneWebAppHandler.do_GET (Function)
```rust
// Lines 39-48 (10 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def do_GET(self)
//  â³ Calls: MessagePackCodec.encode
```

#### StandaloneWebAppHandler.get_model (Function)
```rust
// Lines 32-34 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
def get_model(self)
//  â³ Calls: MobileEdgeEngine.get_model
//  â³ Called by: StandaloneWebAppHandler.do_POST
```

#### StandaloneWebAppHandler.log_message (Function)
```rust
// Lines 36-37 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def log_message(self, format, *args)
```

#### run_server (Function)
```rust
// Lines 108-120 (13 LOC | Complexity 2) | used by 2 callers | [Io]
def run_server(port=8086)
//  â³ Called by: _load_template, _load_template
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_container.dart (117 lines)

#### SduiContainer._resolveEdgeInsets (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
EdgeInsets _resolveEdgeInsets(dynamic val)
//  â³ Called by: SduiContainer
```

#### SduiContainer.build (Function)
```rust
// Lines 105-105 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiContainer (Class)
```rust
// Lines 11-124 (114 LOC | Complexity 1) | used by 0 callers
class SduiContainer extends StatelessWidget
//  â³ Calls: SduiContainer._resolveEdgeInsets, _SduiShimmerLoaderState.padding, SduiContainer._resolveThemeColor, onError, SduiFlexContext.of, SduiIconRegistry.contains, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiContainer
```

#### SduiContainer._resolveThemeColor (Function)
```rust
// Lines 60-60 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color? _resolveThemeColor(BuildContext context, dynamic token)
//  â³ Called by: SduiContainer
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\compiler\typst_compiler_test.go (37 lines)

#### TestCompileTypst (Function)
```rust
// Lines 9-45 (37 LOC | Complexity 4) | used by 0 callers | [Io, Tested, PotentialDeadCode]
func TestCompileTypst(t *testing.T)
//  â³ Calls: WorkItem, Basics, ResumeMatrix, CompileTypst
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_spacer.dart (333 lines)

#### SduiSpacer.createState (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSpacer> createState()
//  â³ Calls: SduiSpacer, _SduiSpacerState
```

#### DashedBorderPainter (Class)
```rust
// Lines 293-338 (46 LOC | Complexity 1) | used by 1 callers
class DashedBorderPainter extends CustomPainter
//  â³ Calls: DashedBorderPainter.paint
//  â³ Called by: _SduiSpacerState
```

#### _SduiSpacerState (Class)
```rust
// Lines 22-291 (270 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiSpacerState extends ConsumerState<SduiSpacer>
//  â³ Calls: SduiSpacer, DashedBorderPainter, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, RadixTrie.remove, SduiEventDispatcher.onStateChange, ShuaSyncQueue.payload, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiSpacer.createState
```

#### SduiSpacer (Class)
```rust
// Lines 8-20 (13 LOC | Complexity 1) | used by 3 callers
class SduiSpacer extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiSpacerState, SduiSpacer.createState, SduiTypeRegistry
```

#### DashedBorderPainter.shouldRepaint (Function)
```rust
// Lines 337-337 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool shouldRepaint(CustomPainter oldDelegate)
```

#### DashedBorderPainter.paint (Function)
```rust
// Lines 305-305 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Called by: DashedBorderPainter
```

#### _SduiSpacerState.build (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_governor\src\governor\supervisor.rs (165 lines)

#### start_supervisor_loop (Function)
```rust
// Lines 29-193 (165 LOC | Complexity 12) | used by 1 callers | [Async, MutatesState, Io, CanPanic, HighComplexity]
pub async fn start_supervisor_loop(
//  â³ Calls: SystemMetrics, ModuleMetrics, ModuleState, MetricsSnapshot, GcGuard::drop, display_state, RadixTrie.insert, read_cgroup_cpu_usec, read_memory_bytes, collect, build
//  â³ Called by: main
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\gemini\GeminiAnalyzerProvider.ts (223 lines)

#### GeminiAnalyzerProvider (Class)
```rust
// Lines 5-117 (113 LOC | Complexity 1) | used by 3 callers
class GeminiAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: GeminiAnalyzerProvider, DiaryAiSession.create, AnalyzerService.getProvider
```

#### GeminiAnalyzerProvider.modelName (Function)
```rust
// Lines 9-9 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
private get modelName() { return ConfigProvider.geminiAnalyzerModel; }
```

#### GeminiAnalyzerProvider.analyze (Function)
```rust
// Lines 11-116 (106 LOC | Complexity 10) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod, Tested]
async analyze(content: string, onProgress?: (data: string) => void): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, ShuaDiaryEntries.milestoneTag, ShuaDiaryEntries.sentimentScore, GeminiRateLimiter.execute, log, filter, Error, warn
```

#### GeminiAnalyzerProvider.apiKey (Function)
```rust
// Lines 6-8 (3 LOC | Complexity 2) | used by 0 callers | [Pure, TraitMethod]
private get apiKey()
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\analyze_entry.ts (38 lines)

#### AnalyzeEntryHandler (Class)
```rust
// Lines 3-22 (20 LOC | Complexity 1) | used by 1 callers
class AnalyzeEntryHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### AnalyzeEntryHandler.handle (Function)
```rust
// Lines 4-21 (18 LOC | Complexity 2) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode
```

### C:\horAIzon_2.0\client_flutter\lib\app\theme\theme_compiler.dart (43 lines)

#### ThemeCompiler.compile (Function)
```rust
// Lines 5-10 (6 LOC | Complexity 1) | used by 7 callers | [Pure, Tested]
static ThemeData compile(
//  â³ Called by: clean_code, clean_code, ThemeState.compiledData, main, rewrite_markdown_links, extract_h1_title, summarize_dart_files
```

#### ThemeCompiler (Class)
```rust
// Lines 4-40 (37 LOC | Complexity 1) | used by 1 callers
class ThemeCompiler
//  â³ Called by: ThemeState.compiledData
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_slider.dart (196 lines)

#### _SduiSliderState._normalize (Function)
```rust
// Lines 98-98 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double _normalize(double raw)
//  â³ Called by: _SduiSliderState
```

#### SduiSlider.createState (Function)
```rust
// Lines 62-62 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiSlider> createState()
//  â³ Calls: SduiSlider, _SduiSliderState
```

#### _SduiSliderState._resolveAccentColor (Function)
```rust
// Lines 105-105 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveAccentColor(BuildContext context)
//  â³ Called by: _SduiSliderState
```

#### _SduiSliderState.initState (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiSliderState.build (Function)
```rust
// Lines 117-117 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiSlider (Class)
```rust
// Lines 22-63 (42 LOC | Complexity 1) | used by 0 callers
class SduiSlider extends StatefulWidget
//  â³ Calls: SliderMode, SduiSlider
```

#### SliderMode (Class)
```rust
// Lines 5-8 (4 LOC | Complexity 1) | used by 3 callers
abstract final class SliderMode
//  â³ Called by: SduiRegistry, _SduiSliderState, SduiSlider
```

#### _SduiSliderState.didUpdateWidget (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiSlider oldWidget)
//  â³ Calls: SduiSlider
//  â³ Called by: _SduiSliderState
```

#### _SduiSliderState (Class)
```rust
// Lines 65-208 (144 LOC | Complexity 1) | used by 0 callers
class _SduiSliderState extends State<SduiSlider>
//  â³ Calls: SduiSlider, _SduiSliderState._normalize, SliderMode, _SduiSliderState._resolveAccentColor, SduiFlexContext.of, _SduiSliderState.didUpdateWidget, initState, _SduiSliderState
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\convert_dataset_split.py (209 lines)

#### main (Function)
```rust
// Lines 17-225 (209 LOC | Complexity 30) | used by 0 callers | [Io, EntryPoint, HighComplexity]
def main()
//  â³ Calls: main, resolve_image_path, RadixTrie.remove, SduiBlockRegistry.get, SduiBlockRegistry.load, find_latest_export, RadixTrie.insert
```

### C:\horAIzon_2.0\tools\summarize_primitives.py (66 lines)

#### summarize_dart_files (Function)
```rust
// Lines 3-68 (66 LOC | Complexity 10) | used by 0 callers | [Async, Pure, PotentialDeadCode]
def summarize_dart_files(directory, output_file)
//  â³ Calls: ThemeCompiler.compile
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\chat.ts (136 lines)

#### ChatHandler (Class)
```rust
// Lines 5-73 (69 LOC | Complexity 1) | used by 1 callers
class ChatHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### ChatHandler.handle (Function)
```rust
// Lines 6-72 (67 LOC | Complexity 9) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode, JbcTranslator.translate, JbcTranslator.parse
```

### C:\horAIzon_2.0\shua_governor\src\main.rs (288 lines)

#### main (Function)
```rust
// Lines 28-315 (288 LOC | Complexity 9) | used by 30 callers | [EntryPoint, Async, MutatesState, Io, CanPanic, CorePrimitive, HighComplexity]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>>
//  â³ Calls: AppState, MetricsSnapshot, LogEntry, Error, create_router, start_subconscious_embedder_loop, start_gc_loop, start_disk_monitor_loop, start_supervisor_loop, new_media_stats, ok, LogEntry::from, new_system_metrics, RadixTrie.insert, load_from_json, new_registry, start_log_ipc_listener, flush_loop, init
//  â³ Called by: OCRReviewerApp, main, main, get_available_fonts, HorAIzonClientShell, is_port_in_use, load_contracts, main, _load_data, clean_code, find_all_exports, safe_remove, main, analyze_text_rules, main, is_port_in_use, clean_code, main, main, new_block_id, load_contracts, main, load_contracts, main, main, main, main, decode_str, load_contracts, deep_merge
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\jbc\jbc_translator.ts (566 lines)

#### JbcTranslator.translate (Function)
```rust
// Lines 116-193 (78 LOC | Complexity 19) | used by 0 callers | [MutatesState, Io, Tested, PotentialDeadCode]
static translate(bytecode: string, activeBlocks: any[]): string
//  â³ Calls: warn, SduiBlockRegistry.isSystemOwned, JbcTranslator.resolveId, JbcTranslator.selfHealLine, filter
```

#### JbcTranslator.parse (Function)
```rust
// Lines 199-282 (84 LOC | Complexity 18) | used by 2 callers | [MutatesState, Io, Tested]
static parse(bytecode: string, activeBlocks?: any[]): { intent: 'MUTATE' | 'SUGGEST_TEMPLATE' | 'CONVERSE' | 'NO_OP'; mutations: JbcMutation[] }
//  â³ Calls: JbcMutation, warn, SduiBlockRegistry.isSystemOwned, JbcTranslator.resolveId, JbcTranslator.selfHealLine, filter
//  â³ Called by: GeminiJbcProvider.presentJbcStream, OllamaJbcProvider.presentJbcStream
```

#### JbcTranslator (Class)
```rust
// Lines 11-303 (293 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class JbcTranslator
//  â³ Calls: JbcTranslator
```

#### JbcMutation (Interface)
```rust
// Lines 3-9 (7 LOC | Complexity 1) | used by 0 callers
interface JbcMutation
//  â³ Calls: JbcMutation
```

#### JbcTranslator.serializeDiaryState (Function)
```rust
// Lines 288-302 (15 LOC | Complexity 5) | used by 0 callers | [Pure, PotentialDeadCode]
static serializeDiaryState(blocks: any[]): string
```

#### JbcTranslator.resolveId (Function)
```rust
// Lines 96-109 (14 LOC | Complexity 5) | used by 2 callers | [Pure]
private static resolveId(id: string, activeBlocks?: any[]): string
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

#### JbcTranslator.selfHealLine (Function)
```rust
// Lines 16-90 (75 LOC | Complexity 22) | used by 2 callers | [Pure, HighComplexity]
private static selfHealLine(line: string): string
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\ollama_analyzer_provider.ts (197 lines)

#### OllamaAnalyzerProvider.analyze (Function)
```rust
// Lines 10-101 (92 LOC | Complexity 9) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod, Tested]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, IAnalyzerProvider.analyze, warn, ShuaDiaryEntries.sentimentScore, Error, filter
```

#### OllamaAnalyzerProvider (Class)
```rust
// Lines 3-102 (100 LOC | Complexity 1) | used by 0 callers
class OllamaAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider, OllamaAnalyzerProvider
```

#### OllamaAnalyzerProvider.constructor (Function)
```rust
// Lines 4-8 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: IAnalyzerProvider
```

### C:\horAIzon_2.0\blueprints\tools\compile_context.py (167 lines)

#### generate_tree (Function)
```rust
// Lines 38-55 (18 LOC | Complexity 5) | used by 1 callers | [Pure]
def generate_tree(dir_path, prefix="")
//  â³ Called by: compile_blueprints
```

#### get_chunk_filename (Function)
```rust
// Lines 101-102 (2 LOC | Complexity 1) | used by 1 callers | [Pure]
def get_chunk_filename(chunk_num)
//  â³ Called by: compile_blueprints
```

#### compile_blueprints (Function)
```rust
// Lines 57-177 (121 LOC | Complexity 18) | used by 2 callers | [Io, Cycle]
def compile_blueprints()
//  â³ Calls: MessagePackCodec.encode, DiaryRepository.close, minify_markdown, generate_tree, get_chunk_filename
//  â³ Called by: minify_markdown, compile_blueprints
```

#### minify_markdown (Function)
```rust
// Lines 11-36 (26 LOC | Complexity 3) | used by 1 callers | [Pure, Cycle]
def minify_markdown(text)
//  â³ Calls: compile_blueprints
//  â³ Called by: compile_blueprints
```

### C:\horAIzon_2.0\scripts\generate_synthetic_ocr.py (201 lines)

#### generate_synthetic_crop (Function)
```rust
// Lines 93-208 (116 LOC | Complexity 11) | used by 1 callers | [Pure]
def generate_synthetic_crop(label, font_paths)
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 211-249 (39 LOC | Complexity 6) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: generate_synthetic_crop, generate_random_label, get_available_fonts, RadixTrie.remove
```

#### generate_random_label (Function)
```rust
// Lines 51-91 (41 LOC | Complexity 3) | used by 1 callers | [Pure]
def generate_random_label()
//  â³ Called by: main
```

#### get_available_fonts (Function)
```rust
// Lines 45-49 (5 LOC | Complexity 2) | used by 1 callers | [Io]
def get_available_fonts()
//  â³ Calls: main
//  â³ Called by: main
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\routes\block_router.ts (42 lines)

#### DiaryBlockPayload (Interface)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 1 callers
interface DiaryBlockPayload
//  â³ Calls: TagSearchService.clearTrie, TagSearchService.searchTagsWithMatches, AssistantService.plannerRefactor, AssistantService.chatStream, AssistantService.generateSummary, AssistantService.generateTemplateStream, flushBlock, AnalysisWorker.getStatus, AnalyzerService.analyze, AnalysisWorker.enqueue, TagSearchService.indexBlockContent, HbpDiaryCodec.decodeSyncPayload, log, run, AnalysisWorker.getInstance, TagSearchService, AssistantService, AnalyzerService
//  â³ Called by: SyncPayload
```

#### flushBlock (Function)
```rust
// Lines 375-405 (31 LOC | Complexity 11) | used by 2 callers | [Pure, Tested]
const flushBlock = () =>
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: parseMarkdown, DiaryBlockPayload
```

#### SyncPayload (Interface)
```rust
// Lines 30-34 (5 LOC | Complexity 1) | used by 0 callers
interface SyncPayload
//  â³ Calls: DiaryBlockPayload
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\graph.rs (77 lines)

#### get_graph (Function)
```rust
// Lines 36-86 (51 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, CanPanic, ApiRoute]
pub async fn get_graph(State(state): State<AppState>) -> Json<GraphPayload>
//  â³ Calls: GraphLink, GraphNode, GraphPayload, AppState, collect
```

#### GraphNode (Struct)
```rust
// Lines 5-20 (16 LOC | Complexity 1) | used by 2 callers
pub struct GraphNode
//  â³ Called by: get_graph, GraphPayload
```

#### GraphPayload (Struct)
```rust
// Lines 31-34 (4 LOC | Complexity 1) | used by 1 callers
pub struct GraphPayload
//  â³ Calls: GraphLink, GraphNode
//  â³ Called by: get_graph
```

#### GraphLink (Struct)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 2 callers
pub struct GraphLink
//  â³ Called by: get_graph, GraphPayload
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\request_screen.ts (14 lines)

#### RequestScreenHandler (Class)
```rust
// Lines 3-10 (8 LOC | Complexity 1) | used by 1 callers
class RequestScreenHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### RequestScreenHandler.handle (Function)
```rust
// Lines 4-9 (6 LOC | Complexity 1) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, SduiOrchestrator.sendReplacePayload
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_drawing_pad.dart (230 lines)

#### SduiDrawingPad.createState (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDrawingPad> createState()
//  â³ Calls: SduiDrawingPad, _SduiDrawingPadState
```

#### _SduiDrawingPadState._parseSvgPathToStrokes (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseSvgPathToStrokes(String svg)
//  â³ Called by: _SduiDrawingPadState
```

#### SduiDrawingPad (Class)
```rust
// Lines 8-20 (13 LOC | Complexity 1) | used by 3 callers
class SduiDrawingPad extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDrawingPadState, SduiDrawingPad.createState, SduiTypeRegistry
```

#### _SduiDrawingPadState (Class)
```rust
// Lines 22-199 (178 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDrawingPadState extends ConsumerState<SduiDrawingPad>
//  â³ Calls: SduiDrawingPad, _SduiShimmerLoaderState.padding, _SduiDrawingPadState._clearCanvas, _DrawingPainter, _SduiDrawingPadState._serializeStrokes, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiDrawingPadState._parseSvgPathToStrokes, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of, SduiEventDispatcher.onStateChange, BoundedRouteHistory.isEmpty, SduiStateVault.clear
//  â³ Called by: SduiDrawingPad.createState
```

#### _DrawingPainter (Class)
```rust
// Lines 201-232 (32 LOC | Complexity 1) | used by 2 callers
class _DrawingPainter extends CustomPainter
//  â³ Calls: BoundedRouteHistory.isEmpty, _DrawingPainter.paint
//  â³ Called by: _DrawingPainter.shouldRepaint, _SduiDrawingPadState
```

#### _SduiDrawingPadState.build (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _DrawingPainter.paint (Function)
```rust
// Lines 211-211 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Called by: _DrawingPainter
```

#### _SduiDrawingPadState._clearCanvas (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _clearCanvas(String bindKey)
//  â³ Called by: _SduiDrawingPadState
```

#### _SduiDrawingPadState._serializeStrokes (Function)
```rust
// Lines 46-46 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _serializeStrokes()
//  â³ Called by: _SduiDrawingPadState
```

#### _DrawingPainter.shouldRepaint (Function)
```rust
// Lines 229-229 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool shouldRepaint(covariant _DrawingPainter oldDelegate)
//  â³ Calls: _DrawingPainter
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_toggle.dart (63 lines)

#### SduiToggle (Class)
```rust
// Lines 7-23 (17 LOC | Complexity 1) | used by 6 callers
class SduiToggle extends StatefulWidget
//  â³ Called by: _SduiToggleState.didUpdateWidget, _SduiToggleState, SduiToggle.createState, SduiRegistry, SduiToggle, SduiTypeRegistry
```

#### _SduiToggleState.didUpdateWidget (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiToggle oldWidget)
//  â³ Calls: SduiToggle
//  â³ Called by: _SduiToggleState
```

#### _SduiToggleState.initState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiToggleState (Class)
```rust
// Lines 25-66 (42 LOC | Complexity 1) | used by 1 callers
class _SduiToggleState extends State<SduiToggle>
//  â³ Calls: SduiToggle, SduiFlexContext.of, _SduiToggleState.didUpdateWidget, initState
//  â³ Called by: SduiToggle.createState
```

#### _SduiToggleState.build (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiToggle.createState (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiToggle> createState()
//  â³ Calls: SduiToggle, _SduiToggleState
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\training\train_ocr.py (535 lines)

#### _char_accuracy (Function)
```rust
// Lines 259-269 (11 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
def _char_accuracy(preds: list[str], targets: list[str]) -> float
//  â³ Calls: levenshtein_distance
```

#### _encode_label (Function)
```rust
// Lines 203-204 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _encode_label(text: str) -> list[int]
```

#### load_samples (Function)
```rust
// Lines 331-346 (16 LOC | Complexity 4) | used by 0 callers | [Io, PotentialDeadCode]
def load_samples() -> list[tuple]
```

#### _compute_detailed_metrics (Function)
```rust
// Lines 276-328 (53 LOC | Complexity 8) | used by 2 callers | [Pure]
def _compute_detailed_metrics(preds: list[str], targets: list[str]) -> dict
//  â³ Calls: _full_string_accuracy, _char_accuracy
//  â³ Called by: _write_history_md, train
```

#### _collate (Function)
```rust
// Lines 228-233 (6 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _collate(batch)
```

#### SerialOCRDataset.__init__ (Function)
```rust
// Lines 208-210 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self, samples: list[tuple], augment: bool = False)
```

#### SerialOCRDataset (Class)
```rust
// Lines 207-225 (19 LOC | Complexity 1) | used by 0 callers
class SerialOCRDataset(Dataset)
```

#### SerialOCRDataset.__getitem__ (Function)
```rust
// Lines 215-225 (11 LOC | Complexity 3) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __getitem__(self, idx)
//  â³ Calls: _encode_label, _augment, _preprocess_crop, _spatial_augment
```

#### _full_string_accuracy (Function)
```rust
// Lines 272-273 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _full_string_accuracy(preds: list[str], targets: list[str]) -> float
```

#### SerialOCRDataset.__len__ (Function)
```rust
// Lines 212-213 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def __len__(self)
```

#### test (Function)
```rust
// Lines 596-617 (22 LOC | Complexity 3) | used by 8 callers | [Io, Tested]
def test()
//  â³ Calls: ctc_greedy_decode, _preprocess_crop, load_samples, load_ocr_model
//  â³ Called by: OllamaAnalyzerProvider.analyze, _spatial_augment, OllamaAssistantProvider.generateSummary, GeminiJbcProvider.generateSummary, OllamaJbcProvider.generateSummary, SduiDropdown, filter, GeminiAssistantProvider.generateSummary
```

#### _spatial_augment (Function)
```rust
// Lines 65-83 (19 LOC | Complexity 2) | used by 1 callers | [Pure]
def _spatial_augment(img_bgr: np.ndarray) -> np.ndarray
//  â³ Calls: train, test, RadixTrie.insert
//  â³ Called by: SerialOCRDataset.__getitem__
```

#### _upsample_minority_classes (Function)
```rust
// Lines 86-113 (28 LOC | Complexity 7) | used by 1 callers | [Io]
def _upsample_minority_classes(samples: list[tuple]) -> list[tuple]
//  â³ Called by: train
```

#### _write_history_md (Function)
```rust
// Lines 519-590 (72 LOC | Complexity 12) | used by 1 callers | [Io]
def _write_history_md(history, best_acc, preds, targets, resumed=False)
//  â³ Calls: _compute_detailed_metrics
//  â³ Called by: train
```

#### levenshtein_distance (Function)
```rust
// Lines 239-256 (18 LOC | Complexity 5) | used by 0 callers | [Pure, PotentialDeadCode]
def levenshtein_distance(s1: str, s2: str) -> int
//  â³ Calls: levenshtein_distance
```

#### train (Function)
```rust
// Lines 349-516 (168 LOC | Complexity 18) | used by 0 callers | [Io, Tested, HighComplexity, PotentialDeadCode]
def train(epochs: int = 100, resume_flag: bool = False)
//  â³ Calls: _compute_detailed_metrics, _write_history_md, _full_string_accuracy, _char_accuracy, ctc_greedy_decode, train, SduiBlockRegistry.load, CRNN, SerialOCRDataset, _upsample_minority_classes, load_samples
```

#### _preprocess_crop (Function)
```rust
// Lines 116-133 (18 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def _preprocess_crop(img_bgr: np.ndarray) -> np.ndarray
```

#### _augment (Function)
```rust
// Lines 136-200 (65 LOC | Complexity 10) | used by 2 callers | [Pure]
def _augment(img: np.ndarray) -> np.ndarray
//  â³ Called by: SerialOCRDataset.__getitem__, KWHDataset.__getitem__
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\resolver.rs (90 lines)

#### clean_path (Function)
```rust
// Lines 11-26 (16 LOC | Complexity 5) | used by 1 callers | [MutatesState]
pub fn clean_path(path: &Path) -> PathBuf
//  â³ Called by: resolve_import
```

#### resolve_import (Function)
```rust
// Lines 28-97 (70 LOC | Complexity 19) | used by 1 callers | [MutatesState]
pub fn resolve_import(source_file: &Path, raw_target: &str, lang: Language) -> ResolvedTarget
//  â³ Calls: ResolvedTarget, Language, log_verbose, clean_path
//  â³ Called by: extract_imports
```

#### ResolvedTarget (Enum)
```rust
// Lines 5-8 (4 LOC | Complexity 1) | used by 2 callers
pub enum ResolvedTarget
//  â³ Called by: extract_imports, resolve_import
```

### C:\horAIzon_2.0\shua_governor\src\routes\module_control.rs (398 lines)

#### wrap_raw_line (Function)
```rust
// Lines 414-432 (19 LOC | Complexity 3) | used by 1 callers | [Io]
fn wrap_raw_line(line: &str, module_u8: u8, is_stderr: bool) -> Option<LogEntry>
//  â³ Calls: LogEntry
//  â³ Called by: harvest_pipe
```

#### control_module (Function)
```rust
// Lines 27-246 (220 LOC | Complexity 21) | used by 0 callers | [Async, MutatesState, CanPanic, ApiRoute, HighComplexity]
pub async fn control_module(
//  â³ Calls: AppState, kill, unfreeze, freeze, assign_pid, harvest_pipe, DiaryRepository.close, LogEntry::from, ensure_cgroup_dir, RadixTrie.insert
```

#### module_id_to_u8 (Function)
```rust
// Lines 436-450 (15 LOC | Complexity 12) | used by 1 callers | [Pure]
fn module_id_to_u8(id: &str) -> u8
//  â³ Called by: harvest_pipe
```

#### harvest_pipe (Function)
```rust
// Lines 264-380 (117 LOC | Complexity 19) | used by 1 callers | [Async, MutatesState]
async fn harvest_pipe<R>(
//  â³ Calls: BorrowedLogEntry, read_until_newline, wrap_raw_line, module_id_to_u8, log_min_level
//  â³ Called by: control_module
```

#### read_until_newline (Function)
```rust
// Lines 384-410 (27 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, Io, PotentialDeadCode]
async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\logging.rs (201 lines)

#### log_status (Function)
```rust
// Lines 193-200 (8 LOC | Complexity 2) | used by 1 callers | [Io]
pub fn log_status(subsystem: &str, message: &str)
//  â³ Calls: SduiBlockRegistry.load
//  â³ Called by: run_full_scan
```

#### FieldVisitor::record_str (Function)
```rust
// Lines 47-53 (7 LOC | Complexity 2) | used by 0 callers | [TraitMethod, MutatesState]
fn record_str(&mut self, field: &tracing::field::Field, value: &str)
//  â³ Calls: RadixTrie.insert
```

#### HbpLoggerLayer (Struct)
```rust
// Lines 16-18 (3 LOC | Complexity 1) | used by 0 callers
pub struct HbpLoggerLayer
//  â³ Calls: HbpLoggerLayer::new
```

#### FieldVisitor::record_i64 (Function)
```rust
// Lines 59-61 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn record_i64(&mut self, field: &tracing::field::Field, value: i64)
//  â³ Calls: RadixTrie.insert
```

#### FieldVisitor::record_u64 (Function)
```rust
// Lines 55-57 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn record_u64(&mut self, field: &tracing::field::Field, value: u64)
//  â³ Calls: RadixTrie.insert
```

#### FieldVisitor::record_debug (Function)
```rust
// Lines 38-45 (8 LOC | Complexity 2) | used by 0 callers | [TraitMethod, MutatesState]
fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug)
//  â³ Calls: Debug, RadixTrie.insert
```

#### FieldVisitor::record_bool (Function)
```rust
// Lines 63-65 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn record_bool(&mut self, field: &tracing::field::Field, value: bool)
//  â³ Calls: RadixTrie.insert
```

#### HbpLoggerLayer::HbpLogMsgpack (Struct)
```rust
// Lines 134-156 (23 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
struct HbpLogMsgpack
//  â³ Called by: HbpLoggerLayer::on_event
```

#### FieldVisitor (Struct)
```rust
// Lines 32-35 (4 LOC | Complexity 1) | used by 1 callers
struct FieldVisitor
//  â³ Called by: HbpLoggerLayer::on_event
```

#### log_verbose (Function)
```rust
// Lines 202-212 (11 LOC | Complexity 3) | used by 9 callers | [Io]
pub fn log_verbose(subsystem: &str, message: &str)
//  â³ Calls: SduiBlockRegistry.load
//  â³ Called by: deduplicate_edges, resolve_type_ref_edges, resolve_call_edges, resolve_import, assign_tags, detect_test_linkages, detect_entry_points, extract_declarations, run_full_scan
```

#### map_level (Function)
```rust
// Lines 69-77 (9 LOC | Complexity 6) | used by 1 callers | [Pure]
fn map_level(level: &Level) -> u8
//  â³ Called by: HbpLoggerLayer::on_event
```

#### HbpLoggerLayer::new (Function)
```rust
// Lines 21-28 (8 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
pub fn new() -> Self
//  â³ Calls: ok
//  â³ Called by: main, HbpLoggerLayer::on_event, HbpLoggerLayer
```

#### HbpLoggerLayer::on_event (Function)
```rust
// Lines 80-190 (111 LOC | Complexity 5) | used by 0 callers | [TraitMethod, MutatesState, Io]
fn on_event(&self, event: &Event<'_>, _ctx: Context<'_, S>)
//  â³ Calls: HbpLoggerLayer::HbpLogMsgpack, FieldVisitor, RadixTrie.remove, HbpLoggerLayer::new, map_level, ShuaDiaryBlocks.metadata
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\train.py (76 lines)

#### train (Function)
```rust
// Lines 17-92 (76 LOC | Complexity 6) | used by 9 callers | [Io, Tested]
def train(refresh=False, epochs=50)
//  â³ Calls: SduiStateVault.dump
//  â³ Called by: _spatial_augment, train, main, _preprocess_crop, train, load_kwh_samples, train, load_synth_samples, train
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\convert_dataset_nobarcode.py (182 lines)

#### main (Function)
```rust
// Lines 18-199 (182 LOC | Complexity 31) | used by 0 callers | [Io, EntryPoint, HighComplexity]
def main()
//  â³ Calls: main, resolve_image_path, RadixTrie.remove, SduiBlockRegistry.get, SduiBlockRegistry.load, find_latest_export, RadixTrie.insert
```

### C:\horAIzon_2.0\shua_governor\src\governor\registry.rs (138 lines)

#### default_exec_cmd (Function)
```rust
// Lines 122-124 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_exec_cmd() -> String
```

#### new_registry (Function)
```rust
// Lines 133-135 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn new_registry() -> ModuleRegistry
//  â³ Called by: main
```

#### new_system_metrics (Function)
```rust
// Lines 162-164 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn new_system_metrics() -> SharedSystemMetrics
//  â³ Called by: main
```

#### default_host (Function)
```rust
// Lines 110-112 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_host() -> String
```

#### load_from_json (Function)
```rust
// Lines 179-191 (13 LOC | Complexity 3) | used by 1 callers | [Async, Io]
pub async fn load_from_json(
//  â³ Calls: RegistryManifest, Error, ModuleEntry
//  â³ Called by: main
```

#### RegistryManifest (Struct)
```rust
// Lines 185-187 (3 LOC | Complexity 1) | used by 1 callers
struct RegistryManifest
//  â³ Calls: ModuleEntry
//  â³ Called by: load_from_json
```

#### SystemMetrics (Struct)
```rust
// Lines 145-157 (13 LOC | Complexity 1) | used by 1 callers
pub struct SystemMetrics
//  â³ Called by: start_supervisor_loop
```

#### ModuleState (Enum)
```rust
// Lines 13-31 (19 LOC | Complexity 1) | used by 4 callers
pub enum ModuleState
//  â³ Called by: start_supervisor_loop, display_state, default_state, ModuleEntry
```

#### display_state (Function)
```rust
// Lines 167-176 (10 LOC | Complexity 7) | used by 2 callers | [Pure]
pub fn display_state(state: &ModuleState) -> String
//  â³ Calls: ModuleState
//  â³ Called by: start_supervisor_loop, inject_module_telemetry
```

#### default_state (Function)
```rust
// Lines 118-120 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_state() -> ModuleState
//  â³ Calls: ModuleState
```

#### default_shimmer_style (Function)
```rust
// Lines 114-116 (3 LOC | Complexity 1) | used by 0 callers | [Pure, SerdeCallback]
fn default_shimmer_style() -> String
```

#### ModuleEntry (Struct)
```rust
// Lines 47-108 (62 LOC | Complexity 1) | used by 3 callers
pub struct ModuleEntry
//  â³ Calls: ModuleState
//  â³ Called by: RegistryManifest, load_from_json, inject_module_telemetry
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\start_mobile_vision.py (89 lines)

#### main (Function)
```rust
// Lines 12-97 (86 LOC | Complexity 14) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: is_port_in_use
```

#### is_port_in_use (Function)
```rust
// Lines 8-10 (3 LOC | Complexity 1) | used by 2 callers | [Io]
def is_port_in_use(port)
//  â³ Calls: main
//  â³ Called by: main, main
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\callgraph.rs (706 lines)

#### resolve_type_ref_edges (Function)
```rust
// Lines 550-663 (114 LOC | Complexity 29) | used by 1 callers | [MutatesState, CanPanic, HighComplexity]
fn resolve_type_ref_edges(
//  â³ Calls: DependencyEdge, AppState, SduiIconRegistry.contains, log_verbose
//  â³ Called by: resolve_edges
```

#### resolve_edges (Function)
```rust
// Lines 335-344 (10 LOC | Complexity 1) | used by 1 callers | [CanPanic]
pub fn resolve_edges(state: &AppState)
//  â³ Calls: AppState, deduplicate_edges, resolve_type_ref_edges, resolve_call_edges, build_symbol_indices
//  â³ Called by: run_full_scan
```

#### extract_call_sites (Function)
```rust
// Lines 99-224 (126 LOC | Complexity 17) | used by 1 callers | [MutatesState, CanPanic]
pub fn extract_call_sites(
//  â³ Calls: AppState, Language, find_first_string_literal_in_ancestor, get_tree_sitter_language, get_parser
//  â³ Called by: parse_and_index_file
```

#### extract_imports (Function)
```rust
// Lines 7-96 (90 LOC | Complexity 16) | used by 1 callers | [MutatesState]
pub fn extract_imports(
//  â³ Calls: ResolvedTarget, AppState, Language, resolve_import, get_tree_sitter_language, get_parser
//  â³ Called by: parse_and_index_file
```

#### find_first_string_literal_in_ancestor (Function)
```rust
// Lines 242-259 (18 LOC | Complexity 5) | used by 1 callers | [MutatesState]
fn find_first_string_literal_in_ancestor(node: tree_sitter::Node, source: &[u8]) -> Option<String>
//  â³ Calls: find_string_literal
//  â³ Called by: extract_call_sites
```

#### find_string_literal (Function)
```rust
// Lines 226-240 (15 LOC | Complexity 5) | used by 1 callers | [MutatesState]
fn find_string_literal(node: tree_sitter::Node, source: &[u8]) -> Option<String>
//  â³ Calls: walk
//  â³ Called by: find_first_string_literal_in_ancestor
```

#### build_symbol_indices (Function)
```rust
// Lines 346-373 (28 LOC | Complexity 3) | used by 1 callers | [MutatesState]
fn build_symbol_indices(
//  â³ Calls: DependencyEdge, SymbolNode
//  â³ Called by: resolve_edges
```

#### test_dart_method_call_ast (Function)
```rust
// Lines 699-731 (33 LOC | Complexity 3) | used by 0 callers | [MutatesState, CanPanic]
fn test_dart_method_call_ast()
//  â³ Calls: get_tree_sitter_language, get_parser
```

#### deduplicate_edges (Function)
```rust
// Lines 665-690 (26 LOC | Complexity 4) | used by 1 callers | [MutatesState, CanPanic]
fn deduplicate_edges(state: &AppState)
//  â³ Calls: AppState, RadixTrie.insert, log_verbose
//  â³ Called by: resolve_edges
```

#### extract_type_references (Function)
```rust
// Lines 262-333 (72 LOC | Complexity 15) | used by 1 callers | [MutatesState, CanPanic]
pub fn extract_type_references(
//  â³ Calls: AppState, Language, get_tree_sitter_language, get_parser
//  â³ Called by: parse_and_index_file
```

#### resolve_call_edges (Function)
```rust
// Lines 375-548 (174 LOC | Complexity 39) | used by 1 callers | [MutatesState, CanPanic, HighComplexity]
fn resolve_call_edges(
//  â³ Calls: DependencyEdge, AppState, SduiBlockRegistry.all, collect, SduiIconRegistry.contains, log_verbose
//  â³ Called by: resolve_edges
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\analysis_worker.ts (338 lines)

#### AnalysisWorker (Class)
```rust
// Lines 30-207 (178 LOC | Complexity 1) | used by 4 callers | [HighComplexity]
class AnalysisWorker
//  â³ Calls: PendingJob
//  â³ Called by: DiaryAiSession.constructor, AnalysisWorker, DiaryAiSession.create, AnalysisWorker.getInstance
```

#### PendingJob (Interface)
```rust
// Lines 7-10 (4 LOC | Complexity 1) | used by 3 callers
interface PendingJob
//  â³ Called by: AnalysisWorker, PendingJob, AnalysisWorker
```

#### AnalysisWorker.queueDepth (Function)
```rust
// Lines 73-75 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
get queueDepth(): number
```

#### AnalysisWorker._processNext (Function)
```rust
// Lines 95-174 (80 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
private async _processNext(): Promise<void>
//  â³ Calls: AnalysisResult, ShuaDiaryEntries.sentimentScore, IAnalyzerProvider.analyze, AnalysisWorker._pushDelta, getDiaryRepository, DiaryRepository.updateEntryAnalysis, warn, filter, AnalysisWorker._setStatus
//  â³ Called by: AnalysisWorker.enqueue
```

#### AnalysisWorker.getStatus (Function)
```rust
// Lines 69-71 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
getStatus(entryId: string): AnalysisStatus | null
```

#### AnalysisWorker._setStatus (Function)
```rust
// Lines 83-93 (11 LOC | Complexity 3) | used by 2 callers | [MutatesState, Io]
private _setStatus(entryId: string, status: AnalysisStatus): void
//  â³ Called by: AnalysisWorker._processNext, AnalysisWorker.enqueue
```

#### AnalysisWorker.enqueue (Function)
```rust
// Lines 49-67 (19 LOC | Complexity 4) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
enqueue(entryId: string, blocks: Array<{ blockType: string; content: string }>): void
//  â³ Calls: AnalysisWorker._processNext, AnalysisWorker._setStatus
```

#### AnalysisWorker._pushDelta (Function)
```rust
// Lines 176-206 (31 LOC | Complexity 2) | used by 1 callers | [Io]
private _pushDelta(entryId: string, result: AnalysisResult): void
//  â³ Calls: AnalysisResult, SduiDeltaEmitter.emitPatch
//  â³ Called by: AnalysisWorker._processNext
```

#### AnalysisWorker.cancelPendingForSocket (Function)
```rust
// Lines 77-81 (5 LOC | Complexity 1) | used by 1 callers | [MutatesState, Io]
cancelPendingForSocket(): void
//  â³ Called by: SduiOrchestrator.setupListeners
```

#### AnalysisWorker.constructor (Function)
```rust
// Lines 39-42 (4 LOC | Complexity 1) | used by 0 callers | [Io, FrameworkInvoked]
constructor(
//  â³ Calls: IAnalyzerProvider
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_state_vault.dart (31 lines)

#### SduiStateVault.releaseScope (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void releaseScope(String screenId)
//  â³ Called by: _SduiScreenState
```

#### SduiStateVault (Class)
```rust
// Lines 4-30 (27 LOC | Complexity 1) | used by 4 callers
class SduiStateVault extends Notifier<Map<String, dynamic>>
//  â³ Calls: LogEntry::from
//  â³ Called by: SduiOrchestrator, SduiStateVault, _SduiScreenState, SduiOrchestrator.setupListeners
```

#### SduiStateVault.set (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void set(String nodeId, dynamic value)
```

#### SduiStateVault.get (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
T? get<T>(String nodeId)
```

#### SduiStateVault.build (Function)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Map<String, dynamic> build()
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\training\train_nobarcode.py (136 lines)

#### get_val (Function)
```rust
// Lines 78-86 (9 LOC | Complexity 4) | used by 1 callers | [Pure]
def get_val(col_name, default="0.0")
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 17-143 (127 LOC | Complexity 16) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, get_val, train, find_pretrained_weights, RadixTrie.insert
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\convert_dataset.py (174 lines)

#### main (Function)
```rust
// Lines 16-189 (174 LOC | Complexity 27) | used by 0 callers | [Io, EntryPoint, HighComplexity]
def main()
//  â³ Calls: main, resolve_image_path, RadixTrie.remove, SduiBlockRegistry.get, SduiBlockRegistry.load, find_latest_export, RadixTrie.insert
```

### C:\horAIzon_2.0\tools\detect_rust_logs.py (198 lines)

#### check_file (Function)
```rust
// Lines 145-167 (23 LOC | Complexity 5) | used by 0 callers | [Pure, PotentialDeadCode]
def check_file(filepath: str) -> list
//  â³ Calls: clean_code
```

#### main (Function)
```rust
// Lines 169-215 (47 LOC | Complexity 11) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: check_file, walk
```

#### clean_code (Function)
```rust
// Lines 16-143 (128 LOC | Complexity 30) | used by 0 callers | [Pure, HighComplexity, PotentialDeadCode]
def clean_code(code: str) -> str
//  â³ Calls: main, ThemeCompiler.compile
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\scratch\test_user_md.js (195 lines)

#### flushBlock (Function)
```rust
// Lines 65-82 (18 LOC | Complexity 6) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
const flushBlock = () =>
//  â³ Calls: ShuaDiaryBlocks.content
```

#### parseMarkdown (Function)
```rust
// Lines 57-233 (177 LOC | Complexity 32) | used by 0 callers | [Pure, Tested, HighComplexity, PotentialDeadCode]
function parseMarkdown(markdown)
//  â³ Calls: log, flushBlock
```

### C:\horAIzon_2.0\shua_governor\src\routes\logs.rs (133 lines)

#### stream_logs (Function)
```rust
// Lines 113-146 (34 LOC | Complexity 7) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn stream_logs(
//  â³ Calls: LogStreamParams, AppState, ok
```

#### query_logs (Function)
```rust
// Lines 51-101 (51 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, Io, ApiRoute]
pub async fn query_logs(
//  â³ Calls: LogQueryParams, AppState, collect, LogEntry::from
```

#### LogQueryParams (Struct)
```rust
// Lines 42-49 (8 LOC | Complexity 1) | used by 1 callers
pub struct LogQueryParams
//  â³ Called by: query_logs
```

#### ingest_log (Function)
```rust
// Lines 165-200 (36 LOC | Complexity 6) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn ingest_log(
//  â³ Calls: BorrowedLogEntry, AppState, log_min_level
```

#### LogStreamParams (Struct)
```rust
// Lines 108-111 (4 LOC | Complexity 1) | used by 1 callers
pub struct LogStreamParams
//  â³ Called by: stream_logs
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\interfaces\IAnalyzerProvider.ts (10 lines)

#### IAnalyzerProvider.analyze (Function)
```rust
// Lines 8-8 (1 LOC | Complexity 1) | used by 1 callers | [Async, Pure, FrameworkInvoked, Tested]
analyze(content: string, onProgress?: (data: string) => void): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult
//  â³ Called by: AnalyzerService.analyze
```

#### AnalysisResult (Interface)
```rust
// Lines 0-5 (6 LOC | Complexity 1) | used by 14 callers | [CorePrimitive]
interface AnalysisResult
//  â³ Called by: OllamaAnalyzerProvider.analyze, GeminiAnalyzerProvider.analyze, PythonFallbackProvider.analyze, AnalyzerService.analyze, AnalysisResult, GeminiAnalyzerProvider.analyze, PythonSemanticsAnalyzerProvider.analyze, OllamaAnalyzerProvider.analyze, IAnalyzerProvider.analyze, AnalysisWorker._pushDelta, AnalysisWorker._processNext, IAnalyzerProvider.analyze, AnalysisResult, N8nAnalyzerProvider.analyze
```

#### IAnalyzerProvider (Interface)
```rust
// Lines 7-9 (3 LOC | Complexity 1) | used by 14 callers | [CorePrimitive]
interface IAnalyzerProvider
//  â³ Called by: OllamaAnalyzerProvider, DiaryAiSession.create, DiaryAiSession.constructor, GeminiAnalyzerProvider, PythonFallbackProvider, AnalyzerService.getProvider, AnalyzerService, GeminiAnalyzerProvider, PythonSemanticsAnalyzerProvider, OllamaAnalyzerProvider.constructor, OllamaAnalyzerProvider, AnalysisWorker.constructor, IAnalyzerProvider, N8nAnalyzerProvider
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\generate_from_notes.ts (116 lines)

#### GenerateFromNotesHandler.handle (Function)
```rust
// Lines 6-62 (57 LOC | Complexity 7) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode, SduiOrchestrator.sendReplacePayload, DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, getDiaryRepository
```

#### GenerateFromNotesHandler (Class)
```rust
// Lines 5-63 (59 LOC | Complexity 1) | used by 1 callers
class GenerateFromNotesHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_governor\src\routes\health.rs (6 lines)

#### health_check (Function)
```rust
// Lines 6-11 (6 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn health_check() -> Json<Value>
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\apply_mutations.ts (132 lines)

#### ApplyMutationsHandler (Class)
```rust
// Lines 5-71 (67 LOC | Complexity 1) | used by 1 callers
class ApplyMutationsHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### ApplyMutationsHandler.handle (Function)
```rust
// Lines 6-70 (65 LOC | Complexity 11) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode, SduiOrchestrator.sendReplacePayload, DiaryRepository.createBlock, DiaryRepository._lexoRankAfter, DiaryRepository.getBlockLexoRank, DiaryRepository._midRankSuffix, DiaryRepository.stmt, DiaryRepository.updateBlock, DiaryRepository.deleteBlock, getDiaryRepository
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\export.rs (94 lines)

#### export_sdg (Function)
```rust
// Lines 11-104 (94 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, CanPanic, ApiRoute]
pub async fn export_sdg(
//  â³ Calls: SubGraph, Response, ExportOptions, AppState, header, serialize, serialize, serialize, collect, compute_subgraph, get_modified_files, LogEntry::from, search_bm25, RadixTrie.insert
```

### C:\horAIzon_2.0\client_flutter\lib\app\auth\pin_entry_screen.dart (294 lines)

#### PinEntryScreen.createState (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<PinEntryScreen> createState()
//  â³ Calls: PinEntryScreen, _PinEntryScreenState
```

#### _PinEntryScreenState.initState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _PinEntryScreenState._buildKey (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildKey(String label, AuthState state)
//  â³ Calls: AuthState
//  â³ Called by: _PinEntryScreenState
```

#### _PinEntryScreenState.build (Function)
```rust
// Lines 82-82 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _PinEntryScreenState (Class)
```rust
// Lines 14-296 (283 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
//  â³ Calls: AuthState, PinEntryScreen, AuthNotifier.deleteDigit, _PinEntryScreenState._buildKey, generate, _SduiShimmerLoaderState.padding, filter, _SduiShimmerLoaderState.borderRadius, LogEntry::from, AuthStatus, SduiBlockRegistry.all, SduiFlexContext.of, AuthNotifier.enterDigit, dispose, initState
//  â³ Called by: PinEntryScreen.createState
```

#### _PinEntryScreenState.dispose (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### PinEntryScreen (Class)
```rust
// Lines 7-12 (6 LOC | Complexity 1) | used by 2 callers
class PinEntryScreen extends ConsumerStatefulWidget
//  â³ Called by: _PinEntryScreenState, PinEntryScreen.createState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\mod.rs (12 lines)

#### ExportOptions (Struct)
```rust
// Lines 8-19 (12 LOC | Complexity 1) | used by 4 callers
pub struct ExportOptions
//  â³ Called by: serialize, serialize, export_sdg, serialize
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\embeddings.ts (64 lines)

#### cosineSimilarity (Function)
```rust
// Lines 68-75 (8 LOC | Complexity 3) | used by 1 callers | [Pure]
function cosineSimilarity(a: number[], b: number[]): number
//  â³ Called by: SemanticSearchHandler.handle
```

#### getEmbedding (Function)
```rust
// Lines 8-63 (56 LOC | Complexity 11) | used by 2 callers | [Async, Io]
async function getEmbedding(text: string, userId: string): Promise<number[]>
//  â³ Calls: warn, DiaryRepository.getAiProviderConfig, getDiaryRepository
//  â³ Called by: SduiActionHandler._saveBlock, SemanticSearchHandler.handle
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\utils\sdui_composer.ts (184 lines)

#### SduiComposer.init (Function)
```rust
// Lines 21-34 (14 LOC | Complexity 3) | used by 0 callers | [MutatesState, Io, Tested, PotentialDeadCode]
static init()
//  â³ Calls: log
```

#### SduiComposer.interpolate (Function)
```rust
// Lines 76-110 (35 LOC | Complexity 9) | used by 1 callers | [MutatesState, Io]
private static interpolate(template: any, variables: Record<string, string>): any
//  â³ Calls: warn
//  â³ Called by: SduiComposer.composeBlock
```

#### SduiComposer (Class)
```rust
// Lines 14-111 (98 LOC | Complexity 1) | used by 0 callers
class SduiComposer
```

#### LegacyDiaryBlock (Interface)
```rust
// Lines 4-8 (5 LOC | Complexity 1) | used by 1 callers
interface LegacyDiaryBlock
//  â³ Called by: SduiComposer.composeBlock
```

#### SduiComposer.composeBlock (Function)
```rust
// Lines 39-70 (32 LOC | Complexity 4) | used by 0 callers | [MutatesState, PotentialDeadCode]
static composeBlock(block: LegacyDiaryBlock): Map<number, any>
//  â³ Calls: LegacyDiaryBlock, ShuaDiaryBlocks.content, SduiComposer.interpolate, init
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\JbcTranslator.ts (566 lines)

#### JbcTranslator.selfHealLine (Function)
```rust
// Lines 30-104 (75 LOC | Complexity 22) | used by 2 callers | [Pure, HighComplexity]
private static selfHealLine(line: string): string
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

#### JbcTranslator.parse (Function)
```rust
// Lines 213-296 (84 LOC | Complexity 18) | used by 11 callers | [MutatesState, Io, Tested, CorePrimitive]
static parse(bytecode: string, activeBlocks?: any[]): { intent: string; mutations: JbcMutation[] }
//  â³ Calls: JbcMutation, warn, JbcTranslator.resolveId, JbcTranslator.selfHealLine, filter
//  â³ Called by: ChatHandler.handle, OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream, OllamaAssistantProvider.generateTemplate, GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc, GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.pull, GeminiAssistantProvider.chatStream, GeminiAssistantProvider.pull, GeminiAssistantProvider.generateTemplate
```

#### JbcTranslator (Class)
```rust
// Lines 25-317 (293 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class JbcTranslator
//  â³ Called by: JbcTranslator
```

#### JbcTranslator.translate (Function)
```rust
// Lines 130-207 (78 LOC | Complexity 19) | used by 7 callers | [MutatesState, Io, Tested]
static translate(bytecode: string, activeBlocks: any[]): string
//  â³ Calls: warn, JbcTranslator.resolveId, JbcTranslator.selfHealLine, filter
//  â³ Called by: ChatHandler.handle, OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream, GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc, GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.chatStream
```

#### JbcTranslator.serializeDiaryState (Function)
```rust
// Lines 302-316 (15 LOC | Complexity 5) | used by 8 callers | [Pure]
static serializeDiaryState(blocks: any[]): string
//  â³ Called by: OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc, GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.chatStream
```

#### JbcTranslator.resolveId (Function)
```rust
// Lines 110-123 (14 LOC | Complexity 5) | used by 2 callers | [Pure]
private static resolveId(id: string, activeBlocks?: any[]): string
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

#### JbcMutation (Interface)
```rust
// Lines 2-8 (7 LOC | Complexity 1) | used by 4 callers
interface JbcMutation
//  â³ Called by: JbcPlanResult, JbcTranslator.parse, JbcMutation, JbcTranslator.parse
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\collect_ocr_data.py (173 lines)

#### _append_rgb_profile (Function)
```rust
// Lines 59-69 (11 LOC | Complexity 2) | used by 1 callers | [Pure]
def _append_rgb_profile(filename: str, bg_r, bg_g, bg_b, fg_r, fg_g, fg_b)
//  â³ Called by: collect
```

#### _load_existing_labels (Function)
```rust
// Lines 43-49 (7 LOC | Complexity 3) | used by 5 callers | [Pure, Cycle]
def _load_existing_labels() -> dict
//  â³ Calls: collect, RadixTrie.insert
//  â³ Called by: review, collect, review, collect, collect
```

#### on_skip (Function)
```rust
// Lines 133-135 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def on_skip(event=None)
```

#### _profile_rgb (Function)
```rust
// Lines 74-93 (20 LOC | Complexity 1) | used by 1 callers | [Pure]
def _profile_rgb(crop_bgr: np.ndarray)
//  â³ Called by: collect
```

#### collect (Function)
```rust
// Lines 158-218 (61 LOC | Complexity 10) | used by 20 callers | [Io, Cycle, CorePrimitive]
def collect(source_dir: str, conf: float = 0.5)
//  â³ Calls: _append_rgb_profile, _append_label, _profile_rgb, _show_crop_gui, _hash_image, _load_existing_labels, _scan_images
//  â³ Called by: start_supervisor_loop, _load_existing_labels, serialize, serialize, resolve_call_edges, export_sdg, query_logs, _load_existing_labels, serialize, read_proc_cpu_usec, read_stat_fields, get_graph, LogEntry::from, assign_tags, compute_centrality, _load_existing_labels, serve_file, chunk_init, parse_and_index_file, search_bm25
```

#### on_save (Function)
```rust
// Lines 128-131 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def on_save(event=None)
```

#### _append_label (Function)
```rust
// Lines 51-57 (7 LOC | Complexity 2) | used by 3 callers | [Pure]
def _append_label(filename: str, label: str)
//  â³ Called by: collect, collect, collect
```

#### _show_crop_gui (Function)
```rust
// Lines 95-144 (50 LOC | Complexity 1) | used by 3 callers | [Pure]
def _show_crop_gui(img_bgr: np.ndarray, source_name: str, class_name: str) -> str
//  â³ Calls: ShuaDiaryEntries.title
//  â³ Called by: collect, collect, collect
```

#### _hash_image (Function)
```rust
// Lines 71-72 (2 LOC | Complexity 1) | used by 3 callers | [Pure]
def _hash_image(img_bgr: np.ndarray) -> str
//  â³ Called by: collect, collect, collect
```

#### _scan_images (Function)
```rust
// Lines 146-153 (8 LOC | Complexity 4) | used by 3 callers | [Pure]
def _scan_images(source_dir: str) -> list[str]
//  â³ Calls: walk
//  â³ Called by: collect, collect, collect
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\python.rs (128 lines)

#### PythonExtractor::extract (Function)
```rust
// Lines 9-135 (127 LOC | Complexity 25) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

#### PythonExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct PythonExtractor;
```

### C:\horAIzon_2.0\tools\explain_all_blueprints.py (180 lines)

#### format_color (Function)
```rust
// Lines 63-70 (8 LOC | Complexity 4) | used by 2 callers | [Pure]
def format_color(val, color_tokens)
//  â³ Called by: format_behavior_value, format_behavior_value
```

#### build_lookup_tables (Function)
```rust
// Lines 19-61 (43 LOC | Complexity 1) | used by 2 callers | [Pure]
def build_lookup_tables(contracts)
//  â³ Called by: main, main
```

#### load_contracts (Function)
```rust
// Lines 5-17 (13 LOC | Complexity 3) | used by 4 callers | [Io]
def load_contracts()
//  â³ Calls: main, SduiBlockRegistry.load
//  â³ Called by: main, main, main, main
```

#### write_node (Function)
```rust
// Lines 79-130 (52 LOC | Complexity 10) | used by 1 callers | [Pure]
def write_node(node, tables, out, indent="", is_last=True, prefix_override=None)
//  â³ Calls: format_behavior_value
//  â³ Called by: main
```

#### format_behavior_value (Function)
```rust
// Lines 72-77 (6 LOC | Complexity 3) | used by 2 callers | [Pure]
def format_behavior_value(name, val, color_tokens, enums)
//  â³ Calls: format_color
//  â³ Called by: print_node, write_node
```

#### main (Function)
```rust
// Lines 132-189 (58 LOC | Complexity 11) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: write_node, SduiBlockRegistry.load, build_lookup_tables, load_contracts
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\utils\RequestContext.ts (3 lines)

#### RequestStore (Interface)
```rust
// Lines 2-4 (3 LOC | Complexity 1) | used by 0 callers
interface RequestStore
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\scripts\analyze_sentiment.py (112 lines)

#### analyze_text_onnx (Function)
```rust
// Lines 94-96 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
def analyze_text_onnx(text: str, model_path: str)
//  â³ Calls: analyze_text_rules
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 98-126 (29 LOC | Complexity 5) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: analyze_text_rules, analyze_text_onnx
```

#### analyze_text_rules (Function)
```rust
// Lines 13-92 (80 LOC | Complexity 4) | used by 2 callers | [Pure]
def analyze_text_rules(text: str)
//  â³ Calls: main
//  â³ Called by: main, analyze_text_onnx
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\check_model_class_metrics.py (56 lines)

#### evaluate_best_model (Function)
```rust
// Lines 17-72 (56 LOC | Complexity 7) | used by 0 callers | [Async, Io, PotentialDeadCode]
def evaluate_best_model()
//  â³ Calls: find_latest_weights, RadixTrie.insert
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\monthly_synthesis.ts (148 lines)

#### startMonthlySynthesisLoop (Function)
```rust
// Lines 8-24 (17 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
function startMonthlySynthesisLoop()
//  â³ Calls: runMonthlySynthesisCheck
```

#### checkAndSynthesizeForUser (Function)
```rust
// Lines 42-157 (116 LOC | Complexity 10) | used by 2 callers | [Async, Io]
async function checkAndSynthesizeForUser(userId: string): Promise<string | null>
//  â³ Calls: DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, DiaryAiSession.create, DiaryRepository.getAiProviderConfig, DiaryRepository.getEntryBlocks, warn, SduiBlockRegistry.all, getDiaryRepository
//  â³ Called by: SduiActionHandler._getMonthlySynthesis, runMonthlySynthesisCheck
```

#### runMonthlySynthesisCheck (Function)
```rust
// Lines 26-40 (15 LOC | Complexity 2) | used by 1 callers | [Async, Io]
async function runMonthlySynthesisCheck()
//  â³ Calls: checkAndSynthesizeForUser, SduiBlockRegistry.all, getDiaryRepository
//  â³ Called by: startMonthlySynthesisLoop
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\ast.rs (32 lines)

#### get_tree_sitter_language (Function)
```rust
// Lines 20-31 (12 LOC | Complexity 6) | used by 13 callers | [Pure, CorePrimitive]
pub fn get_tree_sitter_language(lang: Language) -> tree_sitter::Language
//  â³ Calls: Language
//  â³ Called by: TypeScriptExtractor::extract, test_dart_method_call_ast, extract_type_references, extract_call_sites, extract_imports, PythonExtractor::extract, get_parser, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, GoExtractor::extract, RustExtractor::extract, DartExtractor::extract
```

#### get_parser (Function)
```rust
// Lines 33-41 (9 LOC | Complexity 2) | used by 14 callers | [MutatesState, CorePrimitive]
pub fn get_parser(lang: Language) -> Option<Parser>
//  â³ Calls: Language, get_tree_sitter_language
//  â³ Called by: TypeScriptExtractor::extract, test_dart_method_call_ast, extract_type_references, extract_call_sites, extract_imports, extract_api_routes, PythonExtractor::extract, extract_trait_map, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, GoExtractor::extract, RustExtractor::extract, DartExtractor::extract
```

#### detect_language (Function)
```rust
// Lines 8-18 (11 LOC | Complexity 9) | used by 4 callers | [Pure]
pub fn detect_language(path: &Path) -> Option<Language>
//  â³ Calls: Language
//  â³ Called by: extract_api_routes, extract_trait_map, parse_and_index_file, run_full_scan
```

### C:\horAIzon_2.0\client_flutter\ios\Flutter\ephemeral\flutter_lldb_helper.py (25 lines)

#### handle_new_rx_page (Function)
```rust
// Lines 6-21 (16 LOC | Complexity 2) | used by 0 callers | [Io, PotentialDeadCode]
def handle_new_rx_page(frame: lldb.SBFrame, bp_loc, extra_args, intern_dict)
```

#### __lldb_init_module (Function)
```rust
// Lines 23-31 (9 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
def __lldb_init_module(debugger: lldb.SBDebugger, _)
```

### C:\horAIzon_2.0\shua_governor\src\logging\bridge.rs (98 lines)

#### ChannelLogger (Struct)
```rust
// Lines 9-11 (3 LOC | Complexity 1) | used by 0 callers
pub struct ChannelLogger
//  â³ Calls: LogEntry
```

#### ChannelLogger::Visitor (Struct)
```rust
// Lines 42-46 (5 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
struct Visitor
//  â³ Called by: ChannelLogger::on_event
```

#### Visitor::record_str (Function)
```rust
// Lines 57-65 (9 LOC | Complexity 3) | used by 0 callers | [TraitMethod, MutatesState]
fn record_str(&mut self, field: &tracing::field::Field, value: &str)
//  â³ Calls: RadixTrie.insert
```

#### ChannelLogger::new (Function)
```rust
// Lines 14-16 (3 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
pub fn new(tx: mpsc::Sender<LogEntry>) -> Self
//  â³ Calls: LogEntry
//  â³ Called by: ChannelLogger::on_event
```

#### ChannelLogger::enabled (Function)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 1 callers | [TraitMethod, Pure]
fn enabled(&self, metadata: &tracing::Metadata<'_>, _ctx: Context<'_, S>) -> bool
//  â³ Calls: SduiIconRegistry.contains
//  â³ Called by: _DiaryEditorContent
```

#### ChannelLogger::on_event (Function)
```rust
// Lines 30-92 (63 LOC | Complexity 11) | used by 0 callers | [TraitMethod, MutatesState]
fn on_event(&self, event: &tracing::Event<'_>, _ctx: Context<'_, S>)
//  â³ Calls: LogEntry, ChannelLogger::Visitor, ChannelLogger::new, ShuaDiaryBlocks.metadata
```

#### Visitor::record_debug (Function)
```rust
// Lines 48-56 (9 LOC | Complexity 3) | used by 0 callers | [TraitMethod, MutatesState]
fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug)
//  â³ Calls: Debug, RadixTrie.insert
```

### C:\horAIzon_2.0\client_flutter\lib\app\dashboard_screen.dart (85 lines)

#### DashboardScreen.createState (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<DashboardScreen> createState()
//  â³ Calls: DashboardScreen, _DashboardScreenState
```

#### _DashboardScreenState.initState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _DashboardScreenState._loadDashboard (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadDashboard()
//  â³ Called by: _DashboardScreenState
```

#### _DashboardScreenState.build (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### DashboardScreen (Class)
```rust
// Lines 8-13 (6 LOC | Complexity 1) | used by 2 callers
class DashboardScreen extends ConsumerStatefulWidget
//  â³ Called by: _DashboardScreenState, DashboardScreen.createState
```

#### _DashboardScreenState (Class)
```rust
// Lines 15-89 (75 LOC | Complexity 1) | used by 1 callers
class _DashboardScreenState extends ConsumerState<DashboardScreen>
//  â³ Calls: SduiNode, DashboardScreen, SduiRenderer, ShuaDiaryEntries.title, SduiTransport.decodeJson, SduiTransport, _DashboardScreenState._loadDashboard, initState
//  â³ Called by: DashboardScreen.createState
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\interfaces\i_analyzer.ts (11 lines)

#### AnalysisResult (Interface)
```rust
// Lines 1-7 (7 LOC | Complexity 1) | used by 0 callers
interface AnalysisResult
//  â³ Calls: AnalysisResult
```

#### IAnalyzerProvider (Interface)
```rust
// Lines 9-11 (3 LOC | Complexity 1) | used by 0 callers
interface IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
```

#### IAnalyzerProvider.analyze (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 2 callers | [Async, Pure, FrameworkInvoked, Tested]
analyze(text: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult
//  â³ Called by: OllamaAnalyzerProvider.analyze, AnalysisWorker._processNext
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_icon_button.dart (33 lines)

#### SduiIconButton.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiIconButton (Class)
```rust
// Lines 2-33 (32 LOC | Complexity 1) | used by 1 callers
class SduiIconButton extends StatelessWidget
//  â³ Calls: SduiIconRegistry, ShuaSyncQueue.payload
//  â³ Called by: SduiRegistry
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\export_tflite.py (41 lines)

#### main (Function)
```rust
// Lines 15-55 (41 LOC | Complexity 5) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, RadixTrie.remove, run, SduiBlockRegistry.load, CRNN, RadixTrie.insert
```

### C:\horAIzon_2.0\shua_governor\src\routes\preactivation.rs (222 lines)

#### build_provider_card (Function)
```rust
// Lines 117-215 (99 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
fn build_provider_card(module_id: &str, provider_key: &str, title: &str, subtitle: &str, icon: &str, accent_token: i64) -> Value
```

#### build_generic_preactivation_payload (Function)
```rust
// Lines 217-247 (31 LOC | Complexity 1) | used by 1 callers | [Pure]
fn build_generic_preactivation_payload(display_name: &str, module_id: &str) -> Value
//  â³ Called by: get_preactivation_sheet
```

#### build_diary_preactivation_payload (Function)
```rust
// Lines 61-110 (50 LOC | Complexity 1) | used by 1 callers | [Pure]
fn build_diary_preactivation_payload(display_name: &str, module_id: &str) -> Value
//  â³ Called by: get_preactivation_sheet
```

#### get_preactivation_sheet (Function)
```rust
// Lines 17-58 (42 LOC | Complexity 6) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn get_preactivation_sheet(
//  â³ Calls: AppState, SduiIconRegistry.contains, ok, build_generic_preactivation_payload, build_diary_preactivation_payload
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\compiler\typst_compiler.go (104 lines)

#### resolveTypstPath (Function)
```rust
// Lines 38-66 (29 LOC | Complexity 6) | used by 1 callers | [Pure]
func resolveTypstPath() string
//  â³ Called by: CompileTypst
```

#### CompileTypst (Function)
```rust
// Lines 70-126 (57 LOC | Complexity 4) | used by 3 callers | [MutatesState, Io, Tested]
func CompileTypst(matrix *models.ResumeMatrix, templateName string) ([]byte, error)
//  â³ Calls: ResumeMatrix, Info, Error, findModuleRoot, resolveTypstPath
//  â³ Called by: TestCompileTypst, handleWsofflineCompile, CompilePdfHandler
```

#### findModuleRoot (Function)
```rust
// Lines 18-35 (18 LOC | Complexity 5) | used by 1 callers | [MutatesState]
func findModuleRoot() string
//  â³ Called by: CompileTypst
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_dropdown.dart (298 lines)

#### SduiDropdown.createState (Function)
```rust
// Lines 16-16 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDropdown> createState()
//  â³ Calls: SduiDropdown, _SduiDropdownState
```

#### filter (Function)
```rust
// Lines 304-304 (1 LOC | Complexity 1) | used by 30 callers | [Pure, Tested, CorePrimitive]
Iterable<T> filter(bool Function(T) test)
//  â³ Calls: test
//  â³ Called by: OllamaAnalyzerProvider.analyze, RadixTrie._remove, OllamaAssistantProvider.generateSummary, DiaryRepository.searchEntries, showDetails, SduiActionHandler._searchDiary, GeminiJbcProvider.generateSummary, GeminiAnalyzerProvider.analyze, JbcTranslator.parse, JbcTranslator.translate, AnalysisWorker._processNext, OllamaJbcProvider.generateSummary, GeminiAnalyzerProvider.analyze, _generate_synthetic_crop, SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler.filterAndTrackWrap, SduiScreenAssembler._assembleDiaryList, _SduiDropdownState, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, SduiBlockRegistry.all, JbcTranslator.parse, JbcTranslator.translate, chunk_init, OllamaAnalyzerProvider.analyze, GeminiAssistantProvider.generateSummary, AnalysisWorker._processNext, extract_file_summary, _PinEntryScreenState, search_bm25
```

#### _SduiDropdownState.didUpdateWidget (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiDropdown oldWidget)
//  â³ Calls: SduiDropdown
//  â³ Called by: _SduiDropdownState
```

#### SduiDropdown (Class)
```rust
// Lines 9-17 (9 LOC | Complexity 1) | used by 4 callers
class SduiDropdown extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, test
//  â³ Called by: _SduiDropdownState.didUpdateWidget, _SduiDropdownState, SduiDropdown.createState, SduiTypeRegistry
```

#### _SduiDropdownState (Class)
```rust
// Lines 19-300 (282 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDropdownState extends ConsumerState<SduiDropdown>
//  â³ Calls: SduiDropdown, filter, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiEventDispatcher.onStateChange, ShuaSyncQueue.payload, BoundedRouteHistory.isEmpty, SduiIconRegistry.contains, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of, dispose, _SduiDropdownState.didUpdateWidget, _SduiDropdownState._parseNodeOptions, SduiNode.contentVal, initState
//  â³ Called by: SduiDropdown.createState
```

#### _SduiDropdownState.initState (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiDropdownState.build (Function)
```rust
// Lines 96-96 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiDropdownState.dispose (Function)
```rust
// Lines 89-89 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiDropdownState._parseNodeOptions (Function)
```rust
// Lines 74-74 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<String> _parseNodeOptions()
//  â³ Called by: _SduiDropdownState
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\utils\hbp_codec.ts (76 lines)

#### HbpDiaryCodec (Class)
```rust
// Lines 40-80 (41 LOC | Complexity 1) | used by 0 callers
class HbpDiaryCodec
//  â³ Calls: freeze
```

#### HbpDiaryCodec.decodeSyncPayload (Function)
```rust
// Lines 45-79 (35 LOC | Complexity 9) | used by 1 callers | [Pure]
static decodeSyncPayload(flatPayload: any): any
//  â³ Calls: LogEntry::from
//  â³ Called by: DiaryBlockPayload
```

### C:\horAIzon_2.0\tools\summarize_dart_primitives.py (114 lines)

#### main (Function)
```rust
// Lines 47-120 (74 LOC | Complexity 9) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: ThemeCompiler.compile, load_contracts
```

#### load_contracts (Function)
```rust
// Lines 6-45 (40 LOC | Complexity 11) | used by 0 callers | [Io, PotentialDeadCode]
def load_contracts()
//  â³ Calls: main, SduiBlockRegistry.load
```

### C:\horAIzon_2.0\shua_governor\src\routes\sse_metrics.rs (61 lines)

#### ModuleMetrics (Struct)
```rust
// Lines 35-42 (8 LOC | Complexity 1) | used by 5 callers
pub struct ModuleMetrics
//  â³ Called by: start_supervisor_loop, MetricsSnapshot, MetricsSnapshot, ModuleMetrics.ModuleMetrics, ModuleMetrics
```

#### MetricsSnapshot (Struct)
```rust
// Lines 47-62 (16 LOC | Complexity 1) | used by 6 callers
pub struct MetricsSnapshot
//  â³ Calls: ModuleMetrics
//  â³ Called by: start_supervisor_loop, main, stream_metrics, AppState, MetricsSnapshot.MetricsSnapshot, MetricsSnapshot
```

#### stream_metrics (Function)
```rust
// Lines 79-115 (37 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn stream_metrics(
//  â³ Calls: MetricsSnapshot, AppState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_markdown_editor.dart (322 lines)

#### _SduiMarkdownEditorState.dispose (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiMarkdownEditorState._buildReadonlyView (Function)
```rust
// Lines 118-127 (10 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildReadonlyView(
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState._resolveHeadingStyle (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextStyle? _resolveHeadingStyle(ThemeData theme, int level, Color? textColor)
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState.didUpdateWidget (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiMarkdownEditor oldWidget)
//  â³ Calls: SduiMarkdownEditor
//  â³ Called by: _SduiMarkdownEditorState
```

#### SduiMarkdownEditor (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 9 callers
class SduiMarkdownEditor extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiMarkdownEditorState.didUpdateWidget, _SduiMarkdownEditorState, SduiMarkdownEditor.createState, _SduiMarkdownEditorState.didUpdateWidget, _SduiMarkdownEditorState, SduiMarkdownEditor.createState, SduiMarkdownEditor, SduiRegistry, SduiTypeRegistry
```

#### _SduiMarkdownEditorState (Class)
```rust
// Lines 23-312 (290 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiMarkdownEditorState extends ConsumerState<SduiMarkdownEditor>
//  â³ Calls: SduiMarkdownEditor, _SduiMarkdownEditorState._buildReadonlyView, _SduiMarkdownEditorState._onTextChanged, SduiBlockRegistry.all, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveTextStyle, SduiStyleResolver, _SduiMarkdownEditorState._resolveTextAlign, SduiNode.behavior, SduiFlexContext.of, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, _SduiMarkdownEditorState._resolveHeadingStyle, ShuaDiaryBlocks.content, BoundedRouteHistory.isEmpty, SduiEventDispatcher.onStateChange, dispose, _SduiMarkdownEditorState.didUpdateWidget, _SduiMarkdownEditorState._onFocusChange, SduiNode.contentVal, initState
//  â³ Called by: _SduiMarkdownEditorState, SduiMarkdownEditor.createState, SduiMarkdownEditor.createState
```

#### _SduiMarkdownEditorState._onTextChanged (Function)
```rust
// Lines 79-79 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState._onFocusChange (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFocusChange()
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState._resolveTextAlign (Function)
```rust
// Lines 86-86 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextAlign _resolveTextAlign(int alignVal)
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState.initState (Function)
```rust
// Lines 30-30 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SduiMarkdownEditor.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiMarkdownEditor> createState()
//  â³ Calls: SduiMarkdownEditor, _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState.build (Function)
```rust
// Lines 212-212 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\client_flutter\lib\app\route_history.dart (166 lines)

#### BoundedRouteHistory.addRoute (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
void addRoute(String location)
```

#### BoundedRouteHistory.moveBack (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void moveBack()
//  â³ Called by: AdaptiveShell
```

#### BoundedRouteHistory.isEmpty (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 38 callers | [Pure, Tested, CorePrimitive]
bool get isEmpty
//  â³ Called by: SyntaxHighlightingController, _SduiTableState, _SduiListEditorState, _SduiContainerState, SduiEventDispatcher, _JoshAutomatedGenerationDialogState, _DiaryListScreenState, SduiRegistry, _SduiSandboxScreenState, _SduiExpansionTileState, _DrawingPainter, _SduiDrawingPadState, SyntaxHighlightingController, TelemetryProfile, _SduiChartState, _CoPilotBubbleState, _JoshCoPilotPanelState, _DiaryEditorContent, SduiListView, SduiSandboxScreen, SduiHeatmap, _SduiVideoState, SduiModuleCard, _SduiAudioState, _SduiDropdownState, _SduiJbcPanelState, SduiImage, SduiEventDispatcher, _SduiListEditorState, AuthNotifier, SduiListView, _SduiTableState, _SduiDocumentViewerState, BinaryLexoRank, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState, SduiGridView
```

#### BoundedRouteHistory.canGoForward (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
bool get canGoForward
//  â³ Called by: AdaptiveShell, BoundedRouteHistory
```

#### BoundedRouteHistory.updateMaxCount (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
void updateMaxCount(int newMax)
```

#### RouteNode (Class)
```rust
// Lines 160-171 (12 LOC | Complexity 1) | used by 4 callers
class RouteNode
//  â³ Called by: extract_api_routes, RouteNode, DebugReport, BoundedRouteHistory
```

#### BoundedRouteHistory.moveForward (Function)
```rust
// Lines 83-83 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void moveForward()
//  â³ Called by: AdaptiveShell
```

#### BoundedRouteHistory._logRouteEvent (Function)
```rust
// Lines 148-148 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _logRouteEvent(String detail)
//  â³ Called by: BoundedRouteHistory
```

#### BoundedRouteHistory.canGoBack (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
bool get canGoBack
//  â³ Called by: AdaptiveShell, BoundedRouteHistory
```

#### BoundedRouteHistory.currentLocation (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
String? get currentLocation
//  â³ Called by: AdaptiveShell, SduiEventDispatcher
```

#### BoundedRouteHistory.jumpToNewest (Function)
```rust
// Lines 104-104 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
void jumpToNewest()
```

#### BoundedRouteHistory (Class)
```rust
// Lines 13-156 (144 LOC | Complexity 1) | used by 0 callers
class BoundedRouteHistory extends ChangeNotifier
//  â³ Calls: DiagnosticsHistoryNotifier.logResult, SystemEvents, DiagnosticResult.success, DiagnosticResult, BoundedRouteHistory.canGoBack, BoundedRouteHistory.canGoForward, BoundedRouteHistory._logRouteEvent, RouteNode
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\check_dataset_nobarcode_stats.py (124 lines)

#### check_stats (Function)
```rust
// Lines 14-137 (124 LOC | Complexity 24) | used by 1 callers | [Io, HighComplexity]
def check_stats()
//  â³ Calls: SduiBlockRegistry.load, find_latest_export, RadixTrie.insert
//  â³ Called by: check_stats
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_video.dart (626 lines)

#### _SduiVideoState.initState (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiVideoState._onControllerUpdate (Function)
```rust
// Lines 58-58 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onControllerUpdate()
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._resetHideTimer (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _resetHideTimer()
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._showPicker (Function)
```rust
// Lines 148-148 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context)
//  â³ Called by: _SduiVideoState
```

#### SduiVideo.createState (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiVideo> createState()
//  â³ Calls: SduiVideo, _SduiVideoState
```

#### _SduiVideoState._initVideoSource (Function)
```rust
// Lines 82-82 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _initVideoSource(String path)
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._formatDuration (Function)
```rust
// Lines 142-142 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatDuration(Duration d)
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState.dispose (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiVideoState (Class)
```rust
// Lines 31-633 (603 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiVideoState extends ConsumerState<SduiVideo>
//  â³ Calls: SduiVideo, _SduiVideoState._formatDuration, _SduiVideoState._showPicker, BoundedRouteHistory.isEmpty, _SduiVideoState._initVideoSource, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, ShuaDiaryBlocks.content, SduiEventDispatcher.onStateChange, MediaUploader.pickAndUploadWithUi, _SduiVideoState._onSelectFile, ShuaDiaryEntries.title, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiNode.behavior, SduiFlexContext.of, log, _SduiVideoState._resetHideTimer, SduiBlockRegistry.load, dispose, _SduiVideoState._onControllerUpdate, initState
//  â³ Called by: SduiVideo.createState
```

#### _SduiVideoState.build (Function)
```rust
// Lines 239-239 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiVideo (Class)
```rust
// Lines 17-29 (13 LOC | Complexity 1) | used by 3 callers
class SduiVideo extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiVideoState, SduiVideo.createState, SduiTypeRegistry
```

#### _SduiVideoState._onSelectFile (Function)
```rust
// Lines 208-208 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onSelectFile(BuildContext context, String bindKey, String filePath)
//  â³ Called by: _SduiVideoState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\markdown.rs (80 lines)

#### serialize (Function)
```rust
// Lines 7-86 (80 LOC | Complexity 14) | used by 3 callers | [MutatesState, CanPanic, Tested]
pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String
//  â³ Calls: AppState, ExportOptions, SubGraph, collect, SduiIconRegistry.contains, LogEntry::from
//  â³ Called by: GovernorLogger, export_sdg, MessagePackCodec
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_document_viewer.dart (551 lines)

#### _SduiDocumentViewerState._showPicker (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context)
//  â³ Called by: _SduiDocumentViewerState
```

#### SduiDocumentViewer (Class)
```rust
// Lines 34-46 (13 LOC | Complexity 1) | used by 3 callers
class SduiDocumentViewer extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDocumentViewerState, SduiDocumentViewer.createState, SduiTypeRegistry
```

#### _SduiDocumentViewerState (Class)
```rust
// Lines 48-563 (516 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDocumentViewerState extends ConsumerState<SduiDocumentViewer>
//  â³ Calls: SduiDocumentViewer, ShuaDiaryBlocks.content, _SduiDocumentViewerState._showPicker, _SduiDocumentViewerState._buildErrorState, _SduiDocumentViewerState._buildEmptyReadonly, _SduiDocumentViewerState._buildUploadBox, BoundedRouteHistory.isEmpty, N8nAssistantProvider.baseUrl, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, MediaUploader.pickAndUploadWithUi, ShuaDiaryEntries.title, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiNode.behavior, SduiFlexContext.of, dispose
//  â³ Called by: SduiDocumentViewer.createState
```

#### SduiDocumentViewer.createState (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDocumentViewer> createState()
//  â³ Calls: SduiDocumentViewer, _SduiDocumentViewerState
```

#### _SduiDocumentViewerState._buildErrorState (Function)
```rust
// Lines 494-499 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildErrorState(
//  â³ Called by: _SduiDocumentViewerState
```

#### _SduiDocumentViewerState.dispose (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiDocumentViewerState.build (Function)
```rust
// Lines 136-136 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiDocumentViewerState._buildEmptyReadonly (Function)
```rust
// Lines 461-465 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyReadonly(
//  â³ Called by: _SduiDocumentViewerState
```

#### _SduiDocumentViewerState._buildUploadBox (Function)
```rust
// Lines 416-422 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildUploadBox(
//  â³ Called by: _SduiDocumentViewerState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_renderer.dart (71 lines)

#### SduiRenderer (Class)
```rust
// Lines 38-86 (49 LOC | Complexity 1) | used by 8 callers
class SduiRenderer extends StatelessWidget
//  â³ Calls: Visitor::Key, SduiEventDispatcher, SduiNode, SduiFlexContext.of, SduiFlexContext, _SduiShimmerLoaderState.padding, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiTypeRegistry
//  â³ Called by: _SduiContainerState, _SduiExpansionTileState, SduiListView, SduiGridView, _SduiScreenState, _SduiWrapState, _DashboardScreenState, _SduiCarouselState
```

#### SduiFlexContext (Class)
```rust
// Lines 14-32 (19 LOC | Complexity 1) | used by 4 callers
class SduiFlexContext extends InheritedWidget
//  â³ Called by: SduiFlexContext.updateShouldNotify, SduiFlexContext.of, _SduiContainerState, SduiRenderer
```

#### SduiFlexContext.of (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 87 callers | [Pure, CorePrimitive]
static SduiFlexContext? of(BuildContext context)
//  â³ Calls: SduiFlexContext
//  â³ Called by: SduiButton, _SduiCodeEditorState, SyntaxHighlightingController, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, AdaptiveShell, _SduiContainerState, _SduiMarkdownEditorState, _SduiToggleState, _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, _DiaryListScreenState, _SduiCheckboxState, SduiRegistry, _SduiSandboxScreenState, HorAIzonClientShell, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, SduiStyleResolver, SduiStlViewer, _SduiHeadingState, _SduiShimmerLoaderState, _SduiDrawingPadState, _SduiDashboardScreenState, _SduiCodeEditorState, SyntaxHighlightingController, _SduiChartState, SduiTimePicker, _CoPilotBubbleState, _JoshCoPilotPanelState, _TitleEditorState, _DiaryEditorContent, SduiGauge, _SduiTextInputState, SduiSandboxScreen, MediaUploader, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSpacerState, SduiModuleCard, SduiProgressBar, _SduiSliderState, _SduiAudioState, SduiToggle, _SduiOrdinalSliderState, _SduiRadioState, _SduiScreenState, _SduiRadioState, _NetworkConfigCardState, SettingsPage, _SduiDropdownState, SduiChip, _SduiJbcPanelState, _SduiTextInputState, SduiImage, SduiContainer, SduiEventDispatcher, _SduiWrapState, _SduiListEditorState, _SduiSliderState, SduiRenderer, _SduiTableState, SduiSocketManager, _SduiDocumentViewerState, _SduiQuoteState, SduiRadialGaugeNode, SduiBarChartNode, SduiLineChartNode, SduiEmptyStateNode, SduiErrorStateNode, SduiButtonNode, SduiTextNode, SduiNode, _SduiCarouselState, _SduiShimmerLoaderState, _SduiCheckboxState, _SduiMapState, _FilterChip, _TerminalLineState, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState, _PinEntryScreenState
```

#### SduiFlexContext.updateShouldNotify (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool updateShouldNotify(SduiFlexContext oldWidget)
//  â³ Calls: SduiFlexContext
```

#### SduiRenderer.build (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\ollama\OllamaAnalyzerProvider.ts (455 lines)

#### OllamaAnalyzerProvider.ollamaUrl (Function)
```rust
// Lines 4-4 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
private get ollamaUrl() { return ConfigProvider.ollamaUrl; }
```

#### OllamaAnalyzerProvider (Class)
```rust
// Lines 3-231 (229 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class OllamaAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: OllamaAnalyzerProvider, DiaryAiSession.create, AnalyzerService.getProvider
```

#### OllamaAnalyzerProvider.modelName (Function)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
get modelName() { return ConfigProvider.ollamaSentimentModel; }
//  â³ Called by: OllamaAnalyzerProvider.analyze
```

#### OllamaAnalyzerProvider.analyze (Function)
```rust
// Lines 7-230 (224 LOC | Complexity 29) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod, Tested, HighComplexity]
async analyze(content: string, onProgress?: (data: string) => void): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, warn, ShuaDiaryEntries.milestoneTag, ShuaDiaryEntries.sentimentScore, Error, OllamaAnalyzerProvider.modelName, log, test, filter
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\ollama\OllamaAssistantProvider.ts (1210 lines)

#### OllamaAssistantProvider.plannerRefactor (Function)
```rust
// Lines 514-596 (83 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async plannerRefactor(
//  â³ Calls: JbcTranslator.translate, JbcTranslator.parse, log, Error, OllamaAssistantProvider.plannerModelName, OllamaAssistantProvider.resolvePositionalRefs, JbcTranslator.serializeDiaryState
```

#### OllamaAssistantProvider.summarizerModelName (Function)
```rust
// Lines 7-7 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
private get summarizerModelName() { return ConfigProvider.ollamaSummarizerModel; }
//  â³ Called by: OllamaAssistantProvider.generateSummary
```

#### OllamaAssistantProvider.generateTemplate (Function)
```rust
// Lines 10-117 (108 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateTemplate(topic: string, style: string): Promise<{ markdown: string; titles: string[]; metadata: any }>
//  â³ Calls: ShuaDiaryBlocks.metadata, warn, JbcTranslator.parse, Error, OllamaAssistantProvider.streamerModelName
```

#### OllamaAssistantProvider.ollamaUrl (Function)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
private get ollamaUrl() { return ConfigProvider.ollamaUrl; }
```

#### OllamaAssistantProvider.start (Function)
```rust
// Lines 475-489 (15 LOC | Complexity 4) | used by 0 callers | [Async, Pure, Tested, PotentialDeadCode]
async start(controller)
//  â³ Calls: MessagePackCodec.encode
```

#### OllamaAssistantProvider.chatStream (Function)
```rust
// Lines 273-512 (240 LOC | Complexity 30) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod, HighComplexity]
async chatStream(
//  â³ Calls: MessagePackCodec.encode, Error, OllamaAssistantProvider.streamerModelName, warn, JbcTranslator.translate, ShuaDiaryBlocks.content, JbcTranslator.parse, log, OllamaAssistantProvider.plannerModelName, JbcTranslator.serializeDiaryState, OllamaAssistantProvider.resolvePositionalRefs
```

#### OllamaAssistantProvider.generateSummary (Function)
```rust
// Lines 189-231 (43 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(content: string): Promise<string>
//  â³ Calls: Error, OllamaAssistantProvider.summarizerModelName, test, filter
```

#### OllamaAssistantProvider.resolvePositionalRefs (Function)
```rust
// Lines 233-271 (39 LOC | Complexity 5) | used by 2 callers | [Pure, TraitMethod]
private resolvePositionalRefs(prompt: string, diaryBlocks: any[]): string
//  â³ Called by: OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream
```

#### OllamaAssistantProvider.pull (Function)
```rust
// Lines 490-501 (12 LOC | Complexity 2) | used by 0 callers | [Async, Pure, PotentialDeadCode]
async pull(controller)
//  â³ Calls: DiaryRepository.close
```

#### OllamaAssistantProvider (Class)
```rust
// Lines 4-597 (594 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class OllamaAssistantProvider implements IAssistantProvider
//  â³ Calls: IAssistantProvider
//  â³ Called by: AssistantService.getProvider
```

#### OllamaAssistantProvider.streamerModelName (Function)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
private get streamerModelName() { return ConfigProvider.ollamaStreamerModel; }
//  â³ Called by: OllamaAssistantProvider.chatStream, OllamaAssistantProvider.generateTemplateStream, OllamaAssistantProvider.generateTemplate
```

#### OllamaAssistantProvider.cancel (Function)
```rust
// Lines 502-504 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
cancel()
```

#### OllamaAssistantProvider.plannerModelName (Function)
```rust
// Lines 8-8 (1 LOC | Complexity 1) | used by 2 callers | [Pure, TraitMethod]
private get plannerModelName() { return ConfigProvider.ollamaPlannerModel; }
//  â³ Called by: OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream
```

#### OllamaAssistantProvider.generateTemplateStream (Function)
```rust
// Lines 119-187 (69 LOC | Complexity 2) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateTemplateStream(topic: string, style: string): Promise<any>
//  â³ Calls: Error, OllamaAssistantProvider.streamerModelName
```

### C:\horAIzon_2.0\tools\compile_mock_blueprints.py (671 lines)

#### expand_permutations (Function)
```rust
// Lines 17-619 (603 LOC | Complexity 39) | used by 1 callers | [Io, HighComplexity]
def expand_permutations(block_name, block_data)
//  â³ Called by: compile_mock_blueprints
```

#### compile_mock_blueprints (Function)
```rust
// Lines 621-676 (56 LOC | Complexity 6) | used by 1 callers | [Io, Cycle]
def compile_mock_blueprints(exclude_patterns=None)
//  â³ Calls: SduiStateVault.dump, expand_permutations, inject_mocks, SduiBlockRegistry.load
//  â³ Called by: inject_mocks
```

#### inject_mocks (Function)
```rust
// Lines 4-15 (12 LOC | Complexity 9) | used by 1 callers | [Pure, Cycle]
def inject_mocks(obj)
//  â³ Calls: compile_mock_blueprints
//  â³ Called by: compile_mock_blueprints
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_transport.dart (269 lines)

#### SduiTransport.applyDelta (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
static List<SduiNode> applyDelta(List<SduiNode> tree, dynamic rawDelta)
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport, _SduiScreenState, SduiSocketManager
```

#### SduiTransport.decodeJson (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
static List<SduiNode> decodeJson(String jsonString)
//  â³ Calls: SduiNode
//  â³ Called by: _DashboardScreenState, SduiSocketManager
```

#### SduiTransport._nodeFromMap (Function)
```rust
// Lines 201-201 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static SduiNode _nodeFromMap(Map map)
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

#### SduiTransport._insertAfterInTree (Function)
```rust
// Lines 116-118 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _insertAfterInTree(
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

#### SduiTransport._insertAfterRecursive (Function)
```rust
// Lines 129-131 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static (List<SduiNode>, bool) _insertAfterRecursive(
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

#### SduiTransport._parseList (Function)
```rust
// Lines 187-187 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _parseList(dynamic decodedList)
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

#### SduiTransport._removeNodeFromTree (Function)
```rust
// Lines 100-100 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _removeNodeFromTree(List<SduiNode> tree, String nodeId)
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

#### SduiTransport.patch (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static SduiNode patch(SduiNode existing, Map<String, dynamic> delta)
//  â³ Calls: SduiNode
```

#### SduiTransport.decode (Function)
```rust
// Lines 7-7 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static List<SduiNode> decode(Uint8List bytes)
//  â³ Calls: SduiNode
```

#### SduiTransport (Class)
```rust
// Lines 5-257 (253 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class SduiTransport
//  â³ Calls: SduiTransport._insertAfterRecursive, SduiTransport._patchNodeInTree, SduiTransport._insertAfterInTree, SduiTransport._nodeFromMap, SduiTransport._removeNodeFromTree, SduiTransport.applyDelta, SduiNode, ShuaDiaryBlocks.content, LogEntry::from, SduiTransport._parseList, BorrowedLogEntry::deserialize
//  â³ Called by: _SduiScreenState, _DashboardScreenState, SduiSocketManager
```

#### SduiTransport._patchNodeInTree (Function)
```rust
// Lines 161-163 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _patchNodeInTree(
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\n8n\N8nAnalyzerProvider.ts (18 lines)

#### N8nAnalyzerProvider.analyze (Function)
```rust
// Lines 5-11 (7 LOC | Complexity 1) | used by 0 callers | [Async, Io, CanPanic, FrameworkInvoked, TraitMethod, Tested]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, Error, log
```

#### N8nAnalyzerProvider (Class)
```rust
// Lines 2-12 (11 LOC | Complexity 1) | used by 0 callers
class N8nAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\git_diff.rs (100 lines)

#### commit_touches_file (Function)
```rust
// Lines 82-104 (23 LOC | Complexity 6) | used by 1 callers | [MutatesState]
fn commit_touches_file(repo: &Repository, commit: &Commit, file: &Path) -> bool
//  â³ Called by: churn_score
```

#### get_modified_files (Function)
```rust
// Lines 3-26 (24 LOC | Complexity 8) | used by 1 callers | [MutatesState]
pub fn get_modified_files(repo_root: &Path) -> Vec<PathBuf>
//  â³ Called by: export_sdg
```

#### churn_score (Function)
```rust
// Lines 28-80 (53 LOC | Complexity 14) | used by 0 callers | [MutatesState, CanPanic, PotentialDeadCode]
pub fn churn_score(file: &Path, repo: &Repository, days: u32) -> f32
//  â³ Calls: commit_touches_file
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_container.dart (511 lines)

#### _SduiContainerState (Class)
```rust
// Lines 58-528 (471 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiContainerState extends State<SduiContainer>
//  â³ Calls: SduiNode, SduiContainer, _SduiContainerState._wrapAnimation, _SduiContainerState._wrapOpacity, _SduiContainerState._wrapDecoration, _SduiContainerState._buildLayout, SduiBlockRegistry.all, SduiFlexContext.of, SduiStyleResolver.resolveEdgeInsets, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.maxHeight, _SduiContainerState._resolveSize, _SduiContainerState._resolveClip, _SduiContainerState._num, _SduiShimmerLoaderState.borderRadius, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiContainerState._buildChildren, _SduiContainerState._resolveMainAxisSize, _SduiContainerState._resolveCrossAxis, _SduiContainerState._resolveMainAxis, _SduiContainerState._buildReorderableList, BoundedRouteHistory.isEmpty, ShuaSyncQueue.actionType, _SduiContainerState._buildReorderableItem, _SduiContainerState._findDragHandleIndex, SduiEventDispatcher.onReorder, log, _SduiContainerState._extractBlockId, RadixTrie.insert, _SduiContainerState._int, LogEntry::from, SduiRenderer, SduiFlexContext, dispose, _SduiContainerState._resolveCurve, _SduiContainerState._setupMountAnimation, initState
//  â³ Called by: SduiContainer.createState
```

#### _SduiContainerState._buildReorderableList (Function)
```rust
// Lines 176-176 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildReorderableList()
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveCurve (Function)
```rust
// Lines 125-125 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Curve _resolveCurve(int id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._wrapOpacity (Function)
```rust
// Lines 486-486 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _wrapOpacity(Widget child)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._buildReorderableItem (Function)
```rust
// Lines 243-248 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildReorderableItem(
//  â³ Calls: SduiNode
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveCrossAxis (Function)
```rust
// Lines 106-106 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static CrossAxisAlignment _resolveCrossAxis(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._buildLayout (Function)
```rust
// Lines 317-317 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildLayout()
//  â³ Called by: _SduiContainerState
```

#### SduiContainer (Class)
```rust
// Lines 44-56 (13 LOC | Complexity 1) | used by 5 callers
class SduiContainer extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiContainerState, SduiContainer.createState, SduiRegistry, SduiContainer, SduiTypeRegistry
```

#### _SduiContainerState._wrapAnimation (Function)
```rust
// Lines 494-494 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _wrapAnimation(Widget child)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._extractBlockId (Function)
```rust
// Lines 301-301 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static String? _extractBlockId(String nodeId)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveMainAxis (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static MainAxisAlignment _resolveMainAxis(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._buildChildren (Function)
```rust
// Lines 151-151 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<Widget> _buildChildren(bool isFlexLayout)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveSize (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static double? _resolveSize(dynamic raw)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveClip (Function)
```rust
// Lines 119-119 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Clip _resolveClip(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveMainAxisSize (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static MainAxisSize _resolveMainAxisSize(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._int (Function)
```rust
// Lines 312-312 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
int _int(int key, [int fallback = 0])
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._wrapDecoration (Function)
```rust
// Lines 389-389 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _wrapDecoration(Widget child)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState.initState (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiContainerState._setupMountAnimation (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _setupMountAnimation()
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState.build (Function)
```rust
// Lines 521-521 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiContainerState.dispose (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiContainerState._num (Function)
```rust
// Lines 142-142 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
double? _num(int key)
//  â³ Called by: _SduiContainerState
```

#### SduiContainer.createState (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiContainer> createState()
//  â³ Calls: SduiContainer, _SduiContainerState
```

#### _SduiContainerState._findDragHandleIndex (Function)
```rust
// Lines 282-282 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int _findDragHandleIndex(SduiNode wrapperNode)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiContainerState
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_quote.dart (132 lines)

#### _SduiQuoteState.didUpdateWidget (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiQuote oldWidget)
//  â³ Calls: SduiQuote
//  â³ Called by: _SduiQuoteState
```

#### _SduiQuoteState.dispose (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiQuoteState.build (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiQuoteState.initState (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiQuoteState._onTextChanged (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiQuoteState
```

#### SduiQuote.createState (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiQuote> createState()
//  â³ Calls: SduiQuote, _SduiQuoteState
```

#### SduiQuote (Class)
```rust
// Lines 4-18 (15 LOC | Complexity 1) | used by 4 callers
class SduiQuote extends StatefulWidget
//  â³ Called by: _SduiQuoteState.didUpdateWidget, _SduiQuoteState, SduiQuote.createState, SduiRegistry
```

#### _SduiQuoteState (Class)
```rust
// Lines 20-130 (111 LOC | Complexity 1) | used by 1 callers
class _SduiQuoteState extends State<SduiQuote>
//  â³ Calls: SduiQuote, SduiNode.behavior, _SduiQuoteState._onTextChanged, _SduiShimmerLoaderState.padding, SduiFlexContext.of, dispose, _SduiQuoteState.didUpdateWidget, initState
//  â³ Called by: SduiQuote.createState
```

### C:\horAIzon_2.0\shua_modules\shua_resume\test_matrix.go (17 lines)

#### main (Function)
```rust
// Lines 9-25 (17 LOC | Complexity 2) | used by 0 callers | [MutatesState, Io, EntryPoint]
func main()
//  â³ Calls: ProjectItem, Education, WorkItem, LoadAndHydrateBlueprint
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_terminal.dart (836 lines)

#### SduiTerminal (Class)
```rust
// Lines 35-43 (9 LOC | Complexity 1) | used by 3 callers
class SduiTerminal extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTerminalState, SduiTerminal.createState, SduiTypeRegistry
```

#### _SuccessRateBadge.build (Function)
```rust
// Lines 778-778 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiTerminalState._getFilteredLogs (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<DiagnosticResult> _getFilteredLogs(DiagnosticsState state)
//  â³ Calls: DiagnosticsState, DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _TerminalLineState.build (Function)
```rust
// Lines 539-539 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiTerminalState.build (Function)
```rust
// Lines 183-183 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiTerminalState.dispose (Function)
```rust
// Lines 54-54 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _TerminalLine (Class)
```rust
// Lines 520-533 (14 LOC | Complexity 1) | used by 3 callers
class _TerminalLine extends StatefulWidget
//  â³ Calls: DiagnosticResult
//  â³ Called by: _TerminalLineState, _TerminalLine.createState, _SduiTerminalState
```

#### _SduiTerminalState._buildStdinRow (Function)
```rust
// Lines 458-458 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStdinRow(BuildContext context, Color accentColor)
//  â³ Called by: _SduiTerminalState
```

#### _SuccessRateBadge (Class)
```rust
// Lines 771-804 (34 LOC | Complexity 1) | used by 1 callers
class _SuccessRateBadge extends StatelessWidget
//  â³ Calls: DiagnosticsState, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, DiagnosticsState.successRate
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._buildSubsystemFilterBar (Function)
```rust
// Lines 364-368 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildSubsystemFilterBar(
//  â³ Calls: DiagnosticsState
//  â³ Called by: _SduiTerminalState
```

#### SduiTerminal.createState (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
ConsumerState<SduiTerminal> createState()
//  â³ Calls: SduiTerminal, _SduiTerminalState
//  â³ Called by: _TerminalLine.createState
```

#### _SduiTerminalState._buildHeader (Function)
```rust
// Lines 262-268 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHeader(
//  â³ Calls: DiagnosticResult, DiagnosticsState
//  â³ Called by: _SduiTerminalState
```

#### _FilterChip.build (Function)
```rust
// Lines 821-821 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _FilterChip (Class)
```rust
// Lines 807-850 (44 LOC | Complexity 1) | used by 1 callers
class _FilterChip extends StatelessWidget
//  â³ Calls: SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiFlexContext.of
//  â³ Called by: _SduiTerminalState
```

#### _TerminalLineState (Class)
```rust
// Lines 535-768 (234 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _TerminalLineState extends State<_TerminalLine>
//  â³ Calls: _TerminalLine, convert, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of
//  â³ Called by: _TerminalLine.createState
```

#### _SduiTerminalState._formatTimestamp (Function)
```rust
// Lines 108-108 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatTimestamp(DateTime ts)
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._severityColor (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _severityColor(DiagnosticResult result, ColorScheme colors)
//  â³ Calls: DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._copyLogs (Function)
```rust
// Lines 117-120 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _copyLogs(
//  â³ Calls: DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._buildLogList (Function)
```rust
// Lines 411-415 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildLogList(
//  â³ Calls: DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState (Class)
```rust
// Lines 45-512 (468 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiTerminalState extends ConsumerState<SduiTerminal>
//  â³ Calls: DiagnosticResult, DiagnosticsState, DiagnosticSeverity, SduiTerminal, _SduiTerminalState._submitStdin, _SduiTerminalState._severityColor, _TerminalLine, _SduiShimmerLoaderState.maxHeight, RadixTrie.insert, RadixTrie.remove, log, DiagnosticsHistoryNotifier.clearHistory, _SduiTerminalState._copyLogs, _FilterChip, _SuccessRateBadge, _SduiShimmerLoaderState.padding, _SduiTerminalState._buildStdinRow, _SduiTerminalState._buildLogList, _SduiTerminalState._buildSubsystemFilterBar, _SduiTerminalState._buildHeader, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiTerminalState._getFilteredLogs, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiEventDispatcher.onStateChange, SduiStateVault.clear, SduiNode.behavior, ShuaDiaryBlocks.content, SduiFlexContext.of, convert, _SduiTerminalState._formatTimestamp, BoundedRouteHistory.isEmpty, dispose
//  â³ Called by: SduiTerminal.createState
```

#### _SduiTerminalState._submitStdin (Function)
```rust
// Lines 175-175 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _submitStdin(String command)
//  â³ Called by: _SduiTerminalState
```

#### _TerminalLine.createState (Function)
```rust
// Lines 532-532 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<_TerminalLine> createState()
//  â³ Calls: _TerminalLine, _TerminalLineState, SduiTerminal.createState
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\seed_diary.ts (49 lines)

#### uuid (Function)
```rust
// Lines 26-28 (3 LOC | Complexity 1) | used by 1 callers | [Pure, Cycle, Tested]
function uuid(): string
//  â³ Calls: DiaryRepository.close, warn, insertBlock, makeRank, ShuaDiaryEntries.title, ShuaDiaryBlocks.entryId, insertEntry, run, log
//  â³ Called by: insertBlock
```

#### insertBlock (Function)
```rust
// Lines 72-80 (9 LOC | Complexity 2) | used by 1 callers | [Io, Cycle]
function insertBlock(entryId: string, blockType: string, content: string, rankIdx: number, codeLanguage?: string): void
//  â³ Calls: run, makeRank, uuid
//  â³ Called by: uuid
```

#### insertEntry (Function)
```rust
// Lines 44-69 (26 LOC | Complexity 1) | used by 1 callers | [Io]
function insertEntry(params:
//  â³ Calls: run
//  â³ Called by: uuid
```

#### makeRank (Function)
```rust
// Lines 31-41 (11 LOC | Complexity 2) | used by 2 callers | [Pure]
function makeRank(n: number): string
//  â³ Called by: uuid, insertBlock
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\scan.rs (41 lines)

#### ScanRequest (Struct)
```rust
// Lines 7-9 (3 LOC | Complexity 1) | used by 1 callers
pub struct ScanRequest
//  â³ Called by: trigger_scan
```

#### trigger_scan (Function)
```rust
// Lines 17-50 (34 LOC | Complexity 2) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn trigger_scan(
//  â³ Calls: ScanResponse, ScanRequest, AppState, run_full_scan, LogEntry::from
```

#### ScanResponse (Struct)
```rust
// Lines 12-15 (4 LOC | Complexity 1) | used by 1 callers
pub struct ScanResponse
//  â³ Called by: trigger_scan
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\parser\markdown_parser_test.go (143 lines)

#### TestParseMarkdown (Function)
```rust
// Lines 6-148 (143 LOC | Complexity 44) | used by 0 callers | [Io, Tested, HighComplexity, PotentialDeadCode]
func TestParseMarkdown(t *testing.T)
//  â³ Calls: ParseMarkdown
```

### C:\horAIzon_2.0\client_flutter\lib\app\theme\theme_provider.dart (151 lines)

#### ThemeNotifier.updateSecondary (Function)
```rust
// Lines 121-121 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateSecondary(Color newColor)
//  â³ Called by: SettingsPage
```

#### ThemeNotifier.build (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ThemeState build()
//  â³ Calls: ThemeState, build
```

#### ThemeNotifier (Class)
```rust
// Lines 53-147 (95 LOC | Complexity 1) | used by 1 callers
class ThemeNotifier extends Notifier<ThemeState>
//  â³ Calls: SystemEvents, DiagnosticResult.success, DiagnosticResult, DiagnosticsHistoryNotifier.logResult, ThemeNotifier._logThemeChange, ThemeNotifier._saveSettings, ThemeState.copyWith, log, ThemeState, ThemeNotifier._loadSettings
//  â³ Called by: ThemeState
```

#### ThemeState.compiledData (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ThemeData get compiledData
//  â³ Calls: ThemeCompiler.compile, ThemeCompiler
//  â³ Called by: HorAIzonClientShell
```

#### ThemeState (Class)
```rust
// Lines 13-51 (39 LOC | Complexity 1) | used by 3 callers
class ThemeState
//  â³ Calls: ThemeNotifier
//  â³ Called by: ThemeNotifier.build, ThemeState.copyWith, ThemeNotifier
```

#### ThemeNotifier._saveSettings (Function)
```rust
// Lines 88-88 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _saveSettings()
//  â³ Called by: ThemeNotifier
```

#### ThemeNotifier.updateTextScale (Function)
```rust
// Lines 133-133 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateTextScale(double scale)
//  â³ Called by: SettingsPage
```

#### ThemeNotifier._logThemeChange (Function)
```rust
// Lines 139-139 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _logThemeChange(String detail)
//  â³ Called by: ThemeNotifier
```

#### ThemeNotifier.toggleBrightness (Function)
```rust
// Lines 105-105 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void toggleBrightness()
//  â³ Called by: SettingsPage
```

#### ThemeState.copyWith (Function)
```rust
// Lines 36-42 (7 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ThemeState copyWith(
//  â³ Calls: ThemeState
//  â³ Called by: ThemeNotifier
```

#### ThemeNotifier._loadSettings (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadSettings()
//  â³ Called by: ThemeNotifier
```

#### ThemeNotifier.updatePrimary (Function)
```rust
// Lines 115-115 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updatePrimary(Color newColor)
//  â³ Called by: SettingsPage
```

#### ThemeNotifier.updateAnimationMs (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateAnimationMs(int ms)
//  â³ Called by: SettingsPage
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\registry\sdui_type_registry.dart (66 lines)

#### SduiTypeRegistry.buildNode (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static Widget buildNode(SduiNode node, SduiEventDispatcher dispatcher, BuildContext context)
//  â³ Calls: SduiEventDispatcher, SduiNode
```

#### SduiTypeRegistry.register (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static void register(int typeId, SduiWidgetBuilder builder)
```

#### SduiTypeRegistry (Class)
```rust
// Lines 47-110 (64 LOC | Complexity 1) | used by 2 callers
class SduiTypeRegistry
//  â³ Calls: SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, SduiModuleCard, SduiDropdown, SduiWrap, SduiExpansionTile, SduiSpacer, SduiDivider, SduiTimePicker, SduiDatePicker, SduiHtmlViewer, SduiCarousel, SduiDocumentViewer, SduiTimeline, SduiGauge, SduiChart, SduiStlViewer, SduiImage, SduiVideo, SduiAudio, SduiDrawingPad, SduiMap, SduiHeatmap, SduiTerminal, SduiToggle, SduiTextInput, SduiTable, SduiShimmerLoader, SduiRadio, SduiProgressBar, SduiSlider, SduiOrdinalSlider, SduiListView, SduiListEditor, SduiGridView, SduiContainer, SduiChip, SduiCheckbox, SduiButton, SduiCodeEditor, SduiMarkdownEditor
//  â³ Called by: _SduiSandboxScreenState, SduiRenderer
```

### C:\horAIzon_2.0\shua_modules\shua_resume\cmd\main.go (42 lines)

#### main (Function)
```rust
// Lines 12-53 (42 LOC | Complexity 4) | used by 0 callers | [Io, CanPanic, EntryPoint]
func main()
//  â³ Calls: Error, InitDB, Info
```

### C:\horAIzon_2.0\sdui3\sdui\event_dispatcher.dart (97 lines)

#### SduiEventType (Enum)
```rust
// Lines 1-5 (5 LOC | Complexity 1) | used by 3 callers
enum SduiEventType
//  â³ Called by: SduiEvent.recycled, SduiEvent, SduiRegistry
```

#### SduiEventDispatcher.registerGlobalListener (Function)
```rust
// Lines 50-50 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void registerGlobalListener(SduiEventListener listener)
//  â³ Called by: SduiSandboxScreen
```

#### SduiEventDispatcher.dispatch (Function)
```rust
// Lines 79-79 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void dispatch(SduiEvent event)
//  â³ Calls: SduiEvent
//  â³ Called by: SduiRegistry
```

#### SduiEvent (Class)
```rust
// Lines 9-35 (27 LOC | Complexity 1) | used by 4 callers
class SduiEvent
//  â³ Calls: SduiEventType
//  â³ Called by: SduiEventDispatcher.dispatch, SduiEvent.recycled, _handleSduiEvent, SduiRegistry
```

#### SduiEvent.recycled (Function)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
static SduiEvent recycled(
//  â³ Calls: SduiEventType, SduiEvent
//  â³ Called by: SduiRegistry
```

#### SduiEventDispatcher.unregisterGlobalListener (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void unregisterGlobalListener(SduiEventListener listener)
//  â³ Called by: SduiSandboxScreen
```

#### SduiEventDispatcher.unregisterBlockListener (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void unregisterBlockListener(String blockId, SduiEventListener listener)
```

#### SduiEventDispatcher.registerBlockListener (Function)
```rust
// Lines 60-60 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void registerBlockListener(String blockId, SduiEventListener listener)
```

#### SduiEventDispatcher (Class)
```rust
// Lines 41-94 (54 LOC | Complexity 1) | used by 0 callers
class SduiEventDispatcher
//  â³ Calls: BoundedRouteHistory.isEmpty, RadixTrie.remove, SduiEventDispatcher
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\adapters\shua_orchestrator.py (306 lines)

#### YOLOMeterBackend.__init__ (Function)
```rust
// Lines 33-66 (34 LOC | Complexity 5) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
def __init__(self, **kwargs)
//  â³ Calls: MeterVisionEngine.get_model, find_latest_weights, __init__
```

#### YOLOMeterBackend (Class)
```rust
// Lines 32-185 (154 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class YOLOMeterBackend(LabelStudioMLBase)
//  â³ Calls: run, RadixTrie.insert
```

#### YOLOMeterBackend.predict (Function)
```rust
// Lines 68-185 (118 LOC | Complexity 14) | used by 0 callers | [MutatesState, Io, Tested, PotentialDeadCode]
def predict(self, tasks, **kwargs)
//  â³ Calls: parse_compound_class, resolve_image_path
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\training\collect_ocr_data.py (208 lines)

#### _show_crop_gui (Function)
```rust
// Lines 78-156 (79 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
def _show_crop_gui(img_bgr: np.ndarray, source_name: str, class_name: str) -> str
//  â³ Calls: ShuaDiaryEntries.title
```

#### collect (Function)
```rust
// Lines 173-252 (80 LOC | Complexity 12) | used by 0 callers | [Io, PotentialDeadCode]
def collect(source_dir: str, conf: float = 0.25)
//  â³ Calls: _append_label, _show_crop_gui, _hash_image, _load_existing_labels, _scan_images, find_latest_weights
```

#### on_quit (Function)
```rust
// Lines 136-138 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def on_quit(event=None)
```

#### _scan_images (Function)
```rust
// Lines 159-167 (9 LOC | Complexity 4) | used by 0 callers | [Pure, PotentialDeadCode]
def _scan_images(source_dir: str) -> list[str]
//  â³ Calls: walk
```

#### on_skip (Function)
```rust
// Lines 132-134 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def on_skip(event=None)
```

#### on_save (Function)
```rust
// Lines 124-130 (7 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def on_save(event=None)
```

#### review (Function)
```rust
// Lines 255-263 (9 LOC | Complexity 3) | used by 0 callers | [Io, Tested, PotentialDeadCode]
def review()
//  â³ Calls: _load_existing_labels
```

#### _hash_image (Function)
```rust
// Lines 74-75 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _hash_image(img_bgr: np.ndarray) -> str
```

#### _append_label (Function)
```rust
// Lines 64-71 (8 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def _append_label(filename: str, label: str)
```

#### _load_existing_labels (Function)
```rust
// Lines 54-61 (8 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
def _load_existing_labels() -> dict
//  â³ Calls: collect, review, RadixTrie.insert
```

### C:\horAIzon_2.0\sdui3\sdui\sdui_icon_registry.dart (61 lines)

#### SduiIconRegistry.resolve (Function)
```rust
// Lines 54-54 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static IconData resolve(String? name)
```

#### SduiIconRegistry.resolveOrNull (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static IconData? resolveOrNull(String? name)
//  â³ Called by: SduiRegistry
```

#### SduiIconRegistry (Class)
```rust
// Lines 5-63 (59 LOC | Complexity 1) | used by 11 callers | [CorePrimitive]
class SduiIconRegistry
//  â³ Called by: SduiButton, _SduiListEditorState, SduiRegistry, _SduiExpansionTileState, SduiModuleCard, SduiIconRegistry, SduiChip, _SduiTextInputState, SduiIconButton, _SduiMapState, _SduiTimelineState
```

### C:\horAIzon_2.0\scripts\ai_training\test_jbc_model.py (142 lines)

#### run_ollama_query (Function)
```rust
// Lines 132-156 (25 LOC | Complexity 2) | used by 1 callers | [Pure, Tested]
def run_ollama_query(user_query)
//  â³ Calls: MessagePackCodec.encode
//  â³ Called by: serialize_diary_state
```

#### serialize_diary_state (Function)
```rust
// Lines 97-106 (10 LOC | Complexity 3) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
def serialize_diary_state(blocks)
//  â³ Calls: validate_ast, run_ollama_query
```

#### validate_ast (Function)
```rust
// Lines 223-267 (45 LOC | Complexity 14) | used by 1 callers | [Pure, Tested]
def validate_ast(output, valid_uuids, allowed_types)
//  â³ Calls: self_heal_jbc_line
//  â³ Called by: serialize_diary_state
```

#### self_heal_jbc_line (Function)
```rust
// Lines 159-220 (62 LOC | Complexity 16) | used by 1 callers | [Pure, Tested]
def self_heal_jbc_line(line)
//  â³ Called by: validate_ast
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_list_editor.dart (650 lines)

#### _SduiListEditorState._bindKey (Function)
```rust
// Lines 74-74 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _bindKey
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._persistChange (Function)
```rust
// Lines 165-165 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _persistChange()
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._selectRadio (Function)
```rust
// Lines 218-218 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _selectRadio(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._onBackspaceOnEmpty (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onBackspaceOnEmpty(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildTagChip (Function)
```rust
// Lines 420-420 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTagChip(ThemeData theme, Color accentColor, String tag)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._resolveContainerColor (Function)
```rust
// Lines 236-236 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveContainerColor(ThemeData theme)
//  â³ Called by: _SduiListEditorState
```

#### ListStyle (Class)
```rust
// Lines 9-16 (8 LOC | Complexity 1) | used by 6 callers
abstract final class ListStyle
//  â³ Called by: _SduiListEditorState, _SduiListEditorState._listStyle, SduiRegistry, _SduiListEditorState, SduiListEditor, ListStyle
```

#### _SduiListEditorState.build (Function)
```rust
// Lines 245-245 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _ListItem.dispose (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiListEditorState.dispose (Function)
```rust
// Lines 108-108 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiListEditorState._minItems (Function)
```rust
// Lines 72-72 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _minItems
//  â³ Calls: _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._itemHintText (Function)
```rust
// Lines 78-78 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? get _itemHintText
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._toggleChecked (Function)
```rust
// Lines 184-184 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _toggleChecked(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.initState (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiListEditorState._loadFromContent (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _loadFromContent(String content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._maxItems (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _maxItems
//  â³ Calls: _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._initialContent (Function)
```rust
// Lines 76-76 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _initialContent
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._onEnterPressed (Function)
```rust
// Lines 194-194 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onEnterPressed(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildFooterActions (Function)
```rust
// Lines 575-575 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildFooterActions(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._int (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 5 callers | [Pure, Tested]
int? _int(int key)
//  â³ Called by: _SduiListEditorState._isReadOnly, _SduiListEditorState._minItems, _SduiListEditorState._maxItems, _SduiListEditorState._bulletStyle, _SduiListEditorState._listStyle
```

#### _SduiListEditorState._buildItemRow (Function)
```rust
// Lines 438-438 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildItemRow(ThemeData theme, Color accentColor, int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._serialize (Function)
```rust
// Lines 139-139 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _serialize()
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._headerLabel (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? get _headerLabel
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildHeaderRow (Function)
```rust
// Lines 279-279 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHeaderRow(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._isReadOnly (Function)
```rust
// Lines 73-73 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get _isReadOnly
//  â³ Calls: _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._resolveAccentColor (Function)
```rust
// Lines 231-231 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveAccentColor(ThemeData theme)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildProgressHeader (Function)
```rust
// Lines 309-309 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildProgressHeader(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### SduiListEditor.createState (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiListEditor> createState()
//  â³ Calls: SduiListEditor, _SduiListEditorState
```

#### SduiListEditor (Class)
```rust
// Lines 26-38 (13 LOC | Complexity 1) | used by 9 callers
class SduiListEditor extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiListEditorState.didUpdateWidget, _SduiListEditorState, SduiListEditor.createState, _SduiListEditorState.didUpdateWidget, _SduiListEditorState, SduiListEditor.createState, SduiRegistry, SduiListEditor, SduiTypeRegistry
```

#### _SduiListEditorState._accentIcon (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IconData? get _accentIcon
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._bulletStyle (Function)
```rust
// Lines 65-65 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _bulletStyle
//  â³ Calls: BulletStyle, _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildTagReadMode (Function)
```rust
// Lines 365-365 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTagReadMode(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState (Class)
```rust
// Lines 59-630 (572 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiListEditorState extends State<SduiListEditor>
//  â³ Calls: BulletStyle, SduiListEditor, _SduiListEditorState._onEnterPressed, _SduiListEditorState._itemHintText, _SduiListEditorState._onBackspaceOnEmpty, _SduiListEditorState._bulletStyle, _SduiListEditorState._selectRadio, _SduiListEditorState._toggleChecked, _SduiListEditorState._resolveContainerColor, _SduiListEditorState._buildTagChip, _SduiListEditorState._accentIcon, SduiIconRegistry.contains, _SduiListEditorState._buildFooterActions, _SduiListEditorState._buildItemRow, generate, _SduiListEditorState._buildProgressHeader, _SduiListEditorState._buildHeaderRow, _SduiListEditorState._headerLabel, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiListEditorState._buildTagReadMode, _SduiListEditorState._resolveAccentColor, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiListEditorState._persistChange, _SduiListEditorState._minItems, SduiEventDispatcher.onStateChange, _SduiListEditorState._bindKey, RadixTrie.insert, _SduiListEditorState._maxItems, ListStyle, _ListItem, _SduiListEditorState._listStyle, ShuaDiaryBlocks.content, SduiStateVault.clear, dispose, _SduiListEditorState._serialize, SduiNode.contentVal, _SduiListEditorState.didUpdateWidget, _SduiListEditorState._appendNewItem, _SduiListEditorState._isReadOnly, _SduiListEditorState._initialContent, _SduiListEditorState._loadFromContent, initState, SduiIconRegistry, BoundedRouteHistory.isEmpty, SduiNode.behavior
//  â³ Called by: SduiListEditor.createState, _SduiListEditorState, SduiListEditor.createState
```

#### _SduiListEditorState._appendNewItem (Function)
```rust
// Lines 157-157 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _appendNewItem({int? afterIndex})
//  â³ Called by: _SduiListEditorState
```

#### _ListItem (Class)
```rust
// Lines 40-57 (18 LOC | Complexity 1) | used by 3 callers
class _ListItem
//  â³ Calls: dispose
//  â³ Called by: _SduiListEditorState, _SduiListEditorState, _ListItem
```

#### _SduiListEditorState.didUpdateWidget (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiListEditor oldWidget)
//  â³ Calls: SduiListEditor
//  â³ Called by: _SduiListEditorState
```

#### BulletStyle (Class)
```rust
// Lines 19-24 (6 LOC | Complexity 1) | used by 6 callers
abstract final class BulletStyle
//  â³ Called by: _SduiListEditorState, _SduiListEditorState, _SduiListEditorState._bulletStyle, SduiRegistry, SduiListEditor, BulletStyle
```

#### _SduiListEditorState._listStyle (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _listStyle
//  â³ Calls: ListStyle, _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\diary\diary_search_service.ts (309 lines)

#### DiarySearchService.removeEntry (Function)
```rust
// Lines 139-150 (12 LOC | Complexity 3) | used by 2 callers | [MutatesState]
public removeEntry(entryId: string): void
//  â³ Calls: RadixTrie.remove
//  â³ Called by: DiarySearchService.reconcile, DiarySearchService.indexEntry
```

#### DiarySearchService.getInstance (Function)
```rust
// Lines 81-86 (6 LOC | Complexity 2) | used by 2 callers | [Pure]
public static getInstance(): DiarySearchService
//  â³ Calls: DiarySearchService
//  â³ Called by: SduiActionHandler._searchDiary, SduiScreenAssembler._assembleDiaryList
```

#### DiarySearchService.constructor (Function)
```rust
// Lines 77-79 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
private constructor()
//  â³ Calls: RadixTrie
```

#### tokenize (Function)
```rust
// Lines 41-50 (10 LOC | Complexity 3) | used by 1 callers | [Pure]
function tokenize(text: string): Set<string>
//  â³ Called by: DiarySearchService.indexEntry
```

#### DiarySearchService (Class)
```rust
// Lines 52-240 (189 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiarySearchService
//  â³ Calls: RadixTrie
//  â³ Called by: DiarySearchService.getInstance
```

#### DiarySearchService.search (Function)
```rust
// Lines 228-231 (4 LOC | Complexity 3) | used by 2 callers | [Pure]
public search(query: string, maxDistance: number): { [entryId: string]: SearchMatchDetail[] }
//  â³ Calls: SearchMatchDetail, RadixTrie.searchWithMatches
//  â³ Called by: SduiActionHandler._searchDiary, SduiScreenAssembler._assembleDiaryList
```

#### DiarySearchService.indexedEntryCount (Function)
```rust
// Lines 237-239 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
public get indexedEntryCount(): number
```

#### DiarySearchService.indexEntry (Function)
```rust
// Lines 101-131 (31 LOC | Complexity 8) | used by 1 callers | [MutatesState]
public indexEntry(entry: DiaryEntry, blocks: DiaryBlock[]): void
//  â³ Calls: DiaryBlock, DiaryEntry, RadixTrie.insert, tokenize, DiarySearchService.removeEntry
//  â³ Called by: DiarySearchService.reconcile
```

#### DiarySearchService.reconcile (Function)
```rust
// Lines 167-217 (51 LOC | Complexity 10) | used by 1 callers | [MutatesState, Io]
public reconcile(
//  â³ Calls: DiaryEntry, DiaryBlock, DiarySearchService.indexEntry, ShuaSyncQueue.id, DiarySearchService.removeEntry, LogEntry::from
//  â³ Called by: SduiScreenAssembler._assembleDiaryList
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\handlers\websocket_handler.go (1071 lines)

#### handleRpcCall (Function)
```rust
// Lines 168-254 (87 LOC | Complexity 15) | used by 1 callers | [Async, MutatesState, Io]
func handleRpcCall(s *SocketConnection, rpc ReqRpc)
//  â³ Calls: ReqRpc, SocketConnection, getCompiledHistory, getTemplatesList, handleMatrixCrud, handleWsofflineCompile, sendRpcSuccess, SocketConnection.Emit, Error, assembleScreen, sendRpcError, Info
//  â³ Called by: HandleWebSocket
```

#### assembleScreen (Function)
```rust
// Lines 278-564 (287 LOC | Complexity 59) | used by 1 callers | [MutatesState, Io, HighComplexity]
func assembleScreen(screenId string) (interface{}, error)
//  â³ Calls: ResumeMatrix, LoadAndHydrateBlueprint, Error
//  â³ Called by: handleRpcCall
```

#### SocketConnection (Struct)
```rust
// Lines 26-29 (4 LOC | Complexity 1) | used by 7 callers
SocketConnection struct
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, sendRpcSuccess, sendRpcError, handleRpcCall, HandleWebSocket, SocketConnection.Emit
```

#### getCompiledHistory (Function)
```rust
// Lines 590-642 (53 LOC | Complexity 13) | used by 1 callers | [MutatesState, Io]
func getCompiledHistory(params map[string]interface{}) ([]map[string]interface{}, error)
//  â³ Called by: handleRpcCall
```

#### ReqRpc (Struct)
```rust
// Lines 162-166 (5 LOC | Complexity 1) | used by 4 callers
ReqRpc struct
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, handleRpcCall, HandleWebSocket
```

#### getTemplatesList (Function)
```rust
// Lines 566-588 (23 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io]
func getTemplatesList() ([]map[string]interface{}, error)
//  â³ Called by: handleRpcCall
```

#### sendRpcSuccess (Function)
```rust
// Lines 266-276 (11 LOC | Complexity 2) | used by 3 callers | [MutatesState]
func sendRpcSuccess(s *SocketConnection, txId string, data interface{})
//  â³ Calls: SocketConnection, SocketConnection.Emit
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, handleRpcCall
```

#### sendRpcError (Function)
```rust
// Lines 256-264 (9 LOC | Complexity 1) | used by 3 callers | [MutatesState]
func sendRpcError(s *SocketConnection, txId string, message string)
//  â³ Calls: SocketConnection, SocketConnection.Emit
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, handleRpcCall
```

#### handleWsofflineCompile (Function)
```rust
// Lines 644-855 (212 LOC | Complexity 22) | used by 1 callers | [Async, MutatesState, Io, HighComplexity]
func handleWsofflineCompile(s *SocketConnection, rpc ReqRpc)
//  â³ Calls: ResumeMatrix, ReqRpc, SocketConnection, sendRpcSuccess, saveCompilationToHistory, uploadToCAS, CompileTypst, TailorResume, FilterResume, DefaultTailorConfig, Error, SocketConnection.Emit, Info, sendRpcError
//  â³ Called by: handleRpcCall
```

#### handleMatrixCrud (Function)
```rust
// Lines 893-1116 (224 LOC | Complexity 47) | used by 1 callers | [MutatesState, Io, HighComplexity]
func handleMatrixCrud(s *SocketConnection, rpc ReqRpc)
//  â³ Calls: Award, Certificate, Skill, ProjectItem, Education, WorkItem, ResumeMatrix, ReqRpc, SocketConnection, sendRpcSuccess, parseBoolStr, parseListEditorString, sendRpcError
//  â³ Called by: handleRpcCall
```

#### RpcRequest (Struct)
```rust
// Lines 53-57 (5 LOC | Complexity 1) | used by 0 callers
RpcRequest struct
```

#### parseBoolStr (Function)
```rust
// Lines 885-891 (7 LOC | Complexity 3) | used by 1 callers | [Pure]
func parseBoolStr(val interface{}) bool
//  â³ Called by: handleMatrixCrud
```

#### parseListEditorString (Function)
```rust
// Lines 861-883 (23 LOC | Complexity 8) | used by 1 callers | [MutatesState]
func parseListEditorString(val interface{}) []string
//  â³ Called by: handleMatrixCrud
```

#### SocketConnection.Emit (Function)
```rust
// Lines 31-51 (21 LOC | Complexity 4) | used by 4 callers | [MutatesState, Io]
func (s *SocketConnection) Emit(event string, payload interface{}) error
//  â³ Calls: SocketConnection
//  â³ Called by: handleWsofflineCompile, sendRpcSuccess, sendRpcError, handleRpcCall
```

#### HandleWebSocket (Function)
```rust
// Lines 60-159 (100 LOC | Complexity 23) | used by 0 callers | [Async, MutatesState, Io, HighComplexity, PotentialDeadCode]
func HandleWebSocket(c *websocket.Conn)
//  â³ Calls: ReqRpc, SocketConnection, handleRpcCall, Info, Error
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_grid_view.dart (51 lines)

#### SduiGridView.build (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiGridView (Class)
```rust
// Lines 11-60 (50 LOC | Complexity 1) | used by 0 callers
class SduiGridView extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.maxHeight, BoundedRouteHistory.isEmpty, _SduiShimmerLoaderState.padding, SduiGridView
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_gauge.dart (245 lines)

#### SduiGauge._buildLinearGauge (Function)
```rust
// Lines 180-187 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildLinearGauge(
//  â³ Called by: SduiGauge
```

#### SduiGauge (Class)
```rust
// Lines 11-238 (228 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiGauge extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, SduiGauge._buildRadialGauge, SduiGauge._buildLinearGauge, ShuaDiaryEntries.title, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiGauge.build (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiGauge._buildRadialGauge (Function)
```rust
// Lines 91-98 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildRadialGauge(
//  â³ Called by: SduiGauge
```

### C:\horAIzon_2.0\scripts\pretrain_ocr.py (101 lines)

#### train (Function)
```rust
// Lines 46-133 (88 LOC | Complexity 7) | used by 0 callers | [Async, Io, Tested, PotentialDeadCode]
def train(epochs: int = 30)
//  â³ Calls: _full_string_accuracy, _char_accuracy, ctc_greedy_decode, train, CRNN, SerialOCRDataset, load_synth_samples
```

#### load_synth_samples (Function)
```rust
// Lines 32-44 (13 LOC | Complexity 4) | used by 1 callers | [Io]
def load_synth_samples() -> list[tuple]
//  â³ Calls: train, RadixTrie.insert
//  â³ Called by: train
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\kill_ports.py (21 lines)

#### kill_processes_on_ports (Function)
```rust
// Lines 4-24 (21 LOC | Complexity 7) | used by 0 callers | [Io, PotentialDeadCode]
def kill_processes_on_ports(ports)
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\core\model_utils.py (164 lines)

#### resolve_image_path (Function)
```rust
// Lines 183-211 (29 LOC | Complexity 4) | used by 4 callers | [Pure]
def resolve_image_path(image_filename, dataset_dir=None)
//  â³ Called by: YOLOMeterBackend.predict, main, main, main
```

#### find_latest_weights (Function)
```rust
// Lines 28-73 (46 LOC | Complexity 7) | used by 0 callers | [Io, Tested, PotentialDeadCode]
def find_latest_weights(runs_dir=None, run_prefix="veco_meter_run")
```

#### get_run_num (Function)
```rust
// Lines 59-62 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def get_run_num(folder_path)
```

#### parse_compound_class (Function)
```rust
// Lines 150-177 (28 LOC | Complexity 5) | used by 1 callers | [Pure]
def parse_compound_class(compound_name)
//  â³ Called by: YOLOMeterBackend.predict
```

#### find_pretrained_weights (Function)
```rust
// Lines 76-100 (25 LOC | Complexity 3) | used by 2 callers | [Io]
def find_pretrained_weights(filename="yolo11n.pt")
//  â³ Called by: main, StandaloneWebAppHandler.get_model
```

#### find_latest_export (Function)
```rust
// Lines 103-134 (32 LOC | Complexity 8) | used by 5 callers | [Io]
def find_latest_export()
//  â³ Called by: check_stats, check_stats, main, main, main
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_socket_provider.dart (720 lines)

#### SduiSocketManager.listenForConnect (Function)
```rust
// Lines 427-427 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForConnect(VoidCallback onConnect, {required String screenId})
//  â³ Calls: onConnect
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.disconnect (Function)
```rust
// Lines 149-149 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void disconnect()
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.sendRpcWithResponse (Function)
```rust
// Lines 509-513 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<dynamic> sendRpcWithResponse(
//  â³ Called by: _SduiJbcPanelState
```

#### SduiSocketManager.listenForPatches (Function)
```rust
// Lines 362-365 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForPatches(
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager._moduleIdForScreen (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _moduleIdForScreen(String screenId)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager (Class)
```rust
// Lines 15-702 (688 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiSocketManager
//  â³ Calls: SduiNode, SduiIconRegistry.contains, SduiTransport.applyDelta, SduiSocketManager._socketForMethod, BorrowedLogEntry::deserialize, SduiSocketManager.requestScreen, SduiSocketManager.emitRpc, LogEntry::from, SduiSocketManager._ensureSocketListeners, SduiTransport.decodeJson, SduiTransport, SduiSocketManager.disconnect, SduiSocketManager._socketFor, SduiSocketManager._moduleIdForScreen, SduiSocketManager._isStaticScreen, SduiSocketManager.connect, SduiStateVault.clear, RadixTrie.remove, SduiFlexContext.of, onConnect, build, log
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager._socketFor (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket _socketFor(String moduleId)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.injectLocalDelta (Function)
```rust
// Lines 563-563 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void injectLocalDelta(String screenId, Map<String, dynamic> delta)
//  â³ Called by: SduiEventDispatcher
```

#### SduiSocketManager.connect (Function)
```rust
// Lines 147-147 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
void connect()
//  â³ Calls: SduiSocketManager.connectViaGateway
//  â³ Called by: get_conn, connectSocket, main, SduiSocketManager
```

#### SduiSocketManager.evictCache (Function)
```rust
// Lines 479-479 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void evictCache(String screenId)
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.listenForHotReload (Function)
```rust
// Lines 389-391 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForHotReload(
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager._socketForMethod (Function)
```rust
// Lines 581-581 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket? _socketForMethod(String method)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.requestScreen (Function)
```rust
// Lines 157-157 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<SduiNode>> requestScreen(String screenId)
//  â³ Calls: SduiNode
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager._ensureSocketListeners (Function)
```rust
// Lines 599-599 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _ensureSocketListeners(String moduleId, String screenId)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.getScreen (Function)
```rust
// Lines 311-311 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<SduiNode>> getScreen(String screenId)
//  â³ Calls: SduiNode
//  â³ Called by: SduiScreen
```

#### SduiSocketManager._isStaticScreen (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool _isStaticScreen(String screenId)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.emitRpc (Function)
```rust
// Lines 491-491 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
void emitRpc(String method, Map<String, dynamic> params)
//  â³ Called by: _SduiTextInputState, SduiEventDispatcher, SduiSocketManager
```

#### SduiSocketManager.socketForScreen (Function)
```rust
// Lines 141-141 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket? socketForScreen(String screenId)
//  â³ Called by: _SduiJbcPanelState
```

#### SduiSocketManager.connectViaGateway (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void connectViaGateway(String screenId)
//  â³ Called by: SduiSocketManager.connect
```

#### SduiSocketManager.reRequestScreen (Function)
```rust
// Lines 447-447 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void reRequestScreen(String screenId)
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.listenForReplace (Function)
```rust
// Lines 334-337 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForReplace(
//  â³ Calls: SduiNode
//  â³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_code_editor.dart (494 lines)

#### _SduiCodeEditorState.dispose (Function)
```rust
// Lines 282-282 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiCodeEditorState (Class)
```rust
// Lines 218-496 (279 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiCodeEditorState extends ConsumerState<SduiCodeEditor>
//  â³ Calls: SduiCodeEditor, _SduiCodeEditorState._onLanguageChanged, SyntaxHighlightingController.buildTextSpan, _SduiCodeEditorState._onTextChanged, _SduiShimmerLoaderState.padding, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, dispose, _SduiCodeEditorState.didUpdateWidget, _SduiCodeEditorState._onFocusChange, SyntaxHighlightingController, SduiNode.behavior, SduiNode.contentVal, initState
//  â³ Called by: SduiCodeEditor.createState, _SduiCodeEditorState, SduiCodeEditor.createState
```

#### SyntaxHighlightingController.buildTextSpan (Function)
```rust
// Lines 140-140 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing})
//  â³ Called by: _SduiCodeEditorState
```

#### SduiCodeEditor (Class)
```rust
// Lines 204-216 (13 LOC | Complexity 1) | used by 9 callers
class SduiCodeEditor extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiCodeEditorState.didUpdateWidget, _SduiCodeEditorState, SduiCodeEditor.createState, _SduiCodeEditorState.didUpdateWidget, _SduiCodeEditorState, SduiCodeEditor.createState, SduiRegistry, SduiCodeEditor, SduiTypeRegistry
```

#### _SduiCodeEditorState._onFocusChange (Function)
```rust
// Lines 245-245 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFocusChange()
//  â³ Called by: _SduiCodeEditorState
```

#### SyntaxHighlightingController (Class)
```rust
// Lines 25-202 (178 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class SyntaxHighlightingController extends TextEditingController
//  â³ Calls: SduiFlexContext.of, BoundedRouteHistory.isEmpty, SyntaxRules
//  â³ Called by: _SduiCodeEditorState, _SduiCodeEditorState, SyntaxHighlightingController
```

#### _SduiCodeEditorState._onTextChanged (Function)
```rust
// Lines 290-290 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiCodeEditorState
```

#### _SduiCodeEditorState.build (Function)
```rust
// Lines 315-315 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiCodeEditorState._onLanguageChanged (Function)
```rust
// Lines 297-297 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onLanguageChanged(int newLangId)
//  â³ Called by: _SduiCodeEditorState
```

#### SyntaxRules (Class)
```rust
// Lines 8-22 (15 LOC | Complexity 1) | used by 3 callers
class SyntaxRules
//  â³ Called by: SyntaxHighlightingController, SyntaxHighlightingController, SyntaxRules
```

#### _SduiCodeEditorState.didUpdateWidget (Function)
```rust
// Lines 254-254 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiCodeEditor oldWidget)
//  â³ Calls: SduiCodeEditor
//  â³ Called by: _SduiCodeEditorState
```

#### SduiCodeEditor.createState (Function)
```rust
// Lines 215-215 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiCodeEditor> createState()
//  â³ Calls: SduiCodeEditor, _SduiCodeEditorState
```

#### _SduiCodeEditorState.initState (Function)
```rust
// Lines 226-226 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\analyzer.rs (645 lines)

#### detect_serde_callbacks (Function)
```rust
// Lines 333-407 (75 LOC | Complexity 22) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn detect_serde_callbacks(state: &AppState)
//  â³ Calls: AppState, SduiIconRegistry.contains, get_tree_sitter_language, get_parser
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### test_regression_hardening (Function)
```rust
// Lines 583-664 (82 LOC | Complexity 6) | used by 0 callers | [MutatesState, Io, CanPanic]
fn test_regression_hardening()
//  â³ Calls: assign_tags, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, parse_and_index_file, LogEntry::from, AppState::new
```

#### detect_entry_points (Function)
```rust
// Lines 409-426 (18 LOC | Complexity 5) | used by 2 callers | [MutatesState, CanPanic]
pub fn detect_entry_points(state: &AppState)
//  â³ Calls: AppState, log_verbose, SduiIconRegistry.contains
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### compute_centrality (Function)
```rust
// Lines 4-17 (14 LOC | Complexity 3) | used by 2 callers | [MutatesState, CanPanic]
pub fn compute_centrality(state: &AppState)
//  â³ Calls: AppState, collect
//  â³ Called by: debug_analysis, run_full_scan
```

#### assign_tags (Function)
```rust
// Lines 497-573 (77 LOC | Complexity 8) | used by 3 callers | [MutatesState, CanPanic]
pub fn assign_tags(state: &AppState)
//  â³ Calls: AppState, log_verbose, SduiIconRegistry.contains, collect, detect_test_linkages
//  â³ Called by: test_regression_hardening, debug_analysis, run_full_scan
```

#### detect_framework_invoked (Function)
```rust
// Lines 133-331 (199 LOC | Complexity 44) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn detect_framework_invoked(state: &AppState)
//  â³ Calls: AppState, SduiIconRegistry.contains, get_tree_sitter_language, get_parser
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### detect_test_linkages (Function)
```rust
// Lines 428-495 (68 LOC | Complexity 17) | used by 1 callers | [MutatesState, Io, CanPanic]
pub fn detect_test_linkages(state: &AppState)
//  â³ Calls: AppState, log_verbose, SduiIconRegistry.contains
//  â³ Called by: assign_tags
```

#### detect_cycles (Function)
```rust
// Lines 19-59 (41 LOC | Complexity 12) | used by 2 callers | [MutatesState, CanPanic]
pub fn detect_cycles(state: &AppState)
//  â³ Calls: AppState, SduiIconRegistry.contains, RadixTrie.insert
//  â³ Called by: debug_analysis, run_full_scan
```

#### detect_trait_method_impls (Function)
```rust
// Lines 61-131 (71 LOC | Complexity 21) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn detect_trait_method_impls(state: &AppState)
//  â³ Calls: AppState, SduiIconRegistry.contains, get_tree_sitter_language, get_parser
//  â³ Called by: test_regression_hardening, run_full_scan
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\search.rs (85 lines)

#### search_bm25 (Function)
```rust
// Lines 9-89 (81 LOC | Complexity 11) | used by 1 callers | [MutatesState, CanPanic]
pub fn search_bm25(query: &str, state: &AppState) -> Vec<SearchResult>
//  â³ Calls: SearchResult, AppState, RadixTrie.insert, collect, filter
//  â³ Called by: export_sdg
```

#### SearchResult (Struct)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 1 callers
pub struct SearchResult
//  â³ Called by: search_bm25
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_ordinal_slider.dart (287 lines)

#### SduiOrdinalSlider (Class)
```rust
// Lines 7-19 (13 LOC | Complexity 1) | used by 8 callers
class SduiOrdinalSlider extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiOrdinalSliderState, SduiOrdinalSlider.createState, _SduiOrdinalSliderState.didUpdateWidget, _SduiOrdinalSliderState, SduiOrdinalSlider.createState, SduiRegistry, SduiOrdinalSlider, SduiTypeRegistry
```

#### SduiOrdinalSlider.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiOrdinalSlider> createState()
//  â³ Calls: SduiOrdinalSlider, _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState._labelFor (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _labelFor(double rating, List<String>? customLabels)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState (Class)
```rust
// Lines 21-289 (269 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiOrdinalSliderState extends ConsumerState<SduiOrdinalSlider>
//  â³ Calls: SduiOrdinalSlider, _SduiShimmerLoaderState.borderRadius, _SduiOrdinalSliderState._labelFor, _SduiOrdinalSliderState._handleTap, _SduiOrdinalSliderState._iconFor, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, generate, SduiFlexContext.of, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiEventDispatcher.onAction, SduiNode.behavior, SduiEventDispatcher.onStateChange
//  â³ Called by: SduiOrdinalSlider.createState, _SduiOrdinalSliderState, SduiOrdinalSlider.createState
```

#### _SduiOrdinalSliderState._handleTap (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _handleTap(int index, double tapX, double iconSize, bool halfStep, bool isReadOnly)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState._iconFor (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IconData _iconFor(String iconName, int index, double activeRating)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState.build (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\core\pipeline.py (95 lines)

#### MeterReadingPipeline (Class)
```rust
// Lines 2-49 (48 LOC | Complexity 1) | used by 0 callers
class MeterReadingPipeline
//  â³ Calls: MeterReadingPipeline.evaluate_stage_1
```

#### MeterReadingPipeline.evaluate_stage_1 (Function)
```rust
// Lines 3-49 (47 LOC | Complexity 9) | used by 1 callers | [Pure]
def evaluate_stage_1(self, yolo_predictions: List[Dict[str, Any]]) -> Dict[str, Any]
//  â³ Called by: MeterReadingPipeline
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\utils\RadixTrie.ts (483 lines)

#### TrieEntry (Interface)
```rust
// Lines 0-4 (5 LOC | Complexity 1) | used by 1 callers
interface TrieEntry
//  â³ Called by: TrieNode
```

#### SearchMatchDetail (Interface)
```rust
// Lines 6-10 (5 LOC | Complexity 1) | used by 5 callers
interface SearchMatchDetail
//  â³ Called by: RadixTrie.collectAllBlockIds, RadixTrie._fuzzySearch, RadixTrie.searchWithMatches, TagSearchService.searchTagsWithMatches, DiarySearchService.search
```

#### RadixTrie._remove (Function)
```rust
// Lines 98-156 (59 LOC | Complexity 18) | used by 1 callers | [MutatesState]
private _remove(
//  â³ Calls: TrieNode, filter
//  â³ Called by: RadixTrie.remove
```

#### RadixTrie (Class)
```rust
// Lines 22-268 (247 LOC | Complexity 1) | used by 5 callers | [HighComplexity]
class RadixTrie
//  â³ Calls: TrieNode
//  â³ Called by: TagSearchService, DiarySearchService, TagSearchService.clearTrie, TagSearchService.constructor, DiarySearchService.constructor
```

#### RadixTrie.search (Function)
```rust
// Lines 158-161 (4 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
public search(prefix: string, maxDistance: number = 2): string[]
//  â³ Calls: RadixTrie.searchWithMatches
```

#### RadixTrie.remove (Function)
```rust
// Lines 93-96 (4 LOC | Complexity 1) | used by 18 callers | [MutatesState, CorePrimitive]
public remove(word: string, entryId: string, blockId?: string): boolean
//  â³ Calls: RadixTrie._remove
//  â³ Called by: AppState::upsert_file_symbols, _SduiTableState, main, SduiEventDispatcher, main, showDetails, main, DiarySearchService.removeEntry, _SduiSpacerState, HbpLoggerLayer::on_event, SduiEventDispatcher, main, chunk_finalize, main, main, _SduiTableState, SduiSocketManager, _SduiTerminalState
```

#### RadixTrie._fuzzySearch (Function)
```rust
// Lines 181-248 (68 LOC | Complexity 8) | used by 1 callers | [MutatesState]
private _fuzzySearch(
//  â³ Calls: SearchMatchDetail, TrieNode, RadixTrie.collectAllBlockIds
//  â³ Called by: RadixTrie.searchWithMatches
```

#### TrieNode.constructor (Function)
```rust
// Lines 16-19 (4 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor()
```

#### TrieNode (Class)
```rust
// Lines 12-20 (9 LOC | Complexity 1) | used by 6 callers
class TrieNode
//  â³ Calls: TrieEntry
//  â³ Called by: RadixTrie.collectAllBlockIds, RadixTrie._fuzzySearch, RadixTrie._remove, RadixTrie, RadixTrie._insert, RadixTrie.constructor
```

#### RadixTrie.collectAllBlockIds (Function)
```rust
// Lines 250-267 (18 LOC | Complexity 7) | used by 1 callers | [MutatesState]
private collectAllBlockIds(node: TrieNode, resultSet: Map<string, SearchMatchDetail[]>, distance: number): void
//  â³ Calls: SearchMatchDetail, TrieNode
//  â³ Called by: RadixTrie._fuzzySearch
```

#### RadixTrie.searchWithMatches (Function)
```rust
// Lines 163-179 (17 LOC | Complexity 5) | used by 3 callers | [MutatesState]
public searchWithMatches(prefix: string, maxDistance: number = 2): { [entryId: string]: SearchMatchDetail[] }
//  â³ Calls: SearchMatchDetail, RadixTrie._fuzzySearch, LogEntry::from
//  â³ Called by: RadixTrie.search, TagSearchService.searchTagsWithMatches, DiarySearchService.search
```

#### RadixTrie._insert (Function)
```rust
// Lines 33-69 (37 LOC | Complexity 9) | used by 1 callers | [MutatesState]
private _insert(node: TrieNode, suffix: string, blockId: string, entryId: string, fullTag: string): void
//  â³ Calls: TrieNode
//  â³ Called by: RadixTrie.insert
```

#### RadixTrie.constructor (Function)
```rust
// Lines 25-27 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor()
//  â³ Calls: TrieNode
```

#### RadixTrie.insert (Function)
```rust
// Lines 29-31 (3 LOC | Complexity 1) | used by 59 callers | [Pure, Tested, CorePrimitive]
public insert(tag: string, blockId: string, entryId: string): void
//  â³ Calls: RadixTrie._insert
//  â³ Called by: compute_subgraph, AppState::upsert_file_symbols, start_supervisor_loop, OCRReviewerApp.apply_filter, OCRReviewerApp, _SduiTableState, _spatial_augment, _load_existing_labels, _SduiListEditorState, main, _SduiContainerState, check_stats, check_stats, main, find_latest_weights, serialize, YOLOMeterBackend, main, _load_data, proxy_request, deduplicate_edges, find_all_exports, export_sdg, _preprocess_crop, TagSearchService.indexBlockContent, DiarySearchService.indexEntry, _load_existing_labels, load_kwh_samples, infer, _load_template, extract_api_routes, _DiaryEditorContent, _load_template, SduiNode::with_content, SduiNode::with_behavior, MobileEdgeBackend, track_performance_timing, FieldVisitor::record_bool, FieldVisitor::record_i64, FieldVisitor::record_u64, FieldVisitor::record_str, FieldVisitor::record_debug, control_module, detect_cycles, _load_existing_labels, main, load_synth_samples, _SduiListEditorState, run_garbage_collection, serve_file, chunk_init, main, main, Visitor::record_str, Visitor::record_debug, evaluate_best_model, parse_and_index_file, _SduiTerminalState, search_bm25
```

### C:\horAIzon_2.0\shua_governor\src\routes\ai_proxy.rs (112 lines)

#### try_forward (Function)
```rust
// Lines 141-167 (27 LOC | Complexity 6) | used by 1 callers | [Async, Io]
async fn try_forward(url: &str, body: Value) -> Result<Response, String>
//  â³ Calls: Response, get_client, LogEntry::from, header
//  â³ Called by: infer
```

#### get_client (Function)
```rust
// Lines 46-48 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
fn get_client() -> &'static Client<HttpConnector, Body>
//  â³ Calls: build
```

#### infer (Function)
```rust
// Lines 57-135 (79 LOC | Complexity 9) | used by 0 callers | [Async, MutatesState, Io, ApiRoute, Tested]
pub async fn infer(
//  â³ Calls: AppState, RadixTrie.insert, try_forward, error_response
```

#### error_response (Function)
```rust
// Lines 170-172 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
fn error_response(status: StatusCode, code: &str) -> Response
//  â³ Calls: Response
//  â³ Called by: infer
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_audio.dart (524 lines)

#### _SduiAudioState._onSelectFile (Function)
```rust
// Lines 190-190 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onSelectFile(BuildContext context, String bindKey, String filePath)
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState.initState (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiAudioState._formatDuration (Function)
```rust
// Lines 125-125 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatDuration(Duration d)
//  â³ Called by: _SduiAudioState
```

#### SduiAudio (Class)
```rust
// Lines 13-25 (13 LOC | Complexity 1) | used by 3 callers
class SduiAudio extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiAudioState, SduiAudio.createState, SduiTypeRegistry
```

#### _SduiAudioState.build (Function)
```rust
// Lines 221-221 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiAudioState._togglePlayback (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _togglePlayback()
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState._showPicker (Function)
```rust
// Lines 131-131 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context, String bindKey)
//  â³ Called by: _SduiAudioState
```

#### SduiAudio.createState (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiAudio> createState()
//  â³ Calls: SduiAudio, _SduiAudioState
```

#### _SduiAudioState (Class)
```rust
// Lines 27-528 (502 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiAudioState extends ConsumerState<SduiAudio>
//  â³ Calls: SduiAudio, _SduiAudioState._formatDuration, _SduiAudioState._togglePlayback, _SduiAudioState._showPicker, BoundedRouteHistory.isEmpty, _SduiAudioState._setAudioSource, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, ShuaDiaryBlocks.content, SduiEventDispatcher.onStateChange, MediaUploader.pickAndUploadWithUi, _SduiAudioState._onSelectFile, ShuaDiaryEntries.title, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, log, dispose, initState
//  â³ Called by: SduiAudio.createState
```

#### _SduiAudioState.dispose (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiAudioState._setAudioSource (Function)
```rust
// Lines 75-75 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _setAudioSource(String path)
//  â³ Called by: _SduiAudioState
```

### C:\horAIzon_2.0\tools\compress_sdui_mds.py (160 lines)

#### extract_h1_title (Function)
```rust
// Lines 31-44 (14 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def extract_h1_title(file_path: Path) -> str
//  â³ Calls: compress, ShuaDiaryEntries.title, ThemeCompiler.compile
//  â³ Called by: compress
```

#### compress (Function)
```rust
// Lines 122-173 (52 LOC | Complexity 6) | used by 1 callers | [Io, Cycle, Tested]
def compress()
//  â³ Calls: rewrite_markdown_links, ShuaDiaryEntries.title, extract_h1_title, get_sorted_files
//  â³ Called by: extract_h1_title
```

#### rewrite_markdown_links (Function)
```rust
// Lines 93-120 (28 LOC | Complexity 2) | used by 1 callers | [Pure]
def rewrite_markdown_links(content: str) -> str
//  â³ Calls: ThemeCompiler.compile
//  â³ Called by: compress
```

#### get_numeric_key (Function)
```rust
// Lines 69-74 (6 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def get_numeric_key(item)
```

#### repl (Function)
```rust
// Lines 105-118 (14 LOC | Complexity 2) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
def repl(match)
```

#### get_sorted_files (Function)
```rust
// Lines 46-91 (46 LOC | Complexity 10) | used by 1 callers | [Io]
def get_sorted_files()
//  â³ Called by: compress
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_wrap.dart (170 lines)

#### SduiWrap (Class)
```rust
// Lines 7-19 (13 LOC | Complexity 1) | used by 3 callers
class SduiWrap extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiWrapState, SduiWrap.createState, SduiTypeRegistry
```

#### _SduiWrapState (Class)
```rust
// Lines 21-175 (155 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiWrapState extends ConsumerState<SduiWrap>
//  â³ Calls: SduiWrap, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiRenderer, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiWrap.createState
```

#### SduiWrap.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiWrap> createState()
//  â³ Calls: SduiWrap, _SduiWrapState
```

#### _SduiWrapState.build (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\client_flutter\lib\core\governor\metrics_snapshot.dart (88 lines)

#### MetricsSnapshot.MetricsSnapshot (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory MetricsSnapshot.fromJson(Map<String, dynamic> json)
//  â³ Calls: ModuleMetrics.fromJson, MetricsSnapshot
```

#### MetricsSnapshot (Class)
```rust
// Lines 34-92 (59 LOC | Complexity 1) | used by 0 callers
class MetricsSnapshot
//  â³ Calls: ModuleMetrics.fromJson, ModuleMetrics, MetricsSnapshot
```

#### ModuleMetrics.fromJson (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
factory ModuleMetrics.fromJson(Map<String, dynamic> json)
//  â³ Called by: MetricsSnapshot, MetricsSnapshot.MetricsSnapshot, ModuleMetrics.ModuleMetrics
```

#### MetricsSnapshot.toString (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
String toString()
```

#### MetricsSnapshot.fromJson (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory MetricsSnapshot.fromJson(Map<String, dynamic> json)
```

#### ModuleMetrics.ModuleMetrics (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory ModuleMetrics.fromJson(Map<String, dynamic> json)
//  â³ Calls: ModuleMetrics.fromJson, ModuleMetrics
```

#### ModuleMetrics (Class)
```rust
// Lines 7-30 (24 LOC | Complexity 1) | used by 0 callers
class ModuleMetrics
//  â³ Calls: ModuleMetrics
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\rust.rs (147 lines)

#### RustExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct RustExtractor;
```

#### RustExtractor::extract (Function)
```rust
// Lines 9-154 (146 LOC | Complexity 29) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\check_dataset_stats.py (120 lines)

#### check_stats (Function)
```rust
// Lines 14-133 (120 LOC | Complexity 23) | used by 0 callers | [Io, HighComplexity, PotentialDeadCode]
def check_stats()
//  â³ Calls: check_stats, SduiBlockRegistry.load, find_latest_export, RadixTrie.insert
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_stl_viewer.dart (134 lines)

#### SduiStlViewer.build (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiStlViewer (Class)
```rust
// Lines 30-161 (132 LOC | Complexity 1) | used by 1 callers
class SduiStlViewer extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.padding, SduiStlViewer._buildAxisIndicator, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiStlViewer._buildAxisIndicator (Function)
```rust
// Lines 143-143 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildAxisIndicator(String name, Color color)
//  â³ Called by: SduiStlViewer
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\xml.rs (140 lines)

#### serialize (Function)
```rust
// Lines 7-146 (140 LOC | Complexity 23) | used by 1 callers | [MutatesState, CanPanic, Tested, HighComplexity]
pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String
//  â³ Calls: AppState, ExportOptions, SubGraph, collect, SduiIconRegistry.contains, RadixTrie.insert, LogEntry::from
//  â³ Called by: export_sdg
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_button.dart (112 lines)

#### SduiButton (Class)
```rust
// Lines 7-117 (111 LOC | Complexity 1) | used by 3 callers
class SduiButton extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiFlexContext.of, SduiIconRegistry, ShuaDiaryBlocks.content, SduiEventDispatcher.onAction, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior
//  â³ Called by: SduiRegistry, SduiTypeRegistry, SduiButton
```

#### SduiButton.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_image.dart (451 lines)

#### SduiImage.build (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### SduiImage (Class)
```rust
// Lines 12-437 (426 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiImage extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, MediaUploader.pickAndUploadWithUi, err, SduiImage._buildZoomImage, _SduiShimmerLoaderState.padding, SduiImage._showZoomModal, c, SduiImage._buildErrorImage, SduiBlockRegistry.all, SduiImage._pickAndUpload, _SduiShimmerLoaderState.borderRadius, BoundedRouteHistory.isEmpty, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiImage._pickAndUpload (Function)
```rust
// Lines 423-427 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _pickAndUpload(
//  â³ Called by: SduiImage
```

#### SduiImage._buildErrorImage (Function)
```rust
// Lines 299-305 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildErrorImage(
//  â³ Called by: SduiImage
```

#### SduiImage._showZoomModal (Function)
```rust
// Lines 331-337 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showZoomModal(
//  â³ Called by: SduiImage
```

#### SduiImage._buildZoomImage (Function)
```rust
// Lines 380-384 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildZoomImage(
//  â³ Called by: SduiImage
```

### C:\horAIzon_2.0\sdui3\sdui_sandbox\views\sdui_sandbox_screen.dart (22 lines)

#### _resolveBlueprintNode (Function)
```rust
// Lines 481-486 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Map<int, dynamic> _resolveBlueprintNode(
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiSandboxScreen
```

#### _buildLegacyNativeBlock (Function)
```rust
// Lines 414-414 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildLegacyNativeBlock(DiaryBlock block)
//  â³ Calls: DiaryBlock
//  â³ Called by: SduiSandboxScreen
```

#### _initBlock (Function)
```rust
// Lines 106-106 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _initBlock()
//  â³ Called by: SduiSandboxScreen
```

#### _loadBlueprints (Function)
```rust
// Lines 91-91 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
Future<void> _loadBlueprints()
//  â³ Called by: _SduiSandboxScreenState._loadBlueprints, _SduiSandboxScreenState, SduiSandboxScreen
```

#### SduiSandboxScreen.createState (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSandboxScreen> createState()
//  â³ Calls: SduiSandboxScreen, _SduiSandboxScreenState
```

#### _generateMockAst (Function)
```rust
// Lines 664-664 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Map<int, dynamic> _generateMockAst(String type, String id, String content, String? metadataJson)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiSandboxScreen
```

#### _handleSduiEvent (Function)
```rust
// Lines 65-65 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _handleSduiEvent(SduiEvent event)
//  â³ Calls: SduiEvent
//  â³ Called by: SduiSandboxScreen
```

#### build (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 123 callers | [Pure, TraitMethod, CorePrimitive]
Widget build(BuildContext context)
//  â³ Called by: SduiButton.build, _SduiCodeEditorState.build, _SduiChipState.build, SduiStateVault.build, start_supervisor_loop, _SduiTableState.build, _SduiOrdinalSliderState.build, _SduiListEditorState.build, AdaptiveShell.build, _SduiContainerState.build, _SduiMarkdownEditorState.build, _SduiToggleState.build, _JoshAutomatedGenerationDialogState.build, _DiaryEntryCardState.build, _DiaryListScreenState.build, _SduiCheckboxState.build, _SduiSandboxScreenState.build, HorAIzonClientShell.build, _SduiDividerState.build, _SduiExpansionTileState.build, SduiDatePicker.build, _SduiHtmlViewerState.build, get_client, SduiStlViewer.build, _SduiHeadingState.build, _SduiShimmerLoaderState.build, _SduiDrawingPadState.build, _SduiDashboardScreenState, _SduiDashboardScreenState.build, _SduiCodeEditorState.build, SandboxController.build, get_client, DiagnosticsHistoryNotifier.build, _SduiChartState.build, SduiTimePicker.build, _CoPilotBubbleState.build, _JoshCoPilotPanelState.build, _TitleEditorState.build, _DiaryEditorContent.build, ChatPanelOpenNotifier.build, DiaryEditorScreen.build, SduiListView.build, SduiGauge.build, _SduiTextInputState.build, SduiHeatmap.build, _SduiVideoState.build, SduiProgressBar.build, _SduiSpacerState.build, _ActionChip.build, _TelemetryChip.build, SduiModuleCard.build, SduiProgressBar.build, _SduiSliderState.build, SduiGridView.build, _SduiAudioState.build, SduiToggle.build, _SduiOrdinalSliderState.build, _SduiRadioState.build, _SduiScreenState.build, _SduiRadioState.build, _NetworkConfigCardState.build, SettingsPage.build, _SduiDropdownState.build, SduiChip.build, _SduiJbcPanelState.build, _SduiTextInputState.build, SduiImage.build, ThemeNotifier.build, SduiContainer.build, _SduiWrapState.build, _SduiListEditorState.build, _SduiSliderState.build, SduiIconButton.build, AuthNotifier.build, _DashboardScreenState.build, SduiListView.build, SduiRenderer.build, _SduiTableState.build, SduiSocketManager, _SduiDocumentViewerState.build, _SduiQuoteState.build, ConfigNotifier.build, SduiUnknownNode.build, SduiShuaGridNode.build, SduiRadialGaugeNode.build, SduiDonutChartNode.build, SduiBarChartNode.build, SduiLineChartNode.build, SduiEmptyStateNode.build, SduiErrorStateNode.build, SduiShimmerLoaderNode.build, SduiChipNode.build, SduiProgressBarNode.build, SduiSliderNode.build, SduiSwitchNode.build, SduiSpacerNode.build, SduiDividerNode.build, SduiTextFieldNode.build, SduiButtonNode.build, SduiIconNode.build, SduiCardNode, SduiCardNode.build, SduiColumnNode, SduiColumnNode.build, SduiRowNode, SduiRowNode.build, SduiContainerNode, SduiContainerNode.build, SduiTextNode.build, SduiNode, _SduiCarouselState.build, _SduiShimmerLoaderState.build, _SduiCheckboxState.build, _SduiMapState.build, _FilterChip.build, _SuccessRateBadge.build, _TerminalLineState.build, _SduiTerminalState.build, _SduiTimelineState.build, SduiButton.build, _SduiMarkdownEditorState.build, SduiGridView.build, _PinEntryScreenState.build
```

#### dispose (Function)
```rust
// Lines 60-60 (1 LOC | Complexity 1) | used by 86 callers | [Pure, TraitMethod, Tested, CorePrimitive]
void dispose()
//  â³ Called by: _SduiCodeEditorState.dispose, _SduiCodeEditorState, _SduiTableState, _SduiTableState.dispose, _SduiListEditorState.dispose, _SduiListEditorState, _ListItem, _ListItem.dispose, _SduiContainerState, _SduiContainerState.dispose, _SduiMarkdownEditorState, _SduiMarkdownEditorState.dispose, _JoshAutomatedGenerationDialogState, _JoshAutomatedGenerationDialogState.dispose, _DiaryListScreenState, _DiaryListScreenState.dispose, _SduiCheckboxState, _SduiCheckboxState.dispose, _SduiExpansionTileState, _SduiExpansionTileState.dispose, _SduiHtmlViewerState, _SduiHtmlViewerState.dispose, _SduiHeadingState, _SduiHeadingState.dispose, _SduiShimmerLoaderState, _SduiShimmerLoaderState.dispose, _SduiDashboardScreenState, _SduiDashboardScreenState.dispose, _SduiCodeEditorState.dispose, _SduiCodeEditorState, _SduiChartState, _SduiChartState.dispose, _CoPilotBubbleState, _CoPilotBubbleState.dispose, _JoshCoPilotPanelState, _JoshCoPilotPanelState.dispose, _TitleEditorState, _TitleEditorState.dispose, _SduiTextInputState, _SduiTextInputState.dispose, SduiSandboxScreen, MediaUploader, _SduiVideoState, _SduiVideoState.dispose, _SduiAudioState, _SduiAudioState.dispose, _SduiRadioState, _SduiRadioState.dispose, _SduiScreenState, _SduiScreenState.dispose, _SduiRadioState, _SduiRadioState.dispose, _NetworkConfigCardState, _NetworkConfigCardState.dispose, _SduiDropdownState, _SduiDropdownState.dispose, _SduiJbcPanelState, _SduiJbcPanelState.dispose, _SduiTextInputState, _SduiTextInputState.dispose, _SduiListEditorState.dispose, _SduiListEditorState, _ListItem, _ListItem.dispose, _SduiTableState, _SduiTableState.dispose, _SduiDocumentViewerState, _SduiDocumentViewerState.dispose, _SduiQuoteState, _SduiQuoteState.dispose, _SduiCarouselState, _SduiCarouselState.dispose, _SduiShimmerLoaderState, _SduiShimmerLoaderState.dispose, _SduiCheckboxState, _SduiCheckboxState.dispose, _SduiMapState, _SduiMapState.dispose, _SduiTerminalState, _SduiTerminalState.dispose, _SduiTimelineState, _SduiTimelineState.dispose, _SduiMarkdownEditorState, _SduiMarkdownEditorState.dispose, _PinEntryScreenState, _PinEntryScreenState.dispose
```

#### SduiSandboxScreen (Class)
```rust
// Lines 38-43 (6 LOC | Complexity 1) | used by 4 callers
class SduiSandboxScreen extends ConsumerStatefulWidget
//  â³ Calls: _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState.shimmerType, generate, SduiIconRegistry.contains, _resolveBlueprintNode, _generateMockAst, err, LogEntry::from, _buildLegacyNativeBlock, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, convert, ShuaDiaryBlocks.metadata, _resolveBlueprint, ShuaDiaryBlocks.sortKey, DiaryBlock, ShuaDiaryBlocks.blockType, BoundedRouteHistory.isEmpty, ShuaDiaryEntries.title, SandboxController.initBlock, ShuaDiaryBlocks.content, SduiFlexContext.of, SandboxController.updateMetadata, SandboxController.updateContent, dispose, SduiEventDispatcher.unregisterGlobalListener, _handleSduiEvent, SduiEventDispatcher.registerGlobalListener, SduiEventDispatcher, _initBlock, _loadBlueprints, initState, _SduiSandboxScreenState
//  â³ Called by: _SduiSandboxScreenState, SduiSandboxScreen.createState, SduiSandboxScreen.createState, SduiSandboxScreen
```

#### _resolveBlueprint (Function)
```rust
// Lines 468-468 (1 LOC | Complexity 1) | used by 1 callers | [Io]
Map<int, dynamic> _resolveBlueprint(String type, String id, String content, String? metadataJson)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: SduiSandboxScreen
```

#### initState (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 87 callers | [Pure, TraitMethod, CorePrimitive]
void initState()
//  â³ Called by: _SduiCodeEditorState, _SduiCodeEditorState.initState, _SduiChipState, _SduiChipState.initState, _SduiTableState, _SduiTableState.initState, _SduiListEditorState, _SduiListEditorState.initState, _SduiContainerState, _SduiContainerState.initState, _SduiMarkdownEditorState, _SduiMarkdownEditorState.initState, _SduiToggleState, _SduiToggleState.initState, _JoshAutomatedGenerationDialogState, _JoshAutomatedGenerationDialogState.initState, _DiaryListScreenState, _DiaryListScreenState.initState, _SduiCheckboxState, _SduiCheckboxState.initState, _SduiSandboxScreenState, _SduiSandboxScreenState.initState, _SduiExpansionTileState, _SduiExpansionTileState.initState, _SduiHtmlViewerState, _SduiHtmlViewerState.initState, _SduiHeadingState, _SduiHeadingState.initState, _SduiShimmerLoaderState, _SduiShimmerLoaderState.initState, _SduiDashboardScreenState, _SduiDashboardScreenState.initState, _SduiCodeEditorState, _SduiCodeEditorState.initState, _SduiChartState, _SduiChartState.initState, _CoPilotBubbleState, _CoPilotBubbleState.initState, _TitleEditorState, _TitleEditorState.initState, _SduiTextInputState, _SduiTextInputState.initState, SduiSandboxScreen, _SduiVideoState, _SduiVideoState.initState, _SduiAudioState, _SduiAudioState.initState, _SduiOrdinalSliderState, _SduiOrdinalSliderState.initState, _SduiRadioState, _SduiRadioState.initState, _SduiScreenState, _SduiScreenState.initState, _SduiRadioState, _SduiRadioState.initState, _NetworkConfigCardState, _NetworkConfigCardState.initState, _SduiDropdownState, _SduiDropdownState.initState, _SduiJbcPanelState, _SduiJbcPanelState.initState, _SduiTextInputState, _SduiTextInputState.initState, _SduiListEditorState, _SduiListEditorState.initState, _SduiSliderState, _SduiSliderState.initState, _DashboardScreenState, _DashboardScreenState.initState, _SduiTableState, _SduiTableState.initState, _SduiQuoteState, _SduiQuoteState.initState, _SduiCarouselState, _SduiCarouselState.initState, _SduiShimmerLoaderState, _SduiShimmerLoaderState.initState, _SduiCheckboxState, _SduiCheckboxState.initState, _SduiMapState, _SduiMapState.initState, _SduiTimelineState, _SduiTimelineState.initState, _SduiMarkdownEditorState, _SduiMarkdownEditorState.initState, _PinEntryScreenState, _PinEntryScreenState.initState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\graph\store.rs (137 lines)

#### Visibility (Enum)
```rust
// Lines 21-24 (4 LOC | Complexity 1) | used by 1 callers
pub enum Visibility
//  â³ Called by: SymbolNode
```

#### SymbolKind (Enum)
```rust
// Lines 10-18 (9 LOC | Complexity 1) | used by 1 callers
pub enum SymbolKind
//  â³ Called by: SymbolNode
```

#### SymbolNode (Struct)
```rust
// Lines 63-80 (18 LOC | Complexity 1) | used by 10 callers
pub struct SymbolNode
//  â³ Calls: Language, SymbolTag, Visibility, SymbolKind
//  â³ Called by: AppState::upsert_file_symbols, AppState, TypeScriptExtractor::extract, build_symbol_indices, PythonExtractor::extract, GoExtractor::extract, DeclarationExtractor, extract_declarations, RustExtractor::extract, DartExtractor::extract
```

#### DependencyEdge (Struct)
```rust
// Lines 83-86 (4 LOC | Complexity 1) | used by 5 callers
pub struct DependencyEdge
//  â³ Calls: DependencyType
//  â³ Called by: AppState::upsert_file_symbols, AppState, resolve_type_ref_edges, resolve_call_edges, build_symbol_indices
```

#### SymbolTag (Enum)
```rust
// Lines 35-51 (17 LOC | Complexity 1) | used by 2 callers
pub enum SymbolTag
//  â³ Called by: SymbolNode, infer_side_effects
```

#### DependencyType (Enum)
```rust
// Lines 27-32 (6 LOC | Complexity 1) | used by 1 callers
pub enum DependencyType
//  â³ Called by: DependencyEdge
```

#### AppState::new (Function)
```rust
// Lines 105-112 (8 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
pub fn new() -> Self
//  â³ Called by: AppState::upsert_file_symbols, main, test_regression_hardening
```

#### AppState::upsert_file_symbols (Function)
```rust
// Lines 116-167 (52 LOC | Complexity 9) | used by 1 callers | [MutatesState, CanPanic, TraitMethod]
pub fn upsert_file_symbols(
//  â³ Calls: DependencyEdge, SymbolNode, RadixTrie.insert, AppState::new, RadixTrie.remove
//  â³ Called by: parse_and_index_file
```

#### Language (Enum)
```rust
// Lines 54-60 (7 LOC | Complexity 1) | used by 13 callers | [CorePrimitive]
pub enum Language
//  â³ Called by: SymbolNode, extract_type_references, extract_call_sites, extract_imports, resolve_import, get_parser, get_tree_sitter_language, detect_language, infer_side_effects, walk, compute_cyclomatic_complexity, extract_declarations, extract_file_summary
```

#### FileMetadata (Struct)
```rust
// Lines 89-94 (6 LOC | Complexity 1) | used by 2 callers
pub struct FileMetadata
//  â³ Called by: AppState, parse_and_index_file
```

#### AppState (Struct)
```rust
// Lines 97-102 (6 LOC | Complexity 1) | used by 0 callers
pub struct AppState
//  â³ Calls: FileMetadata, DependencyEdge, SymbolNode, AppState
```

### C:\horAIzon_2.0\client_flutter\lib\app\db\local_db.dart (118 lines)

#### ShuaSyncQueue.recordId (Function)
```rust
// Lines 15-15 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
TextColumn get recordId
```

#### ShuaSyncQueue.id (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 9 callers | [Pure]
IntColumn get id
//  â³ Called by: ShuaDiaryBlocks.primaryKey, ShuaDiaryBlocks.id, ShuaDiaryEntries.primaryKey, ShuaDiaryEntries.id, EpisodicMemories.primaryKey, EpisodicMemories.id, SduiActionHandler._searchDiary, DiarySearchService.reconcile, SduiScreenAssembler._assembleDiaryList
```

#### ShuaDiaryEntries.lamportClock (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IntColumn get lamportClock
//  â³ Called by: ShuaDiaryBlocks.lamportClock
```

#### ShuaDiaryEntries.analysisState (Function)
```rust
// Lines 46-46 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get analysisState
//  â³ Called by: LocalDatabase
```

#### LocalDatabase.migration (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
MigrationStrategy get migration
```

#### ShuaDiaryBlocks.id (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryEntries.title (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 47 callers | [Pure, Tested, CorePrimitive]
TextColumn get title
//  â³ Called by: OCRReviewerApp.load_model_and_data, OCRReviewerApp.__init__, _show_crop_gui, cmd_add_entry, _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, _DiaryListScreenState, SduiRegistry, _SduiSandboxScreenState, HorAIzonClientShell, _SduiExpansionTileState, DiaryRepository._mapEntry, SduiActionHandler._saveTitle, _SduiHtmlViewerState, AnomalyInspector.__init__, _show_crop_gui, _SduiChartState, _JoshCoPilotPanelState, _TitleEditorState, _DiaryEditorContent, _DiaryEditorContent._triggerSync, SduiGauge, SduiSandboxScreen, MediaUploader, uuid, main, _SduiVideoState, _SduiAudioState, SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryList, SduiIconRegistry, _SduiScreenState, SettingsPage, _show_crop_gui, compress, extract_h1_title, _DashboardScreenState, _SduiTableState, SduiTable, _SduiDocumentViewerState, main, SduiDonutChartNode, SduiBarChartNode, SduiLineChartNode, generate_dart, SduiTimelineEvent, _SduiTimelineState
```

#### ShuaDiaryEntries.id (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â³ Calls: ShuaSyncQueue.id
```

#### ShuaSyncQueue.payload (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 30 callers | [Pure, Tested, CorePrimitive]
BlobColumn get payload
//  â³ Called by: GovernorLogger._sendAsync, GovernorLogger, SduiOrchestrator.sendReplacePayload, _SduiTableState, _SduiTableState._parseContent, _SduiCheckboxState, _SduiDividerState, _SduiExpansionTileState, SduiActionHandler._getMonthlySynthesis, SduiActionHandler._getBlocks, SduiActionHandler._createEntry, SduiActionHandler._searchDiary, SduiActionHandler._deleteEntry, SduiActionHandler._createBlock, SduiActionHandler._saveTitle, _SduiDashboardScreenState, MessagePackCodec, MessagePackCodec.encode, _SduiSpacerState, ApiClient, ApiClient.postBinary, _SduiRadioState, _SduiDropdownState, SduiEventDispatcher._handleSubmitForm, SduiEventDispatcher._fireRpc, SduiEventDispatcher._handleAiCommand, SduiEventDispatcher, SduiEventDispatcher.onAction, SduiIconButton, SduiButton
```

#### ShuaDiaryBlocks.content (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 61 callers | [Pure, Tested, CorePrimitive]
TextColumn get content
//  â³ Called by: SduiButton, SduiNode, _SduiListEditorState, _SduiListEditorState._loadFromContent, _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, _DiaryListScreenState, SduiRegistry._buildProgressBar, SduiRegistry._buildButton, SduiRegistry._buildIcon, SduiRegistry._buildRadio, SduiRegistry._buildCheckbox, SduiRegistry._buildCodeEditor, SduiRegistry._buildQuote, SduiRegistry._buildHeading, SduiRegistry._buildMarkdownEditor, SduiRegistry._buildTextInput, SduiRegistry._buildIconButton, SduiRegistry._buildChip, SduiRegistry._buildToggle, SduiRegistry._buildSlider, SduiRegistry._buildTable, SduiRegistry._buildListEditor, SduiRegistry._buildOrdinalSlider, SduiRegistry, _SduiSandboxScreenState, OllamaAssistantProvider.chatStream, DiaryRepository.getBlockSearchDetails, DiaryRepository._mapBlock, _SduiHtmlViewerState, GeminiJbcProvider.presentJbcStream, SandboxController, _CoPilotBubbleState, _JoshCoPilotPanelState, _DiaryEditorContent, _generateMockAst, _resolveBlueprintNode, _resolveBlueprint, SduiSandboxScreen, MediaUploader, _SduiVideoState, SemanticSearchHandler.handle, SduiModuleCard, SduiTransport, OllamaJbcProvider.presentJbcStream, _SduiAudioState, _SduiScreenState, _NetworkConfigCardState, flushBlock, _SduiJbcPanelState, SduiEventDispatcher, _SduiListEditorState, _SduiListEditorState._loadFromContent, GeminiAssistantProvider.chatStream, SduiComposer.composeBlock, flushBlock, _SduiDocumentViewerState, _SduiMapState, _SduiTerminalState, _SduiMarkdownEditorState, _SduiMarkdownEditorState._buildReadonlyView
```

#### EpisodicMemories.suggestedTags (Function)
```rust
// Lines 30-30 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get suggestedTags
```

#### ShuaSyncQueue.tableId (Function)
```rust
// Lines 14-14 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
IntColumn get tableId
```

#### ShuaSyncQueue.actionType (Function)
```rust
// Lines 16-16 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
IntColumn get actionType
//  â³ Called by: _SduiContainerState
```

#### ShuaDiaryEntries.sentimentScore (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 8 callers | [Pure]
RealColumn get sentimentScore
//  â³ Called by: OllamaAnalyzerProvider.analyze, LocalDatabase, GeminiAnalyzerProvider.analyze, _DiaryEditorContent, AnalysisWorker._processNext, GeminiAnalyzerProvider.analyze, OllamaAnalyzerProvider.analyze, AnalysisWorker._processNext
```

#### EpisodicMemories.moodTag (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get moodTag
//  â³ Called by: _DiaryEditorContent
```

#### EpisodicMemories (Class)
```rust
// Lines 23-34 (12 LOC | Complexity 1) | used by 1 callers
class EpisodicMemories extends Table
//  â³ Called by: LocalDatabase
```

#### EpisodicMemories.userId (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
TextColumn get userId
//  â³ Called by: _DiaryEditorContent, SduiScreenAssembler._assembleDiaryAiPromptModal, SduiScreenAssembler._assembleDiaryList
```

#### ShuaDiaryBlocks.sortKey (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
BlobColumn get sortKey
//  â³ Called by: SandboxController, SduiSandboxScreen
```

#### ShuaDiaryBlocks.blockType (Function)
```rust
// Lines 58-58 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
TextColumn get blockType
//  â³ Called by: SandboxController, SduiSandboxScreen, SemanticSearchHandler.handle, SduiScreenAssembler._assembleDiaryBlockPicker, _SduiJbcPanelState
```

#### ShuaDiaryBlocks.primaryKey (Function)
```rust
// Lines 65-65 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Set<Column> get primaryKey
//  â³ Calls: ShuaSyncQueue.id, EpisodicMemories.primaryKey
```

#### EpisodicMemories.createdAt (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DateTimeColumn get createdAt
//  â³ Calls: ShuaSyncQueue.createdAt
```

#### EpisodicMemories.priorityTier (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IntColumn get priorityTier
//  â³ Called by: _DiaryEditorContent
```

#### ShuaSyncQueue.createdAt (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
IntColumn get createdAt
//  â³ Called by: ShuaDiaryEntries.createdAt, EpisodicMemories.createdAt, SduiScreenAssembler._assembleDiaryList
```

#### ShuaSyncQueue (Class)
```rust
// Lines 12-20 (9 LOC | Complexity 1) | used by 1 callers
class ShuaSyncQueue extends Table
//  â³ Calls: LocalDatabase
//  â³ Called by: LocalDatabase
```

#### ShuaSyncQueue.logicalClock (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
IntColumn get logicalClock
```

#### LocalDatabase.schemaVersion (Function)
```rust
// Lines 74-74 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
int get schemaVersion
```

#### ShuaDiaryBlocks (Class)
```rust
// Lines 55-66 (12 LOC | Complexity 1) | used by 1 callers
class ShuaDiaryBlocks extends Table
//  â³ Called by: LocalDatabase
```

#### ShuaDiaryBlocks.entryId (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 14 callers | [Pure, Tested, CorePrimitive]
TextColumn get entryId
//  â³ Called by: SandboxController, _JoshCoPilotPanelState, _DiaryEditorContent, _DiaryEditorContent._triggerSync, DiaryEditorScreen, uuid, SemanticSearchHandler.handle, SduiScreenAssembler._assembleDiaryOptionsModal, SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, _SduiScreenState, _SduiJbcPanelState, SduiJbcPanel, SduiEventDispatcher
```

#### ShuaDiaryEntries.primaryKey (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Set<Column> get primaryKey
//  â³ Calls: ShuaSyncQueue.id, EpisodicMemories.primaryKey
```

#### ShuaDiaryBlocks.lamportClock (Function)
```rust
// Lines 62-62 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
IntColumn get lamportClock
//  â³ Calls: ShuaDiaryEntries.lamportClock
```

#### ShuaDiaryEntries (Class)
```rust
// Lines 37-52 (16 LOC | Complexity 1) | used by 1 callers
class ShuaDiaryEntries extends Table
//  â³ Called by: LocalDatabase
```

#### LocalDatabase (Class)
```rust
// Lines 69-103 (35 LOC | Complexity 1) | used by 1 callers
@DriftDatabase(tables: [ShuaSyncQueue, EpisodicMemories, ShuaDiaryEntries, ShuaDiaryBlocks])
//  â³ Calls: ShuaDiaryBlocks.metadata, ShuaDiaryEntries.milestoneTag, ShuaDiaryEntries.sentimentScore, ShuaDiaryEntries.analysisState, ShuaDiaryEntries.privacyTag, LogEntry::from, ShuaDiaryBlocks, ShuaDiaryEntries, EpisodicMemories, ShuaSyncQueue
//  â³ Called by: ShuaSyncQueue
```

#### ShuaDiaryEntries.privacyTag (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
TextColumn get privacyTag
//  â³ Called by: _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, LocalDatabase, _DiaryEditorContent, AnalysisWorker._processNext
```

#### ShuaDiaryEntries.milestoneTag (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
TextColumn get milestoneTag
//  â³ Called by: OllamaAnalyzerProvider.analyze, LocalDatabase, GeminiAnalyzerProvider.analyze, _DiaryEditorContent, AnalysisWorker._processNext
```

#### EpisodicMemories.memoryContent (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get memoryContent
//  â³ Called by: _DiaryEditorContent
```

#### ShuaDiaryEntries.createdAt (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DateTimeColumn get createdAt
//  â³ Calls: ShuaSyncQueue.createdAt
```

#### EpisodicMemories.id (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryBlocks.metadata (Function)
```rust
// Lines 60-60 (1 LOC | Complexity 1) | used by 10 callers | [Pure, Tested]
TextColumn get metadata
//  â³ Called by: _JoshAutomatedGenerationDialogState, LocalDatabase, OllamaAssistantProvider.generateTemplate, handle_get, SandboxController, SduiSandboxScreen, HbpLoggerLayer::on_event, run_garbage_collection, serve_file, ChannelLogger::on_event
```

#### EpisodicMemories.primaryKey (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Set<Column> get primaryKey
//  â³ Calls: ShuaSyncQueue.id
//  â³ Called by: ShuaDiaryBlocks.primaryKey, ShuaDiaryEntries.primaryKey
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\main.rs (65 lines)

#### main (Function)
```rust
// Lines 25-89 (65 LOC | Complexity 4) | used by 0 callers | [EntryPoint, Async, CanPanic]
async fn main()
//  â³ Calls: run_full_scan, LogEntry::from, AppState::new, init, HbpLoggerLayer::new
```

### C:\horAIzon_2.0\scripts\ai_training\visualizer.py (127 lines)

#### power_decay (Function)
```rust
// Lines 80-82 (3 LOC | Complexity 1) | used by 1 callers | [Pure, Cycle]
def power_decay(x, a, b, c)
//  â³ Calls: plot
//  â³ Called by: fit_and_predict
```

#### plot (Function)
```rust
// Lines 119-214 (96 LOC | Complexity 6) | used by 5 callers | [Io, Cycle, Tested]
def plot(observed_log, total_steps)
//  â³ Calls: fit_and_predict
//  â³ Called by: MobileEdgeEngine.process_image, power_decay, generate_graphs, MeterVisionEngine.process_image, main
```

#### fit_and_predict (Function)
```rust
// Lines 85-112 (28 LOC | Complexity 2) | used by 1 callers | [Io, Cycle]
def fit_and_predict(steps, losses, predict_up_to)
//  â³ Calls: power_decay
//  â³ Called by: plot
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\core\engine.py (235 lines)

#### MobileEdgeEngine.get_model (Function)
```rust
// Lines 48-55 (8 LOC | Complexity 3) | used by 2 callers | [CanPanic]
def get_model(weights_path=None)
//  â³ Calls: find_latest_weights
//  â³ Called by: StandaloneWebAppHandler.get_model, MobileEdgeBackend.__init__
```

#### find_latest_weights (Function)
```rust
// Lines 28-43 (16 LOC | Complexity 6) | used by 7 callers | [Pure, Tested]
def find_latest_weights()
//  â³ Calls: walk, RadixTrie.insert
//  â³ Called by: collect, MobileEdgeEngine.get_model, YOLOMeterBackend.__init__, collect, StandaloneWebAppHandler.get_model, main, evaluate_best_model
```

#### MobileEdgeEngine.process_image (Function)
```rust
// Lines 58-156 (99 LOC | Complexity 12) | used by 1 callers | [MutatesState, CanPanic]
def process_image(model, image_bytes, conf_threshold=0.25)
//  â³ Calls: ctc_greedy_decode, load_ocr_model, plot
//  â³ Called by: StandaloneWebAppHandler.do_POST
```

#### MobileEdgeEngine (Class)
```rust
// Lines 45-156 (112 LOC | Complexity 1) | used by 0 callers
class MobileEdgeEngine
```

### C:\horAIzon_2.0\shua_governor\src\routes\media.rs (712 lines)

#### is_loopback (Function)
```rust
// Lines 68-81 (14 LOC | Complexity 1) | used by 2 callers | [Pure]
fn is_loopback(headers: &HeaderMap) -> bool
//  â³ Calls: ok
//  â³ Called by: dav_handler, verify_auth
```

#### chunk_receive (Function)
```rust
// Lines 459-508 (50 LOC | Complexity 6) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn chunk_receive(
//  â³ Calls: ProgressEvent, AppState, ok, verify_auth
```

#### chunk_init (Function)
```rust
// Lines 358-452 (95 LOC | Complexity 4) | used by 0 callers | [Async, Io, ApiRoute]
pub async fn chunk_init(
//  â³ Calls: UploadState, ProgressEvent, ChunkInitRequest, AppState, RadixTrie.insert, ok, collect, filter, verify_auth
```

#### ChunkInitRequest (Struct)
```rust
// Lines 352-356 (5 LOC | Complexity 1) | used by 1 callers
pub struct ChunkInitRequest
//  â³ Called by: chunk_init
```

#### ProgressEvent (Struct)
```rust
// Lines 34-39 (6 LOC | Complexity 1) | used by 4 callers
pub struct ProgressEvent
//  â³ Called by: chunk_finalize, chunk_receive, chunk_init, UploadState
```

#### verify_auth (Function)
```rust
// Lines 84-96 (13 LOC | Complexity 4) | used by 5 callers | [Pure]
fn verify_auth(headers: &HeaderMap) -> Result<(), Response>
//  â³ Calls: Response, is_loopback
//  â³ Called by: media_stats, chunk_finalize, chunk_receive, chunk_init, upload_file
```

#### process_upload_bytes (Function)
```rust
// Lines 110-267 (158 LOC | Complexity 22) | used by 3 callers | [Async, MutatesState, Io, HighComplexity]
pub async fn process_upload_bytes(
//  â³ Calls: ok, DiaryAiSession.create, SduiBlockRegistry.load, is_allowed_mime
//  â³ Called by: handle_put, chunk_finalize, upload_file
```

#### upload_progress_sse (Function)
```rust
// Lines 654-680 (27 LOC | Complexity 3) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn upload_progress_sse(
//  â³ Calls: GcGuard::drop
```

#### UploadState (Struct)
```rust
// Lines 41-45 (5 LOC | Complexity 1) | used by 1 callers
struct UploadState
//  â³ Calls: ProgressEvent
//  â³ Called by: chunk_init
```

#### media_stats (Function)
```rust
// Lines 803-818 (16 LOC | Complexity 2) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn media_stats(
//  â³ Calls: AppState, verify_auth
```

#### chunk_finalize (Function)
```rust
// Lines 515-648 (134 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, ApiRoute]
pub async fn chunk_finalize(
//  â³ Calls: ProgressEvent, Error, AppState, RadixTrie.remove, process_upload_bytes, ok, verify_auth
```

#### ThumbnailQuery (Struct)
```rust
// Lines 688-690 (3 LOC | Complexity 1) | used by 1 callers
pub struct ThumbnailQuery
//  â³ Called by: serve_file
```

#### is_allowed_mime (Function)
```rust
// Lines 55-62 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
fn is_allowed_mime(mime: &str) -> bool
//  â³ Called by: process_upload_bytes
```

#### upload_file (Function)
```rust
// Lines 273-344 (72 LOC | Complexity 12) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn upload_file(
//  â³ Calls: AppState, process_upload_bytes, verify_auth
```

#### serve_file (Function)
```rust
// Lines 692-797 (106 LOC | Complexity 12) | used by 0 callers | [Async, MutatesState, Io, CanPanic, ApiRoute]
pub async fn serve_file(
//  â³ Calls: ThumbnailQuery, AppState, LogEntry::from, RadixTrie.insert, collect, ok, ShuaDiaryBlocks.metadata
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\registry\sdui_icon_registry.dart (126 lines)

#### SduiIconRegistry.resolve (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static IconData resolve(String? name)
```

#### SduiIconRegistry.contains (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 36 callers | [Pure, Tested, CorePrimitive]
static bool contains(String name)
//  â³ Called by: compute_subgraph, _SduiListEditorState, _DiaryListScreenState, serialize, SduiRegistry, SduiDatePicker, _SduiHtmlViewerState, serialize, resolve_type_ref_edges, resolve_call_edges, _SduiHeadingState, SduiTimePicker, extract_api_routes, _CoPilotBubbleState, serialize, _SduiTextInputState, SduiSandboxScreen, _SduiDropdownState, SduiContainer, assign_tags, detect_test_linkages, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, detect_cycles, SduiEventDispatcher, GoExtractor::extract, infer_side_effects, _SduiListEditorState, run_garbage_collection, SduiSocketManager, ChannelLogger::enabled, get_console, get_dashboard, get_preactivation_sheet
```

#### SduiIconRegistry (Class)
```rust
// Lines 10-133 (124 LOC | Complexity 1) | used by 0 callers
class SduiIconRegistry
//  â³ Calls: ShuaDiaryEntries.title, DiaryRepository.close, SduiIconRegistry
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\db\db.go (132 lines)

#### seedDatabase (Function)
```rust
// Lines 88-154 (67 LOC | Complexity 12) | used by 1 callers | [MutatesState, Io]
func seedDatabase() error
//  â³ Calls: Info
//  â³ Called by: InitDB
```

#### InitDB (Function)
```rust
// Lines 21-52 (32 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io]
func InitDB(dbPath string) error
//  â³ Calls: Info, seedDatabase, runMigrations
//  â³ Called by: main
```

#### runMigrations (Function)
```rust
// Lines 54-86 (33 LOC | Complexity 3) | used by 1 callers | [Pure]
func runMigrations() error
//  â³ Called by: InitDB
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_expansion_tile.dart (364 lines)

#### SduiExpansionTile (Class)
```rust
// Lines 12-24 (13 LOC | Complexity 1) | used by 4 callers
class SduiExpansionTile extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiExpansionTileState.didUpdateWidget, _SduiExpansionTileState, SduiExpansionTile.createState, SduiTypeRegistry
```

#### _SduiExpansionTileState.initState (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiExpansionTileState.didUpdateWidget (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiExpansionTile oldWidget)
//  â³ Calls: SduiExpansionTile
//  â³ Called by: _SduiExpansionTileState
```

#### _SduiExpansionTileState.dispose (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiExpansionTileState.build (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiExpansionTileState (Class)
```rust
// Lines 26-371 (346 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiExpansionTileState extends ConsumerState<SduiExpansionTile>
//  â³ Calls: SduiExpansionTile, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiEventDispatcher.onStateChange, ShuaSyncQueue.payload, BoundedRouteHistory.isEmpty, SduiRenderer, _SduiShimmerLoaderState.padding, SduiIconRegistry, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, dispose, _SduiExpansionTileState.didUpdateWidget, SduiNode.contentVal, ShuaDiaryEntries.title, SduiNode.behavior, initState
//  â³ Called by: SduiExpansionTile.createState
```

#### SduiExpansionTile.createState (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiExpansionTile> createState()
//  â³ Calls: SduiExpansionTile, _SduiExpansionTileState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\scanner.rs (258 lines)

#### extract_file_summary (Function)
```rust
// Lines 174-267 (94 LOC | Complexity 30) | used by 1 callers | [MutatesState, HighComplexity]
fn extract_file_summary(source: &[u8], lang: Language) -> String
//  â³ Calls: Language, filter
//  â³ Called by: parse_and_index_file
```

#### run_full_scan (Function)
```rust
// Lines 8-119 (112 LOC | Complexity 8) | used by 2 callers | [MutatesState, CanPanic]
pub fn run_full_scan(root: &Path, state: &AppState)
//  â³ Calls: AppState, assign_tags, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, detect_cycles, extract_api_routes, compute_centrality, resolve_edges, parse_and_index_file, log_verbose, log_status, SduiBlockRegistry.load, detect_language
//  â³ Called by: main, trigger_scan
```

#### parse_and_index_file (Function)
```rust
// Lines 121-172 (52 LOC | Complexity 7) | used by 2 callers | [MutatesState, Io, CanPanic]
pub fn parse_and_index_file(file_path: &Path, state: &AppState)
//  â³ Calls: FileMetadata, AppState, AppState::upsert_file_symbols, RadixTrie.insert, extract_file_summary, collect, extract_type_references, extract_call_sites, extract_imports, extract_declarations, detect_language
//  â³ Called by: test_regression_hardening, run_full_scan
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\check_dataset.py (328 lines)

#### AnomalyInspector.next_image (Function)
```rust
// Lines 182-185 (4 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def next_image(self)
//  â³ Calls: AnomalyInspector.show_current
```

#### AnomalyInspector (Class)
```rust
// Lines 22-190 (169 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class AnomalyInspector
//  â³ Calls: AnomalyInspector.show_current
```

#### AnomalyInspector.load_data (Function)
```rust
// Lines 67-78 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
def load_data(self)
//  â³ Calls: AnomalyInspector.refresh_indices
//  â³ Called by: AnomalyInspector.__init__
```

#### AnomalyInspector.setup_ui (Function)
```rust
// Lines 36-65 (30 LOC | Complexity 1) | used by 1 callers | [MutatesState]
def setup_ui(self)
//  â³ Called by: AnomalyInspector.__init__
```

#### AnomalyInspector.resolve_current (Function)
```rust
// Lines 167-180 (14 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def resolve_current(self)
//  â³ Calls: AnomalyInspector.show_current, AnomalyInspector.save_csv
```

#### AnomalyInspector.save_csv (Function)
```rust
// Lines 83-87 (5 LOC | Complexity 1) | used by 1 callers | [MutatesState]
def save_csv(self)
//  â³ Called by: AnomalyInspector.resolve_current
```

#### AnomalyInspector.refresh_indices (Function)
```rust
// Lines 80-81 (2 LOC | Complexity 1) | used by 1 callers | [MutatesState]
def refresh_indices(self)
//  â³ Called by: AnomalyInspector.load_data
```

#### AnomalyInspector.prev_image (Function)
```rust
// Lines 187-190 (4 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def prev_image(self)
//  â³ Calls: AnomalyInspector.show_current
```

#### AnomalyInspector.draw_yolo_boxes (Function)
```rust
// Lines 89-124 (36 LOC | Complexity 5) | used by 1 callers | [Pure]
def draw_yolo_boxes(self, img_path, txt_path)
//  â³ Called by: AnomalyInspector.show_current
```

#### AnomalyInspector.__init__ (Function)
```rust
// Lines 23-34 (12 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self, root)
//  â³ Calls: AnomalyInspector.show_current, AnomalyInspector.load_data, AnomalyInspector.setup_ui, ShuaDiaryEntries.title
```

#### AnomalyInspector.show_current (Function)
```rust
// Lines 126-165 (40 LOC | Complexity 6) | used by 5 callers | [MutatesState]
def show_current(self)
//  â³ Calls: AnomalyInspector.draw_yolo_boxes
//  â³ Called by: AnomalyInspector, AnomalyInspector.prev_image, AnomalyInspector.next_image, AnomalyInspector.resolve_current, AnomalyInspector.__init__
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\messagepack_codec.dart (13 lines)

#### MessagePackCodec.encode (Function)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 34 callers | [Pure, Tested, CorePrimitive]
static Uint8List encode(dynamic payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: ChatHandler.handle, SduiOrchestrator.sendReplacePayload, SduiOrchestrator.handleRpc, SduiOrchestrator.setupHotReloadWatcher, OllamaAssistantProvider.start, OllamaAssistantProvider.chatStream, SduiActionHandler._getMonthlySynthesis, SduiActionHandler._getBlocks, SduiActionHandler._createEntry, SduiActionHandler._searchDiary, SduiActionHandler._deleteEntry, SduiActionHandler._createBlock, SduiActionHandler._saveTitle, compile_blueprints, GenerateSummaryHandler.handle, GenerateFromNotesHandler.handle, StandaloneWebAppHandler.do_POST, StandaloneWebAppHandler.do_GET, AnalyzeEntryHandler.handle, StandaloneWebAppHandler.do_POST, StandaloneWebAppHandler.do_GET, msgpackMiddleware, log, SemanticSearchHandler.handle, main, SduiDeltaEmitter._emit, ApiClient, GeminiAssistantProvider.pull, GeminiAssistantProvider.start, GeminiAssistantProvider.chatStream, GeminiAssistantProvider.pull, ApplyMutationsHandler.handle, run_ollama_query, SaveAiConfigHandler.handle
```

#### MessagePackCodec.decode (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static dynamic decode(Uint8List bytes)
```

#### MessagePackCodec (Class)
```rust
// Lines 4-14 (11 LOC | Complexity 1) | used by 1 callers
class MessagePackCodec
//  â³ Calls: BorrowedLogEntry::deserialize, ShuaSyncQueue.payload, serialize
//  â³ Called by: ApiClient
```

### C:\horAIzon_2.0\shua_governor\src\governor\media_gc.rs (316 lines)

#### BackupConfig (Struct)
```rust
// Lines 351-355 (5 LOC | Complexity 1) | used by 2 callers
pub struct BackupConfig
//  â³ Called by: test_run_backup_sync_disabled, run_backup_sync
```

#### run_garbage_collection (Function)
```rust
// Lines 211-344 (134 LOC | Complexity 21) | used by 1 callers | [Async, MutatesState, Io, HighComplexity]
pub async fn run_garbage_collection(media_dir: &Path, db: &Arc<Mutex<Connection>>)
//  â³ Calls: ok, ShuaDiaryBlocks.metadata, SduiIconRegistry.contains, RadixTrie.insert
//  â³ Called by: start_gc_loop
```

#### MediaStats (Struct)
```rust
// Lines 43-50 (8 LOC | Complexity 1) | used by 0 callers
pub struct MediaStats
```

#### new_media_stats (Function)
```rust
// Lines 54-56 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
pub fn new_media_stats() -> SharedMediaStats
//  â³ Called by: main
```

#### start_gc_loop (Function)
```rust
// Lines 200-205 (6 LOC | Complexity 2) | used by 1 callers | [Async, Pure]
pub async fn start_gc_loop(media_dir: Arc<PathBuf>, db: Arc<Mutex<Connection>>)
//  â³ Calls: run_garbage_collection
//  â³ Called by: main
```

#### start_subconscious_embedder_loop (Function)
```rust
// Lines 380-388 (9 LOC | Complexity 2) | used by 1 callers | [Async, Pure]
pub async fn start_subconscious_embedder_loop(_db: Arc<Mutex<Connection>>)
//  â³ Called by: main
```

#### GcGuard (Struct)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers
struct GcGuard;
```

#### refresh_disk_stats (Function)
```rust
// Lines 78-193 (116 LOC | Complexity 7) | used by 1 callers | [Async, MutatesState, Io]
async fn refresh_disk_stats(
//  â³ Called by: start_disk_monitor_loop
```

#### start_disk_monitor_loop (Function)
```rust
// Lines 67-76 (10 LOC | Complexity 2) | used by 1 callers | [Async, Pure]
pub async fn start_disk_monitor_loop(
//  â³ Calls: refresh_disk_stats
//  â³ Called by: main
```

#### test_run_backup_sync_disabled (Function)
```rust
// Lines 395-402 (8 LOC | Complexity 1) | used by 0 callers | [Async, Pure]
async fn test_run_backup_sync_disabled()
//  â³ Calls: BackupConfig, run_backup_sync
```

#### run_backup_sync (Function)
```rust
// Lines 360-372 (13 LOC | Complexity 2) | used by 1 callers | [Async, Io]
pub async fn run_backup_sync(config: &BackupConfig, _source_dir: &Path, _db_path: &Path)
//  â³ Calls: BackupConfig
//  â³ Called by: test_run_backup_sync_disabled
```

#### GcGuard::drop (Function)
```rust
// Lines 20-22 (3 LOC | Complexity 1) | used by 2 callers | [TraitMethod, MutatesState]
fn drop(&mut self)
//  â³ Called by: start_supervisor_loop, upload_progress_sse
```

### C:\horAIzon_2.0\sdui3\diary_editor_screen.dart (1609 lines)

#### _JoshCoPilotPanelState.build (Function)
```rust
// Lines 1150-1150 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### ChatPanelOpenNotifier.toggle (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
void toggle()
//  â³ Called by: _DiaryEditorContent, SduiToggle
```

#### _JoshCoPilotPanelState.dispose (Function)
```rust
// Lines 1143-1143 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _DiaryEditorContent (Class)
```rust
// Lines 53-891 (839 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _DiaryEditorContent extends ConsumerWidget
//  â³ Calls: DiaryBlock, _JoshCoPilotPanel, ChannelLogger::enabled, DiaryRepository.reorderBlock, ChatPanelOpenNotifier.toggle, DiaryRepository.deleteEntry, err, _DiaryEditorContent._triggerSync, _DiaryEditorContent._buildSaveStatusIndicator, _TitleEditor, _DiaryEditorContent._formatTime, EpisodicMemories.moodTag, EpisodicMemories.priorityTier, EpisodicMemories.memoryContent, EpisodicMemories.userId, RadixTrie.insert, ShuaDiaryEntries.milestoneTag, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, ShuaDiaryEntries.title, _SduiShimmerLoaderState.borderRadius, ShuaDiaryEntries.sentimentScore, ShuaDiaryEntries.privacyTag, BoundedRouteHistory.isEmpty, DiagnosticResult.success, ShuaDiaryBlocks.entryId, ShuaDiaryBlocks.content, SduiFlexContext.of
//  â³ Called by: DiaryEditorScreen
```

#### _TitleEditorState.dispose (Function)
```rust
// Lines 920-920 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _TitleEditorState.build (Function)
```rust
// Lines 926-926 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _CoPilotBubbleState._extractTemplateContent (Function)
```rust
// Lines 1334-1334 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _extractTemplateContent(String text)
//  â³ Called by: _CoPilotBubbleState
```

#### _TitleEditorState.didUpdateWidget (Function)
```rust
// Lines 911-911 (1 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
void didUpdateWidget(_TitleEditor oldWidget)
//  â³ Calls: _TitleEditor
//  â³ Called by: _CoPilotBubbleState, _CoPilotBubbleState.didUpdateWidget, _TitleEditorState
```

#### _CoPilotBubble.createState (Function)
```rust
// Lines 1278-1278 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_CoPilotBubble> createState()
//  â³ Calls: _CoPilotBubble, _CoPilotBubbleState, _TitleEditor.createState
```

#### ChatPanelOpenNotifier (Class)
```rust
// Lines 36-41 (6 LOC | Complexity 1) | used by 1 callers
class ChatPanelOpenNotifier extends Notifier<bool>
//  â³ Called by: DiaryEditorScreen
```

#### _CoPilotBubble (Class)
```rust
// Lines 1264-1279 (16 LOC | Complexity 1) | used by 4 callers
class _CoPilotBubble extends ConsumerStatefulWidget
//  â³ Called by: _CoPilotBubbleState.didUpdateWidget, _CoPilotBubbleState, _CoPilotBubble.createState, _JoshCoPilotPanelState
```

#### _JoshCoPilotPanelState._executeAiActionIntents (Function)
```rust
// Lines 988-988 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _executeAiActionIntents(String text)
//  â³ Called by: _JoshCoPilotPanelState
```

#### _JoshCoPilotPanelState._sendMessage (Function)
```rust
// Lines 1007-1007 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _sendMessage()
//  â³ Called by: _JoshCoPilotPanelState
```

#### _CoPilotBubbleState.didUpdateWidget (Function)
```rust
// Lines 1303-1303 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void didUpdateWidget(_CoPilotBubble oldWidget)
//  â³ Calls: _CoPilotBubble, _TitleEditorState.didUpdateWidget
```

#### _CoPilotBubbleState._buildJbcTracePill (Function)
```rust
// Lines 1515-1515 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildJbcTracePill(BuildContext context)
//  â³ Called by: _CoPilotBubbleState
```

#### _DiaryEditorContent.build (Function)
```rust
// Lines 278-278 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### _CoPilotBubbleState._classifyMessage (Function)
```rust
// Lines 1316-1316 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
CoPilotBubbleType _classifyMessage(String text)
//  â³ Calls: CoPilotBubbleType
//  â³ Called by: _CoPilotBubbleState
```

#### CoPilotBubbleType (Enum)
```rust
// Lines 47-51 (5 LOC | Complexity 1) | used by 2 callers
enum CoPilotBubbleType
//  â³ Called by: _CoPilotBubbleState._classifyMessage, _CoPilotBubbleState
```

#### _DiaryEditorContent._buildSaveStatusIndicator (Function)
```rust
// Lines 226-226 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildSaveStatusIndicator(BuildContext context, DiaryEditorState state)
//  â³ Called by: _DiaryEditorContent
```

#### DiaryEditorScreen (Class)
```rust
// Lines 23-35 (13 LOC | Complexity 1) | used by 0 callers
class DiaryEditorScreen extends ConsumerWidget
//  â³ Calls: ChatPanelOpenNotifier, _DiaryEditorContent, ShuaDiaryBlocks.entryId
```

#### _JoshCoPilotPanelState._extractJbcTrace (Function)
```rust
// Lines 968-968 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
(String, String) _extractJbcTrace(String text)
//  â³ Called by: _JoshCoPilotPanelState
```

#### _TitleEditor (Class)
```rust
// Lines 893-899 (7 LOC | Complexity 1) | used by 4 callers
class _TitleEditor extends ConsumerStatefulWidget
//  â³ Called by: _TitleEditorState.didUpdateWidget, _TitleEditorState, _TitleEditor.createState, _DiaryEditorContent
```

#### ChatPanelOpenNotifier.build (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool build()
//  â³ Calls: build
```

#### _DiaryEditorContent._formatTime (Function)
```rust
// Lines 219-219 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatTime(DateTime dt)
//  â³ Called by: _DiaryEditorContent
```

#### _CoPilotBubbleState.dispose (Function)
```rust
// Lines 1311-1311 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _TitleEditorState (Class)
```rust
// Lines 901-952 (52 LOC | Complexity 1) | used by 1 callers
class _TitleEditorState extends ConsumerState<_TitleEditor>
//  â³ Calls: _TitleEditor, DiaryRepository.updateEntryTitle, SduiFlexContext.of, dispose, _TitleEditorState.didUpdateWidget, ShuaDiaryEntries.title, initState
//  â³ Called by: _TitleEditor.createState
```

#### _CoPilotBubbleState (Class)
```rust
// Lines 1281-1607 (327 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _CoPilotBubbleState extends ConsumerState<_CoPilotBubble>
//  â³ Calls: _CoPilotBubble, ShuaDiaryBlocks.content, _CoPilotBubbleState._extractTemplateContent, _CoPilotBubbleState._buildJbcTracePill, _CoPilotBubbleState._parseMutationCounts, _CoPilotBubbleState._buildMutationBadge, _CoPilotBubbleState._getCleanDisplayText, _CoPilotBubbleState._classifyMessage, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, BoundedRouteHistory.isEmpty, SduiFlexContext.of, CoPilotBubbleType, SduiIconRegistry.contains, dispose, _TitleEditorState.didUpdateWidget, initState
//  â³ Called by: _CoPilotBubble.createState
```

#### _JoshCoPilotPanel (Class)
```rust
// Lines 954-959 (6 LOC | Complexity 1) | used by 3 callers
class _JoshCoPilotPanel extends ConsumerStatefulWidget
//  â³ Called by: _JoshCoPilotPanelState, _JoshCoPilotPanel.createState, _DiaryEditorContent
```

#### _TitleEditorState.initState (Function)
```rust
// Lines 905-905 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _CoPilotBubbleState.initState (Function)
```rust
// Lines 1287-1287 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _CoPilotBubbleState._getCleanDisplayText (Function)
```rust
// Lines 1326-1326 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getCleanDisplayText(String text)
//  â³ Called by: _CoPilotBubbleState
```

#### DiaryEditorScreen.build (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### _JoshCoPilotPanelState (Class)
```rust
// Lines 961-1262 (302 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _JoshCoPilotPanelState extends ConsumerState<_JoshCoPilotPanel>
//  â³ Calls: DiaryBlock, _JoshCoPilotPanel, _JoshCoPilotPanelState._sendMessage, _SduiShimmerLoaderState.borderRadius, _CoPilotBubble, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, dispose, onError, _JoshCoPilotPanelState._executeAiActionIntents, _JoshCoPilotPanelState._extractJbcTrace, LogEntry::from, _JoshCoPilotPanelState._scrollToBottom, ShuaDiaryEntries.title, ShuaDiaryBlocks.entryId, SduiStateVault.clear, BoundedRouteHistory.isEmpty, ShuaDiaryBlocks.content, SduiFlexContext.of
//  â³ Called by: _JoshCoPilotPanel.createState
```

#### _JoshCoPilotPanel.createState (Function)
```rust
// Lines 958-958 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_JoshCoPilotPanel> createState()
//  â³ Calls: _JoshCoPilotPanel, _JoshCoPilotPanelState, _TitleEditor.createState
```

#### _CoPilotBubbleState._parseMutationCounts (Function)
```rust
// Lines 1339-1339 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Map<String, int> _parseMutationCounts(String text)
//  â³ Called by: _CoPilotBubbleState
```

#### _CoPilotBubbleState._buildMutationBadge (Function)
```rust
// Lines 1360-1360 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMutationBadge(BuildContext context, Map<String, int> counts)
//  â³ Called by: _CoPilotBubbleState
```

#### _JoshCoPilotPanelState._scrollToBottom (Function)
```rust
// Lines 976-976 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _scrollToBottom()
//  â³ Called by: _JoshCoPilotPanelState
```

#### _CoPilotBubbleState.build (Function)
```rust
// Lines 1401-1401 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _TitleEditor.createState (Function)
```rust
// Lines 898-898 (1 LOC | Complexity 1) | used by 2 callers | [Pure, TraitMethod]
ConsumerState<_TitleEditor> createState()
//  â³ Calls: _TitleEditor, _TitleEditorState
//  â³ Called by: _CoPilotBubble.createState, _JoshCoPilotPanel.createState
```

#### _DiaryEditorContent._triggerSync (Function)
```rust
// Lines 56-62 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _triggerSync(
//  â³ Calls: DiaryBlock, ShuaDiaryEntries.title, ShuaDiaryBlocks.entryId
//  â³ Called by: _DiaryEditorContent
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_delta_emitter.ts (95 lines)

#### SduiDeltaEmitter.emitPatch (Function)
```rust
// Lines 70-81 (12 LOC | Complexity 3) | used by 3 callers | [Io]
static emitPatch(
//  â³ Calls: DeltaPatch, SduiDeltaEmitter._emit
//  â³ Called by: SduiActionHandler._setPrivate, SduiActionHandler._saveTitle, AnalysisWorker._pushDelta
```

#### SduiDeltaEmitter.emitRemove (Function)
```rust
// Lines 59-62 (4 LOC | Complexity 1) | used by 2 callers | [Io]
static emitRemove(socket: Socket, screenId: string, nodeId: string): void
//  â³ Calls: DeltaRemove, SduiDeltaEmitter._emit
//  â³ Called by: SduiActionHandler._deleteEntry, SduiActionHandler._deleteBlock
```

#### DeltaRemove (Interface)
```rust
// Lines 12-15 (4 LOC | Complexity 1) | used by 1 callers
interface DeltaRemove
//  â³ Called by: SduiDeltaEmitter.emitRemove
```

#### DeltaPatch (Interface)
```rust
// Lines 17-22 (6 LOC | Complexity 1) | used by 1 callers
interface DeltaPatch
//  â³ Called by: SduiDeltaEmitter.emitPatch
```

#### SduiDeltaEmitter (Class)
```rust
// Lines 40-91 (52 LOC | Complexity 1) | used by 0 callers
class SduiDeltaEmitter
```

#### SduiDeltaEmitter._emit (Function)
```rust
// Lines 83-90 (8 LOC | Complexity 2) | used by 3 callers | [Io]
private static _emit(socket: Socket, screenId: string, delta: DeltaEvent): void
//  â³ Calls: MessagePackCodec.encode, warn
//  â³ Called by: SduiDeltaEmitter.emitPatch, SduiDeltaEmitter.emitRemove, SduiDeltaEmitter.emitInsert
```

#### DeltaInsert (Interface)
```rust
// Lines 6-10 (5 LOC | Complexity 1) | used by 1 callers
interface DeltaInsert
//  â³ Called by: SduiDeltaEmitter.emitInsert
```

#### SduiDeltaEmitter.emitInsert (Function)
```rust
// Lines 50-53 (4 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
static emitInsert(socket: Socket, screenId: string, node: object, afterId: string | null): void
//  â³ Calls: DeltaInsert, SduiDeltaEmitter._emit
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\models\resume.go (81 lines)

#### ResumeMatrix (Struct)
```rust
// Lines 2-10 (9 LOC | Complexity 1) | used by 11 callers | [CorePrimitive]
ResumeMatrix struct
//  â³ Calls: Award, Certificate, Skill, ProjectItem, Education, WorkItem, Basics
//  â³ Called by: TestCompileTypst, TestFilterResume, handleMatrixCrud, handleWsofflineCompile, assembleScreen, ParseMarkdown, CompilePdfHandler, UpdateMatrixHandler, TailorResume, FilterResume, CompileTypst
```

#### Basics (Struct)
```rust
// Lines 12-21 (10 LOC | Complexity 1) | used by 3 callers
Basics struct
//  â³ Calls: Profile, Location
//  â³ Called by: TestCompileTypst, parseYAML, ResumeMatrix
```

#### Skill (Struct)
```rust
// Lines 70-75 (6 LOC | Complexity 1) | used by 3 callers
Skill struct
//  â³ Called by: handleMatrixCrud, ParseMarkdown, ResumeMatrix
```

#### Certificate (Struct)
```rust
// Lines 77-83 (7 LOC | Complexity 1) | used by 3 callers
Certificate struct
//  â³ Called by: handleMatrixCrud, ParseMarkdown, ResumeMatrix
```

#### Education (Struct)
```rust
// Lines 48-58 (11 LOC | Complexity 1) | used by 4 callers
Education struct
//  â³ Called by: handleMatrixCrud, ParseMarkdown, main, ResumeMatrix
```

#### ProjectItem (Struct)
```rust
// Lines 60-68 (9 LOC | Complexity 1) | used by 5 callers
ProjectItem struct
//  â³ Called by: TestFilterResume, handleMatrixCrud, ParseMarkdown, main, ResumeMatrix
```

#### WorkItem (Struct)
```rust
// Lines 35-46 (12 LOC | Complexity 1) | used by 6 callers
WorkItem struct
//  â³ Called by: TestCompileTypst, TestFilterResume, handleMatrixCrud, ParseMarkdown, main, ResumeMatrix
```

#### Location (Struct)
```rust
// Lines 23-27 (5 LOC | Complexity 1) | used by 1 callers
Location struct
//  â³ Called by: Basics
```

#### Award (Struct)
```rust
// Lines 85-91 (7 LOC | Complexity 1) | used by 3 callers
Award struct
//  â³ Called by: handleMatrixCrud, ParseMarkdown, ResumeMatrix
```

#### Profile (Struct)
```rust
// Lines 29-33 (5 LOC | Complexity 1) | used by 1 callers
Profile struct
//  â³ Called by: Basics
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_progress_bar.dart (53 lines)

#### SduiProgressBar (Class)
```rust
// Lines 18-65 (48 LOC | Complexity 1) | used by 0 callers
class SduiProgressBar extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, SduiFlexContext.of, ProgressMode, SduiProgressBar
```

#### SduiProgressBar.build (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### ProgressMode (Class)
```rust
// Lines 5-8 (4 LOC | Complexity 1) | used by 2 callers
abstract final class ProgressMode
//  â³ Called by: SduiRegistry, SduiProgressBar
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\gemini_analyzer_provider.ts (199 lines)

#### GeminiAnalyzerProvider.analyze (Function)
```rust
// Lines 11-103 (93 LOC | Complexity 8) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod, Tested]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, ShuaDiaryEntries.sentimentScore, AiRateLimiter.execute, filter, Error, warn
```

#### GeminiAnalyzerProvider (Class)
```rust
// Lines 4-104 (101 LOC | Complexity 1) | used by 0 callers
class GeminiAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider, GeminiAnalyzerProvider
```

#### GeminiAnalyzerProvider.constructor (Function)
```rust
// Lines 5-9 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: AiRateLimiter
```

### C:\horAIzon_2.0\tools\summarize_json_mocks.py (98 lines)

#### main (Function)
```rust
// Lines 67-104 (38 LOC | Complexity 5) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: extract_keys, SduiBlockRegistry.load, load_contracts
```

#### extract_keys (Function)
```rust
// Lines 25-65 (41 LOC | Complexity 12) | used by 1 callers | [Pure]
def extract_keys(node, widgets, behaviors, content_keys, summary)
//  â³ Called by: main
```

#### load_contracts (Function)
```rust
// Lines 5-23 (19 LOC | Complexity 3) | used by 0 callers | [Io, PotentialDeadCode]
def load_contracts()
//  â³ Calls: main, SduiBlockRegistry.load
```

### C:\horAIzon_2.0\scripts\ocr_reviewer.py (738 lines)

#### OCRReviewerApp.render_image (Function)
```rust
// Lines 303-322 (20 LOC | Complexity 2) | used by 1 callers | [MutatesState]
def render_image(self, path)
//  â³ Called by: OCRReviewerApp.on_item_select
```

#### OCRReviewerApp (Class)
```rust
// Lines 31-399 (369 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class OCRReviewerApp
//  â³ Calls: main, RadixTrie.insert
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 401-404 (4 LOC | Complexity 1) | used by 0 callers | [Pure, EntryPoint]
def main()
//  â³ Calls: OCRReviewerApp
```

#### OCRReviewerApp.update_csv_file (Function)
```rust
// Lines 375-399 (25 LOC | Complexity 4) | used by 1 callers | [MutatesState]
def update_csv_file(self)
//  â³ Called by: OCRReviewerApp.save_correction
```

#### OCRReviewerApp.load_model_and_data (Function)
```rust
// Lines 162-225 (64 LOC | Complexity 6) | used by 1 callers | [MutatesState, Io]
def load_model_and_data(self)
//  â³ Calls: OCRReviewerApp.apply_filter, ctc_greedy_decode, _preprocess_crop, ShuaDiaryEntries.title, load_ocr_model
//  â³ Called by: OCRReviewerApp.__init__
```

#### OCRReviewerApp.reset_status (Function)
```rust
// Lines 369-372 (4 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def reset_status()
```

#### OCRReviewerApp.save_correction (Function)
```rust
// Lines 324-373 (50 LOC | Complexity 7) | used by 1 callers | [MutatesState, Io]
def save_correction(self)
//  â³ Calls: BinaryLexoRank.after, OCRReviewerApp.on_item_select, OCRReviewerApp.update_csv_file
//  â³ Called by: OCRReviewerApp.build_ui
```

#### OCRReviewerApp.apply_filter (Function)
```rust
// Lines 227-273 (47 LOC | Complexity 8) | used by 1 callers | [MutatesState]
def apply_filter(self, event=None)
//  â³ Calls: RadixTrie.insert
//  â³ Called by: OCRReviewerApp.load_model_and_data
```

#### OCRReviewerApp.__init__ (Function)
```rust
// Lines 32-61 (30 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self, root)
//  â³ Calls: OCRReviewerApp.load_model_and_data, OCRReviewerApp.build_ui, ShuaDiaryEntries.title
```

#### OCRReviewerApp.build_ui (Function)
```rust
// Lines 63-160 (98 LOC | Complexity 1) | used by 1 callers | [MutatesState]
def build_ui(self)
//  â³ Calls: OCRReviewerApp.save_correction
//  â³ Called by: OCRReviewerApp.__init__
```

#### OCRReviewerApp.on_item_select (Function)
```rust
// Lines 275-301 (27 LOC | Complexity 3) | used by 1 callers | [MutatesState]
def on_item_select(self, event=None)
//  â³ Calls: OCRReviewerApp.render_image
//  â³ Called by: OCRReviewerApp.save_correction
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_blueprint_loader.ts (249 lines)

#### SduiBlueprintLoader.invalidateAll (Function)
```rust
// Lines 191-194 (4 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
static invalidateAll(): void
//  â³ Calls: SduiStateVault.clear
```

#### SduiBlueprintLoader.invalidate (Function)
```rust
// Lines 181-186 (6 LOC | Complexity 2) | used by 2 callers | [Io]
static invalidate(modulePath: string): void
//  â³ Called by: _SduiScreenState, SduiEventDispatcher
```

#### SduiBlueprintLoader (Class)
```rust
// Lines 85-195 (111 LOC | Complexity 1) | used by 0 callers
class SduiBlueprintLoader
```

#### SduiBlueprintLoader.loadBlock (Function)
```rust
// Lines 145-175 (31 LOC | Complexity 4) | used by 0 callers | [Io, PotentialDeadCode]
static loadBlock(blockType: string): any | null
//  â³ Calls: ensureWatcher
```

#### ensureWatcher (Function)
```rust
// Lines 52-83 (32 LOC | Complexity 7) | used by 3 callers | [Io, Cycle]
function ensureWatcher(dir: string): void
//  â³ Calls: watchDirectoryRecursive
//  â³ Called by: watchDirectoryRecursive, SduiBlueprintLoader.loadBlock, SduiBlueprintLoader.loadBlueprint
```

#### watchDirectoryRecursive (Function)
```rust
// Lines 16-50 (35 LOC | Complexity 8) | used by 1 callers | [Io, Cycle]
function watchDirectoryRecursive(dirPath: string, callback: (changedAbsPath: string) => void): void
//  â³ Calls: ensureWatcher
//  â³ Called by: ensureWatcher
```

#### SduiBlueprintLoader.loadBlueprint (Function)
```rust
// Lines 103-132 (30 LOC | Complexity 4) | used by 3 callers | [Io, CanPanic]
static loadBlueprint(modulePath: string): any
//  â³ Calls: Error, ensureWatcher
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, SduiNodeBuilder.buildScreen
```

### C:\horAIzon_2.0\scripts\read_sqlite.py (60 lines)

#### main (Function)
```rust
// Lines 4-63 (60 LOC | Complexity 9) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, DiaryRepository.close, MessagePackCodec.encode, SduiSocketManager.connect
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\dart.rs (159 lines)

#### DartExtractor::extract (Function)
```rust
// Lines 9-166 (158 LOC | Complexity 28) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

#### DartExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct DartExtractor;
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\diary\diary_types.ts (53 lines)

#### DiaryBlock (Interface)
```rust
// Lines 34-44 (11 LOC | Complexity 1) | used by 11 callers | [CorePrimitive]
interface DiaryBlock
//  â³ Called by: DiaryRepository._mapBlock, DiaryRepository.createBlock, DiaryRepository.getEntryBlocks, DiaryRepository.getEntryWithBlocks, DiarySearchService.reconcile, DiarySearchService.indexEntry, _JoshCoPilotPanelState, _DiaryEditorContent, _DiaryEditorContent._triggerSync, _buildLegacyNativeBlock, SduiSandboxScreen
```

#### DiaryListContext (Interface)
```rust
// Lines 49-63 (15 LOC | Complexity 1) | used by 0 callers
interface DiaryListContext
```

#### DiaryEditorContext (Interface)
```rust
// Lines 67-78 (12 LOC | Complexity 1) | used by 0 callers
interface DiaryEditorContext
```

#### DiaryEntry (Interface)
```rust
// Lines 8-22 (15 LOC | Complexity 1) | used by 10 callers
interface DiaryEntry
//  â³ Called by: DiaryRepository.searchEntries, DiaryRepository._mapEntry, DiaryRepository.createEntry, DiaryRepository.getEntryWithBlocks, DiaryRepository.getEntry, DiaryRepository.getEntriesList, ScoredEntry, SduiActionHandler._searchDiary, DiarySearchService.reconcile, DiarySearchService.indexEntry
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\save_ai_config.ts (82 lines)

#### SaveAiConfigHandler.handle (Function)
```rust
// Lines 7-46 (40 LOC | Complexity 14) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode, DiaryAiSession.create, SduiOrchestrator.updateSession, DiaryRepository.getAiProviderConfig, getDiaryRepository, DiaryRepository.saveModuleConfig
```

#### SaveAiConfigHandler (Class)
```rust
// Lines 6-47 (42 LOC | Complexity 1) | used by 1 callers
class SaveAiConfigHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_governor\src\logging\flush.rs (164 lines)

#### resolved_db_path (Function)
```rust
// Lines 30-35 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
fn resolved_db_path() -> &'static str
//  â³ Called by: flush_loop
```

#### flush_loop (Function)
```rust
// Lines 79-214 (136 LOC | Complexity 19) | used by 1 callers | [Async, MutatesState, Io]
pub async fn flush_loop(
//  â³ Calls: LogEntry, ok, ensure_schema, resolved_db_path
//  â³ Called by: main
```

#### ensure_schema (Function)
```rust
// Lines 47-68 (22 LOC | Complexity 1) | used by 1 callers | [Io]
fn ensure_schema(conn: &Connection) -> rusqlite::Result<()>
//  â³ Called by: flush_loop
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_block_registry.ts (608 lines)

#### SduiBlockRegistry.buildContentNode (Function)
```rust
// Lines 231-311 (81 LOC | Complexity 25) | used by 1 callers | [Pure, HighComplexity]
static buildContentNode(
//  â³ Calls: SduiBlockRegistry.get
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor
```

#### SduiBlockRegistry.isSystemOwned (Function)
```rust
// Lines 221-226 (6 LOC | Complexity 5) | used by 2 callers | [Pure]
static isSystemOwned(blockType: string): boolean
//  â³ Calls: SduiBlockRegistry.get, SduiBlockRegistry._ensureLoaded
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

#### SduiBlockRegistry.isAiEditable (Function)
```rust
// Lines 214-219 (6 LOC | Complexity 5) | used by 0 callers | [Pure, PotentialDeadCode]
static isAiEditable(blockType: string): boolean
//  â³ Calls: SduiBlockRegistry.get, SduiBlockRegistry._ensureLoaded
```

#### SduiBlockRegistry (Class)
```rust
// Lines 35-345 (311 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiBlockRegistry
//  â³ Calls: BlockTypeSpec
```

#### BlockTypeSpec (Interface)
```rust
// Lines 9-25 (17 LOC | Complexity 1) | used by 4 callers
interface BlockTypeSpec
//  â³ Called by: SduiBlockRegistry.all, SduiBlockRegistry.get, SduiBlockRegistry.load, SduiBlockRegistry
```

#### SduiBlockRegistry.load (Function)
```rust
// Lines 45-144 (100 LOC | Complexity 23) | used by 39 callers | [Io, Tested, CorePrimitive, HighComplexity]
static load(): void
//  â³ Calls: BlockTypeSpec
//  â³ Called by: load_ocr_model, SduiOrchestrator.constructor, train, main, check_stats, check_stats, main, load_contracts, main, convert, load_ocr_model, analyze_json, MeterVisionEngine.get_ocr_model, train, train, main, read_cgroup_cpu_usec, read_memory_bytes, ensure_cgroup_dir, extract_blueprints, _SduiVideoState, log_verbose, log_status, main, load_contracts, summarize, SduiBlockRegistry._ensureLoaded, main, process_upload_bytes, load_contracts, main, main, compile_mock_blueprints, main, load_contracts, run_full_scan, request_primitive, load_schema, compile_blueprints
```

#### SduiBlockRegistry._ensureLoaded (Function)
```rust
// Lines 339-344 (6 LOC | Complexity 2) | used by 6 callers | [Pure]
private static _ensureLoaded(): void
//  â³ Calls: SduiBlockRegistry.load, SduiBlockRegistry._ensureWatcher
//  â³ Called by: SduiBlockRegistry.isSystemOwned, SduiBlockRegistry.isAiEditable, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, SduiBlockRegistry.all, SduiBlockRegistry.get
```

#### SduiBlockRegistry.all (Function)
```rust
// Lines 190-198 (9 LOC | Complexity 1) | used by 72 callers | [Pure, CorePrimitive]
static all(): Array<{ blockType: string; spec: BlockTypeSpec }>
//  â³ Calls: BlockTypeSpec, LogEntry::from, filter, SduiBlockRegistry._ensureLoaded
//  â³ Called by: _SduiCodeEditorState, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, _SduiContainerState, _JoshAutomatedGenerationDialogState, _DiaryEntryCardState, _DiaryListScreenState, _SduiCheckboxState, SduiRegistry, _SduiSandboxScreenState, _SduiDividerState, _SduiExpansionTileState, DiaryRepository.searchEntries, DiaryRepository.getAllEmbeddings, DiaryRepository.getEntryBlocks, DiaryRepository.getMoodTimeline, DiaryRepository.getEntriesList, SduiDatePicker, _SduiHtmlViewerState, SduiStyleResolver, SduiStlViewer, resolve_call_edges, _SduiDrawingPadState, _SduiCodeEditorState, _SduiChartState, SduiTimePicker, _CoPilotBubbleState, _JoshCoPilotPanelState, _DiaryEditorContent, SduiGauge, _SduiTextInputState, SduiSandboxScreen, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSpacerState, _ActionChip, _TelemetryChip, SduiModuleCard, SduiProgressBar, _SduiAudioState, SduiScreenAssembler._assembleDiaryBlockPicker, _SduiOrdinalSliderState, _SduiRadioState, _SduiScreenState, _SduiRadioState, _NetworkConfigCardState, SettingsPage, _SduiDropdownState, _SduiJbcPanelState, SduiImage, SduiContainer, _SduiWrapState, _SduiListEditorState, checkAndSynthesizeForUser, runMonthlySynthesisCheck, _SduiTableState, _SduiDocumentViewerState, SduiCardNode, SduiContainerNode, _SduiCarouselState, SduiTypeRegistry, _SduiShimmerLoaderState, _SduiCheckboxState, _SduiMapState, _FilterChip, _TerminalLineState, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState, _PinEntryScreenState
```

#### SduiBlockRegistry._ensureWatcher (Function)
```rust
// Lines 315-337 (23 LOC | Complexity 3) | used by 1 callers | [Io]
private static _ensureWatcher(): void
//  â³ Calls: warn
//  â³ Called by: SduiBlockRegistry._ensureLoaded
```

#### SduiBlockRegistry.getAiEditableTypes (Function)
```rust
// Lines 200-205 (6 LOC | Complexity 3) | used by 2 callers | [Pure]
static getAiEditableTypes(): string[]
//  â³ Calls: LogEntry::from, filter, SduiBlockRegistry._ensureLoaded
//  â³ Called by: GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc
```

#### SduiBlockRegistry.getSystemOwnedTypes (Function)
```rust
// Lines 207-212 (6 LOC | Complexity 3) | used by 2 callers | [Pure]
static getSystemOwnedTypes(): string[]
//  â³ Calls: LogEntry::from, filter, SduiBlockRegistry._ensureLoaded
//  â³ Called by: GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc
```

#### SduiBlockRegistry.get (Function)
```rust
// Lines 149-185 (37 LOC | Complexity 4) | used by 8 callers | [Io]
static get(blockType: string): BlockTypeSpec
//  â³ Calls: BlockTypeSpec, warn, SduiBlockRegistry._ensureLoaded
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryList, SduiBlockRegistry.buildContentNode, SduiBlockRegistry.isSystemOwned, SduiBlockRegistry.isAiEditable, main, main, main
```

### C:\horAIzon_2.0\shua_governor\src\sdui\node.rs (90 lines)

#### SduiNode::with_content (Function)
```rust
// Lines 42-45 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState, TraitMethod]
pub fn with_content(mut self, key: i32, val: impl Into<Value>) -> Self
//  â³ Calls: RadixTrie.insert
//  â³ Called by: test_sdui_node_builders
```

#### SduiNode::new (Function)
```rust
// Lines 23-33 (11 LOC | Complexity 1) | used by 2 callers | [Pure, TraitMethod]
pub fn new(node_type: i32) -> Self
//  â³ Called by: test_sdui_node_builders, test_sdui_node_construction
```

#### SduiNode::with_child (Function)
```rust
// Lines 48-51 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState, TraitMethod]
pub fn with_child(mut self, child: SduiNode) -> Self
//  â³ Calls: SduiNode
//  â³ Called by: test_sdui_node_builders
```

#### test_sdui_node_construction (Function)
```rust
// Lines 103-107 (5 LOC | Complexity 1) | used by 0 callers | [CanPanic]
fn test_sdui_node_construction()
//  â³ Calls: SduiNode::new
```

#### test_sdui_node_builders (Function)
```rust
// Lines 110-122 (13 LOC | Complexity 1) | used by 0 callers | [CanPanic]
fn test_sdui_node_builders()
//  â³ Calls: SduiNode::with_child, SduiNode::with_content, SduiNode::with_behavior, SduiNode::new
```

#### SduiNode::with_behavior (Function)
```rust
// Lines 36-39 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState, TraitMethod]
pub fn with_behavior(mut self, key: i32, val: impl Into<Value>) -> Self
//  â³ Calls: RadixTrie.insert
//  â³ Called by: test_sdui_node_builders
```

#### SduiNode::serialize (Function)
```rust
// Lines 56-95 (40 LOC | Complexity 17) | used by 0 callers | [TraitMethod, MutatesState]
fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
//  â³ Calls: Error
```

#### SduiNode (Struct)
```rust
// Lines 11-19 (9 LOC | Complexity 1) | used by 0 callers
pub struct SduiNode
//  â³ Calls: SduiNode
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_heading.dart (230 lines)

#### SduiHeading.createState (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiHeading> createState()
//  â³ Calls: SduiHeading, _SduiHeadingState
```

#### _SduiHeadingState._getHeadingStyle (Function)
```rust
// Lines 98-98 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextStyle? _getHeadingStyle(ThemeData theme)
//  â³ Called by: _SduiHeadingState
```

#### _SduiHeadingState._getHeadingMarkdownPrefix (Function)
```rust
// Lines 122-122 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getHeadingMarkdownPrefix()
//  â³ Called by: _SduiHeadingState
```

#### SduiHeading (Class)
```rust
// Lines 4-26 (23 LOC | Complexity 1) | used by 4 callers
class SduiHeading extends StatefulWidget
//  â³ Called by: _SduiHeadingState.didUpdateWidget, _SduiHeadingState, SduiHeading.createState, SduiRegistry
```

#### _SduiHeadingState._resolveTextColor (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color? _resolveTextColor(BuildContext context, String? token)
//  â³ Called by: _SduiHeadingState
```

#### _SduiHeadingState.build (Function)
```rust
// Lines 139-139 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiHeadingState.didUpdateWidget (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiHeading oldWidget)
//  â³ Calls: SduiHeading
//  â³ Called by: _SduiHeadingState
```

#### _SduiHeadingState._onTextChanged (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiHeadingState
```

#### _SduiHeadingState (Class)
```rust
// Lines 28-224 (197 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiHeadingState extends State<SduiHeading>
//  â³ Calls: SduiHeading, _SduiHeadingState._getHeadingMarkdownPrefix, SduiNode.behavior, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, _SduiHeadingState._onTextChanged, _SduiHeadingState._getHintText, _SduiHeadingState._getHeadingStyle, _SduiHeadingState._resolveTextColor, SduiFlexContext.of, SduiIconRegistry.contains, dispose, _SduiHeadingState.didUpdateWidget, initState
//  â³ Called by: SduiHeading.createState
```

#### _SduiHeadingState._getHintText (Function)
```rust
// Lines 134-134 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getHintText()
//  â³ Called by: _SduiHeadingState
```

#### _SduiHeadingState.dispose (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiHeadingState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

### C:\horAIzon_2.0\client_flutter\lib\core\interfaces\illm_provider.dart (3 lines)

#### IllmProvider (Class)
```rust
// Lines 0-2 (3 LOC | Complexity 1) | used by 0 callers
abstract class IllmProvider
```

### C:\horAIzon_2.0\sdui3\diary_list_screen.dart (1045 lines)

#### _DiaryListScreenState.build (Function)
```rust
// Lines 321-321 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _DiaryEntryCard.createState (Function)
```rust
// Lines 450-450 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_DiaryEntryCard> createState()
//  â³ Calls: _DiaryEntryCard, _DiaryEntryCardState, DiaryListScreen.createState
```

#### _DiaryListScreenState._showLoadingDialog (Function)
```rust
// Lines 295-295 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showLoadingDialog(BuildContext context, {String message = 'J.O.S.H. is drafting template blocks...'})
//  â³ Called by: _DiaryListScreenState
```

#### _DiaryListScreenState.initState (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _JoshAutomatedGenerationDialog.createState (Function)
```rust
// Lines 602-602 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_JoshAutomatedGenerationDialog> createState()
//  â³ Calls: _JoshAutomatedGenerationDialog, _JoshAutomatedGenerationDialogState, DiaryListScreen.createState
```

#### _DiaryListScreenState (Class)
```rust
// Lines 24-442 (419 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _DiaryListScreenState extends ConsumerState<DiaryListScreen>
//  â³ Calls: DiaryListScreen, DiaryRepository.createEntry, err, _DiaryEntryCard, DiaryRepository.deleteEntry, onError, SduiBlockRegistry.all, SduiIconRegistry.contains, _DiaryListScreenState._showImportDialog, _DiaryListScreenState._showAiGenerationDialog, SduiStateVault.clear, DiaryRepository.close, _SduiShimmerLoaderState.padding, _DiaryListScreenState._onSearchChanged, DiagnosticResult.success, _JoshAutomatedGenerationDialog, _DiaryListScreenState._showLoadingDialog, ShuaDiaryBlocks.content, ShuaDiaryEntries.title, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, TagSearchService.searchTags, BoundedRouteHistory.isEmpty, dispose, initState
//  â³ Called by: DiaryListScreen.createState
```

#### _DiaryListScreenState.dispose (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _DiaryListScreenState._onSearchChanged (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onSearchChanged(String query)
//  â³ Called by: _DiaryListScreenState
```

#### _JoshAutomatedGenerationDialogState._thinkingStatuses (Function)
```rust
// Lines 619-619 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<String> get _thinkingStatuses
//  â³ Called by: _JoshAutomatedGenerationDialogState
```

#### _JoshAutomatedGenerationDialogState (Class)
```rust
// Lines 605-1049 (445 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _JoshAutomatedGenerationDialogState extends ConsumerState<_JoshAutomatedGenerationDialog>
//  â³ Calls: _JoshAutomatedGenerationDialog, SduiNode.behavior, ShuaDiaryBlocks.content, _SduiShimmerLoaderState.padding, ShuaDiaryEntries.title, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, dispose, ShuaDiaryEntries.privacyTag, BoundedRouteHistory.isEmpty, LogEntry::from, ShuaDiaryBlocks.metadata, _JoshAutomatedGenerationDialogState._parseAndPersist, err, onError, _JoshAutomatedGenerationDialogState._scrollToBottom, _JoshAutomatedGenerationDialogState._thinkingStatuses, initState
//  â³ Called by: _JoshAutomatedGenerationDialog.createState
```

#### _JoshAutomatedGenerationDialogState.initState (Function)
```rust
// Lines 633-633 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _JoshAutomatedGenerationDialogState.dispose (Function)
```rust
// Lines 793-793 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _JoshAutomatedGenerationDialogState.build (Function)
```rust
// Lines 801-801 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _DiaryListScreenState._showImportDialog (Function)
```rust
// Lines 81-81 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showImportDialog(BuildContext context, WidgetRef ref)
//  â³ Called by: _DiaryListScreenState
```

#### DiaryListScreen (Class)
```rust
// Lines 17-22 (6 LOC | Complexity 1) | used by 2 callers
class DiaryListScreen extends ConsumerStatefulWidget
//  â³ Called by: _DiaryListScreenState, DiaryListScreen.createState
```

#### DiaryListScreen.createState (Function)
```rust
// Lines 21-21 (1 LOC | Complexity 1) | used by 2 callers | [Pure, TraitMethod]
ConsumerState<DiaryListScreen> createState()
//  â³ Calls: DiaryListScreen, _DiaryListScreenState
//  â³ Called by: _JoshAutomatedGenerationDialog.createState, _DiaryEntryCard.createState
```

#### _JoshAutomatedGenerationDialogState._parseAndPersist (Function)
```rust
// Lines 696-696 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseAndPersist()
//  â³ Called by: _JoshAutomatedGenerationDialogState
```

#### _DiaryEntryCardState (Class)
```rust
// Lines 453-588 (136 LOC | Complexity 1) | used by 1 callers
class _DiaryEntryCardState extends ConsumerState<_DiaryEntryCard>
//  â³ Calls: _DiaryEntryCard, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, ShuaDiaryBlocks.content, ShuaDiaryEntries.title, _SduiShimmerLoaderState.borderRadius, ShuaDiaryEntries.privacyTag, SduiFlexContext.of
//  â³ Called by: _DiaryEntryCard.createState
```

#### _DiaryEntryCardState.build (Function)
```rust
// Lines 457-457 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _JoshAutomatedGenerationDialogState._scrollToBottom (Function)
```rust
// Lines 682-682 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _scrollToBottom()
//  â³ Called by: _JoshAutomatedGenerationDialogState
```

#### _JoshAutomatedGenerationDialog (Class)
```rust
// Lines 590-603 (14 LOC | Complexity 1) | used by 3 callers
class _JoshAutomatedGenerationDialog extends ConsumerStatefulWidget
//  â³ Called by: _JoshAutomatedGenerationDialogState, _JoshAutomatedGenerationDialog.createState, _DiaryListScreenState
```

#### _DiaryListScreenState._showAiGenerationDialog (Function)
```rust
// Lines 179-179 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showAiGenerationDialog(BuildContext context, WidgetRef ref)
//  â³ Called by: _DiaryListScreenState
```

#### _DiaryEntryCard (Class)
```rust
// Lines 444-451 (8 LOC | Complexity 1) | used by 3 callers
class _DiaryEntryCard extends ConsumerStatefulWidget
//  â³ Called by: _DiaryEntryCardState, _DiaryEntryCard.createState, _DiaryListScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_radio.dart (231 lines)

#### _SduiRadioState (Class)
```rust
// Lines 23-235 (213 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiRadioState extends ConsumerState<SduiRadio>
//  â³ Calls: SduiRadio, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, ShuaSyncQueue.payload, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, dispose, _SduiRadioState.didUpdateWidget, SduiNode.behavior, SduiNode.contentVal, initState
//  â³ Called by: SduiRadio.createState, _SduiRadioState, SduiRadio.createState
```

#### _SduiRadioState.didUpdateWidget (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiRadio oldWidget)
//  â³ Calls: SduiRadio
//  â³ Called by: _SduiRadioState
```

#### _SduiRadioState.dispose (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiRadioState.initState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SduiRadio (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 9 callers
class SduiRadio extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiRadioState.didUpdateWidget, _SduiRadioState, SduiRadio.createState, _SduiRadioState.didUpdateWidget, _SduiRadioState, SduiRadio.createState, SduiRegistry, SduiRadio, SduiTypeRegistry
```

#### _SduiRadioState.build (Function)
```rust
// Lines 78-78 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiRadio.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiRadio> createState()
//  â³ Calls: SduiRadio, _SduiRadioState
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\AnalysisWorker.ts (287 lines)

#### AnalysisWorker.constructor (Function)
```rust
// Lines 54-54 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
private constructor() {}
```

#### AnalysisWorker._processNext (Function)
```rust
// Lines 121-193 (73 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
private async _processNext(): Promise<void>
//  â³ Calls: ShuaDiaryEntries.privacyTag, ShuaDiaryEntries.milestoneTag, ShuaDiaryEntries.sentimentScore, AnalyzerService.analyze, run, warn, filter, log, AnalysisWorker._setStatus
//  â³ Called by: AnalysisWorker.enqueue
```

#### AnalysisWorker.getStatus (Function)
```rust
// Lines 92-94 (3 LOC | Complexity 2) | used by 1 callers | [Pure]
getStatus(entryId: string): AnalysisStatus | null
//  â³ Called by: DiaryBlockPayload
```

#### AnalysisResult (Interface)
```rust
// Lines 9-15 (7 LOC | Complexity 1) | used by 0 callers
interface AnalysisResult
//  â³ Calls: AnalysisResult
```

#### AnalysisWorker._setStatus (Function)
```rust
// Lines 104-115 (12 LOC | Complexity 3) | used by 2 callers | [MutatesState, Io]
private _setStatus(entryId: string, status: AnalysisStatus): void
//  â³ Calls: log
//  â³ Called by: AnalysisWorker._processNext, AnalysisWorker.enqueue
```

#### AnalysisWorker.enqueue (Function)
```rust
// Lines 69-85 (17 LOC | Complexity 3) | used by 1 callers | [MutatesState, Io]
enqueue(entryId: string, blocks: Array<{ type: string; content: string }>, geminiApiKey?: string): void
//  â³ Calls: AnalysisWorker._processNext, AnalysisWorker._setStatus, log
//  â³ Called by: DiaryBlockPayload
```

#### AnalysisWorker (Class)
```rust
// Lines 35-194 (160 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class AnalysisWorker
//  â³ Calls: PendingJob, AnalysisWorker, AnalyzerService
```

#### AnalysisWorker.queueDepth (Function)
```rust
// Lines 97-99 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
get queueDepth(): number
```

#### AnalysisWorker.getInstance (Function)
```rust
// Lines 57-62 (6 LOC | Complexity 2) | used by 1 callers | [Pure]
static getInstance(): AnalysisWorker
//  â³ Calls: AnalysisWorker
//  â³ Called by: DiaryBlockPayload
```

#### PendingJob (Interface)
```rust
// Lines 3-7 (5 LOC | Complexity 1) | used by 0 callers
interface PendingJob
//  â³ Calls: PendingJob
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\ai\tailor.go (232 lines)

#### projectScore (Struct)
```rust
// Lines 120-123 (4 LOC | Complexity 1) | used by 1 callers
projectScore struct
//  â³ Called by: FilterResume
```

#### JaccardSimilarity (Function)
```rust
// Lines 32-47 (16 LOC | Complexity 6) | used by 2 callers | [Pure, Tested]
func JaccardSimilarity(setA, setB map[string]bool) float64
//  â³ Called by: TestJaccardSimilarity, FilterResume
```

#### OllamaResponse (Struct)
```rust
// Lines 164-167 (4 LOC | Complexity 1) | used by 1 callers
OllamaResponse struct
//  â³ Called by: TailorResume
```

#### OllamaRequest (Struct)
```rust
// Lines 157-161 (5 LOC | Complexity 1) | used by 1 callers
OllamaRequest struct
//  â³ Called by: TailorResume
```

#### Tokenize (Function)
```rust
// Lines 19-29 (11 LOC | Complexity 3) | used by 2 callers | [MutatesState, Tested]
func Tokenize(text string) map[string]bool
//  â³ Called by: TestTokenize, FilterResume
```

#### workScore (Struct)
```rust
// Lines 83-86 (4 LOC | Complexity 1) | used by 1 callers
workScore struct
//  â³ Called by: FilterResume
```

#### FilterResume (Function)
```rust
// Lines 68-154 (87 LOC | Complexity 14) | used by 3 callers | [MutatesState, Tested]
func FilterResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) *models.ResumeMatrix
//  â³ Calls: projectScore, workScore, TailorConfig, ResumeMatrix, JaccardSimilarity, Tokenize
//  â³ Called by: TestFilterResume, handleWsofflineCompile, CompilePdfHandler
```

#### TailorConfig (Struct)
```rust
// Lines 50-55 (6 LOC | Complexity 1) | used by 3 callers
TailorConfig struct
//  â³ Called by: TailorResume, FilterResume, DefaultTailorConfig
```

#### TailorResume (Function)
```rust
// Lines 171-257 (87 LOC | Complexity 15) | used by 2 callers | [MutatesState, Io]
func TailorResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) *models.ResumeMatrix
//  â³ Calls: OllamaResponse, OllamaRequest, TailorConfig, ResumeMatrix, Info, Error
//  â³ Called by: handleWsofflineCompile, CompilePdfHandler
```

#### DefaultTailorConfig (Function)
```rust
// Lines 58-65 (8 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
func DefaultTailorConfig() TailorConfig
//  â³ Calls: TailorConfig
//  â³ Called by: TestFilterResume, handleWsofflineCompile, CompilePdfHandler
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\mod.rs (35 lines)

#### health_check (Function)
```rust
// Lines 18-32 (15 LOC | Complexity 1) | used by 0 callers | [Async, CanPanic, ApiRoute]
pub async fn health_check(State(state): State<AppState>) -> Json<HealthResponse>
//  â³ Calls: HealthResponse, AppState, get_rss_mb
```

#### HealthResponse (Struct)
```rust
// Lines 10-16 (7 LOC | Complexity 1) | used by 1 callers
pub struct HealthResponse
//  â³ Called by: health_check
```

#### get_rss_mb (Function)
```rust
// Lines 34-46 (13 LOC | Complexity 4) | used by 1 callers | [Io]
fn get_rss_mb() -> u32
//  â³ Called by: health_check
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\logger\logger.go (116 lines)

#### GetDroppedCount (Function)
```rust
// Lines 152-154 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
func GetDroppedCount() uint64
```

#### Info (Function)
```rust
// Lines 138-140 (3 LOC | Complexity 1) | used by 10 callers | [Pure]
func Info(subsystem, msg string, telemetry map[string]interface{})
//  â³ Calls: submitLog
//  â³ Called by: handleWsofflineCompile, handleRpcCall, HandleWebSocket, main, saveCompilationToHistory, UpdateMatrixHandler, seedDatabase, InitDB, TailorResume, CompileTypst
```

#### logWorker (Function)
```rust
// Lines 42-93 (52 LOC | Complexity 6) | used by 1 callers | [MutatesState, Io]
func logWorker()
//  â³ Called by: init
```

#### resolveLogLevel (Function)
```rust
// Lines 96-111 (16 LOC | Complexity 6) | used by 1 callers | [Pure]
func resolveLogLevel(level string) uint8
//  â³ Called by: submitLog
```

#### Debug (Function)
```rust
// Lines 133-135 (3 LOC | Complexity 1) | used by 2 callers | [Pure]
func Debug(subsystem, msg string, telemetry map[string]interface{})
//  â³ Calls: submitLog
//  â³ Called by: FieldVisitor::record_debug, Visitor::record_debug
```

#### submitLog (Function)
```rust
// Lines 114-130 (17 LOC | Complexity 2) | used by 3 callers | [Async, Pure]
func submitLog(levelStr, subsystem, msg string, telemetry map[string]interface{})
//  â³ Calls: LogEntry, resolveLogLevel
//  â³ Called by: Error, Info, Debug
```

#### init (Function)
```rust
// Lines 34-39 (6 LOC | Complexity 1) | used by 3 callers | [Async, Pure, Tested]
func init()
//  â³ Calls: logWorker
//  â³ Called by: main, main, SduiComposer.composeBlock
```

#### Error (Function)
```rust
// Lines 143-149 (7 LOC | Complexity 2) | used by 68 callers | [MutatesState, Tested, CorePrimitive]
func Error(subsystem, msg string, err error, telemetry map[string]interface{})
//  â³ Calls: submitLog
//  â³ Called by: main, load_from_json, SduiNode::serialize, kill, read_memory_bytes, assign_pid, unfreeze, freeze, ensure_cgroup_dir, Visitor::visit_map, BorrowedLogEntry::deserialize, chunk_finalize, OllamaAnalyzerProvider.analyze, OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream, OllamaAssistantProvider.generateSummary, OllamaAssistantProvider.generateTemplateStream, OllamaAssistantProvider.generateTemplate, GeminiJbcProvider.generateSummary, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, handleWsofflineCompile, assembleScreen, handleRpcCall, HandleWebSocket, GeminiAnalyzerProvider.analyze, PythonFallbackProvider.analyze, AnalyzerService.analyze, N8nJbcProvider.generateSummary, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc, N8nJbcProvider.checkConfig, OllamaGeneratorProvider.generateFromNotesStream, OllamaGeneratorProvider.generateFromNotes, SemanticSearchHandler.handle, main, ListCompiledHandler, GetTemplatesHandler, saveCompilationToHistory, CompilePdfHandler, UpdateMatrixHandler, GetMatrixHandler, sendResponse, SduiBlueprintLoader.loadBlueprint, OllamaJbcProvider.generateSummary, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc, GeminiAnalyzerProvider.analyze, SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, PythonSemanticsAnalyzerProvider.analyze, TailorResume, GeminiGeneratorProvider.generateFromNotesStream, GeminiGeneratorProvider.generateFromNotes, OllamaAnalyzerProvider.analyze, N8nAssistantProvider.plannerRefactor, N8nAssistantProvider.chatStream, N8nAssistantProvider.generateSummary, N8nAssistantProvider.generateTemplateStream, N8nAssistantProvider.generateTemplate, GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.chatStream, GeminiAssistantProvider.generateSummary, GeminiAssistantProvider.generateTemplateStream, GeminiAssistantProvider.generateTemplate, SduiNodeBuilder.buildScreen, CompileTypst, N8nAnalyzerProvider.analyze
```

#### LogEntry (Struct)
```rust
// Lines 15-23 (9 LOC | Complexity 1) | used by 0 callers
LogEntry struct
//  â³ Calls: LogEntry
```

### C:\horAIzon_2.0\tools\manage_skills.py (105 lines)

#### main (Function)
```rust
// Lines 22-112 (91 LOC | Complexity 19) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: safe_remove
```

#### safe_remove (Function)
```rust
// Lines 7-20 (14 LOC | Complexity 5) | used by 1 callers | [Io]
def safe_remove(path: Path)
//  â³ Calls: main
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\go.rs (154 lines)

#### GoExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct GoExtractor;
```

#### GoExtractor::extract (Function)
```rust
// Lines 9-161 (153 LOC | Complexity 28) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, SduiIconRegistry.contains, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\AssistantService.ts (120 lines)

#### AssistantService.generateTemplateStream (Function)
```rust
// Lines 38-40 (3 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
async generateTemplateStream(topic: string, style: string): Promise<any>
//  â³ Calls: AssistantService.getProvider, IAssistantProvider.generateTemplateStream
//  â³ Called by: DiaryBlockPayload
```

#### AssistantService.plannerRefactor (Function)
```rust
// Lines 65-76 (12 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
async plannerRefactor(
//  â³ Calls: AssistantService.getProvider, IAssistantProvider.plannerRefactor
//  â³ Called by: DiaryBlockPayload
```

#### AssistantService (Class)
```rust
// Lines 6-77 (72 LOC | Complexity 1) | used by 1 callers
class AssistantService
//  â³ Calls: IAssistantProvider
//  â³ Called by: DiaryBlockPayload
```

#### AssistantService.generateSummary (Function)
```rust
// Lines 45-47 (3 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
async generateSummary(content: string): Promise<string>
//  â³ Calls: AssistantService.getProvider, IAssistantProvider.generateSummary
//  â³ Called by: DiaryBlockPayload
```

#### AssistantService.getProvider (Function)
```rust
// Lines 9-23 (15 LOC | Complexity 4) | used by 5 callers | [MutatesState]
private getProvider(): IAssistantProvider
//  â³ Calls: IAssistantProvider, OllamaAssistantProvider, GeminiAssistantProvider, N8nAssistantProvider
//  â³ Called by: AssistantService.plannerRefactor, AssistantService.chatStream, AssistantService.generateSummary, AssistantService.generateTemplateStream, AssistantService.generateTemplate
```

#### AssistantService.chatStream (Function)
```rust
// Lines 52-60 (9 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
async chatStream(
//  â³ Calls: AssistantService.getProvider, IAssistantProvider.chatStream
//  â³ Called by: DiaryBlockPayload
```

#### AssistantService.generateTemplate (Function)
```rust
// Lines 28-33 (6 LOC | Complexity 1) | used by 0 callers | [Async, Pure, PotentialDeadCode]
async generateTemplate(
//  â³ Calls: AssistantService.getProvider, IAssistantProvider.generateTemplate
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\generate_synthetic_ocr.py (157 lines)

#### _generate_serial_string (Function)
```rust
// Lines 52-67 (16 LOC | Complexity 1) | used by 1 callers | [Pure]
def _generate_serial_string() -> str
//  â³ Called by: generate
```

#### _apply_jitter (Function)
```rust
// Lines 84-90 (7 LOC | Complexity 1) | used by 2 callers | [Pure]
def _apply_jitter(color: tuple, max_jitter: int = 15) -> tuple
//  â³ Called by: generate, _generate_synthetic_crop
```

#### _load_rgb_profiles (Function)
```rust
// Lines 69-82 (14 LOC | Complexity 3) | used by 1 callers | [Io]
def _load_rgb_profiles() -> list[tuple]
//  â³ Called by: generate
```

#### get_font (Function)
```rust
// Lines 40-47 (8 LOC | Complexity 3) | used by 1 callers | [Pure, Cycle]
def get_font(size)
//  â³ Calls: generate
//  â³ Called by: _generate_synthetic_crop
```

#### generate (Function)
```rust
// Lines 171-207 (37 LOC | Complexity 4) | used by 13 callers | [Io, Cycle, Tested, CorePrimitive]
def generate(num_samples=10000)
//  â³ Calls: _generate_synthetic_crop, _apply_jitter, _generate_serial_string, _load_rgb_profiles
//  â³ Called by: _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, _SduiSandboxScreenState, _SduiShimmerLoaderState, SduiSandboxScreen, get_font, _SduiOrdinalSliderState, _SduiTableState, _SduiCarouselState, _SduiShimmerLoaderState, _SduiTimelineState, _PinEntryScreenState
```

#### _generate_synthetic_crop (Function)
```rust
// Lines 92-166 (75 LOC | Complexity 8) | used by 1 callers | [Pure, Cycle]
def _generate_synthetic_crop(text: str, bg_color: tuple, fg_color: tuple) -> np.ndarray
//  â³ Calls: filter, get_font, _apply_jitter
//  â³ Called by: generate
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\convert_dataset.py (243 lines)

#### setup_dirs (Function)
```rust
// Lines 28-32 (5 LOC | Complexity 3) | used by 1 callers | [Pure, Cycle]
def setup_dirs()
//  â³ Calls: convert
//  â³ Called by: convert
```

#### process_split (Function)
```rust
// Lines 87-175 (89 LOC | Complexity 17) | used by 1 callers | [Io]
def process_split(tasks, img_out, lbl_out, split_name)
//  â³ Called by: convert
```

#### get_latest_export (Function)
```rust
// Lines 34-40 (7 LOC | Complexity 3) | used by 2 callers | [Pure]
def get_latest_export()
//  â³ Called by: convert, summarize
```

#### convert (Function)
```rust
// Lines 42-183 (142 LOC | Complexity 25) | used by 4 callers | [Io, Cycle, HighComplexity]
def convert(json_path=None)
//  â³ Calls: DiaryRepository.close, process_split, setup_dirs, SduiBlockRegistry.load, get_latest_export
//  â³ Called by: setup_dirs, SduiSandboxScreen, _TerminalLineState, _SduiTerminalState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\json.rs (78 lines)

#### serialize (Function)
```rust
// Lines 23-84 (62 LOC | Complexity 8) | used by 1 callers | [MutatesState, CanPanic, Tested]
pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String
//  â³ Calls: ExportNode, AppState, ExportOptions, SubGraph, SduiIconRegistry.contains, collect
//  â³ Called by: export_sdg
```

#### ExportNode (Struct)
```rust
// Lines 6-21 (16 LOC | Complexity 1) | used by 1 callers
pub struct ExportNode
//  â³ Called by: serialize
```

### C:\horAIzon_2.0\sdui3\sdui_sandbox\providers\sandbox_providers.dart (91 lines)

#### SandboxController.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void build()
//  â³ Calls: build
```

#### SandboxController (Class)
```rust
// Lines 14-100 (87 LOC | Complexity 1) | used by 0 callers
class SandboxController extends Notifier<void>
//  â³ Calls: ShuaDiaryBlocks.metadata, ShuaDiaryBlocks.sortKey, ShuaDiaryBlocks.content, ShuaDiaryBlocks.blockType, ShuaDiaryBlocks.entryId
```

#### SandboxController.updateContent (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> updateContent(String blockId, String newContent)
//  â³ Called by: SduiSandboxScreen
```

#### SandboxController.updateMetadata (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> updateMetadata(String blockId, String newMetadata)
//  â³ Called by: SduiSandboxScreen
```

#### SandboxController.initBlock (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> initBlock(String type)
//  â³ Called by: SduiSandboxScreen
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_module_card.dart (362 lines)

#### _TelemetryChip.build (Function)
```rust
// Lines 323-323 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiModuleCard.build (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### SduiModuleCard (Class)
```rust
// Lines 22-312 (291 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiModuleCard extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, _ActionChip, _TelemetryChip, SduiShimmerLoader, _SduiShimmerLoaderState.borderRadius, ShuaDiaryBlocks.content, SduiNode, SduiIconRegistry, SduiFlexContext.of, log, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, BoundedRouteHistory.isEmpty, SduiNode.contentVal
//  â³ Called by: SduiTypeRegistry
```

#### _ActionChip.build (Function)
```rust
// Lines 367-367 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _TelemetryChip (Class)
```rust
// Lines 315-349 (35 LOC | Complexity 1) | used by 1 callers
class _TelemetryChip extends StatelessWidget
//  â³ Calls: SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding
//  â³ Called by: SduiModuleCard
```

#### _ActionChip (Class)
```rust
// Lines 353-385 (33 LOC | Complexity 1) | used by 1 callers
class _ActionChip extends StatelessWidget
//  â³ Calls: SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius
//  â³ Called by: SduiModuleCard
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\events\sdui_event_dispatcher.dart (492 lines)

#### SduiEventDispatcher._handleSubmitForm (Function)
```rust
// Lines 457-457 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _handleSubmitForm(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.onReorder (Function)
```rust
// Lines 330-335 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
void onReorder(
//  â³ Called by: _SduiContainerState
```

#### SduiEventDispatcher._fireRpc (Function)
```rust
// Lines 430-430 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _fireRpc(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.flushPending (Function)
```rust
// Lines 368-368 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void flushPending()
//  â³ Called by: _SduiScreenState
```

#### SduiActionType (Enum)
```rust
// Lines 16-22 (7 LOC | Complexity 1) | used by 0 callers
enum SduiActionType
//  â³ Calls: SduiEventDispatcher
```

#### SduiEventDispatcher._syncToServer (Function)
```rust
// Lines 401-401 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _syncToServer(String nodeId, dynamic value)
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher (Class)
```rust
// Lines 31-499 (469 LOC | Complexity 1) | used by 50 callers | [CorePrimitive, HighComplexity]
class SduiEventDispatcher
//  â³ Calls: ShuaDiaryBlocks.entryId, SduiStateVault.clear, LogEntry::from, SduiSocketManager.emitRpc, SduiEventDispatcher._resolveRpcMethodName, DiaryRepository.close, SduiIconRegistry.contains, BoundedRouteHistory.isEmpty, SduiSocketManager.injectLocalDelta, SduiEventDispatcher._handleAiCommand, SduiEventDispatcher._handleSubmitForm, ShuaDiaryBlocks.content, N8nAssistantProvider.baseUrl, SduiBlueprintLoader.invalidate, SduiEventDispatcher._resolveScreenIdFromLocation, BoundedRouteHistory.currentLocation, Response, log, SduiEventDispatcher._fireRpc, SduiFlexContext.of, ShuaSyncQueue.payload, SduiEventDispatcher._syncToServer, RadixTrie.remove
//  â³ Called by: SduiButton, SduiCodeEditor, SduiTable, SduiOrdinalSlider, SduiListEditor, SduiContainer, SduiCheckbox, _SduiSandboxScreenState._buildBody, SduiDivider, SduiExpansionTile, SduiDatePicker, SduiHtmlViewer, SduiStlViewer, SduiDrawingPad, SduiChart, SduiTimePicker, SduiListView, SduiGauge, MediaUploader.pickAndUploadWithUi, SduiHeatmap, SduiVideo, SduiProgressBar, SduiSpacer, SduiModuleCard, SduiSlider, SduiGridView, SduiAudio, SduiToggle, SduiRadio, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, _SduiScreenState, SduiDropdown, SduiChip, SduiTextInput, SduiImage, SduiWrap, SduiRenderer, SduiDocumentViewer, SduiCarousel, SduiTypeRegistry.buildNode, SduiShimmerLoader, SduiMap, SduiTerminal, SduiTimeline, SduiMarkdownEditor, SduiEventDispatcher, SduiRegistry, SduiSandboxScreen, SduiActionType
```

#### SduiEventDispatcher.onAction (Function)
```rust
// Lines 86-86 (1 LOC | Complexity 1) | used by 11 callers | [Pure, CorePrimitive]
void onAction(Map<int, dynamic> payload, [BuildContext? context])
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: SduiButton, _SduiCodeEditorState, _SduiOrdinalSliderState, _SduiCheckboxState, _SduiHtmlViewerState, SduiHeatmap, _SduiSliderState, SduiToggle, _SduiRadioState, SduiChip, _SduiMapState
```

#### SduiEventDispatcher.cancelPending (Function)
```rust
// Lines 382-382 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void cancelPending()
```

#### SduiEventDispatcher._resolveScreenIdFromLocation (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? _resolveScreenIdFromLocation(String location)
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher._resolveRpcMethodName (Function)
```rust
// Lines 396-396 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? _resolveRpcMethodName(int methodId)
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.onStateChange (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 28 callers | [Pure, CorePrimitive]
void onStateChange(String nodeId, dynamic value)
//  â³ Called by: _SduiCodeEditorState, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState, _SduiCheckboxState, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, _SduiDrawingPadState, _SduiChartState, SduiTimePicker, MediaUploader, SduiHeatmap, _SduiVideoState, _SduiSpacerState, _SduiSliderState, _SduiAudioState, SduiToggle, _SduiRadioState, _SduiDropdownState, SduiChip, _SduiTextInputState, _SduiCarouselState, _SduiMapState, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState
```

#### SduiEventDispatcher._handleAiCommand (Function)
```rust
// Lines 218-218 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _handleAiCommand(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: SduiEventDispatcher
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_action_handler.ts (896 lines)

#### SduiActionHandler._getMonthlySynthesis (Function)
```rust
// Lines 509-527 (19 LOC | Complexity 3) | used by 1 callers | [Io]
private static _getMonthlySynthesis(socket: Socket, params: Record<string, any>): void
//  â³ Calls: MessagePackCodec.encode, ShuaSyncQueue.payload, SduiScreenAssembler.assemble, checkAndSynthesizeForUser
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._reorderBlock (Function)
```rust
// Lines 161-184 (24 LOC | Complexity 5) | used by 1 callers | [Io]
private static _reorderBlock(params: Record<string, any>): void
//  â³ Calls: DiaryRepository.reorderBlockByNeighbors, DiaryRepository.getEntryIdForBlock, getDiaryRepository
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._deleteBlock (Function)
```rust
// Lines 192-206 (15 LOC | Complexity 3) | used by 1 callers | [Io]
private static _deleteBlock(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiDeltaEmitter.emitRemove, getDiaryRepository, DiaryRepository.deleteBlock
//  â³ Called by: SduiActionHandler.handle
```

#### ScoredEntry (Interface)
```rust
// Lines 360-360 (1 LOC | Complexity 1) | used by 1 callers
interface ScoredEntry { entry: DiaryEntry; score: number; }
//  â³ Calls: DiaryEntry
//  â³ Called by: SduiActionHandler._searchDiary
```

#### SduiActionHandler._createEntry (Function)
```rust
// Lines 430-453 (24 LOC | Complexity 4) | used by 1 callers | [Io]
private static _createEntry(socket: Socket, params: Record<string, any>): void
//  â³ Calls: MessagePackCodec.encode, ShuaSyncQueue.payload, SduiScreenAssembler.assemble, getDiaryRepository, DiaryRepository.createEntry
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler.handle (Function)
```rust
// Lines 31-82 (52 LOC | Complexity 12) | used by 1 callers | [Io, Tested]
static handle(socket: Socket, method: string, params: Record<string, any>): void
//  â³ Calls: warn, SduiActionHandler._getMonthlySynthesis, SduiActionHandler._getBlocks, SduiActionHandler._searchDiary, SduiActionHandler._setPrivate, SduiActionHandler._deleteEntry, SduiActionHandler._createEntry, SduiActionHandler._createBlock, SduiActionHandler._deleteBlock, SduiActionHandler._reorderBlock, SduiActionHandler._saveTitle, SduiActionHandler._saveBlock
//  â³ Called by: SduiOrchestrator.handleRpc
```

#### SduiActionHandler (Class)
```rust
// Lines 23-528 (506 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiActionHandler
```

#### SduiActionHandler._saveTitle (Function)
```rust
// Lines 91-121 (31 LOC | Complexity 4) | used by 1 callers | [Io]
private static _saveTitle(socket: Socket, params: Record<string, any>): void
//  â³ Calls: MessagePackCodec.encode, ShuaSyncQueue.payload, SduiScreenAssembler.assemble, DiaryRepository.getEntry, ShuaDiaryEntries.title, SduiDeltaEmitter.emitPatch, getDiaryRepository, DiaryRepository.updateEntryTitle
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._saveBlock (Function)
```rust
// Lines 129-149 (21 LOC | Complexity 4) | used by 1 callers | [Io]
private static _saveBlock(params: Record<string, any>): void
//  â³ Calls: DiaryRepository.saveBlockEmbedding, getEmbedding, DiaryRepository.getEntryUserIdForBlock, DiaryRepository.updateBlock, getDiaryRepository
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._createBlock (Function)
```rust
// Lines 224-253 (30 LOC | Complexity 4) | used by 1 callers | [Io]
private static _createBlock(socket: Socket, params: Record<string, any>): void
//  â³ Calls: ShuaSyncQueue.payload, MessagePackCodec.encode, SduiScreenAssembler.assemble, getDiaryRepository, DiaryRepository.createBlock
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._deleteEntry (Function)
```rust
// Lines 262-284 (23 LOC | Complexity 5) | used by 1 callers | [Io]
private static _deleteEntry(socket: Socket, params: Record<string, any>): void
//  â³ Calls: ShuaSyncQueue.payload, MessagePackCodec.encode, SduiScreenAssembler.assemble, SduiDeltaEmitter.emitRemove, getDiaryRepository, DiaryRepository.deleteEntry
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._getBlocks (Function)
```rust
// Lines 484-502 (19 LOC | Complexity 3) | used by 1 callers | [Io]
private static _getBlocks(socket: Socket, params: Record<string, any>): void
//  â³ Calls: MessagePackCodec.encode, ShuaSyncQueue.payload, SduiScreenAssembler.assemble
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._searchDiary (Function)
```rust
// Lines 308-421 (114 LOC | Complexity 20) | used by 1 callers | [Async, Io]
private static async _searchDiary(socket: Socket, params: Record<string, any>): Promise<void>
//  â³ Calls: ScoredEntry, DiaryEntry, DiaryRepository.getBlockSearchDetails, DiaryRepository.getSnippetsForEntries, DiaryRepository.getEntriesList, filter, ShuaSyncQueue.id, DiaryRepository.searchEntries, DiarySearchService.getInstance, DiarySearchService.search, getDiaryRepository, ShuaSyncQueue.payload, MessagePackCodec.encode, SduiScreenAssembler.assemble
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._setPrivate (Function)
```rust
// Lines 461-477 (17 LOC | Complexity 3) | used by 1 callers | [Io]
private static _setPrivate(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiDeltaEmitter.emitPatch, getDiaryRepository, DiaryRepository.setPrivate
//  â³ Called by: SduiActionHandler.handle
```

### C:\horAIzon_2.0\client_flutter\lib\app\adaptive_shell.dart (245 lines)

#### AdaptiveShell._buildMobileStat (Function)
```rust
// Lines 210-210 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMobileStat(IconData icon, String value, Color color)
//  â³ Called by: AdaptiveShell
```

#### AdaptiveShell._getSelectedIndex (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int _getSelectedIndex(BuildContext context)
//  â³ Called by: AdaptiveShell
```

#### AdaptiveShell (Class)
```rust
// Lines 10-250 (241 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class AdaptiveShell extends ConsumerWidget
//  â³ Calls: SduiFlexContext.of, AdaptiveShell._buildStatIcon, _SduiShimmerLoaderState.padding, AdaptiveShell._getSelectedIndex, BoundedRouteHistory.moveForward, BoundedRouteHistory.canGoForward, BoundedRouteHistory.moveBack, BoundedRouteHistory.canGoBack, BoundedRouteHistory.currentLocation, AdaptiveShell._buildMobileStat
```

#### AdaptiveShell.build (Function)
```rust
// Lines 16-16 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### AdaptiveShell._buildStatIcon (Function)
```rust
// Lines 229-229 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStatIcon(IconData icon, String value, Color color)
//  â³ Called by: AdaptiveShell
```

### C:\horAIzon_2.0\tools\scratch\split_schema.py (47 lines)

#### main (Function)
```rust
// Lines 7-53 (47 LOC | Complexity 4) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, RadixTrie.remove, SduiStateVault.dump, SduiBlockRegistry.load
```

### C:\horAIzon_2.0\client_flutter\lib\main.dart (28 lines)

#### HorAIzonClientShell (Class)
```rust
// Lines 30-56 (27 LOC | Complexity 1) | used by 0 callers
class HorAIzonClientShell extends ConsumerWidget
//  â³ Calls: SduiFlexContext.of, ThemeState.compiledData, ShuaDiaryEntries.title, onError, main
```

#### HorAIzonClientShell.build (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\diagnostics_provider.dart (352 lines)

#### DiagnosticsHistoryNotifier (Class)
```rust
// Lines 110-346 (237 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiagnosticsHistoryNotifier extends Notifier<DiagnosticsState>
//  â³ Calls: DiagnosticResult, DiagnosticResult.latencyMs, DiagnosticResult.isFailure, DiagnosticResult.isCritical, LogEntry::from, OccurrenceEntry, log, DiagnosticSeverity, TelemetryProfile, DiagnosticsHistoryNotifier.setTelemetryProfile, DiagnosticsHistoryNotifier.updateLimits, DiagnosticsHistoryNotifier._truncate, DiagnosticsState.copyWith, DiagnosticsState, DiagnosticsHistoryNotifier.logResult
//  â³ Called by: TelemetryProfile
```

#### DiagnosticsHistoryNotifier.setTelemetryProfile (Function)
```rust
// Lines 168-168 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void setTelemetryProfile(TelemetryProfile profile)
//  â³ Calls: TelemetryProfile
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.build (Function)
```rust
// Lines 112-112 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
DiagnosticsState build()
//  â³ Calls: DiagnosticsState, build
```

#### DiagnosticsHistoryNotifier.updateLimits (Function)
```rust
// Lines 144-149 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateLimits(
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsState (Class)
```rust
// Lines 24-102 (79 LOC | Complexity 1) | used by 8 callers
class DiagnosticsState
//  â³ Calls: DiagnosticResult
//  â³ Called by: DiagnosticsHistoryNotifier.build, DiagnosticsState.copyWith, _SuccessRateBadge, _SduiTerminalState._buildSubsystemFilterBar, _SduiTerminalState._buildHeader, _SduiTerminalState, _SduiTerminalState._getFilteredLogs, DiagnosticsHistoryNotifier
```

#### TelemetryProfile (Enum)
```rust
// Lines 12-21 (10 LOC | Complexity 1) | used by 2 callers
enum TelemetryProfile
//  â³ Calls: log, DiagnosticResult.success, DiagnosticResult.failure, SystemDiagnostic, DiagnosticSeverity, BoundedRouteHistory.isEmpty, DiaryRepository.close, DiagnosticResult, DiagnosticsHistoryNotifier
//  â³ Called by: DiagnosticsHistoryNotifier.setTelemetryProfile, DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier._truncate (Function)
```rust
// Lines 136-136 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<DiagnosticResult> _truncate(List<DiagnosticResult> list, int limit)
//  â³ Calls: DiagnosticResult
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.resetLimitsToDefault (Function)
```rust
// Lines 198-198 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void resetLimitsToDefault()
```

#### DiagnosticsState.successRate (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double get successRate
//  â³ Called by: _SuccessRateBadge
```

#### DiagnosticsHistoryNotifier.clearHistory (Function)
```rust
// Lines 335-335 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void clearHistory()
//  â³ Called by: _SduiTerminalState
```

#### DiagnosticsHistoryNotifier.logResult (Function)
```rust
// Lines 203-203 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
void logResult(DiagnosticResult result, {bool fromRemote = false})
//  â³ Calls: DiagnosticResult
//  â³ Called by: DiagnosticsHistoryNotifier, BoundedRouteHistory, ThemeNotifier, AuthNotifier
```

#### DiagnosticsState.copyWith (Function)
```rust
// Lines 67-79 (13 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
DiagnosticsState copyWith(
//  â³ Calls: DiagnosticResult, DiagnosticsState
//  â³ Called by: DiagnosticsHistoryNotifier
```

### C:\horAIzon_2.0\tools\compile_blueprints.py (31 lines)

#### compile_blueprints (Function)
```rust
// Lines 4-34 (31 LOC | Complexity 3) | used by 0 callers | [Io, PotentialDeadCode]
def compile_blueprints()
//  â³ Calls: compile_blueprints, SduiStateVault.dump, SduiBlockRegistry.load
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_list_view.dart (42 lines)

#### SduiListView.build (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiListView (Class)
```rust
// Lines 9-49 (41 LOC | Complexity 1) | used by 0 callers
class SduiListView extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.maxHeight, BoundedRouteHistory.isEmpty, _SduiShimmerLoaderState.padding, SduiListView
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_checkbox.dart (198 lines)

#### _SduiCheckboxState.dispose (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiCheckboxState (Class)
```rust
// Lines 23-202 (180 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiCheckboxState extends ConsumerState<SduiCheckbox>
//  â³ Calls: SduiCheckbox, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, ShuaSyncQueue.payload, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, dispose, _SduiCheckboxState.didUpdateWidget, SduiNode.contentVal, initState
//  â³ Called by: SduiCheckbox.createState, _SduiCheckboxState, SduiCheckbox.createState
```

#### _SduiCheckboxState.didUpdateWidget (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiCheckbox oldWidget)
//  â³ Calls: SduiCheckbox
//  â³ Called by: _SduiCheckboxState
```

#### _SduiCheckboxState.initState (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SduiCheckbox.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiCheckbox> createState()
//  â³ Calls: SduiCheckbox, _SduiCheckboxState
```

#### SduiCheckbox (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 9 callers
class SduiCheckbox extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiCheckboxState.didUpdateWidget, _SduiCheckboxState, SduiCheckbox.createState, _SduiCheckboxState.didUpdateWidget, _SduiCheckboxState, SduiCheckbox.createState, SduiRegistry, SduiTypeRegistry, SduiCheckbox
```

#### _SduiCheckboxState.build (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\config_provider.dart (132 lines)

#### ConfigState (Class)
```rust
// Lines 8-38 (31 LOC | Complexity 1) | used by 3 callers
class ConfigState
//  â³ Calls: ConfigNotifier, ConfigProvider.geminiApiKey
//  â³ Called by: ConfigNotifier.build, ConfigState.copyWith, ConfigNotifier
```

#### ConfigNotifier.updateOllamaUrl (Function)
```rust
// Lines 106-106 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateOllamaUrl(String url)
//  â³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier.updateSyncBaseUrl (Function)
```rust
// Lines 101-101 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateSyncBaseUrl(String url)
//  â³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier (Class)
```rust
// Lines 40-125 (86 LOC | Complexity 1) | used by 1 callers
class ConfigNotifier extends Notifier<ConfigState>
//  â³ Calls: ConfigNotifier._saveConfig, ConfigState.copyWith, log, ConfigProvider.geminiApiKey, ConfigState, ConfigNotifier._loadConfig
//  â³ Called by: ConfigState
```

#### ConfigNotifier.updateOllamaModel (Function)
```rust
// Lines 111-111 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateOllamaModel(String model)
//  â³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier.build (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConfigState build()
//  â³ Calls: ConfigState, build
```

#### ConfigNotifier.updateGeminiApiKey (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateGeminiApiKey(String key)
//  â³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier._saveConfig (Function)
```rust
// Lines 79-79 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _saveConfig()
//  â³ Called by: ConfigNotifier
```

#### ConfigState.copyWith (Function)
```rust
// Lines 23-29 (7 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ConfigState copyWith(
//  â³ Calls: ConfigState, ConfigProvider.geminiApiKey
//  â³ Called by: ConfigNotifier
```

#### ConfigNotifier._loadConfig (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadConfig()
//  â³ Called by: ConfigNotifier
```

#### ConfigNotifier.updateWorkspaceRoot (Function)
```rust
// Lines 121-121 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateWorkspaceRoot(String root)
//  â³ Called by: _NetworkConfigCardState
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\theme_seeds.dart (20 lines)

#### AppThemeSeeds (Class)
```rust
// Lines 11-24 (14 LOC | Complexity 1) | used by 1 callers
class AppThemeSeeds
//  â³ Calls: ThemeSeedOption
//  â³ Called by: SettingsPage
```

#### ThemeSeedOption (Class)
```rust
// Lines 3-8 (6 LOC | Complexity 1) | used by 1 callers
class ThemeSeedOption
//  â³ Called by: AppThemeSeeds
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\training\train_kwh.py (270 lines)

#### KWHDataset._augment (Function)
```rust
// Lines 74-94 (21 LOC | Complexity 5) | used by 0 callers | [Pure, PotentialDeadCode]
def _augment(self, img)
```

#### KWHDataset.__init__ (Function)
```rust
// Lines 67-69 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __init__(self, samples: List[Tuple[str, str]], augment: bool = False)
```

#### KWHDataset (Class)
```rust
// Lines 66-122 (57 LOC | Complexity 1) | used by 1 callers
class KWHDataset(Dataset)
//  â³ Called by: train
```

#### KWHDataset.__getitem__ (Function)
```rust
// Lines 96-122 (27 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __getitem__(self, idx)
//  â³ Calls: _augment
```

#### _collate_fn (Function)
```rust
// Lines 124-138 (15 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _collate_fn(batch)
```

#### _full_string_accuracy (Function)
```rust
// Lines 143-145 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _full_string_accuracy(preds: List[str], truths: List[str]) -> float
```

#### train (Function)
```rust
// Lines 150-277 (128 LOC | Complexity 8) | used by 0 callers | [Io, Tested, PotentialDeadCode]
def train(epochs: int = 150)
//  â³ Calls: _full_string_accuracy, ctc_greedy_decode, train, SduiBlockRegistry.load, CRNN, KWHDataset, load_kwh_samples
```

#### KWHDataset.__len__ (Function)
```rust
// Lines 71-72 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def __len__(self)
```

#### load_kwh_samples (Function)
```rust
// Lines 51-64 (14 LOC | Complexity 4) | used by 1 callers | [Io]
def load_kwh_samples() -> List[Tuple[str, str]]
//  â³ Calls: train, c, RadixTrie.insert
//  â³ Called by: train
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\training\train_ocr.py (256 lines)

#### _preprocess_crop (Function)
```rust
// Lines 62-80 (19 LOC | Complexity 2) | used by 6 callers | [Pure]
def _preprocess_crop(img_bgr: np.ndarray) -> np.ndarray
//  â³ Calls: train, RadixTrie.insert
//  â³ Called by: OCRReviewerApp.load_model_and_data, test, SerialOCRDataset.__getitem__, run_confidence_audit, SerialOCRDataset.__getitem__, SerialOCRDataset.__init__
```

#### _encode_label (Function)
```rust
// Lines 82-83 (2 LOC | Complexity 1) | used by 3 callers | [Pure]
def _encode_label(text: str) -> list[int]
//  â³ Called by: SerialOCRDataset.__getitem__, SerialOCRDataset.__getitem__, SerialOCRDataset.__init__
```

#### SerialOCRDataset.__init__ (Function)
```rust
// Lines 93-111 (19 LOC | Complexity 4) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
def __init__(self, samples: list[tuple], is_training: bool = True, preload_ram: bool = True)
//  â³ Calls: _encode_label, _preprocess_crop
```

#### SerialOCRDataset.__getitem__ (Function)
```rust
// Lines 116-132 (17 LOC | Complexity 4) | used by 0 callers | [MutatesState, PotentialDeadCode]
def __getitem__(self, idx)
//  â³ Calls: _encode_label, _preprocess_crop
```

#### SerialOCRDataset.__len__ (Function)
```rust
// Lines 113-114 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def __len__(self)
```

#### _char_accuracy (Function)
```rust
// Lines 159-165 (7 LOC | Complexity 3) | used by 4 callers | [Pure]
def _char_accuracy(preds: list[str], targets: list[str]) -> float
//  â³ Calls: levenshtein_distance
//  â³ Called by: train, _compute_detailed_metrics, train, train
```

#### train (Function)
```rust
// Lines 190-301 (112 LOC | Complexity 14) | used by 0 callers | [Io, Tested, PotentialDeadCode]
def train(epochs: int = 100, use_synthetic: bool = True, is_finetuning: bool = False)
//  â³ Calls: _full_string_accuracy, _char_accuracy, ctc_greedy_decode, train, SduiBlockRegistry.load, CRNN, SerialOCRDataset, load_samples
```

#### _collate (Function)
```rust
// Lines 134-139 (6 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _collate(batch)
```

#### _full_string_accuracy (Function)
```rust
// Lines 167-168 (2 LOC | Complexity 1) | used by 5 callers | [Pure]
def _full_string_accuracy(preds: list[str], targets: list[str]) -> float
//  â³ Called by: train, _compute_detailed_metrics, train, train, train
```

#### load_samples (Function)
```rust
// Lines 170-185 (16 LOC | Complexity 4) | used by 3 callers | [Io]
def load_samples(source_dir) -> list[tuple]
//  â³ Called by: test, train, train
```

#### SerialOCRDataset (Class)
```rust
// Lines 92-132 (41 LOC | Complexity 1) | used by 3 callers
class SerialOCRDataset(Dataset)
//  â³ Called by: train, train, train
```

#### levenshtein_distance (Function)
```rust
// Lines 145-157 (13 LOC | Complexity 5) | used by 3 callers | [Pure]
def levenshtein_distance(s1: str, s2: str) -> int
//  â³ Called by: _char_accuracy, levenshtein_distance, _char_accuracy
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\ai\tailor_test.go (59 lines)

#### TestFilterResume (Function)
```rust
// Lines 33-68 (36 LOC | Complexity 5) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
func TestFilterResume(t *testing.T)
//  â³ Calls: ProjectItem, WorkItem, ResumeMatrix, DefaultTailorConfig, FilterResume
```

#### TestJaccardSimilarity (Function)
```rust
// Lines 20-31 (12 LOC | Complexity 2) | used by 0 callers | [MutatesState, Tested, PotentialDeadCode]
func TestJaccardSimilarity(t *testing.T)
//  â³ Calls: JaccardSimilarity
```

#### TestTokenize (Function)
```rust
// Lines 8-18 (11 LOC | Complexity 3) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
func TestTokenize(t *testing.T)
//  â³ Calls: Tokenize
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\gemini_generator_provider.ts (266 lines)

#### GeminiGeneratorProvider.constructor (Function)
```rust
// Lines 5-9 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: AiRateLimiter
```

#### GeminiGeneratorProvider.generateFromNotes (Function)
```rust
// Lines 11-77 (67 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async generateFromNotes(rawNotes: string, style: string): Promise<DiaryBlueprint>
//  â³ Calls: DiaryBlueprint, AiRateLimiter.execute, Error
```

#### GeminiGeneratorProvider (Class)
```rust
// Lines 4-138 (135 LOC | Complexity 1) | used by 1 callers
class GeminiGeneratorProvider implements IDiaryGeneratorProvider
//  â³ Calls: IDiaryGeneratorProvider
//  â³ Called by: DiaryAiSession.create
```

#### GeminiGeneratorProvider.generateFromNotesStream (Function)
```rust
// Lines 79-137 (59 LOC | Complexity 8) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>
//  â³ Calls: AiRateLimiter.execute, Error
```

### C:\horAIzon_2.0\scripts\test_parser.py (44 lines)

#### main (Function)
```rust
// Lines 3-46 (44 LOC | Complexity 5) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main
```

### C:\horAIzon_2.0\shua_governor\src\logging\listener.rs (184 lines)

#### read_until_newline (Function)
```rust
// Lines 190-202 (13 LOC | Complexity 4) | used by 2 callers | [Async, MutatesState, Io]
async fn read_until_newline<R>(reader: &mut R, buf: &mut Vec<u8>) -> std::io::Result<usize>
//  â³ Called by: harvest_socket_stream, harvest_pipe
```

#### harvest_socket_stream (Function)
```rust
// Lines 88-174 (87 LOC | Complexity 13) | used by 1 callers | [Async, MutatesState, Io]
async fn harvest_socket_stream<S>(stream: S, log_tx: mpsc::Sender<LogEntry>)
//  â³ Calls: BorrowedLogEntry, LogEntry, read_until_newline, wrap_socket_raw_line, log_min_level
//  â³ Called by: start_log_ipc_listener
```

#### start_log_ipc_listener (Function)
```rust
// Lines 16-86 (71 LOC | Complexity 12) | used by 1 callers | [Async, Io]
pub async fn start_log_ipc_listener(log_tx: mpsc::Sender<LogEntry>)
//  â³ Calls: LogEntry, harvest_socket_stream
//  â³ Called by: main
```

#### wrap_socket_raw_line (Function)
```rust
// Lines 176-188 (13 LOC | Complexity 1) | used by 1 callers | [Io]
fn wrap_socket_raw_line(line: &str) -> LogEntry
//  â³ Calls: LogEntry
//  â³ Called by: harvest_socket_stream
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\python_semantics_analyzer_provider.ts (98 lines)

#### PythonSemanticsAnalyzerProvider.constructor (Function)
```rust
// Lines 7-7 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(private pythonScriptPath: string) {}
```

#### PythonSemanticsAnalyzerProvider (Class)
```rust
// Lines 3-54 (52 LOC | Complexity 1) | used by 1 callers
class PythonSemanticsAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: DiaryAiSession.create
```

#### PythonSemanticsAnalyzerProvider.analyze (Function)
```rust
// Lines 9-53 (45 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, FrameworkInvoked, TraitMethod, Tested]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, Error, ConfigProvider.pythonScriptPath
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_state_vault.ts (35 lines)

#### SduiStateVault.constructor (Function)
```rust
// Lines 4-4 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
constructor() {}
```

#### SduiStateVault.get (Function)
```rust
// Lines 6-8 (3 LOC | Complexity 1) | used by 2 callers | [Pure]
public get(id: string): any
//  â³ Called by: SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners
```

#### SduiStateVault.clear (Function)
```rust
// Lines 18-20 (3 LOC | Complexity 1) | used by 10 callers | [Pure, Tested]
public clear(): void
//  â³ Called by: _SduiListEditorState, _DiaryListScreenState, _SduiDrawingPadState, _JoshCoPilotPanelState, SduiBlueprintLoader.invalidateAll, _SduiJbcPanelState, SduiEventDispatcher, _SduiListEditorState, SduiSocketManager, _SduiTerminalState
```

#### SduiStateVault.dump (Function)
```rust
// Lines 14-16 (3 LOC | Complexity 1) | used by 8 callers | [Pure, Tested]
public dump(): Record<string, any>
//  â³ Called by: main, main, extract_blueprints, train, compile_mock_blueprints, delete_primitive, request_primitive, compile_blueprints
```

#### SduiStateVault (Class)
```rust
// Lines 0-21 (22 LOC | Complexity 1) | used by 0 callers
class SduiStateVault
//  â³ Calls: SduiStateVault
```

#### SduiStateVault.set (Function)
```rust
// Lines 10-12 (3 LOC | Complexity 1) | used by 4 callers | [Pure]
public set(id: string, value: any): void
//  â³ Called by: SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, SduiOrchestrator.updateSession, SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\public\app.js (78 lines)

#### getColor (Function)
```rust
// Lines 32-42 (11 LOC | Complexity 7) | used by 0 callers | [Pure, PotentialDeadCode]
const getColor = (d) =>
//  â³ Calls: showDetails, isConnected, drag
```

#### isConnected (Function)
```rust
// Lines 126-131 (6 LOC | Complexity 4) | used by 1 callers | [Pure]
function isConnected(a, b)
//  â³ Called by: getColor
```

#### showDetails (Function)
```rust
// Lines 171-214 (44 LOC | Complexity 3) | used by 1 callers | [Pure]
function showDetails(node, allLinks)
//  â³ Calls: filter, RadixTrie.remove
//  â³ Called by: getColor
```

#### drag (Function)
```rust
// Lines 152-168 (17 LOC | Complexity 3) | used by 1 callers | [Pure, FrameworkInvoked]
function drag(simulation)
//  â³ Called by: getColor
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\rate_limiter.ts (103 lines)

#### AiRateLimiter.constructor (Function)
```rust
// Lines 23-27 (5 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor(private rpmCeiling: number = 15, private burstMax: number = 5)
```

#### AiRateLimiter.execute (Function)
```rust
// Lines 48-71 (24 LOC | Complexity 3) | used by 6 callers | [Async, MutatesState, Io, Tested]
async execute<T>(task: () => Promise<T>): Promise<T>
//  â³ Calls: warn, AiRateLimiter.refill
//  â³ Called by: GeminiJbcProvider.generateSummary, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, GeminiAnalyzerProvider.analyze, GeminiGeneratorProvider.generateFromNotesStream, GeminiGeneratorProvider.generateFromNotes
```

#### AiRateLimiter (Class)
```rust
// Lines 11-72 (62 LOC | Complexity 1) | used by 4 callers
class AiRateLimiter
//  â³ Called by: GeminiJbcProvider.constructor, GeminiAnalyzerProvider.constructor, GeminiGeneratorProvider.constructor, DiaryAiSession
```

#### AiRateLimiter.refill (Function)
```rust
// Lines 32-43 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
private refill(): void
//  â³ Called by: AiRateLimiter.execute
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\AnalyzerService.ts (99 lines)

#### AnalyzerService.getProvider (Function)
```rust
// Lines 9-23 (15 LOC | Complexity 4) | used by 1 callers | [MutatesState]
private getProvider(): IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider, OllamaAnalyzerProvider, PythonFallbackProvider, GeminiAnalyzerProvider
//  â³ Called by: AnalyzerService.analyze
```

#### AnalyzerService (Class)
```rust
// Lines 6-60 (55 LOC | Complexity 1) | used by 2 callers
class AnalyzerService
//  â³ Calls: IAnalyzerProvider, PythonFallbackProvider
//  â³ Called by: AnalysisWorker, DiaryBlockPayload
```

#### AnalyzerService.analyze (Function)
```rust
// Lines 31-59 (29 LOC | Complexity 3) | used by 2 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, Tested]
async analyze(content: string, onProgress?: (data: string) => void): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, Error, warn, IAnalyzerProvider.analyze, log, AnalyzerService.getProvider
//  â³ Called by: AnalysisWorker._processNext, DiaryBlockPayload
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_jbc_panel.dart (577 lines)

#### _SduiJbcPanelState (Class)
```rust
// Lines 59-574 (516 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiJbcPanelState extends ConsumerState<SduiJbcPanel>
//  â³ Calls: SduiNode, SduiJbcPanel, _SduiJbcPanelState._sendMessage, _SduiJbcPanelState._acceptMutations, _SduiJbcPanelState._buildVisualDiff, DiaryRepository.close, _SduiShimmerLoaderState.padding, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, ShuaDiaryBlocks.entryId, SduiSocketManager.sendRpcWithResponse, _SduiJbcPanelState._extractCurrentBlocks, log, JbcMessage.copyWith, BorrowedLogEntry::deserialize, LogEntry::from, _SduiJbcPanelState._scrollToBottom, SduiStateVault.clear, BoundedRouteHistory.isEmpty, ShuaDiaryBlocks.content, SduiNode.behavior, ShuaDiaryBlocks.blockType, c, SduiSocketManager.socketForScreen, dispose, _SduiJbcPanelState._cleanupActiveStream, JbcMessage, initState
//  â³ Called by: SduiJbcPanel.createState
```

#### _SduiJbcPanelState.dispose (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiJbcPanel (Class)
```rust
// Lines 43-57 (15 LOC | Complexity 1) | used by 3 callers
class SduiJbcPanel extends ConsumerStatefulWidget
//  â³ Calls: SduiNode, ShuaDiaryBlocks.entryId
//  â³ Called by: _SduiJbcPanelState, SduiJbcPanel.createState, _SduiScreenState
```

#### _SduiJbcPanelState._extractCurrentBlocks (Function)
```rust
// Lines 92-92 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<Map<String, dynamic>> _extractCurrentBlocks()
//  â³ Called by: _SduiJbcPanelState
```

#### JbcMessage.copyWith (Function)
```rust
// Lines 27-32 (6 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
JbcMessage copyWith(
//  â³ Calls: JbcMessage
//  â³ Called by: _SduiJbcPanelState
```

#### JbcMessage (Class)
```rust
// Lines 12-41 (30 LOC | Complexity 1) | used by 2 callers
class JbcMessage
//  â³ Called by: JbcMessage.copyWith, _SduiJbcPanelState
```

#### _SduiJbcPanelState._cleanupActiveStream (Function)
```rust
// Lines 84-84 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _cleanupActiveStream()
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState.initState (Function)
```rust
// Lines 67-67 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiJbcPanelState.build (Function)
```rust
// Lines 403-403 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiJbcPanel.createState (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiJbcPanel> createState()
//  â³ Calls: SduiJbcPanel, _SduiJbcPanelState
```

#### _SduiJbcPanelState._scrollToBottom (Function)
```rust
// Lines 147-147 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _scrollToBottom()
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._buildVisualDiff (Function)
```rust
// Lines 303-303 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildVisualDiff(List<dynamic> mutations)
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._acceptMutations (Function)
```rust
// Lines 263-263 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _acceptMutations(List<dynamic> mutations)
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._sendMessage (Function)
```rust
// Lines 159-159 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _sendMessage()
//  â³ Called by: _SduiJbcPanelState
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\handlers\sdui_blueprint_loader.go (130 lines)

#### hydrateString (Function)
```rust
// Lines 126-143 (18 LOC | Complexity 6) | used by 2 callers | [MutatesState]
func hydrateString(str string, ctx map[string]interface{}) interface{}
//  â³ Called by: hydrateValue, SduiNodeBuilder.hydrateNode
```

#### hydrateValue (Function)
```rust
// Lines 50-124 (75 LOC | Complexity 19) | used by 1 callers | [MutatesState]
func hydrateValue(node interface{}, ctx map[string]interface{}) interface{}
//  â³ Calls: hydrateString
//  â³ Called by: LoadAndHydrateBlueprint
```

#### LoadAndHydrateBlueprint (Function)
```rust
// Lines 12-48 (37 LOC | Complexity 14) | used by 2 callers | [MutatesState, Io, Tested]
func LoadAndHydrateBlueprint(screenId string, ctx map[string]interface{}) (interface{}, error)
//  â³ Calls: hydrateValue
//  â³ Called by: assembleScreen, main
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry.rs (284 lines)

#### compute_cyclomatic_complexity (Function)
```rust
// Lines 52-146 (95 LOC | Complexity 22) | used by 5 callers | [MutatesState, HighComplexity]
fn compute_cyclomatic_complexity(source: &[u8], lang: Language, node: tree_sitter::Node) -> u32
//  â³ Calls: Language, walk
//  â³ Called by: TypeScriptExtractor::extract, PythonExtractor::extract, GoExtractor::extract, RustExtractor::extract, DartExtractor::extract
```

#### extract_declarations (Function)
```rust
// Lines 15-46 (32 LOC | Complexity 7) | used by 1 callers | [CanPanic]
pub fn extract_declarations(
//  â³ Calls: DeclarationExtractor, SymbolNode, AppState, Language, log_verbose
//  â³ Called by: parse_and_index_file
```

#### walk (Function)
```rust
// Lines 55-142 (88 LOC | Complexity 22) | used by 12 callers | [MutatesState, CorePrimitive, HighComplexity]
fn walk(node: tree_sitter::Node, lang: Language, source: &[u8], count: &mut u32)
//  â³ Calls: Language
//  â³ Called by: _scan_images, find_latest_weights, main, find_string_literal, _scan_images, StandaloneWebAppHandler.do_POST, StandaloneWebAppHandler.do_POST, main, main, _scan_images, compute_cyclomatic_complexity, get_text_body
```

#### infer_side_effects (Function)
```rust
// Lines 148-213 (66 LOC | Complexity 17) | used by 5 callers | [Async, MutatesState, Io, CanPanic]
fn infer_side_effects(source_text: &str, language: Language) -> Vec<SymbolTag>
//  â³ Calls: SymbolTag, Language, SduiIconRegistry.contains
//  â³ Called by: TypeScriptExtractor::extract, PythonExtractor::extract, GoExtractor::extract, RustExtractor::extract, DartExtractor::extract
```

#### DeclarationExtractor (Trait)
```rust
// Lines 48-50 (3 LOC | Complexity 1) | used by 1 callers
trait DeclarationExtractor
//  â³ Calls: SymbolNode, AppState
//  â³ Called by: extract_declarations
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_time_picker.dart (395 lines)

#### SduiTimePicker (Class)
```rust
// Lines 9-393 (385 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiTimePicker extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiEventDispatcher.onStateChange, SduiTimePicker._buildThemeData, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiTimePicker._pickTime, SduiIconRegistry.contains, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiTimePicker._pickTime (Function)
```rust
// Lines 250-257 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _pickTime(
//  â³ Called by: SduiTimePicker
```

#### SduiTimePicker._buildThemeData (Function)
```rust
// Lines 331-331 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildThemeData(BuildContext context, Widget? child, Color accentColor)
//  â³ Called by: SduiTimePicker
```

#### SduiTimePicker.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_carousel.dart (386 lines)

#### SduiCarousel (Class)
```rust
// Lines 43-55 (13 LOC | Complexity 1) | used by 3 callers
class SduiCarousel extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiCarouselState, SduiCarousel.createState, SduiTypeRegistry
```

#### _SduiCarouselState._boolBehavior (Function)
```rust
// Lines 159-159 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool _boolBehavior(int key, {required bool defaultValue})
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._doubleBehavior (Function)
```rust
// Lines 167-167 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double _doubleBehavior(int key, {required double defaultValue})
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState.dispose (Function)
```rust
// Lines 92-92 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiCarouselState._onPageChanged (Function)
```rust
// Lines 148-148 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onPageChanged(int page)
//  â³ Called by: _SduiCarouselState
```

#### SduiCarousel.createState (Function)
```rust
// Lines 54-54 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiCarousel> createState()
//  â³ Calls: SduiCarousel, _SduiCarouselState
```

#### _SduiCarouselState._stopAutoScroll (Function)
```rust
// Lines 144-144 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _stopAutoScroll()
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._resolveController (Function)
```rust
// Lines 102-102 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
PageController _resolveController(double peekExtent, double screenWidth)
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState.initState (Function)
```rust
// Lines 78-78 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiCarouselState (Class)
```rust
// Lines 57-404 (348 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiCarouselState extends ConsumerState<SduiCarousel>
//  â³ Calls: SduiCarousel, generate, SduiBlockRegistry.all, _SduiShimmerLoaderState.borderRadius, _SduiCarouselState._buildDotIndicators, _SduiCarouselState._buildArrowButton, SduiRenderer, _SduiCarouselState._onPageChanged, _SduiCarouselState._stopAutoScroll, _SduiCarouselState._startAutoScroll, _SduiCarouselState._resolveController, _SduiCarouselState._buildEmpty, SduiStyleResolver.resolveColor, _SduiCarouselState._boolBehavior, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, _SduiShimmerLoaderState.padding, _SduiCarouselState._doubleBehavior, SduiFlexContext.of, SduiEventDispatcher.onStateChange, dispose, SduiNode.contentVal, SduiNode.behavior, initState
//  â³ Called by: SduiCarousel.createState
```

#### _SduiCarouselState._startAutoScroll (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _startAutoScroll(int intervalMs, int pageCount)
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._buildEmpty (Function)
```rust
// Lines 363-367 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmpty(
//  â³ Calls: _SduiShimmerLoaderState.padding
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._buildArrowButton (Function)
```rust
// Lines 312-316 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildArrowButton(
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._buildDotIndicators (Function)
```rust
// Lines 337-341 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildDotIndicators(
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState.build (Function)
```rust
// Lines 176-176 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\scripts\ocr_diagnostics.py (173 lines)

#### run_aspect_audit (Function)
```rust
// Lines 56-77 (22 LOC | Complexity 3) | used by 1 callers | [Io]
def run_aspect_audit()
//  â³ Calls: _load_data
//  â³ Called by: main
```

#### _load_data (Function)
```rust
// Lines 38-53 (16 LOC | Complexity 4) | used by 3 callers | [Io]
def _load_data()
//  â³ Calls: main, RadixTrie.insert
//  â³ Called by: run_width_audit, run_confidence_audit, run_aspect_audit
```

#### main (Function)
```rust
// Lines 201-218 (18 LOC | Complexity 5) | used by 0 callers | [Pure, EntryPoint]
def main()
//  â³ Calls: run_width_audit, run_confidence_audit, run_aspect_audit
```

#### run_confidence_audit (Function)
```rust
// Lines 80-152 (73 LOC | Complexity 14) | used by 1 callers | [Io]
def run_confidence_audit()
//  â³ Calls: _preprocess_crop, load_ocr_model, _load_data
//  â³ Called by: main
```

#### run_width_audit (Function)
```rust
// Lines 155-198 (44 LOC | Complexity 6) | used by 1 callers | [Io]
def run_width_audit()
//  â³ Calls: _load_data
//  â³ Called by: main
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_node.dart (220 lines)

#### SduiNode.SduiNode (Function)
```rust
// Lines 179-179 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiNode
```

#### SduiNode.contentVal (Function)
```rust
// Lines 88-88 (1 LOC | Complexity 1) | used by 40 callers | [Pure, CorePrimitive]
T? contentVal<T>(int key)
//  â³ Called by: SduiButton, _SduiCodeEditorState, _SduiTableState, _SduiTableState._headerLabel, _SduiTableState._initialContent, _SduiOrdinalSliderState, _SduiListEditorState, _SduiListEditorState._itemHintText, _SduiListEditorState._headerLabel, _SduiListEditorState._initialContent, _SduiCheckboxState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, SduiStlViewer, _SduiDrawingPadState, _SduiChartState, SduiTimePicker, SduiListView, SduiGauge, SduiHeatmap, _SduiVideoState, SduiProgressBar, SduiModuleCard, _SduiSliderState, SduiGridView, _SduiAudioState, SduiToggle, _SduiRadioState, _SduiScreenState, _SduiDropdownState, SduiChip, _SduiTextInputState, SduiImage, _SduiDocumentViewerState, _SduiCarouselState, _SduiMapState, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState
```

#### SduiNode (Class)
```rust
// Lines 6-220 (215 LOC | Complexity 1) | used by 101 callers | [CorePrimitive, HighComplexity]
@immutable
//  â³ Calls: SduiNode.fromJson, c, LogEntry::from, SduiNode.interpolate, log, ShuaDiaryBlocks.content
//  â³ Called by: SduiButton, SduiNode.interpolate, SduiCodeEditor, SduiTable, SduiOrdinalSlider, SduiListEditor, _SduiContainerState._findDragHandleIndex, _SduiContainerState._buildReorderableItem, _SduiContainerState, SduiContainer, SduiCheckbox, _SduiSandboxScreenState._parseLegacyV4Format, _SduiSandboxScreenState._loadBlueprints, SduiDivider, SduiExpansionTile, SduiDatePicker, SduiHtmlViewer, SduiStlViewer, SduiDrawingPad, SduiChart, SduiTimePicker, SduiListView, SduiGauge, SduiNode::with_child, SduiNode, SduiHeatmap, SduiVideo, SduiProgressBar, SduiSpacer, SduiSlider, SduiGridView, SduiTransport._nodeFromMap, SduiTransport._parseList, SduiTransport._patchNodeInTree, SduiTransport._insertAfterRecursive, SduiTransport._insertAfterInTree, SduiTransport._removeNodeFromTree, SduiTransport.applyDelta, SduiTransport.patch, SduiTransport.decodeJson, SduiTransport.decode, SduiAudio, SduiToggle, SduiRadio, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, _SduiScreenState._findNodeByIdSuffix, _SduiScreenState._onFullReplace, SduiDropdown, SduiChip, _SduiJbcPanelState, SduiJbcPanel, SduiTextInput, SduiImage, SduiWrap, _DashboardScreenState, SduiRenderer, SduiSocketManager.listenForReplace, SduiSocketManager.getScreen, SduiSocketManager.requestScreen, SduiSocketManager, SduiDocumentViewer, SduiUnknownNode, SduiShuaGridNode, SduiRadialGaugeNode, SduiDonutChartNode, SduiBarChartNode, SduiLineChartNode, SduiEmptyStateNode, SduiErrorStateNode, SduiShimmerLoaderNode, SduiChipNode, SduiProgressBarNode, SduiSliderNode, SduiSwitchNode, SduiSpacerNode, SduiDividerNode, SduiTextFieldNode, SduiButtonNode, SduiIconNode, SduiTextNode, SduiNode.parseChildren, SduiCarousel, SduiTypeRegistry.buildNode, SduiShimmerLoader, SduiMap, SduiTerminal, SduiTimeline, SduiMarkdownEditor, SduiNode.SduiNode, _SduiSandboxScreenState, _SduiDashboardScreenState, SduiModuleCard, SduiTransport, _SduiScreenState, SduiCardNode, SduiColumnNode, SduiRowNode, SduiContainerNode, SduiNode.SduiNode, SduiNode
```

#### SduiNode.interpolate (Function)
```rust
// Lines 134-134 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode interpolate(Map<String, dynamic> context)
//  â³ Calls: SduiNode
//  â³ Called by: SduiNode
```

#### SduiNode.fromJson (Function)
```rust
// Lines 179-179 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â³ Called by: SduiNode, SduiNode.SduiNode
```

#### SduiNode.behavior (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 72 callers | [Pure, CorePrimitive]
T? behavior<T>(int key)
//  â³ Called by: SduiButton, _SduiCodeEditorState, _SduiTableState._bindKey, _SduiTableState, _SduiOrdinalSliderState, _SduiListEditorState._bindKey, _SduiListEditorState, _SduiMarkdownEditorState, _JoshAutomatedGenerationDialogState, _SduiCheckboxState, SduiRegistry._buildShimmerLoader, SduiRegistry._buildGridView, SduiRegistry._buildListView, SduiRegistry._buildProgressBar, SduiRegistry._buildContainer, SduiRegistry._buildRow, SduiRegistry._buildColumn, SduiRegistry._buildButton, SduiRegistry._buildIcon, SduiRegistry._buildCodeEditor, SduiRegistry._buildHeading, SduiRegistry._buildMarkdownEditor, SduiRegistry._buildTextInput, SduiRegistry._buildIconButton, SduiRegistry._buildChip, SduiRegistry._buildSlider, SduiRegistry._buildTable, SduiRegistry._buildListEditor, SduiRegistry._buildOrdinalSlider, SduiRegistry, _SduiDividerState, _SduiExpansionTileState, SduiDatePicker, _SduiHtmlViewerState, SduiStlViewer, _SduiHeadingState, _SduiDrawingPadState, _SduiCodeEditorState, _SduiChartState, SduiTimePicker, SduiListView, SduiGauge, SduiHeatmap, _SduiVideoState, SduiProgressBar, _SduiSpacerState, _SduiSliderState, SduiGridView, _SduiAudioState, SduiToggle, _SduiRadioState, _SduiDropdownState, SduiChip, _SduiJbcPanelState, _SduiTextInputState, _SduiTextInputState._bindKey, SduiImage, _SduiWrapState, _SduiDocumentViewerState, _SduiQuoteState, _SduiCarouselState, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.shimmerAnimStyle, _SduiShimmerLoaderState.shimmerType, _SduiMapState, _SduiTerminalState, _SduiTimelineState, _SduiMarkdownEditorState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_html_viewer.dart (562 lines)

#### _SduiHtmlViewerState.dispose (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiHtmlViewerState._buildErrorState (Function)
```rust
// Lines 517-522 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildErrorState(
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState.didUpdateWidget (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiHtmlViewer oldWidget)
//  â³ Calls: SduiHtmlViewer
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState._buildUploadBox (Function)
```rust
// Lines 444-449 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildUploadBox(
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState._loadHtmlFile (Function)
```rust
// Lines 65-65 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadHtmlFile(String src)
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState (Class)
```rust
// Lines 32-556 (525 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiHtmlViewerState extends ConsumerState<SduiHtmlViewer>
//  â³ Calls: SduiHtmlViewer, SduiEventDispatcher.onAction, _SduiHtmlViewerState._buildEmptyReadonly, _SduiHtmlViewerState._buildUploadBox, _SduiHtmlViewerState._buildErrorState, _SduiHtmlViewerState._showPicker, _SduiHtmlViewerState._loadHtmlFile, SduiIconRegistry.contains, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiEventDispatcher.onStateChange, MediaUploader.pickAndUploadWithUi, ShuaDiaryEntries.title, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiNode.behavior, SduiFlexContext.of, log, ShuaDiaryBlocks.content, dispose, _SduiHtmlViewerState.didUpdateWidget, SduiNode.contentVal, initState
//  â³ Called by: SduiHtmlViewer.createState
```

#### _SduiHtmlViewerState._buildEmptyReadonly (Function)
```rust
// Lines 484-488 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyReadonly(
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState.initState (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiHtmlViewerState.build (Function)
```rust
// Lines 173-173 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiHtmlViewer.createState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiHtmlViewer> createState()
//  â³ Calls: SduiHtmlViewer, _SduiHtmlViewerState
```

#### SduiHtmlViewer (Class)
```rust
// Lines 18-30 (13 LOC | Complexity 1) | used by 4 callers
class SduiHtmlViewer extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiHtmlViewerState.didUpdateWidget, _SduiHtmlViewerState, SduiHtmlViewer.createState, SduiTypeRegistry
```

#### _SduiHtmlViewerState._showPicker (Function)
```rust
// Lines 99-99 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context)
//  â³ Called by: _SduiHtmlViewerState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_chart.dart (487 lines)

#### _SduiChartState._formatPointsToText (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatPointsToText(List<SduiChartDataPoint> points)
//  â³ Calls: SduiChartDataPoint
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._buildEmptyState (Function)
```rust
// Lines 434-434 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._getRawDataString (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getRawDataString()
//  â³ Called by: _SduiChartState
```

#### SduiChartDataPoint.SduiChartDataPoint (Function)
```rust
// Lines 474-474 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiChartDataPoint.fromMap(Map<dynamic, dynamic> map)
//  â³ Calls: SduiChartDataPoint.fromMap, SduiChartDataPoint
```

#### _SduiChartState._parseFromTextLines (Function)
```rust
// Lines 144-144 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseFromTextLines(String text)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### SduiChart.createState (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiChart> createState()
//  â³ Calls: SduiChart, _SduiChartState
```

#### _SduiChartState.build (Function)
```rust
// Lines 172-172 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiChartState._buildSplineAreaChart (Function)
```rust
// Lines 340-340 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildSplineAreaChart(Color accentColor, ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._parseData (Function)
```rust
// Lines 99-99 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseData()
//  â³ Called by: _SduiChartState
```

#### _SduiChartState.dispose (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### _SduiChartState._buildCandlestickChart (Function)
```rust
// Lines 410-410 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildCandlestickChart(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### SduiChart (Class)
```rust
// Lines 14-26 (13 LOC | Complexity 1) | used by 4 callers
class SduiChart extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiChartState.didUpdateWidget, _SduiChartState, SduiChart.createState, SduiTypeRegistry
```

#### _SduiChartState._buildPieChart (Function)
```rust
// Lines 390-390 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildPieChart(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### SduiChartDataPoint.fromMap (Function)
```rust
// Lines 474-474 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiChartDataPoint.fromMap(Map<dynamic, dynamic> map)
//  â³ Called by: SduiChartDataPoint.SduiChartDataPoint, _SduiChartState
```

#### _SduiChartState._buildColumnChart (Function)
```rust
// Lines 369-369 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildColumnChart(Color accentColor, ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState.didUpdateWidget (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiChart oldWidget)
//  â³ Calls: SduiChart
//  â³ Called by: _SduiChartState
```

#### _SduiChartState (Class)
```rust
// Lines 28-455 (428 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiChartState extends ConsumerState<SduiChart>
//  â³ Calls: SduiChart, DiaryRepository.close, SduiEventDispatcher.onStateChange, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiChartState._buildSplineAreaChart, _SduiChartState._buildCandlestickChart, _SduiChartState._buildPieChart, _SduiChartState._buildColumnChart, _SduiChartState._buildEmptyState, ShuaDiaryEntries.title, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, BoundedRouteHistory.isEmpty, _SduiChartState._parseFromTextLines, _SduiChartState._formatPointsToText, SduiChartDataPoint.fromMap, SduiChartDataPoint, SduiNode.contentVal, SduiNode.behavior, dispose, _SduiChartState.didUpdateWidget, _SduiChartState._getRawDataString, _SduiChartState._parseData, initState
//  â³ Called by: SduiChart.createState
```

#### SduiChartDataPoint (Class)
```rust
// Lines 457-486 (30 LOC | Complexity 1) | used by 3 callers
class SduiChartDataPoint
//  â³ Calls: DiaryRepository.close
//  â³ Called by: _SduiChartState._formatPointsToText, SduiChartDataPoint.SduiChartDataPoint, _SduiChartState
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision_2\adapters\label_studio_ml_backend.py (150 lines)

#### MobileEdgeBackend.predict (Function)
```rust
// Lines 28-93 (66 LOC | Complexity 8) | used by 0 callers | [MutatesState, Io, Tested, PotentialDeadCode]
def predict(self, tasks, **kwargs)
```

#### MobileEdgeBackend (Class)
```rust
// Lines 18-93 (76 LOC | Complexity 1) | used by 0 callers
class MobileEdgeBackend(LabelStudioMLBase)
//  â³ Calls: run, RadixTrie.insert
```

#### MobileEdgeBackend.__init__ (Function)
```rust
// Lines 19-26 (8 LOC | Complexity 2) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
def __init__(self, **kwargs)
//  â³ Calls: MobileEdgeEngine.get_model, __init__
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\adapters\standalone_web_app.py (225 lines)

#### StandaloneWebAppHandler.log_message (Function)
```rust
// Lines 35-36 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def log_message(self, format, *args)
```

#### StandaloneWebAppHandler (Class)
```rust
// Lines 28-129 (102 LOC | Complexity 1) | used by 0 callers
class StandaloneWebAppHandler(BaseHTTPRequestHandler)
```

#### __init__ (Function)
```rust
// Lines 149-153 (5 LOC | Complexity 2) | used by 5 callers | [Pure]
def __init__(self, request, client_address, server, pre_warm=False)
//  â³ Calls: StandaloneWebAppHandler.get_model
//  â³ Called by: CRNN.__init__, YOLOMeterBackend.__init__, CRNN.__init__, MobileEdgeBackend.__init__, _HTMLTextExtractor.__init__
```

#### StandaloneWebAppHandler.do_POST (Function)
```rust
// Lines 49-129 (81 LOC | Complexity 9) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
def do_POST(self)
//  â³ Calls: MeterVisionEngine.process_image, StandaloneWebAppHandler.get_model, get_filename, walk, MessagePackCodec.encode
```

#### run_server (Function)
```rust
// Lines 131-146 (16 LOC | Complexity 2) | used by 0 callers | [Io, PotentialDeadCode]
def run_server(port=8085)
//  â³ Calls: StandaloneWebAppHandler
```

#### StandaloneWebAppHandler.do_GET (Function)
```rust
// Lines 38-47 (10 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
def do_GET(self)
//  â³ Calls: MessagePackCodec.encode
```

#### StandaloneWebAppHandler.get_model (Function)
```rust
// Lines 30-33 (4 LOC | Complexity 1) | used by 2 callers | [Pure]
def get_model(self)
//  â³ Calls: MeterVisionEngine.get_model, find_pretrained_weights, find_latest_weights
//  â³ Called by: __init__, StandaloneWebAppHandler.do_POST
```

#### _load_template (Function)
```rust
// Lines 20-24 (5 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def _load_template()
//  â³ Calls: run_server, _load_template, RadixTrie.insert
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_table.dart (352 lines)

#### _SduiTableState._bindKey (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _bindKey
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._onFocusChange (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFocusChange()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.build (Function)
```rust
// Lines 210-210 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### _SduiTableState.initState (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void initState()
//  â³ Calls: initState
```

#### _SduiTableState._saveCellEdit (Function)
```rust
// Lines 146-146 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveCellEdit()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._startCellEdit (Function)
```rust
// Lines 124-124 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _startCellEdit(int row, int col)
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._addColumn (Function)
```rust
// Lines 172-172 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _addColumn()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._saveMatrix (Function)
```rust
// Lines 112-112 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveMatrix()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._isReadOnly (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get _isReadOnly
//  â³ Calls: _SduiTableState._int
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._resolveAccentColor (Function)
```rust
// Lines 204-204 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveAccentColor(ThemeData theme)
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._removeRow (Function)
```rust
// Lines 182-182 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _removeRow()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._minRows (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _minRows
//  â³ Calls: _SduiTableState._int
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._initialContent (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _initialContent
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._headerLabel (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? get _headerLabel
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._colWidth (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double get _colWidth
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._removeColumn (Function)
```rust
// Lines 192-192 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _removeColumn()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._addRow (Function)
```rust
// Lines 158-158 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _addRow()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.dispose (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: dispose
```

#### SduiTable.createState (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiTable> createState()
//  â³ Calls: SduiTable, _SduiTableState
```

#### _SduiTableState._int (Function)
```rust
// Lines 46-46 (1 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
int? _int(int key)
//  â³ Called by: _SduiTableState._isReadOnly, _SduiTableState._minCols, _SduiTableState._minRows
```

#### SduiTable (Class)
```rust
// Lines 6-18 (13 LOC | Complexity 1) | used by 9 callers
class SduiTable extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTableState.didUpdateWidget, _SduiTableState, SduiTable.createState, _SduiTableState.didUpdateWidget, _SduiTableState, SduiTable.createState, SduiRegistry, SduiTable, SduiTypeRegistry
```

#### _SduiTableState.didUpdateWidget (Function)
```rust
// Lines 68-68 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiTable oldWidget)
//  â³ Calls: SduiTable
//  â³ Called by: _SduiTableState
```

#### _SduiTableState (Class)
```rust
// Lines 20-335 (316 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class _SduiTableState extends State<SduiTable>
//  â³ Calls: SduiTable, _SduiShimmerLoaderState.padding, _SduiTableState._startCellEdit, _SduiShimmerLoaderState.borderRadius, SduiBlockRegistry.all, _SduiTableState._colWidth, _SduiTableState._addColumn, _SduiTableState._removeColumn, _SduiTableState._addRow, _SduiTableState._removeRow, RadixTrie.remove, _SduiTableState._headerLabel, _SduiTableState._resolveAccentColor, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiTableState._minCols, _SduiTableState._minRows, RadixTrie.insert, generate, _SduiTableState._saveMatrix, _SduiTableState._isReadOnly, SduiEventDispatcher.onStateChange, _SduiTableState._bindKey, BoundedRouteHistory.isEmpty, ShuaSyncQueue.payload, dispose, SduiNode.contentVal, _SduiTableState.didUpdateWidget, _SduiTableState._saveCellEdit, _SduiTableState._onFocusChange, _SduiTableState._initialContent, _SduiTableState._parseContent, initState, SduiNode.behavior
//  â³ Called by: SduiTable.createState, _SduiTableState, SduiTable.createState
```

#### _SduiTableState._minCols (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _minCols
//  â³ Calls: _SduiTableState._int
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._parseContent (Function)
```rust
// Lines 84-84 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseContent(String payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: _SduiTableState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_date_picker.dart (372 lines)

#### SduiDatePicker._triggerPicker (Function)
```rust
// Lines 222-231 (10 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _triggerPicker(
//  â³ Called by: SduiDatePicker
```

#### SduiDatePicker.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Calls: build
```

#### SduiDatePicker (Class)
```rust
// Lines 9-367 (359 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiDatePicker extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiIconRegistry.contains, SduiEventDispatcher.onStateChange, SduiDatePicker._buildThemeData, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiDatePicker._triggerPicker, SduiDatePicker._formatDate, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiDatePicker._formatDate (Function)
```rust
// Lines 360-360 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatDate(DateTime date)
//  â³ Called by: SduiDatePicker
```

#### SduiDatePicker._buildThemeData (Function)
```rust
// Lines 283-283 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildThemeData(BuildContext context, Widget? child, Color accentColor)
//  â³ Called by: SduiDatePicker
```

### C:\horAIzon_2.0\shua_governor\src\proxy\handler.rs (34 lines)

#### get_client (Function)
```rust
// Lines 15-17 (3 LOC | Complexity 1) | used by 2 callers | [Pure]
fn get_client() -> &'static Client<HttpConnector, Body>
//  â³ Calls: build
//  â³ Called by: proxy_request, try_forward
```

#### proxy_request (Function)
```rust
// Lines 22-52 (31 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
pub async fn proxy_request(
//  â³ Calls: Response, get_client, RadixTrie.insert
//  â³ Called by: fallback_proxy_handler
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\fallback\PythonFallbackProvider.ts (86 lines)

#### PythonFallbackProvider.analyze (Function)
```rust
// Lines 5-46 (42 LOC | Complexity 6) | used by 0 callers | [Async, Pure, FrameworkInvoked, TraitMethod, Tested]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, Error
```

#### PythonFallbackProvider (Class)
```rust
// Lines 4-47 (44 LOC | Complexity 1) | used by 2 callers
class PythonFallbackProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: AnalyzerService, AnalyzerService.getProvider
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\scripts\compare_dataset_stats.py (209 lines)

#### analyze_json (Function)
```rust
// Lines 40-110 (71 LOC | Complexity 17) | used by 1 callers | [Pure]
def analyze_json(json_path)
//  â³ Calls: SduiBlockRegistry.load
//  â³ Called by: main
```

#### main (Function)
```rust
// Lines 165-233 (69 LOC | Complexity 10) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: generate_graphs, analyze_json, find_all_exports
```

#### generate_graphs (Function)
```rust
// Lines 112-163 (52 LOC | Complexity 4) | used by 1 callers | [Pure]
def generate_graphs(stats, all_classes, graph_path)
//  â³ Calls: DiaryRepository.close, plot
//  â³ Called by: main
```

#### find_all_exports (Function)
```rust
// Lines 22-38 (17 LOC | Complexity 7) | used by 1 callers | [Pure]
def find_all_exports()
//  â³ Calls: main, RadixTrie.insert
//  â³ Called by: main
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\utils\binary_lexo_rank.dart (100 lines)

#### BinaryLexoRank.before (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static Uint8List before(Uint8List b)
```

#### BinaryLexoRank.after (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
static Uint8List after(Uint8List a)
//  â³ Called by: OCRReviewerApp.save_correction
```

#### BinaryLexoRank.between (Function)
```rust
// Lines 8-8 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static Uint8List between(Uint8List a, Uint8List b)
```

#### BinaryLexoRank (Class)
```rust
// Lines 5-101 (97 LOC | Complexity 1) | used by 0 callers
class BinaryLexoRank
//  â³ Calls: BoundedRouteHistory.isEmpty
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\lib\governor_logger.ts (114 lines)

#### onError (Function)
```rust
// Lines 69-74 (6 LOC | Complexity 1) | used by 6 callers | [Io, FrameworkInvoked]
const onError = (err: any) =>
//  â³ Called by: _JoshAutomatedGenerationDialogState, _DiaryListScreenState, HorAIzonClientShell, _JoshCoPilotPanelState, _SduiTextInputState, SduiContainer
```

#### log (Function)
```rust
// Lines 117-171 (55 LOC | Complexity 10) | used by 42 callers | [Io, CanPanic, CorePrimitive]
function log(
//  â³ Calls: header, MessagePackCodec.encode
//  â³ Called by: SduiNode, GovernorLogger.log, OllamaAnalyzerProvider.analyze, _SduiContainerState, OllamaAssistantProvider.plannerRefactor, OllamaAssistantProvider.chatStream, _SduiHtmlViewerState, TelemetryProfile, DiagnosticsHistoryNotifier, GeminiAnalyzerProvider.analyze, SduiListView, AnalyzerService.analyze, connectSocket, MediaUploader, uuid, SduiHeatmap, GeminiRateLimiter.execute, _SduiVideoState, SduiModuleCard, SduiGridView, AnalysisWorker._processNext, AnalysisWorker._setStatus, AnalysisWorker.enqueue, _SduiAudioState, _SduiScreenState, SduiScreen, parseMarkdown, _SduiJbcPanelState, ThemeNotifier, SduiEventDispatcher, GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.chatStream, GeminiAssistantProvider.generateSummary, GeminiAssistantProvider.generateTemplateStream, GeminiAssistantProvider.generateTemplate, SduiComposer.init, DiaryBlockPayload, SduiSocketManager, ConfigNotifier, run, _SduiTerminalState, N8nAnalyzerProvider.analyze
```

#### onConnect (Function)
```rust
// Lines 56-67 (12 LOC | Complexity 3) | used by 2 callers | [Io]
const onConnect = () =>
//  â³ Called by: SduiSocketManager.listenForConnect, SduiSocketManager
```

#### connectSocket (Function)
```rust
// Lines 46-86 (41 LOC | Complexity 5) | used by 0 callers | [Io, PotentialDeadCode]
function connectSocket(): void
//  â³ Calls: log, SduiSocketManager.connect, freeze
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\scratch\test_planner_only.js (34 lines)

#### run (Function)
```rust
// Lines 46-79 (34 LOC | Complexity 2) | used by 25 callers | [Async, Io, CorePrimitive]
async function run()
//  â³ Calls: log
//  â³ Called by: YOLOMeterBackend, DiaryRepository.saveBlockEmbedding, DiaryRepository.saveModuleConfig, DiaryRepository._refreshPreview, DiaryRepository.deleteEntry, DiaryRepository.setGloballyElevated, DiaryRepository.updateEntryTitle, DiaryRepository.updateEntryAnalysis, DiaryRepository.updateEntryMood, DiaryRepository.setPrivate, DiaryRepository.reorderBlock, DiaryRepository.deleteBlock, DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, main, MobileEdgeBackend, track_performance_timing, uuid, insertBlock, insertEntry, AnalysisWorker._processNext, DiaryBlockPayload, delete_primitive, request_primitive
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\gemini\GeminiAssistantProvider.ts (1250 lines)

#### GeminiAssistantProvider.start (Function)
```rust
// Lines 473-482 (10 LOC | Complexity 4) | used by 0 callers | [Async, Pure, Tested, PotentialDeadCode]
async start(controller)
//  â³ Calls: MessagePackCodec.encode
```

#### GeminiAssistantProvider.modelName (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
private get modelName() { return ConfigProvider.geminiAssistantModel; }
```

#### GeminiAssistantProvider.chatStream (Function)
```rust
// Lines 297-524 (228 LOC | Complexity 43) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod, HighComplexity]
async chatStream(
//  â³ Calls: MessagePackCodec.encode, warn, JbcTranslator.translate, ShuaDiaryBlocks.content, JbcTranslator.parse, log, GeminiRateLimiter.execute, JbcTranslator.serializeDiaryState, GeminiAssistantProvider.resolvePositionalRefs, Error
```

#### GeminiAssistantProvider.pull (Function)
```rust
// Lines 164-199 (36 LOC | Complexity 5) | used by 0 callers | [Async, Pure, PotentialDeadCode]
async pull(controller)
//  â³ Calls: MessagePackCodec.encode, JbcTranslator.parse, DiaryRepository.close
```

#### GeminiAssistantProvider (Class)
```rust
// Lines 6-597 (592 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class GeminiAssistantProvider implements IAssistantProvider
//  â³ Calls: IAssistantProvider
//  â³ Called by: AssistantService.getProvider
```

#### GeminiAssistantProvider.generateTemplate (Function)
```rust
// Lines 14-101 (88 LOC | Complexity 8) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateTemplate(
//  â³ Calls: warn, JbcTranslator.parse, log, GeminiRateLimiter.execute, Error
```

#### GeminiAssistantProvider.generateTemplateStream (Function)
```rust
// Lines 105-205 (101 LOC | Complexity 8) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateTemplateStream(topic: string, style: string): Promise<any>
//  â³ Calls: log, GeminiRateLimiter.execute, Error
```

#### GeminiAssistantProvider.cancel (Function)
```rust
// Lines 519-521 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
cancel()
//  â³ Calls: GeminiAssistantProvider.cancel
```

#### GeminiAssistantProvider.apiKey (Function)
```rust
// Lines 7-9 (3 LOC | Complexity 2) | used by 0 callers | [Pure, TraitMethod]
private get apiKey()
```

#### GeminiAssistantProvider.cancel (Function)
```rust
// Lines 200-202 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
cancel()
//  â³ Called by: GeminiAssistantProvider.cancel
```

#### GeminiAssistantProvider.generateSummary (Function)
```rust
// Lines 209-249 (41 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(content: string): Promise<string>
//  â³ Calls: log, GeminiRateLimiter.execute, test, filter, Error
```

#### GeminiAssistantProvider.plannerRefactor (Function)
```rust
// Lines 528-596 (69 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async plannerRefactor(
//  â³ Calls: JbcTranslator.translate, JbcTranslator.parse, log, GeminiRateLimiter.execute, GeminiAssistantProvider.resolvePositionalRefs, JbcTranslator.serializeDiaryState, Error
```

#### GeminiAssistantProvider.pull (Function)
```rust
// Lines 483-518 (36 LOC | Complexity 5) | used by 0 callers | [Async, Pure, PotentialDeadCode]
async pull(controller)
//  â³ Calls: MessagePackCodec.encode, JbcTranslator.parse, DiaryRepository.close
```

#### GeminiAssistantProvider.resolvePositionalRefs (Function)
```rust
// Lines 255-293 (39 LOC | Complexity 5) | used by 2 callers | [Pure, TraitMethod]
private resolvePositionalRefs(prompt: string, diaryBlocks: any[]): string
//  â³ Called by: GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.chatStream
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\ollama_jbc_provider.ts (680 lines)

#### OllamaJbcProvider.generateSummary (Function)
```rust
// Lines 264-311 (48 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(entryContent: string, entryTitle: string): Promise<string>
//  â³ Calls: Error, test, filter
```

#### OllamaJbcProvider.compileJbc (Function)
```rust
// Lines 14-112 (99 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot, JbcTranslator.translate, JbcTranslator.parse, Error, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, JbcTranslator.serializeDiaryState, OllamaJbcProvider.resolvePositionalRefs
```

#### OllamaJbcProvider.resolvePositionalRefs (Function)
```rust
// Lines 316-352 (37 LOC | Complexity 5) | used by 1 callers | [Pure, TraitMethod]
private resolvePositionalRefs(prompt: string, blocks: any[]): string
//  â³ Called by: OllamaJbcProvider.compileJbc
```

#### OllamaJbcProvider.presentJbcStream (Function)
```rust
// Lines 117-259 (143 LOC | Complexity 20) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult, JbcTranslator.parse, Error, JbcTranslator.serializeDiaryState, ShuaDiaryBlocks.content
```

#### OllamaJbcProvider.constructor (Function)
```rust
// Lines 6-9 (4 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
```

#### OllamaJbcProvider (Class)
```rust
// Lines 5-353 (349 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class OllamaJbcProvider implements IJbcChatProvider
//  â³ Calls: IJbcChatProvider
//  â³ Called by: DiaryAiSession.create
```

### C:\horAIzon_2.0\sdui3\sdui\sdui_node.dart (769 lines)

#### SduiTextFieldNode.build (Function)
```rust
// Lines 428-428 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiDonutChartNode (Class)
```rust
// Lines 711-741 (31 LOC | Complexity 1) | used by 2 callers
class SduiDonutChartNode extends SduiNode
//  â³ Calls: SduiNode, SduiChartPoint, ShuaDiaryEntries.title
//  â³ Called by: SduiDonutChartNode.SduiDonutChartNode, SduiNode
```

#### SduiNode.resolveIcon (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static IconData resolveIcon(String name)
//  â³ Calls: _SduiOrdinalSliderState._resolveIcon
```

#### SduiRowNode.SduiRowNode (Function)
```rust
// Lines 243-243 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiRowNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiRowNode
```

#### SduiButtonNode.fromJson (Function)
```rust
// Lines 376-376 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiButtonNode.fromJson(Map<String, dynamic> json)
```

#### SduiSpacerNode.build (Function)
```rust
// Lines 462-462 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiTextNode.SduiTextNode (Function)
```rust
// Lines 142-142 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiTextNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiTextNode
```

#### SduiContainerNode.fromJson (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiContainerNode.fromJson(Map<String, dynamic> json)
```

#### SduiSliderNode.SduiSliderNode (Function)
```rust
// Lines 489-489 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiSliderNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiSliderNode
```

#### SduiColumnNode (Class)
```rust
// Lines 269-297 (29 LOC | Complexity 1) | used by 2 callers
class SduiColumnNode extends SduiNode
//  â³ Calls: build, c, SduiNode.parseChildren, SduiNode
//  â³ Called by: SduiColumnNode.SduiColumnNode, SduiNode
```

#### SduiContainerNode.build (Function)
```rust
// Lines 215-215 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiBarChartNode.SduiBarChartNode (Function)
```rust
// Lines 681-681 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiBarChartNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiBarChartNode
```

#### SduiIconNode.SduiIconNode (Function)
```rust
// Lines 344-344 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiIconNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiIconNode
```

#### SduiShimmerLoaderNode.fromJson (Function)
```rust
// Lines 551-551 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiShimmerLoaderNode.fromJson(Map<String, dynamic> json)
```

#### SduiCardNode.SduiCardNode (Function)
```rust
// Lines 310-310 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiCardNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiCardNode
```

#### SduiSliderNode.build (Function)
```rust
// Lines 499-499 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiRowNode (Class)
```rust
// Lines 237-267 (31 LOC | Complexity 1) | used by 2 callers
class SduiRowNode extends SduiNode
//  â³ Calls: build, c, SduiNode.parseChildren, SduiNode
//  â³ Called by: SduiRowNode.SduiRowNode, SduiNode
```

#### SduiChipNode.SduiChipNode (Function)
```rust
// Lines 527-527 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiChipNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiChipNode
```

#### SduiLineChartNode.fromJson (Function)
```rust
// Lines 644-644 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiLineChartNode.fromJson(Map<String, dynamic> json)
```

#### SduiShimmerLoaderNode.SduiShimmerLoaderNode (Function)
```rust
// Lines 551-551 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiShimmerLoaderNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiShimmerLoaderNode
```

#### SduiShuaGridNode.build (Function)
```rust
// Lines 818-818 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiProgressBarNode.fromJson (Function)
```rust
// Lines 510-510 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiProgressBarNode.fromJson(Map<String, dynamic> json)
```

#### SduiNode.fromJson (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 24 callers | [Pure, CorePrimitive]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â³ Called by: SduiShuaGridNode.SduiShuaGridNode, SduiRadialGaugeNode.SduiRadialGaugeNode, SduiDonutChartNode.SduiDonutChartNode, SduiBarChartNode.SduiBarChartNode, SduiLineChartNode.SduiLineChartNode, SduiEmptyStateNode.SduiEmptyStateNode, SduiErrorStateNode.SduiErrorStateNode, SduiShimmerLoaderNode.SduiShimmerLoaderNode, SduiChipNode.SduiChipNode, SduiProgressBarNode.SduiProgressBarNode, SduiSliderNode.SduiSliderNode, SduiSwitchNode.SduiSwitchNode, SduiSpacerNode.SduiSpacerNode, SduiDividerNode.SduiDividerNode, SduiTextFieldNode.SduiTextFieldNode, SduiButtonNode.SduiButtonNode, SduiIconNode.SduiIconNode, SduiCardNode.SduiCardNode, SduiColumnNode.SduiColumnNode, SduiRowNode.SduiRowNode, SduiContainerNode.SduiContainerNode, SduiTextNode.SduiTextNode, SduiNode, SduiNode.SduiNode
```

#### SduiLineChartNode.build (Function)
```rust
// Lines 654-654 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiSpacerNode.SduiSpacerNode (Function)
```rust
// Lines 453-453 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiSpacerNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiSpacerNode
```

#### SduiSwitchNode.SduiSwitchNode (Function)
```rust
// Lines 470-470 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiSwitchNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiSwitchNode
```

#### SduiDividerNode.SduiDividerNode (Function)
```rust
// Lines 441-441 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiDividerNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiDividerNode
```

#### SduiChipNode.fromJson (Function)
```rust
// Lines 527-527 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiChipNode.fromJson(Map<String, dynamic> json)
```

#### SduiChipNode (Class)
```rust
// Lines 521-540 (20 LOC | Complexity 1) | used by 2 callers
class SduiChipNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiChipNode.SduiChipNode, SduiNode
```

#### SduiRadialGaugeNode.SduiRadialGaugeNode (Function)
```rust
// Lines 758-758 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiRadialGaugeNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiRadialGaugeNode
```

#### SduiUnknownNode (Class)
```rust
// Lines 827-832 (6 LOC | Complexity 1) | used by 1 callers
class SduiUnknownNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiNode
```

#### SduiColumnNode.fromJson (Function)
```rust
// Lines 275-275 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiColumnNode.fromJson(Map<String, dynamic> json)
```

#### SduiButtonNode (Class)
```rust
// Lines 363-411 (49 LOC | Complexity 1) | used by 2 callers
class SduiButtonNode extends SduiNode
//  â³ Calls: SduiNode, SduiFlexContext.of
//  â³ Called by: SduiButtonNode.SduiButtonNode, SduiNode
```

#### SduiErrorStateNode.build (Function)
```rust
// Lines 577-577 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiTextNode (Class)
```rust
// Lines 129-183 (55 LOC | Complexity 1) | used by 2 callers
class SduiTextNode extends SduiNode
//  â³ Calls: SduiNode, SduiFlexContext.of
//  â³ Called by: SduiTextNode.SduiTextNode, SduiNode
```

#### SduiRadialGaugeNode.build (Function)
```rust
// Lines 770-770 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiSpacerNode.fromJson (Function)
```rust
// Lines 453-453 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiSpacerNode.fromJson(Map<String, dynamic> json)
```

#### SduiTextNode.fromJson (Function)
```rust
// Lines 142-142 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiTextNode.fromJson(Map<String, dynamic> json)
```

#### SduiCardNode (Class)
```rust
// Lines 303-335 (33 LOC | Complexity 1) | used by 2 callers
class SduiCardNode extends SduiNode
//  â³ Calls: build, c, SduiBlockRegistry.all, _SduiShimmerLoaderState.padding, SduiNode.parseChildren, SduiNode, _SduiShimmerLoaderState.borderRadius
//  â³ Called by: SduiCardNode.SduiCardNode, SduiNode
```

#### SduiRadialGaugeNode.fromJson (Function)
```rust
// Lines 758-758 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiRadialGaugeNode.fromJson(Map<String, dynamic> json)
```

#### SduiContainerNode.SduiContainerNode (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiContainerNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiContainerNode
```

#### SduiSliderNode (Class)
```rust
// Lines 482-503 (22 LOC | Complexity 1) | used by 2 callers
class SduiSliderNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiSliderNode.SduiSliderNode, SduiNode
```

#### SduiNode.SduiNode (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiNode
```

#### SduiProgressBarNode (Class)
```rust
// Lines 505-519 (15 LOC | Complexity 1) | used by 2 callers
class SduiProgressBarNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiProgressBarNode.SduiProgressBarNode, SduiNode
```

#### SduiContainerNode (Class)
```rust
// Lines 185-235 (51 LOC | Complexity 1) | used by 2 callers
class SduiContainerNode extends SduiNode
//  â³ Calls: build, c, SduiBlockRegistry.all, SduiNode.parseChildren, SduiNode, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding
//  â³ Called by: SduiContainerNode.SduiContainerNode, SduiNode
```

#### SduiUnknownNode.build (Function)
```rust
// Lines 831-831 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiNode (Class)
```rust
// Lines 7-54 (48 LOC | Complexity 1) | used by 0 callers
sealed class SduiNode
//  â³ Calls: SduiChartPoint, DiaryRepository.close, _SduiOrdinalSliderState._resolveIcon, SduiFlexContext.of, build, SduiUnknownNode, SduiShuaGridNode, SduiRadialGaugeNode, SduiDonutChartNode, SduiBarChartNode, SduiLineChartNode, SduiEmptyStateNode, SduiErrorStateNode, SduiShimmerLoaderNode, SduiChipNode, SduiProgressBarNode, SduiSliderNode, SduiSwitchNode, SduiSpacerNode, SduiDividerNode, SduiTextFieldNode, SduiCardNode, SduiButtonNode, SduiIconNode, SduiColumnNode, SduiRowNode, SduiContainerNode, SduiNode.fromJson, SduiTextNode, SduiNode
```

#### SduiRowNode.fromJson (Function)
```rust
// Lines 243-243 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiRowNode.fromJson(Map<String, dynamic> json)
```

#### SduiSwitchNode.fromJson (Function)
```rust
// Lines 470-470 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiSwitchNode.fromJson(Map<String, dynamic> json)
```

#### SduiColumnNode.build (Function)
```rust
// Lines 284-284 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiEmptyStateNode (Class)
```rust
// Lines 591-614 (24 LOC | Complexity 1) | used by 2 callers
class SduiEmptyStateNode extends SduiNode
//  â³ Calls: SduiNode, SduiFlexContext.of
//  â³ Called by: SduiEmptyStateNode.SduiEmptyStateNode, SduiNode
```

#### SduiCardNode.fromJson (Function)
```rust
// Lines 310-310 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiCardNode.fromJson(Map<String, dynamic> json)
```

#### SduiSwitchNode (Class)
```rust
// Lines 465-480 (16 LOC | Complexity 1) | used by 2 callers
class SduiSwitchNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiSwitchNode.SduiSwitchNode, SduiNode
```

#### SduiShuaGridNode.SduiShuaGridNode (Function)
```rust
// Lines 809-809 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiShuaGridNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiShuaGridNode
```

#### SduiNode.parseChildren (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
static List<SduiNode> parseChildren(dynamic childrenJson)
//  â³ Calls: SduiNode
//  â³ Called by: SduiCardNode, SduiColumnNode, SduiRowNode, SduiContainerNode
```

#### SduiLineChartNode.SduiLineChartNode (Function)
```rust
// Lines 644-644 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiLineChartNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiLineChartNode
```

#### SduiCardNode.build (Function)
```rust
// Lines 320-320 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiDividerNode.build (Function)
```rust
// Lines 444-444 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiEmptyStateNode.fromJson (Function)
```rust
// Lines 596-596 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiEmptyStateNode.fromJson(Map<String, dynamic> json)
```

#### SduiShimmerLoaderNode (Class)
```rust
// Lines 546-564 (19 LOC | Complexity 1) | used by 2 callers
class SduiShimmerLoaderNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiShimmerLoaderNode.SduiShimmerLoaderNode, SduiNode
```

#### SduiErrorStateNode.fromJson (Function)
```rust
// Lines 571-571 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiErrorStateNode.fromJson(Map<String, dynamic> json)
```

#### SduiDonutChartNode.fromJson (Function)
```rust
// Lines 717-717 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiDonutChartNode.fromJson(Map<String, dynamic> json)
```

#### SduiChipNode.build (Function)
```rust
// Lines 533-533 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiRadialGaugeNode (Class)
```rust
// Lines 743-798 (56 LOC | Complexity 1) | used by 2 callers
class SduiRadialGaugeNode extends SduiNode
//  â³ Calls: SduiNode, SduiFlexContext.of
//  â³ Called by: SduiRadialGaugeNode.SduiRadialGaugeNode, SduiNode
```

#### SduiIconNode (Class)
```rust
// Lines 337-361 (25 LOC | Complexity 1) | used by 2 callers
class SduiIconNode extends SduiNode
//  â³ Calls: SduiNode, _SduiOrdinalSliderState._resolveIcon
//  â³ Called by: SduiIconNode.SduiIconNode, SduiNode
```

#### SduiTextNode.build (Function)
```rust
// Lines 153-153 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiColumnNode.SduiColumnNode (Function)
```rust
// Lines 275-275 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiColumnNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiColumnNode
```

#### SduiTextFieldNode (Class)
```rust
// Lines 413-437 (25 LOC | Complexity 1) | used by 2 callers
class SduiTextFieldNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiTextFieldNode.SduiTextFieldNode, SduiNode
```

#### SduiButtonNode.SduiButtonNode (Function)
```rust
// Lines 376-376 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiButtonNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiButtonNode
```

#### SduiErrorStateNode.SduiErrorStateNode (Function)
```rust
// Lines 571-571 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiErrorStateNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiErrorStateNode
```

#### SduiErrorStateNode (Class)
```rust
// Lines 566-589 (24 LOC | Complexity 1) | used by 2 callers
class SduiErrorStateNode extends SduiNode
//  â³ Calls: SduiNode, SduiFlexContext.of
//  â³ Called by: SduiErrorStateNode.SduiErrorStateNode, SduiNode
```

#### SduiTextFieldNode.fromJson (Function)
```rust
// Lines 419-419 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiTextFieldNode.fromJson(Map<String, dynamic> json)
```

#### SduiLineChartNode (Class)
```rust
// Lines 637-672 (36 LOC | Complexity 1) | used by 2 callers
class SduiLineChartNode extends SduiNode
//  â³ Calls: SduiNode, SduiChartPoint, SduiFlexContext.of, ShuaDiaryEntries.title
//  â³ Called by: SduiLineChartNode.SduiLineChartNode, SduiNode
```

#### SduiEmptyStateNode.SduiEmptyStateNode (Function)
```rust
// Lines 596-596 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiEmptyStateNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiEmptyStateNode
```

#### SduiProgressBarNode.build (Function)
```rust
// Lines 516-516 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiDividerNode (Class)
```rust
// Lines 439-445 (7 LOC | Complexity 1) | used by 2 callers
class SduiDividerNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiDividerNode.SduiDividerNode, SduiNode
```

#### SduiDonutChartNode.build (Function)
```rust
// Lines 726-726 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiShimmerLoaderNode.build (Function)
```rust
// Lines 557-557 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiSwitchNode.build (Function)
```rust
// Lines 476-476 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiBarChartNode.build (Function)
```rust
// Lines 691-691 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiRowNode.build (Function)
```rust
// Lines 252-252 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiIconNode.build (Function)
```rust
// Lines 354-354 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiProgressBarNode.SduiProgressBarNode (Function)
```rust
// Lines 510-510 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiProgressBarNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiProgressBarNode
```

#### SduiChartPoint (Class)
```rust
// Lines 631-635 (5 LOC | Complexity 1) | used by 4 callers
class SduiChartPoint
//  â³ Called by: SduiDonutChartNode, SduiBarChartNode, SduiLineChartNode, SduiNode
```

#### SduiEmptyStateNode.build (Function)
```rust
// Lines 602-602 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

#### SduiSpacerNode (Class)
```rust
// Lines 447-463 (17 LOC | Complexity 1) | used by 2 callers
class SduiSpacerNode extends SduiNode
//  â³ Calls: SduiNode
//  â³ Called by: SduiSpacerNode.SduiSpacerNode, SduiNode
```

#### SduiTextFieldNode.SduiTextFieldNode (Function)
```rust
// Lines 419-419 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiTextFieldNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiTextFieldNode
```

#### SduiSliderNode.fromJson (Function)
```rust
// Lines 489-489 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiSliderNode.fromJson(Map<String, dynamic> json)
```

#### SduiDividerNode.fromJson (Function)
```rust
// Lines 441-441 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiDividerNode.fromJson(Map<String, dynamic> json)
```

#### SduiIconNode.fromJson (Function)
```rust
// Lines 344-344 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiIconNode.fromJson(Map<String, dynamic> json)
```

#### SduiShuaGridNode (Class)
```rust
// Lines 804-821 (18 LOC | Complexity 1) | used by 2 callers
class SduiShuaGridNode extends SduiNode
//  â³ Calls: SduiNode, LogEntry::from
//  â³ Called by: SduiShuaGridNode.SduiShuaGridNode, SduiNode
```

#### SduiBarChartNode (Class)
```rust
// Lines 674-709 (36 LOC | Complexity 1) | used by 2 callers
class SduiBarChartNode extends SduiNode
//  â³ Calls: SduiNode, SduiChartPoint, SduiFlexContext.of, ShuaDiaryEntries.title
//  â³ Called by: SduiBarChartNode.SduiBarChartNode, SduiNode
```

#### SduiDonutChartNode.SduiDonutChartNode (Function)
```rust
// Lines 717-717 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiDonutChartNode.fromJson(Map<String, dynamic> json)
//  â³ Calls: SduiNode.fromJson, SduiDonutChartNode
```

#### SduiBarChartNode.fromJson (Function)
```rust
// Lines 681-681 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiBarChartNode.fromJson(Map<String, dynamic> json)
```

#### SduiShuaGridNode.fromJson (Function)
```rust
// Lines 809-809 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiShuaGridNode.fromJson(Map<String, dynamic> json)
```

#### SduiButtonNode.build (Function)
```rust
// Lines 387-387 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\scripts\ai_training\generate_synthetic_dataset.py (385 lines)

#### make_single_update (Function)
```rust
// Lines 568-598 (31 LOC | Complexity 2) | used by 1 callers | [Pure]
def make_single_update(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, content_preview, random_different_content, make_no_op, editable_blocks
//  â³ Called by: new_block_id
```

#### make_system_block_refusal (Function)
```rust
// Lines 728-747 (20 LOC | Complexity 2) | used by 1 callers | [Pure, Cycle]
def make_system_block_refusal(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, new_block_id
//  â³ Called by: new_block_id
```

#### random_different_content (Function)
```rust
// Lines 487-494 (8 LOC | Complexity 2) | used by 4 callers | [Pure]
def random_different_content(block_type: str, exclude: str) -> str
//  â³ Called by: make_triple_chain, make_update_then_insert, make_mixed_delete_update, make_single_update
```

#### make_no_op (Function)
```rust
// Lines 749-760 (12 LOC | Complexity 4) | used by 3 callers | [Io]
def make_no_op(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state
//  â³ Called by: new_block_id, make_single_update, make_single_delete
```

#### main (Function)
```rust
// Lines 822-908 (87 LOC | Complexity 15) | used by 0 callers | [Io, EntryPoint]
def main(
//  â³ Calls: build_training_pair, generate_coverage_pairs
```

#### make_mixed_delete_insert (Function)
```rust
// Lines 652-668 (17 LOC | Complexity 2) | used by 1 callers | [Pure]
def make_mixed_delete_insert(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, random_content, make_insert_top, editable_blocks
//  â³ Called by: new_block_id
```

#### editable_blocks (Function)
```rust
// Lines 510-512 (3 LOC | Complexity 1) | used by 8 callers | [Pure]
def editable_blocks(blocks: List[Dict]) -> List[Dict]
//  â³ Called by: make_triple_chain, make_update_then_insert, make_mixed_delete_insert, make_mixed_delete_update, make_insert_after, make_single_update, make_batch_delete, make_single_delete
```

#### make_insert_after (Function)
```rust
// Lines 600-626 (27 LOC | Complexity 1) | used by 2 callers | [Pure]
def make_insert_after(blocks: List[Dict], force_type: str = None) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, content_preview, random_content, editable_blocks
//  â³ Called by: generate_coverage_pairs, new_block_id
```

#### generate_coverage_pairs (Function)
```rust
// Lines 787-803 (17 LOC | Complexity 4) | used by 1 callers | [Pure]
def generate_coverage_pairs() -> List[Dict]
//  â³ Calls: make_insert_after, make_insert_top, generate_blocks
//  â³ Called by: main
```

#### new_block_id (Function)
```rust
// Lines 473-474 (2 LOC | Complexity 1) | used by 2 callers | [Pure, Cycle]
def new_block_id() -> str
//  â³ Calls: main, make_system_block_refusal, make_no_op, make_batch_delete, make_triple_chain, make_update_then_insert, make_mixed_delete_insert, make_mixed_delete_update, make_insert_top, make_single_delete, make_insert_after, make_single_update
//  â³ Called by: make_system_block_refusal, generate_blocks
```

#### random_content (Function)
```rust
// Lines 479-485 (7 LOC | Complexity 2) | used by 6 callers | [Pure]
def random_content(block_type: str) -> str
//  â³ Called by: make_triple_chain, make_update_then_insert, make_mixed_delete_insert, make_insert_top, make_insert_after, generate_blocks
```

#### build_training_pair (Function)
```rust
// Lines 808-820 (13 LOC | Complexity 1) | used by 1 callers | [Pure]
def build_training_pair(mutation_fn) -> Dict
//  â³ Calls: generate_blocks
//  â³ Called by: main
```

#### content_preview (Function)
```rust
// Lines 476-477 (2 LOC | Complexity 1) | used by 4 callers | [Pure]
def content_preview(content: str, max_len: int = 40) -> str
//  â³ Called by: make_insert_after, make_single_update, make_single_delete, serialize_input_state
```

#### make_triple_chain (Function)
```rust
// Lines 689-726 (38 LOC | Complexity 3) | used by 1 callers | [Pure]
def make_triple_chain(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, random_content, random_different_content, make_mixed_delete_update, editable_blocks
//  â³ Called by: new_block_id
```

#### make_update_then_insert (Function)
```rust
// Lines 670-687 (18 LOC | Complexity 2) | used by 1 callers | [Pure]
def make_update_then_insert(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, random_content, random_different_content, make_insert_top, editable_blocks
//  â³ Called by: new_block_id
```

#### make_single_delete (Function)
```rust
// Lines 523-552 (30 LOC | Complexity 2) | used by 3 callers | [Pure]
def make_single_delete(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, content_preview, make_no_op, editable_blocks
//  â³ Called by: new_block_id, make_mixed_delete_update, make_batch_delete
```

#### make_insert_top (Function)
```rust
// Lines 628-634 (7 LOC | Complexity 1) | used by 4 callers | [Pure]
def make_insert_top(blocks: List[Dict], force_type: str = None) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, random_content
//  â³ Called by: generate_coverage_pairs, new_block_id, make_update_then_insert, make_mixed_delete_insert
```

#### make_mixed_delete_update (Function)
```rust
// Lines 636-650 (15 LOC | Complexity 2) | used by 2 callers | [Pure]
def make_mixed_delete_update(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, random_different_content, make_single_delete, editable_blocks
//  â³ Called by: new_block_id, make_triple_chain
```

#### generate_blocks (Function)
```rust
// Lines 496-508 (13 LOC | Complexity 3) | used by 2 callers | [Pure]
def generate_blocks(count: int, include_system: bool = True) -> List[Dict]
//  â³ Calls: new_block_id, random_content
//  â³ Called by: build_training_pair, generate_coverage_pairs
```

#### make_batch_delete (Function)
```rust
// Lines 554-566 (13 LOC | Complexity 2) | used by 1 callers | [Pure]
def make_batch_delete(blocks: List[Dict]) -> Tuple[str, str, str]
//  â³ Calls: serialize_input_state, make_single_delete, editable_blocks
//  â³ Called by: new_block_id
```

#### serialize_input_state (Function)
```rust
// Lines 514-518 (5 LOC | Complexity 2) | used by 11 callers | [Pure, CorePrimitive]
def serialize_input_state(blocks: List[Dict]) -> str
//  â³ Calls: content_preview
//  â³ Called by: make_no_op, make_system_block_refusal, make_triple_chain, make_update_then_insert, make_mixed_delete_insert, make_mixed_delete_update, make_insert_top, make_insert_after, make_single_update, make_batch_delete, make_single_delete
```

### C:\horAIzon_2.0\shua_governor\src\routes\manifest.rs (17 lines)

#### get_manifest (Function)
```rust
// Lines 6-22 (17 LOC | Complexity 3) | used by 0 callers | [Async, Io, ApiRoute]
pub async fn get_manifest() -> impl IntoResponse
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\interfaces\IAssistantProvider.ts (67 lines)

#### IAssistantProvider (Interface)
```rust
// Lines 0-43 (44 LOC | Complexity 1) | used by 5 callers
interface IAssistantProvider
//  â³ Called by: OllamaAssistantProvider, AssistantService.getProvider, AssistantService, N8nAssistantProvider, GeminiAssistantProvider
```

#### IAssistantProvider.generateTemplateStream (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
generateTemplateStream(topic: string, style: string): Promise<any>
//  â³ Called by: AssistantService.generateTemplateStream
```

#### IAssistantProvider.chatStream (Function)
```rust
// Lines 22-28 (7 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
chatStream(
//  â³ Called by: AssistantService.chatStream
```

#### IAssistantProvider.plannerRefactor (Function)
```rust
// Lines 33-42 (10 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
plannerRefactor(
//  â³ Called by: AssistantService.plannerRefactor
```

#### IAssistantProvider.generateTemplate (Function)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
generateTemplate(
//  â³ Called by: AssistantService.generateTemplate
```

#### IAssistantProvider.generateSummary (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 1 callers | [Async, Pure]
generateSummary(content: string): Promise<string>
//  â³ Called by: AssistantService.generateSummary
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\handlers\resume_handler.go (455 lines)

#### uploadToCAS (Function)
```rust
// Lines 281-347 (67 LOC | Complexity 12) | used by 2 callers | [Io]
func uploadToCAS(pdfBytes []byte) (string, error)
//  â³ Called by: handleWsofflineCompile, CompilePdfHandler
```

#### ListCompiledHandler (Function)
```rust
// Lines 427-498 (72 LOC | Complexity 15) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func ListCompiledHandler(c *fiber.Ctx) error
//  â³ Calls: Error, sendResponse, parseRequestBody
```

#### HealthCheckHandler (Function)
```rust
// Lines 501-503 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
func HealthCheckHandler(c *fiber.Ctx) error
```

#### CompilePdfHandler (Function)
```rust
// Lines 164-277 (114 LOC | Complexity 28) | used by 0 callers | [Async, MutatesState, Io, HighComplexity, PotentialDeadCode]
func CompilePdfHandler(c *fiber.Ctx) error
//  â³ Calls: ResumeMatrix, saveCompilationToHistory, uploadToCAS, CompileTypst, TailorResume, FilterResume, DefaultTailorConfig, parseRequestBody, sendResponse, Error
```

#### saveCompilationToHistory (Function)
```rust
// Lines 351-394 (44 LOC | Complexity 7) | used by 2 callers | [MutatesState, Io]
func saveCompilationToHistory(templateID string, exhibitID string, jd string) error
//  â³ Calls: Info, Error
//  â³ Called by: handleWsofflineCompile, CompilePdfHandler
```

#### UpdateMatrixHandler (Function)
```rust
// Lines 131-161 (31 LOC | Complexity 6) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func UpdateMatrixHandler(c *fiber.Ctx) error
//  â³ Calls: ResumeMatrix, Info, Error, sendResponse, parseRequestBody
```

#### parseRequestBody (Function)
```rust
// Lines 29-81 (53 LOC | Complexity 9) | used by 3 callers | [MutatesState]
func parseRequestBody(c *fiber.Ctx) (map[string]string, error)
//  â³ Called by: ListCompiledHandler, CompilePdfHandler, UpdateMatrixHandler
```

#### GetTemplatesHandler (Function)
```rust
// Lines 397-424 (28 LOC | Complexity 5) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func GetTemplatesHandler(c *fiber.Ctx) error
//  â³ Calls: sendResponse, Error
```

#### sendResponse (Function)
```rust
// Lines 84-112 (29 LOC | Complexity 5) | used by 5 callers | [MutatesState, Io]
func sendResponse(c *fiber.Ctx, status int, data interface{}) error
//  â³ Calls: Error
//  â³ Called by: ListCompiledHandler, GetTemplatesHandler, CompilePdfHandler, UpdateMatrixHandler, GetMatrixHandler
```

#### GetMatrixHandler (Function)
```rust
// Lines 115-128 (14 LOC | Complexity 3) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func GetMatrixHandler(c *fiber.Ctx) error
//  â³ Calls: sendResponse, Error
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\TagSearchService.ts (91 lines)

#### TagSearchService.clearTrie (Function)
```rust
// Lines 9-11 (3 LOC | Complexity 1) | used by 1 callers | [MutatesState]
public clearTrie(): void
//  â³ Calls: RadixTrie
//  â³ Called by: DiaryBlockPayload
```

#### TagSearchService (Class)
```rust
// Lines 2-54 (53 LOC | Complexity 1) | used by 1 callers
class TagSearchService
//  â³ Calls: RadixTrie
//  â³ Called by: DiaryBlockPayload
```

#### TagSearchService.searchTags (Function)
```rust
// Lines 45-48 (4 LOC | Complexity 2) | used by 1 callers | [Pure]
public searchTags(prefix: string): string[]
//  â³ Called by: _DiaryListScreenState
```

#### TagSearchService.constructor (Function)
```rust
// Lines 5-7 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor()
//  â³ Calls: RadixTrie
```

#### TagSearchService.searchTagsWithMatches (Function)
```rust
// Lines 50-53 (4 LOC | Complexity 2) | used by 1 callers | [MutatesState]
public searchTagsWithMatches(prefix: string, maxDistance: number = 2): { [entryId: string]: SearchMatchDetail[] }
//  â³ Calls: SearchMatchDetail, RadixTrie.searchWithMatches
//  â³ Called by: DiaryBlockPayload
```

#### TagSearchService.indexBlockContent (Function)
```rust
// Lines 20-43 (24 LOC | Complexity 8) | used by 1 callers | [MutatesState]
public indexBlockContent(text: string, blockType: string, blockId: string, entryId: string): void
//  â³ Calls: RadixTrie.insert
//  â³ Called by: DiaryBlockPayload
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_rpc_handler.ts (12 lines)

#### ISduiRpcHandler.handle (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 0 callers | [Async, Pure, Tested, PotentialDeadCode]
handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext
```

#### ISduiRpcHandler (Interface)
```rust
// Lines 12-14 (3 LOC | Complexity 1) | used by 9 callers
interface ISduiRpcHandler
//  â³ Called by: ChatHandler, SduiOrchestrator, GenerateSummaryHandler, GenerateFromNotesHandler, AnalyzeEntryHandler, RequestScreenHandler, SemanticSearchHandler, ApplyMutationsHandler, SaveAiConfigHandler
```

#### SduiRpcContext (Interface)
```rust
// Lines 3-10 (8 LOC | Complexity 1) | used by 9 callers
interface SduiRpcContext
//  â³ Calls: DiaryAiSession
//  â³ Called by: ChatHandler.handle, GenerateSummaryHandler.handle, GenerateFromNotesHandler.handle, AnalyzeEntryHandler.handle, ISduiRpcHandler.handle, RequestScreenHandler.handle, SemanticSearchHandler.handle, ApplyMutationsHandler.handle, SaveAiConfigHandler.handle
```

### C:\horAIzon_2.0\sdui3\shua_diary_archive\providers\gemini\GeminiRateLimiter.ts (144 lines)

#### GeminiRateLimiter.execute (Function)
```rust
// Lines 47-82 (36 LOC | Complexity 5) | used by 6 callers | [Async, Io, Tested]
static async execute<T>(model: string, task: () => Promise<T>): Promise<T>
//  â³ Calls: warn, log, GeminiRateLimiter.refill
//  â³ Called by: GeminiAnalyzerProvider.analyze, GeminiAssistantProvider.plannerRefactor, GeminiAssistantProvider.chatStream, GeminiAssistantProvider.generateSummary, GeminiAssistantProvider.generateTemplateStream, GeminiAssistantProvider.generateTemplate
```

#### GeminiRateLimiter.refill (Function)
```rust
// Lines 19-42 (24 LOC | Complexity 4) | used by 1 callers | [Pure]
private static refill(isPro: boolean): void
//  â³ Called by: GeminiRateLimiter.execute
```

#### GeminiRateLimiter (Class)
```rust
// Lines 0-83 (84 LOC | Complexity 1) | used by 0 callers
class GeminiRateLimiter
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\diary\diary_repository.ts (1464 lines)

#### DiaryRepository.stmt (Function)
```rust
// Lines 162-167 (6 LOC | Complexity 2) | used by 31 callers | [MutatesState, Io, CorePrimitive]
private stmt(name: string, sql: string): Database.Statement
//  â³ Called by: DiaryRepository.getEntryCount, DiaryRepository.getBlockEmbedding, DiaryRepository.saveBlockEmbedding, DiaryRepository.saveModuleConfig, DiaryRepository.getModuleConfig, DiaryRepository.getBlockSearchDetails, DiaryRepository._refreshPreview, DiaryRepository.getEntryUserIdForBlock, DiaryRepository._nextSortOrder, DiaryRepository._lexoRankAfter, DiaryRepository._nextBlockLexoRank, DiaryRepository._nextLexoRank, DiaryRepository.deleteEntry, DiaryRepository.setGloballyElevated, DiaryRepository.updateEntryTitle, DiaryRepository.updateEntryAnalysis, DiaryRepository.updateEntryMood, DiaryRepository.setPrivate, DiaryRepository.getEntryIdForBlock, DiaryRepository.getBlockLexoRank, DiaryRepository.reorderBlockByNeighbors, DiaryRepository.reorderBlock, DiaryRepository.deleteBlock, DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, DiaryRepository.getEntryBlocks, DiaryRepository.getMoodTimeline, DiaryRepository.getEntry, DiaryRepository.getEntriesList, ApplyMutationsHandler.handle
```

#### DiaryRepository (Class)
```rust
// Lines 19-841 (823 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiaryRepository
//  â³ Called by: getDiaryRepository
```

#### DiaryRepository._ensureSchema (Function)
```rust
// Lines 37-155 (119 LOC | Complexity 3) | used by 1 callers | [MutatesState, Io]
private _ensureSchema(): void
//  â³ Called by: DiaryRepository.constructor
```

#### DiaryRepository._uuid (Function)
```rust
// Lines 685-687 (3 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
private _uuid(): string
//  â³ Called by: DiaryRepository.createBlock, DiaryRepository.createEntry
```

#### DiaryRepository.createBlock (Function)
```rust
// Lines 291-305 (15 LOC | Complexity 1) | used by 4 callers | [MutatesState]
createBlock(entryId: string, blockType: BlockType, afterLexoRank?: string): DiaryBlock
//  â³ Calls: DiaryBlock, DiaryRepository.getEntryBlocks, DiaryRepository.stmt, run, DiaryRepository._nextSortOrder, DiaryRepository._nextBlockLexoRank, DiaryRepository._lexoRankAfter, DiaryRepository._uuid
//  â³ Called by: SduiActionHandler._createBlock, GenerateFromNotesHandler.handle, checkAndSynthesizeForUser, ApplyMutationsHandler.handle
```

#### DiaryRepository._nextSortOrder (Function)
```rust
// Lines 629-634 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
private _nextSortOrder(entryId: string): number
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: DiaryRepository.createBlock
```

#### DiaryRepository._nextBlockLexoRank (Function)
```rust
// Lines 591-602 (12 LOC | Complexity 2) | used by 2 callers | [MutatesState]
private _nextBlockLexoRank(entryId: string): string
//  â³ Calls: DiaryRepository._nextRankSuffix, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.reorderBlockByNeighbors, DiaryRepository.createBlock
```

#### DiaryRepository.updateEntryTitle (Function)
```rust
// Lines 463-468 (6 LOC | Complexity 1) | used by 2 callers | [MutatesState]
updateEntryTitle(entryId: string, title: string): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: SduiActionHandler._saveTitle, _TitleEditorState
```

#### DiaryRepository.getEntry (Function)
```rust
// Lines 189-196 (8 LOC | Complexity 1) | used by 3 callers | [MutatesState, Tested]
getEntry(entryId: string): DiaryEntry | null
//  â³ Calls: DiaryEntry, DiaryRepository._mapEntry, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.createEntry, DiaryRepository.getEntryWithBlocks, SduiActionHandler._saveTitle
```

#### DiaryRepository.searchEntries (Function)
```rust
// Lines 764-784 (21 LOC | Complexity 2) | used by 2 callers | [MutatesState, Io]
searchEntries(userId: string, query: string): DiaryEntry[]
//  â³ Calls: DiaryEntry, DiaryRepository._mapEntry, SduiBlockRegistry.all, filter
//  â³ Called by: SduiActionHandler._searchDiary, SduiScreenAssembler._assembleDiaryList
```

#### DiaryRepository.getEntriesList (Function)
```rust
// Lines 175-184 (10 LOC | Complexity 1) | used by 2 callers | [MutatesState, Tested]
getEntriesList(userId: string): DiaryEntry[]
//  â³ Calls: DiaryEntry, DiaryRepository._mapEntry, DiaryRepository.stmt, SduiBlockRegistry.all
//  â³ Called by: SduiActionHandler._searchDiary, SduiScreenAssembler._assembleDiaryList
```

#### DiaryRepository.getSnippetsForEntries (Function)
```rust
// Lines 797-827 (31 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io, CanPanic]
getSnippetsForEntries(entryIds: string[], ftsQuery: string): Map<string, string>
//  â³ Called by: SduiActionHandler._searchDiary
```

#### DiaryRepository.getEntryBlocks (Function)
```rust
// Lines 238-247 (10 LOC | Complexity 1) | used by 4 callers | [MutatesState, Tested]
getEntryBlocks(entryId: string): DiaryBlock[]
//  â³ Calls: DiaryBlock, DiaryRepository._mapBlock, DiaryRepository.stmt, SduiBlockRegistry.all
//  â³ Called by: DiaryRepository.createBlock, DiaryRepository.getEntryWithBlocks, SduiScreenAssembler._assembleDiaryList, checkAndSynthesizeForUser
```

#### DiaryRepository.close (Function)
```rust
// Lines 838-840 (3 LOC | Complexity 1) | used by 20 callers | [Io, Tested, CorePrimitive]
close(): void
//  â³ Called by: repl, _DiaryListScreenState, OllamaAssistantProvider.pull, compile_blueprints, convert, generate_graphs, TelemetryProfile, SduiChartDataPoint, _SduiChartState, MediaUploader, uuid, main, control_module, SduiIconRegistry, _SduiJbcPanelState, SduiEventDispatcher, GeminiAssistantProvider.pull, GeminiAssistantProvider.pull, main, SduiNode
```

#### DiaryRepository.getMoodTimeline (Function)
```rust
// Lines 211-232 (22 LOC | Complexity 1) | used by 1 callers | [MutatesState, Tested]
getMoodTimeline(userId: string, monthOffset: number = 0): Array<{ date: string; moodScore: number | null }>
//  â³ Calls: DiaryRepository.stmt, SduiBlockRegistry.all
//  â³ Called by: SduiScreenAssembler._assembleDiaryList
```

#### DiaryRepository.getBlockLexoRank (Function)
```rust
// Lines 411-416 (6 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getBlockLexoRank(blockId: string): string | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: ApplyMutationsHandler.handle
```

#### DiaryRepository.getAiProviderConfig (Function)
```rust
// Lines 711-723 (13 LOC | Complexity 16) | used by 6 callers | [MutatesState, Io]
getAiProviderConfig(userId: string): Record<string, any>
//  â³ Calls: DiaryRepository.getModuleConfig
//  â³ Called by: SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, getEmbedding, SduiScreenAssembler._assembleDiaryAiConfig, checkAndSynthesizeForUser, SaveAiConfigHandler.handle
```

#### DiaryRepository.getModuleConfig (Function)
```rust
// Lines 689-700 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getModuleConfig(userId: string, moduleId: string): Record<string, any> | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: DiaryRepository.getAiProviderConfig
```

#### DiaryRepository.getEntryIdForBlock (Function)
```rust
// Lines 423-428 (6 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getEntryIdForBlock(blockId: string): string | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._reorderBlock
```

#### DiaryRepository.getEntryUserIdForBlock (Function)
```rust
// Lines 636-643 (8 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getEntryUserIdForBlock(blockId: string): string | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._saveBlock
```

#### DiaryRepository.constructor (Function)
```rust
// Lines 22-33 (12 LOC | Complexity 3) | used by 0 callers | [MutatesState, Io, FrameworkInvoked]
constructor(dbPath?: string)
//  â³ Calls: DiaryRepository._ensureSchema
```

#### DiaryRepository._lexoRankAfter (Function)
```rust
// Lines 607-627 (21 LOC | Complexity 2) | used by 3 callers | [MutatesState]
private _lexoRankAfter(entryId: string, afterRank: string): string
//  â³ Calls: DiaryRepository._midRankSuffix, DiaryRepository._nextRankSuffix, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.reorderBlockByNeighbors, DiaryRepository.createBlock, ApplyMutationsHandler.handle
```

#### DiaryRepository._mapEntry (Function)
```rust
// Lines 492-508 (17 LOC | Complexity 3) | used by 3 callers | [Pure]
private _mapEntry(row: any): DiaryEntry
//  â³ Calls: DiaryEntry, ShuaDiaryEntries.title
//  â³ Called by: DiaryRepository.searchEntries, DiaryRepository.getEntry, DiaryRepository.getEntriesList
```

#### DiaryRepository.createEntry (Function)
```rust
// Lines 255-285 (31 LOC | Complexity 2) | used by 4 callers | [MutatesState]
createEntry(
//  â³ Calls: DiaryEntry, DiaryRepository.getEntry, DiaryRepository.stmt, run, DiaryRepository._nextLexoRank, DiaryRepository._uuid
//  â³ Called by: _DiaryListScreenState, SduiActionHandler._createEntry, GenerateFromNotesHandler.handle, checkAndSynthesizeForUser
```

#### DiaryRepository.getEntryWithBlocks (Function)
```rust
// Lines 201-206 (6 LOC | Complexity 2) | used by 2 callers | [MutatesState]
getEntryWithBlocks(entryId: string): { entry: DiaryEntry; blocks: DiaryBlock[] } | null
//  â³ Calls: DiaryBlock, DiaryEntry, DiaryRepository.getEntryBlocks, DiaryRepository.getEntry
//  â³ Called by: SduiOrchestrator.sendReplacePayload, SduiScreenAssembler._assembleDiaryEditor
```

#### DiaryRepository.saveBlockEmbedding (Function)
```rust
// Lines 726-734 (9 LOC | Complexity 1) | used by 1 callers | [MutatesState]
saveBlockEmbedding(blockId: string, embedding: number[]): void
//  â³ Calls: DiaryRepository.stmt, run, LogEntry::from
//  â³ Called by: SduiActionHandler._saveBlock
```

#### DiaryRepository.deleteEntry (Function)
```rust
// Lines 483-487 (5 LOC | Complexity 1) | used by 3 callers | [MutatesState]
deleteEntry(entryId: string): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: _DiaryListScreenState, SduiActionHandler._deleteEntry, _DiaryEditorContent
```

#### DiaryRepository.reorderBlockByNeighbors (Function)
```rust
// Lines 359-406 (48 LOC | Complexity 7) | used by 1 callers | [MutatesState, Io]
reorderBlockByNeighbors(
//  â³ Calls: DiaryRepository.reorderBlock, DiaryRepository._lexoRankAfter, DiaryRepository._midRankSuffix, DiaryRepository.stmt, DiaryRepository._nextBlockLexoRank
//  â³ Called by: SduiActionHandler._reorderBlock
```

#### DiaryRepository._nextLexoRank (Function)
```rust
// Lines 577-588 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
private _nextLexoRank(userId: string): string
//  â³ Calls: DiaryRepository._nextRankSuffix, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.createEntry
```

#### DiaryRepository.getBlockSearchDetails (Function)
```rust
// Lines 667-682 (16 LOC | Complexity 1) | used by 2 callers | [MutatesState]
getBlockSearchDetails(blockId: string): { blockId: string; content: string; blockType: string; entryId: string; entryTitle: string } | null
//  â³ Calls: ShuaDiaryBlocks.content, DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._searchDiary, SemanticSearchHandler.handle
```

#### DiaryRepository.getEntryCount (Function)
```rust
// Lines 830-835 (6 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
getEntryCount(userId: string): number
//  â³ Calls: DiaryRepository.stmt
```

#### DiaryRepository.getAllEmbeddings (Function)
```rust
// Lines 746-758 (13 LOC | Complexity 1) | used by 1 callers | [MutatesState, Io]
getAllEmbeddings(): Array<{ blockId: string; embedding: number[] }>
//  â³ Calls: LogEntry::from, SduiBlockRegistry.all
//  â³ Called by: SemanticSearchHandler.handle
```

#### DiaryRepository.updateEntryAnalysis (Function)
```rust
// Lines 453-458 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
updateEntryAnalysis(entryId: string, moodScore: number | null, preview: string | null): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: AnalysisWorker._processNext
```

#### DiaryRepository.setGloballyElevated (Function)
```rust
// Lines 473-478 (6 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
setGloballyElevated(entryId: string, isGloballyElevated: boolean): void
//  â³ Calls: DiaryRepository.stmt, run
```

#### DiaryRepository.updateBlock (Function)
```rust
// Lines 311-319 (9 LOC | Complexity 1) | used by 4 callers | [MutatesState]
updateBlock(blockId: string, content: string): void
//  â³ Calls: DiaryRepository._refreshPreview, DiaryRepository.stmt, run
//  â³ Called by: SduiActionHandler._saveBlock, GenerateFromNotesHandler.handle, checkAndSynthesizeForUser, ApplyMutationsHandler.handle
```

#### DiaryRepository._midRankSuffix (Function)
```rust
// Lines 558-574 (17 LOC | Complexity 5) | used by 3 callers | [Pure]
private static _midRankSuffix(lo: string, hi: string | undefined): string
//  â³ Called by: DiaryRepository._lexoRankAfter, DiaryRepository.reorderBlockByNeighbors, ApplyMutationsHandler.handle
```

#### getDiaryRepository (Function)
```rust
// Lines 848-853 (6 LOC | Complexity 2) | used by 23 callers | [Pure, Tested, CorePrimitive]
function getDiaryRepository(): DiaryRepository
//  â³ Calls: DiaryRepository
//  â³ Called by: SduiOrchestrator.sendReplacePayload, SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, getEmbedding, SduiActionHandler._setPrivate, SduiActionHandler._createEntry, SduiActionHandler._searchDiary, SduiActionHandler._deleteEntry, SduiActionHandler._createBlock, SduiActionHandler._deleteBlock, SduiActionHandler._reorderBlock, SduiActionHandler._saveBlock, SduiActionHandler._saveTitle, GenerateFromNotesHandler.handle, SemanticSearchHandler.handle, SduiScreenAssembler._assembleDiaryAiConfig, SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryList, checkAndSynthesizeForUser, runMonthlySynthesisCheck, ApplyMutationsHandler.handle, AnalysisWorker._processNext, SaveAiConfigHandler.handle
```

#### DiaryRepository.deleteBlock (Function)
```rust
// Lines 324-328 (5 LOC | Complexity 1) | used by 2 callers | [MutatesState]
deleteBlock(blockId: string): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: SduiActionHandler._deleteBlock, ApplyMutationsHandler.handle
```

#### DiaryRepository.saveModuleConfig (Function)
```rust
// Lines 702-709 (8 LOC | Complexity 1) | used by 1 callers | [MutatesState]
saveModuleConfig(userId: string, moduleId: string, config: Record<string, any>): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: SaveAiConfigHandler.handle
```

#### DiaryRepository.setPrivate (Function)
```rust
// Lines 433-438 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
setPrivate(entryId: string, isPrivate: boolean): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: SduiActionHandler._setPrivate
```

#### DiaryRepository.getBlockEmbedding (Function)
```rust
// Lines 736-744 (9 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
getBlockEmbedding(blockId: string): number[] | null
//  â³ Calls: LogEntry::from, DiaryRepository.stmt
```

#### DiaryRepository.reorderBlock (Function)
```rust
// Lines 335-340 (6 LOC | Complexity 1) | used by 2 callers | [MutatesState]
reorderBlock(blockId: string, newLexoRank: string): void
//  â³ Calls: DiaryRepository.stmt, run
//  â³ Called by: DiaryRepository.reorderBlockByNeighbors, _DiaryEditorContent
```

#### DiaryRepository._mapBlock (Function)
```rust
// Lines 511-523 (13 LOC | Complexity 2) | used by 1 callers | [Pure]
private _mapBlock(row: any): DiaryBlock
//  â³ Calls: DiaryBlock, ShuaDiaryBlocks.content
//  â³ Called by: DiaryRepository.getEntryBlocks
```

#### DiaryRepository._nextRankSuffix (Function)
```rust
// Lines 544-553 (10 LOC | Complexity 3) | used by 3 callers | [Pure]
private static _nextRankSuffix(suffix: string): string
//  â³ Called by: DiaryRepository._lexoRankAfter, DiaryRepository._nextBlockLexoRank, DiaryRepository._nextLexoRank
```

#### DiaryRepository.updateEntryMood (Function)
```rust
// Lines 443-448 (6 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
updateEntryMood(entryId: string, moodScore: number | null, energyScore: number | null): void
//  â³ Calls: DiaryRepository.stmt, run
```

#### DiaryRepository._refreshPreview (Function)
```rust
// Lines 645-665 (21 LOC | Complexity 2) | used by 1 callers | [MutatesState]
private _refreshPreview(blockId: string): void
//  â³ Calls: run, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.updateBlock
```

### C:\horAIzon_2.0\shua_governor\src\routes\module_ready.rs (39 lines)

#### mark_ready (Function)
```rust
// Lines 31-69 (39 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, ApiRoute]
pub async fn mark_ready(
//  â³ Calls: AppState
```

### C:\horAIzon_2.0\tools\toggle_view.py (66 lines)

#### main (Function)
```rust
// Lines 37-102 (66 LOC | Complexity 14) | used by 0 callers | [Io, EntryPoint]
def main()
//  â³ Calls: main, SduiStateVault.dump, SduiBlockRegistry.load
```

### C:\horAIzon_2.0\tools\extract_blueprints.py (20 lines)

#### extract_blueprints (Function)
```rust
// Lines 3-22 (20 LOC | Complexity 2) | used by 0 callers | [Io, PotentialDeadCode]
def extract_blueprints()
//  â³ Calls: SduiStateVault.dump, SduiBlockRegistry.load
```

### C:\horAIzon_2.0\client_flutter\lib\core\logging\governor_logger.dart (114 lines)

#### GovernorLogger.GovernorLogger (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory GovernorLogger()
//  â³ Calls: GovernorLogger
```

#### GovernorLogger (Class)
```rust
// Lines 54-154 (101 LOC | Complexity 1) | used by 1 callers
class GovernorLogger
//  â³ Calls: GovernorLogger._uri, header, serialize, GovernorLogger._sendAsync, ShuaSyncQueue.payload, Response.msgpack
//  â³ Called by: GovernorLogger.GovernorLogger
```

#### GovernorLogger._uri (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Uri get _uri
//  â³ Called by: GovernorLogger
```

#### GovernorLogger._sendAsync (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _sendAsync(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: GovernorLogger
```

#### GovernorLogger.log (Function)
```rust
// Lines 85-93 (9 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void log(
//  â³ Calls: log
```

#### GovernorLogger.setMinLogLevel (Function)
```rust
// Lines 67-67 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void setMinLogLevel(int level)
```

### C:\horAIzon_2.0\sdui3\sdui\primitives\sdui_button.dart (36 lines)

#### SduiButton (Class)
```rust
// Lines 2-36 (35 LOC | Complexity 1) | used by 0 callers
class SduiButton extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, ShuaSyncQueue.payload, SduiButton
```

#### SduiButton.build (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: build
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\lexer.rs (5 lines)

#### Lexer::parse_imports (Function)
```rust
// Lines 3-6 (4 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
pub fn parse_imports(_content: &str, _language: &str) -> Vec<String>
```

#### Lexer (Struct)
```rust
// Lines 0-0 (1 LOC | Complexity 1) | used by 0 callers
pub struct Lexer;
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\boundary.rs (53 lines)

#### find_boundary_violations (Function)
```rust
// Lines 20-58 (39 LOC | Complexity 6) | used by 1 callers | [MutatesState, CanPanic]
pub fn find_boundary_violations(state: &AppState) -> Vec<BoundaryViolation>
//  â³ Calls: BoundaryViolation, AppState, get_module_root, LogEntry::from
//  â³ Called by: debug_analysis
```

#### BoundaryViolation (Struct)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 2 callers
pub struct BoundaryViolation
//  â³ Called by: DebugReport, find_boundary_violations
```

#### get_module_root (Function)
```rust
// Lines 9-18 (10 LOC | Complexity 6) | used by 1 callers | [MutatesState]
fn get_module_root(path: &Path) -> Option<String>
//  â³ Called by: find_boundary_violations
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\api_client.dart (17 lines)

#### ApiClient (Class)
```rust
// Lines 8-20 (13 LOC | Complexity 1) | used by 0 callers
class ApiClient
//  â³ Calls: ShuaSyncQueue.payload, MessagePackCodec.encode, MessagePackCodec
```

#### ApiClient.postBinary (Function)
```rust
// Lines 9-12 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Future<Map<String, dynamic>> postBinary(
//  â³ Calls: ShuaSyncQueue.payload
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_node_builder.ts (174 lines)

#### SduiNodeBuilder.hydrateString (Function)
```rust
// Lines 86-97 (12 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
private static hydrateString(str: string, context: HydrationContext): any
```

#### SduiNodeBuilder (Class)
```rust
// Lines 4-98 (95 LOC | Complexity 1) | used by 0 callers
class SduiNodeBuilder
```

#### SduiNodeBuilder.buildScreen (Function)
```rust
// Lines 10-20 (11 LOC | Complexity 2) | used by 2 callers | [MutatesState, Io, CanPanic]
static buildScreen(moduleName: string, screenKey: string, context: HydrationContext): any
//  â³ Calls: SduiNodeBuilder.hydrateNode, Error, SduiBlueprintLoader.loadBlueprint
//  â³ Called by: SduiScreenAssembler._assembleDiaryAiConfig, SduiScreenAssembler._assembleDiaryList
```

#### SduiNodeBuilder.hydrateNode (Function)
```rust
// Lines 25-80 (56 LOC | Complexity 16) | used by 3 callers | [MutatesState]
static hydrateNode(node: any, context: HydrationContext): any
//  â³ Calls: hydrateString
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, SduiNodeBuilder.buildScreen
```

### C:\horAIzon_2.0\shua_modules\shua_meter_vision\training\collect_kwh_data.py (196 lines)

#### on_save (Function)
```rust
// Lines 109-115 (7 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def on_save(event=None)
```

#### _append_label (Function)
```rust
// Lines 56-62 (7 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
def _append_label(filename: str, label: str)
```

#### _scan_images (Function)
```rust
// Lines 142-149 (8 LOC | Complexity 4) | used by 0 callers | [Pure, PotentialDeadCode]
def _scan_images(source_dir: str) -> list[str]
//  â³ Calls: walk
```

#### _load_existing_labels (Function)
```rust
// Lines 47-53 (7 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
def _load_existing_labels() -> dict
//  â³ Calls: collect, review, RadixTrie.insert
```

#### review (Function)
```rust
// Lines 237-244 (8 LOC | Complexity 3) | used by 2 callers | [Io, Tested]
def review()
//  â³ Calls: _load_existing_labels
//  â³ Called by: _load_existing_labels, _load_existing_labels
```

#### collect (Function)
```rust
// Lines 155-234 (80 LOC | Complexity 12) | used by 0 callers | [Io, PotentialDeadCode]
def collect(source_dir: str, conf: float = 0.25)
//  â³ Calls: _append_label, _show_crop_gui, _hash_image, _load_existing_labels, _scan_images, find_latest_weights
```

#### _show_crop_gui (Function)
```rust
// Lines 69-139 (71 LOC | Complexity 3) | used by 0 callers | [Pure, PotentialDeadCode]
def _show_crop_gui(img_bgr: np.ndarray, source_name: str, class_name: str) -> str
//  â³ Calls: ShuaDiaryEntries.title
```

#### on_skip (Function)
```rust
// Lines 117-119 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def on_skip(event=None)
```

#### on_quit (Function)
```rust
// Lines 121-123 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def on_quit(event=None)
```

#### _hash_image (Function)
```rust
// Lines 65-66 (2 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
def _hash_image(img_bgr: np.ndarray) -> str
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\n8n_jbc_provider.ts (224 lines)

#### N8nJbcProvider.presentJbcStream (Function)
```rust
// Lines 45-99 (55 LOC | Complexity 11) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult, Error, N8nJbcProvider.checkConfig
```

#### N8nJbcProvider (Class)
```rust
// Lines 3-117 (115 LOC | Complexity 1) | used by 1 callers
class N8nJbcProvider implements IJbcChatProvider
//  â³ Calls: IJbcChatProvider
//  â³ Called by: DiaryAiSession.create
```

#### N8nJbcProvider.checkConfig (Function)
```rust
// Lines 6-10 (5 LOC | Complexity 4) | used by 3 callers | [Io, CanPanic, TraitMethod]
private checkConfig()
//  â³ Calls: Error
//  â³ Called by: N8nJbcProvider.generateSummary, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc
```

#### N8nJbcProvider.compileJbc (Function)
```rust
// Lines 12-43 (32 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot, Error, N8nJbcProvider.checkConfig
```

#### N8nJbcProvider.constructor (Function)
```rust
// Lines 4-4 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(private n8nUrl: string) {}
```

#### N8nJbcProvider.generateSummary (Function)
```rust
// Lines 101-116 (16 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(entryContent: string, entryTitle: string): Promise<string>
//  â³ Calls: Error, N8nJbcProvider.checkConfig
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\generate_summary.ts (40 lines)

#### GenerateSummaryHandler (Class)
```rust
// Lines 4-24 (21 LOC | Complexity 1) | used by 1 callers
class GenerateSummaryHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### GenerateSummaryHandler.handle (Function)
```rust
// Lines 5-23 (19 LOC | Complexity 3) | used by 0 callers | [Async, Io, TraitMethod, Tested]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, MessagePackCodec.encode
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\ollama_generator_provider.ts (280 lines)

#### OllamaGeneratorProvider (Class)
```rust
// Lines 3-144 (142 LOC | Complexity 1) | used by 1 callers
class OllamaGeneratorProvider implements IDiaryGeneratorProvider
//  â³ Calls: IDiaryGeneratorProvider
//  â³ Called by: DiaryAiSession.create
```

#### OllamaGeneratorProvider.constructor (Function)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
```

#### OllamaGeneratorProvider.generateFromNotes (Function)
```rust
// Lines 9-78 (70 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async generateFromNotes(rawNotes: string, style: string): Promise<DiaryBlueprint>
//  â³ Calls: DiaryBlueprint, Error
```

#### OllamaGeneratorProvider.generateFromNotesStream (Function)
```rust
// Lines 80-143 (64 LOC | Complexity 10) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>
//  â³ Calls: Error
```


