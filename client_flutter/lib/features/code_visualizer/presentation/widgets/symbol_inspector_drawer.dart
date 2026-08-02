import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../providers/code_topology_provider.dart';

class SymbolInspectorDrawer extends ConsumerWidget {
  final TopologyNodeModel node;

  const SymbolInspectorDrawer({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.all(16),
            color: cs.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Symbol Inspector',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    ref.read(selectedNodeProvider.notifier).state = null;
                  },
                ),
              ],
            ),
          ),

          // Drawer Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Symbol Name
                Text(
                  node.qualifiedName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${node.file}:${node.line}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                Row(
                  children: [
                    _MetricBadge(
                        label: 'LOC', value: '${node.loc}', color: cs.primary),
                    const SizedBox(width: 8),
                    _MetricBadge(
                      label: 'Complexity',
                      value: '${node.complexity}',
                      color: node.complexity > 10
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _MetricBadge(
                      label: 'Risk Score',
                      value: node.riskScore.toStringAsFixed(1),
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Intent / Doc Comment
                if (node.intent != null && node.intent!.isNotEmpty) ...[
                  Text(
                    'Intent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      node.intent!,
                      style: TextStyle(fontSize: 12, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Parameters
                Text(
                  'Parameters (${node.params.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                if (node.params.isEmpty)
                  Text(
                    'None',
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  )
                else
                  ...node.params.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ': ${p.type}',
                            style: TextStyle(fontSize: 11, color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Side Effects
                Text(
                  'Side Effects',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                if (node.sideEffects.isEmpty)
                  Text(
                    'Pure (No side effects detected)',
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: node.sideEffects
                        .map(
                          (se) => Chip(
                            label: Text(se, style: const TextStyle(fontSize: 10)),
                            backgroundColor: cs.errorContainer,
                            labelStyle: TextStyle(color: cs.onErrorContainer),
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
