import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import 'providers/cert_providers.dart';

class InvestmentSummaryScreen extends ConsumerWidget {
  const InvestmentSummaryScreen({super.key});

  void _showAddInvestmentDialog(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'exam_fee';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Self-Investment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. SAA-C03 Exam Fee'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount in PHP (₱)', hintText: 'e.g. 8500'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'exam_fee', child: Text('Exam Fee')),
                DropdownMenuItem(value: 'course', child: Text('Course / Training')),
                DropdownMenuItem(value: 'book', child: Text('Book / Material')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment / Hardware')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => type = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (descController.text.trim().isEmpty || amount <= 0) return;

              final hbp = await ref.read(hbpClientProvider.future);
              final p = Packer()
                ..packMapLength(4)
                ..packString('description')..packString(descController.text)
                ..packString('amount_php')..packDouble(amount)
                ..packString('type')..packString(type)
                ..packString('paid_at')..packString(DateTime.now().toIso8601String());

              await hbp.send(HbpFrame.request('shua.diary', 'cert.investment.save', p.takeBytes()));
              ref.invalidate(certInvestmentsProvider);
              ref.invalidate(certDashboardProvider);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invAsync = ref.watch(certInvestmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Investment Tracker'),
      ),
      body: invAsync.when(
        data: (items) {
          final total = items.fold(0.0, (sum, i) => sum + i.amountPhp);

          return Column(
            children: [
              // Hero Summary Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('TOTAL INVESTED IN YOURSELF', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 4),
                    Text('Data Annotation Earnings → Certification Journey', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No investments logged yet. Tap + to log an expense.'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                              title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item.type.toUpperCase()} • ${item.paidAt.toIso8601String().split('T').first}'),
                              trailing: Text('₱${item.amountPhp.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Investments error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Log Expense'),
        onPressed: () => _showAddInvestmentDialog(context, ref),
      ),
    );
  }
}
