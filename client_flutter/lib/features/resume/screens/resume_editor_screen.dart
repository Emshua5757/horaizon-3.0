import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../core/hbp/hbp_client.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';
import '../widgets/award_item_card.dart';
import '../widgets/certificate_item_card.dart';
import '../widgets/education_item_card.dart';
import '../widgets/org_item_card.dart';
import '../widgets/project_item_card.dart';
import '../widgets/resume_section_tab.dart';
import '../widgets/skill_chip_row.dart';
import '../widgets/work_item_card.dart';

/// 8-tab CRUD matrix editor for the resume data.
///
/// Tabs: Basics | Experience | Projects | Skills | Education | Certs | Awards | Org Exp
///
/// Each list tab supports: inline expand-to-edit, 800ms debounced auto-save,
/// FAB add, swipe-to-dismiss delete (optimistic UI).
class ResumeEditorScreen extends ConsumerWidget {
  const ResumeEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ??
        HbpConnectionState.disconnected;
    final isOffline = connState != HbpConnectionState.connected;

    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          // ── Offline banner ─────────────────────────────────────────────
          if (isOffline)
            MaterialBanner(
              content: const Text('Pi 5 offline — Resume data unavailable'),
              backgroundColor: const Color(0xFFFFF3E0),
              leading:
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFA000)),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Dismiss')),
              ],
            ),

          // ── Tab bar ────────────────────────────────────────────────────
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Basics'),
              Tab(text: 'Experience'),
              Tab(text: 'Projects'),
              Tab(text: 'Skills'),
              Tab(text: 'Education'),
              Tab(text: 'Certs'),
              Tab(text: 'Awards'),
              Tab(text: 'Org Exp'),
            ],
          ),

          // ── Tab views ──────────────────────────────────────────────────
          Expanded(
            child: ref.watch(resumeMatrixProvider).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _ErrorState(message: err.toString()),
                  data: (matrix) => TabBarView(
                    children: [
                      _BasicsTab(matrix: matrix),
                      _WorkTab(matrix: matrix),
                      _ProjectsTab(matrix: matrix),
                      _SkillsTab(matrix: matrix),
                      _EducationTab(matrix: matrix),
                      _CertsTab(matrix: matrix),
                      _AwardsTab(matrix: matrix),
                      _OrgsTab(matrix: matrix),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Basics tab (single-record form)
// ---------------------------------------------------------------------------

class _BasicsTab extends ConsumerStatefulWidget {
  final ResumeMatrixDto matrix;

  const _BasicsTab({required this.matrix});

  @override
  ConsumerState<_BasicsTab> createState() => _BasicsTabState();
}

class _BasicsTabState extends ConsumerState<_BasicsTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _regionCtrl;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final b = widget.matrix.basics;
    _nameCtrl = TextEditingController(text: b.name);
    _labelCtrl = TextEditingController(text: b.label);
    _emailCtrl = TextEditingController(text: b.email);
    _phoneCtrl = TextEditingController(text: b.phone);
    _urlCtrl = TextEditingController(text: b.url);
    _summaryCtrl = TextEditingController(text: b.summary);
    _cityCtrl = TextEditingController(text: b.location.city);
    _regionCtrl = TextEditingController(text: b.location.region);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _labelCtrl,
      _emailCtrl,
      _phoneCtrl,
      _urlCtrl,
      _summaryCtrl,
      _cityCtrl,
      _regionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(resumeMatrixProvider.notifier).upsertSection('basics', {
      'name': _nameCtrl.text,
      'label': _labelCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'url': _urlCtrl.text,
      'summary': _summaryCtrl.text,
      'location': {
        'city': _cityCtrl.text,
        'region': _regionCtrl.text,
        'country_code': widget.matrix.basics.location.countryCode,
      },
      'profiles': widget.matrix.basics.profiles.map((p) => p.toMap()).toList(),
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _saved = false);
  }

  void _addProfile() {
    setState(() {
      widget.matrix.basics.profiles.add(
        const ProfileDto(network: '', username: '', url: ''),
      );
    });
    _save();
  }

  void _removeProfile(int index) {
    setState(() {
      widget.matrix.basics.profiles.removeAt(index);
    });
    _save();
  }

  void _updateProfile(int index, ProfileDto updated) {
    setState(() {
      widget.matrix.basics.profiles[index] = updated;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Saved', style: TextStyle(color: cs.primary)),
                ],
              ),
            ),
          _field('Full Name', _nameCtrl),
          _field('Label / Headline', _labelCtrl),
          _field('Email', _emailCtrl, keyboard: TextInputType.emailAddress),
          _field('Phone', _phoneCtrl, keyboard: TextInputType.phone),
          _field('Professional Summary', _summaryCtrl, maxLines: 4),
          const SizedBox(height: 8),
          Text('Location',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field('City', _cityCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _field('Region', _regionCtrl)),
          ]),
          const SizedBox(height: 16),
          // ── Profile Links ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Profile Links',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: cs.outline)),
              ),
              TextButton.icon(
                onPressed: _addProfile,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Link'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'e.g. GitHub, LinkedIn, Portfolio — these appear in the resume header',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          ...List.generate(widget.matrix.basics.profiles.length, (i) {
            final p = widget.matrix.basics.profiles[i];
            return _ProfileLinkRow(
              key: ValueKey('profile_$i'),
              initial: p,
              onRemove: () => _removeProfile(i),
              onChanged: (updated) => _updateProfile(i, updated),
            );
          }),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Basics'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
        ),
      );
}

