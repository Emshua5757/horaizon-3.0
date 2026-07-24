import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/network/media_uploader.dart';
import 'package:client_flutter/app/settings/config_provider.dart';

/// SduiDocumentViewer — Type ID 29
///
/// Renders a PDF document from a URL or a local file path using
/// `syncfusion_flutter_pdfviewer` (already in the Syncfusion family used by
/// SduiChart and SduiGauge).
///
/// Behavior keys consumed:
///   INTERACTIVE_MODE  (95) — 0=readonly (no toolbar), 1=full toolbar + picker affordance.
///   ALLOW_ZOOM        (118)— 0=no pan/zoom (static view), 1=pinch-zoom enabled (default 1).
///   ACCENT_COLOR_TOKEN(96) — Toolbar and page-indicator accent color.
///   HEIGHT            (33) — Explicit viewer height (required when inside an unbounded parent).
///   PADDING           (30) — Outer padding.
///   BIND_KEY          (40) — State vault key (stores currently selected PDF path or URL).
///
/// Content keys consumed:
///   SRC         (5) — URL or absolute local path to the PDF.
///   LABEL       (1) — Optional card header label.
///   PLACEHOLDER (2) — Text shown in the empty upload box (editable mode).
///
/// Source priority: StateVault (BIND_KEY) > SRC content key.
class SduiDocumentViewer extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiDocumentViewer({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiDocumentViewer> createState() => _SduiDocumentViewerState();
}

class _SduiDocumentViewerState extends ConsumerState<SduiDocumentViewer> {
  // Syncfusion controller: exposes page navigation, jump-to-page, search.
  final PdfViewerController _pdfController = PdfViewerController();

  String? _loadedPath; // The path that the current controller is bound to.
  bool _hasError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // ── File Picker ────────────────────────────────────────────────────────────

  void _showPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bindKey =
        widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select PDF Document',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Select Local PDF File...'),
                  subtitle: const Text('Browse your device for a .pdf file'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref
                        .read(mediaUploaderProvider)
                        .pickAndUploadWithUi(
                          context: context,
                          ref: ref,
                          bindKey: bindKey,
                          fileType: FileType.custom,
                          allowedExtensions: ['pdf'],
                          moduleOwner: 'sdui_document_viewer',
                          dispatcher: widget.dispatcher,
                        );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.link_rounded,
                    color: colorScheme.secondary,
                  ),
                  title: const Text('Enter Remote PDF URL (Dev Mode)'),
                  subtitle: const Text(
                    'Update the SRC content key server-side to load a remote PDF',
                  ),
                  // Remote URL entry in a dev-mode context; user updates server-side.
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // ── Behavior Resolution ──────────────────────────────────────────────────
    final int interactiveMode =
        node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final int allowZoom = node.behavior<int>(HbpBehavior.ALLOW_ZOOM) ?? 1;
    final int? accentColorToken = node.behavior<int>(
      HbpBehavior.ACCENT_COLOR_TOKEN,
    );
    final double height =
        node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble() ??
        node.behavior<double>(HbpBehavior.HEIGHT) ??
        400.0; // PDF viewers need a bounded height.
    final EdgeInsetsGeometry padding =
        SduiStyleResolver.resolveEdgeInsets(
          node.behavior<dynamic>(HbpBehavior.PADDING),
        ) ??
        EdgeInsets.zero;
    final String bindKey =
        node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;

    final Color accentColor =
        SduiStyleResolver.resolveColor(context, accentColorToken) ??
        colorScheme.primary;

    // ── Content Resolution (StateVault > SRC) ────────────────────────────────
    final String? vaultValue = ref.watch(
      sduiStateVaultProvider.select((s) => s[bindKey] as String?),
    );
    final String? initialSrc = node.contentVal<String>(HbpContent.SRC);
    final String? rawPath = (vaultValue != null && vaultValue.isNotEmpty)
        ? vaultValue
        : initialSrc;
    String? currentPath = rawPath;
    if (currentPath != null && currentPath.startsWith('/')) {
      final baseUrl = ref.read(systemConfigProvider).syncBaseUrl;
      currentPath = '$baseUrl$currentPath';
    }
    final String? label = node.contentVal<String>(HbpContent.LABEL);
    final String? placeholder = node.contentVal<String>(HbpContent.PLACEHOLDER);

    // Detect a path change → reset error state so the viewer rebuilds with new source.
    if (currentPath != _loadedPath) {
      _loadedPath = currentPath;
      _hasError = false;
      _errorMessage = null;
    }

    // ── Widget Assembly ──────────────────────────────────────────────────────
    Widget buildContent() {
      // No source — show the appropriate empty state.
      if (currentPath == null || currentPath.isEmpty) {
        if (interactiveMode == 1) {
          return _buildUploadBox(
            colorScheme,
            theme,
            height,
            placeholder,
            label,
          );
        }
        return _buildEmptyReadonly(colorScheme, theme, height);
      }

      // Error state (onDocumentLoadFailed fires below).
      if (_hasError) {
        return _buildErrorState(colorScheme, theme, height, _errorMessage);
      }

      // ── Syncfusion PDF Viewer ────────────────────────────────────────────
      // SfPdfViewer.network and SfPdfViewer.file auto-detect; we branch for clarity.
      final Widget pdfViewer;
      final bool isNetwork =
          currentPath.startsWith('http://') ||
          currentPath.startsWith('https://');

      if (isNetwork) {
        pdfViewer = SfPdfViewer.network(
          currentPath,
          controller: _pdfController,
          enableDoubleTapZooming: allowZoom == 1,
          enableDocumentLinkAnnotation: true,
          canShowPaginationDialog: interactiveMode == 1,
          canShowScrollHead: interactiveMode == 1,
          canShowScrollStatus: interactiveMode == 1,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = details.description;
                  });
                }
              });
            }
          },
        );
      } else {
        pdfViewer = SfPdfViewer.file(
          io.File(currentPath),
          controller: _pdfController,
          enableDoubleTapZooming: allowZoom == 1,
          enableDocumentLinkAnnotation: true,
          canShowPaginationDialog: interactiveMode == 1,
          canShowScrollHead: interactiveMode == 1,
          canShowScrollStatus: interactiveMode == 1,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = details.description;
                  });
                }
              });
            }
          },
        );
      }

      // SfPdfViewer requires a bounded height — wrap in SizedBox.
      final Widget viewer = SizedBox(height: height, child: pdfViewer);

      // In editable mode overlay a floating "Change PDF" badge.
      if (interactiveMode == 1) {
        return Stack(
          children: [
            viewer,
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showPicker(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Change PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Page navigation toolbar strip (editable mode only).
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withAlpha(160)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                      tooltip: 'Previous page',
                      onPressed: () {
                        if (_pdfController.pageNumber > 1) {
                          _pdfController.previousPage();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                      tooltip: 'Next page',
                      onPressed: () {
                        if (_pdfController.pageNumber <
                            _pdfController.pageCount) {
                          _pdfController.nextPage();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      return viewer;
    }

    Widget content = Padding(padding: padding, child: buildContent());

    // ── Card Wrap ────────────────────────────────────────────────────────────
    if (label != null && label.isNotEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              content,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: content,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Widget _buildUploadBox(
    ColorScheme colorScheme,
    ThemeData theme,
    double height,
    String? placeholder,
    String? label,
  ) {
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: colorScheme.outline.withAlpha(128),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                placeholder ?? label ?? 'Load PDF Document',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyReadonly(
    ColorScheme colorScheme,
    ThemeData theme,
    double height,
  ) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(width: 8),
            Text(
              'No Document Source',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(128),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ColorScheme colorScheme,
    ThemeData theme,
    double height,
    String? message,
  ) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: colorScheme.errorContainer),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 28),
          const SizedBox(height: 8),
          Text(
            'Failed to load PDF document',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          if (widget.node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) == 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Retry'),
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = null;
                      // Force a rebuild by resetting _loadedPath.
                      _loadedPath = null;
                    });
                  },
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.folder_open_rounded, size: 14),
                  label: const Text('Try Another File'),
                  onPressed: () => _showPicker(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
