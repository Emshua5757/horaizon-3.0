import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart';
import 'package:client_flutter/app/router.dart';
import 'package:client_flutter/app/route_history.dart';
import 'package:client_flutter/sdui/core/sdui_screen.dart';
import 'package:http/http.dart' as http;
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:client_flutter/app/settings/config_provider.dart';

enum SduiActionType {
  navigate,
  stateSync,
  submitForm,
  aiCommand,
  dismiss,
}

/// Dispatches actions directly to the local Sync Queue or Network layer.
///
/// Debounce contract:
///  - Text content changes (`onStateChange`) → debounced 500ms per node.
///    Vault is always updated immediately; network write is deferred.
///  - Action payloads (`onAction`) → fired immediately, no debounce.
///    These are discrete user events (button taps, drag-end), not streams.
class SduiEventDispatcher {
  final Ref ref;

  /// Per-node-id debounce timers.
  /// Each node that is being typed in gets its own independent 500ms clock.
  /// Typing in block A doesn't reset block B's timer.
  final Map<String, Timer> _debounceTimers = {};

  /// Debounce window for text content writes.
  static const _kDebounceMs = 500;

  SduiEventDispatcher(this.ref);

  /// Helper to resolve screen ID from GoRouter location path.
  String? _resolveScreenIdFromLocation(String location) {
    if (location == '/dashboard') {
      return 'dashboard';
    } else if (location == '/comms') {
      return 'chat_playground';
    } else if (location == '/diary') {
      return 'diary_list';
    } else if (location.startsWith('/diary/')) {
      final id = location.substring('/diary/'.length);
      return 'diary_editor_$id';
    } else if (location == '/resume') {
      return 'resume_dashboard';
    } else if (location.startsWith('/resume/forge')) {
      return 'resume_forge';
    }
    return null;
  }

  /// Called by any primitive widget (MarkdownEditor, TextInput, ListEditor, etc.)
  /// every time its internal value changes.
  ///
  /// Phase 1: Write to vault immediately → UI stays snappy, no frame drops.
  /// Phase 2: Cancel any pending sync for this node (reset the 500ms clock).
  /// Phase 3: Schedule a new sync at 500ms → if no new call in 500ms, fires.
  void onStateChange(String nodeId, dynamic value) {
    // Phase 1 — always immediate, no debounce
    ref.read(sduiStateVaultProvider.notifier).set(nodeId, value);

    // Phase 2 — cancel pending sync for this specific node
    _debounceTimers[nodeId]?.cancel();

    // Phase 3 — schedule new sync
    _debounceTimers[nodeId] = Timer(
      const Duration(milliseconds: _kDebounceMs),
      () {
        _debounceTimers.remove(nodeId);
        _syncToServer(nodeId, value);
      },
    );
  }

