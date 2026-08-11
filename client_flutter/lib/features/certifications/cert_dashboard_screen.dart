import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/cert_providers.dart';
import 'cert_roadmap_screen.dart';
import 'cert_editor_screen.dart';
import 'investment_summary_screen.dart';

class CertDashboardScreen extends ConsumerWidget {
  const CertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashAsync = ref.watch(certDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certification Roadmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Timeline View',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertRoadmapScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Investments',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentSummaryScreen())),
          ),
        ],
      ),
      body: dashAsync.when(
        data: (dash) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(certDashboardProvider.future),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Countdown Card (if exam scheduled)
                  if (dash.nextExam != null)
                    _buildExamCountdownCard(context, theme, dash.nextExam!, dash.nextExamDaysUntil ?? 0)
                  else
                    _buildNoExamCard(context, theme),

                  const SizedBox(height: 20),

                  // 2. Stats summary cards row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Total Certs',
                          dash.totalCerts.toString(),
                          Icons.workspace_premium,
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Active Grinding',
                          (dash.byStatus['studying'] ?? 0).toString(),
                          Icons.menu_book,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Earned',
                          (dash.byStatus['passed'] ?? 0).toString(),
                          Icons.verified,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Investment strip
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentSummaryScreen())),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on_outlined, color: theme.colorScheme.onTertiaryContainer, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Self-Investment', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
                                Text('₱${dash.totalInvestedPhp.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onTertiaryContainer)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Roadmap preview section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Roadmap Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertRoadmapScreen())),
                        child: const Text('View Full Timeline →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (dash.roadmap.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No certifications added yet')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dash.roadmap.length,
                      itemBuilder: (context, idx) {
                        final cert = dash.roadmap[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${idx + 1}'),
                            ),
                            title: Text(cert.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${cert.issuer} • ${cert.status.toUpperCase()}'),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Dashboard error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Cert'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CertEditorScreen()));
        },
      ),
    );
  }

  Widget _buildExamCountdownCard(BuildContext context, ThemeData theme, dynamic cert, int daysLeft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: const Text('UPCOMING EXAM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                side: BorderSide.none,
              ),
              Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Text(cert.name as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '$daysLeft DAYS LEFT',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled: ${(cert.examScheduledAt as DateTime).toIso8601String().split('T').first} (${cert.examVenue})',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExamCard(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No Exam Scheduled', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Select a certification from your roadmap to schedule your exam.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
