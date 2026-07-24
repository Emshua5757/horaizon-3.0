// client_flutter/lib/core/governor/governor_metrics_provider.dart
// Phase 11.10.B — SSE StreamProvider for /api/metrics/stream.
//
// Design:
//   Opens one persistent HTTP connection to the Governor's SSE endpoint.
//   Parses "data: {JSON}\n\n" frames from the byte stream.
//   Emits MetricsSnapshot objects to Riverpod consumers.
//
//   Complexity:
//     - O(1) persistent connection — no polling loop, no timer
//     - O(k) per frame where k = number of modules (parse one JSON object)
//     - Riverpod StreamProvider rebuilds only the widgets that watch this —
//       not the full dashboard AST

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:client_flutter/core/governor/metrics_snapshot.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart' show kGovernorBaseUrl;
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// StreamProvider that opens GET /api/metrics/stream and yields MetricsSnapshot
/// objects as they arrive. Riverpod automatically manages the lifecycle:
/// the stream is opened when first watched, closed when all watchers are disposed.
///
/// Usage:
///   final snapshot = ref.watch(governorMetricsProvider);
///   snapshot.when(
///     data: (s) => Text('CPU: ${s.cpuPct.toStringAsFixed(1)}%'),
///     loading: () => const CircularProgressIndicator(),
///     error: (e, _) => Text('SSE error: $e'),
///   );
final governorMetricsProvider = StreamProvider<MetricsSnapshot>((ref) {
  return _sseMetricsStream();
});

/// Opens an SSE connection to /api/metrics/stream and yields decoded snapshots.
///
/// SSE wire format:
///   data: {JSON}\n\n
///
/// We split the byte stream on newlines, filter lines starting with "data: ",
/// strip the prefix, and parse the JSON. Empty keep-alive lines are silently ignored.
Stream<MetricsSnapshot> _sseMetricsStream() async* {
  final uri = Uri.parse('$kGovernorBaseUrl/api/metrics/stream');

  while (true) {
    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        gLog.log(HbpLogLevel.WARN, 'metrics_sse', 'Server returned ${response.statusCode}', tags: HbpLogTag.NETWORK);
        client.close();
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      gLog.log(HbpLogLevel.INFO, 'metrics_sse', 'Connected to metrics stream', tags: HbpLogTag.NETWORK);

      // Decode the byte stream as UTF-8, split on newlines
      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (!line.startsWith('data: ')) continue; // skip empty lines, comments, keep-alives

        final jsonStr = line.substring(6).trim(); // strip "data: " prefix (6 chars)
        if (jsonStr.isEmpty) continue;

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          gLog.log(HbpLogLevel.DEBUG, 'metrics_sse', 'Received snapshot: $jsonStr', tags: HbpLogTag.NETWORK | HbpLogTag.PERF);
          yield MetricsSnapshot.fromJson(json);
        } catch (e) {
          gLog.log(HbpLogLevel.ERROR, 'metrics_sse', 'JSON parse error: $e', tags: HbpLogTag.SYSTEM);
        }
      }

      // Stream ended (server closed connection or network dropped)
      gLog.log(HbpLogLevel.WARN, 'metrics_sse', 'Stream ended — reconnecting in 3s', tags: HbpLogTag.NETWORK);
      client.close();
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'metrics_sse', 'Connection error: $e', tags: HbpLogTag.NETWORK);
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
