import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import 'providers/cert_providers.dart';

class CertEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? certToEdit;

  const CertEditorScreen({
    super.key,
    this.certToEdit,
  });

  @override
  ConsumerState<CertEditorScreen> createState() => _CertEditorScreenState();
}

class _CertEditorScreenState extends ConsumerState<CertEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _issuerController;
  late TextEditingController _examCodeController;
  late TextEditingController _notesController;
  late TextEditingController _regUrlController;

  String _status = 'planned';
  String _category = 'aws';
  DateTime? _examScheduledAt;

  @override
  void initState() {
    super.initState();
    final cert = widget.certToEdit;
    _nameController = TextEditingController(text: cert?['name'] ?? '');
    _issuerController = TextEditingController(text: cert?['issuer'] ?? 'Amazon Web Services');
    _examCodeController = TextEditingController(text: cert?['examCode'] ?? '');
    _notesController = TextEditingController(text: cert?['notes'] ?? '');
    _regUrlController = TextEditingController(text: cert?['examRegistrationUrl'] ?? '');
    _status = cert?['status'] ?? 'planned';
    _category = cert?['category'] ?? 'aws';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _examCodeController.dispose();
    _notesController.dispose();
    _regUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hbp = await ref.read(hbpClientProvider.future);
    final p = Packer()
      ..packMapLength(8)
      ..packString('name')..packString(_nameController.text)
      ..packString('issuer')..packString(_issuerController.text)
      ..packString('exam_code')..packString(_examCodeController.text)
      ..packString('status')..packString(_status)
      ..packString('category')..packString(_category)
      ..packString('notes')..packString(_notesController.text)
      ..packString('exam_registration_url')..packString(_regUrlController.text)
      ..packString('exam_scheduled_at')..packString(_examScheduledAt?.toIso8601String() ?? '');

    await hbp.send(HbpFrame.request('shua.diary', 'cert.save', p.takeBytes()));
    ref.invalidate(certDashboardProvider);
    ref.invalidate(certRoadmapProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Certification'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Certification Name *', hintText: 'e.g. AWS Solutions Architect — Associate'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuerController,
              decoration: const InputDecoration(labelText: 'Issuer *', hintText: 'e.g. Amazon Web Services'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _examCodeController,
              decoration: const InputDecoration(labelText: 'Exam Code', hintText: 'e.g. SAA-C03'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'planned', child: Text('Planned')),
                DropdownMenuItem(value: 'studying', child: Text('Studying / Grinding')),
                DropdownMenuItem(value: 'exam_scheduled', child: Text('Exam Scheduled')),
                DropdownMenuItem(value: 'passed', child: Text('Passed / Earned')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'aws', child: Text('AWS Cloud')),
                DropdownMenuItem(value: 'devops', child: Text('DevOps / Infrastructure')),
                DropdownMenuItem(value: 'security', child: Text('Security')),
                DropdownMenuItem(value: 'ai_ml', child: Text('AI / Machine Learning')),
                DropdownMenuItem(value: 'general', child: Text('General IT')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_examScheduledAt == null ? 'Schedule Exam Date' : 'Exam Date: ${_examScheduledAt!.toIso8601String().split('T').first}'),
              leading: const Icon(Icons.calendar_month),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _examScheduledAt = picked);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regUrlController,
              decoration: const InputDecoration(labelText: 'Exam Registration Link', hintText: 'Pearson VUE / PSI URL'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes / Study Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
