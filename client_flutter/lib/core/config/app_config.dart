import 'package:shared_preferences/shared_preferences.dart';

/// Client application configuration storing Governor host address and port.
class AppConfig {
  final String governorHost;
  final int governorPort;

  const AppConfig({
    this.governorHost = '127.0.0.1',
    this.governorPort = 7700,
  });

  /// Formatted HBP v2 WebSocket URL (ws://host:port/hbp)
  String get governorWsUrl => 'ws://$governorHost:$governorPort/hbp';

  static const String _keyHost = 'governor_host';
  static const String _keyPort = 'governor_port';

  /// Load user preference configuration from SharedPreferences
  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_keyHost) ?? '127.0.0.1';
    final port = prefs.getInt(_keyPort) ?? 7700;
    return AppConfig(governorHost: host, governorPort: port);
  }

  /// Save updated configuration to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, governorHost);
    await prefs.setInt(_keyPort, governorPort);
  }

  AppConfig copyWith({String? governorHost, int? governorPort}) {
    return AppConfig(
      governorHost: governorHost ?? this.governorHost,
      governorPort: governorPort ?? this.governorPort,
    );
  }
}
