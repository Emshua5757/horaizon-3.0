import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../logging/governor_logger.dart';

enum AuthState { unauthenticated, authenticated }

class AuthNotifier extends Notifier<AuthState> {
  final _localAuth = LocalAuthentication();

  @override
  AuthState build() => AuthState.unauthenticated;

  /// Attempt biometric authentication (Face ID / fingerprint) with PIN fallback
  Future<bool> authenticateBiometric() async {
    final logger = ref.read(governorLoggerProvider);
    logger.log(
      subsystem: 'AUTH',
      level: LogLevel.info,
      message: 'Biometric authentication challenge initiated',
    );

    try {
      final canAuth = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuth) {
        logger.log(
          subsystem: 'AUTH',
          level: LogLevel.warn,
          message: 'Biometric hardware unsupported or unavailable',
        );
        return false;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock horAIzon 3.0',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        state = AuthState.authenticated;
        logger.log(
          subsystem: 'AUTH',
          level: LogLevel.info,
          message: 'Biometric authentication successful',
        );
      } else {
        logger.log(
          subsystem: 'AUTH',
          level: LogLevel.warn,
          message: 'Biometric authentication failed or canceled',
        );
      }
      return didAuth;
    } catch (e) {
      logger.log(
        subsystem: 'AUTH',
        level: LogLevel.error,
        message: 'Biometric auth error: $e',
      );
      return false;
    }
  }

  /// Fallback PIN verification
  void verifyPin(String pin) {
    final logger = ref.read(governorLoggerProvider);
    // TODO: Replace with secure PIN storage in TASK-012
    if (pin == '5757') {
      state = AuthState.authenticated;
      logger.log(
        subsystem: 'AUTH',
        level: LogLevel.info,
        message: 'PIN verification successful',
      );
    } else {
      logger.log(
        subsystem: 'AUTH',
        level: LogLevel.warn,
        message: 'Incorrect PIN entered',
      );
    }
  }

  void signOut() {
    final logger = ref.read(governorLoggerProvider);
    state = AuthState.unauthenticated;
    logger.log(
      subsystem: 'AUTH',
      level: LogLevel.info,
      message: 'User signed out of horAIzon 3.0 session',
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