  void onAction(Map<int, dynamic> payload, [BuildContext? context]) {
    final actionId = payload[0] as int?;
    if (actionId == null) return;

    switch (actionId) {
      case 1: // RPC action — fire socket emit
        final rawParams = payload[4] as Map? ?? {};
        if (rawParams['panel'] == 'chat') {
          if (context != null) {
            Scaffold.of(context).openEndDrawer();
          }
        } else {
          _fireRpc(payload);
        }
        break;
      case 2: // NAVIGATE or HTTP ACTION
        final url = payload[3] as String?;
        if (url != null) {
          if (url.startsWith('/sdui_modal/')) {
            final activeContext = context ?? rootNavigatorKey.currentContext;
            if (activeContext != null) {
              final screenId = url.substring('/sdui_modal/'.length);
              showSduiModalSheet(activeContext, screenId);
            } else {
              ref.read(routerProvider).push(url);
            }
          } else if (url.startsWith('/api/governor/control/')) {
            // Fire HTTP POST action to Governor control endpoint and dismiss modal
            final syncBase = ref.read(systemConfigProvider).syncBaseUrl;
            final fullUrl = '$syncBase$url';
            http.post(Uri.parse(fullUrl)).catchError((e) {
              gLog.log(HbpLogLevel.ERROR, 'sdui_events', 'Control POST failed: $e', tags: HbpLogTag.SDUI | HbpLogTag.NETWORK);
              return http.Response('', 500);
            });
            final router = ref.read(routerProvider);
            if (router.canPop()) {
              router.pop();
            }
          } else {
            ref.read(routerProvider).go(url);
          }
        }
        break;

      case 3: // DISMISS — pop the current route (works for GoRouter & modal sheets)
        final router = ref.read(routerProvider);
        if (router.canPop()) {
          router.pop();
        } else if (context != null && context.mounted) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
        break;
      case 7: // REFRESH
        final history = ref.read(routeHistoryProvider);
        final location = history.currentLocation ?? '';
        final screenId = _resolveScreenIdFromLocation(location);
        if (screenId != null) {
          ref.invalidate(sduiDataProvider(screenId));
        }
        break;
      case 5: // LAUNCH_URL
        String? url = payload[3] as String?;
        if (url != null && url.isNotEmpty) {
          if (url.startsWith('/')) {
            final baseUrl = ref.read(systemConfigProvider).syncBaseUrl;
            url = '$baseUrl$url';
          }
          final uri = Uri.tryParse(url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) {
              gLog.log(HbpLogLevel.ERROR, 'sdui_events', 'Launch URL failed: $e', tags: HbpLogTag.SDUI);
              return false;
            });
          }
        }
        break;
      case 8: // COPY_TO_CLIPBOARD
        String? text = payload[3] as String?;
        if (text != null && text.isNotEmpty) {
          if (text.startsWith('/')) {
            final baseUrl = ref.read(systemConfigProvider).syncBaseUrl;
            text = '$baseUrl$text';
          }
          final copiedText = text;
          Clipboard.setData(ClipboardData(text: copiedText)).then((_) {
            final activeContext = context ?? rootNavigatorKey.currentContext;
            if (activeContext != null && activeContext.mounted) {
              ScaffoldMessenger.of(activeContext).showSnackBar(
                SnackBar(
                  content: Text('Copied link: $copiedText'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
        break;
      case 10: // STATE_SYNC (legacy)
        gLog.log(HbpLogLevel.WARN, 'sdui_events', 'Deprecated STATE_SYNC action: $payload', tags: HbpLogTag.SDUI);
        break;
      case 11: // SUBMIT_FORM
        _handleSubmitForm(payload);
        break;
      case 12: // AI_COMMAND (HbpActionType.AI_COMMAND)
        _handleAiCommand(payload);
        break;
      case 18: // LOCAL_DELETE (Custom action for local node eviction)
        final targetNodeId = payload[2] as String?;
        if (targetNodeId != null) {
          final history = ref.read(routeHistoryProvider);
          final location = history.currentLocation ?? '';
          final screenId = _resolveScreenIdFromLocation(location);
          if (screenId != null) {
            ref.read(sduiSocketProvider).injectLocalDelta(screenId, {
              'op': 'remove',
              'node_id': targetNodeId,
            });
          }
        }
        break;
      default:
        gLog.log(HbpLogLevel.WARN, 'sdui_events', 'Unknown action type: $actionId in $payload', tags: HbpLogTag.SDUI);
    }
  }

  /// POST /api/ai/infer
  ///
  /// Requests streamed inference from the Governor with real-time NDJSON buffering and local
  /// state vault updates. Handles failover warning chip injection and tap-to-dismiss behavior.
  Future<void> _handleAiCommand(Map<int, dynamic> payload) async {
    final targetId = payload[2] as String?;
    if (targetId == null) return;

    final args = payload[4] as Map?;
    final inputNodeId = args?['input_node_id'] as String?;
    final prompt = inputNodeId != null
        ? ref.read(sduiStateVaultProvider)[inputNodeId]?.toString() ?? ''
        : args?['prompt']?.toString() ?? '';

    if (prompt.trim().isEmpty) return;

    final history = ref.read(routeHistoryProvider);
    final location = history.currentLocation ?? '';
    final screenId = _resolveScreenIdFromLocation(location);
    if (screenId == null) return;

    final syncBase = ref.read(systemConfigProvider).syncBaseUrl;
    final client = http.Client();

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$syncBase/api/ai/infer'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': 'horaizon-diary',
        'prompt': prompt,
      });

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 15));

      if (streamedResponse.statusCode != 200) {
        throw http.ClientException('HTTP ${streamedResponse.statusCode}');
      }

      var accumulatedText = '';
      var buffer = '';

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.isNotEmpty) {
            try {
              final decoded = jsonDecode(line) as Map<String, dynamic>;
              final token = decoded['response'] as String?;
              if (token != null) {
                accumulatedText += token;
                ref.read(sduiStateVaultProvider.notifier).set(targetId, accumulatedText);
              }
            } catch (e) {
              gLog.log(
                HbpLogLevel.WARN,
                'sdui_ai',
                'Failed to parse NDJSON line: $e',
                tags: HbpLogTag.SDUI | HbpLogTag.AI,
              );
            }
          }
        }
      }
    } catch (e) {
      gLog.log(
        HbpLogLevel.ERROR,
        'sdui_ai',
        'AI inference failed: $e',
        tags: HbpLogTag.SDUI | HbpLogTag.AI,
      );

      // Inject local warning chip after the toolbar
      final errorChipId = '$screenId:ai_error_chip';
      ref.read(sduiSocketProvider).injectLocalDelta(screenId, {
        'op': 'insert',
        'after_id': '$screenId:toolbar',
        'node': {
          '0': 5, // Chip (HbpWidget.CHIP)
          '1': errorChipId,
          '4': {
            '1': 'AI unreachable. Tap to dismiss.',
            '3': 'warning',
          },
          '3': {
            '113': 2, // DELETABLE mode
            '70': {
              '0': 18, // LOCAL_DELETE
              '2': errorChipId,
            }
          }
        }
      });
    } finally {
      client.close();
    }
  }


  /// Called by [SduiContainer] when a drag-reorder gesture completes.
  ///
  /// Flutter has already performed the optimistic UI reorder (the node list
  /// is mutated in-place inside StatefulBuilder). This method persists the
  /// new position to the server by sending neighbor block IDs — the server
  /// computes the new lexo_rank. Flutter has zero knowledge of lexo_rank.
  ///
  /// @param rpcMethodId  RPC method ID from behavior key 87 (default 110 = reorder_block)
  /// @param movedBlockId Block that was moved
  /// @param beforeBlockId Block that now sits above the moved block (null = moved to top)
  /// @param afterBlockId  Block that now sits below the moved block (null = moved to bottom)
  void onReorder(
    int rpcMethodId,
    String movedBlockId,
    String? beforeBlockId,
    String? afterBlockId,
  ) {
    final methodName = _resolveRpcMethodName(rpcMethodId);
    if (methodName == null) {
      gLog.log(
        HbpLogLevel.WARN,
        'SDUI_REORDER',
        'Unknown RPC method ID: $rpcMethodId',
        tags: HbpLogTag.SDUI,
      );
      return;
    }
    ref.read(sduiSocketProvider).emitRpc(methodName, {
      'block_id': movedBlockId,
      'before_block_id': beforeBlockId,
      'after_block_id': afterBlockId,
    });
    gLog.log(
      HbpLogLevel.INFO,
      'SDUI_REORDER',
      'RPC $methodName → block=$movedBlockId before=$beforeBlockId after=$afterBlockId',
      tags: HbpLogTag.SDUI,
      telemetry: {
        'rpc_method': methodName,
        'block_id': movedBlockId,
        'before_block_id': beforeBlockId,
        'after_block_id': afterBlockId,
      },
    );
  }

  /// Flush all pending debounce timers immediately.
  /// Call this when the user navigates away from the editor
  /// to ensure in-flight content is persisted before the screen is torn down.
  void flushPending() {
    final pending = Map<String, Timer>.from(_debounceTimers);
    for (final entry in pending.entries) {
      entry.value.cancel();
      final currentValue = ref.read(sduiStateVaultProvider.notifier).get(entry.key);
      if (currentValue != null) {
        _syncToServer(entry.key, currentValue);
      }
    }
    _debounceTimers.clear();
  }

  /// Cancel all pending timers without flushing.
  /// Call on dispose when you intentionally discard changes (e.g., "discard edits").
  void cancelPending() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Zero-maintenance O(1) RPC method name resolver.
  /// Reads directly from the generated HbpRpcMethod.names map in
  /// hbp_constants.g.dart. Adding a new module or method requires only
  /// updating communication_contracts.json and re-running sync_contracts.py —
  /// no changes needed here.
  String? _resolveRpcMethodName(int methodId) => HbpRpcMethod.names[methodId];


  /// Fires the debounced content save RPC to Node.js.
  /// Node.js receives exactly ONE write per typing pause — never per-keystroke.
  void _syncToServer(String nodeId, dynamic value) {
    if (nodeId.endsWith(':title')) {
      final parts = nodeId.split(':');
      final entrySegment = parts[0];
      final entryId = entrySegment.replaceFirst('diary_editor_', '');

      ref.read(sduiSocketProvider).emitRpc('shua.diary.save_title', {
        'entry_id': entryId,
        'title': value.toString(),
      });
      return;
    }

    // nodeId format: "diary_editor_{entryId}:block_{blockId}:content"
    final parts = nodeId.split(':');
    final blockSegment = parts.firstWhere(
      (p) => p.startsWith('block_'),
      orElse: () => '',
    );
    if (blockSegment.isEmpty) return;
    final blockId = blockSegment.replaceFirst('block_', '');

    ref.read(sduiSocketProvider).emitRpc('shua.diary.save_block', {
      'block_id': blockId,
      'content': value.toString(),
    });
  }

  /// Fire an RPC action immediately.
  void _fireRpc(Map<int, dynamic> payload) {
    final methodId = payload[1] as int?;
    if (methodId == null) return;

    final methodName = _resolveRpcMethodName(methodId);
    if (methodName == null) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_events', 'Failed to resolve RPC method ID: $methodId', tags: HbpLogTag.SDUI);
      return;
    }

    final rawParams = payload[4] as Map? ?? {};
    final Map<String, dynamic> params = {};
    rawParams.forEach((k, v) {
      params[k.toString()] = v;
    });

    gLog.log(HbpLogLevel.DEBUG, 'sdui_events', 'RPC action → method=$methodName params=$params', tags: HbpLogTag.SDUI);
    ref.read(sduiSocketProvider).emitRpc(methodName, params);
  }

  /// Gather vault values for bind_keys and send via RPC.
  ///
  /// Supports two modes:
  ///  1. `bind_keys: [String]` in action params — reads ONLY those specific vault keys.
  ///     Used by targeted forms (search bar, AI prompt input).
  ///  2. No bind_keys — reads entire vault excluding keys containing ':'.
  ///     Used by full-form screens (AI config settings page).
  void _handleSubmitForm(Map<int, dynamic> payload) {
    final methodId = payload[1] as int?;
    if (methodId == null) return;

    final methodName = _resolveRpcMethodName(methodId);
    if (methodName == null) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_events', 'Failed to resolve form submit RPC method ID: $methodId', tags: HbpLogTag.SDUI);
      return;
    }

    final vault = ref.read(sduiStateVaultProvider);
    final rawParams = payload[4] as Map? ?? {};

    // Check for bind_keys: if present, read only those specific vault keys
    final rawBindKeys = rawParams[int.tryParse('bind_keys') ?? 'bind_keys'];
    final bindKeys = rawBindKeys is List
        ? rawBindKeys.cast<String>()
        : null;

    final Map<String, dynamic> params = {};

    // Copy static params from action payload (e.g. user_id, style)
    rawParams.forEach((k, v) {
      final key = k.toString();
      if (key != 'bind_keys') params[key] = v;
    });

    if (bindKeys != null) {
      // Targeted mode: read only the specified bind_keys from vault
      for (final key in bindKeys) {
        params[key] = vault[key];
      }
    } else {
      // Full vault mode: read all non-namespaced keys
      vault.forEach((k, v) {
        if (!k.contains(':')) params[k] = v;
      });
    }

    gLog.log(HbpLogLevel.DEBUG, 'sdui_events', 'SUBMIT_FORM → method=$methodName params=$params', tags: HbpLogTag.SDUI);
    ref.read(sduiSocketProvider).emitRpc(methodName, params);
  }
}

final sduiDispatcherProvider = Provider<SduiEventDispatcher>((ref) {
  return SduiEventDispatcher(ref);
});
