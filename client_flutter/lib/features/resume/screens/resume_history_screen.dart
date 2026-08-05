import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:messagepack/messagepack.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../providers/resume_history_provider.dart';
import '../resume_history_item_dto.dart';

/// PDF History & Viewer screen.
///
/// Shows a scrollable list of compiled PDFs.
/// On narrow screens (< 720px): tapping an item navigates to a detail view.
/// On wide screens: side-by-side split: list left, viewer right.
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
          _ExportMarkdownButton(itemDate: item.formattedDate),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
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
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _hasError = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(_PdfViewerPanel old) {
    super.didUpdateWidget(old);
    // Reset state when a new PDF is selected
    if (old.item.exhibitId != widget.item.exhibitId) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.item.vaultUrl.isEmpty) {
      return _buildErrorState(context, 'No vault URL available for this PDF.');
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
                tooltip: 'Download PDF',
                onPressed: () => _download(context, widget.item),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
                onPressed: () => _share(context, widget.item),
              ),
              _ExportMarkdownButton(itemDate: widget.item.formattedDate),
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded),
                tooltip: 'Open in browser',
                onPressed: () => _openInBrowser(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Built-in External PDF Viewer
        Expanded(
          child: _hasError
              ? _buildErrorState(context, _errorMessage ?? 'Failed to load PDF')
              : SfPdfViewer.network(
                  widget.item.vaultUrl,
                  controller: _pdfViewerController,
                  canShowScrollHead: false,
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = details.description;
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String errorText) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'PDF preview unavailable',
              style: theme.textTheme.titleMedium,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                errorText,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
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
          _ExportMarkdownButton(itemDate: item.formattedDate),
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
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

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

// ---------------------------------------------------------------------------
// Export as Markdown — calls shua.resume.export.markdown HBP op
// ---------------------------------------------------------------------------

/// Stateful button that manages in-progress / done / error state for the
/// export.markdown RPC call.
class _ExportMarkdownButton extends ConsumerStatefulWidget {
  /// Used to name the output file: `resume_<itemDate>.md`
  final String itemDate;

  const _ExportMarkdownButton({required this.itemDate});

  @override
  ConsumerState<_ExportMarkdownButton> createState() =>
      _ExportMarkdownButtonState();
}

class _ExportMarkdownButtonState
    extends ConsumerState<_ExportMarkdownButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Export as Markdown',
            onPressed: () => _export(context),
          );
  }

  Future<void> _export(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final frame =
          HbpFrame.request('shua.resume', 'export.markdown', []);
      final resp = await hbp.send(frame,
          timeout: const Duration(seconds: 30));

      if (resp.isError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: ${resp.error}')),
          );
        }
        return;
      }

      final md = _decodeMarkdownPayload(resp.payload);
      if (md == null || md.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export returned empty content')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      await _saveOrShareMarkdown(context, md, widget.itemDate);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Decode the export.markdown response payload.
/// The Go handler returns: { "1": "<markdown string>" }
String? _decodeMarkdownPayload(List<int> bytes) {
  if (bytes.isEmpty) return null;
  try {
    final u = Unpacker(Uint8List.fromList(bytes));
    final len = u.unpackMapLength();
    for (var i = 0; i < len; i++) {
      final key = u.unpackString();
      final val = u.unpackString();
      if (key == '1') return val;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> _saveOrShareMarkdown(
    BuildContext context, String md, String itemDate) async {
  // Sanitize date for filename: replace spaces/: with _
  final safeName = 'resume_${itemDate.replaceAll(RegExp(r'[^\w]+'), '_')}.md';
  final mdBytes = md.codeUnits;

  if (UniversalPlatform.isWindows) {
    // Save to Downloads directory
    Directory? dir = await getDownloadsDirectory();
    dir ??= await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(mdBytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Markdown saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              final uri = Uri.file(file.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ),
      );
    }
    return;
  }

  // Mobile / other: share via share_plus
  try {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$safeName')
      ..writeAsBytesSync(mdBytes);
    await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: 'text/markdown')],
      text: 'Resume Markdown Export',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }
}
