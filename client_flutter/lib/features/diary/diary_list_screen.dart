import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/diary_list_provider.dart';
import 'providers/diary_search_provider.dart';
import 'models/diary_entry_dto.dart';
import 'diary_editor_screen.dart';

class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(diaryListProvider);
    final searchQuery = ref.watch(diarySearchQueryProvider);
    final searchAsync = ref.watch(diarySearchResultsProvider);

    final isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shua Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: 'Certification Roadmap',
            onPressed: () => Navigator.pushNamed(context, '/certs'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search entries and blocks (FTS5)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(diarySearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (val) {
                ref.read(diarySearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Search results or entry list
          Expanded(
            child: isSearching
                ? searchAsync.when(
                    data: (results) => _buildSearchResults(results, theme),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Search error: $err')),
                  )
                : listAsync.when(
                    data: (entries) => _buildEntryList(entries, theme),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Failed to load entries: $err')),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        onPressed: () async {
          final newEntry = await ref.read(diaryListProvider.notifier).createEntry();
          if (newEntry != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DiaryEditorScreen(entryId: newEntry.id)),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchResults(List<DiarySearchResultDto> results, ThemeData theme) {
    if (results.isEmpty) {
      return const Center(child: Text('No matching entries found'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              item.snippet ?? item.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: item.isGloballyElevated ? Icon(Icons.push_pin, color: theme.colorScheme.primary, size: 18) : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DiaryEditorScreen(entryId: item.id)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEntryList(List<DiaryEntryDto> entries, ThemeData theme) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Your diary is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + New Entry to write your first entry', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(diaryListProvider.future),
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: entry.isPrivate ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
                child: Icon(
                  entry.isPrivate ? Icons.lock_outline : Icons.article_outlined,
                  color: entry.isPrivate ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Row(
                children: [
                  if (entry.isGloballyElevated) ...[
                    Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(child: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.preview.isNotEmpty)
                    Text(entry.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    entry.loggedAt.toIso8601String().split('T').first,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  ref.read(diaryListProvider.notifier).deleteEntry(entry.id);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DiaryEditorScreen(entryId: entry.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
