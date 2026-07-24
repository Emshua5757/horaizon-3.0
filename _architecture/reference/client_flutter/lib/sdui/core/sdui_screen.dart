import 'package:client_flutter/sdui/primitives/sdui_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/core/sdui_transport.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/primitives/sdui_jbc_panel.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

final sduiDataProvider = FutureProvider.autoDispose.family<List<SduiNode>, String>((ref, screenId) async {
  final socketManager = ref.read(sduiSocketProvider);
  ref.onDispose(() {
    gLog.log(HbpLogLevel.DEBUG, 'sdui_screen', 'sduiDataProvider($screenId) has been disposed from Riverpod cache', tags: HbpLogTag.SDUI);
  });
  return await socketManager.getScreen(screenId);
});

class SduiScreen extends ConsumerStatefulWidget {
  final String screenId;
  /// When true, no AppBar is rendered. Used by modal bottom sheets where the
  /// SDUI layout itself provides a close button.
  final bool suppressAppBar;
  final ScrollController? scrollController;

  const SduiScreen({
    super.key,
    required this.screenId,
    this.suppressAppBar = false,
    this.scrollController,
  });

  @override
  ConsumerState<SduiScreen> createState() => _SduiScreenState();
}

class _SduiScreenState extends ConsumerState<SduiScreen> {
  /// Local mutable copy of the node tree.
  /// Starts as null — populated when the FutureProvider resolves.
  /// Updated in-place via applyDelta on patch events.
  List<SduiNode>? _localNodes;

  /// Cancel function returned by listenForPatches — called on dispose.
  VoidCallback? _cancelPatchListener;

  /// Cancel function for the persistent replace_${screenId} listener.
  /// Handles full-tree replacements sent by get_blocks and similar RPCs
  /// that fire after the initial socket.once() completer has already completed.
  VoidCallback? _cancelReplaceListener;

  /// Cancel function for the global hot reload listener.
  VoidCallback? _cancelHotReloadListener;

  /// Cancel function for the socket connection listener.
  VoidCallback? _cancelConnectListener;

  /// Cached provider references to prevent defunct BuildContext lookup during dispose.
  late final SduiEventDispatcher _cachedDispatcher;
  late final SduiStateVault _cachedVaultNotifier;
  late final SduiSocketManager _cachedSocketManager;

  @override
  void initState() {
    super.initState();
    _cachedDispatcher = ref.read(sduiDispatcherProvider);
    _cachedVaultNotifier = ref.read(sduiStateVaultProvider.notifier);
    _cachedSocketManager = ref.read(sduiSocketProvider);

    // Subscribe to patch events for this screen immediately.
    // Patches may arrive before the initial screen load completes (race is safe
    // because applyDelta is a no-op if _localNodes is null).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final socketManager = _cachedSocketManager;
      _cancelPatchListener = socketManager.listenForPatches(
        widget.screenId,
        _onPatchDelta,
      );
      // Also subscribe to full replace events (e.g. from get_blocks).
      // The initial requestScreen uses socket.once() which fires only once.
      // Any subsequent replace_${screenId} emitted by the server (get_blocks,
      // search, delete_entry, etc.) would be silently dropped without this.
      _cancelReplaceListener = socketManager.listenForReplace(
        widget.screenId,
        _onFullReplace,
      );

      // Listen for hot-reloads of blueprints/blocks
      _cancelHotReloadListener = socketManager.listenForHotReload((pattern) {
        if (!mounted) return;
        if (widget.screenId == 'dashboard') return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          // Skip if this screen is not the active route on the stack
          return;
        }

        bool matches = false;
        if (pattern == '*') {
          matches = true;
        } else if (pattern.endsWith('*')) {
          final prefix = pattern.substring(0, pattern.length - 1);
          matches = widget.screenId.startsWith(prefix);
        } else {
          matches = widget.screenId == pattern;
        }

        if (matches) {
          gLog.log(HbpLogLevel.INFO, 'sdui_screen', 'Hot reload triggered for screen ${widget.screenId} by pattern: $pattern', tags: HbpLogTag.SDUI | HbpLogTag.LIFECYCLE);
          socketManager.reRequestScreen(widget.screenId);
        }
      });

