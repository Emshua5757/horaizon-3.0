import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:client_flutter/app/diagnostics/diagnostic_result.dart';
import 'package:client_flutter/app/diagnostics/system_diagnostics.dart';
import 'package:client_flutter/app/diagnostics/diagnostics_provider.dart';

/// An O(1) memory-bounded branching history stack for Navigation.
///
/// Designed to keep routing lightweight by using a Doubly-Linked List.
/// When the memory threshold (`_maxCount`) is breached, it instantly drops
/// the oldest routes. It natively handles timeline branching: adding a new
/// route while deep in the back-history instantly severs all forward routes
/// for the Dart Garbage Collector.
class BoundedRouteHistory extends ChangeNotifier {
  final void Function(DiagnosticResult)? onLog;

  BoundedRouteHistory({this.onLog});

  int _maxCount = 10;

  // _pos tracks the user's current location relative to the head.
  int _pos = 0;

  // _totalCount tracks the absolute number of nodes currently in memory.
  int _totalCount = 0;

  RouteNode? _currNode;
  RouteNode? _headNode;
  RouteNode? _tailNode;

  /// Returns true if there is a previous route in the history stack.
  bool get canGoBack => _currNode?.prev != null;

  /// Gets the current location URI
  String? get currentLocation => _currNode?.location;

  /// Returns true if there is a forward route in the history stack.
  bool get canGoForward => _currNode?.next != null;

  /// Returns true if the routing chassis has not yet initialized.
  bool get isEmpty => _currNode == null;

  /// Pushes a new route onto the stack in O(1) time.
  void addRoute(String location) {
    // Ignore splash/loading screens from history
    if (location == '/loading' || location == '/splash') return;

    // Deduplicate consecutive identical routes
    if (_currNode?.location == location) return;

    var newNode = RouteNode(location);

    if (_currNode == null) {
      // Initialize the very first route
      _headNode = newNode;
      _currNode = newNode;
      _tailNode = newNode;
      _pos = 1;
      _totalCount = 1;
    } else {
      // Attach new route and sever any existing future timeline
      _currNode!.next = newNode;
      newNode.prev = _currNode;
      _currNode = newNode;
      _tailNode = newNode; // The new route is always the absolute new tail

      _pos++;
      // Since the future was severed, total count resets to our current position
      _totalCount = _pos;

      // O(1) FIFO Eviction from the past
      if (_totalCount > _maxCount) {
        _headNode = _headNode!.next;
        _headNode?.prev = null; // Completely orphan the oldest node
        _pos--;
        _totalCount--;
      }
    }
    _logRouteEvent('Navigated to $location');
    notifyListeners();
  }

  /// Shifts the internal pointer to the next route in O(1) time.
  void moveForward() {
    if (canGoForward) {
      _currNode = _currNode?.next;
      _pos++;
      _logRouteEvent('Navigated forward to ${_currNode?.location}');
      notifyListeners();
    }
  }

  /// Shifts the internal pointer to the previous route in O(1) time.
  void moveBack() {
    if (canGoBack) {
      _currNode = _currNode?.prev;
      _pos--;
      _logRouteEvent('Navigated back to ${_currNode?.location}');
      notifyListeners();
    }
  }

  /// Instantly fast-forwards the user to the most recent timeline edge.
  /// Made possible in O(1) time by the _tailNode optimization.
  void jumpToNewest() {
    if (_tailNode != null && _currNode != _tailNode) {
      _currNode = _tailNode;
      _pos = _totalCount;
      _logRouteEvent('Fast-forwarded to newest route: ${_currNode?.location}');
      notifyListeners();
    }
  }

  /// Dynamically tightens or loosens the memory constraint.
  ///
  /// Employs a Dual-Trim strategy: drops oldest nodes first. If it reaches
  /// the user's active viewport, it shifts to dropping future nodes to
  /// guarantee the active session is never destroyed. Now fully O(1) per node.
  void updateMaxCount(int newMax) {
    if (newMax < 1) return;
    _maxCount = newMax;

    // Phase 1: Trim from the past (head)
    while (_totalCount > _maxCount && _headNode != _currNode) {
      _headNode = _headNode!.next;
      _headNode?.prev = null;
      _pos--;
      _totalCount--;
    }

    // Phase 2: Trim from the future (tail)
    while (_totalCount > _maxCount &&
        _tailNode != null &&
        _tailNode != _currNode) {
      _tailNode = _tailNode!.prev;
      _tailNode?.next = null; // Sever the old tail completely
      _totalCount--;
    }

    onLog?.call(
      DiagnosticResult.success(
        'Compacted to $_maxCount bounds',
        diagnostic: SystemEvents.routeTrimmed,
      ),
    );
    notifyListeners();
  }

  void _logRouteEvent(String detail) {
    onLog?.call(
      DiagnosticResult.success(
        detail,
        diagnostic: SystemEvents.routeChanged,
      ),
    );
  }
}

/// A lightweight, stateful node representing a single navigation instance.
/// Holds references to its adjacent routes for O(1) traversal.
class RouteNode {
  RouteNode? next;
  RouteNode? prev;

  /// Optional payload to restore page state (e.g., scroll position, models)
  final Object? extra;

  /// The go_router URI location
  final String location;

  RouteNode(this.location, {this.extra});
}

/// Riverpod provider to expose the history across the entire Flutter app.
final routeHistoryProvider = ChangeNotifierProvider<BoundedRouteHistory>((ref) {
  return BoundedRouteHistory(
    onLog: (result) => ref.read(diagnosticsHistoryProvider.notifier).logResult(result),
  );
});
