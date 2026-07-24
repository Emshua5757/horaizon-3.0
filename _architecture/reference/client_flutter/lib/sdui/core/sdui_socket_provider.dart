import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/services.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:http/http.dart' as http;
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_transport.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/app/settings/config_provider.dart';

const String kGovernorBaseUrl = 'http://100.67.11.0:3000';

class SduiSocketManager {
  final Ref ref;

  /// Per-module socket connections. Keyed by moduleId (e.g. 'shua_diary',
  /// 'shua_resume'). Each module maintains an independent Socket.io session
  /// so that a reconnect to one module never clobbers another.
  final Map<String, io.Socket> _sockets = {};

  /// In-memory cache of the latest screen layouts.
  final Map<String, List<SduiNode>> _screenCache = {};

  /// Registered socket event names per moduleId — ensures exactly one
  /// listener per (module, screen) pair.
  final Map<String, Set<String>> _registeredEvents = {};

  /// Active subscribers for full screen replace events.
  final Map<String, void Function(List<SduiNode>)> _replaceSubscribers = {};

  /// Active subscribers for delta patch events.
  final Map<String, void Function(dynamic)> _patchSubscribers = {};

  /// Per-module connect-callback registrations. Stored so we can cancel them.
  final Map<String, List<Function(dynamic)>> _connectHandlers = {};

  SduiSocketManager(this.ref);

  // ── Module resolution ─────────────────────────────────────────────────────

  /// Derives the moduleId from the screenId using zero-maintenance O(1) prefix
  /// extraction. Convention: `<module_prefix>_<screen_name>` maps to
  /// `shua_<module_prefix>`. E.g. `resume_dashboard` → `shua_resume`.
  ///
  /// Special cases:
  ///   - `diary_*`  → `shua_diary`  (existing module)
  ///   - `console`  → served directly from Governor, no WebSocket module
  ///   - `dashboard`→ served directly from Governor, no WebSocket module
  String _moduleIdForScreen(String screenId) {
    // Extract the first underscore-delimited segment
    final underscore = screenId.indexOf('_');
    final prefix = underscore > 0 ? screenId.substring(0, underscore) : screenId;
    return 'shua_$prefix';
  }

  // ── Socket lifecycle ──────────────────────────────────────────────────────

  /// Returns the active socket for the given moduleId, creating and connecting
  /// it if it does not yet exist. All module sockets are long-lived — they are
  /// only torn down when the app is disposed.
  io.Socket _socketFor(String moduleId) {
    if (_sockets.containsKey(moduleId)) {
      return _sockets[moduleId]!;
    }

    final targetBase = ref.read(systemConfigProvider).syncBaseUrl;
    final socketPath = '/ws/$moduleId';

    gLog.log(
      HbpLogLevel.INFO,
      'sdui_socket',
      'Connecting via Governor gateway: $targetBase (path: $socketPath)',
      tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
    );

    final socket = io.io(
      targetBase,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(socketPath)
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      gLog.log(
        HbpLogLevel.INFO,
        'sdui_socket',
        'Connected through Governor WS proxy → $moduleId',
        tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
      );
      // Notify all per-module connect handlers (e.g. screens re-requesting layout)
      for (final handler in List.of(_connectHandlers[moduleId] ?? [])) {
        handler(null);
      }
    });

    socket.onDisconnect((_) {
      gLog.log(
        HbpLogLevel.INFO,
        'sdui_socket',
        'Disconnected from Governor WS proxy ($moduleId)',
        tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
      );
      // Clear only events registered to THIS module's socket
      final events = _registeredEvents[moduleId] ?? {};
      for (final screenId in events) {
        socket.off('replace_$screenId');
        socket.off('patch_$screenId');
        // Evict cache for screens of this module so they re-fetch on reconnect
        _screenCache.remove(screenId);
      }
      _registeredEvents[moduleId]?.clear();
    });

    _sockets[moduleId] = socket;
    _registeredEvents[moduleId] = {};
    _connectHandlers[moduleId] = [];

