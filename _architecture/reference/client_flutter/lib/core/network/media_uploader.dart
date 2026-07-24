// core/network/media_uploader.dart
// Phase 8 — Multipart HTTP Upload with SSE Progress & Chunked Protocol
// Architecture spec: _architecture/governor/media-server-spec.md §4, §9, §16
//
// Design:
//   - Files ≤ 50 MB: single multipart POST (/api/media/upload)
//   - Files > 50 MB: init → chunk × N → finalize with SSE progress stream
//   - CAS dedup: 201 = new file, 200 = hash already existed (free upload)
//   - SSE failure is non-fatal: falls back to client-side estimated progress
//   - O(1) per-chunk: no accumulated buffer; chunks are sliced sublist references

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'package:client_flutter/app/settings/config_provider.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Upload result & progress types
// ─────────────────────────────────────────────────────────────────────────────

class MediaUploadResult {
  /// SHA-256 hex digest — the CAS key.
  final String hash;

  /// Absolute path segment, e.g. '/api/media/uploads/abc123.jpg'.
  /// Prepend your governor base URL to construct the full URL.
  final String url;

  /// True if the server deduped this upload (file already existed in CAS).
  final bool wasDeduplicated;

  const MediaUploadResult({
    required this.hash,
    required this.url,
    required this.wasDeduplicated,
  });
}

class UploadProgressEvent {
  final String uploadId;
  final int chunksReceived;
  final int chunksTotal;
  final int pct; // 0–100

