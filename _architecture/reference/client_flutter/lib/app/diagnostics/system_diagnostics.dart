/// Categorizes the severity of a system diagnostic event.
enum DiagnosticSeverity { 
  /// Routine operational logging (e.g. successful syncs, UI transitions).
  nominal, 
  
  /// Recoverable errors, handled exceptions, or minor anomalies (e.g. invalid PIN, minor lag).
  warning, 
  
  /// Irrecoverable state corruption, data loss risks, or hard exceptions (e.g. DB locks).
  critical 
}

/// The immutable definition of a system event or failure.
class SystemDiagnostic {
  final String code;
  final String defaultMessage;
  final DiagnosticSeverity severity;

  const SystemDiagnostic(this.code, this.defaultMessage, this.severity);
}

/// Centralized Registry of all system events, errors, and telemetry codes.
/// Ensures O(1) error categorization without magic strings or runtime parsing.
class SystemEvents {
  // --- Initialization & Boot ---
  static const bootSuccess = SystemDiagnostic('SYS-001', 'System bootstrap nominal', DiagnosticSeverity.nominal);

  // --- Database ---
  static const dbDeadlock = SystemDiagnostic('DB-001', 'Database transaction deadlock', DiagnosticSeverity.critical);
  static const dbRecordMissing = SystemDiagnostic('DB-002', 'Record not found in local cache', DiagnosticSeverity.warning);
  static const dbWriteSuccess = SystemDiagnostic('DB-003', 'Database write successful', DiagnosticSeverity.nominal);

  // --- Authentication ---
  static const authSuccess = SystemDiagnostic('AUTH-000', 'Authentication successful', DiagnosticSeverity.nominal);
  static const authInvalidPin = SystemDiagnostic('AUTH-001', 'Invalid security PIN entered', DiagnosticSeverity.warning);
  static const authBruteForce = SystemDiagnostic('AUTH-002', 'Multiple failed PIN attempts. Locking.', DiagnosticSeverity.critical);
  
  // --- Network & Sync ---
  static const netOffline = SystemDiagnostic('NET-001', 'Remote server unreachable', DiagnosticSeverity.warning);
  // --- Navigation ---
  static const routeChanged = SystemDiagnostic('NAV-001', 'Navigation route updated', DiagnosticSeverity.nominal);
  static const routeTrimmed = SystemDiagnostic('NAV-002', 'Route history memory compacted', DiagnosticSeverity.nominal);

  // --- Theme ---
  static const themeUpdated = SystemDiagnostic('THEME-001', 'UI Theme parameters compiled', DiagnosticSeverity.nominal);
}
