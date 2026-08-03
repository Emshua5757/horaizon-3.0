import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header Title
                Text(
                  'Settings & Theme Engine 2.0',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Customize system aesthetic presets, circadian time drifting, animation speeds, and Pi 5 network link.',
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
                          Expanded(
                            child: Text(
                              'Theme Vibe Presets (7 Environments)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Presets Grid (2 Columns on Desktop, 1 Column on Mobile)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 2 : 1,
                          childAspectRatio: isDesktop ? 2.1 : 3.2,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                preset.name,
                                                style: GoogleFonts.getFont(
                                                  variant.fontFamily,
                                                  textStyle: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: variant.onSurface,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(Icons.check_circle_rounded, color: cs.primary, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          preset.description,
                                          style: GoogleFonts.getFont(
                                            variant.fontFamily,
                                            textStyle: TextStyle(
                                              color: variant.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),

                                        // Micro-Color Palette Swatch Strip
                                        if (isDesktop)
                                          Row(
                                            children: [
                                              _ColorSwatchDot(color: variant.primary, tooltip: 'Primary'),
                                              const SizedBox(width: 4),
                                              _ColorSwatchDot(color: variant.secondary, tooltip: 'Secondary'),
                                              const SizedBox(width: 4),
                                              _ColorSwatchDot(color: variant.scaffoldBg, hasBorder: true, tooltip: 'Background'),
                                              const SizedBox(width: 4),
                                              _ColorSwatchDot(color: variant.cardBg, hasBorder: true, tooltip: 'Card Surface'),
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: variant.semantic.success,
                                                  boxShadow: [BoxShadow(color: variant.semantic.success, blurRadius: 4)],
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Row(
                                            children: [
                                              _ColorSwatchDot(color: variant.primary),
                                              const SizedBox(width: 3),
                                              _ColorSwatchDot(color: variant.secondary),
                                              const SizedBox(width: 3),
                                              _ColorSwatchDot(color: variant.semantic.success),
                                            ],
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

                      if (themeState.brightnessMode == BrightnessMode.circadianAuto) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Circadian Schedule Tuning',
                                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${themeState.circadianDayStartHour.toString().padLeft(2, '0')}:00 ☀️ — ${themeState.circadianNightStartHour.toString().padLeft(2, '0')}:00 🌙',
                                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Daytime Start (Light Mode)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                                        Slider(
                                          value: themeState.circadianDayStartHour.toDouble(),
                                          min: 4,
                                          max: 10,
                                          divisions: 6,
                                          activeColor: cs.primary,
                                          label: '${themeState.circadianDayStartHour}:00 AM',
                                          onChanged: (val) => themeNotifier.setCircadianHours(
                                            dayStart: val.toInt(),
                                            nightStart: themeState.circadianNightStartHour,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Nighttime Start (Dark Mode)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                                        Slider(
                                          value: themeState.circadianNightStartHour.toDouble(),
                                          min: 16,
                                          max: 23,
                                          divisions: 7,
                                          activeColor: cs.primary,
                                          label: '${themeState.circadianNightStartHour}:00',
                                          onChanged: (val) => themeNotifier.setCircadianHours(
                                            dayStart: themeState.circadianDayStartHour,
                                            nightStart: val.toInt(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Fine-Tune Visual Effects & Animation Timing Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fine-Tune Visual Effects & Animation Speed',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Animation Speed Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Theme Interpolation Speed', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${themeState.animationMs} ms', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Slider(
                        value: themeState.animationMs.toDouble(),
                        min: 100,
                        max: 600,
                        divisions: 10,
                        activeColor: cs.primary,
                        label: '${themeState.animationMs} ms',
                        onChanged: (val) => themeNotifier.setAnimationMs(val.toInt()),
                      ),
                      const SizedBox(height: 12),

                      // Text Scale Factor Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('UI Font Scale Factor', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${(themeState.textScale * 100).toStringAsFixed(0)}%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Slider(
                        value: themeState.textScale,
                        min: 0.85,
                        max: 1.25,
                        divisions: 8,
                        activeColor: cs.primary,
                        label: '${(themeState.textScale * 100).toStringAsFixed(0)}%',
                        onChanged: (val) => themeNotifier.setTextScale(val),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Neon Outer Glow & Card Halos', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Enables dynamic neon drop shadows and hover halo reflections.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: themeState.enableGlowBorders,
                            activeTrackColor: cs.primary,
                            onChanged: (val) => themeNotifier.toggleGlowBorders(enabled: val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card Hover Spring Scaling Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Card Hover Spring Scaling', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Smooth 150ms micro-spring scaling when hovering mouse over cards.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: themeState.enableHoverScaling,
                            activeTrackColor: cs.primary,
                            onChanged: (val) => themeNotifier.toggleHoverScaling(enabled: val),
                          ),
                        ],
                      ),

                      if (themeState.enableHoverScaling) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hover Scale Intensity', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${((themeState.hoverScaleFactor - 1.0) * 100).toStringAsFixed(1)}%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Slider(
                          value: themeState.hoverScaleFactor,
                          min: 1.002,
                          max: 1.020,
                          divisions: 9,
                          activeColor: cs.primary,
                          label: '${((themeState.hoverScaleFactor - 1.0) * 100).toStringAsFixed(1)}%',
                          onChanged: (val) => themeNotifier.setHoverScaleFactor(val),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Telemetry & Hardware Polling Rate Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'HBP Telemetry Polling Rate & Pi 5 Impact',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Polling Interval / Frequency', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            themeState.telemetryPollingSeconds < 1.0
                                ? '${(themeState.telemetryPollingSeconds * 1000).round()}ms → ${(1.0 / themeState.telemetryPollingSeconds).toStringAsFixed(1)} Hz'
                                : '${themeState.telemetryPollingSeconds.toStringAsFixed(1)}s → ${(1.0 / themeState.telemetryPollingSeconds).toStringAsFixed(2)} Hz',
                            style: TextStyle(
                              color: themeState.telemetryPollingSeconds < 1.0 ? const Color(0xFFF59E0B) : cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: themeState.telemetryPollingSeconds.clamp(0.1, 10.0),
                        min: 0.1,
                        max: 10.0,
                        divisions: 99,
                        activeColor: themeState.telemetryPollingSeconds < 1.0 ? const Color(0xFFF59E0B) : cs.primary,
                        label: themeState.telemetryPollingSeconds < 1.0
                            ? '${(themeState.telemetryPollingSeconds * 1000).round()}ms (${(1.0 / themeState.telemetryPollingSeconds).toStringAsFixed(1)} Hz)'
                            : '${themeState.telemetryPollingSeconds.toStringAsFixed(1)}s (${(1.0 / themeState.telemetryPollingSeconds).toStringAsFixed(2)} Hz)',
                        onChanged: (val) => themeNotifier.setTelemetryPollingSeconds((val * 10).round() / 10.0),
                      ),
                      const SizedBox(height: 8),

                      // High Frequency Warning Banner (> 1.0 Hz)
                      if (themeState.telemetryPollingSeconds < 1.0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'HIGH FREQUENCY POLLING WARNING (> 1.0 Hz)',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Polling at ${(1.0 / themeState.telemetryPollingSeconds).toStringAsFixed(1)} Hz (${(themeState.telemetryPollingSeconds * 1000).round()}ms) consumes up to ~8.5% RPi 5 CPU load and saturates network bandwidth. Use with caution during heavy Ollama AI inference.',
                                      style: TextStyle(color: cs.onSurface, fontSize: 11, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Pi 5 Hardware Impact Calculation Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.memory_rounded, color: cs.secondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Raspberry Pi 5 CPU & Network Overhead',
                                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getPi5CpuImpactText(themeState.telemetryPollingSeconds),
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Network & Pi 5 Connection Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.router_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Raspberry Pi 5 Network Link',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
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

                // 4. Developer Tools Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.developer_mode_rounded, color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Developer Tools & Component Gallery',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
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

                // 5. About System Card
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

  String _getPi5CpuImpactText(double seconds) {
    final hz = 1.0 / seconds;
    final cpuPct = (hz * 0.85).toStringAsFixed(1);
    if (seconds <= 0.2) {
      return '🔥 MAX TURBO MESH • ~$cpuPct% RPi5 CPU Load • Real-Time Tailscale 20ms Roundtrip';
    } else if (seconds <= 0.5) {
      return '⚡ High Speed Telemetry • ~$cpuPct% RPi5 CPU Load • Tailscale Fast Sync';
    } else if (seconds < 1.0) {
      return '⚡ Accelerated Refresh • ~$cpuPct% RPi5 CPU Load';
    } else if (seconds <= 2.0) {
      return '⚖️ Balanced (Recommended) • ~$cpuPct% RPi5 CPU Load • Zero Frame Drop';
    } else if (seconds <= 5.0) {
      return '🌱 Energy Saver • ~$cpuPct% RPi5 CPU Load • Low Network Overhead';
    } else {
      return '💤 Standby Saver • ~$cpuPct% RPi5 CPU Load • Ultra-Low Power';
    }
  }
}

class _ColorSwatchDot extends StatelessWidget {
  final Color color;
  final bool hasBorder;
  final String? tooltip;

  const _ColorSwatchDot({
    required this.color,
    this.hasBorder = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: hasBorder ? Border.all(color: Colors.white24, width: 1) : null,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: dot);
    }
    return dot;
  }
}
