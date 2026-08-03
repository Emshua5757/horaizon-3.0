// File: client_flutter/lib/features/code_visualizer/presentation/widgets/symbol_inspector_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';
import '../../providers/code_topology_provider.dart';

class SymbolInspectorDrawer extends ConsumerWidget {
  final TopologyNodeModel node;
  const SymbolInspectorDrawer({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    final isStart = pathStart?.id == node.id;
    final isEnd = pathEnd?.id == node.id;

    final isMobile = MediaQuery.of(context).size.width < 600;

    final innerContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle bar for mobile
          if (isMobile)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title & Close Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.qualifiedName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    ref.read(selectedNodeProvider.notifier).state = null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${node.file}:${node.line}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Shortest Path Tracer Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isStart ? Icons.check_circle_rounded : Icons.play_arrow_rounded, size: 14),
                    label: Text(isStart ? 'Path Start' : 'Set Start', style: const TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(color: isStart ? Colors.green : cs.outlineVariant),
                    ),
                    onPressed: () {
                      ref.read(pathStartNodeProvider.notifier).state = isStart ? null : node;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isEnd ? Icons.check_circle_rounded : Icons.flag_rounded, size: 14),
                    label: Text(isEnd ? 'Path End' : 'Set End', style: const TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(color: isEnd ? Colors.green : cs.outlineVariant),
                    ),
                    onPressed: () {
                      ref.read(pathEndNodeProvider.notifier).state = isEnd ? null : node;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Insight Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (node.isGodFunction)
                  _badge('👑 God Function', const Color(0xFFAB47BC)),
                if (node.isDeadCode)
                  _badge('💀 Dead Code', const Color(0xFF757575)),
                if (node.isHighRisk)
                  _badge('⚠️ High Risk', const Color(0xFFEF5350)),
                if (node.isHub) _badge('🔥 Hub', const Color(0xFFFFA726)),
                if (node.isPublic) _badge('Public', const Color(0xFF42A5F5)),
                if (node.isTest) _badge('Test', const Color(0xFF26A69A)),
              ],
            ),
            const SizedBox(height: 18),

            _metricRow('Complexity', node.complexity.toString(),
                warn: node.exceedsComplexityThreshold),
            _metricRow('Lines of Code', node.loc.toString(),
                warn: node.exceedsLocThreshold),
            _metricRow('Params', node.params.length.toString(),
                warn: node.exceedsParamThreshold),
            _metricRow('Fan In', node.fanIn.toString()),
            _metricRow('Fan Out', node.fanOut.toString()),
            _metricRow('Risk Score', node.riskScore.toStringAsFixed(1),
                warn: node.riskScore >= 7.0),
            if (node.returnType != null)
              _metricRow('Returns', node.returnType!),
            const SizedBox(height: 16),
            if (node.intent != null) ...[
              Text(
                'Intent',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(node.intent!, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
            ],
            if (node.params.isNotEmpty) ...[
              Text(
                'Parameters',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ...node.params.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${p.name}: ${p.type}${p.isOptional ? '?' : ''}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (node.sideEffects.isNotEmpty) ...[
              Text(
                'Side Effects',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: node.sideEffects
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );

    if (isMobile) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 220),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: cs.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: innerContent,
      );
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: innerContent,
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: warn ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
