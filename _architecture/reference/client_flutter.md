# Repository Export

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_socket_provider.dart (720 lines)

#### SduiSocketManager.listenForReplace (Function)
```rust
// Lines 334-337 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForReplace(
//  â³ Calls: SduiNode
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.emitRpc (Function)
```rust
// Lines 491-491 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
void emitRpc(String method, Map<String, dynamic> params)
//  â³ Called by: _SduiTextInputState, SduiSocketManager, SduiEventDispatcher
```

#### SduiSocketManager.listenForConnect (Function)
```rust
// Lines 427-427 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForConnect(VoidCallback onConnect, {required String screenId})
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.evictCache (Function)
```rust
// Lines 479-479 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void evictCache(String screenId)
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.sendRpcWithResponse (Function)
```rust
// Lines 509-513 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<dynamic> sendRpcWithResponse(
//  â³ Called by: _SduiJbcPanelState
```

#### SduiSocketManager._isStaticScreen (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool _isStaticScreen(String screenId)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager._socketForMethod (Function)
```rust
// Lines 581-581 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket? _socketForMethod(String method)
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.connectViaGateway (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void connectViaGateway(String screenId)
//  â³ Called by: SduiSocketManager.connect
```

#### SduiSocketManager.socketForScreen (Function)
```rust
// Lines 141-141 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket? socketForScreen(String screenId)
//  â³ Called by: _SduiJbcPanelState
```

#### SduiSocketManager.disconnect (Function)
```rust
// Lines 149-149 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void disconnect()
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.connect (Function)
```rust
// Lines 147-147 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void connect()
//  â³ Calls: SduiSocketManager.connectViaGateway
//  â³ Called by: SduiSocketManager
```

#### SduiSocketManager.reRequestScreen (Function)
```rust
// Lines 447-447 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void reRequestScreen(String screenId)
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.listenForHotReload (Function)
```rust
// Lines 389-391 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForHotReload(
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager._socketFor (Function)
```rust
// Lines 63-63 (1 LOC | Complexity 1) | used by 1 callers | [Io]
io.Socket _socketFor(String moduleId)
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

#### SduiSocketManager.injectLocalDelta (Function)
```rust
// Lines 563-563 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void injectLocalDelta(String screenId, Map<String, dynamic> delta)
//  â³ Called by: SduiEventDispatcher
```

#### SduiSocketManager.listenForPatches (Function)
```rust
// Lines 362-365 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
VoidCallback listenForPatches(
//  â³ Called by: _SduiScreenState
```

#### SduiSocketManager.requestScreen (Function)
```rust
// Lines 157-157 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<SduiNode>> requestScreen(String screenId)
//  â³ Calls: SduiNode
//  â³ Called by: SduiSocketManager
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
//  â³ Calls: SduiNode, SduiIconRegistry.contains, SduiTransport.applyDelta, SduiSocketManager._socketForMethod, SduiSocketManager.requestScreen, SduiSocketManager.emitRpc, SduiSocketManager._ensureSocketListeners, SduiTransport.decodeJson, SduiTransport, SduiStateVault.get, SduiSocketManager.disconnect, SduiSocketManager._socketFor, SduiSocketManager._moduleIdForScreen, SduiSocketManager._isStaticScreen, SduiSocketManager.connect, SduiFlexContext.of, GovernorLogger.log
//  â³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_list_view.dart (103 lines)

#### SduiListView (Class)
```rust
// Lines 9-108 (100 LOC | Complexity 1) | used by 1 callers
class SduiListView extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiRenderer, SduiNode.interpolate, _SduiShimmerLoaderState.maxHeight, BoundedRouteHistory.isEmpty, GovernorLogger.log, SduiNode.contentVal, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, _SduiShimmerLoaderState.padding, SduiNode.behavior, SduiListView._num, SduiListView._int
//  â³ Called by: SduiTypeRegistry
```

#### SduiListView._num (Function)
```rust
// Lines 103-103 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double? _num(int key)
//  â³ Called by: SduiListView
```

#### SduiListView._int (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int? _int(int key)
//  â³ Called by: SduiListView
```

#### SduiListView.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
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
//  â³ Called by: _SduiScreenState
```

#### SduiStateVault.get (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
T? get<T>(String nodeId)
//  â³ Called by: SduiSocketManager, SduiEventDispatcher
```

#### SduiStateVault.set (Function)
```rust
// Lines 11-11 (1 LOC | Complexity 1) | used by 16 callers | [Pure, CorePrimitive]
void set(String nodeId, dynamic value)
//  â³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, _SduiCheckboxState, SduiTimePicker, MediaUploader, _SduiDividerState, SduiDatePicker, _SduiMapState, SduiEventDispatcher, _SduiDrawingPadState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiStateVault.releaseScope (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void releaseScope(String screenId)
//  â³ Called by: _SduiScreenState
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

#### _SduiDrawingPadState.build (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _DrawingPainter (Class)
```rust
// Lines 201-232 (32 LOC | Complexity 1) | used by 2 callers
class _DrawingPainter extends CustomPainter
//  â³ Calls: BoundedRouteHistory.isEmpty, _DrawingPainter.paint
//  â³ Called by: _DrawingPainter.shouldRepaint, _SduiDrawingPadState
```

#### _SduiDrawingPadState (Class)
```rust
// Lines 22-199 (178 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDrawingPadState extends ConsumerState<SduiDrawingPad>
//  â³ Calls: SduiDrawingPad, _SduiShimmerLoaderState.padding, _SduiDrawingPadState._clearCanvas, _DrawingPainter, _SduiDrawingPadState._serializeStrokes, _SduiShimmerLoaderState.borderRadius, _SduiDrawingPadState._parseSvgPathToStrokes, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of, SduiEventDispatcher.onStateChange, SduiStateVault.set, BoundedRouteHistory.isEmpty
//  â³ Called by: SduiDrawingPad.createState
```

#### _DrawingPainter.paint (Function)
```rust
// Lines 211-211 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Called by: _DrawingPainter
```

#### _SduiDrawingPadState._serializeStrokes (Function)
```rust
// Lines 46-46 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _serializeStrokes()
//  â³ Called by: _SduiDrawingPadState
```

#### _SduiDrawingPadState._clearCanvas (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _clearCanvas(String bindKey)
//  â³ Called by: _SduiDrawingPadState
```

#### SduiDrawingPad (Class)
```rust
// Lines 8-20 (13 LOC | Complexity 1) | used by 3 callers
class SduiDrawingPad extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDrawingPadState, SduiDrawingPad.createState, SduiTypeRegistry
```

#### _DrawingPainter.shouldRepaint (Function)
```rust
// Lines 229-229 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool shouldRepaint(covariant _DrawingPainter oldDelegate)
//  â³ Calls: _DrawingPainter
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_screen.dart (318 lines)

#### _SduiScreenState._findNodeByIdSuffix (Function)
```rust
// Lines 186-186 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode? _findNodeByIdSuffix(List<SduiNode> nodes, String suffix)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState._buildBody (Function)
```rust
// Lines 235-239 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildBody(
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiScreenState
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
//  â³ Calls: SduiSocketManager.getScreen, GovernorLogger.log
//  â³ Called by: _SduiScreenState, SduiScreen.createState
```

#### _SduiScreenState._resolveTitle (Function)
```rust
// Lines 166-166 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _resolveTitle()
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState.initState (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiScreenState
```

#### SduiScreen.createState (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiScreen> createState()
//  â³ Calls: SduiScreen, _SduiScreenState
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
// Lines 131-131 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState (Class)
```rust
// Lines 40-322 (283 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiScreenState extends ConsumerState<SduiScreen>
//  â³ Calls: SduiSocketManager, SduiStateVault, SduiEventDispatcher, SduiScreen, SduiRenderer, ShuaDiaryBlocks.content, SduiNode, SduiShimmerLoader, _SduiShimmerLoaderState.padding, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, ShuaDiaryBlocks.entryId, SduiJbcPanel, _SduiScreenState._resolveTitle, ShuaDiaryEntries.title, SduiNode.contentVal, _SduiScreenState._findNodeByIdSuffix, SduiTransport.applyDelta, SduiTransport, _SduiScreenState.dispose, SduiSocketManager.evictCache, SduiStateVault.releaseScope, SduiEventDispatcher.flushPending, SduiSocketManager.listenForConnect, SduiSocketManager.reRequestScreen, GovernorLogger.log, SduiFlexContext.of, SduiSocketManager.listenForHotReload, _SduiScreenState._onFullReplace, SduiSocketManager.listenForReplace, _SduiScreenState._onPatchDelta, SduiSocketManager.listenForPatches, _SduiScreenState.initState
//  â³ Called by: SduiScreen.createState
```

#### _SduiScreenState._onPatchDelta (Function)
```rust
// Lines 153-153 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onPatchDelta(dynamic rawDelta)
//  â³ Called by: _SduiScreenState
```

#### _SduiScreenState._buildNodeList (Function)
```rust
// Lines 303-307 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildNodeList(
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_heatmap.dart (328 lines)

#### SduiHeatmap._resolveSize (Function)
```rust
// Lines 316-316 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static double? _resolveSize(dynamic raw)
//  â³ Called by: SduiHeatmap
```

#### SduiHeatmap.build (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiHeatmap (Class)
```rust
// Lines 11-334 (324 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiHeatmap extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.maxHeight, SduiHeatmap._resolveSize, SduiStyleResolver.resolveEdgeInsets, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiFlexContext.of, BoundedRouteHistory.isEmpty, GovernorLogger.log, SduiNode.behavior, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiHeatmap._num, SduiHeatmap._int, SduiNode.contentVal
//  â³ Called by: SduiTypeRegistry
```

#### SduiHeatmap._num (Function)
```rust
// Lines 329-329 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double? _num(int key)
//  â³ Called by: SduiHeatmap
```

#### SduiHeatmap._int (Function)
```rust
// Lines 323-323 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int? _int(int key)
//  â³ Called by: SduiHeatmap
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_checkbox.dart (198 lines)

#### SduiCheckbox.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiCheckbox> createState()
//  â³ Calls: SduiCheckbox, _SduiCheckboxState
```

#### SduiCheckbox (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 4 callers
class SduiCheckbox extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiCheckboxState.didUpdateWidget, _SduiCheckboxState, SduiCheckbox.createState, SduiTypeRegistry
```

#### _SduiCheckboxState.build (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiCheckboxState.didUpdateWidget (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiCheckbox oldWidget)
//  â³ Calls: SduiCheckbox
//  â³ Called by: _SduiCheckboxState
```

#### _SduiCheckboxState.dispose (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiCheckboxState
```

#### _SduiCheckboxState (Class)
```rust
// Lines 23-202 (180 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiCheckboxState extends ConsumerState<SduiCheckbox>
//  â³ Calls: SduiCheckbox, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, SduiStateVault.set, ShuaSyncQueue.payload, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, _SduiCheckboxState.dispose, _SduiCheckboxState.didUpdateWidget, SduiNode.contentVal, _SduiCheckboxState.initState
//  â³ Called by: SduiCheckbox.createState
```

#### _SduiCheckboxState.initState (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiCheckboxState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_chip.dart (78 lines)

#### SduiChip.build (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiChip (Class)
```rust
// Lines 8-84 (77 LOC | Complexity 1) | used by 1 callers
class SduiChip extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiEventDispatcher.onStateChange, SduiEventDispatcher.onAction, SduiIconRegistry.resolve, SduiIconRegistry, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior
//  â³ Called by: SduiTypeRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_video.dart (626 lines)

#### _SduiVideoState._onControllerUpdate (Function)
```rust
// Lines 58-58 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onControllerUpdate()
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._formatDuration (Function)
```rust
// Lines 142-142 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatDuration(Duration d)
//  â³ Called by: _SduiVideoState
```

#### SduiVideo (Class)
```rust
// Lines 17-29 (13 LOC | Complexity 1) | used by 3 callers
class SduiVideo extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiVideoState, SduiVideo.createState, SduiTypeRegistry
```

#### _SduiVideoState.build (Function)
```rust
// Lines 239-239 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiVideoState.dispose (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState (Class)
```rust
// Lines 31-633 (603 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiVideoState extends ConsumerState<SduiVideo>
//  â³ Calls: SduiVideo, _SduiVideoState._formatDuration, _SduiVideoState._showPicker, BoundedRouteHistory.isEmpty, _SduiVideoState._initVideoSource, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, ShuaDiaryBlocks.content, SduiEventDispatcher.onStateChange, SduiStateVault.set, MediaUploader.pickAndUploadWithUi, _SduiVideoState._onSelectFile, ShuaDiaryEntries.title, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiNode.behavior, SduiFlexContext.of, GovernorLogger.log, _SduiVideoState._resetHideTimer, _SduiVideoState.dispose, _SduiVideoState._onControllerUpdate, _SduiVideoState.initState
//  â³ Called by: SduiVideo.createState
```

#### _SduiVideoState.initState (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiVideoState
```

#### SduiVideo.createState (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiVideo> createState()
//  â³ Calls: SduiVideo, _SduiVideoState
```

#### _SduiVideoState._showPicker (Function)
```rust
// Lines 148-148 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context)
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._onSelectFile (Function)
```rust
// Lines 208-208 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onSelectFile(BuildContext context, String bindKey, String filePath)
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._resetHideTimer (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _resetHideTimer()
//  â³ Called by: _SduiVideoState
```

#### _SduiVideoState._initVideoSource (Function)
```rust
// Lines 82-82 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _initVideoSource(String path)
//  â³ Called by: _SduiVideoState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_timeline.dart (686 lines)

#### _SduiTimelineState._buildNodeIcon (Function)
```rust
// Lines 528-528 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildNodeIcon(SduiTimelineEvent event, Color accentColor, ColorScheme colorScheme)
//  â³ Calls: SduiTimelineEvent
//  â³ Called by: _SduiTimelineState
```

#### TimelineTrackPainter.paint (Function)
```rust
// Lines 616-616 (1 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Called by: TimelineHorizontalTrackPainter, TimelineHorizontalTrackPainter.paint, TimelineTrackPainter
```

#### TimelineHorizontalTrackPainter.paint (Function)
```rust
// Lines 652-652 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Calls: TimelineTrackPainter.paint
```

#### _SduiTimelineState._getRawDataString (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getRawDataString()
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState._parseData (Function)
```rust
// Lines 107-107 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseData()
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState.didUpdateWidget (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiTimeline oldWidget)
//  â³ Calls: SduiTimeline
//  â³ Called by: _SduiTimelineState
```

#### SduiTimeline (Class)
```rust
// Lines 14-26 (13 LOC | Complexity 1) | used by 4 callers
class SduiTimeline extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTimelineState.didUpdateWidget, _SduiTimelineState, SduiTimeline.createState, SduiTypeRegistry
```

#### _SduiTimelineState.dispose (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState._formatEventsToText (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatEventsToText(List<SduiTimelineEvent> events)
//  â³ Calls: SduiTimelineEvent
//  â³ Called by: _SduiTimelineState
```

#### TimelineTrackPainter.shouldRepaint (Function)
```rust
// Lines 633-633 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
bool shouldRepaint(covariant TimelineTrackPainter oldDelegate)
//  â³ Calls: TimelineTrackPainter
//  â³ Called by: TimelineHorizontalTrackPainter.shouldRepaint
```

#### TimelineTrackPainter (Class)
```rust
// Lines 604-638 (35 LOC | Complexity 1) | used by 2 callers
class TimelineTrackPainter extends CustomPainter
//  â³ Calls: TimelineTrackPainter.paint
//  â³ Called by: TimelineTrackPainter.shouldRepaint, _SduiTimelineState
```

#### TimelineHorizontalTrackPainter.shouldRepaint (Function)
```rust
// Lines 669-669 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool shouldRepaint(covariant TimelineHorizontalTrackPainter oldDelegate)
//  â³ Calls: TimelineHorizontalTrackPainter, TimelineTrackPainter.shouldRepaint
```

#### SduiTimelineEvent (Class)
```rust
// Lines 581-602 (22 LOC | Complexity 1) | used by 4 callers
class SduiTimelineEvent
//  â³ Calls: ShuaDiaryEntries.title
//  â³ Called by: _SduiTimelineState._buildNodeIcon, _SduiTimelineState._formatEventsToText, SduiTimelineEvent.SduiTimelineEvent, _SduiTimelineState
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

#### _SduiTimelineState (Class)
```rust
// Lines 28-579 (552 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiTimelineState extends ConsumerState<SduiTimeline>
//  â³ Calls: SduiTimeline, SduiIconRegistry.resolve, SduiIconRegistry, TimelineHorizontalTrackPainter, _SduiTimelineState._buildNodeIcon, TimelineTrackPainter, SduiEventDispatcher.onStateChange, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiTimelineState._buildVerticalTimeline, _SduiTimelineState._buildHorizontalTimeline, _SduiTimelineState._buildEmptyState, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, BoundedRouteHistory.isEmpty, _SduiTimelineState._parseFromTextLines, _SduiTimelineState._formatEventsToText, ShuaDiaryEntries.title, SduiTimelineEvent.fromMap, SduiTimelineEvent, SduiNode.contentVal, SduiNode.behavior, _SduiTimelineState.dispose, _SduiTimelineState.didUpdateWidget, _SduiTimelineState._getRawDataString, _SduiTimelineState._parseData, _SduiTimelineState.initState
//  â³ Called by: SduiTimeline.createState
```

#### SduiTimelineEvent.SduiTimelineEvent (Function)
```rust
// Lines 594-594 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiTimelineEvent.fromMap(Map<dynamic, dynamic> map)
//  â³ Calls: SduiTimelineEvent.fromMap, SduiTimelineEvent
```

#### _SduiTimelineState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState.build (Function)
```rust
// Lines 197-197 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### TimelineHorizontalTrackPainter (Class)
```rust
// Lines 640-674 (35 LOC | Complexity 1) | used by 2 callers
class TimelineHorizontalTrackPainter extends CustomPainter
//  â³ Calls: TimelineTrackPainter.paint
//  â³ Called by: TimelineHorizontalTrackPainter.shouldRepaint, _SduiTimelineState
```

#### _SduiTimelineState._parseFromTextLines (Function)
```rust
// Lines 152-152 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseFromTextLines(String text)
//  â³ Called by: _SduiTimelineState
```

#### SduiTimelineEvent.fromMap (Function)
```rust
// Lines 594-594 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiTimelineEvent.fromMap(Map<dynamic, dynamic> map)
//  â³ Called by: SduiTimelineEvent.SduiTimelineEvent, _SduiTimelineState
```

#### _SduiTimelineState._buildHorizontalTimeline (Function)
```rust
// Lines 437-442 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHorizontalTimeline(
//  â³ Called by: _SduiTimelineState
```

#### _SduiTimelineState._buildEmptyState (Function)
```rust
// Lines 558-558 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiTimelineState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_module_card.dart (362 lines)

#### _TelemetryChip.build (Function)
```rust
// Lines 323-323 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: SduiModuleCard.build
```

#### _ActionChip (Class)
```rust
// Lines 353-385 (33 LOC | Complexity 1) | used by 1 callers
class _ActionChip extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius
//  â³ Called by: SduiModuleCard
```

#### SduiModuleCard.build (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 2 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Called by: _ActionChip.build, _TelemetryChip.build
```

#### _ActionChip.build (Function)
```rust
// Lines 367-367 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: SduiModuleCard.build
```

#### SduiModuleCard (Class)
```rust
// Lines 22-312 (291 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiModuleCard extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, _ActionChip, _TelemetryChip, SduiShimmerLoader, _SduiShimmerLoaderState.borderRadius, ShuaDiaryBlocks.content, SduiNode, SduiIconRegistry.resolve, SduiIconRegistry, SduiFlexContext.of, GovernorLogger.log, _SduiShimmerLoaderState.padding, BoundedRouteHistory.isEmpty, SduiNode.contentVal
//  â³ Called by: SduiTypeRegistry
```

#### _TelemetryChip (Class)
```rust
// Lines 315-349 (35 LOC | Complexity 1) | used by 1 callers
class _TelemetryChip extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding
//  â³ Called by: SduiModuleCard
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_progress_bar.dart (100 lines)

#### SduiProgressBar.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiProgressBar (Class)
```rust
// Lines 7-105 (99 LOC | Complexity 1) | used by 1 callers
class SduiProgressBar extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiNode.contentVal
//  â³ Called by: SduiTypeRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_divider.dart (214 lines)

#### _SduiDividerState.build (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiDivider (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 3 callers
class SduiDivider extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDividerState, SduiDivider.createState, SduiTypeRegistry
```

#### SduiDivider.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDivider> createState()
//  â³ Calls: SduiDivider, _SduiDividerState
```

#### _SduiDividerState (Class)
```rust
// Lines 23-221 (199 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDividerState extends ConsumerState<SduiDivider>
//  â³ Calls: SduiDivider, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onStateChange, SduiStateVault.set, ShuaSyncQueue.payload, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiDivider.createState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_markdown_editor.dart (322 lines)

#### _SduiMarkdownEditorState.dispose (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState.build (Function)
```rust
// Lines 212-212 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiMarkdownEditor.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiMarkdownEditor> createState()
//  â³ Calls: SduiMarkdownEditor, _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState._onTextChanged (Function)
```rust
// Lines 79-79 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState (Class)
```rust
// Lines 23-312 (290 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiMarkdownEditorState extends ConsumerState<SduiMarkdownEditor>
//  â³ Calls: SduiMarkdownEditor, _SduiMarkdownEditorState._buildReadonlyView, _SduiMarkdownEditorState._onTextChanged, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveTextStyle, SduiStyleResolver, _SduiMarkdownEditorState._resolveTextAlign, SduiNode.behavior, SduiFlexContext.of, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, _SduiMarkdownEditorState._resolveHeadingStyle, ShuaDiaryBlocks.content, BoundedRouteHistory.isEmpty, SduiEventDispatcher.onStateChange, _SduiMarkdownEditorState.dispose, _SduiMarkdownEditorState.didUpdateWidget, _SduiMarkdownEditorState._onFocusChange, SduiNode.contentVal, _SduiMarkdownEditorState.initState
//  â³ Called by: SduiMarkdownEditor.createState
```

#### _SduiMarkdownEditorState._buildReadonlyView (Function)
```rust
// Lines 118-127 (10 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildReadonlyView(
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: _SduiMarkdownEditorState
```

#### SduiMarkdownEditor (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 4 callers
class SduiMarkdownEditor extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiMarkdownEditorState.didUpdateWidget, _SduiMarkdownEditorState, SduiMarkdownEditor.createState, SduiTypeRegistry
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
// Lines 30-30 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState.didUpdateWidget (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiMarkdownEditor oldWidget)
//  â³ Calls: SduiMarkdownEditor
//  â³ Called by: _SduiMarkdownEditorState
```

#### _SduiMarkdownEditorState._resolveHeadingStyle (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextStyle? _resolveHeadingStyle(ThemeData theme, int level, Color? textColor)
//  â³ Called by: _SduiMarkdownEditorState
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

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_image.dart (451 lines)

#### SduiImage._buildZoomImage (Function)
```rust
// Lines 380-384 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildZoomImage(
//  â³ Called by: SduiImage
```

#### SduiImage._buildErrorImage (Function)
```rust
// Lines 299-305 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildErrorImage(
//  â³ Called by: SduiImage
```

#### SduiImage.build (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiImage._pickAndUpload (Function)
```rust
// Lines 423-427 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _pickAndUpload(
//  â³ Called by: SduiImage
```

#### SduiImage._showZoomModal (Function)
```rust
// Lines 331-337 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showZoomModal(
//  â³ Called by: SduiImage
```

#### SduiImage (Class)
```rust
// Lines 12-437 (426 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiImage extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, MediaUploader.pickAndUploadWithUi, SduiImage._buildZoomImage, _SduiShimmerLoaderState.padding, SduiImage._showZoomModal, SduiImage._buildErrorImage, SduiImage._pickAndUpload, _SduiShimmerLoaderState.borderRadius, BoundedRouteHistory.isEmpty, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\diagnostic_result.dart (141 lines)

#### DiagnosticResult.success (Function)
```rust
// Lines 53-56 (4 LOC | Complexity 1) | used by 5 callers | [Pure, Tested]
factory DiagnosticResult.success(T data,
//  â³ Called by: TelemetryProfile, ThemeNotifier, BoundedRouteHistory, AuthNotifier, DiagnosticResult.DiagnosticResult
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
//  â³ Calls: SystemDiagnostic, DiagnosticResult.success, DiagnosticResult
```

#### DiagnosticResult.failure (Function)
```rust
// Lines 70-73 (4 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
factory DiagnosticResult.failure(SystemDiagnostic diagnostic,
//  â³ Called by: TelemetryProfile, AuthNotifier, DiagnosticResult.DiagnosticResult
```

#### DiagnosticResult.isFailure (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get isFailure
//  â³ Called by: DiagnosticsHistoryNotifier
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
//  â³ Called by: DiagnosticResult.copyWith, DiagnosticsHistoryNotifier, DiagnosticResult
```

#### DiagnosticResult.isCritical (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get isCritical
//  â³ Calls: DiagnosticSeverity
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticResult (Class)
```rust
// Lines 16-122 (107 LOC | Complexity 1) | used by 21 callers | [CorePrimitive]
class DiagnosticResult<T>
//  â³ Calls: SystemDiagnostic, OccurrenceEntry
//  â³ Called by: DiagnosticsHistoryNotifier, DiagnosticsHistoryNotifier.logResult, DiagnosticsHistoryNotifier._truncate, DiagnosticsState.copyWith, DiagnosticsState, _TerminalLine, _SduiTerminalState._buildLogList, _SduiTerminalState._buildHeader, _SduiTerminalState, _SduiTerminalState._copyLogs, _SduiTerminalState._severityColor, _SduiTerminalState._getFilteredLogs, AuthState.copyWith, AuthState, DiagnosticResult.copyWith, TelemetryProfile, ThemeNotifier, BoundedRouteHistory, AuthNotifier, DiagnosticResult.DiagnosticResult, DiagnosticResult.DiagnosticResult
```

#### DiagnosticResult.copyWith (Function)
```rust
// Lines 96-100 (5 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DiagnosticResult<T> copyWith(
//  â³ Calls: OccurrenceEntry, DiagnosticResult
```

#### DiagnosticResult.latencyMs (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get latencyMs
//  â³ Called by: DiagnosticsHistoryNotifier
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\system_diagnostics.dart (40 lines)

#### DiagnosticSeverity (Enum)
```rust
// Lines 1-10 (10 LOC | Complexity 1) | used by 6 callers
enum DiagnosticSeverity
//  â³ Called by: _SduiTerminalState, SystemDiagnostic, TelemetryProfile, DiagnosticsHistoryNotifier, SystemEvents, DiagnosticResult.isCritical
```

#### SystemEvents (Class)
```rust
// Lines 23-45 (23 LOC | Complexity 1) | used by 3 callers
class SystemEvents
//  â³ Calls: DiagnosticSeverity, SystemDiagnostic
//  â³ Called by: ThemeNotifier, BoundedRouteHistory, AuthNotifier
```

#### SystemDiagnostic (Class)
```rust
// Lines 13-19 (7 LOC | Complexity 1) | used by 5 callers
class SystemDiagnostic
//  â³ Calls: DiagnosticSeverity
//  â³ Called by: DiagnosticResult.DiagnosticResult, DiagnosticResult.DiagnosticResult, DiagnosticResult, TelemetryProfile, SystemEvents
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_spacer.dart (333 lines)

#### DashedBorderPainter.shouldRepaint (Function)
```rust
// Lines 337-337 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool shouldRepaint(CustomPainter oldDelegate)
```

#### DashedBorderPainter (Class)
```rust
// Lines 293-338 (46 LOC | Complexity 1) | used by 1 callers
class DashedBorderPainter extends CustomPainter
//  â³ Calls: DashedBorderPainter.paint
//  â³ Called by: _SduiSpacerState
```

#### SduiSpacer (Class)
```rust
// Lines 8-20 (13 LOC | Complexity 1) | used by 3 callers
class SduiSpacer extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiSpacerState, SduiSpacer.createState, SduiTypeRegistry
```

#### _SduiSpacerState.build (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiSpacerState (Class)
```rust
// Lines 22-291 (270 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiSpacerState extends ConsumerState<SduiSpacer>
//  â³ Calls: SduiSpacer, DashedBorderPainter, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiEventDispatcher.onStateChange, SduiStateVault.set, ShuaSyncQueue.payload, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiSpacer.createState
```

#### SduiSpacer.createState (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSpacer> createState()
//  â³ Calls: SduiSpacer, _SduiSpacerState
```

#### DashedBorderPainter.paint (Function)
```rust
// Lines 305-305 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void paint(Canvas canvas, Size size)
//  â³ Called by: DashedBorderPainter
```

### C:\horAIzon_2.0\client_flutter\lib\core\interfaces\illm_provider.dart (3 lines)

#### IllmProvider (Class)
```rust
// Lines 0-2 (3 LOC | Complexity 1) | used by 0 callers
abstract class IllmProvider
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_map.dart (266 lines)

#### _SduiMapState (Class)
```rust
// Lines 24-270 (247 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiMapState extends ConsumerState<SduiMap>
//  â³ Calls: SduiMap, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onStateChange, SduiStateVault.set, _SduiShimmerLoaderState.borderRadius, _SduiMapState._buildMarkers, _SduiMapState._parseCoordinates, SduiNode.contentVal, SduiNode.behavior, ShuaDiaryBlocks.content, SduiFlexContext.of, SduiEventDispatcher.onAction, SduiIconRegistry.resolve, SduiIconRegistry, _SduiMapState.dispose, _SduiMapState.initState
//  â³ Called by: SduiMap.createState
```

#### _SduiMapState.dispose (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiMapState
```

#### SduiMap (Class)
```rust
// Lines 10-22 (13 LOC | Complexity 1) | used by 3 callers
class SduiMap extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiMapState, SduiMap.createState, SduiTypeRegistry
```

#### _SduiMapState.build (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiMapState._buildMarkers (Function)
```rust
// Lines 75-75 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<Marker> _buildMarkers(BuildContext context, dynamic rawData, ThemeData theme, ColorScheme colorScheme)
//  â³ Called by: _SduiMapState
```

#### SduiMap.createState (Function)
```rust
// Lines 21-21 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiMap> createState()
//  â³ Calls: SduiMap, _SduiMapState
```

#### _SduiMapState.initState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiMapState
```

#### _SduiMapState._parseCoordinates (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
LatLng? _parseCoordinates(dynamic value)
//  â³ Called by: _SduiMapState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_list_editor.dart (650 lines)

#### _SduiListEditorState._accentIcon (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IconData? get _accentIcon
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._isReadOnly (Function)
```rust
// Lines 73-73 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get _isReadOnly
//  â³ Calls: _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._persistChange (Function)
```rust
// Lines 165-165 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _persistChange()
//  â³ Called by: _SduiListEditorState
```

#### _ListItem (Class)
```rust
// Lines 40-57 (18 LOC | Complexity 1) | used by 1 callers
class _ListItem
//  â³ Calls: _ListItem.dispose
//  â³ Called by: _SduiListEditorState
```

#### SduiListEditor.createState (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiListEditor> createState()
//  â³ Calls: SduiListEditor, _SduiListEditorState
```

#### _SduiListEditorState._loadFromContent (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _loadFromContent(String content)
//  â³ Calls: ShuaDiaryBlocks.content
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._listStyle (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _listStyle
//  â³ Calls: ListStyle, _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState (Class)
```rust
// Lines 59-630 (572 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiListEditorState extends State<SduiListEditor>
//  â³ Calls: BulletStyle, SduiListEditor, _SduiListEditorState._onEnterPressed, _SduiListEditorState._itemHintText, _SduiListEditorState._onBackspaceOnEmpty, _SduiListEditorState._bulletStyle, _SduiListEditorState._selectRadio, _SduiListEditorState._toggleChecked, _SduiListEditorState._resolveContainerColor, _SduiListEditorState._buildTagChip, _SduiListEditorState._accentIcon, SduiIconRegistry.contains, _SduiListEditorState._buildFooterActions, _SduiListEditorState._buildItemRow, _SduiListEditorState._buildProgressHeader, _SduiListEditorState._buildHeaderRow, _SduiListEditorState._headerLabel, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, _SduiListEditorState._buildTagReadMode, _SduiListEditorState._resolveAccentColor, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiListEditorState._persistChange, _SduiListEditorState._minItems, SduiEventDispatcher.onStateChange, _SduiListEditorState._bindKey, _SduiListEditorState._maxItems, ListStyle, _ListItem, _SduiListEditorState._listStyle, ShuaDiaryBlocks.content, _ListItem.dispose, _SduiListEditorState._serialize, SduiNode.contentVal, _SduiListEditorState.didUpdateWidget, _SduiListEditorState._appendNewItem, _SduiListEditorState._isReadOnly, _SduiListEditorState._initialContent, _SduiListEditorState._loadFromContent, _SduiListEditorState.initState, SduiIconRegistry.resolve, SduiIconRegistry, BoundedRouteHistory.isEmpty, SduiNode.behavior
//  â³ Called by: SduiListEditor.createState
```

#### _SduiListEditorState.build (Function)
```rust
// Lines 245-245 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiListEditorState._buildItemRow (Function)
```rust
// Lines 438-438 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildItemRow(ThemeData theme, Color accentColor, int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._toggleChecked (Function)
```rust
// Lines 184-184 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _toggleChecked(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.didUpdateWidget (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiListEditor oldWidget)
//  â³ Calls: SduiListEditor
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._selectRadio (Function)
```rust
// Lines 218-218 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _selectRadio(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildProgressHeader (Function)
```rust
// Lines 309-309 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildProgressHeader(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildTagReadMode (Function)
```rust
// Lines 365-365 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTagReadMode(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._resolveAccentColor (Function)
```rust
// Lines 231-231 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveAccentColor(ThemeData theme)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._minItems (Function)
```rust
// Lines 72-72 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _minItems
//  â³ Calls: _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.initState (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._onBackspaceOnEmpty (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onBackspaceOnEmpty(int index)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._int (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 5 callers | [Pure]
int? _int(int key)
//  â³ Called by: _SduiListEditorState._isReadOnly, _SduiListEditorState._minItems, _SduiListEditorState._maxItems, _SduiListEditorState._bulletStyle, _SduiListEditorState._listStyle
```

#### _SduiListEditorState._maxItems (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _maxItems
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

#### _SduiListEditorState._appendNewItem (Function)
```rust
// Lines 157-157 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _appendNewItem({int? afterIndex})
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._bindKey (Function)
```rust
// Lines 74-74 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _bindKey
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiListEditorState
```

#### ListStyle (Class)
```rust
// Lines 9-16 (8 LOC | Complexity 1) | used by 2 callers
abstract final class ListStyle
//  â³ Called by: _SduiListEditorState, _SduiListEditorState._listStyle
```

#### _SduiListEditorState._resolveContainerColor (Function)
```rust
// Lines 236-236 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveContainerColor(ThemeData theme)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState.dispose (Function)
```rust
// Lines 108-108 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Calls: _ListItem.dispose
```

#### _SduiListEditorState._buildTagChip (Function)
```rust
// Lines 420-420 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTagChip(ThemeData theme, Color accentColor, String tag)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._bulletStyle (Function)
```rust
// Lines 65-65 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _bulletStyle
//  â³ Calls: BulletStyle, _SduiListEditorState._int
//  â³ Called by: _SduiListEditorState
```

#### BulletStyle (Class)
```rust
// Lines 19-24 (6 LOC | Complexity 1) | used by 2 callers
abstract final class BulletStyle
//  â³ Called by: _SduiListEditorState, _SduiListEditorState._bulletStyle
```

#### _SduiListEditorState._onEnterPressed (Function)
```rust
// Lines 194-194 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onEnterPressed(int index)
//  â³ Called by: _SduiListEditorState
```

#### SduiListEditor (Class)
```rust
// Lines 26-38 (13 LOC | Complexity 1) | used by 4 callers
class SduiListEditor extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiListEditorState.didUpdateWidget, _SduiListEditorState, SduiListEditor.createState, SduiTypeRegistry
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

#### _ListItem.dispose (Function)
```rust
// Lines 52-52 (1 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiListEditorState.dispose, _SduiListEditorState, _ListItem
```

#### _SduiListEditorState._buildFooterActions (Function)
```rust
// Lines 575-575 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildFooterActions(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._initialContent (Function)
```rust
// Lines 76-76 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _initialContent
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiListEditorState
```

#### _SduiListEditorState._buildHeaderRow (Function)
```rust
// Lines 279-279 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHeaderRow(ThemeData theme, Color accentColor)
//  â³ Called by: _SduiListEditorState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_gauge.dart (245 lines)

#### SduiGauge._buildLinearGauge (Function)
```rust
// Lines 180-187 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildLinearGauge(
//  â³ Called by: SduiGauge
```

#### SduiGauge.build (Function)
```rust
// Lines 22-22 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiGauge (Class)
```rust
// Lines 11-238 (228 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiGauge extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiGauge._buildRadialGauge, SduiGauge._buildLinearGauge, ShuaDiaryEntries.title, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiGauge._buildRadialGauge (Function)
```rust
// Lines 91-98 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildRadialGauge(
//  â³ Called by: SduiGauge
```

### C:\horAIzon_2.0\client_flutter\lib\main.dart (28 lines)

#### HorAIzonClientShell (Class)
```rust
// Lines 30-56 (27 LOC | Complexity 1) | used by 0 callers
class HorAIzonClientShell extends ConsumerWidget
//  â³ Calls: SduiFlexContext.of, ThemeState.compiledData, ShuaDiaryEntries.title
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
//  â³ Calls: PinEntryScreen, _PinEntryScreenState
```

#### _PinEntryScreenState.initState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _PinEntryScreenState
```

#### PinEntryScreen (Class)
```rust
// Lines 7-12 (6 LOC | Complexity 1) | used by 2 callers
class PinEntryScreen extends ConsumerStatefulWidget
//  â³ Called by: _PinEntryScreenState, PinEntryScreen.createState
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
//  â³ Calls: AuthState
//  â³ Called by: _PinEntryScreenState
```

#### _PinEntryScreenState (Class)
```rust
// Lines 14-296 (283 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
//  â³ Calls: AuthState, PinEntryScreen, AuthNotifier.deleteDigit, _PinEntryScreenState._buildKey, _SduiShimmerLoaderState.padding, filter, _SduiShimmerLoaderState.borderRadius, AuthStatus, SduiFlexContext.of, AuthNotifier.enterDigit, _PinEntryScreenState.dispose, _PinEntryScreenState.initState
//  â³ Called by: PinEntryScreen.createState
```

#### _PinEntryScreenState.dispose (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _PinEntryScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_node.dart (220 lines)

#### SduiNode (Class)
```rust
// Lines 6-220 (215 LOC | Complexity 1) | used by 72 callers | [CorePrimitive, HighComplexity]
@immutable
//  â³ Calls: SduiNode.fromJson, SduiNode.interpolate, GovernorLogger.log, ShuaDiaryBlocks.content
//  â³ Called by: SduiWrap, SduiRadio, SduiHtmlViewer, _SduiContainerState._findDragHandleIndex, _SduiContainerState._buildReorderableItem, _SduiContainerState, SduiContainer, SduiAudio, _DashboardScreenState, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, _SduiScreenState._findNodeByIdSuffix, _SduiScreenState._onFullReplace, SduiGridView, SduiCheckbox, SduiTimePicker, SduiTextInput, SduiImage, SduiMarkdownEditor, SduiCodeEditor, SduiToggle, SduiShimmerLoader, _SduiJbcPanelState, SduiJbcPanel, SduiDivider, SduiDatePicker, SduiProgressBar, SduiTerminal, SduiOrdinalSlider, SduiTimeline, SduiChip, _SduiSandboxScreenState._parseLegacyV4Format, _SduiSandboxScreenState._loadBlueprints, SduiHeatmap, SduiListEditor, SduiListView, SduiSocketManager.listenForReplace, SduiSocketManager.getScreen, SduiSocketManager.requestScreen, SduiSocketManager, SduiButton, SduiRenderer, SduiMap, SduiTransport._nodeFromMap, SduiTransport._parseList, SduiTransport._patchNodeInTree, SduiTransport._insertAfterRecursive, SduiTransport._insertAfterInTree, SduiTransport._removeNodeFromTree, SduiTransport.applyDelta, SduiTransport.patch, SduiTransport.decodeJson, SduiTransport.decode, SduiSlider, SduiNode.interpolate, SduiDocumentViewer, SduiTypeRegistry.buildNode, SduiDrawingPad, SduiStlViewer, SduiTable, SduiSpacer, SduiVideo, SduiCarousel, SduiGauge, SduiChart, SduiDropdown, SduiExpansionTile, _SduiScreenState, _SduiSandboxScreenState, SduiTransport, SduiModuleCard, SduiNode.SduiNode
```

#### SduiNode.interpolate (Function)
```rust
// Lines 134-134 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
SduiNode interpolate(Map<String, dynamic> context)
//  â³ Calls: SduiNode
//  â³ Called by: SduiGridView, SduiListView, SduiNode
```

#### SduiNode.behavior (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 47 callers | [Pure, CorePrimitive]
T? behavior<T>(int key)
//  â³ Called by: _SduiWrapState, _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, SduiGridView, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, _SduiTextInputState._bindKey, SduiImage, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.shimmerAnimStyle, _SduiShimmerLoaderState.shimmerType, _SduiJbcPanelState, _SduiDividerState, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState._bindKey, _SduiListEditorState, SduiListView, SduiButton, _SduiMapState, _SduiSliderState, _SduiDocumentViewerState, _SduiDrawingPadState, SduiStlViewer, _SduiTableState._bindKey, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiNode.fromJson (Function)
```rust
// Lines 179-179 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiNode.fromJson(Map<String, dynamic> json)
//  â³ Called by: SduiNode, SduiNode.SduiNode
```

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
//  â³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, _SduiScreenState, SduiGridView, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, SduiImage, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, _SduiListEditorState._itemHintText, _SduiListEditorState._headerLabel, _SduiListEditorState._initialContent, SduiListView, SduiButton, _SduiMapState, _SduiSliderState, SduiModuleCard, _SduiDocumentViewerState, _SduiDrawingPadState, SduiStlViewer, _SduiTableState, _SduiTableState._headerLabel, _SduiTableState._initialContent, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_renderer.dart (71 lines)

#### SduiFlexContext.updateShouldNotify (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
bool updateShouldNotify(SduiFlexContext oldWidget)
//  â³ Calls: SduiFlexContext
```

#### SduiFlexContext (Class)
```rust
// Lines 14-32 (19 LOC | Complexity 1) | used by 4 callers
class SduiFlexContext extends InheritedWidget
//  â³ Called by: SduiFlexContext.updateShouldNotify, SduiFlexContext.of, _SduiContainerState, SduiRenderer
```

#### SduiFlexContext.of (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 53 callers | [Pure, CorePrimitive]
static SduiFlexContext? of(BuildContext context)
//  â³ Calls: SduiFlexContext
//  â³ Called by: _SduiWrapState, _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, _SduiScreenState, _SduiCheckboxState, HorAIzonClientShell, _NetworkConfigCardState, SettingsPage, SduiTimePicker, _SduiTextInputState, MediaUploader, SduiImage, _PinEntryScreenState, _SduiMarkdownEditorState, _SduiCodeEditorState, SyntaxHighlightingController, SduiToggle, _SduiShimmerLoaderState, SduiStyleResolver, _SduiJbcPanelState, _SduiDividerState, SduiDatePicker, SduiProgressBar, _FilterChip, _TerminalLineState, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, _SduiSandboxScreenState, AdaptiveShell, SduiHeatmap, _SduiListEditorState, SduiSocketManager, SduiButton, SduiRenderer, _SduiMapState, _SduiSliderState, SduiModuleCard, _SduiDocumentViewerState, SduiEventDispatcher, _SduiDrawingPadState, SduiStlViewer, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiRenderer (Class)
```rust
// Lines 38-86 (49 LOC | Complexity 1) | used by 8 callers
class SduiRenderer extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiFlexContext.of, SduiFlexContext, _SduiShimmerLoaderState.padding, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiTypeRegistry.buildNode, SduiTypeRegistry
//  â³ Called by: _SduiWrapState, _SduiContainerState, _DashboardScreenState, _SduiScreenState, SduiGridView, SduiListView, _SduiCarouselState, _SduiExpansionTileState
```

#### SduiRenderer.build (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_jbc_panel.dart (577 lines)

#### JbcMessage.copyWith (Function)
```rust
// Lines 27-32 (6 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
JbcMessage copyWith(
//  â³ Calls: JbcMessage
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._sendMessage (Function)
```rust
// Lines 159-159 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _sendMessage()
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._cleanupActiveStream (Function)
```rust
// Lines 84-84 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _cleanupActiveStream()
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._acceptMutations (Function)
```rust
// Lines 263-263 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _acceptMutations(List<dynamic> mutations)
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._extractCurrentBlocks (Function)
```rust
// Lines 92-92 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<Map<String, dynamic>> _extractCurrentBlocks()
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState.initState (Function)
```rust
// Lines 67-67 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiJbcPanelState
```

#### SduiJbcPanel.createState (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiJbcPanel> createState()
//  â³ Calls: SduiJbcPanel, _SduiJbcPanelState
```

#### _SduiJbcPanelState.dispose (Function)
```rust
// Lines 77-77 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiJbcPanelState
```

#### JbcMessage (Class)
```rust
// Lines 12-41 (30 LOC | Complexity 1) | used by 2 callers
class JbcMessage
//  â³ Called by: JbcMessage.copyWith, _SduiJbcPanelState
```

#### _SduiJbcPanelState.build (Function)
```rust
// Lines 403-403 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiJbcPanelState (Class)
```rust
// Lines 59-574 (516 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiJbcPanelState extends ConsumerState<SduiJbcPanel>
//  â³ Calls: SduiNode, SduiJbcPanel, _SduiJbcPanelState._sendMessage, _SduiJbcPanelState._acceptMutations, _SduiJbcPanelState._buildVisualDiff, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, ShuaDiaryBlocks.entryId, SduiSocketManager.sendRpcWithResponse, _SduiJbcPanelState._extractCurrentBlocks, GovernorLogger.log, JbcMessage.copyWith, _SduiJbcPanelState._scrollToBottom, BoundedRouteHistory.isEmpty, ShuaDiaryBlocks.content, SduiNode.behavior, ShuaDiaryBlocks.blockType, SduiSocketManager.socketForScreen, _SduiJbcPanelState.dispose, _SduiJbcPanelState._cleanupActiveStream, JbcMessage, _SduiJbcPanelState.initState
//  â³ Called by: SduiJbcPanel.createState
```

#### _SduiJbcPanelState._buildVisualDiff (Function)
```rust
// Lines 303-303 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildVisualDiff(List<dynamic> mutations)
//  â³ Called by: _SduiJbcPanelState
```

#### _SduiJbcPanelState._scrollToBottom (Function)
```rust
// Lines 147-147 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _scrollToBottom()
//  â³ Called by: _SduiJbcPanelState
```

#### SduiJbcPanel (Class)
```rust
// Lines 43-57 (15 LOC | Complexity 1) | used by 3 callers
class SduiJbcPanel extends ConsumerStatefulWidget
//  â³ Calls: SduiNode, ShuaDiaryBlocks.entryId
//  â³ Called by: _SduiJbcPanelState, SduiJbcPanel.createState, _SduiScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\config_provider.dart (132 lines)

#### ConfigNotifier.updateWorkspaceRoot (Function)
```rust
// Lines 121-121 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateWorkspaceRoot(String root)
//  â³ Called by: _NetworkConfigCardState
```

#### ConfigState (Class)
```rust
// Lines 8-38 (31 LOC | Complexity 1) | used by 3 callers
class ConfigState
//  â³ Calls: ConfigNotifier
//  â³ Called by: ConfigNotifier.build, ConfigState.copyWith, ConfigNotifier
```

#### ConfigNotifier._saveConfig (Function)
```rust
// Lines 79-79 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _saveConfig()
//  â³ Called by: ConfigNotifier
```

#### ConfigNotifier (Class)
```rust
// Lines 40-125 (86 LOC | Complexity 1) | used by 1 callers
class ConfigNotifier extends Notifier<ConfigState>
//  â³ Calls: ConfigNotifier._saveConfig, ConfigState.copyWith, GovernorLogger.log, ConfigState, ConfigNotifier._loadConfig
//  â³ Called by: ConfigState
```

#### ConfigNotifier.updateOllamaModel (Function)
```rust
// Lines 111-111 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateOllamaModel(String model)
//  â³ Called by: _NetworkConfigCardState
```

#### ConfigNotifier._loadConfig (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadConfig()
//  â³ Called by: ConfigNotifier
```

#### ConfigState.copyWith (Function)
```rust
// Lines 23-29 (7 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ConfigState copyWith(
//  â³ Calls: ConfigState
//  â³ Called by: ConfigNotifier
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

#### ConfigNotifier.build (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConfigState build()
//  â³ Calls: ConfigState
```

#### ConfigNotifier.updateGeminiApiKey (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateGeminiApiKey(String key)
//  â³ Called by: _NetworkConfigCardState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_dropdown.dart (298 lines)

#### SduiDropdown (Class)
```rust
// Lines 9-17 (9 LOC | Complexity 1) | used by 4 callers
class SduiDropdown extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDropdownState.didUpdateWidget, _SduiDropdownState, SduiDropdown.createState, SduiTypeRegistry
```

#### _SduiDropdownState (Class)
```rust
// Lines 19-300 (282 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDropdownState extends ConsumerState<SduiDropdown>
//  â³ Calls: SduiDropdown, filter, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiEventDispatcher.onStateChange, SduiStateVault.set, ShuaSyncQueue.payload, BoundedRouteHistory.isEmpty, SduiIconRegistry.contains, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiFlexContext.of, _SduiDropdownState.dispose, _SduiDropdownState.didUpdateWidget, _SduiDropdownState._parseNodeOptions, SduiNode.contentVal, _SduiDropdownState.initState
//  â³ Called by: SduiDropdown.createState
```

#### _SduiDropdownState.initState (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiDropdownState
```

#### _SduiDropdownState.didUpdateWidget (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiDropdown oldWidget)
//  â³ Calls: SduiDropdown
//  â³ Called by: _SduiDropdownState
```

#### _SduiDropdownState.dispose (Function)
```rust
// Lines 89-89 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiDropdownState
```

#### filter (Function)
```rust
// Lines 304-304 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Iterable<T> filter(bool Function(T) test)
//  â³ Called by: _PinEntryScreenState, _SduiDropdownState
```

#### SduiDropdown.createState (Function)
```rust
// Lines 16-16 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDropdown> createState()
//  â³ Calls: SduiDropdown, _SduiDropdownState
```

#### _SduiDropdownState._parseNodeOptions (Function)
```rust
// Lines 74-74 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<String> _parseNodeOptions()
//  â³ Called by: _SduiDropdownState
```

#### _SduiDropdownState.build (Function)
```rust
// Lines 96-96 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_slider.dart (207 lines)

#### _SduiSliderState.build (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiSliderState (Class)
```rust
// Lines 21-210 (190 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiSliderState extends ConsumerState<SduiSlider>
//  â³ Calls: SduiSlider, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, _SduiSliderState._normalize, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiNode.contentVal, _SduiSliderState.didUpdateWidget
//  â³ Called by: SduiSlider.createState
```

#### SduiSlider.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSlider> createState()
//  â³ Calls: SduiSlider, _SduiSliderState
```

#### SduiSlider (Class)
```rust
// Lines 7-19 (13 LOC | Complexity 1) | used by 4 callers
class SduiSlider extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiSliderState.didUpdateWidget, _SduiSliderState, SduiSlider.createState, SduiTypeRegistry
```

#### _SduiSliderState._normalize (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double _normalize(double raw, double min, double max, bool normalize)
//  â³ Called by: _SduiSliderState
```

#### _SduiSliderState.didUpdateWidget (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiSlider oldWidget)
//  â³ Calls: SduiSlider
//  â³ Called by: _SduiSliderState
```

### C:\horAIzon_2.0\client_flutter\lib\app\auth\auth_provider.dart (77 lines)

#### AuthStatus (Enum)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 4 callers
enum AuthStatus { unauthenticated, authenticating, authenticated, error }
//  â³ Calls: AuthNotifier
//  â³ Called by: AuthState.copyWith, AuthState, _PinEntryScreenState, AuthNotifier
```

#### AuthState (Class)
```rust
// Lines 7-29 (23 LOC | Complexity 1) | used by 5 callers
class AuthState
//  â³ Calls: DiagnosticResult, AuthStatus
//  â³ Called by: _PinEntryScreenState, _PinEntryScreenState._buildKey, AuthNotifier.build, AuthState.copyWith, AuthNotifier
```

#### AuthNotifier.verifyPIN (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void verifyPIN(String pin)
//  â³ Called by: AuthNotifier
```

#### AuthState.copyWith (Function)
```rust
// Lines 18-22 (5 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
AuthState copyWith(
//  â³ Calls: DiagnosticResult, AuthStatus, AuthState
//  â³ Called by: AuthNotifier
```

#### AuthNotifier (Class)
```rust
// Lines 31-74 (44 LOC | Complexity 1) | used by 1 callers
class AuthNotifier extends Notifier<AuthState>
//  â³ Calls: DiagnosticsHistoryNotifier.logResult, DiagnosticResult.failure, SystemEvents, DiagnosticResult.success, DiagnosticResult, BoundedRouteHistory.isEmpty, AuthNotifier.verifyPIN, AuthState.copyWith, AuthStatus, AuthState
//  â³ Called by: AuthStatus
```

#### AuthNotifier.enterDigit (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void enterDigit(String digit)
//  â³ Called by: _PinEntryScreenState
```

#### AuthNotifier.build (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
AuthState build()
//  â³ Calls: AuthState
```

#### AuthNotifier.deleteDigit (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void deleteDigit()
//  â³ Called by: _PinEntryScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\app\db\local_db.dart (118 lines)

#### ShuaDiaryEntries.milestoneTag (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get milestoneTag
//  â³ Called by: LocalDatabase
```

#### ShuaDiaryEntries.id (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryBlocks (Class)
```rust
// Lines 55-66 (12 LOC | Complexity 1) | used by 1 callers
class ShuaDiaryBlocks extends Table
//  â³ Called by: LocalDatabase
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
//  â³ Called by: _SduiContainerState
```

#### ShuaDiaryEntries (Class)
```rust
// Lines 37-52 (16 LOC | Complexity 1) | used by 1 callers
class ShuaDiaryEntries extends Table
//  â³ Called by: LocalDatabase
```

#### EpisodicMemories.primaryKey (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Set<Column> get primaryKey
//  â³ Calls: ShuaSyncQueue.id
//  â³ Called by: ShuaDiaryBlocks.primaryKey, ShuaDiaryEntries.primaryKey
```

#### ShuaDiaryBlocks.lamportClock (Function)
```rust
// Lines 62-62 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
IntColumn get lamportClock
//  â³ Calls: ShuaDiaryEntries.lamportClock
```

#### ShuaDiaryBlocks.id (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryEntries.sentimentScore (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
RealColumn get sentimentScore
//  â³ Called by: LocalDatabase
```

#### ShuaSyncQueue.id (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 6 callers | [Pure]
IntColumn get id
//  â³ Called by: ShuaDiaryBlocks.primaryKey, ShuaDiaryBlocks.id, ShuaDiaryEntries.primaryKey, ShuaDiaryEntries.id, EpisodicMemories.primaryKey, EpisodicMemories.id
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
//  â³ Called by: _SduiRadioState, _SduiCheckboxState, MessagePackCodec, MessagePackCodec.encode, _SduiDividerState, GovernorLogger._sendAsync, GovernorLogger, ApiClient, ApiClient.postBinary, SduiEventDispatcher._handleSubmitForm, SduiEventDispatcher._fireRpc, SduiEventDispatcher._handleAiCommand, SduiEventDispatcher, SduiEventDispatcher.onAction, _SduiTableState, _SduiTableState._parseContent, _SduiSpacerState, _SduiDropdownState, _SduiExpansionTileState
```

#### EpisodicMemories.id (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
TextColumn get id
//  â³ Calls: ShuaSyncQueue.id
```

#### ShuaDiaryBlocks.metadata (Function)
```rust
// Lines 60-60 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get metadata
//  â³ Called by: LocalDatabase
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
//  â³ Calls: ShuaSyncQueue.createdAt
```

#### ShuaDiaryEntries.privacyTag (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get privacyTag
//  â³ Called by: LocalDatabase
```

#### ShuaDiaryEntries.primaryKey (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Set<Column> get primaryKey
//  â³ Calls: ShuaSyncQueue.id, EpisodicMemories.primaryKey
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

#### ShuaDiaryBlocks.content (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 20 callers | [Pure, CorePrimitive]
TextColumn get content
//  â³ Called by: _SduiHtmlViewerState, _SduiAudioState, _SduiScreenState, _NetworkConfigCardState, MediaUploader, _SduiMarkdownEditorState, _SduiMarkdownEditorState._buildReadonlyView, _SduiJbcPanelState, _SduiTerminalState, _SduiSandboxScreenState, _SduiListEditorState, _SduiListEditorState._loadFromContent, SduiButton, _SduiMapState, SduiTransport, SduiModuleCard, SduiNode, _SduiDocumentViewerState, SduiEventDispatcher, _SduiVideoState
```

#### EpisodicMemories (Class)
```rust
// Lines 23-34 (12 LOC | Complexity 1) | used by 1 callers
class EpisodicMemories extends Table
//  â³ Called by: LocalDatabase
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
//  â³ Called by: ShuaDiaryEntries.createdAt, EpisodicMemories.createdAt
```

#### ShuaDiaryEntries.title (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 16 callers | [Pure, CorePrimitive]
TextColumn get title
//  â³ Called by: _SduiHtmlViewerState, _SduiAudioState, _DashboardScreenState, _SduiScreenState, HorAIzonClientShell, SettingsPage, MediaUploader, SduiTimelineEvent, _SduiTimelineState, _SduiSandboxScreenState, SduiIconRegistry, _SduiDocumentViewerState, _SduiVideoState, SduiGauge, _SduiChartState, _SduiExpansionTileState
```

#### ShuaDiaryEntries.createdAt (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
DateTimeColumn get createdAt
//  â³ Calls: ShuaSyncQueue.createdAt
```

#### ShuaSyncQueue (Class)
```rust
// Lines 12-20 (9 LOC | Complexity 1) | used by 1 callers
class ShuaSyncQueue extends Table
//  â³ Calls: LocalDatabase
//  â³ Called by: LocalDatabase
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
//  â³ Calls: ShuaDiaryBlocks.metadata, ShuaDiaryEntries.milestoneTag, ShuaDiaryEntries.sentimentScore, ShuaDiaryEntries.analysisState, ShuaDiaryEntries.privacyTag, ShuaDiaryBlocks, ShuaDiaryEntries, EpisodicMemories, ShuaSyncQueue
//  â³ Called by: ShuaSyncQueue
```

#### ShuaDiaryBlocks.blockType (Function)
```rust
// Lines 58-58 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextColumn get blockType
//  â³ Called by: _SduiJbcPanelState
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
//  â³ Calls: ShuaSyncQueue.id, EpisodicMemories.primaryKey
```

#### ShuaDiaryBlocks.entryId (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
TextColumn get entryId
//  â³ Called by: _SduiScreenState, _SduiJbcPanelState, SduiJbcPanel, SduiEventDispatcher
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
//  â³ Called by: _DashboardScreenState, DashboardScreen.createState
```

#### _DashboardScreenState._loadDashboard (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadDashboard()
//  â³ Called by: _DashboardScreenState
```

#### _DashboardScreenState.initState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _DashboardScreenState
```

#### _DashboardScreenState (Class)
```rust
// Lines 15-89 (75 LOC | Complexity 1) | used by 1 callers
class _DashboardScreenState extends ConsumerState<DashboardScreen>
//  â³ Calls: SduiNode, DashboardScreen, SduiRenderer, ShuaDiaryEntries.title, SduiTransport.decodeJson, SduiTransport, _DashboardScreenState._loadDashboard, _DashboardScreenState.initState
//  â³ Called by: DashboardScreen.createState
```

#### DashboardScreen.createState (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<DashboardScreen> createState()
//  â³ Calls: DashboardScreen, _DashboardScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\messagepack_codec.dart (13 lines)

#### MessagePackCodec (Class)
```rust
// Lines 4-14 (11 LOC | Complexity 1) | used by 1 callers
class MessagePackCodec
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: ApiClient
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
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: ApiClient
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\utils\sdui_style_resolver.dart (52 lines)

#### SduiStyleResolver (Class)
```rust
// Lines 3-51 (49 LOC | Complexity 1) | used by 33 callers | [CorePrimitive]
class SduiStyleResolver
//  â³ Calls: SduiFlexContext.of
//  â³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, SduiGridView, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, _SduiMarkdownEditorState, SduiToggle, _SduiShimmerLoaderState.padding, _SduiDividerState, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, SduiListView, SduiButton, SduiRenderer, _SduiSliderState, _SduiDocumentViewerState, _SduiDrawingPadState, _SduiTableState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
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
//  â³ Called by: _SduiHtmlViewerState, _SduiContainerState, SduiGridView, _SduiShimmerLoaderState.padding, _SduiDividerState, SduiHeatmap, SduiListView, SduiRenderer, _SduiDocumentViewerState, _SduiCarouselState
```

#### SduiStyleResolver.resolveColor (Function)
```rust
// Lines 5-5 (1 LOC | Complexity 1) | used by 29 callers | [Pure, CorePrimitive]
static Color? resolveColor(BuildContext context, int? token)
//  â³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, _SduiMarkdownEditorState, SduiToggle, _SduiDividerState, SduiDatePicker, SduiProgressBar, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, SduiButton, _SduiSliderState, _SduiDocumentViewerState, _SduiDrawingPadState, _SduiTableState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\events\sdui_event_dispatcher.dart (492 lines)

#### SduiEventDispatcher._syncToServer (Function)
```rust
// Lines 401-401 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _syncToServer(String nodeId, dynamic value)
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher._fireRpc (Function)
```rust
// Lines 430-430 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _fireRpc(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: SduiEventDispatcher
```

#### SduiActionType (Enum)
```rust
// Lines 16-22 (7 LOC | Complexity 1) | used by 0 callers
enum SduiActionType
//  â³ Calls: SduiEventDispatcher
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
//  â³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiAudioState, _SduiCheckboxState, SduiTimePicker, _SduiTextInputState, MediaUploader, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, _SduiDividerState, SduiDatePicker, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiChip, SduiHeatmap, _SduiListEditorState, _SduiMapState, _SduiSliderState, _SduiDrawingPadState, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### SduiEventDispatcher._handleAiCommand (Function)
```rust
// Lines 218-218 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _handleAiCommand(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.onAction (Function)
```rust
// Lines 86-86 (1 LOC | Complexity 1) | used by 11 callers | [Pure, CorePrimitive]
void onAction(Map<int, dynamic> payload, [BuildContext? context])
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: _SduiRadioState, _SduiHtmlViewerState, _SduiCheckboxState, _SduiCodeEditorState, SduiToggle, _SduiOrdinalSliderState, SduiChip, SduiHeatmap, SduiButton, _SduiMapState, _SduiSliderState
```

#### SduiEventDispatcher._resolveScreenIdFromLocation (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? _resolveScreenIdFromLocation(String location)
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher.flushPending (Function)
```rust
// Lines 368-368 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void flushPending()
//  â³ Called by: _SduiScreenState
```

#### SduiEventDispatcher._resolveRpcMethodName (Function)
```rust
// Lines 396-396 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? _resolveRpcMethodName(int methodId)
//  â³ Called by: SduiEventDispatcher
```

#### SduiEventDispatcher (Class)
```rust
// Lines 31-499 (469 LOC | Complexity 1) | used by 47 callers | [CorePrimitive, HighComplexity]
class SduiEventDispatcher
//  â³ Calls: ShuaDiaryBlocks.entryId, SduiStateVault.get, SduiSocketManager.emitRpc, SduiEventDispatcher._resolveRpcMethodName, SduiIconRegistry.contains, BoundedRouteHistory.isEmpty, SduiSocketManager.injectLocalDelta, SduiEventDispatcher._handleAiCommand, SduiEventDispatcher._handleSubmitForm, ShuaDiaryBlocks.content, SduiEventDispatcher._resolveScreenIdFromLocation, BoundedRouteHistory.currentLocation, GovernorLogger.log, SduiEventDispatcher._fireRpc, SduiFlexContext.of, ShuaSyncQueue.payload, SduiEventDispatcher._syncToServer, SduiStateVault.set
//  â³ Called by: SduiWrap, SduiRadio, SduiHtmlViewer, SduiContainer, SduiAudio, _SduiScreenState._buildNodeList, _SduiScreenState._buildBody, _SduiScreenState, SduiGridView, SduiCheckbox, SduiTimePicker, SduiTextInput, MediaUploader.pickAndUploadWithUi, SduiImage, SduiMarkdownEditor, SduiCodeEditor, SduiToggle, SduiShimmerLoader, SduiDivider, SduiDatePicker, SduiProgressBar, SduiTerminal, SduiOrdinalSlider, SduiTimeline, SduiChip, _SduiSandboxScreenState._buildBody, SduiHeatmap, SduiListEditor, SduiListView, SduiButton, SduiRenderer, SduiMap, SduiSlider, SduiModuleCard, SduiDocumentViewer, SduiTypeRegistry.buildNode, SduiDrawingPad, SduiStlViewer, SduiTable, SduiSpacer, SduiVideo, SduiCarousel, SduiGauge, SduiChart, SduiDropdown, SduiExpansionTile, SduiActionType
```

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

### C:\horAIzon_2.0\client_flutter\lib\app\settings\settings_page.dart (341 lines)

#### _NetworkConfigCard (Class)
```rust
// Lines 173-178 (6 LOC | Complexity 1) | used by 3 callers
class _NetworkConfigCard extends ConsumerStatefulWidget
//  â³ Called by: _NetworkConfigCardState, _NetworkConfigCard.createState, SettingsPage
```

#### SettingsPage.build (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
//  â³ Called by: _NetworkConfigCardState.build
```

#### SettingsPage._buildColorSwatch (Function)
```rust
// Lines 125-131 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildColorSwatch(
//  â³ Called by: SettingsPage
```

#### _NetworkConfigCardState._saveSettings (Function)
```rust
// Lines 208-208 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveSettings()
//  â³ Called by: _NetworkConfigCardState
```

#### _NetworkConfigCardState.dispose (Function)
```rust
// Lines 199-199 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _NetworkConfigCardState
```

#### _NetworkConfigCardState (Class)
```rust
// Lines 180-335 (156 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _NetworkConfigCardState extends ConsumerState<_NetworkConfigCard>
//  â³ Calls: _NetworkConfigCard, _NetworkConfigCardState._saveSettings, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, ShuaDiaryBlocks.content, SduiFlexContext.of, ConfigNotifier.updateWorkspaceRoot, ConfigNotifier.updateGeminiApiKey, ConfigNotifier.updateOllamaModel, ConfigNotifier.updateOllamaUrl, ConfigNotifier.updateSyncBaseUrl, _NetworkConfigCardState.dispose, _NetworkConfigCardState.initState
//  â³ Called by: _NetworkConfigCard.createState
```

#### _NetworkConfigCardState.initState (Function)
```rust
// Lines 188-188 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _NetworkConfigCardState
```

#### SettingsPage (Class)
```rust
// Lines 6-171 (166 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SettingsPage extends ConsumerWidget
//  â³ Calls: ThemeNotifier.updatePrimary, ThemeNotifier.updateSecondary, _NetworkConfigCard, ThemeNotifier.updateTextScale, ThemeNotifier.updateAnimationMs, SettingsPage._buildColorSwatch, AppThemeSeeds, ThemeNotifier.toggleBrightness, ShuaDiaryEntries.title, SduiFlexContext.of, _SduiShimmerLoaderState.padding
```

#### _NetworkConfigCard.createState (Function)
```rust
// Lines 177-177 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<_NetworkConfigCard> createState()
//  â³ Calls: _NetworkConfigCard, _NetworkConfigCardState
```

#### _NetworkConfigCardState.build (Function)
```rust
// Lines 225-225 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: SettingsPage.build
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_container.dart (511 lines)

#### _SduiContainerState._buildReorderableItem (Function)
```rust
// Lines 243-248 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildReorderableItem(
//  â³ Calls: SduiNode
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState.build (Function)
```rust
// Lines 521-521 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiContainerState._resolveCurve (Function)
```rust
// Lines 125-125 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Curve _resolveCurve(int id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState.initState (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveMainAxisSize (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static MainAxisSize _resolveMainAxisSize(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState (Class)
```rust
// Lines 58-528 (471 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiContainerState extends State<SduiContainer>
//  â³ Calls: SduiNode, SduiContainer, _SduiContainerState._wrapAnimation, _SduiContainerState._wrapOpacity, _SduiContainerState._wrapDecoration, _SduiContainerState._buildLayout, SduiFlexContext.of, SduiStyleResolver.resolveEdgeInsets, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.maxHeight, _SduiContainerState._resolveSize, _SduiContainerState._resolveClip, _SduiContainerState._num, _SduiShimmerLoaderState.borderRadius, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiContainerState._buildChildren, _SduiContainerState._resolveMainAxisSize, _SduiContainerState._resolveCrossAxis, _SduiContainerState._resolveMainAxis, _SduiContainerState._buildReorderableList, BoundedRouteHistory.isEmpty, ShuaSyncQueue.actionType, _SduiContainerState._buildReorderableItem, _SduiContainerState._findDragHandleIndex, SduiEventDispatcher.onReorder, GovernorLogger.log, _SduiContainerState._extractBlockId, _SduiContainerState._int, SduiRenderer, SduiFlexContext, _SduiContainerState.dispose, _SduiContainerState._resolveCurve, _SduiContainerState._setupMountAnimation, _SduiContainerState.initState
//  â³ Called by: SduiContainer.createState
```

#### _SduiContainerState._setupMountAnimation (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _setupMountAnimation()
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveMainAxis (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static MainAxisAlignment _resolveMainAxis(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._wrapDecoration (Function)
```rust
// Lines 389-389 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _wrapDecoration(Widget child)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._wrapAnimation (Function)
```rust
// Lines 494-494 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _wrapAnimation(Widget child)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveClip (Function)
```rust
// Lines 119-119 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static Clip _resolveClip(int? id)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._resolveSize (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static double? _resolveSize(dynamic raw)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._extractBlockId (Function)
```rust
// Lines 301-301 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static String? _extractBlockId(String nodeId)
//  â³ Called by: _SduiContainerState
```

#### SduiContainer.createState (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiContainer> createState()
//  â³ Calls: SduiContainer, _SduiContainerState
```

#### _SduiContainerState._wrapOpacity (Function)
```rust
// Lines 486-486 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _wrapOpacity(Widget child)
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

#### _SduiContainerState._buildReorderableList (Function)
```rust
// Lines 176-176 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildReorderableList()
//  â³ Called by: _SduiContainerState
```

#### SduiContainer (Class)
```rust
// Lines 44-56 (13 LOC | Complexity 1) | used by 3 callers
class SduiContainer extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiContainerState, SduiContainer.createState, SduiTypeRegistry
```

#### _SduiContainerState._int (Function)
```rust
// Lines 312-312 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int _int(int key, [int fallback = 0])
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._findDragHandleIndex (Function)
```rust
// Lines 282-282 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int _findDragHandleIndex(SduiNode wrapperNode)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._buildChildren (Function)
```rust
// Lines 151-151 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<Widget> _buildChildren(bool isFlexLayout)
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState.dispose (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiContainerState
```

#### _SduiContainerState._num (Function)
```rust
// Lines 142-142 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double? _num(int key)
//  â³ Called by: _SduiContainerState
```

### C:\horAIzon_2.0\client_flutter\lib\app\theme\theme_provider.dart (151 lines)

#### ThemeNotifier.build (Function)
```rust
// Lines 55-55 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ThemeState build()
//  â³ Calls: ThemeState
```

#### ThemeNotifier._saveSettings (Function)
```rust
// Lines 88-88 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _saveSettings()
//  â³ Called by: ThemeNotifier
```

#### ThemeNotifier.updateAnimationMs (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateAnimationMs(int ms)
//  â³ Called by: SettingsPage
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

#### ThemeState (Class)
```rust
// Lines 13-51 (39 LOC | Complexity 1) | used by 3 callers
class ThemeState
//  â³ Calls: ThemeNotifier
//  â³ Called by: ThemeNotifier.build, ThemeState.copyWith, ThemeNotifier
```

#### ThemeState.compiledData (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ThemeData get compiledData
//  â³ Calls: ThemeCompiler.compile, ThemeCompiler
//  â³ Called by: HorAIzonClientShell
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

#### ThemeNotifier (Class)
```rust
// Lines 53-147 (95 LOC | Complexity 1) | used by 1 callers
class ThemeNotifier extends Notifier<ThemeState>
//  â³ Calls: SystemEvents, DiagnosticResult.success, DiagnosticResult, DiagnosticsHistoryNotifier.logResult, ThemeNotifier._logThemeChange, ThemeNotifier._saveSettings, ThemeState.copyWith, GovernorLogger.log, ThemeState, ThemeNotifier._loadSettings
//  â³ Called by: ThemeState
```

#### ThemeNotifier.updateSecondary (Function)
```rust
// Lines 121-121 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateSecondary(Color newColor)
//  â³ Called by: SettingsPage
```

#### ThemeState.copyWith (Function)
```rust
// Lines 36-42 (7 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
ThemeState copyWith(
//  â³ Calls: ThemeState
//  â³ Called by: ThemeNotifier
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_radio.dart (231 lines)

#### SduiRadio.createState (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiRadio> createState()
//  â³ Calls: SduiRadio, _SduiRadioState
```

#### _SduiRadioState.dispose (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiRadioState
```

#### _SduiRadioState (Class)
```rust
// Lines 23-235 (213 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiRadioState extends ConsumerState<SduiRadio>
//  â³ Calls: SduiRadio, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, SduiStateVault.set, ShuaSyncQueue.payload, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiRadioState.dispose, _SduiRadioState.didUpdateWidget, SduiNode.behavior, SduiNode.contentVal, _SduiRadioState.initState
//  â³ Called by: SduiRadio.createState
```

#### _SduiRadioState.didUpdateWidget (Function)
```rust
// Lines 49-49 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiRadio oldWidget)
//  â³ Calls: SduiRadio
//  â³ Called by: _SduiRadioState
```

#### _SduiRadioState.initState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiRadioState
```

#### _SduiRadioState.build (Function)
```rust
// Lines 78-78 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiRadio (Class)
```rust
// Lines 9-21 (13 LOC | Complexity 1) | used by 4 callers
class SduiRadio extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiRadioState.didUpdateWidget, _SduiRadioState, SduiRadio.createState, SduiTypeRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\core\sdui_transport.dart (269 lines)

#### SduiTransport.decodeJson (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
static List<SduiNode> decodeJson(String jsonString)
//  â³ Calls: SduiNode
//  â³ Called by: _DashboardScreenState, SduiSocketManager
```

#### SduiTransport (Class)
```rust
// Lines 5-257 (253 LOC | Complexity 1) | used by 3 callers | [HighComplexity]
class SduiTransport
//  â³ Calls: SduiTransport._insertAfterRecursive, SduiTransport._patchNodeInTree, SduiTransport._insertAfterInTree, SduiTransport._nodeFromMap, SduiTransport._removeNodeFromTree, SduiTransport.applyDelta, SduiNode, ShuaDiaryBlocks.content, SduiTransport._parseList
//  â³ Called by: _DashboardScreenState, _SduiScreenState, SduiSocketManager
```

#### SduiTransport.decode (Function)
```rust
// Lines 7-7 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static List<SduiNode> decode(Uint8List bytes)
//  â³ Calls: SduiNode
```

#### SduiTransport.patch (Function)
```rust
// Lines 19-19 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
static SduiNode patch(SduiNode existing, Map<String, dynamic> delta)
//  â³ Calls: SduiNode
```

#### SduiTransport._insertAfterInTree (Function)
```rust
// Lines 116-118 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _insertAfterInTree(
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

#### SduiTransport.applyDelta (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
static List<SduiNode> applyDelta(List<SduiNode> tree, dynamic rawDelta)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiScreenState, SduiSocketManager, SduiTransport
```

#### SduiTransport._patchNodeInTree (Function)
```rust
// Lines 161-163 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
static List<SduiNode> _patchNodeInTree(
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

#### SduiTransport._nodeFromMap (Function)
```rust
// Lines 201-201 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
static SduiNode _nodeFromMap(Map map)
//  â³ Calls: SduiNode
//  â³ Called by: SduiTransport
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_button.dart (112 lines)

#### SduiButton (Class)
```rust
// Lines 7-117 (111 LOC | Complexity 1) | used by 1 callers
class SduiButton extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiFlexContext.of, SduiIconRegistry.resolve, SduiIconRegistry, ShuaDiaryBlocks.content, SduiEventDispatcher.onAction, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior
//  â³ Called by: SduiTypeRegistry
```

#### SduiButton.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_time_picker.dart (395 lines)

#### SduiTimePicker._buildThemeData (Function)
```rust
// Lines 331-331 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildThemeData(BuildContext context, Widget? child, Color accentColor)
//  â³ Called by: SduiTimePicker
```

#### SduiTimePicker._pickTime (Function)
```rust
// Lines 250-257 (8 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _pickTime(
//  â³ Called by: SduiTimePicker
```

#### SduiTimePicker.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiTimePicker (Class)
```rust
// Lines 9-393 (385 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiTimePicker extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiEventDispatcher.onStateChange, SduiStateVault.set, SduiTimePicker._buildThemeData, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiTimePicker._pickTime, SduiIconRegistry.contains, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_expansion_tile.dart (364 lines)

#### _SduiExpansionTileState.initState (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiExpansionTileState
```

#### SduiExpansionTile.createState (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiExpansionTile> createState()
//  â³ Calls: SduiExpansionTile, _SduiExpansionTileState
```

#### _SduiExpansionTileState (Class)
```rust
// Lines 26-371 (346 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiExpansionTileState extends ConsumerState<SduiExpansionTile>
//  â³ Calls: SduiExpansionTile, _SduiShimmerLoaderState.borderRadius, SduiEventDispatcher.onStateChange, SduiStateVault.set, ShuaSyncQueue.payload, BoundedRouteHistory.isEmpty, SduiRenderer, _SduiShimmerLoaderState.padding, SduiIconRegistry.resolve, SduiIconRegistry, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, _SduiExpansionTileState.dispose, _SduiExpansionTileState.didUpdateWidget, SduiNode.contentVal, ShuaDiaryEntries.title, SduiNode.behavior, _SduiExpansionTileState.initState
//  â³ Called by: SduiExpansionTile.createState
```

#### SduiExpansionTile (Class)
```rust
// Lines 12-24 (13 LOC | Complexity 1) | used by 4 callers
class SduiExpansionTile extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiExpansionTileState.didUpdateWidget, _SduiExpansionTileState, SduiExpansionTile.createState, SduiTypeRegistry
```

#### _SduiExpansionTileState.build (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiExpansionTileState.dispose (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiExpansionTileState
```

#### _SduiExpansionTileState.didUpdateWidget (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiExpansionTile oldWidget)
//  â³ Calls: SduiExpansionTile
//  â³ Called by: _SduiExpansionTileState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\utils\binary_lexo_rank.dart (100 lines)

#### BinaryLexoRank (Class)
```rust
// Lines 5-101 (97 LOC | Complexity 1) | used by 0 callers
class BinaryLexoRank
//  â³ Calls: BoundedRouteHistory.isEmpty
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

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_chart.dart (487 lines)

#### _SduiChartState._buildEmptyState (Function)
```rust
// Lines 434-434 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._buildCandlestickChart (Function)
```rust
// Lines 410-410 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildCandlestickChart(ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._getRawDataString (Function)
```rust
// Lines 56-56 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _getRawDataString()
//  â³ Called by: _SduiChartState
```

#### _SduiChartState.didUpdateWidget (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiChart oldWidget)
//  â³ Calls: SduiChart
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._formatPointsToText (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatPointsToText(List<SduiChartDataPoint> points)
//  â³ Calls: SduiChartDataPoint
//  â³ Called by: _SduiChartState
```

#### SduiChartDataPoint (Class)
```rust
// Lines 457-486 (30 LOC | Complexity 1) | used by 3 callers
class SduiChartDataPoint
//  â³ Called by: _SduiChartState._formatPointsToText, SduiChartDataPoint.SduiChartDataPoint, _SduiChartState
```

#### SduiChartDataPoint.fromMap (Function)
```rust
// Lines 474-474 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
factory SduiChartDataPoint.fromMap(Map<dynamic, dynamic> map)
//  â³ Called by: SduiChartDataPoint.SduiChartDataPoint, _SduiChartState
```

#### _SduiChartState.dispose (Function)
```rust
// Lines 51-51 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiChartState
```

#### _SduiChartState._parseFromTextLines (Function)
```rust
// Lines 144-144 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseFromTextLines(String text)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState.build (Function)
```rust
// Lines 172-172 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiChartState._buildColumnChart (Function)
```rust
// Lines 369-369 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildColumnChart(Color accentColor, ColorScheme colorScheme, ThemeData theme)
//  â³ Called by: _SduiChartState
```

#### _SduiChartState (Class)
```rust
// Lines 28-455 (428 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiChartState extends ConsumerState<SduiChart>
//  â³ Calls: SduiChart, SduiEventDispatcher.onStateChange, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, _SduiChartState._buildSplineAreaChart, _SduiChartState._buildCandlestickChart, _SduiChartState._buildPieChart, _SduiChartState._buildColumnChart, _SduiChartState._buildEmptyState, ShuaDiaryEntries.title, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, BoundedRouteHistory.isEmpty, _SduiChartState._parseFromTextLines, _SduiChartState._formatPointsToText, SduiChartDataPoint.fromMap, SduiChartDataPoint, SduiNode.contentVal, SduiNode.behavior, _SduiChartState.dispose, _SduiChartState.didUpdateWidget, _SduiChartState._getRawDataString, _SduiChartState._parseData, _SduiChartState.initState
//  â³ Called by: SduiChart.createState
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

#### SduiChartDataPoint.SduiChartDataPoint (Function)
```rust
// Lines 474-474 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory SduiChartDataPoint.fromMap(Map<dynamic, dynamic> map)
//  â³ Calls: SduiChartDataPoint.fromMap, SduiChartDataPoint
```

#### SduiChart.createState (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiChart> createState()
//  â³ Calls: SduiChart, _SduiChartState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_carousel.dart (386 lines)

#### _SduiCarouselState._boolBehavior (Function)
```rust
// Lines 159-159 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool _boolBehavior(int key, {required bool defaultValue})
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._resolveController (Function)
```rust
// Lines 102-102 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
PageController _resolveController(double peekExtent, double screenWidth)
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

#### _SduiCarouselState._doubleBehavior (Function)
```rust
// Lines 167-167 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double _doubleBehavior(int key, {required double defaultValue})
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState._stopAutoScroll (Function)
```rust
// Lines 144-144 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _stopAutoScroll()
//  â³ Called by: _SduiCarouselState
```

#### SduiCarousel (Class)
```rust
// Lines 43-55 (13 LOC | Complexity 1) | used by 3 callers
class SduiCarousel extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiCarouselState, SduiCarousel.createState, SduiTypeRegistry
```

#### _SduiCarouselState._onPageChanged (Function)
```rust
// Lines 148-148 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onPageChanged(int page)
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState.initState (Function)
```rust
// Lines 78-78 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState (Class)
```rust
// Lines 57-404 (348 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiCarouselState extends ConsumerState<SduiCarousel>
//  â³ Calls: SduiCarousel, _SduiShimmerLoaderState.borderRadius, _SduiCarouselState._buildDotIndicators, _SduiCarouselState._buildArrowButton, SduiRenderer, _SduiCarouselState._onPageChanged, _SduiCarouselState._stopAutoScroll, _SduiCarouselState._startAutoScroll, _SduiCarouselState._resolveController, _SduiCarouselState._buildEmpty, SduiStyleResolver.resolveColor, _SduiCarouselState._boolBehavior, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, _SduiShimmerLoaderState.padding, _SduiCarouselState._doubleBehavior, SduiFlexContext.of, SduiEventDispatcher.onStateChange, SduiStateVault.set, _SduiCarouselState.dispose, SduiNode.contentVal, SduiNode.behavior, _SduiCarouselState.initState
//  â³ Called by: SduiCarousel.createState
```

#### _SduiCarouselState._buildEmpty (Function)
```rust
// Lines 363-367 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmpty(
//  â³ Calls: _SduiShimmerLoaderState.padding
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState.dispose (Function)
```rust
// Lines 92-92 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiCarouselState
```

#### _SduiCarouselState.build (Function)
```rust
// Lines 176-176 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiCarousel.createState (Function)
```rust
// Lines 54-54 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiCarousel> createState()
//  â³ Calls: SduiCarousel, _SduiCarouselState
```

#### _SduiCarouselState._startAutoScroll (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _startAutoScroll(int intervalMs, int pageCount)
//  â³ Called by: _SduiCarouselState
```

### C:\horAIzon_2.0\client_flutter\lib\core\governor\metrics_snapshot.dart (88 lines)

#### ModuleMetrics.ModuleMetrics (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory ModuleMetrics.fromJson(Map<String, dynamic> json)
//  â³ Calls: ModuleMetrics.fromJson, ModuleMetrics
```

#### MetricsSnapshot.MetricsSnapshot (Function)
```rust
// Lines 66-66 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory MetricsSnapshot.fromJson(Map<String, dynamic> json)
//  â³ Calls: ModuleMetrics.fromJson, MetricsSnapshot
```

#### ModuleMetrics.fromJson (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
factory ModuleMetrics.fromJson(Map<String, dynamic> json)
//  â³ Called by: MetricsSnapshot, MetricsSnapshot.MetricsSnapshot, ModuleMetrics.ModuleMetrics
```

#### ModuleMetrics (Class)
```rust
// Lines 7-30 (24 LOC | Complexity 1) | used by 2 callers
class ModuleMetrics
//  â³ Called by: MetricsSnapshot, ModuleMetrics.ModuleMetrics
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
//  â³ Calls: ModuleMetrics.fromJson, ModuleMetrics
//  â³ Called by: MetricsSnapshot.MetricsSnapshot
```

#### MetricsSnapshot.toString (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
String toString()
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_table.dart (352 lines)

#### _SduiTableState._resolveAccentColor (Function)
```rust
// Lines 204-204 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _resolveAccentColor(ThemeData theme)
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._saveMatrix (Function)
```rust
// Lines 112-112 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveMatrix()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._colWidth (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double get _colWidth
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._parseContent (Function)
```rust
// Lines 84-84 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _parseContent(String payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.build (Function)
```rust
// Lines 210-210 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiTableState._onFocusChange (Function)
```rust
// Lines 61-61 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFocusChange()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._removeRow (Function)
```rust
// Lines 182-182 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _removeRow()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._saveCellEdit (Function)
```rust
// Lines 146-146 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _saveCellEdit()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._headerLabel (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String? get _headerLabel
//  â³ Calls: SduiNode.contentVal
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._addColumn (Function)
```rust
// Lines 172-172 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _addColumn()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.initState (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState.didUpdateWidget (Function)
```rust
// Lines 68-68 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiTable oldWidget)
//  â³ Calls: SduiTable
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
// Lines 77-77 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._minCols (Function)
```rust
// Lines 33-33 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get _minCols
//  â³ Calls: _SduiTableState._int
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._removeColumn (Function)
```rust
// Lines 192-192 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _removeColumn()
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._bindKey (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _bindKey
//  â³ Calls: SduiNode.behavior
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

#### _SduiTableState._isReadOnly (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
bool get _isReadOnly
//  â³ Calls: _SduiTableState._int
//  â³ Called by: _SduiTableState
```

#### _SduiTableState._startCellEdit (Function)
```rust
// Lines 124-124 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _startCellEdit(int row, int col)
//  â³ Called by: _SduiTableState
```

#### SduiTable (Class)
```rust
// Lines 6-18 (13 LOC | Complexity 1) | used by 4 callers
class SduiTable extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTableState.didUpdateWidget, _SduiTableState, SduiTable.createState, SduiTypeRegistry
```

#### _SduiTableState (Class)
```rust
// Lines 20-335 (316 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiTableState extends State<SduiTable>
//  â³ Calls: SduiTable, _SduiShimmerLoaderState.padding, _SduiTableState._startCellEdit, _SduiShimmerLoaderState.borderRadius, _SduiTableState._colWidth, _SduiTableState._addColumn, _SduiTableState._removeColumn, _SduiTableState._addRow, _SduiTableState._removeRow, _SduiTableState._headerLabel, _SduiTableState._resolveAccentColor, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, _SduiTableState._minCols, _SduiTableState._minRows, _SduiTableState._saveMatrix, _SduiTableState._isReadOnly, SduiEventDispatcher.onStateChange, _SduiTableState._bindKey, BoundedRouteHistory.isEmpty, ShuaSyncQueue.payload, _SduiTableState.dispose, SduiNode.contentVal, _SduiTableState.didUpdateWidget, _SduiTableState._saveCellEdit, _SduiTableState._onFocusChange, _SduiTableState._initialContent, _SduiTableState._parseContent, _SduiTableState.initState, SduiNode.behavior
//  â³ Called by: SduiTable.createState
```

#### _SduiTableState._int (Function)
```rust
// Lines 46-46 (1 LOC | Complexity 1) | used by 3 callers | [Pure]
int? _int(int key)
//  â³ Called by: _SduiTableState._isReadOnly, _SduiTableState._minCols, _SduiTableState._minRows
```

#### SduiTable.createState (Function)
```rust
// Lines 17-17 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiTable> createState()
//  â³ Calls: SduiTable, _SduiTableState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_date_picker.dart (372 lines)

#### SduiDatePicker._buildThemeData (Function)
```rust
// Lines 283-283 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildThemeData(BuildContext context, Widget? child, Color accentColor)
//  â³ Called by: SduiDatePicker
```

#### SduiDatePicker (Class)
```rust
// Lines 9-367 (359 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SduiDatePicker extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiIconRegistry.contains, SduiEventDispatcher.onStateChange, SduiStateVault.set, SduiDatePicker._buildThemeData, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiDatePicker._triggerPicker, SduiDatePicker._formatDate, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiDatePicker.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiDatePicker._formatDate (Function)
```rust
// Lines 360-360 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatDate(DateTime date)
//  â³ Called by: SduiDatePicker
```

#### SduiDatePicker._triggerPicker (Function)
```rust
// Lines 222-231 (10 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _triggerPicker(
//  â³ Called by: SduiDatePicker
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_terminal.dart (836 lines)

#### _SuccessRateBadge (Class)
```rust
// Lines 771-804 (34 LOC | Complexity 1) | used by 1 callers
class _SuccessRateBadge extends StatelessWidget
//  â³ Calls: DiagnosticsState, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, DiagnosticsState.successRate
//  â³ Called by: _SduiTerminalState
```

#### _TerminalLineState.build (Function)
```rust
// Lines 539-539 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: _SduiTerminalState.build
```

#### _FilterChip.build (Function)
```rust
// Lines 821-821 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: _SduiTerminalState.build
```

#### _SduiTerminalState._getFilteredLogs (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<DiagnosticResult> _getFilteredLogs(DiagnosticsState state)
//  â³ Calls: DiagnosticsState, DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### SduiTerminal.createState (Function)
```rust
// Lines 42-42 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
ConsumerState<SduiTerminal> createState()
//  â³ Calls: SduiTerminal, _SduiTerminalState
//  â³ Called by: _TerminalLine.createState
```

#### _TerminalLineState (Class)
```rust
// Lines 535-768 (234 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _TerminalLineState extends State<_TerminalLine>
//  â³ Calls: _TerminalLine, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of
//  â³ Called by: _TerminalLine.createState
```

#### _SduiTerminalState._buildStdinRow (Function)
```rust
// Lines 458-458 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStdinRow(BuildContext context, Color accentColor)
//  â³ Called by: _SduiTerminalState
```

#### _TerminalLine.createState (Function)
```rust
// Lines 532-532 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<_TerminalLine> createState()
//  â³ Calls: _TerminalLine, _TerminalLineState, SduiTerminal.createState
```

#### _FilterChip (Class)
```rust
// Lines 807-850 (44 LOC | Complexity 1) | used by 1 callers
class _FilterChip extends StatelessWidget
//  â³ Calls: _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.padding, SduiFlexContext.of
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._buildLogList (Function)
```rust
// Lines 411-415 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildLogList(
//  â³ Calls: DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState.dispose (Function)
```rust
// Lines 54-54 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiTerminalState
```

#### _SuccessRateBadge.build (Function)
```rust
// Lines 778-778 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Calls: _SduiTerminalState.build
```

#### _SduiTerminalState._copyLogs (Function)
```rust
// Lines 117-120 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _copyLogs(
//  â³ Calls: DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._severityColor (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Color _severityColor(DiagnosticResult result, ColorScheme colors)
//  â³ Calls: DiagnosticResult
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._buildSubsystemFilterBar (Function)
```rust
// Lines 364-368 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildSubsystemFilterBar(
//  â³ Calls: DiagnosticsState
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._submitStdin (Function)
```rust
// Lines 175-175 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _submitStdin(String command)
//  â³ Called by: _SduiTerminalState
```

#### _SduiTerminalState._buildHeader (Function)
```rust
// Lines 262-268 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildHeader(
//  â³ Calls: DiagnosticResult, DiagnosticsState
//  â³ Called by: _SduiTerminalState
```

#### SduiTerminal (Class)
```rust
// Lines 35-43 (9 LOC | Complexity 1) | used by 3 callers
class SduiTerminal extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTerminalState, SduiTerminal.createState, SduiTypeRegistry
```

#### _TerminalLine (Class)
```rust
// Lines 520-533 (14 LOC | Complexity 1) | used by 3 callers
class _TerminalLine extends StatefulWidget
//  â³ Calls: DiagnosticResult
//  â³ Called by: _TerminalLineState, _TerminalLine.createState, _SduiTerminalState
```

#### _SduiTerminalState (Class)
```rust
// Lines 45-512 (468 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiTerminalState extends ConsumerState<SduiTerminal>
//  â³ Calls: DiagnosticResult, DiagnosticsState, DiagnosticSeverity, SduiTerminal, _SduiTerminalState._submitStdin, _SduiTerminalState._severityColor, _TerminalLine, _SduiShimmerLoaderState.maxHeight, GovernorLogger.log, DiagnosticsHistoryNotifier.clearHistory, _SduiTerminalState._copyLogs, _FilterChip, _SuccessRateBadge, _SduiShimmerLoaderState.padding, _SduiTerminalState._buildStdinRow, _SduiTerminalState._buildLogList, _SduiTerminalState._buildSubsystemFilterBar, _SduiTerminalState._buildHeader, _SduiShimmerLoaderState.borderRadius, _SduiTerminalState._getFilteredLogs, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiEventDispatcher.onStateChange, SduiNode.behavior, ShuaDiaryBlocks.content, SduiFlexContext.of, _SduiTerminalState._formatTimestamp, BoundedRouteHistory.isEmpty, _SduiTerminalState.dispose
//  â³ Called by: SduiTerminal.createState
```

#### _SduiTerminalState.build (Function)
```rust
// Lines 183-183 (1 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
//  â³ Called by: _FilterChip.build, _SuccessRateBadge.build, _TerminalLineState.build
```

#### _SduiTerminalState._formatTimestamp (Function)
```rust
// Lines 108-108 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatTimestamp(DateTime ts)
//  â³ Called by: _SduiTerminalState
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
//  â³ Calls: SduiWrap, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiRenderer, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiWrap.createState
```

#### _SduiWrapState.build (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiWrap.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiWrap> createState()
//  â³ Calls: SduiWrap, _SduiWrapState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_code_editor.dart (494 lines)

#### SduiCodeEditor (Class)
```rust
// Lines 204-216 (13 LOC | Complexity 1) | used by 4 callers
class SduiCodeEditor extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiCodeEditorState.didUpdateWidget, _SduiCodeEditorState, SduiCodeEditor.createState, SduiTypeRegistry
```

#### _SduiCodeEditorState.initState (Function)
```rust
// Lines 226-226 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiCodeEditorState
```

#### SyntaxRules (Class)
```rust
// Lines 8-22 (15 LOC | Complexity 1) | used by 1 callers
class SyntaxRules
//  â³ Called by: SyntaxHighlightingController
```

#### _SduiCodeEditorState (Class)
```rust
// Lines 218-496 (279 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiCodeEditorState extends ConsumerState<SduiCodeEditor>
//  â³ Calls: SduiCodeEditor, _SduiCodeEditorState._onLanguageChanged, SyntaxHighlightingController.buildTextSpan, _SduiCodeEditorState._onTextChanged, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, _SduiCodeEditorState.dispose, _SduiCodeEditorState.didUpdateWidget, _SduiCodeEditorState._onFocusChange, SyntaxHighlightingController, SduiNode.behavior, SduiNode.contentVal, _SduiCodeEditorState.initState
//  â³ Called by: SduiCodeEditor.createState
```

#### _SduiCodeEditorState.dispose (Function)
```rust
// Lines 282-282 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiCodeEditorState
```

#### SyntaxHighlightingController (Class)
```rust
// Lines 25-202 (178 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class SyntaxHighlightingController extends TextEditingController
//  â³ Calls: SduiFlexContext.of, BoundedRouteHistory.isEmpty, SyntaxRules
//  â³ Called by: _SduiCodeEditorState
```

#### _SduiCodeEditorState.didUpdateWidget (Function)
```rust
// Lines 254-254 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(SduiCodeEditor oldWidget)
//  â³ Calls: SduiCodeEditor
//  â³ Called by: _SduiCodeEditorState
```

#### _SduiCodeEditorState.build (Function)
```rust
// Lines 315-315 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiCodeEditorState._onTextChanged (Function)
```rust
// Lines 290-290 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiCodeEditorState
```

#### SyntaxHighlightingController.buildTextSpan (Function)
```rust
// Lines 140-140 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing})
//  â³ Called by: _SduiCodeEditorState
```

#### SduiCodeEditor.createState (Function)
```rust
// Lines 215-215 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiCodeEditor> createState()
//  â³ Calls: SduiCodeEditor, _SduiCodeEditorState
```

#### _SduiCodeEditorState._onFocusChange (Function)
```rust
// Lines 245-245 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onFocusChange()
//  â³ Called by: _SduiCodeEditorState
```

#### _SduiCodeEditorState._onLanguageChanged (Function)
```rust
// Lines 297-297 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onLanguageChanged(int newLangId)
//  â³ Called by: _SduiCodeEditorState
```

### C:\horAIzon_2.0\client_flutter\lib\app\diagnostics\diagnostics_provider.dart (352 lines)

#### DiagnosticsHistoryNotifier.build (Function)
```rust
// Lines 112-112 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
DiagnosticsState build()
//  â³ Calls: DiagnosticsState
```

#### DiagnosticsState.successRate (Function)
```rust
// Lines 97-97 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double get successRate
//  â³ Called by: _SuccessRateBadge
```

#### DiagnosticsState (Class)
```rust
// Lines 24-102 (79 LOC | Complexity 1) | used by 8 callers
class DiagnosticsState
//  â³ Calls: DiagnosticResult
//  â³ Called by: DiagnosticsHistoryNotifier.build, DiagnosticsState.copyWith, _SuccessRateBadge, _SduiTerminalState._buildSubsystemFilterBar, _SduiTerminalState._buildHeader, _SduiTerminalState, _SduiTerminalState._getFilteredLogs, DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.setTelemetryProfile (Function)
```rust
// Lines 168-168 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void setTelemetryProfile(TelemetryProfile profile)
//  â³ Calls: TelemetryProfile
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsState.copyWith (Function)
```rust
// Lines 67-79 (13 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
DiagnosticsState copyWith(
//  â³ Calls: DiagnosticResult, DiagnosticsState
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### TelemetryProfile (Enum)
```rust
// Lines 12-21 (10 LOC | Complexity 1) | used by 2 callers
enum TelemetryProfile
//  â³ Calls: GovernorLogger.log, DiagnosticResult.success, DiagnosticResult.failure, SystemDiagnostic, DiagnosticSeverity, BoundedRouteHistory.isEmpty, DiagnosticResult, DiagnosticsHistoryNotifier
//  â³ Called by: DiagnosticsHistoryNotifier.setTelemetryProfile, DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.updateLimits (Function)
```rust
// Lines 144-149 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
void updateLimits(
//  â³ Called by: DiagnosticsHistoryNotifier
```

#### DiagnosticsHistoryNotifier.logResult (Function)
```rust
// Lines 203-203 (1 LOC | Complexity 1) | used by 4 callers | [Pure]
void logResult(DiagnosticResult result, {bool fromRemote = false})
//  â³ Calls: DiagnosticResult
//  â³ Called by: DiagnosticsHistoryNotifier, ThemeNotifier, BoundedRouteHistory, AuthNotifier
```

#### DiagnosticsHistoryNotifier (Class)
```rust
// Lines 110-346 (237 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiagnosticsHistoryNotifier extends Notifier<DiagnosticsState>
//  â³ Calls: DiagnosticResult, DiagnosticResult.latencyMs, DiagnosticResult.isFailure, DiagnosticResult.isCritical, OccurrenceEntry, GovernorLogger.log, DiagnosticSeverity, TelemetryProfile, DiagnosticsHistoryNotifier.setTelemetryProfile, DiagnosticsHistoryNotifier.updateLimits, DiagnosticsHistoryNotifier._truncate, DiagnosticsState.copyWith, DiagnosticsState, DiagnosticsHistoryNotifier.logResult
//  â³ Called by: TelemetryProfile
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
//  â³ Called by: _SduiTerminalState
```

#### DiagnosticsHistoryNotifier._truncate (Function)
```rust
// Lines 136-136 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<DiagnosticResult> _truncate(List<DiagnosticResult> list, int limit)
//  â³ Calls: DiagnosticResult
//  â³ Called by: DiagnosticsHistoryNotifier
```

### C:\horAIzon_2.0\client_flutter\lib\app\theme\theme_compiler.dart (43 lines)

#### ThemeCompiler.compile (Function)
```rust
// Lines 5-10 (6 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
static ThemeData compile(
//  â³ Called by: ThemeState.compiledData
```

#### ThemeCompiler (Class)
```rust
// Lines 4-40 (37 LOC | Complexity 1) | used by 1 callers
class ThemeCompiler
//  â³ Called by: ThemeState.compiledData
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
//  â³ Called by: BoundedRouteHistory
```

#### BoundedRouteHistory.isEmpty (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 25 callers | [Pure, Tested, CorePrimitive]
bool get isEmpty
//  â³ Called by: _SduiContainerState, TelemetryProfile, _SduiAudioState, SduiImage, _SduiMarkdownEditorState, SyntaxHighlightingController, _SduiJbcPanelState, _SduiTerminalState, _SduiTimelineState, _SduiSandboxScreenState, SduiHeatmap, _SduiListEditorState, SduiListView, BinaryLexoRank, SduiModuleCard, _SduiDocumentViewerState, SduiEventDispatcher, _DrawingPainter, _SduiDrawingPadState, AuthNotifier, _SduiTableState, _SduiVideoState, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
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
//  â³ Called by: BoundedRouteHistory
```

#### BoundedRouteHistory.currentLocation (Function)
```rust
// Lines 34-34 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
String? get currentLocation
//  â³ Called by: AdaptiveShell, SduiEventDispatcher
```

#### BoundedRouteHistory.moveBack (Function)
```rust
// Lines 93-93 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void moveBack()
//  â³ Called by: AdaptiveShell
```

#### BoundedRouteHistory.canGoBack (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 2 callers | [Pure, Tested]
bool get canGoBack
//  â³ Called by: AdaptiveShell, BoundedRouteHistory
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
//  â³ Called by: AdaptiveShell, BoundedRouteHistory
```

#### BoundedRouteHistory (Class)
```rust
// Lines 13-156 (144 LOC | Complexity 1) | used by 0 callers
class BoundedRouteHistory extends ChangeNotifier
//  â³ Calls: DiagnosticsHistoryNotifier.logResult, SystemEvents, DiagnosticResult.success, DiagnosticResult, BoundedRouteHistory.canGoBack, BoundedRouteHistory.canGoForward, BoundedRouteHistory._logRouteEvent, RouteNode
```

#### BoundedRouteHistory.moveForward (Function)
```rust
// Lines 83-83 (1 LOC | Complexity 1) | used by 1 callers | [Pure, Tested]
void moveForward()
//  â³ Called by: AdaptiveShell
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_shimmer_loader.dart (362 lines)

#### _SduiShimmerLoaderState._buildMediaCard (Function)
```rust
// Lines 151-151 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMediaCard(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState (Class)
```rust
// Lines 21-343 (323 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiShimmerLoaderState extends State<SduiShimmerLoader> with SingleTickerProviderStateMixin
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState._animated, _SduiShimmerLoaderState._buildRectangle, _SduiShimmerLoaderState._buildTerminalWindow, _SduiShimmerLoaderState._buildModuleCard, _SduiShimmerLoaderState._buildFeedRow, _SduiShimmerLoaderState._buildStatCard, _SduiShimmerLoaderState._buildChatBubble, _SduiShimmerLoaderState._buildMediaCard, _SduiShimmerLoaderState._buildParagraph, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState.shimmerType, SduiFlexContext.of, _SduiShimmerLoaderState._buildListTile, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState._circle, _SduiShimmerLoaderState.lastLineWidthPct, _SduiShimmerLoaderState._rect, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.lineCount, _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.dispose, _SduiShimmerLoaderState.shimmerAnimStyle, _SduiShimmerLoaderState.initState
//  â³ Called by: SduiShimmerLoader.createState
```

#### _SduiShimmerLoaderState.shimmerAnimStyle (Function)
```rust
// Lines 27-27 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get shimmerAnimStyle
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildStatCard (Function)
```rust
// Lines 177-177 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStatCard(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.lineCount (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get lineCount
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.initState (Function)
```rust
// Lines 35-35 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiShimmerLoaderState
```

#### SduiShimmerLoader.createState (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
State<SduiShimmerLoader> createState()
//  â³ Calls: SduiShimmerLoader, _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildModuleCard (Function)
```rust
// Lines 201-201 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildModuleCard(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.lastLineWidthPct (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double get lastLineWidthPct
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildCircle (Function)
```rust
// Lines 114-114 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildCircle(Color c)
//  â³ Calls: _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState._circle
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildChatBubble (Function)
```rust
// Lines 163-163 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildChatBubble(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._animated (Function)
```rust
// Lines 53-53 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _animated(Widget child, Color baseColor)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.padding (Function)
```rust
// Lines 32-32 (1 LOC | Complexity 1) | used by 50 callers | [Pure, CorePrimitive]
EdgeInsetsGeometry get padding
//  â³ Calls: SduiNode.behavior, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver
//  â³ Called by: _SduiWrapState, _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, _SduiScreenState, SduiGridView, _SduiCheckboxState, _NetworkConfigCardState, SettingsPage, SduiTimePicker, SduiImage, _PinEntryScreenState, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, _SduiShimmerLoaderState, _SduiJbcPanelState, _SduiDividerState, SduiDatePicker, SduiProgressBar, _FilterChip, _SuccessRateBadge, _TerminalLineState, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, _SduiSandboxScreenState, AdaptiveShell, SduiHeatmap, _SduiListEditorState, SduiListView, SduiRenderer, _SduiMapState, _ActionChip, _TelemetryChip, SduiModuleCard, _SduiDocumentViewerState, SduiTypeRegistry, _SduiDrawingPadState, SduiStlViewer, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState._buildEmpty, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### _SduiShimmerLoaderState._buildFeedRow (Function)
```rust
// Lines 189-189 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildFeedRow(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.borderRadius (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 42 callers | [Pure, CorePrimitive]
double get borderRadius
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiWrapState, _SduiRadioState, _SduiHtmlViewerState, _SduiContainerState, _SduiAudioState, _SduiCheckboxState, _NetworkConfigCardState, SduiTimePicker, SduiImage, _PinEntryScreenState, _SduiMarkdownEditorState, _SduiCodeEditorState, SduiToggle, _SduiShimmerLoaderState._buildRectangle, _SduiShimmerLoaderState, _SduiJbcPanelState, _SduiDividerState, SduiDatePicker, SduiProgressBar, _FilterChip, _SuccessRateBadge, _TerminalLineState, _SduiTerminalState, _SduiOrdinalSliderState, _SduiTimelineState, SduiHeatmap, _SduiListEditorState, _SduiMapState, _ActionChip, _TelemetryChip, SduiModuleCard, _SduiDocumentViewerState, _SduiDrawingPadState, SduiStlViewer, _SduiTableState, _SduiSpacerState, _SduiVideoState, _SduiCarouselState, SduiGauge, _SduiChartState, _SduiDropdownState, _SduiExpansionTileState
```

#### _SduiShimmerLoaderState._buildParagraph (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildParagraph(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildListTile (Function)
```rust
// Lines 130-130 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildListTile(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### SduiShimmerLoader (Class)
```rust
// Lines 5-19 (15 LOC | Complexity 1) | used by 5 callers
class SduiShimmerLoader extends StatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiShimmerLoaderState, SduiShimmerLoader.createState, _SduiScreenState, SduiModuleCard, SduiTypeRegistry
```

#### _SduiShimmerLoaderState.shimmerType (Function)
```rust
// Lines 26-26 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int get shimmerType
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._buildTerminalWindow (Function)
```rust
// Lines 241-241 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildTerminalWindow(Color c)
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.dispose (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState._rect (Function)
```rust
// Lines 92-92 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Widget _rect(Color color, {double? height, double radius = 8.0, double widthFactor = 1.0})
//  â³ Called by: _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildRectangle
```

#### _SduiShimmerLoaderState.build (Function)
```rust
// Lines 314-314 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiShimmerLoaderState._buildRectangle (Function)
```rust
// Lines 113-113 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildRectangle(Color c)
//  â³ Calls: _SduiShimmerLoaderState.borderRadius, _SduiShimmerLoaderState.maxHeight, _SduiShimmerLoaderState._rect
//  â³ Called by: _SduiShimmerLoaderState
```

#### _SduiShimmerLoaderState.maxHeight (Function)
```rust
// Lines 30-30 (1 LOC | Complexity 1) | used by 8 callers | [Pure]
double? get maxHeight
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiContainerState, SduiGridView, _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildCircle, _SduiShimmerLoaderState._buildRectangle, _SduiTerminalState, SduiHeatmap, SduiListView
```

#### _SduiShimmerLoaderState._circle (Function)
```rust
// Lines 105-105 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
Widget _circle(Color color, double diameter)
//  â³ Called by: _SduiShimmerLoaderState, _SduiShimmerLoaderState._buildCircle
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_document_viewer.dart (551 lines)

#### SduiDocumentViewer (Class)
```rust
// Lines 34-46 (13 LOC | Complexity 1) | used by 3 callers
class SduiDocumentViewer extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiDocumentViewerState, SduiDocumentViewer.createState, SduiTypeRegistry
```

#### _SduiDocumentViewerState.build (Function)
```rust
// Lines 136-136 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiDocumentViewerState._showPicker (Function)
```rust
// Lines 64-64 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context)
//  â³ Called by: _SduiDocumentViewerState
```

#### _SduiDocumentViewerState.dispose (Function)
```rust
// Lines 57-57 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiDocumentViewerState
```

#### _SduiDocumentViewerState._buildUploadBox (Function)
```rust
// Lines 416-422 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildUploadBox(
//  â³ Called by: _SduiDocumentViewerState
```

#### _SduiDocumentViewerState (Class)
```rust
// Lines 48-563 (516 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiDocumentViewerState extends ConsumerState<SduiDocumentViewer>
//  â³ Calls: SduiDocumentViewer, ShuaDiaryBlocks.content, _SduiDocumentViewerState._showPicker, _SduiDocumentViewerState._buildErrorState, _SduiDocumentViewerState._buildEmptyReadonly, _SduiDocumentViewerState._buildUploadBox, BoundedRouteHistory.isEmpty, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, MediaUploader.pickAndUploadWithUi, ShuaDiaryEntries.title, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiNode.behavior, SduiFlexContext.of, _SduiDocumentViewerState.dispose
//  â³ Called by: SduiDocumentViewer.createState
```

#### _SduiDocumentViewerState._buildErrorState (Function)
```rust
// Lines 494-499 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildErrorState(
//  â³ Called by: _SduiDocumentViewerState
```

#### _SduiDocumentViewerState._buildEmptyReadonly (Function)
```rust
// Lines 461-465 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyReadonly(
//  â³ Called by: _SduiDocumentViewerState
```

#### SduiDocumentViewer.createState (Function)
```rust
// Lines 45-45 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiDocumentViewer> createState()
//  â³ Calls: SduiDocumentViewer, _SduiDocumentViewerState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_html_viewer.dart (562 lines)

#### _SduiHtmlViewerState.initState (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState._buildEmptyReadonly (Function)
```rust
// Lines 484-488 (5 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildEmptyReadonly(
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState.didUpdateWidget (Function)
```rust
// Lines 48-48 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiHtmlViewer oldWidget)
//  â³ Calls: SduiHtmlViewer
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState.dispose (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiHtmlViewerState
```

#### SduiHtmlViewer (Class)
```rust
// Lines 18-30 (13 LOC | Complexity 1) | used by 4 callers
class SduiHtmlViewer extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiHtmlViewerState.didUpdateWidget, _SduiHtmlViewerState, SduiHtmlViewer.createState, SduiTypeRegistry
```

#### _SduiHtmlViewerState.build (Function)
```rust
// Lines 173-173 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiHtmlViewer.createState (Function)
```rust
// Lines 29-29 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiHtmlViewer> createState()
//  â³ Calls: SduiHtmlViewer, _SduiHtmlViewerState
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
//  â³ Calls: SduiHtmlViewer, SduiEventDispatcher.onAction, _SduiHtmlViewerState._buildEmptyReadonly, _SduiHtmlViewerState._buildUploadBox, _SduiHtmlViewerState._buildErrorState, _SduiHtmlViewerState._showPicker, _SduiHtmlViewerState._loadHtmlFile, SduiIconRegistry.contains, SduiStyleResolver.resolveColor, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, SduiEventDispatcher.onStateChange, SduiStateVault.set, MediaUploader.pickAndUploadWithUi, ShuaDiaryEntries.title, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiNode.behavior, SduiFlexContext.of, GovernorLogger.log, ShuaDiaryBlocks.content, _SduiHtmlViewerState.dispose, _SduiHtmlViewerState.didUpdateWidget, SduiNode.contentVal, _SduiHtmlViewerState.initState
//  â³ Called by: SduiHtmlViewer.createState
```

#### _SduiHtmlViewerState._buildUploadBox (Function)
```rust
// Lines 444-449 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildUploadBox(
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState._buildErrorState (Function)
```rust
// Lines 517-522 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildErrorState(
//  â³ Called by: _SduiHtmlViewerState
```

#### _SduiHtmlViewerState._showPicker (Function)
```rust
// Lines 99-99 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context)
//  â³ Called by: _SduiHtmlViewerState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_ordinal_slider.dart (287 lines)

#### _SduiOrdinalSliderState._handleTap (Function)
```rust
// Lines 25-25 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _handleTap(int index, double tapX, double iconSize, bool halfStep, bool isReadOnly)
//  â³ Called by: _SduiOrdinalSliderState
```

#### SduiOrdinalSlider (Class)
```rust
// Lines 7-19 (13 LOC | Complexity 1) | used by 3 callers
class SduiOrdinalSlider extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiOrdinalSliderState, SduiOrdinalSlider.createState, SduiTypeRegistry
```

#### _SduiOrdinalSliderState.build (Function)
```rust
// Lines 80-80 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
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

#### _SduiOrdinalSliderState._iconFor (Function)
```rust
// Lines 43-43 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
IconData _iconFor(String iconName, int index, double activeRating)
//  â³ Called by: _SduiOrdinalSliderState
```

#### _SduiOrdinalSliderState (Class)
```rust
// Lines 21-289 (269 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiOrdinalSliderState extends ConsumerState<SduiOrdinalSlider>
//  â³ Calls: SduiOrdinalSlider, _SduiShimmerLoaderState.borderRadius, _SduiOrdinalSliderState._labelFor, _SduiOrdinalSliderState._handleTap, _SduiOrdinalSliderState._iconFor, _SduiShimmerLoaderState.padding, SduiFlexContext.of, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiEventDispatcher.onAction, SduiNode.behavior, SduiEventDispatcher.onStateChange
//  â³ Called by: SduiOrdinalSlider.createState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\sdui_sandbox_screen.dart (291 lines)

#### _SduiSandboxScreenState.initState (Function)
```rust
// Lines 23-23 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState._parseLegacyV4Format (Function)
```rust
// Lines 69-69 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
SduiNode _parseLegacyV4Format(Map<String, dynamic> map)
//  â³ Calls: SduiNode
//  â³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState._parseIntMap (Function)
```rust
// Lines 83-83 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
dynamic _parseIntMap(dynamic value)
//  â³ Called by: _SduiSandboxScreenState
```

#### SduiSandboxScreen (Class)
```rust
// Lines 8-13 (6 LOC | Complexity 1) | used by 2 callers
class SduiSandboxScreen extends ConsumerStatefulWidget
//  â³ Called by: _SduiSandboxScreenState, SduiSandboxScreen.createState
```

#### _SduiSandboxScreenState._loadBlueprints (Function)
```rust
// Lines 47-47 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<List<MapEntry<String, SduiNode>>> _loadBlueprints()
//  â³ Calls: SduiNode
//  â³ Called by: _SduiSandboxScreenState
```

#### _SduiSandboxScreenState (Class)
```rust
// Lines 15-291 (277 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiSandboxScreenState extends ConsumerState<SduiSandboxScreen>
//  â³ Calls: SduiSandboxScreen, SduiFlexContext.of, SduiTypeRegistry.buildNode, SduiTypeRegistry, _SduiShimmerLoaderState.padding, _SduiSandboxScreenState._buildBody, BoundedRouteHistory.isEmpty, ShuaDiaryEntries.title, ShuaDiaryBlocks.content, _SduiSandboxScreenState._parseIntMap, SduiNode, _SduiSandboxScreenState._parseLegacyV4Format, _SduiSandboxScreenState._loadBlueprints, _SduiSandboxScreenState._loadAll, _SduiSandboxScreenState.initState
//  â³ Called by: SduiSandboxScreen.createState
```

#### SduiSandboxScreen.createState (Function)
```rust
// Lines 12-12 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiSandboxScreen> createState()
//  â³ Calls: SduiSandboxScreen, _SduiSandboxScreenState
```

#### _SduiSandboxScreenState._loadAll (Function)
```rust
// Lines 28-28 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _loadAll()
//  â³ Called by: _SduiSandboxScreenState
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
//  â³ Calls: SduiEventDispatcher
//  â³ Called by: _SduiSandboxScreenState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_text_input.dart (197 lines)

#### _SduiTextInputState._resolveFormatters (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
List<TextInputFormatter> _resolveFormatters(int inputType)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.build (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiTextInputState (Class)
```rust
// Lines 35-201 (167 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiTextInputState extends ConsumerState<SduiTextInput>
//  â³ Calls: SduiTextInput, _SduiTextInputState._onTextChanged, SduiIconRegistry.resolve, SduiIconRegistry, SduiInputType, _SduiTextInputState._resolveFormatters, _SduiTextInputState._resolveKeyboardType, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiFlexContext.of, SduiSocketManager.emitRpc, SduiEventDispatcher.onStateChange, _SduiTextInputState.dispose, _SduiTextInputState.didUpdateWidget, SduiNode.behavior, SduiNode.contentVal, _SduiTextInputState._bindKey, _SduiTextInputState.initState
//  â³ Called by: SduiTextInput.createState
```

#### SduiTextInput (Class)
```rust
// Lines 21-33 (13 LOC | Complexity 1) | used by 4 callers
class SduiTextInput extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiTextInputState.didUpdateWidget, _SduiTextInputState, SduiTextInput.createState, SduiTypeRegistry
```

#### _SduiTextInputState._resolveKeyboardType (Function)
```rust
// Lines 107-107 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
TextInputType _resolveKeyboardType(int inputType)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState._bindKey (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String get _bindKey
//  â³ Calls: SduiNode.behavior
//  â³ Called by: _SduiTextInputState
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

#### _SduiTextInputState._onTextChanged (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onTextChanged(String newText)
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.didUpdateWidget (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void didUpdateWidget(covariant SduiTextInput oldWidget)
//  â³ Calls: SduiTextInput
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.initState (Function)
```rust
// Lines 44-44 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiTextInputState
```

#### _SduiTextInputState.dispose (Function)
```rust
// Lines 87-87 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiTextInputState
```

### C:\horAIzon_2.0\client_flutter\lib\core\network\media_uploader.dart (552 lines)

#### MediaUploadException (Class)
```rust
// Lines 67-74 (8 LOC | Complexity 1) | used by 1 callers
class MediaUploadException implements Exception
//  â³ Called by: MediaUploader
```

#### MediaUploadResult (Class)
```rust
// Lines 31-47 (17 LOC | Complexity 1) | used by 5 callers
class MediaUploadResult
//  â³ Calls: MediaUploader
//  â³ Called by: MediaUploader._chunkedUpload, MediaUploader._simpleUpload, MediaUploader.uploadBytes, MediaUploader.uploadFile, MediaUploader
```

#### MediaUploader._listenToSseProgress (Function)
```rust
// Lines 322-325 (4 LOC | Complexity 1) | used by 1 callers | [Pure]
void _listenToSseProgress(
//  â³ Calls: UploadProgressEvent
//  â³ Called by: MediaUploader
```

#### MediaUploader._simpleUpload (Function)
```rust
// Lines 167-173 (7 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> _simpleUpload(
//  â³ Calls: MediaUploadResult
//  â³ Called by: MediaUploader
```

#### MediaUploader.pickAndUploadWithUi (Function)
```rust
// Lines 438-446 (9 LOC | Complexity 1) | used by 5 callers | [Pure]
Future<void> pickAndUploadWithUi(
//  â³ Calls: SduiEventDispatcher
//  â³ Called by: _SduiHtmlViewerState, _SduiAudioState, SduiImage, _SduiDocumentViewerState, _SduiVideoState
```

#### MediaUploader._chunkedUpload (Function)
```rust
// Lines 211-216 (6 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<MediaUploadResult> _chunkedUpload(
//  â³ Calls: MediaUploadResult
//  â³ Called by: MediaUploader
```

#### MediaUploader.uploadBytes (Function)
```rust
// Lines 140-146 (7 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
Future<MediaUploadResult> uploadBytes(
//  â³ Calls: MediaUploadResult
```

#### UploadProgressEvent (Class)
```rust
// Lines 49-61 (13 LOC | Complexity 1) | used by 2 callers
class UploadProgressEvent
//  â³ Called by: MediaUploader._listenToSseProgress, MediaUploader
```

#### MediaUploader (Class)
```rust
// Lines 99-569 (471 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class MediaUploader
//  â³ Calls: SduiEventDispatcher.onStateChange, SduiStateVault.set, MediaUploader.uploadFile, ShuaDiaryBlocks.content, ShuaDiaryEntries.title, SduiFlexContext.of, MediaUploader._showError, UploadProgressEvent, MediaUploader._listenToSseProgress, MediaUploadException, MediaUploader._deterministicId, MediaUploadResult, MediaUploader._assertStatus, MediaUploader._inferMime, MediaUploader._chunkedUpload, MediaUploader._simpleUpload, GovernorLogger.log
//  â³ Called by: MediaUploadResult
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
//  â³ Calls: MediaUploadResult
//  â³ Called by: MediaUploader
```

#### MediaUploader._showError (Function)
```rust
// Lines 560-560 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showError(BuildContext context, String message)
//  â³ Called by: MediaUploader
```

#### MediaUploader._assertStatus (Function)
```rust
// Lines 382-382 (1 LOC | Complexity 1) | used by 1 callers | [Io]
void _assertStatus(http.Response response)
//  â³ Called by: MediaUploader
```

#### MediaUploader._inferMime (Function)
```rust
// Lines 418-418 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _inferMime(String filename)
//  â³ Called by: MediaUploader
```

#### MediaUploader._deterministicId (Function)
```rust
// Lines 407-407 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _deterministicId(String filename, int size)
//  â³ Called by: MediaUploader
```

### C:\horAIzon_2.0\client_flutter\lib\core\logging\governor_logger.dart (114 lines)

#### GovernorLogger._sendAsync (Function)
```rust
// Lines 118-118 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _sendAsync(Map<int, dynamic> payload)
//  â³ Calls: ShuaSyncQueue.payload
//  â³ Called by: GovernorLogger
```

#### GovernorLogger._uri (Function)
```rust
// Lines 71-71 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Uri get _uri
//  â³ Called by: GovernorLogger
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
//  â³ Called by: _SduiHtmlViewerState, _SduiContainerState, TelemetryProfile, DiagnosticsHistoryNotifier, _SduiAudioState, _SduiScreenState, SduiScreen, SduiGridView, MediaUploader, _SduiJbcPanelState, _SduiTerminalState, ConfigNotifier, ThemeNotifier, SduiHeatmap, SduiListView, SduiSocketManager, SduiModuleCard, SduiNode, SduiEventDispatcher, _SduiVideoState
```

#### GovernorLogger (Class)
```rust
// Lines 54-154 (101 LOC | Complexity 1) | used by 1 callers
class GovernorLogger
//  â³ Calls: GovernorLogger._uri, GovernorLogger._sendAsync, ShuaSyncQueue.payload
//  â³ Called by: GovernorLogger.GovernorLogger
```

#### GovernorLogger.GovernorLogger (Function)
```rust
// Lines 59-59 (1 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
factory GovernorLogger()
//  â³ Calls: GovernorLogger
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_grid_view.dart (101 lines)

#### SduiGridView (Class)
```rust
// Lines 9-106 (98 LOC | Complexity 1) | used by 1 callers
class SduiGridView extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, SduiRenderer, SduiNode.interpolate, _SduiShimmerLoaderState.maxHeight, GovernorLogger.log, SduiNode.contentVal, SduiGridView._num, SduiStyleResolver.resolveEdgeInsets, SduiStyleResolver, _SduiShimmerLoaderState.padding, SduiNode.behavior, SduiGridView._int
//  â³ Called by: SduiTypeRegistry
```

#### SduiGridView._int (Function)
```rust
// Lines 95-95 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int? _int(int key)
//  â³ Called by: SduiGridView
```

#### SduiGridView.build (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiGridView._num (Function)
```rust
// Lines 101-101 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
double? _num(int key)
//  â³ Called by: SduiGridView
```

### C:\horAIzon_2.0\client_flutter\lib\app\adaptive_shell.dart (245 lines)

#### AdaptiveShell._buildStatIcon (Function)
```rust
// Lines 229-229 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildStatIcon(IconData icon, String value, Color color)
//  â³ Called by: AdaptiveShell
```

#### AdaptiveShell._buildMobileStat (Function)
```rust
// Lines 210-210 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildMobileStat(IconData icon, String value, Color color)
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
```

#### AdaptiveShell._getSelectedIndex (Function)
```rust
// Lines 202-202 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
int _getSelectedIndex(BuildContext context)
//  â³ Called by: AdaptiveShell
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
//  â³ Calls: _SduiShimmerLoaderState.padding, SduiModuleCard, SduiDropdown, SduiWrap, SduiExpansionTile, SduiSpacer, SduiDivider, SduiTimePicker, SduiDatePicker, SduiHtmlViewer, SduiCarousel, SduiDocumentViewer, SduiTimeline, SduiGauge, SduiChart, SduiStlViewer, SduiImage, SduiVideo, SduiAudio, SduiDrawingPad, SduiMap, SduiHeatmap, SduiTerminal, SduiToggle, SduiTextInput, SduiTable, SduiShimmerLoader, SduiRadio, SduiProgressBar, SduiSlider, SduiOrdinalSlider, SduiListView, SduiListEditor, SduiGridView, SduiContainer, SduiChip, SduiCheckbox, SduiButton, SduiCodeEditor, SduiMarkdownEditor
//  â³ Called by: _SduiSandboxScreenState, SduiRenderer
```

#### SduiTypeRegistry.buildNode (Function)
```rust
// Lines 94-94 (1 LOC | Complexity 1) | used by 2 callers | [Pure]
static Widget buildNode(SduiNode node, SduiEventDispatcher dispatcher, BuildContext context)
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiSandboxScreenState, SduiRenderer
```

#### SduiTypeRegistry.register (Function)
```rust
// Lines 90-90 (1 LOC | Complexity 1) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
static void register(int typeId, SduiWidgetBuilder builder)
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_toggle.dart (63 lines)

#### SduiToggle.build (Function)
```rust
// Lines 18-18 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context, WidgetRef ref)
```

#### SduiToggle (Class)
```rust
// Lines 7-68 (62 LOC | Complexity 1) | used by 1 callers
class SduiToggle extends ConsumerWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiEventDispatcher.onAction, SduiEventDispatcher.onStateChange, SduiFlexContext.of, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, SduiNode.contentVal
//  â³ Called by: SduiTypeRegistry
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\registry\sdui_icon_registry.dart (126 lines)

#### SduiIconRegistry.resolve (Function)
```rust
// Lines 127-127 (1 LOC | Complexity 1) | used by 8 callers | [Pure]
static IconData resolve(String? name)
//  â³ Called by: _SduiTextInputState, _SduiTimelineState, SduiChip, _SduiListEditorState, SduiButton, _SduiMapState, SduiModuleCard, _SduiExpansionTileState
```

#### SduiIconRegistry (Class)
```rust
// Lines 10-133 (124 LOC | Complexity 1) | used by 8 callers
class SduiIconRegistry
//  â³ Calls: ShuaDiaryEntries.title
//  â³ Called by: _SduiTextInputState, _SduiTimelineState, SduiChip, _SduiListEditorState, SduiButton, _SduiMapState, SduiModuleCard, _SduiExpansionTileState
```

#### SduiIconRegistry.contains (Function)
```rust
// Lines 132-132 (1 LOC | Complexity 1) | used by 7 callers | [Pure, Tested]
static bool contains(String name)
//  â³ Called by: _SduiHtmlViewerState, SduiTimePicker, SduiDatePicker, _SduiListEditorState, SduiSocketManager, SduiEventDispatcher, _SduiDropdownState
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_audio.dart (524 lines)

#### _SduiAudioState._showPicker (Function)
```rust
// Lines 131-131 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _showPicker(BuildContext context, String bindKey)
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState (Class)
```rust
// Lines 27-528 (502 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class _SduiAudioState extends ConsumerState<SduiAudio>
//  â³ Calls: SduiAudio, _SduiAudioState._formatDuration, _SduiAudioState._togglePlayback, _SduiAudioState._showPicker, BoundedRouteHistory.isEmpty, _SduiAudioState._setAudioSource, SduiNode.contentVal, SduiStyleResolver.resolveColor, SduiStyleResolver, SduiNode.behavior, ShuaDiaryBlocks.content, SduiEventDispatcher.onStateChange, SduiStateVault.set, MediaUploader.pickAndUploadWithUi, _SduiAudioState._onSelectFile, ShuaDiaryEntries.title, _SduiShimmerLoaderState.padding, _SduiShimmerLoaderState.borderRadius, SduiFlexContext.of, GovernorLogger.log, _SduiAudioState.dispose, _SduiAudioState.initState
//  â³ Called by: SduiAudio.createState
```

#### SduiAudio (Class)
```rust
// Lines 13-25 (13 LOC | Complexity 1) | used by 3 callers
class SduiAudio extends ConsumerStatefulWidget
//  â³ Calls: SduiEventDispatcher, SduiNode
//  â³ Called by: _SduiAudioState, SduiAudio.createState, SduiTypeRegistry
```

#### _SduiAudioState.initState (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod]
void initState()
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState.build (Function)
```rust
// Lines 221-221 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### _SduiAudioState.dispose (Function)
```rust
// Lines 70-70 (1 LOC | Complexity 1) | used by 1 callers | [Pure, TraitMethod, Tested]
void dispose()
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState._formatDuration (Function)
```rust
// Lines 125-125 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
String _formatDuration(Duration d)
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState._togglePlayback (Function)
```rust
// Lines 116-116 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _togglePlayback()
//  â³ Called by: _SduiAudioState
```

#### _SduiAudioState._setAudioSource (Function)
```rust
// Lines 75-75 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Future<void> _setAudioSource(String path)
//  â³ Called by: _SduiAudioState
```

#### SduiAudio.createState (Function)
```rust
// Lines 24-24 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
ConsumerState<SduiAudio> createState()
//  â³ Calls: SduiAudio, _SduiAudioState
```

#### _SduiAudioState._onSelectFile (Function)
```rust
// Lines 190-190 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
void _onSelectFile(BuildContext context, String bindKey, String filePath)
//  â³ Called by: _SduiAudioState
```

### C:\horAIzon_2.0\client_flutter\lib\app\settings\theme_seeds.dart (20 lines)

#### ThemeSeedOption (Class)
```rust
// Lines 3-8 (6 LOC | Complexity 1) | used by 1 callers
class ThemeSeedOption
//  â³ Called by: AppThemeSeeds
```

#### AppThemeSeeds (Class)
```rust
// Lines 11-24 (14 LOC | Complexity 1) | used by 1 callers
class AppThemeSeeds
//  â³ Calls: ThemeSeedOption
//  â³ Called by: SettingsPage
```

### C:\horAIzon_2.0\client_flutter\lib\sdui\primitives\sdui_stl_viewer.dart (134 lines)

#### SduiStlViewer (Class)
```rust
// Lines 30-161 (132 LOC | Complexity 1) | used by 1 callers
class SduiStlViewer extends StatelessWidget
//  â³ Calls: SduiEventDispatcher, SduiNode, _SduiShimmerLoaderState.padding, SduiStlViewer._buildAxisIndicator, _SduiShimmerLoaderState.borderRadius, SduiNode.contentVal, SduiNode.behavior, SduiFlexContext.of
//  â³ Called by: SduiTypeRegistry
```

#### SduiStlViewer.build (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
Widget build(BuildContext context)
```

#### SduiStlViewer._buildAxisIndicator (Function)
```rust
// Lines 143-143 (1 LOC | Complexity 1) | used by 1 callers | [Pure]
Widget _buildAxisIndicator(String name, Color color)
//  â³ Called by: SduiStlViewer
```


