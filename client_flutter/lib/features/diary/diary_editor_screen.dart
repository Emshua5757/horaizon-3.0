import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/active_entry_provider.dart';
import 'widgets/diary_block_widget.dart';
import 'widgets/diary_block_picker_bottom_sheet.dart';

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
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final movedBlock = activeState.blocks[oldIndex];

              String? beforeBlockId;
              String? afterBlockId;

              if (newIndex > 0) {
                beforeBlockId = activeState.blocks[newIndex - 1].id;
              }
              if (newIndex < activeState.blocks.length - 1) {
                afterBlockId = activeState.blocks[newIndex + 1].id;
              }

              ref
                  .read(activeEntryNotifierProvider(widget.entryId).notifier)
                  .reorderBlock(movedBlock.id, beforeBlockId: beforeBlockId, afterBlockId: afterBlockId);
            },
            itemBuilder: (context, index) {
              final block = activeState.blocks[index];

              return KeyedSubtree(
                key: ValueKey(block.id),
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
