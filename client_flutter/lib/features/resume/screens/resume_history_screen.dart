import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/resume_history_provider.dart';
import '../resume_history_item_dto.dart';

/// PDF History & Viewer screen.
///
/// Shows a scrollable list of compiled PDFs.
/// On narrow screens (< 720px): tapping an item navigates to a detail view.
/// On wide screens: side-by-side split: list left, pdfx viewer right.
class ResumeHistoryScreen extends ConsumerWidget {
  const ResumeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(resumeHistoryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error loading history: $err'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyHistory();
        }
        final isWide = MediaQuery.of(context).size.width >= 720;
        return isWide
            ? _WideLayout(items: items)
            : _NarrowLayout(items: items);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            'No compiled PDFs yet\nGo to Compile tab to build your first resume',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow layout (< 720px)
// ---------------------------------------------------------------------------

class _NarrowLayout extends ConsumerWidget {
  final List<ResumeHistoryItemDto> items;

  const _NarrowLayout({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => _HistoryListTile(
        item: items[i],
        onTap: () {
          ref.read(selectedHistoryItemProvider.notifier).state = items[i];
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PdfDetailPage(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout (>= 720px) — split view
// ---------------------------------------------------------------------------

class _WideLayout extends ConsumerStatefulWidget {
  final List<ResumeHistoryItemDto> items;

  const _WideLayout({required this.items});

  @override
  ConsumerState<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends ConsumerState<_WideLayout> {
  ResumeHistoryItemDto? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: history list
        SizedBox(
          width: 320,
          child: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return _HistoryListTile(
                item: item,
                selected: _selected?.exhibitId == item.exhibitId,
                onTap: () => setState(() => _selected = item),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: PDF viewer
        Expanded(
          child: _selected == null
              ? const Center(child: Text('Select a PDF to preview'))
              : _PdfViewerPanel(item: _selected!),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// History list tile
// ---------------------------------------------------------------------------

class _HistoryListTile extends StatelessWidget {
  final ResumeHistoryItemDto item;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryListTile({
    required this.item,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = item.tailorScore != null
        ? 'Match: ${(item.tailorScore! * 100).round()}%'
        : null;

    return ListTile(
      selected: selected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
      leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
      title: Text(
        '${_capitalize(item.templateId)} — ${item.formattedDate}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: score != null
          ? Text('$score · ${item.formattedDuration}')
          : Text(item.formattedDuration),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download',
            onPressed: () => _download(context, item),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () => _share(context, item),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// PDF viewer panel (used in wide split and detail page)
// ---------------------------------------------------------------------------

class _PdfViewerPanel extends StatefulWidget {
  final ResumeHistoryItemDto item;

  const _PdfViewerPanel({required this.item});

  @override
  State<_PdfViewerPanel> createState() => _PdfViewerPanelState();
}

class _PdfViewerPanelState extends State<_PdfViewerPanel> {
  PdfController? _ctrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  @override
  void didUpdateWidget(_PdfViewerPanel old) {
    super.didUpdateWidget(old);
    if (old.item.exhibitId != widget.item.exhibitId) {
      _ctrl?.dispose();
      _ctrl = null;
      setState(() {
        _loading = true;
        _error = null;
      });
      _initPdf();
    }
  }

  void _initPdf() {
    if (widget.item.vaultUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No vault URL available for this PDF.';
      });
      return;
    }

    // pdfx has no built-in HTTP URI support — download bytes, then openData.
    _loadPdfFromUrl();
  }

  Future<void> _loadPdfFromUrl() async {
    try {
      final response = await http.get(Uri.parse(widget.item.vaultUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      _ctrl = PdfController(
        document: PdfDocument.openData(response.bodyBytes),
      );
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      // URL unreachable or unsupported — offer open-in-browser fallback
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _ctrl == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_rounded,
                  size: 48, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'PDF preview unavailable',
                style: theme.textTheme.titleMedium,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              if (widget.item.vaultUrl.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => _openInBrowser(context),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open in Browser'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_capitalize(widget.item.templateId)} — ${widget.item.formattedDate}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Download',
                onPressed: () => _download(context, widget.item),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
                onPressed: () => _share(context, widget.item),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded),
                tooltip: 'Open in browser',
                onPressed: () => _openInBrowser(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PdfView(controller: _ctrl!),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _openInBrowser(BuildContext context) async {
    final uri = Uri.tryParse(widget.item.vaultUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open URL')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Detail page (narrow screens)
// ---------------------------------------------------------------------------

class _PdfDetailPage extends StatelessWidget {
  final ResumeHistoryItemDto item;

  const _PdfDetailPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${item.templateId[0].toUpperCase()}${item.templateId.substring(1)} — ${item.formattedDate}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _download(context, item),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _share(context, item),
          ),
        ],
      ),
      body: _PdfViewerPanel(item: item),
    );
  }
}

// ---------------------------------------------------------------------------
// Download & Share helpers
// ---------------------------------------------------------------------------

Future<void> _download(BuildContext context, ResumeHistoryItemDto item) async {
  if (item.vaultUrl.isEmpty) return;

  try {
    final response = await http.get(Uri.parse(item.vaultUrl));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    Directory? dir;
    if (UniversalPlatform.isWindows) {
      dir = await getDownloadsDirectory();
    } else {
      dir = await getExternalStorageDirectory();
    }
    dir ??= await getTemporaryDirectory();

    final file = File('${dir.path}/${item.fileName}');
    await file.writeAsBytes(response.bodyBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}

Future<void> _share(BuildContext context, ResumeHistoryItemDto item) async {
  if (item.vaultUrl.isEmpty) return;

  // On Windows: open in browser (no native share sheet)
  if (UniversalPlatform.isWindows) {
    final uri = Uri.tryParse(item.vaultUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  try {
    final response = await http.get(Uri.parse(item.vaultUrl));
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${item.fileName}')
      ..writeAsBytesSync(response.bodyBytes);
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: 'My Resume — ${item.fileName}',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }
}
