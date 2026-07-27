import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../config/app_config_provider.dart';
import 'hbp_client.dart';
import 'hbp_frame.dart';

/// Riverpod provider supplying singleton HbpClient instance
final hbpClientProvider = FutureProvider<HbpClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final client = HbpClient(config);
  await client.connect();

  // Automatically subscribe to shua_governor live telemetry log stream over HBP v2 WebSocket
  try {
    final p = Packer();
    p.packMapLength(1);
    p.packString('min_level'); p.packString('TRACE');
    final reqFrame = HbpFrame.request('shua.governor', 'logs.subscribe', p.takeBytes());
    client.send(reqFrame).catchError((_) => HbpFrame.ping());
  } catch (_) {}

  ref.onDispose(() => client.disconnect());
  return client;
});

/// Riverpod stream provider broadcasting HBP connection state transitions
final hbpConnectionStateProvider = StreamProvider<HbpConnectionState>((ref) async* {
  final client = await ref.watch(hbpClientProvider.future);
  yield client.currentState;
  yield* client.connectionState;
});
