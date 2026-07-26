import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

enum AuthState { unauthenticated, authenticated }

class AuthNotifier extends Notifier<AuthState> {
  final _localAuth = LocalAuthentication();

  @override
  AuthState build() => AuthState.unauthenticated;

  /// Attempt biometric authentication (Face ID / fingerprint) with PIN fallback
  Future<bool> authenticateBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuth) return false;

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock horAIzon 3.0',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        state = AuthState.authenticated;
      }
      return didAuth;
    } catch (_) {
      return false;
    }
  }

  /// Fallback PIN verification
  void verifyPin(String pin) {
    // TODO: Replace with secure PIN storage in TASK-012
    if (pin == '5757') {
      state = AuthState.authenticated;
    }
  }

  void signOut() {
    state = AuthState.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
