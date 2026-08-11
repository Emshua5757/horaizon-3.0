import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/active_entry_provider.dart';
import 'widgets/diary_block_widget.dart';
import 'widgets/diary_block_picker_bottom_sheet.dart';
import 'widgets/ai_assistant_drawer.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final String entryId;

  const DiaryEditorScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showJsonImportDialog(BuildContext context) {
    final jsonController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Import Blocks from JSON', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a JSON array of block specifications to generate blocks automatically:',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jsonController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: '''[
  { "type": "markdown", "content": { "text": "# AWS SAA Study Notes" } },
  { "type": "checkbox", "content": { "label": "Review VPC Peering", "checked": false } },
  { "type": "certification", "content": { "cert_name": "AWS SAA-C03", "status": "studying" } }
]''',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Insert Sample Template'),
                  onPressed: () {
                    jsonController.text = '''[
  { "type": "markdown", "content": { "text": "## AWS DevOps Certification Grind" } },
  { "type": "checkbox", "content": { "label": "Finish Stephane Maarek Video Course", "checked": true } },
  { "type": "checkbox", "content": { "label": "Score 85%+ on Tutorials Dojo Exam 1", "checked": false } },
  { "type": "progress", "content": { "label": "Overall Progress", "value": 0.45 } },
  { "type": "certification", "content": { "name": "AWS DevOps Engineer — Professional", "issuer": "Amazon Web Services", "status": "studying" } }
]''';
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Generate Blocks'),
                  onPressed: () async {
                    if (jsonController.text.trim().isEmpty) return;
                    try {
                      final count = await ref
                          .read(activeEntryNotifierProvider(widget.entryId).notifier)
                          .importBlocksFromJson(jsonController.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Successfully generated $count blocks from JSON!')),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('JSON Parse Error: $e'), backgroundColor: theme.colorScheme.error),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeAsync = ref.watch(activeEntryNotifierProvider(widget.entryId));

    return activeAsync.when(
      data: (activeState) {
        if (_titleController.text != activeState.entry.title) {
          _titleController.text = activeState.entry.title;
        }

        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _titleController,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Entry title...',
                border: InputBorder.none,
              ),
              onEditingComplete: () {
                ref
                    .read(activeEntryNotifierProvider(widget.entryId).notifier)
                    .updateTitle(_titleController.text);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                tooltip: 'JBC AI Copilot',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => AiAssistantDrawer(entryId: widget.entryId),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.data_object),
                tooltip: 'Import Blocks from JSON',
                onPressed: () => _showJsonImportDialog(context),
              ),
              IconButton(
                icon: Icon(
                  activeState.entry.isPrivate ? Icons.lock : Icons.lock_open_outlined,
                  color: activeState.entry.isPrivate ? theme.colorScheme.error : null,
                ),
                tooltip: 'Toggle Privacy',
                onPressed: () {
                  ref
                      .read(activeEntryNotifierProvider(widget.entryId).notifier)
                      .togglePrivate();
                },
              ),
            ],
          ),
          body: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: activeState.blocks.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final movedBlock = activeState.blocks[oldIndex];

              // 1. Instant local reorder for 100% smooth UI feedback
              ref
                  .read(activeEntryNotifierProvider(widget.entryId).notifier)
                  .reorderBlocksLocally(oldIndex, newIndex);

              // 2. Compute LexoRank neighbor IDs
              String? beforeBlockId;
              String? afterBlockId;

              if (newIndex > 0) {
                beforeBlockId = activeState.blocks[newIndex - 1].id;
              }
              if (newIndex < activeState.blocks.length - 1) {
                afterBlockId = activeState.blocks[newIndex + 1].id;
              }

              // 3. Send LexoRank update to backend API in background
              ref
                  .read(activeEntryNotifierProvider(widget.entryId).notifier)
                  .reorderBlock(movedBlock.id, beforeBlockId: beforeBlockId, afterBlockId: afterBlockId);
            },
            itemBuilder: (context, index) {
              final block = activeState.blocks[index];

              return KeyedSubtree(
                key: ValueKey(block.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.drag_indicator, color: theme.colorScheme.outlineVariant, size: 20),
                      ),
                    ),
                    Expanded(
                      child: DiaryBlockWidget(
                        block: block,
                        onChanged: (contentMap) {
                          ref
                              .read(activeEntryNotifierProvider(widget.entryId).notifier)
                              .updateBlock(block.id, contentMap);
                        },
                        onDelete: () {
                          ref
                              .read(activeEntryNotifierProvider(widget.entryId).notifier)
                              .deleteBlock(block.id);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => DiaryBlockPickerBottomSheet(
                  onBlockSelected: (blockType) {
                    ref
                        .read(activeEntryNotifierProvider(widget.entryId).notifier)
                        .createBlock(blockType);
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error opening entry: $err')),
      ),
    );
  }
}