// ---------------------------------------------------------------------------
// List tabs (Experience, Projects, Skills, Education, Certs, Awards)
// ---------------------------------------------------------------------------

class _WorkTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _WorkTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Experience',
        isEmpty: matrix.work.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.work_outline_rounded,
          message: 'No experience yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('work', newBlankWorkItem().toMap()),
        child: Column(
          children: matrix.work
              .map((w) => WorkItemCard(key: ValueKey(w.id), item: w))
              .toList(),
        ),
      );
}

class _ProjectsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _ProjectsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Project',
        isEmpty: matrix.projects.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.folder_open_rounded,
          message: 'No projects yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('projects', newBlankProjectItem().toMap()),
        child: Column(
          children: matrix.projects
              .map((p) => ProjectItemCard(key: ValueKey(p.id), item: p))
              .toList(),
        ),
      );
}

class _SkillsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _SkillsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Skill Group',
        isEmpty: matrix.skills.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.code_rounded,
          message: 'No skill groups yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('skills', newBlankSkill().toMap()),
        child: Column(
          children: matrix.skills
              .map((s) => SkillChipRow(key: ValueKey(s.id), item: s))
              .toList(),
        ),
      );
}

class _EducationTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _EducationTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Education',
        isEmpty: matrix.education.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.school_rounded,
          message: 'No education entries yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('education', newBlankEducation().toMap()),
        child: Column(
          children: matrix.education
              .map((e) => EducationItemCard(key: ValueKey(e.id), item: e))
              .toList(),
        ),
      );
}

class _CertsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _CertsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Certificate',
        isEmpty: matrix.certificates.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.verified_outlined,
          message: 'No certificates yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('certificates', newBlankCertificate().toMap()),
        child: Column(
          children: matrix.certificates
              .map((c) => CertificateItemCard(key: ValueKey(c.id), item: c))
              .toList(),
        ),
      );
}

class _AwardsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _AwardsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Award',
        isEmpty: matrix.awards.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.emoji_events_outlined,
          message: 'No awards yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('awards', newBlankAward().toMap()),
        child: Column(
          children: matrix.awards
              .map((a) => AwardItemCard(key: ValueKey(a.id), item: a))
              .toList(),
        ),
      );
}

class _OrgsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _OrgsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Org Experience',
        isEmpty: matrix.organizations.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.groups_rounded,
          message: 'No org experience yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('organizations', newBlankOrgItem().toMap()),
        child: Column(
          children: matrix.organizations
              .map((o) => OrgItemCard(key: ValueKey(o.id), item: o))
              .toList(),
        ),
      );
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile link row (Basics tab — dynamic social profile editor)
// ---------------------------------------------------------------------------

class _ProfileLinkRow extends StatefulWidget {
  final ProfileDto initial;
  final VoidCallback onRemove;
  final ValueChanged<ProfileDto> onChanged;

  const _ProfileLinkRow({
    super.key,
    required this.initial,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ProfileLinkRow> createState() => _ProfileLinkRowState();
}

class _ProfileLinkRowState extends State<_ProfileLinkRow> {
  late TextEditingController _networkCtrl;
  late TextEditingController _urlCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _networkCtrl = TextEditingController(text: widget.initial.network);
    _urlCtrl = TextEditingController(text: widget.initial.url);
    _networkCtrl.addListener(_onChanged);
    _urlCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _networkCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      widget.onChanged(
        ProfileDto(
          network: _networkCtrl.text,
          username: widget.initial.username,
          url: _urlCtrl.text,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _networkCtrl,
              decoration: const InputDecoration(
                labelText: 'Network',
                hintText: 'GitHub',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://github.com/username',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: cs.outline, size: 20),
            onPressed: widget.onRemove,
            tooltip: 'Remove link',
          ),
        ],
      ),
    );
  }
}
