import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/network/media_uploader.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

/// SduiHtmlViewer — Type ID 31
///
/// Renders an HTML string as a Flutter widget tree using `flutter_html`.
class SduiHtmlViewer extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiHtmlViewer({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiHtmlViewer> createState() => _SduiHtmlViewerState();
}

class _SduiHtmlViewerState extends ConsumerState<SduiHtmlViewer> {
  String? _loadedFileHtml;
  bool _isLoadingFile = false;
  bool _hasFileError = false;
  String? _lastLoadedSrc;
  bool _isEditing = false;
  late TextEditingController _htmlController;

  @override
  void initState() {
    super.initState();
    final String? inlineHtml = widget.node.contentVal<String>(HbpContent.VALUE);
    _htmlController = TextEditingController(text: inlineHtml ?? '');
  }

  @override
  void didUpdateWidget(covariant SduiHtmlViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.id != oldWidget.node.id) {
      final String? inlineHtml = widget.node.contentVal<String>(
        HbpContent.VALUE,
      );
      _htmlController.text = inlineHtml ?? '';
    }
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  /// Attempts to load HTML content from a local file path.
  Future<void> _loadHtmlFile(String src) async {
    if (src == _lastLoadedSrc) return;
    if (mounted) {
      setState(() {
        _isLoadingFile = true;
        _hasFileError = false;
        _lastLoadedSrc = src;
      });
    }
    try {
      final String content = await io.File(src).readAsString();
      if (mounted && _lastLoadedSrc == src) {
        setState(() {
          _loadedFileHtml = content;
          _isLoadingFile = false;
          _htmlController.text = content;
        });
      }
    } catch (e) {
      gLog.log(
        HbpLogLevel.ERROR,
        'sdui_html_viewer',
        'Failed to read file $src: $e',
        tags: HbpLogTag.SDUI | HbpLogTag.DATABASE,
      );
      if (mounted && _lastLoadedSrc == src) {
        setState(() {
          _isLoadingFile = false;
          _hasFileError = true;
        });
      }
    }
  }

  void _showPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  'Select HTML Source',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.folder_open_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Select Local HTML File...'),
                  subtitle: const Text(
                    'Browse for a .html or .htm file on your device',
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref
                        .read(mediaUploaderProvider)
                        .pickAndUploadWithUi(
                          context: context,
                          ref: ref,
                          bindKey: bindKey,
                          fileType: FileType.custom,
                          allowedExtensions: ['html', 'htm'],
                          moduleOwner: 'sdui_html_viewer',
                          dispatcher: widget.dispatcher,
                        );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.code_rounded,
                    color: colorScheme.secondary,
                  ),
                  title: const Text('Paste HTML String (Dev Mode)'),
                  subtitle: const Text(
                    'Uses the VALUE content key already set on this node',
                  ),
                  onTap: () {
                    ref.read(sduiStateVaultProvider.notifier).set(bindKey, '');
                    widget.dispatcher.onStateChange(bindKey, '');
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;
    final dispatcher = widget.dispatcher;

    // ── Behavior Resolution ──────────────────────────────────────────────────
    final int interactiveMode =
        node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final int? accentColorToken = node.behavior<int>(
      HbpBehavior.ACCENT_COLOR_TOKEN,
    );
    final double? height =
        node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble() ??
        node.behavior<double>(HbpBehavior.HEIGHT);
    final EdgeInsetsGeometry padding =
        SduiStyleResolver.resolveEdgeInsets(
          node.behavior<dynamic>(HbpBehavior.PADDING),
        ) ??
        EdgeInsets.zero;
    final String bindKey =
        node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;

    final Color linkColor =
        SduiStyleResolver.resolveColor(context, accentColorToken) ??
        colorScheme.primary;

    // ── Content Resolution (StateVault > SRC > VALUE) ────────────────────────
    final String? vaultValue = ref.watch(
      sduiStateVaultProvider.select((s) => s[bindKey] as String?),
    );
    final String? srcPath = node.contentVal<String>(HbpContent.SRC);
    final String? inlineHtml = node.contentVal<String>(HbpContent.VALUE);
    final String? label = node.contentVal<String>(HbpContent.LABEL);

    final String? activeSrc =
        (vaultValue != null &&
            vaultValue.isNotEmpty &&
            vaultValue.contains(RegExp(r'[/\\]')))
        ? vaultValue
        : srcPath;

    // Trigger async file load when activeSrc is a local path
    if (activeSrc != null &&
        activeSrc.isNotEmpty &&
        !activeSrc.startsWith('data:') &&
        activeSrc != _lastLoadedSrc) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadHtmlFile(activeSrc),
      );
    }

    String? htmlContent;
    if (activeSrc != null && activeSrc.isNotEmpty) {
      htmlContent = _isLoadingFile
          ? null
          : (_hasFileError ? null : _loadedFileHtml);
    } else {
      htmlContent =
          (vaultValue != null &&
              vaultValue.isNotEmpty &&
              !vaultValue.contains(RegExp(r'[/\\]')))
          ? vaultValue
          : ((inlineHtml != null && inlineHtml.isNotEmpty) ? inlineHtml : null);
    }

    // ── Widget Assembly ──────────────────────────────────────────────────────
    Widget buildContentWidget() {
      if (_isEditing) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.html_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HTML Editor',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                  onPressed: () => setState(() => _isEditing = false),
                  tooltip: 'Done Editing',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _htmlController,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'HTML Source snippet',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                dispatcher.onStateChange(bindKey, val);
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 14),
              label: const Text('Or select local HTML file...'),
              onPressed: () => _showPicker(context),
            ),
          ],
        );
      }

      if (htmlContent == null) {
        if (_isLoadingFile) {
          return Container(
            height: height ?? 150.0,
            color: colorScheme.surfaceContainerHigh,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (_hasFileError) {
          return _buildErrorState(
            colorScheme,
            theme,
            'Failed to read HTML file.\n${_lastLoadedSrc ?? ''}',
            height,
          );
        }
        if (interactiveMode == 1) {
          return _buildUploadBox(colorScheme, theme, height, label);
        }
        return _buildEmptyReadonly(colorScheme, theme, height);
      }

      final Widget htmlWidget = Html(
        data: htmlContent,
        onLinkTap: (url, attributes, element) async {
          if (url == null) return;
          if (url.startsWith('http://') ||
              url.startsWith('https://') ||
              url.startsWith('mailto:')) {
            final uri = Uri.tryParse(url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else if (url.startsWith('/')) {
            dispatcher.onAction({0: 2, 3: url});
          } else {
            dispatcher.onStateChange('${node.id}:link_tap', url);
          }
        },
        style: {
          'a': Style(
            color: linkColor,
            textDecoration: TextDecoration.underline,
          ),
          'body': Style(padding: HtmlPaddings.zero, margin: Margins.zero),
        },
      );

      Widget scrollable = height != null
          ? SizedBox(
              height: height,
              child: SingleChildScrollView(child: htmlWidget),
            )
          : htmlWidget;

      if (interactiveMode == 1) {
        return Stack(
          children: [
            scrollable,
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _isEditing = true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit HTML',
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
          ],
        );
      }
      return scrollable;
    }

    Widget content = Padding(padding: padding, child: buildContentWidget());

    // ── Card Wrap ────────────────────────────────────────────────────────────
    if (label != null &&
        label.isNotEmpty &&
        htmlContent != null &&
        !_isEditing) {
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
                    Icons.html_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
    double? height,
    String? label,
  ) {
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: () => setState(() => _isEditing = true),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: double.infinity,
          height: height ?? 150.0,
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
              Icon(Icons.html_rounded, size: 36, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label ?? 'Edit HTML / Embed snippet',
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
    double? height,
  ) {
    return Container(
      width: double.infinity,
      height: height ?? 150.0,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.html_rounded,
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(width: 8),
            Text(
              'No HTML Source',
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
    String message,
    double? height,
  ) {
    return Container(
      width: double.infinity,
      height: height ?? 150.0,
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
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          if (widget.node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) == 1) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 14),
              label: const Text('Try Another File'),
              onPressed: () => _showPicker(context),
            ),
          ],
        ],
      ),
    );
  }
}
