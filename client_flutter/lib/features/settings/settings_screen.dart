import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/theme_preset_registry.dart';
import '../../shared/widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header Title
                Text(
                  'Settings & Theme Engine',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Customize system aesthetic presets, circadian time drifting, and Pi 5 network link.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // 1. Theme Presets Vibe Engine Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Theme Vibe Presets (7 Environments)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Presets Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: ThemePresetRegistry.allPresets.length,
                        itemBuilder: (context, index) {
                          final preset = ThemePresetRegistry.allPresets[index];
                          final isSelected = themeState.presetId == preset.id;
                          final variant = preset.getVariant(themeState.activeBrightness);

                          return InkWell(
                            onTap: () => themeNotifier.selectPreset(preset.id),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: variant.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? cs.primary : variant.effects.cardBorder.color,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected ? variant.effects.cardShadow : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: variant.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(preset.icon, color: variant.primary, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          preset.name,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: variant.onSurface,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          preset.description,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: variant.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Brightness & Circadian Mode Selector
                      Text(
                        'Brightness & Circadian Mode',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<BrightnessMode>(
                        segments: const [
                          ButtonSegment(
                            value: BrightnessMode.circadianAuto,
                            icon: Icon(Icons.wb_twilight_rounded),
                            label: Text('Circadian Auto'),
                          ),
                          ButtonSegment(
                            value: BrightnessMode.dark,
                            icon: Icon(Icons.dark_mode_rounded),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: BrightnessMode.light,
                            icon: Icon(Icons.light_mode_rounded),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: BrightnessMode.system,
                            icon: Icon(Icons.settings_suggest_rounded),
                            label: Text('System'),
                          ),
                        ],
                        selected: {themeState.brightnessMode},
                        onSelectionChanged: (set) => themeNotifier.setBrightnessMode(set.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Network & Pi 5 Connection Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.router_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Raspberry Pi 5 Network Link',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: '100.67.11.0',
                              decoration: const InputDecoration(
                                labelText: 'Tailscale / LAN Host IP',
                                hintText: '100.67.11.0',
                                prefixIcon: Icon(Icons.dns_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: '7700',
                              decoration: const InputDecoration(
                                labelText: 'HBP Port',
                                hintText: '7700',
                                prefixIcon: Icon(Icons.numbers_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('mDNS Scan: Querying horaizon.local on Tailscale mesh...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.radar_rounded),
                        label: const Text('Scan LAN for Pi 5 (mDNS horaizon.local)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Developer Tools Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.developer_mode_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Developer Tools & Component Gallery',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/dev/blocks'),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('Open Native Diary Block Gallery (/dev/blocks)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. About System Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'horAIzon 3.0 Architecture Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Flutter Native Desktop/Mobile Client • HBP v2 MessagePack RPC • Raspberry Pi 5 Node (shua_governor)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