      // Automatically re-request layout when the socket connects or reconnects (e.g. after server restart)
      _cancelConnectListener = socketManager.listenForConnect(() {
        if (!mounted) return;
        if (widget.screenId == 'dashboard' || widget.screenId == 'console') return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        gLog.log(HbpLogLevel.INFO, 'sdui_screen', 'Connection restored. Re-requesting layout for: ${widget.screenId}', tags: HbpLogTag.SDUI | HbpLogTag.NETWORK);
        socketManager.reRequestScreen(widget.screenId);
      }, screenId: widget.screenId);

    });
  }

  @override
  void dispose() {
    _cancelPatchListener?.call();
    _cancelReplaceListener?.call();
    _cancelHotReloadListener?.call();
    _cancelConnectListener?.call();

    final dispatcher = _cachedDispatcher;
    final vaultNotifier = _cachedVaultNotifier;
    final socketManager = _cachedSocketManager;
    final screenId = widget.screenId;

    // Defer state mutations to the next microtask to prevent 
    // synchronously triggering rebuilds on defunct widgets.
    Future.microtask(() {
      dispatcher.flushPending();
      vaultNotifier.releaseScope(screenId);
      socketManager.evictCache(screenId);
    });

    super.dispose();
  }

  void _onPatchDelta(dynamic rawDelta) {
    if (_localNodes == null || !mounted) return;
    gLog.log(HbpLogLevel.DEBUG, 'sdui_screen', '_onPatchDelta received for screen: ${widget.screenId}', tags: HbpLogTag.SDUI);
    final updated = SduiTransport.applyDelta(_localNodes!, rawDelta);
    setState(() => _localNodes = updated);
  }

  void _onFullReplace(List<SduiNode> nodes) {
    if (!mounted) return;
    gLog.log(HbpLogLevel.DEBUG, 'sdui_screen', '_onFullReplace received for screen: ${widget.screenId} with ${nodes.length} nodes', tags: HbpLogTag.SDUI);
    setState(() => _localNodes = nodes);
  }

  String _resolveTitle() {
    if (widget.screenId == 'dashboard') return 'horAIzon Dashboard';
    if (widget.screenId == 'diary_list') return 'My Journals';
    if (widget.screenId == 'diary_ai_config') return 'AI Configuration';
    if (widget.screenId.startsWith('diary_editor_')) {
      final nodes = _localNodes;
      if (nodes != null && nodes.isNotEmpty) {
        final titleNode = _findNodeByIdSuffix(nodes, ':title');
        if (titleNode != null) {
          final val = titleNode.contentVal<String>(0);
          if (val != null && val.isNotEmpty) {
            return val;
          }
        }
      }
      return 'Edit Entry';
    }
    return widget.screenId;
  }

  SduiNode? _findNodeByIdSuffix(List<SduiNode> nodes, String suffix) {
    for (final node in nodes) {
      if (node.id.endsWith(suffix)) return node;
      if (node.children != null) {
        final found = _findNodeByIdSuffix(node.children!, suffix);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenData = ref.watch(sduiDataProvider(widget.screenId));
    final dispatcher = ref.watch(sduiDispatcherProvider);

    // Listen for layout changes in the provider (e.g. cache invalidation/refetch)
    ref.listen<AsyncValue<List<SduiNode>>>(sduiDataProvider(widget.screenId), (previous, next) {
      next.whenData((nodes) {
        gLog.log(HbpLogLevel.INFO, 'sdui_screen', 'sduiDataProvider(${widget.screenId}) resolved new nodes', tags: HbpLogTag.SDUI);
        if (mounted) {
          setState(() => _localNodes = nodes);
        }
      });
    });

    // Populate _localNodes synchronously if the provider has already resolved
    if (_localNodes == null && screenData.hasValue) {
      _localNodes = screenData.value;
    }

    return Scaffold(
      appBar: widget.suppressAppBar
          ? null
          : AppBar(
              title: Text(_resolveTitle()),
              centerTitle: true,
            ),
      endDrawer: widget.screenId.startsWith('diary_editor_')
          ? SduiJbcPanel(
              entryId: widget.screenId.replaceFirst('diary_editor_', ''),
              screenId: widget.screenId,
              localNodes: _localNodes ?? [],
            )
          : null,
      body: _buildBody(context, screenData, dispatcher),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<SduiNode>> screenData,
    SduiEventDispatcher dispatcher,
  ) {
    // If we have local nodes (either from initial load or patched),
    // render from _localNodes. This keeps patch animations smooth —
    // the FutureProvider's cache is stale but _localNodes is live.
    final nodes = _localNodes;
    if (nodes != null) {
      return _buildNodeList(nodes, dispatcher, context);
    }

    // Fallback: render from the FutureProvider state
    return screenData.when(
      data: (n) => _buildNodeList(n, dispatcher, context),
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SduiShimmerLoader(
            node: const SduiNode(
              id: 'loader', typeId: 14,
              behaviors: {91: 4, 37: 120.0}, content: {},
            ),
            dispatcher: dispatcher,
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load layout',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Escape hatch: always lets the user out of a broken screen
                if (Navigator.of(context).canPop())
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                if (Navigator.of(context).canPop())
                  const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _localNodes = null);
                    ref.invalidate(sduiDataProvider(widget.screenId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeList(
    List<SduiNode> nodes,
    SduiEventDispatcher dispatcher,
    BuildContext context,
  ) {
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: nodes.map((node) {
        return SliverToBoxAdapter(
          key: ValueKey('${node.id}_sliver'),
          child: SduiRenderer(
            key: ValueKey(node.id),
            node: node,
            dispatcher: dispatcher,
          ),
        );
      }).toList(),
    );
  }
}
