import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../governor/governor_provider.dart';
import 'microservice_card.dart';

/// Supervised Microservices Grid section matching Google Stitch specifications,
/// dynamically adapting to active Theme Preset and AppSemanticPalette.
class MicroservicesSection extends StatelessWidget {
  final GovernorStatus status;
  final bool isDesktop;

  const MicroservicesSection({
    super.key,
    required this.status,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();

    final successColor = semantic?.success ?? cs.primary;
    final warningColor = semantic?.warning ?? cs.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Text(
              'Supervised Microservices',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(cgroups v2 Power Control)',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Microservices Layout (3 Columns on Desktop, 1 Column on Mobile)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MicroserviceCard(
                  name: 'shua_diary',
                  title: 'shua_diary',
                  icon: Icons.book_rounded,
                  accentColor: successColor,
                  status: status,
                  ramText: '142 MB RAM',
                  subText: '384 Entries',
                  buttonLabel: 'Launch Diary',
                  onLaunch: () => context.go('/diary'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MicroserviceCard(
                  name: 'shua_code_viz',
                  title: 'shua_code_viz',
                  icon: Icons.code_rounded,
                  accentColor: warningColor,
                  status: status,
                  ramText: '0 MB RAM (Frozen)',
                  subText: '-',
                  buttonLabel: '▷ Wake & Launch',
                  onLaunch: () => context.go('/code/topology'),
                  isSigstop: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MicroserviceCard(
                  name: 'shua_resume',
                  title: 'shua_resume',
                  icon: Icons.description_rounded,
                  accentColor: successColor,
                  status: status,
                  ramText: '88 MB RAM',
                  subText: '4 Exhibits',
                  buttonLabel: 'Launch Builder',
                  onLaunch: () => context.go('/resume/editor'),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              MicroserviceCard(
                name: 'shua_diary',
                title: 'shua_diary',
                icon: Icons.book_rounded,
                accentColor: successColor,
                status: status,
                ramText: '142 MB RAM',
                subText: '384 Entries',
                buttonLabel: 'Launch Diary',
                onLaunch: () => context.go('/diary'),
              ),
              const SizedBox(height: 12),
              MicroserviceCard(
                name: 'shua_code_viz',
                title: 'shua_code_viz',
                icon: Icons.code_rounded,
                accentColor: warningColor,
                status: status,
                ramText: '0 MB RAM (Frozen)',
                subText: '-',
                buttonLabel: '▷ Wake & Launch',
                onLaunch: () => context.go('/code/topology'),
                isSigstop: true,
              ),
              const SizedBox(height: 12),
              MicroserviceCard(
                name: 'shua_resume',
                title: 'shua_resume',
                icon: Icons.description_rounded,
                accentColor: successColor,
                status: status,
                ramText: '88 MB RAM',
                subText: '4 Exhibits',
                buttonLabel: 'Launch Builder',
                onLaunch: () => context.go('/resume/editor'),
              ),
            ],
          ),
      ],
    );
  }
}
