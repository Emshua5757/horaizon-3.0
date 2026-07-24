import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';

class SduiMarkdownEditor extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiMarkdownEditor({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiMarkdownEditor> createState() => _SduiMarkdownEditorState();
}

class _SduiMarkdownEditorState extends ConsumerState<SduiMarkdownEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final rawVaultVal = ref.read(sduiStateVaultProvider)[widget.node.id];
    String initialVal = widget.node.contentVal<String>(0) ?? '';
    if (rawVaultVal != null) {
      initialVal = rawVaultVal.toString();
    }
    
    _controller = TextEditingController(text: initialVal);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SduiMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String oldVal = oldWidget.node.contentVal<String>(0) ?? '';
    final String newVal = widget.node.contentVal<String>(0) ?? '';
    if (widget.node.id != oldWidget.node.id || oldVal != newVal) {
      if (!_focusNode.hasFocus) {
        final rawVaultVal = ref.read(sduiStateVaultProvider)[widget.node.id];
        String val = newVal;
        if (rawVaultVal != null) {
          val = rawVaultVal.toString();
        }
        if (_controller.text != val) {
          _controller.text = val;
        }
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String newText) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.dispatcher.onStateChange(widget.node.id, newText);
    });
  }

  TextAlign _resolveTextAlign(int alignVal) {
    return switch (alignVal) {
      1 => TextAlign.center,
      2 => TextAlign.end,
      3 => TextAlign.justify,
      _ => TextAlign.start,
    };
  }

  TextStyle? _resolveHeadingStyle(ThemeData theme, int level, Color? textColor) {
    TextStyle? base;
    switch (level) {
      case 1: base = theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold); break;
      case 2: base = theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold); break;
      case 3: base = theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold); break;
      case 4: base = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold); break;
      case 5: base = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold); break;
      case 6: 
        base = theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.primary,
        ); 
        break;
      default: base = theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold); break;
    }
    if (textColor != null) {
      return base?.copyWith(color: textColor);
    }
    return base;
  }

  Widget _buildReadonlyView(
    ThemeData theme, 
    int displayMode, 
    int headingLevel, 
    TextAlign align, 
    TextStyle? customStyle, 
    Color? customColor, 
    String content,
    String hint,
  ) {
    final bool isEmpty = content.trim().isEmpty;
    final String textToRender = isEmpty ? hint : content;
    
    Widget contentWidget;

    // 0=body, 1=heading, 2=quote, 3=caption, 4=code_inline
    switch (displayMode) {
      case 1: // Heading
        contentWidget = Text(
          textToRender,
          textAlign: align,
          style: _resolveHeadingStyle(theme, headingLevel, customColor),
        );
        break;
      case 2: // Quote
        contentWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(8),
            border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4.0)),
          ),
          child: Text(
            textToRender,
            textAlign: align,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: customColor ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
        break;
      case 3: // Caption
        contentWidget = Text(
          textToRender,
          textAlign: align,
          style: theme.textTheme.bodySmall?.copyWith(
            color: customColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        );
        break;
      case 4: // Code Inline
        contentWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            textToRender,
            textAlign: align,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'JetBrainsMono',
              color: customColor ?? theme.colorScheme.onSurface,
            ),
          ),
        );
        break;
      case 0: // Body
      default:
        if (isEmpty) {
          contentWidget = Text(
            hint,
            textAlign: align,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
              fontStyle: FontStyle.italic,
            ),
          );
        } else {
          contentWidget = MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: customStyle ?? theme.textTheme.bodyLarge?.copyWith(color: customColor),
              textAlign: WrapAlignment.start, // flutter_markdown doesn't support TextAlign easily without WrapAlignment mapping
            ),
          );
        }
        break;
    }

    return contentWidget;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Behaviors
    final int displayMode = widget.node.behavior<int>(100) ?? 0;
    final int headingLevel = widget.node.behavior<int>(101) ?? 1;
    final bool isEditable = widget.node.behavior<int>(95) == 1;
    final TextAlign align = _resolveTextAlign(widget.node.behavior<int>(102) ?? 0);
    
    final TextStyle? customStyle = SduiStyleResolver.resolveTextStyle(context, widget.node.behavior<int>(103) ?? -1);
    final Color? customColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(97));

    // 2. Content
    final String hint = widget.node.contentVal<String>(2) ?? 'Write something...';

    // 3. StateVault sync
    ref.listen(
      sduiStateVaultProvider.select((state) => state[widget.node.id]),
      (previous, next) {
        if (!mounted) return;
        final String? vaultVal = next?.toString();
        if (vaultVal != null && vaultVal != _controller.text && !_focusNode.hasFocus) {
          _controller.text = vaultVal;
        }
      },
    );

    // EDITABLE MODE - FOCUSED
    if (isEditable && _hasFocus) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(128)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          textAlign: align,
          style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'JetBrainsMono'),
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onTextChanged,
        ),
      );
    }

    // READONLY OR EDITABLE (NOT FOCUSED)
    final Widget viewWidget = _buildReadonlyView(
      theme,
      displayMode,
      headingLevel,
      align,
      customStyle,
      customColor,
      _controller.text,
      hint,
    );

    if (!isEditable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: viewWidget,
      );
    }

    // Tap to edit wrapper
    return GestureDetector(
      onTap: () {
        setState(() {
          _hasFocus = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      },
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Container(
          // Do NOT set width: double.infinity here — this widget may be a
          // flex child (Expanded) inside a Row. Asserting infinite width
          // while the parent LayoutBuilder is still computing constraints
          // causes BoxConstraints forces an infinite width crash.
          // The parent Expanded/Row provides the bounded width.
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: viewWidget,
        ),
      ),
    );
  }
}
