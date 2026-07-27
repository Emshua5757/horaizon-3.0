import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/governor_logger.dart';

/// Native SSH Client Service connecting directly to Raspberry Pi 5 (shua@100.67.11.0:22 over Tailscale).
class Rpi5SshService {
  final String host;
  final int port;
  final String username;
  final String? password;
  final GovernorLogger? _logger;

  SSHClient? _client;
  SSHSession? _shellSession;

  final _outputController = StreamController<String>.broadcast();
  Stream<String> get outputStream => _outputController.stream;

  bool get isConnected => _client != null && !_client!.isClosed;

  Rpi5SshService({
    this.host = '100.67.11.0',
    this.port = 22,
    this.username = 'shua',
    this.password,
    GovernorLogger? logger,
  }) : _logger = logger;

  Future<bool> connect() async {
    if (isConnected) return true;

    _logger?.log(
      subsystem: 'SSH',
      level: LogLevel.info,
      message: 'Connecting to RPi 5 SSH at $username@$host:$port',
    );

    try {
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );

      List<SSHKeyPair> keyPairs = [];
      try {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
        if (home.isNotEmpty) {
          final ed25519File = File('$home/.ssh/id_ed25519');
          final rsaFile = File('$home/.ssh/id_rsa');
          if (ed25519File.existsSync()) {
            keyPairs = SSHKeyPair.fromPem(ed25519File.readAsStringSync());
            _logger?.log(
              subsystem: 'SSH',
              level: LogLevel.info,
              message: 'Loaded ed25519 keypair from ~/.ssh/id_ed25519',
            );
          } else if (rsaFile.existsSync()) {
            keyPairs = SSHKeyPair.fromPem(rsaFile.readAsStringSync());
            _logger?.log(
              subsystem: 'SSH',
              level: LogLevel.info,
              message: 'Loaded RSA keypair from ~/.ssh/id_rsa',
            );
          }
        }
      } catch (e) {
        _logger?.log(
          subsystem: 'SSH',
          level: LogLevel.warn,
          message: 'Failed reading SSH keys: $e',
        );
      }

      _client = SSHClient(
        socket,
        username: username,
        identities: keyPairs.isNotEmpty ? keyPairs : null,
        onPasswordRequest: password != null ? () => password! : null,
      );

      _shellSession = await _client!.shell().timeout(const Duration(seconds: 2));

      _logger?.log(
        subsystem: 'SSH',
        level: LogLevel.info,
        message: 'Successfully established RPi 5 PTY bash shell stream',
      );

      _shellSession!.stdout.listen(
        (bytes) {
          final decoded = utf8.decode(bytes, allowMalformed: true);
          final cleaned = stripAnsiCodes(decoded);
          if (cleaned.isNotEmpty) {
            _outputController.add(cleaned);
          }
        },
        onError: (e) {
          _logger?.log(subsystem: 'SSH', level: LogLevel.error, message: 'SSH stdout error: $e');
          _outputController.add('\n[SSH Stream Error: $e]\n');
        },
      );

      _shellSession!.stderr.listen(
        (bytes) {
          final decoded = utf8.decode(bytes, allowMalformed: true);
          final cleaned = stripAnsiCodes(decoded);
          if (cleaned.isNotEmpty) {
            _outputController.add(cleaned);
          }
        },
      );

      return true;
    } catch (e) {
      _logger?.log(
        subsystem: 'SSH',
        level: LogLevel.error,
        message: 'SSH Connection to $username@$host:$port failed: $e',
      );
      _outputController.add('\n[SSH Connection to $username@$host:$port failed -> $e]\n');
      disconnect();
      return false;
    }
  }

  /// Utility to strip ANSI terminal escape codes, bracketed paste tokens, and OSC window title escapes
  static String stripAnsiCodes(String text) {
    if (text.isEmpty) return text;
    var s = text.replaceAll(RegExp(r'\x1B\][^\x07\x1B]*(\x07|\x1B\\)?'), '');
    s = s.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
    s = s.replaceAll(RegExp(r'\[\?[0-9]{4}[hl]'), '');
    s = s.replaceAll(RegExp(r'\]0;[^\n\r]*'), '');
    s = s.replaceAll(RegExp(r'\[[0-9;]+m'), '');
    s = s.replaceAll(RegExp(r'\[K'), '');
    return s;
  }

  void writeCommand(String command) {
    if (_shellSession != null) {
      _logger?.log(
        subsystem: 'SSH',
        level: LogLevel.info,
        message: 'Executed remote bash command: $command',
      );
      _shellSession!.write(utf8.encode('$command\n'));
    }
  }

  void disconnect() {
    _logger?.log(
      subsystem: 'SSH',
      level: LogLevel.info,
      message: 'SSH Session disconnected',
    );
    _shellSession?.close();
    _client?.close();
    _client = null;
    _shellSession = null;
  }

  void dispose() {
    disconnect();
    _outputController.close();
  }
}

/// Riverpod provider for Rpi5SshService
final rpi5SshServiceProvider = Provider<Rpi5SshService>((ref) {
  final logger = ref.watch(governorLoggerProvider);
  final service = Rpi5SshService(logger: logger);
  ref.onDispose(() => service.dispose());
  return service;
});
