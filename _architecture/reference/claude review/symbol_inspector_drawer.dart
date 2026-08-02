// File: client_flutter/lib/features/code_visualizer/presentation/widgets/symbol_inspector_drawer.dart

import 'package:flutter/material.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';

class SymbolInspectorDrawer extends StatelessWidget {
  final TopologyNodeModel node;
  const SymbolInspectorDrawer({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.qualifiedName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${node.file}:${node.line}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
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
              Text(node.intent!, style: const TextStyle(fontSize: 13)),
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
                    '${p.name}: ${p.typeName}${p.isOptional ? '?' : ''}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
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
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: warn ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}
