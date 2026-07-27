import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Native SSH Client Service connecting directly to Raspberry Pi 5 (shua@100.67.11.0:22 over Tailscale).
class Rpi5SshService {
  final String host;
  final int port;
  final String username;
  final String? password;

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
  });

  Future<bool> connect() async {
    if (isConnected) return true;

    try {
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: password != null ? () => password! : null,
      );

      _shellSession = await _client!.shell();

      _shellSession!.stdout.listen(
        (bytes) => _outputController.add(utf8.decode(bytes, allowMalformed: true)),
        onError: (e) => _outputController.add('\n[SSH Stream Error: $e]\n'),
      );

      _shellSession!.stderr.listen(
        (bytes) => _outputController.add(utf8.decode(bytes, allowMalformed: true)),
      );

      return true;
    } catch (e) {
      _outputController.add('\n[SSH Connection to $username@$host:$port failed -> $e]\n');
      return false;
    }
  }

  void writeCommand(String command) {
    if (_shellSession != null) {
      _shellSession!.write(utf8.encode('$command\n'));
    }
  }

  void disconnect() {
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
  final service = Rpi5SshService();
  ref.onDispose(() => service.dispose());
  return service;
});
