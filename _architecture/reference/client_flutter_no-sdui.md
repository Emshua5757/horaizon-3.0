# Repository Export

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_socket_provider.dart (720 lines)

#### SduiSocketManager.listenForReplace (Function)
```rust
// Lines 334-337 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForReplace(
//  â†³ Calls: SduiNode
//  â†³ Called by: _SduiScreenState
```

#### SduiSocketManager.emitRpc (Function)
```rust
// Lines 491-491 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
void emitRpc(String method, Map<String, dynamic> params)
//  â†³ Called by: _SduiTextInputState, SduiSocketManager, SduiEventDispatcher
```

#### SduiSocketManager.listenForConnect (Function)
```rust
// Lines 427-427 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForConnect(VoidCallback onConnect, {required String screenId})
//  â†³ Called by: _SduiScreenState
```

#### SduiSocketManager.evictCache (Function)
```rust
// Lines 479-479 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void evictCache(String screenId)
//  â†³ Called by: _SduiScreenState
```

#### SduiSocketManager.sendRpcWithResponse (Function)
```rust
// Lines 509-513 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<dynamic> sendRpcWithResponse(
//  â†³ Called by: _SduiJbcPanelState
```

#### SduiSocketManager._isStaticScreen (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool _isStaticScreen(String screenId)
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager._socketForMethod (Function)
```rust
// Lines 581-581 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket? _socketForMethod(String method)
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager.connectViaGateway (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void connectViaGateway(String screenId)
//  â†³ Called by: SduiSocketManager.connect
```

#### SduiSocketManager.socketForScreen (Function)
```rust
// Lines 141-141 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket? socketForScreen(String screenId)
//  â†³ Called by: _SduiJbcPanelState
```

#### SduiSocketManager.disconnect (Function)
```rust
// Lines 149-149 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void disconnect()
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager.connect (Function)
```rust
// Lines 147-147 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void connect()
//  â†³ Calls: SduiSocketManager.connectViaGateway
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager.reRequestScreen (Function)
```rust
// Lines 447-447 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void reRequestScreen(String screenId)
//  â†³ Called by: _SduiScreenState
```

#### SduiSocketManager.listenForHotReload (Function)
```rust
// Lines 389-391 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForHotReload(
//  â†³ Called by: _SduiScreenState
```

