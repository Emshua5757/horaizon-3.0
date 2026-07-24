import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single source of truth for all SDUI screen state variables.
/// Prevents data loss during widget tree rebuilds.
class SduiStateVault extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {};
  }

  /// Pure immutable state mutation.
  void set(String nodeId, dynamic value) {
    state = {
      ...state,
      nodeId: value,
    };
  }

  /// O(1) state lookup.
  T? get<T>(String nodeId) {
    return state[nodeId] as T?;
  }

  /// Safely garbage collects all state for a screen when popped.
  void releaseScope(String screenId) {
    final prefix = '$screenId:';
    final newState = Map<String, dynamic>.from(state)
      ..removeWhere((key, _) => key.startsWith(prefix));
    state = newState;
  }
}

final sduiStateVaultProvider = NotifierProvider<SduiStateVault, Map<String, dynamic>>(() {
  return SduiStateVault();
});
