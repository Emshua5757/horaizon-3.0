import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config_provider.dart';
import 'hbp_client.dart';

/// Riverpod provider supplying singleton HbpClient instance
final hbpClientProvider = FutureProvider<HbpClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final client = HbpClient(config);
  await client.connect();

  ref.onDispose(() => client.disconnect());
  return client;
});

/// Riverpod stream provider broadcasting HBP connection state transitions
final hbpConnectionStateProvider = StreamProvider<HbpConnectionState>((ref) async* {
  final client = await ref.watch(hbpClientProvider.future);
  yield client.currentState;
  yield* client.connectionState;
});
