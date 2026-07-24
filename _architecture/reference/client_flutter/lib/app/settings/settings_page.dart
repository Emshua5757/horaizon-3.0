import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/app/theme/theme_provider.dart';
import 'package:client_flutter/app/settings/theme_seeds.dart';
import 'package:client_flutter/app/settings/config_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mathematical Theme Engine',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Obsidian Dark Mode'),
                        value: themeState.brightness == Brightness.dark,
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).toggleBrightness();
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Primary Accent Seed:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: AppThemeSeeds.options
                            .map(
                              (seed) => _buildColorSwatch(
                                context,
                                ref,
                                seed.color,
                                seed.label,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Secondary Accent Seed:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: AppThemeSeeds.options
                            .map(
                              (seed) => _buildColorSwatch(
                                context,
                                ref,
                                seed.color,
                                seed.label,
                                isSecondary: true,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text('Animation Duration: ${themeState.animationMs} ms'),
                      Slider(
                        value: themeState.animationMs.toDouble(),
                        min: 0,
                        max: 2000,
                        divisions: 20,
                        label: '${themeState.animationMs} ms',
                        onChanged: (val) {
                          ref
                              .read(themeProvider.notifier)
                              .updateAnimationMs(val.toInt());
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Global Font Scale: ${themeState.textScale.toStringAsFixed(2)}x',
                      ),
                      Slider(
                        value: themeState.textScale,
                        min: 0.8,
                        max: 1.5,
                        divisions: 7,
                        label: '${themeState.textScale.toStringAsFixed(2)}x',
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).updateTextScale(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _NetworkConfigCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(
    BuildContext context,
    WidgetRef ref,
    Color color,
    String tooltip, {
    bool isSecondary = false,
  }) {
    final themeState = ref.watch(themeProvider);
    final isSelected = isSecondary
        ? themeState.secondary == color
        : themeState.primary == color;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          if (isSecondary) {
            ref.read(themeProvider.notifier).updateSecondary(color);
          } else {
            ref.read(themeProvider.notifier).updatePrimary(color);
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}

class _NetworkConfigCard extends ConsumerStatefulWidget {
  const _NetworkConfigCard();

  @override
  ConsumerState<_NetworkConfigCard> createState() => _NetworkConfigCardState();
}

class _NetworkConfigCardState extends ConsumerState<_NetworkConfigCard> {
  late TextEditingController _syncController;
  late TextEditingController _ollamaController;
  late TextEditingController _modelController;
  late TextEditingController _geminiKeyController;
  late TextEditingController _workspaceController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(systemConfigProvider);
    _syncController = TextEditingController(text: config.syncBaseUrl);
    _ollamaController = TextEditingController(text: config.ollamaUrl);
    _modelController = TextEditingController(text: config.ollamaModel);
    _geminiKeyController = TextEditingController(text: config.geminiApiKey);
    _workspaceController = TextEditingController(text: config.workspaceRoot);
  }

  @override
  void dispose() {
    _syncController.dispose();
    _ollamaController.dispose();
    _modelController.dispose();
    _geminiKeyController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final notifier = ref.read(systemConfigProvider.notifier);
    notifier.updateSyncBaseUrl(_syncController.text.trim());
    notifier.updateOllamaUrl(_ollamaController.text.trim());
    notifier.updateOllamaModel(_modelController.text.trim());
    notifier.updateGeminiApiKey(_geminiKeyController.text.trim());
    notifier.updateWorkspaceRoot(_workspaceController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ J.O.S.H. System configuration updated reactively!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: theme.colorScheme.surface.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_ethernet, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'J.O.S.H. Engine & Network Controller',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Customize host nodes and target LLM models dynamically to support zero-downtime Raspberry Pi 5 edge migrations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _syncController,
              decoration: InputDecoration(
                labelText: 'Node.js Backend Sync URL',
                hintText: 'http://127.0.0.1:3000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ollamaController,
              decoration: InputDecoration(
                labelText: 'Ollama Endpoint URL',
                hintText: 'http://127.0.0.1:11434/api/chat',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.bolt),
              ),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Ollama Model Target',
                hintText: 'qwen2.5:7b',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.psychology_outlined),
              ),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _geminiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Gemini Cloud API Key (Optional)',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _workspaceController,
              decoration: InputDecoration(
                labelText: 'Workspace Root Directory',
                hintText: 'c:\\horAIzon_2.0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.folder_open_outlined),
              ),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Commit System Configs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
