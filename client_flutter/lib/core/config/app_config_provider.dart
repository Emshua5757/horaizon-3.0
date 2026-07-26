import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_config.dart';

/// Async Riverpod provider supplying application configuration
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return AppConfig.load();
});
