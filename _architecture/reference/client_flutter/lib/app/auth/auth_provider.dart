import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/app/diagnostics/diagnostic_result.dart';
import 'package:client_flutter/app/diagnostics/system_diagnostics.dart';
import 'package:client_flutter/app/diagnostics/diagnostics_provider.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  final String enteredPin;
  final AuthStatus status;
  final DiagnosticResult<String>? lastDiagnostic;

  AuthState({
    required this.enteredPin, 
    required this.status, 
    this.lastDiagnostic,
  });

  AuthState copyWith({
    String? enteredPin, 
    AuthStatus? status, 
    DiagnosticResult<String>? lastDiagnostic,
  }) {
    return AuthState(
      enteredPin: enteredPin ?? this.enteredPin,
      status: status ?? this.status,
      lastDiagnostic: lastDiagnostic ?? this.lastDiagnostic,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(enteredPin: '', status: AuthStatus.unauthenticated);
  }

  void enterDigit(String digit) {
    if (state.enteredPin.length == 4) return;

    state = state.copyWith(enteredPin: state.enteredPin + digit);

    if (state.enteredPin.length == 4) {
      verifyPIN(state.enteredPin);
    }
  }

  void deleteDigit() {
    if (state.enteredPin.isEmpty) return;

    state = state.copyWith(
      enteredPin: state.enteredPin.substring(0, state.enteredPin.length - 1),
    );
  }

  void verifyPIN(String pin) {
    final isValid = pin == '4002'; // Matching existing mock PIN

    DiagnosticResult<String> result;
    if (isValid) {
      result = DiagnosticResult.success(pin, diagnostic: SystemEvents.authSuccess);
    } else {
      result = DiagnosticResult.failure(SystemEvents.authInvalidPin);
    }

    // Pipe the result into the centralized telemetry mirror
    ref.read(diagnosticsHistoryProvider.notifier).logResult(result);

    state = state.copyWith(
      status: isValid ? AuthStatus.authenticated : AuthStatus.error,
      enteredPin: isValid ? pin : '',
      lastDiagnostic: result,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
