import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/cert_providers.dart';
import 'models/cert_dtos.dart';

class CertRoadmapScreen extends ConsumerWidget {
  const CertRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roadmapAsync = ref.watch(certRoadmapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certification Timeline'),
      ),
      body: roadmapAsync.when(
        data: (certs) {
          if (certs.isEmpty) {
            return const Center(child: Text('No certifications on timeline'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certs.length,
            itemBuilder: (context, idx) {
              final cert = certs[idx];
              final isLast = idx == certs.length - 1;
              return _buildTimelineNode(context, theme, cert, idx + 1, isLast);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Timeline error: $err')),
      ),
    );
  }

  Widget _buildTimelineNode(BuildContext context, ThemeData theme, CertEntryDto cert, int index, bool isLast) {
    Color statusColor;
    IconData statusIcon;

    switch (cert.status) {
      case 'passed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'exam_scheduled':
        statusColor = Colors.orange;
        statusIcon = Icons.event;
        break;
      case 'studying':
        statusColor = Colors.blue;
        statusIcon = Icons.menu_book;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.outlined_flag;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline node & vertical line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('STEP $index', style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text(cert.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: statusColor.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(cert.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(cert.issuer, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (cert.examScheduledAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Exam: ${cert.examScheduledAt!.toIso8601String().split('T').first}',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
