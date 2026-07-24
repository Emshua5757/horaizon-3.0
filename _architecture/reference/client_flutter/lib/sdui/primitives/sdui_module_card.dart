// sdui/primitives/sdui_module_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart';
import 'package:client_flutter/core/governor/governor_metrics_provider.dart';
import 'package:client_flutter/app/router.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/sdui/primitives/sdui_shimmer_loader.dart';




/// The Module Card SDUI Primitive (Type ID 39).
/// Pure SDUI-4 Dumb Shell Widget: displays state, RAM, and port injected by Rust Governor.
class SduiModuleCard extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiModuleCard({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleId = node.contentVal<String>(0) ?? '';
    if (moduleId.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Error: Module ID is null or empty in SDUI content'),
        ),
      );
    }

    final displayName = node.contentVal<String>(70) ?? moduleId;
    final iconName = node.contentVal<String>(71) ?? 'help_outline';
    final stateLabel = (node.contentVal<String>(72) ?? 'STOPPED').toUpperCase();
    final ramLabel = node.contentVal<String>(73);
    final portLabel = node.contentVal<String>(74);
    final targetRoute = node.contentVal<String>(75) ?? '/diary';
    final startActionUrl = node.contentVal<String>(76) ?? '/api/governor/control/$moduleId/start';
    final stopActionUrl = node.contentVal<String>(77) ?? '/api/governor/control/$moduleId/stop';
    final freezeActionUrl = node.contentVal<String>(78) ?? '/api/governor/control/$moduleId/freeze';
    final unfreezeActionUrl = node.contentVal<String>(79) ?? '/api/governor/control/$moduleId/unfreeze';
    final cpuLabel = node.contentVal<String>(82);

    // ── Real-time SSE stream watch ───────────────────────────────────────────
    // Overrides static AST values with real-time SSE metrics when available.
    final metricsAsync = ref.watch(governorMetricsProvider);
    String liveStateLabel = stateLabel;
    String? liveRamLabel = ramLabel;
    String? liveCpuLabel = cpuLabel;

    metricsAsync.whenData((snapshot) {
      final moduleMetrics = snapshot.modules[moduleId];
      if (moduleMetrics != null) {
        gLog.log(HbpLogLevel.DEBUG, 'sdui_module_card', 'module=$moduleId state=${moduleMetrics.state} ram=${moduleMetrics.ramMb}MB cpu=${moduleMetrics.cpuPct}%', tags: HbpLogTag.SDUI | HbpLogTag.PERF);
        liveStateLabel = moduleMetrics.state.toUpperCase();
        if (moduleMetrics.ramMb > 0) {
          liveRamLabel = '${moduleMetrics.ramMb.toStringAsFixed(1)} MB';
        }
        liveCpuLabel = '${moduleMetrics.cpuPct.toStringAsFixed(1)}%';
      }
    });

    final isBooting = liveStateLabel == 'STARTING' || liveStateLabel == 'BOOTING';
    final isActive = liveStateLabel == 'ACTIVE' || liveStateLabel == 'RUNNING' || liveStateLabel == 'READY';
    final isFrozen = liveStateLabel == 'FROZEN';

    Color statusColor;
    String statusText;
    switch (liveStateLabel) {
      case 'ACTIVE':
      case 'RUNNING':
      case 'READY':
        statusColor = Colors.green;
        statusText = 'Running';
        break;
      case 'STARTING':
      case 'BOOTING':
        statusColor = Colors.blue;
        statusText = 'Booting';
        break;
      case 'FROZEN':
        statusColor = Colors.cyan;
        statusText = 'Frozen';
        break;
      case 'CRASHED':
      case 'FAILED':
        statusColor = Colors.red;
        statusText = 'Failed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Stopped';
        break;
    }

    final theme = Theme.of(context);

    // ── Build Shared Card Body Layout ────────────────────────────────────────
    // Reused between standard active state and booting shimmer state to ensure
    // 100% identical layout bounds and zero layout shift.
    final Widget cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              SduiIconRegistry.resolve(iconName),
              size: 32,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        if (portLabel != null && portLabel.isNotEmpty)
          Text(
            'Port $portLabel',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );

    if (isBooting) {
      final dummyShimmerNode = SduiNode(
        id: 'shimmer_$moduleId',
        typeId: 14,
        behaviors: {
          91: 0, // type: none (shimmers child directly)
          92: 1, // Sweep animation strategy
          21: 16.0, // borderRadius
        },
        content: {},
        children: [],
      );

      return SizedBox(
        height: 155,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 42),
            child: SduiShimmerLoader(
              node: dummyShimmerNode,
              dispatcher: dispatcher,
              child: cardBody,
            ),
          ),
        ),
      );
    }

    Widget content = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          if (isActive) {
            // Navigate to dynamic route resolved from SDUI AST
            context.go(targetRoute);
          } else if (!isBooting) {
            if (startActionUrl.startsWith('/sdui_modal/')) {
              final modalScreenId = startActionUrl.substring('/sdui_modal/'.length);
              showSduiModalSheet(context, modalScreenId);
            } else {
              // Request module start via action URL resolved from SDUI AST
              try {
                await http.post(
                  Uri.parse('$kGovernorBaseUrl$startActionUrl'),
                );
              } catch (e) {
                gLog.log(HbpLogLevel.ERROR, 'sdui_module_card', 'Start failed: $e', tags: HbpLogTag.SDUI | HbpLogTag.SYSTEM | HbpLogTag.NETWORK);
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 42),
          child: cardBody,
        ),
      ),
    );

    return SizedBox(
      height: 155,
      child: Stack(
        children: [
          content,
          // ── Bottom Telemetry & Action Bar ──────────────────────────────
          Positioned(
            bottom: 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (liveRamLabel != null)
                      _TelemetryChip(label: liveRamLabel!, icon: Icons.memory_outlined, color: Colors.tealAccent),
                    if (liveRamLabel != null && liveCpuLabel != null)
                      const SizedBox(width: 4),
                    if (liveCpuLabel != null)
                      _TelemetryChip(label: liveCpuLabel!, icon: Icons.speed_rounded, color: Colors.orangeAccent),
                  ],
                ),
                // ── Freeze / Thaw / Stop secondary action chips ────────────
                if (isActive)
                  Row(
                    children: [
                      _ActionChip(
                        icon: Icons.ac_unit_rounded,
                        color: Colors.cyanAccent,
                        tooltip: 'Freeze (SIGSTOP)',
                        onTap: () async {
                          try {
                            await http.post(
                              Uri.parse('$kGovernorBaseUrl$freezeActionUrl'),
                            );
                          } catch (e) {
                            gLog.log(HbpLogLevel.ERROR, 'sdui_module_card', 'Freeze failed: $e', tags: HbpLogTag.SDUI | HbpLogTag.SYSTEM | HbpLogTag.NETWORK);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _ActionChip(
                        icon: Icons.stop_rounded,
                        color: Colors.redAccent,
                        tooltip: 'Stop (SIGKILL)',
                        onTap: () async {
                          try {
                            await http.post(
                              Uri.parse('$kGovernorBaseUrl$stopActionUrl'),
                            );
                          } catch (e) {
                            gLog.log(HbpLogLevel.ERROR, 'sdui_module_card', 'Stop failed: $e', tags: HbpLogTag.SDUI | HbpLogTag.SYSTEM | HbpLogTag.NETWORK);
                          }
                        },
                      ),
                    ],
                  ),
                if (isFrozen)
                  _ActionChip(
                    icon: Icons.play_arrow_rounded,
                    color: Colors.greenAccent,
                    tooltip: 'Thaw (SIGCONT)',
                    onTap: () async {
                      try {
                        await http.post(
                          Uri.parse('$kGovernorBaseUrl$unfreezeActionUrl'),
                        );
                      } catch (e) {
                        gLog.log(HbpLogLevel.ERROR, 'sdui_module_card', 'Thaw failed: $e', tags: HbpLogTag.SDUI | HbpLogTag.SYSTEM | HbpLogTag.NETWORK);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}

/// Small telemetry badge rendered inside module cards
class _TelemetryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TelemetryChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact icon button chip for module lifecycle actions (Freeze, Thaw, Stop).
/// Uses the same glassmorphism container style as _TelemetryChip for visual consistency.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

