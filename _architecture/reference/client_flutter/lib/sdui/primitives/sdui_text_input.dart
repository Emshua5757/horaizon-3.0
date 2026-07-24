import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart';


abstract final class SduiInputType {
  static const int text = 0;
  static const int number = 1;
  static const int decimal = 2;
  static const int email = 3;
  static const int phone = 4;
  static const int multiline = 5;
}

class SduiTextInput extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiTextInput({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiTextInput> createState() => _SduiTextInputState();
}

class _SduiTextInputState extends ConsumerState<SduiTextInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _obscured;
  Timer? _debounce;

  String get _bindKey => widget.node.behavior<String>(40) ?? widget.node.id;

  @override
  void initState() {
    super.initState();
    // Resolve initial value from StateVault or Content
    final rawVaultVal = ref.read(sduiStateVaultProvider)[_bindKey];
    String initialVal = widget.node.contentVal<String>(0) ?? '';
    if (rawVaultVal != null) {
      initialVal = rawVaultVal.toString();
    }
    
    _controller = TextEditingController(text: initialVal);
    _focusNode = FocusNode();
    _obscured = widget.node.behavior<int>(43) == 1; // obscure_text
  }

  @override
  void didUpdateWidget(covariant SduiTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if obscureText changed
    final bool oldObscure = oldWidget.node.behavior<int>(43) == 1;
    final bool newObscure = widget.node.behavior<int>(43) == 1;
    if (oldObscure != newObscure) {
      _obscured = newObscure;
    }

    final String oldVal = oldWidget.node.contentVal<String>(0) ?? '';
    final String newVal = widget.node.contentVal<String>(0) ?? '';
    final String oldBindKey = oldWidget.node.behavior<String>(40) ?? oldWidget.node.id;
    if (_bindKey != oldBindKey || oldVal != newVal) {
      if (!_focusNode.hasFocus) {
        final rawVaultVal = ref.read(sduiStateVaultProvider)[_bindKey];
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
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String newText) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.dispatcher.onStateChange(_bindKey, newText);
      if (_bindKey == 'search_query') {
        ref.read(sduiSocketProvider).emitRpc('shua.diary.search', {
          'search_query': newText,
          'user_id': 'default',
        });
      }
    });
  }

  TextInputType _resolveKeyboardType(int inputType) {
    return switch (inputType) {
      SduiInputType.number => TextInputType.number,
      SduiInputType.decimal => const TextInputType.numberWithOptions(decimal: true),
      SduiInputType.email => TextInputType.emailAddress,
      SduiInputType.phone => TextInputType.phone,
      SduiInputType.multiline => TextInputType.multiline,
      _ => TextInputType.text,
    };
  }

  List<TextInputFormatter> _resolveFormatters(int inputType) {
    return switch (inputType) {
      SduiInputType.number => [FilteringTextInputFormatter.digitsOnly],
      SduiInputType.decimal => [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 1. Behaviors
    final int inputType = widget.node.behavior<int>(41) ?? 0;
    final bool obscureText = widget.node.behavior<int>(43) == 1;
    final int? maxLines = widget.node.behavior<int>(48);
    final bool isReadOnly = widget.node.behavior<int>(95) == 0;
    final bool borderless = widget.node.behavior<int>(99) == 1;
    
    final Color? textColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(101));
    final int textAlignVal = widget.node.behavior<int>(102) ?? 0;
    final bool isBold = widget.node.behavior<int>(104) == 1;

    // 2. Content
    final String label = widget.node.contentVal<String>(1) ?? '';
    final String? hint = widget.node.contentVal<String>(2);
    final String? iconName = widget.node.behavior<String>(62);
    
    // 3. StateVault sync
    // Listen to vault. If an external event mutated our state, we update the controller IF NOT FOCUSED.
    ref.listen(
      sduiStateVaultProvider.select((state) => state[_bindKey]),
      (previous, next) {
        if (!mounted) return;
        final String? vaultVal = next?.toString();
        if (vaultVal != null && vaultVal != _controller.text && !_focusNode.hasFocus) {
          _controller.text = vaultVal;
        }
      },
    );

    TextAlign align = switch (textAlignVal) {
      1 => TextAlign.center,
      2 => TextAlign.end,
      _ => TextAlign.start,
    };

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: _obscured,
      keyboardType: _resolveKeyboardType(inputType),
      inputFormatters: _resolveFormatters(inputType),
      maxLines: obscureText ? 1 : (inputType == SduiInputType.multiline ? null : (maxLines ?? 1)),
      readOnly: isReadOnly,
      textAlign: align,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: textColor,
        fontWeight: isBold ? FontWeight.bold : null,
      ),
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: iconName != null ? Icon(SduiIconRegistry.resolve(iconName)) : null,
        border: borderless ? InputBorder.none : const OutlineInputBorder(),
        contentPadding: borderless 
            ? EdgeInsets.zero 
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: borderless,
        filled: !borderless,
        fillColor: borderless ? Colors.transparent : theme.colorScheme.surfaceContainerHighest.withAlpha(76),
        suffixIcon: obscureText
          ? IconButton(
              icon: Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              onPressed: () => setState(() => _obscured = !_obscured),
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      ),
      onChanged: _onTextChanged,
    );
  }
}