    socket.connect();
    return socket;
  }

  bool _isStaticScreen(String screenId) {
    return screenId == 'dashboard' || screenId == 'console' || screenId.startsWith('preactivation_');
  }

  /// Convenience: connect through the gateway for a given screenId.
  void connectViaGateway(String screenId) {
    if (_isStaticScreen(screenId)) return;
    final moduleId = _moduleIdForScreen(screenId);
    _socketFor(moduleId); // ensures socket is created + connected
  }

  /// Returns the live Socket.io instance responsible for the given screenId.
  /// Returns null for static screens (dashboard, console, preactivation) that don't use WebSocket.
  /// External call sites (e.g. JBC panel) should use this instead of .socket.
  io.Socket? socketForScreen(String screenId) {
    if (_isStaticScreen(screenId)) return null;
    final moduleId = _moduleIdForScreen(screenId);
    return _sockets[moduleId];
  }

  void connect() => connectViaGateway('diary_list');

  void disconnect() {
    for (final socket in _sockets.values) {
      socket.disconnect();
    }
  }

  // ── Screen loading ────────────────────────────────────────────────────────

  Future<List<SduiNode>> requestScreen(String screenId) async {
    if (screenId == 'dashboard') {
      try {
        final res = await http
            .get(
              Uri.parse('$kGovernorBaseUrl/api/dashboard'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final nodes = SduiTransport.decodeJson(res.body);
          _screenCache[screenId] = nodes;
          return nodes;
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.WARN,
          'sdui_socket',
          'Failed to load live dashboard from Governor, falling back to local asset: $e',
          tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
        );
        try {
          final jsonStr = await rootBundle.loadString(
            'assets/mock_sdui/dashboard.json',
          );
          return SduiTransport.decodeJson(jsonStr);
        } catch (_) {}
      }
    }

    if (screenId == 'console') {
      try {
        final res = await http
            .get(
              Uri.parse('$kGovernorBaseUrl/api/console'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final nodes = SduiTransport.decodeJson(res.body);
          _screenCache[screenId] = nodes;
          return nodes;
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.WARN,
          'sdui_socket',
          'Failed to load live console from Governor, falling back to local asset: $e',
          tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
        );
        try {
          final jsonStr = await rootBundle.loadString(
            'assets/mock_sdui/v4_terminal.json',
          );
          return SduiTransport.decodeJson(jsonStr);
        } catch (_) {}
      }
    }

    if (screenId.startsWith('preactivation_')) {
      final moduleId = screenId.replaceFirst('preactivation_', '');
      try {
        final res = await http
            .get(
              Uri.parse(
                '$kGovernorBaseUrl/api/governor/preactivation/$moduleId',
              ),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final nodes = SduiTransport.decodeJson(res.body);
          _screenCache[screenId] = nodes;
          return nodes;
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.WARN,
          'sdui_socket',
          'Failed to load preactivation sheet for $moduleId: $e',
          tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
        );
      }
    }

    // --- Module-backed screen: resolve socket for the owning module ---
    final moduleId = _moduleIdForScreen(screenId);
    final socket = _socketFor(moduleId);
    _ensureSocketListeners(moduleId, screenId);

    final completer = Completer<List<SduiNode>>();

    socket.once('replace_$screenId', (data) {
      gLog.log(
        HbpLogLevel.DEBUG,
        'sdui_socket',
        'requestScreen: once(replace_$screenId) triggered',
        tags: HbpLogTag.SDUI,
      );
      try {
        final Uint8List bytes = data is Uint8List
            ? data
            : Uint8List.fromList(List<int>.from(data as List));
        final nodes = SduiTransport.decode(bytes);
        _screenCache[screenId] = nodes;
        _ensureSocketListeners(moduleId, screenId);
        completer.complete(nodes);
      } catch (e) {
        completer.completeError('Failed to decode replace payload: $e');
      }
    });

    // Extract scoped variables from StateVault
    final vault = ref.read(sduiStateVaultProvider);
    final Map<String, dynamic> screenParams = {};
    vault.forEach((k, v) {
      if (k.startsWith('$screenId:')) {
        final keyWithoutPrefix = k.substring(screenId.length + 1);
        screenParams[keyWithoutPrefix] = v;
      }
    });

    void emitRpc() {
      gLog.log(
        HbpLogLevel.DEBUG,
        'sdui_socket',
        'Emitting request_screen RPC for $screenId',
        tags: HbpLogTag.SDUI,
      );
      socket.emit('rpc', {
        'method': 'request_screen',
        'params': {'screenId': screenId, ...screenParams},
      });
    }

    if (socket.connected) {
      emitRpc();
    } else {
      socket.once('connect', (_) => emitRpc());
    }

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        throw Exception('WebSocket replace payload timeout');
      },
    );
  }

  /// Retrieves screen layout nodes. Checks the in-memory socket cache first.
  /// If not cached, triggers requestScreen to fetch it over the network.
  Future<List<SduiNode>> getScreen(String screenId) async {
    if (screenId != 'dashboard' && _screenCache.containsKey(screenId)) {
      gLog.log(
        HbpLogLevel.DEBUG,
        'sdui_cache',
        'getScreen($screenId) - Cache Hit. Cache keys: ${_screenCache.keys.toList()}',
        tags: HbpLogTag.SDUI,
      );
      return _screenCache[screenId]!;
    }
    gLog.log(
      HbpLogLevel.DEBUG,
      'sdui_cache',
      'getScreen($screenId) - Cache Miss. Cache keys: ${_screenCache.keys.toList()}',
      tags: HbpLogTag.SDUI,
    );
    return await requestScreen(screenId);
  }

  // ── Event subscriptions ───────────────────────────────────────────────────

  /// Subscribe to replace_${screenId} full-tree replacement events.
  /// Returns a cancel function — call it from dispose() to unsubscribe.
  VoidCallback listenForReplace(
    String screenId,
    void Function(List<SduiNode> nodes) onReplace,
  ) {
    gLog.log(
      HbpLogLevel.INFO,
      'sdui_socket',
      'listenForReplace subscribed for: $screenId',
      tags: HbpLogTag.SDUI,
    );
    if (!_isStaticScreen(screenId)) {
      final moduleId = _moduleIdForScreen(screenId);
      _ensureSocketListeners(moduleId, screenId);
    }
    _replaceSubscribers[screenId] = onReplace;
    return () {
      gLog.log(
        HbpLogLevel.INFO,
        'sdui_socket',
        'listenForReplace unsubscribed for: $screenId',
        tags: HbpLogTag.SDUI,
      );
      _replaceSubscribers.remove(screenId);
    };
  }

  /// Subscribe to patch_${screenId} delta events.
  /// Returns a cancel function — call it from dispose() to unsubscribe.
  VoidCallback listenForPatches(
    String screenId,
    void Function(dynamic delta) onDelta,
  ) {
    gLog.log(
      HbpLogLevel.INFO,
      'sdui_socket',
      'listenForPatches subscribed for: $screenId',
      tags: HbpLogTag.SDUI,
    );
    if (!_isStaticScreen(screenId)) {
      final moduleId = _moduleIdForScreen(screenId);
      _ensureSocketListeners(moduleId, screenId);
    }
    _patchSubscribers[screenId] = onDelta;
    return () {
      gLog.log(
        HbpLogLevel.INFO,
        'sdui_socket',
        'listenForPatches unsubscribed for: $screenId',
        tags: HbpLogTag.SDUI,
      );
      _patchSubscribers.remove(screenId);
    };
  }

  /// Listen to global hot reload events from the server (module-scoped).
  VoidCallback listenForHotReload(
    void Function(String screenIdPattern) onHotReload,
  ) {
    final handlers = <VoidCallback>[];

    for (final entry in _sockets.entries) {
      final socket = entry.value;
      void handler(dynamic data) {
        try {
          final Uint8List bytes = data is Uint8List
              ? data
              : Uint8List.fromList(List<int>.from(data as List));
          final Map decoded = deserialize(bytes) as Map;
          final String pattern = decoded['screenIdPattern'] as String;
          onHotReload(pattern);
        } catch (e) {
          gLog.log(
            HbpLogLevel.ERROR,
            'sdui_socket',
            'Failed to decode hot_reload payload: $e',
            tags: HbpLogTag.SDUI,
          );
        }
      }
      socket.on('hot_reload', handler);
      handlers.add(() => socket.off('hot_reload', handler));
    }

    return () {
      for (final cancel in handlers) {
        cancel();
      }
    };
  }

  /// Listen to connection events scoped to the specific module that owns [screenId].
  /// Only fires when that module's socket connects — not when any other module connects.
  /// Used by [SduiScreen] to re-request layout on reconnect without cross-module interference.
  VoidCallback listenForConnect(VoidCallback onConnect, {required String screenId}) {
    if (_isStaticScreen(screenId)) return () {};

    final moduleId = _moduleIdForScreen(screenId);
    // Ensure the socket exists — _socketFor is idempotent.
    final socket = _socketFor(moduleId);

    void handler(dynamic _) => onConnect();

    socket.on('connect', handler);
    _connectHandlers[moduleId] ??= [];
    _connectHandlers[moduleId]!.add(handler);

    return () {
      socket.off('connect', handler);
      _connectHandlers[moduleId]?.remove(handler);
    };
  }

  /// Silently requests the screen layout again.
  void reRequestScreen(String screenId) {
    if (screenId == 'dashboard' || screenId == 'console') return;

    _screenCache.remove(screenId);

    final moduleId = _moduleIdForScreen(screenId);
    final socket = _sockets[moduleId];
    if (socket == null || !socket.connected) return;

    gLog.log(
      HbpLogLevel.DEBUG,
      'sdui_cache',
      'reRequestScreen evicting cache for: $screenId',
      tags: HbpLogTag.SDUI,
    );

    final vault = ref.read(sduiStateVaultProvider);
    final Map<String, dynamic> screenParams = {};
    vault.forEach((k, v) {
      if (k.startsWith('$screenId:')) {
        final keyWithoutPrefix = k.substring(screenId.length + 1);
        screenParams[keyWithoutPrefix] = v;
      }
    });

    socket.emit('rpc', {
      'method': 'request_screen',
      'params': {'screenId': screenId, ...screenParams},
    });
  }

  /// Evict a screen layout from the in-memory cache.
  void evictCache(String screenId) {
    gLog.log(
      HbpLogLevel.DEBUG,
      'sdui_cache',
      'evictCache evicting cache for: $screenId',
      tags: HbpLogTag.SDUI,
    );
    _screenCache.remove(screenId);
  }

  /// Emit any RPC call to the correct module socket.
  /// Resolves the module by the current router location screen prefix.
  void emitRpc(String method, Map<String, dynamic> params) {
    // Determine which module owns this RPC by prefix convention on the method name.
    // e.g. 'shua.resume.compile_pdf' → module 'shua_resume'
    final socket = _socketForMethod(method);
    if (socket == null || !socket.connected) {
      gLog.log(
        HbpLogLevel.WARN,
        'sdui_socket',
        'emitRpc called while disconnected, dropping: $method',
        tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
      );
      return;
    }
    socket.emit('rpc', {'method': method, 'params': params});
  }

  /// Sends an RPC call and returns a Future that resolves with the rpc_response payload
  /// that matches the specified transaction ID.
  Future<dynamic> sendRpcWithResponse(
    String method,
    Map<String, dynamic> params,
    String transactionId,
  ) {
    final completer = Completer<dynamic>();
    final socket = _socketForMethod(method);

    if (socket == null || !socket.connected) {
      completer.completeError(Exception('Socket is disconnected for $method'));
      return completer.future;
    }

    void handler(dynamic data) {
      try {
        final Uint8List bytes = data is Uint8List
            ? data
            : Uint8List.fromList(List<int>.from(data as List));
        final Map decoded = deserialize(bytes) as Map;

        // key 3 is transaction_id
        final txId = decoded[3] ?? decoded['3'];
        if (txId == transactionId) {
          socket.off('rpc_response', handler);
          completer.complete(decoded);
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.ERROR,
          'sdui_socket',
          'sendRpcWithResponse decode error: $e',
          tags: HbpLogTag.SDUI,
        );
      }
    }

    socket.on('rpc_response', handler);
    socket.emit('rpc', {
      'method': method,
      'params': params,
      'transaction_id': transactionId,
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        socket.off('rpc_response', handler);
        throw TimeoutException('RPC response timeout for $method');
      },
    );
  }

  /// Injects a client-side layout delta update directly into the screen cache
  /// and broadcasts to active UI listeners.
  void injectLocalDelta(String screenId, Map<String, dynamic> delta) {
    final cached = _screenCache[screenId];
    if (cached != null) {
      final updated = SduiTransport.applyDelta(cached, delta);
      _screenCache[screenId] = updated;

      final subscriber = _patchSubscribers[screenId];
      if (subscriber != null) {
        subscriber(delta);
      }
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Resolves the owning socket for a given RPC method string.
  /// Convention: 'shua.resume.compile_pdf' → moduleId 'shua_resume'.
  /// Falls back to the first available socket if no match found.
  io.Socket? _socketForMethod(String method) {
    // method format: 'shua.<module>.<action>'
    final parts = method.split('.');
    if (parts.length >= 2) {
      final candidate = '${parts[0]}_${parts[1]}'; // e.g. 'shua_resume'
      if (_sockets.containsKey(candidate)) {
        return _sockets[candidate];
      }
    }
    // Fallback: return first connected socket
    for (final s in _sockets.values) {
      if (s.connected) return s;
    }
    return _sockets.values.firstOrNull;
  }

  /// Ensures background replace_/patch_ listeners are registered for
  /// the given (moduleId, screenId) pair. Idempotent — safe to call repeatedly.
  void _ensureSocketListeners(String moduleId, String screenId) {
    if (screenId == 'dashboard' || screenId == 'console') return;

    _registeredEvents[moduleId] ??= {};
    if (_registeredEvents[moduleId]!.contains(screenId)) return;
    _registeredEvents[moduleId]!.add(screenId);

    final socket = _sockets[moduleId];
    if (socket == null) return;

    gLog.log(
      HbpLogLevel.DEBUG,
      'sdui_cache',
      'Registering background cache listeners for $screenId on $moduleId',
      tags: HbpLogTag.SDUI,
    );

    socket.on('replace_$screenId', (data) {
      gLog.log(
        HbpLogLevel.DEBUG,
        'sdui_socket',
        'replace_$screenId event received on socket!',
        tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
      );
      try {
        final Uint8List bytes = data is Uint8List
            ? data
            : Uint8List.fromList(List<int>.from(data as List));
        final nodes = SduiTransport.decode(bytes);

        _screenCache[screenId] = nodes;
        gLog.log(
          HbpLogLevel.DEBUG,
          'sdui_cache',
          'Background replace updated cache for $screenId. Nodes count: ${nodes.length}',
          tags: HbpLogTag.SDUI,
        );

        final subscriber = _replaceSubscribers[screenId];
        if (subscriber != null) {
          gLog.log(
            HbpLogLevel.DEBUG,
            'sdui_cache',
            'Notifying active replace subscriber for $screenId',
            tags: HbpLogTag.SDUI,
          );
          subscriber(nodes);
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.WARN,
          'sdui_cache',
          'Failed to decode background replace for $screenId: $e',
          tags: HbpLogTag.SDUI,
        );
      }
    });

    socket.on('patch_$screenId', (data) {
      gLog.log(
        HbpLogLevel.DEBUG,
        'sdui_socket',
        'patch_$screenId event received on socket!',
        tags: HbpLogTag.SDUI | HbpLogTag.NETWORK,
      );
      try {
        final Uint8List bytes = data is Uint8List
            ? data
            : Uint8List.fromList(List<int>.from(data as List));
        final decoded = deserialize(bytes);

        final cached = _screenCache[screenId];
        if (cached != null) {
          final updated = SduiTransport.applyDelta(cached, decoded);
          _screenCache[screenId] = updated;
          gLog.log(
            HbpLogLevel.DEBUG,
            'sdui_cache',
            'Background patch updated cache for $screenId',
            tags: HbpLogTag.SDUI,
          );

          final subscriber = _patchSubscribers[screenId];
          if (subscriber != null) {
            gLog.log(
              HbpLogLevel.DEBUG,
              'sdui_cache',
              'Notifying active patch subscriber for $screenId',
              tags: HbpLogTag.SDUI,
            );
            subscriber(decoded);
          }
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.WARN,
          'sdui_cache',
          'Failed to decode background patch for $screenId: $e',
          tags: HbpLogTag.SDUI,
        );
      }
    });
  }
}

final sduiSocketProvider = Provider((ref) => SduiSocketManager(ref));