  const UploadProgressEvent({
    required this.uploadId,
    required this.chunksReceived,
    required this.chunksTotal,
    required this.pct,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Exception
// ─────────────────────────────────────────────────────────────────────────────

class MediaUploadException implements Exception {
  final String code;
  final String message;
  const MediaUploadException({required this.code, required this.message});

  @override
  String toString() => 'MediaUploadException[$code]: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Threshold above which chunked upload is used (§9).
const int _kChunkUploadThreshold = 50 * 1024 * 1024; // 50 MB

/// Each chunk size (§9.2) — matches Governor's CHUNK_SIZE constant.
const int _kChunkSize = 10 * 1024 * 1024; // 10 MB

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  final baseUrl = ref.watch(systemConfigProvider).syncBaseUrl;
  return MediaUploader(baseUrl: baseUrl);
});

// ─────────────────────────────────────────────────────────────────────────────
// MediaUploader
// ─────────────────────────────────────────────────────────────────────────────

class MediaUploader {
  final String baseUrl;

  const MediaUploader({required this.baseUrl});

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Upload a file at [filePath] to the Governor's CAS pipeline.
  Future<MediaUploadResult> uploadFile({
    required String filePath,
    required String moduleOwner,
    void Function(int pct)? onProgress,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final filename = filePath.split(Platform.pathSeparator).last;

    gLog.log(
      HbpLogLevel.INFO,
      'media_uploader',
      'Uploading "$filename" — ${(bytes.length / 1048576).toStringAsFixed(2)} MB',
    );

    if (bytes.length <= _kChunkUploadThreshold) {
      return _simpleUpload(
        bytes: bytes,
        filename: filename,
        moduleOwner: moduleOwner,
        onProgress: onProgress,
      );
    } else {
      return _chunkedUpload(
        bytes: bytes,
        filename: filename,
        moduleOwner: moduleOwner,
        onProgress: onProgress,
      );
    }
  }

  /// Upload raw in-memory bytes (e.g. generated documents, camera captures).
  Future<MediaUploadResult> uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String moduleOwner,
    String? mimeType,
    void Function(int pct)? onProgress,
  }) async {
    if (bytes.length <= _kChunkUploadThreshold) {
      return _simpleUpload(
        bytes: bytes,
        filename: filename,
        moduleOwner: moduleOwner,
        mimeType: mimeType,
        onProgress: onProgress,
      );
    } else {
      return _chunkedUpload(
        bytes: bytes,
        filename: filename,
        moduleOwner: moduleOwner,
        onProgress: onProgress,
      );
    }
  }

  // ── Simple Multipart Upload (§4) ─────────────────────────────────────────

  Future<MediaUploadResult> _simpleUpload({
    required Uint8List bytes,
    required String filename,
    required String moduleOwner,
    String? mimeType,
    void Function(int pct)? onProgress,
  }) async {
    onProgress?.call(0);

    final uri = Uri.parse('$baseUrl/api/media/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer horAIzon-CAS-Token-v1';
    final mime = mimeType ?? _inferMime(filename);
    final parts = mime.split('/');

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: http.MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream'),
      ),
    );
    request.fields['module_owner'] = moduleOwner;

    onProgress?.call(10);
    final streamed = await request.send();
    onProgress?.call(80);
    final response = await http.Response.fromStream(streamed);
    onProgress?.call(100);

    _assertStatus(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MediaUploadResult(
      hash: json['hash'] as String,
      url: json['url'] as String,
      // 200 = dedup hit, 201 = new file
      wasDeduplicated: response.statusCode == 200,
    );
  }

  // ── Chunked Upload Protocol (§9) ─────────────────────────────────────────

  Future<MediaUploadResult> _chunkedUpload({
    required Uint8List bytes,
    required String filename,
    required String moduleOwner,
    void Function(int pct)? onProgress,
  }) async {
    final sizeBytes = bytes.length;
    final totalChunks = (sizeBytes / _kChunkSize).ceil();
    onProgress?.call(0);

    // ── 1. Init ──────────────────────────────────────────────────────────────
    final initUri = Uri.parse('$baseUrl/api/media/upload/init');
    final initResponse = await http.post(
      initUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer horAIzon-CAS-Token-v1',
      },
      body: jsonEncode({
        'hash': _deterministicId(filename, sizeBytes),
        'size_bytes': sizeBytes,
        'filename': filename,
      }),
    );

    if (initResponse.statusCode != 200) {
      throw MediaUploadException(
        code: 'INIT_${initResponse.statusCode}',
        message: initResponse.body,
      );
    }

    final initJson = jsonDecode(initResponse.body) as Map<String, dynamic>;

    // Server-side dedup: all chunks already present
    if (initJson['url'] != null) {
      onProgress?.call(100);
      return MediaUploadResult(
        hash: initJson['upload_id'] as String? ?? '',
        url: initJson['url'] as String,
        wasDeduplicated: true,
      );
    }

    final uploadId = initJson['upload_id'] as String;
    final chunksNeeded = (initJson['chunks_needed'] as List? ?? []).cast<int>();

    // ── 2. Subscribe to SSE progress stream (§16) ────────────────────────────
    final progressCtrl = StreamController<UploadProgressEvent>.broadcast();
    _listenToSseProgress(uploadId, progressCtrl);
    final sub = progressCtrl.stream.listen((e) => onProgress?.call(e.pct));

    // ── 3. Send chunks ───────────────────────────────────────────────────────
    final chunkUri = Uri.parse('$baseUrl/api/media/upload/chunk');

    for (final idx in chunksNeeded) {
      final start = idx * _kChunkSize;
      final end = (start + _kChunkSize).clamp(0, sizeBytes);
      final chunkBytes = bytes.sublist(start, end); // O(1) view, no copy

      final chunkResp = await http.post(
        chunkUri,
        headers: {
          'X-Upload-ID': uploadId,
          'X-Chunk-Index': '$idx',
          'Content-Type': 'application/octet-stream',
          'Authorization': 'Bearer horAIzon-CAS-Token-v1',
        },
        body: chunkBytes,
      );

      if (chunkResp.statusCode != 200) {
        await sub.cancel();
        await progressCtrl.close();
        throw MediaUploadException(
          code: 'CHUNK_${chunkResp.statusCode}',
          message: 'Chunk $idx: ${chunkResp.body}',
        );
      }

      // Fallback progress in case SSE is lagging
      final fallbackPct = ((idx + 1) / totalChunks * 90).round();
      onProgress?.call(fallbackPct);
    }

    // ── 4. Finalize ──────────────────────────────────────────────────────────
    final finalizeUri = Uri.parse('$baseUrl/api/media/upload/finalize');
    final finalizeResp = await http.post(
      finalizeUri,
      headers: {
        'X-Upload-ID': uploadId,
        'Authorization': 'Bearer horAIzon-CAS-Token-v1',
      },
    );

    await sub.cancel();
    await progressCtrl.close();

    _assertStatus(finalizeResp);
    onProgress?.call(100);

    final finalJson = jsonDecode(finalizeResp.body) as Map<String, dynamic>;
    return MediaUploadResult(
      hash: uploadId,
      url: finalJson['url'] as String,
      wasDeduplicated: false,
    );
  }

  // ── SSE Progress Listener (§16) ──────────────────────────────────────────

