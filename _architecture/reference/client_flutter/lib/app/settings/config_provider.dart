import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

class ConfigState {
  final String syncBaseUrl;
  final String ollamaUrl;
  final String ollamaModel;
  final String geminiApiKey;
  final String workspaceRoot;

  ConfigState({
    required this.syncBaseUrl,
    required this.ollamaUrl,
    required this.ollamaModel,
    required this.geminiApiKey,
    required this.workspaceRoot,
  });

  ConfigState copyWith({
    String? syncBaseUrl,
    String? ollamaUrl,
    String? ollamaModel,
    String? geminiApiKey,
    String? workspaceRoot,
  }) {
    return ConfigState(
      syncBaseUrl: syncBaseUrl ?? this.syncBaseUrl,
      ollamaUrl: ollamaUrl ?? this.ollamaUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      workspaceRoot: workspaceRoot ?? this.workspaceRoot,
    );
  }
}

class ConfigNotifier extends Notifier<ConfigState> {
  @override
  ConfigState build() {
    _loadConfig();
    return ConfigState(
      syncBaseUrl: 'http://100.67.11.0:3000',
      ollamaUrl: 'http://127.0.0.1:11434/api/chat',
      ollamaModel: 'qwen2.5:7b',
      geminiApiKey: '',
      workspaceRoot: 'c:\\horAIzon_2.0',
    );
  }

  Future<void> _loadConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'system_config.json'));
      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        state = ConfigState(
          syncBaseUrl: data['syncBaseUrl'] as String? ?? state.syncBaseUrl,
          ollamaUrl: data['ollamaUrl'] as String? ?? state.ollamaUrl,
          ollamaModel: data['ollamaModel'] as String? ?? state.ollamaModel,
          geminiApiKey: data['geminiApiKey'] as String? ?? state.geminiApiKey,
          workspaceRoot:
              data['workspaceRoot'] as String? ?? state.workspaceRoot,
        );
      }
    } catch (e) {
      gLog.log(
        HbpLogLevel.ERROR,
        'config_provider',
        'Failed to load configuration: $e',
        tags: HbpLogTag.SYSTEM,
      );
    }
  }

  Future<void> _saveConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'system_config.json'));
      final data = {
        'syncBaseUrl': state.syncBaseUrl,
        'ollamaUrl': state.ollamaUrl,
        'ollamaModel': state.ollamaModel,
        'geminiApiKey': state.geminiApiKey,
        'workspaceRoot': state.workspaceRoot,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      gLog.log(
        HbpLogLevel.ERROR,
        'config_provider',
        'Failed to save configuration: $e',
        tags: HbpLogTag.SYSTEM,
      );
    }
  }

  void updateSyncBaseUrl(String url) {
    state = state.copyWith(syncBaseUrl: url);
    _saveConfig();
  }

  void updateOllamaUrl(String url) {
    state = state.copyWith(ollamaUrl: url);
    _saveConfig();
  }

  void updateOllamaModel(String model) {
    state = state.copyWith(ollamaModel: model);
    _saveConfig();
  }

  void updateGeminiApiKey(String key) {
    state = state.copyWith(geminiApiKey: key);
    _saveConfig();
  }

  void updateWorkspaceRoot(String root) {
    state = state.copyWith(workspaceRoot: root);
    _saveConfig();
  }
}

final systemConfigProvider = NotifierProvider<ConfigNotifier, ConfigState>(() {
  return ConfigNotifier();
});