#### SduiSocketManager._socketFor (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket _socketFor(String moduleId)
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager._ensureSocketListeners (Function)
```rust
// Lines 599-599 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _ensureSocketListeners(String moduleId, String screenId)
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager.getScreen (Function)
```rust
// Lines 311-311 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<SduiNode>> getScreen(String screenId)
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiScreen
```

#### SduiSocketManager.injectLocalDelta (Function)
```rust
// Lines 563-563 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void injectLocalDelta(String screenId, Map<String, dynamic> delta)
//  â†³ Called by: SduiEventDispatcher
```

#### SduiSocketManager.listenForPatches (Function)
```rust
// Lines 362-365 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForPatches(
//  â†³ Called by: _SduiScreenState
```

#### SduiSocketManager.requestScreen (Function)
```rust
// Lines 157-157 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<SduiNode>> requestScreen(String screenId)
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager._moduleIdForScreen (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _moduleIdForScreen(String screenId)
//  â†³ Called by: SduiSocketManager
```

#### SduiSocketManager (Class)
```rust
// Lines 15-702 (688 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiSocketManager
//  â†³ Calls: SduiNode, SduiIconRegistry.contains, SduiTransport.applyDelta, SduiSocketManager._socketForMethod, SduiSocketManager.requestScreen, SduiSocketManager.emitRpc, SduiSocketManager._ensureSocketListeners, SduiTransport.decodeJson, SduiTransport, SduiStateVault.get, SduiSocketManager.disconnect, SduiSocketManager._socketFor, SduiSocketManager._moduleIdForScreen, SduiSocketManager._isStaticScreen, SduiSocketManager.connect, SduiFlexContext.of, GovernorLogger.log
//  â†³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_state_vault.dart (31 lines)

#### SduiStateVault.build (Function)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Map<String, dynamic> build()
```

#### SduiStateVault (Class)
```rust
// Lines 4-30 (27 LOC | Complexity 1) | used by 1 callers
class SduiStateVault extends Notifier<Map<String, dynamic>>
//  â†³ Called by: _SduiScreenState
```

#### SduiStateVault.get (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
T? get<T>(String nodeId)
//  â†³ Called by: SduiSocketManager, SduiEventDispatcher
```

#### SduiStateVault.set (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 16 callers | [Pure, CorePrimitive]
void set(String nodeId, dynamic value)
//  â†³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, _SduiCheckboxState, SduiTimePicker, MediaUploader, _SduiDividerState, SduiDatePicker, _SduiMapState, SduiEventDispatcher, _SduiDrawingPadState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiStateVault.releaseScope (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void releaseScope(String screenId)
//  â†³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_screen.dart (318 lines)

#### _SduiScreenState._findNodeByIdSuffix (Function)
```rust
// Lines 186-186 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode? _findNodeByIdSuffix(List<SduiNode> nodes, String suffix)
//  â†³ Calls: SduiNode
//  â†³ Called by: _SduiScreenState
```

#### _SduiScreenState._buildBody (Function)
```rust
// Lines 235-239 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildBody(
//  â†³ Calls: SduiEventDispatcher, SduiNode
//  â†³ Called by: _SduiScreenState
```

#### _SduiScreenState.build (Function)
```rust
// Lines 198-198 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiScreen (Class)
```rust
// Lines 22-38 (17 LOC | Complexity 1) | used by 2 callers
class SduiScreen extends ConsumerStatefulWidget
//  â†³ Calls: SduiSocketManager.getScreen, GovernorLogger.log
//  â†³ Called by: _SduiScreenState, SduiScreen.createState
```

#### _SduiScreenState._resolveTitle (Function)
```rust
// Lines 166-166 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _resolveTitle()
//  â†³ Called by: _SduiScreenState
```

#### _SduiScreenState.initState (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â†³ Called by: _SduiScreenState
```

#### SduiScreen.createState (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiScreen> createState()
//  â†³ Calls: SduiScreen, _SduiScreenState
```

#### _SduiScreenState._onFullReplace (Function)
```rust
// Lines 160-160 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFullReplace(List<SduiNode> nodes)
//  â†³ Calls: SduiNode
//  â†³ Called by: _SduiScreenState
```

#### _SduiScreenState.dispose (Function)
```rust
// Lines 131-131 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â†³ Called by: _SduiScreenState
```

#### _SduiScreenState (Class)
```rust
// Lines 40-322 (283 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiScreenState extends ConsumerState<SduiScreen>
//  â†³ Calls: SduiSocketManager, SduiStateVault, SduiEventDispatcher, SduiScreen, SduiRenderer, ShuaDiaryBlocks.content, SduiNode, SduiShimmerLoader, _SduiShimmerLoaderState.padding, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, ShuaDiaryBlocks.entryId, SduiJbcPanel, _SduiScreenState._resolveTitle, ShuaDiaryEntries.title, SduiNode.contentVal, _SduiScreenState._findNodeByIdSuffix, SduiTransport.applyDelta, SduiTransport, _SduiScreenState.dispose, SduiSocketManager.evictCache, SduiStateVault.releaseScope, SduiEventDispatcher.flushPending, SduiSocketManager.listenForConnect, SduiSocketManager.reRequestScreen, GovernorLogger.log, SduiFlexContext.of, SduiSocketManager.listenForHotReload, _SduiScreenState._onFullReplace, SduiSocketManager.listenForReplace, _SduiScreenState._onPatchDelta, SduiSocketManager.listenForPatches, _SduiScreenState.initState
//  â†³ Called by: SduiScreen.createState
```

#### _SduiScreenState._onPatchDelta (Function)
```rust
// Lines 153-153 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onPatchDelta(dynamic rawDelta)
//  â†³ Called by: _SduiScreenState
```

#### _SduiScreenState._buildNodeList (Function)
```rust
// Lines 303-307 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildNodeList(
//  â†³ Calls: SduiEventDispatcher, SduiNode
//  â†³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\api_client.dart (17 lines)

#### ApiClient (Class)
```rust
// Lines 8-20 (13 LOC | Complexity 1) | used by 0 callers
class ApiClient
//  â†³ Calls: ShuaSyncQueue.payload, MessagePackCodec.encode, MessagePackCodec
```

#### ApiClient.postBinary (Function)
```rust
// Lines 9-12 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Future<Map<String, dynamic>> postBinary(
//  â†³ Calls: ShuaSyncQueue.payload
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\diagnostic_result.dart (141 lines)

#### DiagnosticResult.success (Function)
```rust
// Lines 53-56 (4 LOC | Complexity 1) | used by 5 callers | [Pure, Tested]
factory DiagnosticResult.success(T data,
//  â†³ Called by: TelemetryProfile, ThemeNotifier, BoundedRouteHistory, AuthNotifier, DiagnosticResult.DiagnosticResult
```

#### DiagnosticResult.toString (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
String toString()
```

#### DiagnosticResult.DiagnosticResult (Function)
```rust
// Lines 53-56 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory DiagnosticResult.success(T data,
//  â†³ Calls: SystemDiagnostic, DiagnosticResult.success, DiagnosticResult
```

#### DiagnosticResult.failure (Function)
```rust
// Lines 70-73 (4 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
factory DiagnosticResult.failure(SystemDiagnostic diagnostic,
//  â†³ Called by: TelemetryProfile, AuthNotifier, DiagnosticResult.DiagnosticResult
```

#### DiagnosticResult.isFailure (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get isFailure
//  â†³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticResult.DiagnosticResult (Function)
```rust
// Lines 70-73 (4 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory DiagnosticResult.failure(SystemDiagnostic diagnostic,
//  â†³ Calls: SystemDiagnostic, DiagnosticResult.failure, DiagnosticResult
```

#### OccurrenceEntry (Class)
```rust
// Lines 3-11 (9 LOC | Complexity 1) | used by 3 callers
class OccurrenceEntry
//  â†³ Called by: DiagnosticResult.copyWith, DiagnosticsHistoryNotifier, DiagnosticResult
```

#### DiagnosticResult.isCritical (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get isCritical
//  â†³ Calls: DiagnosticSeverity
//  â†³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticResult (Class)
```rust
// Lines 16-122 (107 LOC | Complexity 1) | used by 21 callers | [CorePrimitive]
class DiagnosticResult<T>
//  â†³ Calls: SystemDiagnostic, OccurrenceEntry
//  â†³ Called by: DiagnosticsHistoryNotifier, DiagnosticsHistoryNotifier.logResult, DiagnosticsHistoryNotifier._truncate, DiagnosticsState.copyWith, DiagnosticsState, _TerminalLine, _SduiTerminalState._buildLogList, _SduiTerminalState._buildHeader, _SduiTerminalState, _SduiTerminalState._copyLogs, _SduiTerminalState._severityColor, _SduiTerminalState._getFilteredLogs, AuthState.copyWith, AuthState, DiagnosticResult.copyWith, TelemetryProfile, ThemeNotifier, BoundedRouteHistory, AuthNotifier, DiagnosticResult.DiagnosticResult, DiagnosticResult.DiagnosticResult
```

#### DiagnosticResult.copyWith (Function)
```rust
// Lines 96-100 (5 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DiagnosticResult<T> copyWith(
//  â†³ Calls: OccurrenceEntry, DiagnosticResult
```

#### DiagnosticResult.latencyMs (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get latencyMs
//  â†³ Called by: DiagnosticsHistoryNotifier
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\system_diagnostics.dart (40 lines)

#### DiagnosticSeverity (Enum)
```rust
// Lines 1-10 (10 LOC | Complexity 1) | used by 6 callers
enum DiagnosticSeverity
//  â†³ Called by: _SduiTerminalState, SystemDiagnostic, TelemetryProfile, DiagnosticsHistoryNotifier, SystemEvents, DiagnosticResult.isCritical
```

#### SystemEvents (Class)
```rust
// Lines 23-45 (23 LOC | Complexity 1) | used by 3 callers
class SystemEvents
//  â†³ Calls: DiagnosticSeverity, SystemDiagnostic
//  â†³ Called by: ThemeNotifier, BoundedRouteHistory, AuthNotifier
```

#### SystemDiagnostic (Class)
```rust
// Lines 13-19 (7 LOC | Complexity 1) | used by 5 callers
class SystemDiagnostic
//  â†³ Calls: DiagnosticSeverity
//  â†³ Called by: DiagnosticResult.DiagnosticResult, DiagnosticResult.DiagnosticResult, DiagnosticResult, TelemetryProfile, SystemEvents
```

### C:\horAIzon_2.0\client_flutter\lib\core\interfaces\illm_provider.dart (3 lines)

#### IllmProvider (Class)
```rust
// Lines 0-2 (3 LOC | Complexity 1) | used by 0 callers
abstract class IllmProvider
```

### C:\horAIzon_2.0\client_flutter\lib\main.dart (28 lines)

#### HorAIzonClientShell (Class)
```rust
// Lines 30-56 (27 LOC | Complexity 1) | used by 0 callers
class HorAIzonClientShell extends ConsumerWidget
//  â†³ Calls: SduiFlexContext.of, ThemeState.compiledData, ShuaDiaryEntries.title
```

#### HorAIzonClientShell.build (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

### C:\horAIzon_2.0\client_flutter\lib\app\auth\pin_entry_screen.dart (294 lines)

#### PinEntryScreen.createState (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<PinEntryScreen> createState()
//  â†³ Calls: PinEntryScreen, _PinEntryScreenState
```

#### _PinEntryScreenState.initState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â†³ Called by: _PinEntryScreenState
```

#### PinEntryScreen (Class)
```rust
// Lines 7-12 (6 LOC | Complexity 1) | used by 2 callers
class PinEntryScreen extends ConsumerStatefulWidget
//  â†³ Called by: _PinEntryScreenState, PinEntryScreen.createState
```

#### _PinEntryScreenState.build (Function)
```rust
// Lines 82-82 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _PinEntryScreenState._buildKey (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildKey(String label, AuthState state)
//  â†³ Calls: AuthState
//  â†³ Called by: _PinEntryScreenState
```

#### _PinEntryScreenState (Class)
```rust
// Lines 14-296 (283 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
//  â†³ Calls: AuthState, PinEntryScreen, AuthNotifier.deleteDigit, _PinEntryScreenState._buildKey, _SduiShimmerLoaderState.padding, filter, _SduiShimmerLoaderState.borderRadius, AuthStatus, SduiFlexContext.of, AuthNotifier.enterDigit, _PinEntryScreenState.dispose, _PinEntryScreenState.initState
//  â†³ Called by: PinEntryScreen.createState
```

#### _PinEntryScreenState.dispose (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â†³ Called by: _PinEntryScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_node.dart (220 lines)

#### SduiNode (Class)
```rust
// Lines 6-220 (215 LOC | Complexity 1) | used by 72 callers | [CorePrimitive, HighComplexity]
@immutable
//  â†³ Calls: SduiNode.fromJson, SduiNode.interpolate, GovernorLogger.log, ShuaDiaryBlocks.content
//  â†³ Called by: SduiWrap, SduiRadio, SduiHtmlViewer, _SduiContainerState._findDragHandleIndex, _SduiContainerState._buildReorderableItem, _SduiContainerState, SduiContainer, SduiAudio, _DashboardScreenState, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, _SduiScreenState._findNodeByIdSuffix, _SduiScreenState._onFullReplace, SduiGridView, SduiCheckbox, SduiTimePicker, SduiTextInput, SduiImage, SduiMarkdownEditor, SduiCodeEditor, SduiToggle, SduiShimmerLoader, _SduiJbcPanelState, SduiJbcPanel, SduiDivider, SduiDatePicker, SduiProgressBar, SduiTerminal, SduiOrdinalSlider, SduiTimeline, SduiChip, _SduiSandboxScreenState._parseLegacyV4Format, _SduiSandboxScreenState._loadBlueprints, SduiHeatmap, SduiListEditor, SduiListView, SduiSocketManager.listenForReplace, SduiSocketManager.getScreen, SduiSocketManager.requestScreen, SduiSocketManager, SduiButton, SduiRenderer, SduiMap, SduiTransport._nodeFromMap, SduiTransport._parseList, SduiTransport._patchNodeInTree, SduiTransport._insertAfterRecursive, SduiTransport._insertAfterInTree, SduiTransport._removeNodeFromTree, SduiTransport.applyDelta, SduiTransport.patch, SduiTransport.decodeJson, SduiTransport.decode, SduiSlider, SduiNode.interpolate, SduiDocumentViewer, SduiTypeRegistry.buildNode, SduiDrawingPad, SduiStlViewer, SduiTable, SduiSpacer, SduiVideo, SduiCarousel, SduiGauge, SduiChart, SduiDropdown, SduiExpansionTile, _SduiScreenState, _SduiSandboxScreenState, SduiTransport, SduiModuleCard, SduiNode.SduiNode
```

#### SduiNode.interpolate (Function)
```rust
// Lines 134-134 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
SduiNode interpolate(Map<String, dynamic> context)
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiGridView, SduiListView, SduiNode
```

#### SduiNode.behavior (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 47 callers | [Pure, CorePrimitive]
T? behavior<T>(int key)
//  â†³ Called by: _SduiWrapState, _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, SduiGridView, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, _SduiTextInputState._bindKey, SduiImage, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.shimmerAnimStyle, _SduiShimmerLoaderState.shimmerType, _SduiJbcPanelState, _SduiDividerState, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState._bindKey, _SduiListEditorState, SduiListView, SduiButton, _SduiMapState, _SduiSliderState, _SduiDocumentViewerState, _SduiDrawingPadState, SduiStlViewer, _SduiTableState._bindKey, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiNode.fromJson (Function)
```rust
// Lines 179-179 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â†³ Called by: SduiNode, SduiNode.SduiNode
```

#### SduiNode.SduiNode (Function)
```rust
// Lines 179-179 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â†³ Calls: SduiNode.fromJson, SduiNode
```

#### SduiNode.contentVal (Function)
```rust
// Lines 88-88 (1 LOC | Complexity 1) | used by 40 callers | [Pure, CorePrimitive]
T? contentVal<T>(int key)
//  â†³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, _SduiScreenState, SduiGridView, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, SduiImage, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, _SduiListEditorState._itemHintText, _SduiListEditorState._headerLabel, _SduiListEditorState._initialContent, SduiListView, SduiButton, _SduiMapState, _SduiSliderState, SduiModuleCard, _SduiDocumentViewerState, _SduiDrawingPadState, SduiStlViewer, _SduiTableState, _SduiTableState._headerLabel, _SduiTableState._initialContent, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_renderer.dart (71 lines)

#### SduiFlexContext.updateShouldNotify (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool updateShouldNotify(SduiFlexContext oldWidget)
//  â†³ Calls: SduiFlexContext
```

#### SduiFlexContext (Class)
```rust
// Lines 14-32 (19 LOC | Complexity 1) | used by 4 callers
class SduiFlexContext extends InheritedWidget
//  â†³ Called by: SduiFlexContext.updateShouldNotify, SduiFlexContext.of, _SduiContainerState, SduiRenderer
```

#### SduiFlexContext.of (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 53 callers | [Pure, CorePrimitive]
static SduiFlexContext? of(BuildContext context)
//  â†³ Calls: SduiFlexContext
//  â†³ Called by: _SduiWrapState, _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, _SduiScreenState, _SduiCheckboxState, HorAIzonClientShell, _NetworkConfigCardState, SettingsPage, SduiTimePicker, _SduiTextInputState, MediaUploader, SduiImage, _PinEntryScreenState, _SduiMarkdownEditorState, _SduiCodeEditorState, SyntaxHighlightingController, SduiToggle, _SduiShimmerLoaderState, SduiStyleResolver, _SduiJbcPanelState, _SduiDividerState, SduiDatePicker, SduiProgressBar, _FilterChip, _TerminalLineState, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, _SduiSandboxScreenState, AdaptiveShell, SduiHeatmap, _SduiListEditorState, SduiSocketManager, SduiButton, SduiRenderer, _SduiMapState, _SduiSliderState, SduiModuleCard, _SduiDocumentViewerState, SduiEventDispatcher, _SduiDrawingPadState, SduiStlViewer, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiRenderer (Class)
```rust
// Lines 38-86 (49 LOC | Complexity 1) | used by 8 callers
class SduiRenderer extends StatelessWidget
//  â†³ Calls: SduiEventDispatcher, SduiNode, SduiFlexContext.of, SduiFlexContext, _SduiShimmerLoaderState.padding, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiTypeRegistry.buildNode, SduiTypeRegistry
//  â†³ Called by: _SduiWrapState, _SduiContainerState, _DashboardScreenState, _SduiScreenState, SduiGridView, SduiListView, _SduiCarouselState, _SduiExpansionTileState
```

#### SduiRenderer.build (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\config_provider.dart (132 lines)

#### ConfigNotifier.updateWorkspaceRoot (Function)
```rust
// Lines 121-121 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateWorkspaceRoot(String root)
//  â†³ Called by: _NetworkConfigCardState
```

#### ConfigState (Class)
```rust
// Lines 8-38 (31 LOC | Complexity 1) | used by 3 callers
class ConfigState
//  â†³ Calls: ConfigNotifier
//  â†³ Called by: ConfigNotifier.build, ConfigState.copyWith, ConfigNotifier
```

#### ConfigNotifier._saveConfig (Function)
```rust
// Lines 79-79 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _saveConfig()
//  â†³ Called by: ConfigNotifier
```

#### ConfigNotifier (Class)
```rust
// Lines 40-125 (86 LOC | Complexity 1) | used by 1 callers
class ConfigNotifier extends Notifier<ConfigState>
//  â†³ Calls: ConfigNotifier._saveConfig, ConfigState.copyWith, GovernorLogger.log, ConfigState, ConfigNotifier._loadConfig
//  â†³ Called by: ConfigState
```

#### ConfigNotifier.updateOllamaModel (Function)
```rust
// Lines 111-111 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateOllamaModel(String model)
//  â†³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier._loadConfig (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadConfig()
//  â†³ Called by: ConfigNotifier
```

#### ConfigState.copyWith (Function)
```rust
// Lines 23-29 (7 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ConfigState copyWith(
//  â†³ Calls: ConfigState
//  â†³ Called by: ConfigNotifier
```

#### ConfigNotifier.updateOllamaUrl (Function)
```rust
// Lines 106-106 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateOllamaUrl(String url)
//  â†³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier.updateSyncBaseUrl (Function)
```rust
// Lines 101-101 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateSyncBaseUrl(String url)
//  â†³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier.build (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConfigState build()
//  â†³ Calls: ConfigState
```

#### ConfigNotifier.updateGeminiApiKey (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateGeminiApiKey(String key)
//  â†³ Called by: _NetworkConfigCardState
```

### C:\horAIzon_2.0\client_flutter\lib\app\auth\auth_provider.dart (77 lines)

#### AuthStatus (Enum)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 4 callers
enum AuthStatus { unauthenticated, authenticating, authenticated, error }
//  â†³ Calls: AuthNotifier
//  â†³ Called by: AuthState.copyWith, AuthState, _PinEntryScreenState, AuthNotifier
```

#### AuthState (Class)
```rust
// Lines 7-29 (23 LOC | Complexity 1) | used by 5 callers
class AuthState
//  â†³ Calls: DiagnosticResult, AuthStatus
//  â†³ Called by: _PinEntryScreenState, _PinEntryScreenState._buildKey, AuthNotifier.build, AuthState.copyWith, AuthNotifier
```

#### AuthNotifier.verifyPIN (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void verifyPIN(String pin)
//  â†³ Called by: AuthNotifier
```

#### AuthState.copyWith (Function)
```rust
// Lines 18-22 (5 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
AuthState copyWith(
//  â†³ Calls: DiagnosticResult, AuthStatus, AuthState
//  â†³ Called by: AuthNotifier
```

#### AuthNotifier (Class)
```rust
// Lines 31-74 (44 LOC | Complexity 1) | used by 1 callers
class AuthNotifier extends Notifier<AuthState>
//  â†³ Calls: DiagnosticsHistoryNotifier.logResult, DiagnosticResult.failure, SystemEvents, DiagnosticResult.success, DiagnosticResult, BoundedRouteHistory.isEmpty, AuthNotifier.verifyPIN, AuthState.copyWith, AuthStatus, AuthState
//  â†³ Called by: AuthStatus
```

#### AuthNotifier.enterDigit (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void enterDigit(String digit)
//  â†³ Called by: _PinEntryScreenState
```

#### AuthNotifier.build (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
AuthState build()
//  â†³ Calls: AuthState
```

#### AuthNotifier.deleteDigit (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void deleteDigit()
//  â†³ Called by: _PinEntryScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\app\db\local_db.dart (118 lines)

#### ShuaDiaryEntries.milestoneTag (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get milestoneTag
//  â†³ Called by: LocalDatabase
```

#### ShuaDiaryEntries.id (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â†³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryBlocks (Class)
```rust
// Lines 55-66 (12 LOC | Complexity 1) | used by 1 callers
class ShuaDiaryBlocks extends Table
//  â†³ Called by: LocalDatabase
```

#### LocalDatabase.schemaVersion (Function)
```rust
// Lines 74-74 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
int get schemaVersion
```

#### ShuaSyncQueue.actionType (Function)
```rust
// Lines 16-16 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
IntColumn get actionType
//  â†³ Called by: _SduiContainerState
```

#### ShuaDiaryEntries (Class)
```rust
// Lines 37-52 (16 LOC | Complexity 1) | used by 1 callers
class ShuaDiaryEntries extends Table
//  â†³ Called by: LocalDatabase
```

#### EpisodicMemories.primaryKey (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Set<Column> get primaryKey
//  â†³ Calls: ShuaSyncQueue.id
//  â†³ Called by: ShuaDiaryBlocks.primaryKey, ShuaDiaryEntries.primaryKey
```

#### ShuaDiaryBlocks.lamportClock (Function)
```rust
// Lines 62-62 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
IntColumn get lamportClock
//  â†³ Calls: ShuaDiaryEntries.lamportClock
```

#### ShuaDiaryBlocks.id (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â†³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryEntries.sentimentScore (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
RealColumn get sentimentScore
//  â†³ Called by: LocalDatabase
```

#### ShuaSyncQueue.id (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 6 callers | [Pure]
IntColumn get id
//  â†³ Called by: ShuaDiaryBlocks.primaryKey, ShuaDiaryBlocks.id, ShuaDiaryEntries.primaryKey, ShuaDiaryEntries.id, EpisodicMemories.primaryKey, EpisodicMemories.id
```

#### EpisodicMemories.memoryContent (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get memoryContent
```

#### ShuaSyncQueue.payload (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 19 callers | [Pure, Tested, CorePrimitive]
BlobColumn get payload
//  â†³ Called by: _SduiRadioState, _SduiCheckboxState, MessagePackCodec, MessagePackCodec.encode, _SduiDividerState, GovernorLogger._sendAsync, GovernorLogger, ApiClient, ApiClient.postBinary, SduiEventDispatcher._handleSubmitForm, SduiEventDispatcher._fireRpc, SduiEventDispatcher._handleAiCommand, SduiEventDispatcher, SduiEventDispatcher.onAction, _SduiTableState, _SduiTableState._parseContent, _SduiSpacerState, _SduiDropdownState, _SduiExpansionTileState
```

#### EpisodicMemories.id (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â†³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryBlocks.metadata (Function)
```rust
// Lines 60-60 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get metadata
//  â†³ Called by: LocalDatabase
```

#### EpisodicMemories.moodTag (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get moodTag
```

#### ShuaSyncQueue.logicalClock (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
IntColumn get logicalClock
```

#### EpisodicMemories.suggestedTags (Function)
```rust
// Lines 30-30 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get suggestedTags
```

#### EpisodicMemories.createdAt (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DateTimeColumn get createdAt
//  â†³ Calls: ShuaSyncQueue.createdAt
```

#### ShuaDiaryEntries.privacyTag (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get privacyTag
//  â†³ Called by: LocalDatabase
```

#### ShuaDiaryEntries.primaryKey (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Set<Column> get primaryKey
//  â†³ Calls: ShuaSyncQueue.id, EpisodicMemories.primaryKey
```

#### ShuaDiaryEntries.lamportClock (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IntColumn get lamportClock
//  â†³ Called by: ShuaDiaryBlocks.lamportClock
```

#### ShuaDiaryEntries.analysisState (Function)
```rust
// Lines 46-46 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get analysisState
//  â†³ Called by: LocalDatabase
```

#### ShuaDiaryBlocks.content (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 20 callers | [Pure, CorePrimitive]
TextColumn get content
//  â†³ Called by: _SduiHtmlViewerState, _SduiAudioState, _SduiScreenState, _NetworkConfigCardState, MediaUploader, _SduiMarkdownEditorState, _SduiMarkdownEditorState._buildReadonlyView, _SduiJbcPanelState, _SduiTerminalState, _SduiSandboxScreenState, _SduiListEditorState, _SduiListEditorState._loadFromContent, SduiButton, _SduiMapState, SduiTransport, SduiModuleCard, SduiNode, _SduiDocumentViewerState, SduiEventDispatcher, _SduiVideoState
```

#### EpisodicMemories (Class)
```rust
// Lines 23-34 (12 LOC | Complexity 1) | used by 1 callers
class EpisodicMemories extends Table
//  â†³ Called by: LocalDatabase
```

#### LocalDatabase.migration (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
MigrationStrategy get migration
```

#### ShuaSyncQueue.createdAt (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
IntColumn get createdAt
//  â†³ Called by: ShuaDiaryEntries.createdAt, EpisodicMemories.createdAt
```

#### ShuaDiaryEntries.title (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 16 callers | [Pure, CorePrimitive]
TextColumn get title
//  â†³ Called by: _SduiHtmlViewerState, _SduiAudioState, _DashboardScreenState, _SduiScreenState, HorAIzonClientShell, SettingsPage, MediaUploader, SduiTimelineEvent, _SduiTimelineState, _SduiSandboxScreenState, SduiIconRegistry, _SduiDocumentViewerState, _SduiVideoState, SduiGauge, _SduiChartState, _SduiExpansionTileState
```

#### ShuaDiaryEntries.createdAt (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DateTimeColumn get createdAt
//  â†³ Calls: ShuaSyncQueue.createdAt
```

#### ShuaSyncQueue (Class)
```rust
// Lines 12-20 (9 LOC | Complexity 1) | used by 1 callers
class ShuaSyncQueue extends Table
//  â†³ Calls: LocalDatabase
//  â†³ Called by: LocalDatabase
```

#### EpisodicMemories.priorityTier (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
IntColumn get priorityTier
```

#### ShuaSyncQueue.recordId (Function)
```rust
// Lines 15-15 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
TextColumn get recordId
```

#### LocalDatabase (Class)
```rust
// Lines 69-103 (35 LOC | Complexity 1) | used by 1 callers
@DriftDatabase(tables: [ShuaSyncQueue, EpisodicMemories, ShuaDiaryEntries, ShuaDiaryBlocks])
//  â†³ Calls: ShuaDiaryBlocks.metadata, ShuaDiaryEntries.milestoneTag, ShuaDiaryEntries.sentimentScore, ShuaDiaryEntries.analysisState, ShuaDiaryEntries.privacyTag, ShuaDiaryBlocks, ShuaDiaryEntries, EpisodicMemories, ShuaSyncQueue
//  â†³ Called by: ShuaSyncQueue
```

#### ShuaDiaryBlocks.blockType (Function)
```rust
// Lines 58-58 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get blockType
//  â†³ Called by: _SduiJbcPanelState
```

#### ShuaDiaryBlocks.sortKey (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
BlobColumn get sortKey
```

#### ShuaDiaryBlocks.primaryKey (Function)
```rust
// Lines 65-65 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Set<Column> get primaryKey
//  â†³ Calls: ShuaSyncQueue.id, EpisodicMemories.primaryKey
```

#### ShuaDiaryBlocks.entryId (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
TextColumn get entryId
//  â†³ Called by: _SduiScreenState, _SduiJbcPanelState, SduiJbcPanel, SduiEventDispatcher
```

#### ShuaSyncQueue.tableId (Function)
```rust
// Lines 14-14 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
IntColumn get tableId
```

#### EpisodicMemories.userId (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get userId
```

### C:\horAIzon_2.0\client_flutter\lib\app\dashboard_screen.dart (85 lines)

#### _DashboardScreenState.build (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### DashboardScreen (Class)
```rust
// Lines 8-13 (6 LOC | Complexity 1) | used by 2 callers
class DashboardScreen extends ConsumerStatefulWidget
//  â†³ Called by: _DashboardScreenState, DashboardScreen.createState
```

#### _DashboardScreenState._loadDashboard (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadDashboard()
//  â†³ Called by: _DashboardScreenState
```

#### _DashboardScreenState.initState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â†³ Called by: _DashboardScreenState
```

#### _DashboardScreenState (Class)
```rust
// Lines 15-89 (75 LOC | Complexity 1) | used by 1 callers
class _DashboardScreenState extends ConsumerState<DashboardScreen>
//  â†³ Calls: SduiNode, DashboardScreen, SduiRenderer, ShuaDiaryEntries.title, SduiTransport.decodeJson, SduiTransport, _DashboardScreenState._loadDashboard, _DashboardScreenState.initState
//  â†³ Called by: DashboardScreen.createState
```

#### DashboardScreen.createState (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<DashboardScreen> createState()
//  â†³ Calls: DashboardScreen, _DashboardScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\messagepack_codec.dart (13 lines)

#### MessagePackCodec (Class)
```rust
// Lines 4-14 (11 LOC | Complexity 1) | used by 1 callers
class MessagePackCodec
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: ApiClient
```

#### MessagePackCodec.decode (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static dynamic decode(Uint8List bytes)
```

#### MessagePackCodec.encode (Function)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
static Uint8List encode(dynamic payload)
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: ApiClient
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\utils\sdui_style_resolver.dart (52 lines)

#### SduiStyleResolver (Class)
```rust
// Lines 3-51 (49 LOC | Complexity 1) | used by 33 callers | [CorePrimitive]
class SduiStyleResolver
//  â†³ Calls: SduiFlexContext.of
//  â†³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, SduiGridView, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, _SduiMarkdownEditorState, SduiToggle, _SduiShimmerLoaderState.padding, _SduiDividerState, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, SduiListView, SduiButton, SduiRenderer, _SduiSliderState, _SduiDocumentViewerState, _SduiDrawingPadState, _SduiTableState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiStyleResolver.resolveTextStyle (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static TextStyle? resolveTextStyle(BuildContext context, int? slot)
//  â†³ Called by: _SduiMarkdownEditorState
```

#### SduiStyleResolver.resolveEdgeInsets (Function)
```rust
// Lines 14-14 (1 LOC | Complexity 1) | used by 10 callers | [Pure]
static EdgeInsetsGeometry? resolveEdgeInsets(dynamic val)
//  â†³ Called by: _SduiHtmlViewerState, _SduiContainerState, SduiGridView, _SduiShimmerLoaderState.padding, _SduiDividerState, SduiHeatmap, SduiListView, SduiRenderer, _SduiDocumentViewerState, _SduiCarouselState
```

#### SduiStyleResolver.resolveColor (Function)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 29 callers | [Pure, CorePrimitive]
static Color? resolveColor(BuildContext context, int? token)
//  â†³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, _SduiMarkdownEditorState, SduiToggle, _SduiDividerState, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, SduiButton, _SduiSliderState, _SduiDocumentViewerState, _SduiDrawingPadState, _SduiTableState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\events\sdui_event_dispatcher.dart (492 lines)

#### SduiEventDispatcher._syncToServer (Function)
```rust
// Lines 401-401 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _syncToServer(String nodeId, dynamic value)
//  â†³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher._fireRpc (Function)
```rust
// Lines 430-430 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _fireRpc(Map<int, dynamic> payload)
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: SduiEventDispatcher
```

#### SduiActionType (Enum)
```rust
// Lines 16-22 (7 LOC | Complexity 1) | used by 0 callers
enum SduiActionType
//  â†³ Calls: SduiEventDispatcher
```

#### SduiEventDispatcher.cancelPending (Function)
```rust
// Lines 382-382 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void cancelPending()
```

#### SduiEventDispatcher.onStateChange (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 28 callers | [Pure, CorePrimitive]
void onStateChange(String nodeId, dynamic value)
//  â†³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, MediaUploader, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, _SduiDividerState, SduiDatePicker, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, _SduiMapState, _SduiSliderState, _SduiDrawingPadState, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiEventDispatcher._handleAiCommand (Function)
```rust
// Lines 218-218 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _handleAiCommand(Map<int, dynamic> payload)
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.onAction (Function)
```rust
// Lines 86-86 (1 LOC | Complexity 1) | used by 11 callers | [Pure, CorePrimitive]
void onAction(Map<int, dynamic> payload, [BuildContext? context])
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiCheckboxState, _SduiCodeEditorState, SduiToggle, _SduiOrdinalSliderState, SduiChip, SduiHeatmap, SduiButton, _SduiMapState, _SduiSliderState
```

#### SduiEventDispatcher._resolveScreenIdFromLocation (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? _resolveScreenIdFromLocation(String location)
//  â†³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.flushPending (Function)
```rust
// Lines 368-368 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void flushPending()
//  â†³ Called by: _SduiScreenState
```

#### SduiEventDispatcher._resolveRpcMethodName (Function)
```rust
// Lines 396-396 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? _resolveRpcMethodName(int methodId)
//  â†³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher (Class)
```rust
// Lines 31-499 (469 LOC | Complexity 1) | used by 47 callers | [CorePrimitive, HighComplexity]
class SduiEventDispatcher
//  â†³ Calls: ShuaDiaryBlocks.entryId, SduiStateVault.get, SduiSocketManager.emitRpc, SduiEventDispatcher._resolveRpcMethodName, SduiIconRegistry.contains, BoundedRouteHistory.isEmpty, SduiSocketManager.injectLocalDelta, SduiEventDispatcher._handleAiCommand, SduiEventDispatcher._handleSubmitForm, ShuaDiaryBlocks.content, SduiEventDispatcher._resolveScreenIdFromLocation, BoundedRouteHistory.currentLocation, GovernorLogger.log, SduiEventDispatcher._fireRpc, SduiFlexContext.of, ShuaSyncQueue.payload, SduiEventDispatcher._syncToServer, SduiStateVault.set
//  â†³ Called by: SduiWrap, SduiRadio, SduiHtmlViewer, SduiContainer, SduiAudio, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, _SduiScreenState, SduiGridView, SduiCheckbox, SduiTimePicker, SduiTextInput, MediaUploader.pickAndUploadWithUi, SduiImage, SduiMarkdownEditor, SduiCodeEditor, SduiToggle, SduiShimmerLoader, SduiDivider, SduiDatePicker, SduiProgressBar, SduiTerminal, SduiOrdinalSlider, SduiTimeline, SduiChip, _SduiSandboxScreenState._buildBody, SduiHeatmap, SduiListEditor, SduiListView, SduiButton, SduiRenderer, SduiMap, SduiSlider, SduiModuleCard, SduiDocumentViewer, SduiTypeRegistry.buildNode, SduiDrawingPad, SduiStlViewer, SduiTable, SduiSpacer, SduiVideo, SduiCarousel, SduiGauge, SduiChart, SduiDropdown, SduiExpansionTile, SduiActionType
```

#### SduiEventDispatcher._handleSubmitForm (Function)
```rust
// Lines 457-457 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _handleSubmitForm(Map<int, dynamic> payload)
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.onReorder (Function)
```rust
// Lines 330-335 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
void onReorder(
//  â†³ Called by: _SduiContainerState
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\settings_page.dart (341 lines)

#### _NetworkConfigCard (Class)
```rust
// Lines 173-178 (6 LOC | Complexity 1) | used by 3 callers
class _NetworkConfigCard extends ConsumerStatefulWidget
//  â†³ Called by: _NetworkConfigCardState, _NetworkConfigCard.createState, SettingsPage
```

#### SettingsPage.build (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â†³ Called by: _NetworkConfigCardState.build
```

#### SettingsPage._buildColorSwatch (Function)
```rust
// Lines 125-131 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildColorSwatch(
//  â†³ Called by: SettingsPage
```

#### _NetworkConfigCardState._saveSettings (Function)
```rust
// Lines 208-208 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveSettings()
//  â†³ Called by: _NetworkConfigCardState
```

#### _NetworkConfigCardState.dispose (Function)
```rust
// Lines 199-199 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â†³ Called by: _NetworkConfigCardState
```

#### _NetworkConfigCardState (Class)
```rust
// Lines 180-335 (156 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _NetworkConfigCardState extends ConsumerState<_NetworkConfigCard>
//  â†³ Calls: _NetworkConfigCard, _NetworkConfigCardState._saveSettings, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, ShuaDiaryBlocks.content, SduiFlexContext.of, ConfigNotifier.updateWorkspaceRoot, ConfigNotifier.updateGeminiApiKey, ConfigNotifier.updateOllamaModel, ConfigNotifier.updateOllamaUrl, ConfigNotifier.updateSyncBaseUrl, _NetworkConfigCardState.dispose, _NetworkConfigCardState.initState
//  â†³ Called by: _NetworkConfigCard.createState
```

#### _NetworkConfigCardState.initState (Function)
```rust
// Lines 188-188 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â†³ Called by: _NetworkConfigCardState
```

#### SettingsPage (Class)
```rust
// Lines 6-171 (166 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SettingsPage extends ConsumerWidget
//  â†³ Calls: ThemeNotifier.updatePrimary, ThemeNotifier.updateSecondary, _NetworkConfigCard, ThemeNotifier.updateTextScale, ThemeNotifier.updateAnimationMs, SettingsPage._buildColorSwatch, AppThemeSeeds, ThemeNotifier.toggleBrightness, ShuaDiaryEntries.title, SduiFlexContext.of, _SduiShimmerLoaderState.padding
```

#### _NetworkConfigCard.createState (Function)
```rust
// Lines 177-177 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_NetworkConfigCard> createState()
//  â†³ Calls: _NetworkConfigCard, _NetworkConfigCardState
```

#### _NetworkConfigCardState.build (Function)
```rust
// Lines 225-225 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â†³ Calls: SettingsPage.build
```

### C:\horAIzon_2.0\client_flutter\lib\app\theme\theme_provider.dart (151 lines)

#### ThemeNotifier.build (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ThemeState build()
//  â†³ Calls: ThemeState
```

#### ThemeNotifier._saveSettings (Function)
```rust
// Lines 88-88 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _saveSettings()
//  â†³ Called by: ThemeNotifier
```

#### ThemeNotifier.updateAnimationMs (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateAnimationMs(int ms)
//  â†³ Called by: SettingsPage
```

#### ThemeNotifier._loadSettings (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadSettings()
//  â†³ Called by: ThemeNotifier
```

#### ThemeNotifier.updatePrimary (Function)
```rust
// Lines 115-115 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updatePrimary(Color newColor)
//  â†³ Called by: SettingsPage
```

#### ThemeState (Class)
```rust
// Lines 13-51 (39 LOC | Complexity 1) | used by 3 callers
class ThemeState
//  â†³ Calls: ThemeNotifier
//  â†³ Called by: ThemeNotifier.build, ThemeState.copyWith, ThemeNotifier
```

#### ThemeState.compiledData (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ThemeData get compiledData
//  â†³ Calls: ThemeCompiler.compile, ThemeCompiler
//  â†³ Called by: HorAIzonClientShell
```

#### ThemeNotifier.updateTextScale (Function)
```rust
// Lines 133-133 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateTextScale(double scale)
//  â†³ Called by: SettingsPage
```

#### ThemeNotifier._logThemeChange (Function)
```rust
// Lines 139-139 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _logThemeChange(String detail)
//  â†³ Called by: ThemeNotifier
```

#### ThemeNotifier.toggleBrightness (Function)
```rust
// Lines 105-105 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void toggleBrightness()
//  â†³ Called by: SettingsPage
```

#### ThemeNotifier (Class)
```rust
// Lines 53-147 (95 LOC | Complexity 1) | used by 1 callers
class ThemeNotifier extends Notifier<ThemeState>
//  â†³ Calls: SystemEvents, DiagnosticResult.success, DiagnosticResult, DiagnosticsHistoryNotifier.logResult, ThemeNotifier._logThemeChange, ThemeNotifier._saveSettings, ThemeState.copyWith, GovernorLogger.log, ThemeState, ThemeNotifier._loadSettings
//  â†³ Called by: ThemeState
```

#### ThemeNotifier.updateSecondary (Function)
```rust
// Lines 121-121 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateSecondary(Color newColor)
//  â†³ Called by: SettingsPage
```

#### ThemeState.copyWith (Function)
```rust
// Lines 36-42 (7 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ThemeState copyWith(
//  â†³ Calls: ThemeState
//  â†³ Called by: ThemeNotifier
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_transport.dart (269 lines)

#### SduiTransport.decodeJson (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
static List<SduiNode> decodeJson(String jsonString)
//  â†³ Calls: SduiNode
//  â†³ Called by: _DashboardScreenState, SduiSocketManager
```

#### SduiTransport (Class)
```rust
// Lines 5-257 (253 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class SduiTransport
//  â†³ Calls: SduiTransport._insertAfterRecursive, SduiTransport._patchNodeInTree, SduiTransport._insertAfterInTree, SduiTransport._nodeFromMap, SduiTransport._removeNodeFromTree, SduiTransport.applyDelta, SduiNode, ShuaDiaryBlocks.content, SduiTransport._parseList
//  â†³ Called by: _DashboardScreenState, _SduiScreenState, SduiSocketManager
```

#### SduiTransport.decode (Function)
```rust
// Lines 7-7 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static List<SduiNode> decode(Uint8List bytes)
//  â†³ Calls: SduiNode
```

#### SduiTransport.patch (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static SduiNode patch(SduiNode existing, Map<String, dynamic> delta)
//  â†³ Calls: SduiNode
```

#### SduiTransport._insertAfterInTree (Function)
```rust
// Lines 116-118 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _insertAfterInTree(
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiTransport
```

#### SduiTransport._removeNodeFromTree (Function)
```rust
// Lines 100-100 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _removeNodeFromTree(List<SduiNode> tree, String nodeId)
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiTransport
```

#### SduiTransport.applyDelta (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
static List<SduiNode> applyDelta(List<SduiNode> tree, dynamic rawDelta)
//  â†³ Calls: SduiNode
//  â†³ Called by: _SduiScreenState, SduiSocketManager, SduiTransport
```

#### SduiTransport._patchNodeInTree (Function)
```rust
// Lines 161-163 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _patchNodeInTree(
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiTransport
```

#### SduiTransport._insertAfterRecursive (Function)
```rust
// Lines 129-131 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static (List<SduiNode>, bool) _insertAfterRecursive(
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiTransport
```

#### SduiTransport._parseList (Function)
```rust
// Lines 187-187 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _parseList(dynamic decodedList)
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiTransport
```

#### SduiTransport._nodeFromMap (Function)
```rust
// Lines 201-201 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static SduiNode _nodeFromMap(Map map)
//  â†³ Calls: SduiNode
//  â†³ Called by: SduiTransport
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\utils\binary_lexo_rank.dart (100 lines)

#### BinaryLexoRank (Class)
```rust
// Lines 5-101 (97 LOC | Complexity 1) | used by 0 callers
class BinaryLexoRank
//  â†³ Calls: BoundedRouteHistory.isEmpty
```

#### BinaryLexoRank.after (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static Uint8List after(Uint8List a)
```

#### BinaryLexoRank.between (Function)
```rust
// Lines 8-8 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static Uint8List between(Uint8List a, Uint8List b)
```

#### BinaryLexoRank.before (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static Uint8List before(Uint8List b)
```

### C:\horAIzon_2.0\client_flutter\lib\core\governor\metrics_snapshot.dart (88 lines)

#### ModuleMetrics.ModuleMetrics (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory ModuleMetrics.fromJson(Map<String, dynamic> json)
//  â†³ Calls: ModuleMetrics.fromJson, ModuleMetrics
```

#### MetricsSnapshot.MetricsSnapshot (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory MetricsSnapshot.fromJson(Map<String, dynamic> json)
//  â†³ Calls: ModuleMetrics.fromJson, MetricsSnapshot
```

#### ModuleMetrics.fromJson (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
factory ModuleMetrics.fromJson(Map<String, dynamic> json)
//  â†³ Called by: MetricsSnapshot, MetricsSnapshot.MetricsSnapshot, ModuleMetrics.ModuleMetrics
```

#### ModuleMetrics (Class)
```rust
// Lines 7-30 (24 LOC | Complexity 1) | used by 2 callers
class ModuleMetrics
//  â†³ Called by: MetricsSnapshot, ModuleMetrics.ModuleMetrics
```

#### MetricsSnapshot.fromJson (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory MetricsSnapshot.fromJson(Map<String, dynamic> json)
```

#### MetricsSnapshot (Class)
```rust
// Lines 34-92 (59 LOC | Complexity 1) | used by 1 callers
class MetricsSnapshot
//  â†³ Calls: ModuleMetrics.fromJson, ModuleMetrics
//  â†³ Called by: MetricsSnapshot.MetricsSnapshot
```

#### MetricsSnapshot.toString (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
String toString()
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\diagnostics_provider.dart (352 lines)

#### DiagnosticsHistoryNotifier.build (Function)
```rust
// Lines 112-112 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
DiagnosticsState build()
//  â†³ Calls: DiagnosticsState
```

#### DiagnosticsState.successRate (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double get successRate
//  â†³ Called by: _SuccessRateBadge
```

#### DiagnosticsState (Class)
```rust
// Lines 24-102 (79 LOC | Complexity 1) | used by 8 callers
class DiagnosticsState
//  â†³ Calls: DiagnosticResult
//  â†³ Called by: DiagnosticsHistoryNotifier.build, DiagnosticsState.copyWith, _SuccessRateBadge, _SduiTerminalState._buildSubsystemFilterBar, _SduiTerminalState._buildHeader, _SduiTerminalState, _SduiTerminalState._getFilteredLogs, DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.setTelemetryProfile (Function)
```rust
// Lines 168-168 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void setTelemetryProfile(TelemetryProfile profile)
//  â†³ Calls: TelemetryProfile
//  â†³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsState.copyWith (Function)
```rust
// Lines 67-79 (13 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
DiagnosticsState copyWith(
//  â†³ Calls: DiagnosticResult, DiagnosticsState
//  â†³ Called by: DiagnosticsHistoryNotifier
```

#### TelemetryProfile (Enum)
```rust
// Lines 12-21 (10 LOC | Complexity 1) | used by 2 callers
enum TelemetryProfile
//  â†³ Calls: GovernorLogger.log, DiagnosticResult.success, DiagnosticResult.failure, SystemDiagnostic, DiagnosticSeverity, BoundedRouteHistory.isEmpty, DiagnosticResult, DiagnosticsHistoryNotifier
//  â†³ Called by: DiagnosticsHistoryNotifier.setTelemetryProfile, DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.updateLimits (Function)
```rust
// Lines 144-149 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateLimits(
//  â†³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.logResult (Function)
```rust
// Lines 203-203 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
void logResult(DiagnosticResult result, {bool fromRemote = false})
//  â†³ Calls: DiagnosticResult
//  â†³ Called by: DiagnosticsHistoryNotifier, ThemeNotifier, BoundedRouteHistory, AuthNotifier
```

#### DiagnosticsHistoryNotifier (Class)
```rust
// Lines 110-346 (237 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiagnosticsHistoryNotifier extends Notifier<DiagnosticsState>
//  â†³ Calls: DiagnosticResult, DiagnosticResult.latencyMs, DiagnosticResult.isFailure, DiagnosticResult.isCritical, OccurrenceEntry, GovernorLogger.log, DiagnosticSeverity, TelemetryProfile, DiagnosticsHistoryNotifier.setTelemetryProfile, DiagnosticsHistoryNotifier.updateLimits, DiagnosticsHistoryNotifier._truncate, DiagnosticsState.copyWith, DiagnosticsState, DiagnosticsHistoryNotifier.logResult
//  â†³ Called by: TelemetryProfile
```

#### DiagnosticsHistoryNotifier.resetLimitsToDefault (Function)
```rust
// Lines 198-198 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void resetLimitsToDefault()
```

#### DiagnosticsHistoryNotifier.clearHistory (Function)
```rust
// Lines 335-335 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void clearHistory()
//  â†³ Called by: _SduiTerminalState
```

#### DiagnosticsHistoryNotifier._truncate (Function)
```rust
// Lines 136-136 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<DiagnosticResult> _truncate(List<DiagnosticResult> list, int limit)
//  â†³ Calls: DiagnosticResult
//  â†³ Called by: DiagnosticsHistoryNotifier
```

### C:\horAIzon_2.0\client_flutter\lib\app\theme\theme_compiler.dart (43 lines)

#### ThemeCompiler.compile (Function)
```rust
// Lines 5-10 (6 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
static ThemeData compile(
//  â†³ Called by: ThemeState.compiledData
```

#### ThemeCompiler (Class)
```rust
// Lines 4-40 (37 LOC | Complexity 1) | used by 1 callers
class ThemeCompiler
//  â†³ Called by: ThemeState.compiledData
```

### C:\horAIzon_2.0\client_flutter\lib\app\route_history.dart (166 lines)

#### BoundedRouteHistory.jumpToNewest (Function)
```rust
// Lines 104-104 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
void jumpToNewest()
```

#### RouteNode (Class)
```rust
// Lines 160-171 (12 LOC | Complexity 1) | used by 1 callers
class RouteNode
//  â†³ Called by: BoundedRouteHistory
```

#### BoundedRouteHistory.isEmpty (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 25 callers | [Pure, Tested, CorePrimitive]
bool get isEmpty
//  â†³ Called by: _SduiContainerState, TelemetryProfile, _SduiAudioState, SduiImage, _SduiMarkdownEditorState, SyntaxHighlightingController, _SduiJbcPanelState, _SduiTerminalState, _SduiTimelineState, _SduiSandboxScreenState, SduiHeatmap, _SduiListEditorState, SduiListView, BinaryLexoRank, SduiModuleCard, _SduiDocumentViewerState, SduiEventDispatcher, _DrawingPainter, _SduiDrawingPadState, AuthNotifier, _SduiTableState, _SduiVideoState, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### BoundedRouteHistory.updateMaxCount (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
void updateMaxCount(int newMax)
```

#### BoundedRouteHistory._logRouteEvent (Function)
```rust
// Lines 148-148 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _logRouteEvent(String detail)
//  â†³ Called by: BoundedRouteHistory
```

#### BoundedRouteHistory.currentLocation (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
String? get currentLocation
//  â†³ Called by: AdaptiveShell, SduiEventDispatcher
```

#### BoundedRouteHistory.moveBack (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void moveBack()
//  â†³ Called by: AdaptiveShell
```

#### BoundedRouteHistory.canGoBack (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
bool get canGoBack
//  â†³ Called by: AdaptiveShell, BoundedRouteHistory
```

#### BoundedRouteHistory.addRoute (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
void addRoute(String location)
```

#### BoundedRouteHistory.canGoForward (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
bool get canGoForward
//  â†³ Called by: AdaptiveShell, BoundedRouteHistory
```

#### BoundedRouteHistory (Class)
```rust
// Lines 13-156 (144 LOC | Complexity 1) | used by 0 callers
class BoundedRouteHistory extends ChangeNotifier
//  â†³ Calls: DiagnosticsHistoryNotifier.logResult, SystemEvents, DiagnosticResult.success, DiagnosticResult, BoundedRouteHistory.canGoBack, BoundedRouteHistory.canGoForward, BoundedRouteHistory._logRouteEvent, RouteNode
```

#### BoundedRouteHistory.moveForward (Function)
```rust
// Lines 83-83 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void moveForward()
//  â†³ Called by: AdaptiveShell
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\sdui_sandbox_screen.dart (291 lines)

#### _SduiSandboxScreenState.initState (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â†³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState._parseLegacyV4Format (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode _parseLegacyV4Format(Map<String, dynamic> map)
//  â†³ Calls: SduiNode
//  â†³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState._parseIntMap (Function)
```rust
// Lines 83-83 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
dynamic _parseIntMap(dynamic value)
//  â†³ Called by: _SduiSandboxScreenState
```

#### SduiSandboxScreen (Class)
```rust
// Lines 8-13 (6 LOC | Complexity 1) | used by 2 callers
class SduiSandboxScreen extends ConsumerStatefulWidget
//  â†³ Called by: _SduiSandboxScreenState, SduiSandboxScreen.createState
```

#### _SduiSandboxScreenState._loadBlueprints (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<MapEntry<String, SduiNode>>> _loadBlueprints()
//  â†³ Calls: SduiNode
//  â†³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState (Class)
```rust
// Lines 15-291 (277 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiSandboxScreenState extends ConsumerState<SduiSandboxScreen>
//  â†³ Calls: SduiSandboxScreen, SduiFlexContext.of, SduiTypeRegistry.buildNode, SduiTypeRegistry, _SduiShimmerLoaderState.padding, _SduiSandboxScreenState._buildBody, BoundedRouteHistory.isEmpty, ShuaDiaryEntries.title, ShuaDiaryBlocks.content, _SduiSandboxScreenState._parseIntMap, SduiNode, _SduiSandboxScreenState._parseLegacyV4Format, _SduiSandboxScreenState._loadBlueprints, _SduiSandboxScreenState._loadAll, _SduiSandboxScreenState.initState
//  â†³ Called by: SduiSandboxScreen.createState
```

#### SduiSandboxScreen.createState (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSandboxScreen> createState()
//  â†³ Calls: SduiSandboxScreen, _SduiSandboxScreenState
```

#### _SduiSandboxScreenState._loadAll (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadAll()
//  â†³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState.build (Function)
```rust
// Lines 109-109 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiSandboxScreenState._buildBody (Function)
```rust
// Lines 159-159 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildBody(SduiEventDispatcher dispatcher)
//  â†³ Calls: SduiEventDispatcher
//  â†³ Called by: _SduiSandboxScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\media_uploader.dart (552 lines)

#### MediaUploadException (Class)
```rust
// Lines 67-74 (8 LOC | Complexity 1) | used by 1 callers
class MediaUploadException implements Exception
//  â†³ Called by: MediaUploader
```

#### MediaUploadResult (Class)
```rust
// Lines 31-47 (17 LOC | Complexity 1) | used by 5 callers
class MediaUploadResult
//  â†³ Calls: MediaUploader
//  â†³ Called by: MediaUploader._chunkedUpload, MediaUploader._simpleUpload, MediaUploader.uploadBytes, MediaUploader.uploadFile, MediaUploader
```

#### MediaUploader._listenToSseProgress (Function)
```rust
// Lines 322-325 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
void _listenToSseProgress(
//  â†³ Calls: UploadProgressEvent
//  â†³ Called by: MediaUploader
```

#### MediaUploader._simpleUpload (Function)
```rust
// Lines 167-173 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> _simpleUpload(
//  â†³ Calls: MediaUploadResult
//  â†³ Called by: MediaUploader
```

#### MediaUploader.pickAndUploadWithUi (Function)
```rust
// Lines 438-446 (9 LOC | Complexity 1) | used by 5 callers | [Pure]
Future<void> pickAndUploadWithUi(
//  â†³ Calls: SduiEventDispatcher
//  â†³ Called by: _SduiHtmlViewerState, _SduiAudioState, SduiImage, _SduiDocumentViewerState, _SduiVideoState
```

#### MediaUploader._chunkedUpload (Function)
```rust
// Lines 211-216 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> _chunkedUpload(
//  â†³ Calls: MediaUploadResult
//  â†³ Called by: MediaUploader
```

#### MediaUploader.uploadBytes (Function)
```rust
// Lines 140-146 (7 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Future<MediaUploadResult> uploadBytes(
//  â†³ Calls: MediaUploadResult
```

#### UploadProgressEvent (Class)
```rust
// Lines 49-61 (13 LOC | Complexity 1) | used by 2 callers
class UploadProgressEvent
//  â†³ Called by: MediaUploader._listenToSseProgress, MediaUploader
```

#### MediaUploader (Class)
```rust
// Lines 99-569 (471 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class MediaUploader
//  â†³ Calls: SduiEventDispatcher.onStateChange, SduiStateVault.set, MediaUploader.uploadFile, ShuaDiaryBlocks.content, ShuaDiaryEntries.title, SduiFlexContext.of, MediaUploader._showError, UploadProgressEvent, MediaUploader._listenToSseProgress, MediaUploadException, MediaUploader._deterministicId, MediaUploadResult, MediaUploader._assertStatus, MediaUploader._inferMime, MediaUploader._chunkedUpload, MediaUploader._simpleUpload, GovernorLogger.log
//  â†³ Called by: MediaUploadResult
```

#### MediaUploadException.toString (Function)
```rust
// Lines 73-73 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
String toString()
```

#### MediaUploader.uploadFile (Function)
```rust
// Lines 107-111 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> uploadFile(
//  â†³ Calls: MediaUploadResult
//  â†³ Called by: MediaUploader
```

#### MediaUploader._showError (Function)
```rust
// Lines 560-560 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showError(BuildContext context, String message)
//  â†³ Called by: MediaUploader
```

#### MediaUploader._assertStatus (Function)
```rust
// Lines 382-382 (1 LOC | Complexity 1) | used by 1 callers | [Io]
void _assertStatus(http.Response response)
//  â†³ Called by: MediaUploader
```

#### MediaUploader._inferMime (Function)
```rust
// Lines 418-418 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _inferMime(String filename)
//  â†³ Called by: MediaUploader
```

#### MediaUploader._deterministicId (Function)
```rust
// Lines 407-407 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _deterministicId(String filename, int size)
//  â†³ Called by: MediaUploader
```

### C:\horAIzon_2.0\client_flutter\lib\core\logging\governor_logger.dart (114 lines)

#### GovernorLogger._sendAsync (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _sendAsync(Map<int, dynamic> payload)
//  â†³ Calls: ShuaSyncQueue.payload
//  â†³ Called by: GovernorLogger
```

#### GovernorLogger._uri (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Uri get _uri
//  â†³ Called by: GovernorLogger
```

#### GovernorLogger.setMinLogLevel (Function)
```rust
// Lines 67-67 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
void setMinLogLevel(int level)
```

#### GovernorLogger.log (Function)
```rust
// Lines 85-93 (9 LOC | Complexity 1) | used by 20 callers | [Pure, CorePrimitive]
void log(
//  â†³ Called by: _SduiHtmlViewerState, _SduiContainerState, TelemetryProfile, DiagnosticsHistoryNotifier, _SduiAudioState, _SduiScreenState, SduiScreen, SduiGridView, MediaUploader, _SduiJbcPanelState, _SduiTerminalState, ConfigNotifier, ThemeNotifier, SduiHeatmap, SduiListView, SduiSocketManager, SduiModuleCard, SduiNode, SduiEventDispatcher, _SduiVideoState
```

#### GovernorLogger (Class)
```rust
// Lines 54-154 (101 LOC | Complexity 1) | used by 1 callers
class GovernorLogger
//  â†³ Calls: GovernorLogger._uri, GovernorLogger._sendAsync, ShuaSyncQueue.payload
//  â†³ Called by: GovernorLogger.GovernorLogger
```

#### GovernorLogger.GovernorLogger (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory GovernorLogger()
//  â†³ Calls: GovernorLogger
```

### C:\horAIzon_2.0\client_flutter\lib\app\adaptive_shell.dart (245 lines)

#### AdaptiveShell._buildStatIcon (Function)
```rust
// Lines 229-229 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStatIcon(IconData icon, String value, Color color)
//  â†³ Called by: AdaptiveShell
```

#### AdaptiveShell._buildMobileStat (Function)
```rust
// Lines 210-210 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMobileStat(IconData icon, String value, Color color)
//  â†³ Called by: AdaptiveShell
```

#### AdaptiveShell (Class)
```rust
// Lines 10-250 (241 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class AdaptiveShell extends ConsumerWidget
//  â†³ Calls: SduiFlexContext.of, AdaptiveShell._buildStatIcon, _SduiShimmerLoaderState.padding, AdaptiveShell._getSelectedIndex, BoundedRouteHistory.moveForward, BoundedRouteHistory.canGoForward, BoundedRouteHistory.moveBack, BoundedRouteHistory.canGoBack, BoundedRouteHistory.currentLocation, AdaptiveShell._buildMobileStat
```

#### AdaptiveShell.build (Function)
```rust
// Lines 16-16 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### AdaptiveShell._getSelectedIndex (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int _getSelectedIndex(BuildContext context)
//  â†³ Called by: AdaptiveShell
```

### C:\horAIzon_2.0\client_flutter\ios\Flutter\ephemeral\flutter_lldb_helper.py (25 lines)

#### __lldb_init_module (Function)
```rust
// Lines 23-31 (9 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
def __lldb_init_module(debugger: lldb.SBDebugger, _)
```

#### handle_new_rx_page (Function)
```rust
// Lines 6-21 (16 LOC | Complexity 2) | used by 0 callers | [Io, PotentialDeadCode]
def handle_new_rx_page(frame: lldb.SBFrame, bp_loc, extra_args, intern_dict)
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\registry\sdui_type_registry.dart (66 lines)

#### SduiTypeRegistry (Class)
```rust
// Lines 47-110 (64 LOC | Complexity 1) | used by 2 callers
class SduiTypeRegistry
//  â†³ Calls: _SduiShimmerLoaderState.padding, SduiModuleCard, SduiDropdown, SduiWrap, SduiExpansionTile, SduiSpacer, SduiDivider, SduiTimePicker, SduiDatePicker, SduiHtmlViewer, SduiCarousel, SduiDocumentViewer, SduiTimeline, SduiGauge, SduiChart, SduiStlViewer, SduiImage, SduiVideo, SduiAudio, SduiDrawingPad, SduiMap, SduiHeatmap, SduiTerminal, SduiToggle, SduiTextInput, SduiTable, SduiShimmerLoader, SduiRadio, SduiProgressBar, SduiSlider, SduiOrdinalSlider, SduiListView, SduiListEditor, SduiGridView, SduiContainer, SduiChip, SduiCheckbox, SduiButton, SduiCodeEditor, SduiMarkdownEditor
//  â†³ Called by: _SduiSandboxScreenState, SduiRenderer
```

#### SduiTypeRegistry.buildNode (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
static Widget buildNode(SduiNode node, SduiEventDispatcher dispatcher, BuildContext context)
//  â†³ Calls: SduiEventDispatcher, SduiNode
//  â†³ Called by: _SduiSandboxScreenState, SduiRenderer
```

#### SduiTypeRegistry.register (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static void register(int typeId, SduiWidgetBuilder builder)
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\registry\sdui_icon_registry.dart (126 lines)

#### SduiIconRegistry.resolve (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 8 callers | [Pure]
static IconData resolve(String? name)
//  â†³ Called by: _SduiTextInputState, _SduiTimelineState, SduiChip, _SduiListEditorState, SduiButton, _SduiMapState, SduiModuleCard, _SduiExpansionTileState
```

#### SduiIconRegistry (Class)
```rust
// Lines 10-133 (124 LOC | Complexity 1) | used by 8 callers
class SduiIconRegistry
//  â†³ Calls: ShuaDiaryEntries.title
//  â†³ Called by: _SduiTextInputState, _SduiTimelineState, SduiChip, _SduiListEditorState, SduiButton, _SduiMapState, SduiModuleCard, _SduiExpansionTileState
```

#### SduiIconRegistry.contains (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 7 callers | [Pure, Tested]
static bool contains(String name)
//  â†³ Called by: _SduiHtmlViewerState, SduiTimePicker, SduiDatePicker, _SduiListEditorState, SduiSocketManager, SduiEventDispatcher, _SduiDropdownState
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\theme_seeds.dart (20 lines)

#### ThemeSeedOption (Class)
```rust
// Lines 3-8 (6 LOC | Complexity 1) | used by 1 callers
class ThemeSeedOption
//  â†³ Called by: AppThemeSeeds
```

#### AppThemeSeeds (Class)
```rust
// Lines 11-24 (14 LOC | Complexity 1) | used by 1 callers
class AppThemeSeeds
//  â†³ Called by: SettingsPage
```