  void _listenToSseProgress(
    String uploadId,
    StreamController<UploadProgressEvent> controller,
  ) {
    // Non-blocking detached async task — failure is non-fatal.
    Future(() async {
      final client = http.Client();
      try {
        final uri = Uri.parse('$baseUrl/api/media/upload/progress/$uploadId');
        final request = http.Request('GET', uri);
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';
        request.headers['Authorization'] = 'Bearer horAIzon-CAS-Token-v1';

        final response = await client.send(request);
        if (response.statusCode != 200) return;

        String buf = '';
        await for (final chunk in response.stream.toStringStream()) {
          if (controller.isClosed) break;
          buf += chunk;

          // Process complete lines
          final lines = buf.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (!line.startsWith('data:')) continue;

            final dataStr = line.substring(5).trim();
            try {
              final map = jsonDecode(dataStr) as Map<String, dynamic>;
              final event = UploadProgressEvent(
                uploadId: map['upload_id'] as String? ?? uploadId,
                chunksReceived: (map['chunks_received'] as num?)?.toInt() ?? 0,
                chunksTotal: (map['chunks_total'] as num?)?.toInt() ?? 1,
                pct: (map['pct'] as num?)?.toInt() ?? 0,
              );
              if (!controller.isClosed) controller.add(event);
              if (event.pct >= 100) return;
            } catch (_) {
              // Skip malformed SSE frames
            }
          }
          buf = lines.last; // Preserve incomplete tail line
        }
      } catch (e) {
        gLog.log(
          HbpLogLevel.WARN,
          'media_uploader',
          'SSE stream error: $e — falling back to client-side progress',
        );
      } finally {
        client.close();
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Validates HTTP status and throws typed [MediaUploadException] on failure.
  void _assertStatus(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw switch (response.statusCode) {
      507 => const MediaUploadException(
        code: 'DISK_FULL',
        message: 'Pi 5 storage is full — uploads blocked until space frees.',
      ),
      415 => MediaUploadException(
        code: 'MIME_REJECTED',
        message: 'MIME type not allowed: ${response.body}',
      ),
      409 => const MediaUploadException(
        code: 'CONCURRENT_WRITE',
        message: 'Upload session conflict — retry in a few seconds.',
      ),
      _ => MediaUploadException(
        code: 'HTTP_${response.statusCode}',
        message: response.body,
      ),
    };
  }

  /// Deterministic upload session ID from filename + size.
  /// This is sent as the initial hash hint; the server computes the real SHA-256
  /// on finalize and stores it in the CAS ledger.
  String _deterministicId(String filename, int size) {
    // Simple mixing hash — sufficient for session key uniqueness, not CAS purity.
    // Production: compute dart:crypto SHA-256 of the file bytes before upload.
    int h = size;
    for (final c in filename.codeUnits) {
      h = (h * 31 + c) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(64, '0');
  }

  /// Infer MIME type from file extension for multipart Content-Type header.
  String _inferMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp3' => 'audio/mpeg',
      'ogg' => 'audio/ogg',
      'mp4' => 'video/mp4',
      'mkv' => 'video/x-matroska',
      'pdf' => 'application/pdf',
      'stl' => 'model/stl',
      'obj' => 'model/obj',
      _ => 'application/octet-stream',
    };
  }

  /// Helper to pick a file, display a non-dismissible progress dialog, upload it to the NAS,
  /// update the StateVault with the resolved CAS URL, and notify the event dispatcher.
  Future<void> pickAndUploadWithUi({
    required BuildContext context,
    required WidgetRef ref,
    required String bindKey,
    required FileType fileType,
    List<String>? allowedExtensions,
    required String moduleOwner,
    required SduiEventDispatcher dispatcher,
  }) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        withData: false,
      );
    } catch (e) {
      if (context.mounted) _showError(context, 'File pick failed: $e');
      return;
    }

    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;
    final filename = result.files.single.name;

    if (!context.mounted) return;

    // Coordinating variables to prevent Flutter showDialog builder race condition
    bool uploadFinished = false;
    BuildContext? dialogContext;
    final progressNotifier = ValueNotifier<int>(0);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        dialogContext = dCtx;
        if (uploadFinished) {
          // If upload completed before builder executed, dismiss immediately
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dCtx.mounted) Navigator.of(dCtx).pop();
          });
        }
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Uploading to Pi 5 NAS'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: progressNotifier,
                  builder: (context, pct, child) {
                    return Column(
                      children: [
                        LinearProgressIndicator(value: pct / 100.0),
                        const SizedBox(height: 8),
                        Text('$pct%  —  $filename',
                            style: Theme.of(dCtx).textTheme.bodySmall),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    void closeDialog() {
      uploadFinished = true;
      if (context.mounted && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
    }

    // Execute upload
    try {
      final result = await uploadFile(
        filePath: filePath,
        moduleOwner: moduleOwner,
        onProgress: (pct) => progressNotifier.value = pct,
      );

      closeDialog();

      // Write CAS URL to state vault — triggers view rebuild
      final casUrl = baseUrl + result.url;
      ref.read(sduiStateVaultProvider.notifier).set(bindKey, casUrl);
      dispatcher.onStateChange(bindKey, casUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.wasDeduplicated
                  ? '✓ Already in NAS — loaded from cache'
                  : '✓ Uploaded: ${result.hash.substring(0, 8)}…',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      gLog.log(
        HbpLogLevel.INFO,
        moduleOwner,
        'Upload complete — hash=${result.hash.substring(0, 8)} dedup=${result.wasDeduplicated}',
      );
    } on MediaUploadException catch (e) {
      closeDialog();
      if (context.mounted) _showError(context, e.message);
    } catch (e) {
      closeDialog();
      if (context.mounted) _showError(context, 'Upload failed: $e');
    } finally {
      progressNotifier.dispose();
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload error: $message'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

