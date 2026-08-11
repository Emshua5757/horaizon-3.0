import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/cert_dtos.dart';

class CertDetailScreen extends ConsumerWidget {
  final CertEntryDto cert;

  const CertDetailScreen({
    super.key,
    required this.cert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(cert.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cert.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(cert.issuer, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const Divider(height: 24),
                  _buildDetailRow('Status', cert.status.replaceAll('_', ' ').toUpperCase()),
                  _buildDetailRow('Category', cert.category.toUpperCase()),
                  if (cert.examCode.isNotEmpty) _buildDetailRow('Exam Code', cert.examCode),
                  if (cert.examScheduledAt != null) _buildDetailRow('Exam Date', cert.examScheduledAt!.toIso8601String().split('T').first),
                  if (cert.examVenue.isNotEmpty) _buildDetailRow('Venue', cert.examVenue),
                  if (cert.credentialId.isNotEmpty) _buildDetailRow('Credential ID', cert.credentialId),
                  if (cert.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notes', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(cert.notes, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
