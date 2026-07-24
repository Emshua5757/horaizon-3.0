import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';

/// Defines the regex patterns for a specific programming language
class SyntaxRules {
  final String keywords;
  final String types;
  final String numbers;
  final String comments;
  final String strings;

  const SyntaxRules({
    required this.keywords,
    this.types = r'', // Default empty, overridden per language
    this.numbers = r'\b0x[a-fA-F0-9]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b', // Handles hex, ints, and floats
    required this.comments,
    this.strings = r'(["\u0027`])(?:(?=(\\?))\2.)*?\1', // Handles ", ', and ` with basic escaping
  });
}

/// A lightweight, memory-safe syntax highlighter.
class SyntaxHighlightingController extends TextEditingController {
  final int languageId;

  SyntaxHighlightingController({super.text, required this.languageId});

  // --- LANGUAGE DEFINITIONS ---
  static const String _capitalizedTypes = r'\b[A-Z][a-zA-Z0-9_]*\b';

  static const Map<int, SyntaxRules> _languageRules = {
    1: SyntaxRules( // Python
      keywords: r'\b(def|class|if|else|elif|for|while|try|except|finally|with|as|return|yield|import|from|pass|lambda|global|nonlocal|and|or|not|in|is)\b',
      types: r'\b(int|float|str|bool|list|dict|set|tuple|None|True|False)\b|' + _capitalizedTypes,
      comments: r'#.*',
    ),
    2: SyntaxRules( // Dart
      keywords: r'\b(abstract|as|assert|async|await|break|case|catch|class|const|continue|default|do|dynamic|else|enum|extends|factory|final|finally|for|Function|get|if|implements|import|in|is|late|mixin|new|null|return|set|static|super|switch|this|throw|try|var|while|with|yield)\b',
      types: r'\b(int|double|bool|void|true|false)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    3: SyntaxRules( // TypeScript
      keywords: r'\b(type|interface|namespace|implements|enum|declare|async|await|break|case|catch|class|const|continue|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|null|return|super|switch|this|throw|try|typeof|var|while|yield)\b',
      types: r'\b(number|string|boolean|any|unknown|never|void|true|false)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    4: SyntaxRules( // JavaScript
      keywords: r'\b(async|await|break|case|catch|class|const|continue|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|null|return|super|switch|this|throw|try|typeof|var|void|while|yield)\b',
      types: r'\b(true|false)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    5: SyntaxRules( // JSON
      keywords: r'\b(true|false|null)\b',
      comments: r'', // JSON officially doesn't have comments
    ),
    6: SyntaxRules( // Bash
      keywords: r'\b(if|fi|then|elif|else|for|do|done|until|while|break|continue|case|esac|function|in|return|echo)\b',
      comments: r'#.*',
    ),
    7: SyntaxRules( // Rust
      keywords: r'\b(as|break|const|continue|crate|else|enum|extern|fn|for|if|impl|in|let|loop|match|mod|move|mut|pub|ref|return|self|Self|static|struct|super|trait|unsafe|use|where|while)\b',
      types: r'\b(i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|bool|char|String|true|false)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    8: SyntaxRules( // Go
      keywords: r'\b(break|default|func|interface|select|case|defer|go|map|struct|chan|else|goto|package|switch|const|fallthrough|if|range|type|continue|for|import|return|var)\b',
      types: r'\b(int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|bool|string|byte|rune|true|false|nil)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    9: SyntaxRules( // C++
      keywords: r'\b(auto|break|case|class|const|continue|default|delete|do|else|enum|explicit|export|extern|for|friend|goto|if|inline|mutable|namespace|new|operator|private|protected|public|register|return|signed|sizeof|static|struct|switch|template|this|throw|try|typedef|typeid|typename|union|unsigned|using|virtual|volatile|while)\b',
      types: r'\b(int|float|double|char|bool|void|short|long|true|false)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    10: SyntaxRules( // Java
      keywords: r'\b(abstract|assert|break|case|catch|class|const|continue|default|do|else|enum|extends|final|finally|for|goto|if|implements|import|instanceof|interface|native|new|package|private|protected|public|return|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|volatile|while)\b',
      types: r'\b(int|float|double|char|boolean|byte|short|long|void|true|false|null)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    11: SyntaxRules( // C#
      keywords: r'\b(abstract|as|base|break|case|catch|checked|class|const|continue|default|delegate|do|else|enum|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|interface|internal|is|lock|namespace|new|null|object|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|struct|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|async|await|yield)\b',
      types: r'\b(bool|byte|char|decimal|double|float|int|long|sbyte|short|string|uint|ulong|ushort|void|true|false)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    12: SyntaxRules( // Swift
      keywords: r'\b(class|deinit|enum|extension|func|import|init|inout|let|protocol|struct|subscript|typealias|var|break|case|continue|default|defer|do|else|fallthrough|for|guard|if|in|repeat|return|switch|where|while|as|catch|is|rethrows|super|self|Self|throw|throws|try)\b',
      types: r'\b(Int|Float|Double|Bool|String|true|false|nil)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    13: SyntaxRules( // Kotlin
      keywords: r'\b(as|break|class|continue|do|else|for|fun|if|in|interface|is|object|package|return|super|this|throw|try|typealias|typeof|val|var|when|while|suspend)\b',
      types: r'\b(Int|Float|Double|Boolean|String|Byte|Short|Long|Char|Unit|Any|true|false|null)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/',
    ),
    14: SyntaxRules( // Ruby
      keywords: r'\b(BEGIN|END|alias|and|begin|break|case|class|def|defined\?|do|else|elsif|end|ensure|for|if|in|module|next|not|or|redo|rescue|retry|return|self|super|then|undef|unless|until|when|while|yield)\b',
      types: r'\b(true|false|nil)\b|' + _capitalizedTypes,
      comments: r'#.*',
    ),
    15: SyntaxRules( // PHP
      keywords: r'\b(abstract|and|array|as|break|callable|case|catch|class|clone|const|continue|declare|default|die|do|echo|else|elseif|empty|enddeclare|endfor|endforeach|endif|endswitch|endwhile|eval|exit|extends|final|finally|for|foreach|function|global|goto|if|implements|include|include_once|instanceof|insteadof|interface|isset|list|namespace|new|or|print|private|protected|public|require|require_once|return|static|switch|throw|trait|try|unset|use|var|while|xor|yield)\b',
      types: r'\b(int|float|bool|string|true|false|null)\b|' + _capitalizedTypes,
      comments: r'//.*|/\*[\s\S]*?\*/|#.*',
    ),
    16: SyntaxRules( // SQL
      keywords: r'\b(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|DELETE|CREATE|TABLE|DROP|ALTER|JOIN|ON|GROUP|BY|ORDER|HAVING|ASC|DESC|AND|OR|NOT|IN|AS|IS|PRIMARY|KEY|FOREIGN)\b',
      types: r'\b(INT|VARCHAR|TEXT|DATE|BOOLEAN|FLOAT|DOUBLE|NULL|TRUE|FALSE)\b',
      comments: r'--.*|/\*[\s\S]*?\*/',
    ),
    17: SyntaxRules( // HTML
      keywords: r'</?[a-zA-Z0-9]+', // Highlighting tags loosely
      comments: r'',
      strings: r'(["\u0027]).*?\1',
    ),
    18: SyntaxRules( // CSS
      keywords: r'\b(margin|padding|color|background|border|font|display|position|top|right|bottom|left|width|height|flex|grid)\b',
      numbers: r'\b\d+(?:\.\d+)?(?:px|em|rem|%|vh|vw)?\b', // CSS specific numbers + units
      comments: r'/\*[\s\S]*?\*/',
    ),
    19: SyntaxRules( // YAML
      keywords: r'\b(true|false|null|yes|no)\b',
      comments: r'#.*',
    ),
    20: SyntaxRules( // Markdown
      keywords: r'(^#+\s.*|\*\*.*?\*\*|__.*?__|_.*?_|^\>.*)', // Headers, bold, italic, quotes
      comments: r'',
      strings: r'\[.*?\]\(.*?\)', // Treating links as strings for coloring
    ),
  };

  static const SyntaxRules _defaultRules = SyntaxRules(
    keywords: r'\b(class|function|let|var|const|if|else|for|while|return|import|export)\b',
    types: r'\b(int|float|double|bool|boolean|string|String|true|false)\b|' + _capitalizedTypes,
    comments: r'//.*|#.*',
  );

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final text = this.text;
    if (text.isEmpty) return TextSpan(text: text, style: style);

    final theme = Theme.of(context);
    
    // --- STYLING DEFINITIONS ---
    final keywordStyle = style?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold);
    final typeStyle = style?.copyWith(color: theme.colorScheme.secondary); // Highlight types with secondary!
    final stringStyle = style?.copyWith(color: Colors.green);
    final numberStyle = style?.copyWith(color: Colors.orange); // Or theme.colorScheme.tertiary
    final commentStyle = style?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic);

    final rules = _languageRules[languageId] ?? _defaultRules;

    // Use Named Capture Groups to prevent overlapping match errors 
    // IMPORTANT: The order matters. Comments and Strings must be matched FIRST so they "consume" keywords inside them.
    final List<String> patterns = [];
    if (rules.comments.isNotEmpty) patterns.add('(?<comment>${rules.comments})');
    if (rules.strings.isNotEmpty) patterns.add('(?<string>${rules.strings})');
    if (rules.keywords.isNotEmpty) patterns.add('(?<keyword>${rules.keywords})');
    if (rules.types.isNotEmpty) patterns.add('(?<type>${rules.types})');
    if (rules.numbers.isNotEmpty) patterns.add('(?<number>${rules.numbers})');

    final combinedRegex = RegExp(
      patterns.join('|'),
      multiLine: true,
    );

    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in combinedRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: style));
      }

      TextStyle? matchStyle = style;
      
      // Determine which named group was matched
      if (rules.comments.isNotEmpty && match.namedGroup('comment') != null) {
        matchStyle = commentStyle;
      } else if (rules.strings.isNotEmpty && match.namedGroup('string') != null) {
        matchStyle = stringStyle;
      } else if (rules.keywords.isNotEmpty && match.namedGroup('keyword') != null) {
        matchStyle = keywordStyle;
      } else if (rules.types.isNotEmpty && match.namedGroup('type') != null) {
        matchStyle = typeStyle;
      } else if (rules.numbers.isNotEmpty && match.namedGroup('number') != null) {
        matchStyle = numberStyle;
      }

      spans.add(TextSpan(text: match.group(0), style: matchStyle));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}

class SduiCodeEditor extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiCodeEditor({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiCodeEditor> createState() => _SduiCodeEditorState();
}

class _SduiCodeEditorState extends ConsumerState<SduiCodeEditor> {
  late SyntaxHighlightingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  Timer? _debounce;
  int _currentLanguageId = 0;

  @override
  void initState() {
    super.initState();
    final rawVaultVal = ref.read(sduiStateVaultProvider)[widget.node.id];
    String initialVal = widget.node.contentVal<String>(0) ?? '';
    if (rawVaultVal != null) {
      initialVal = rawVaultVal.toString();
    }
    
    _currentLanguageId = widget.node.behavior<int>(110) ?? 0;

    _controller = SyntaxHighlightingController(
      text: initialVal, 
      languageId: _currentLanguageId,
    );
    
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
  void didUpdateWidget(SduiCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final int newLanguageId = widget.node.behavior<int>(110) ?? 0;
    if (_currentLanguageId != newLanguageId) {
      _currentLanguageId = newLanguageId;
      final oldText = _controller.text;
      _controller.dispose();
      _controller = SyntaxHighlightingController(text: oldText, languageId: _currentLanguageId);
    }

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

  void _onLanguageChanged(int newLangId) {
    setState(() {
      _currentLanguageId = newLangId;
      final oldText = _controller.text;
      _controller.dispose();
      _controller = SyntaxHighlightingController(text: oldText, languageId: _currentLanguageId);
    });
    
    // The spec says: emits HBP event with new language ID. Node.js persists this.
    // For now we will use a special action payload (ID 12: generic/AI) to signal language change.
    widget.dispatcher.onAction({
      0: 12, // Action ID (e.g. 12 = AI_COMMAND or custom)
      1: newLangId,
      2: widget.node.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = _controller.text.trim().isNotEmpty;
    
    // 1. Behaviors
    final bool isEditable = widget.node.behavior<int>(95) == 1;
    final String placeholder = widget.node.contentVal<String>(2) ?? 'print("Hello World");';

    // 2. Vault Sync
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
    
    final codeStyle = const TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 14.0,
      height: 1.4,
    ).copyWith(color: theme.colorScheme.onSurface);

    final String badgeText = switch (_currentLanguageId) {
      1 => 'PYTHON',
      2 => 'DART',
      3 => 'TYPESCRIPT',
      4 => 'JAVASCRIPT',
      5 => 'JSON',
      6 => 'BASH',
      7 => 'RUST',
      8 => 'GO',
      9 => 'C++',
      10 => 'JAVA',
      11 => 'C#',
      12 => 'SWIFT',
      13 => 'KOTLIN',
      14 => 'RUBY',
      15 => 'PHP',
      16 => 'SQL',
      17 => 'HTML',
      18 => 'CSS',
      19 => 'YAML',
      20 => 'MARKDOWN',
      _ => 'CODE',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(51), // 0.2 opacity
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: (_hasFocus && isEditable) ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: (_hasFocus && isEditable) ? 2.0 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: (_hasFocus && isEditable) || (!hasContent && isEditable)
                ? TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    style: codeStyle,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onTextChanged,
                  )
                : GestureDetector(
                    onTap: isEditable ? () {
                      setState(() {
                        _hasFocus = true;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusNode.requestFocus();
                      });
                    } : null,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: double.infinity,
                      child: RichText(
                        text: _controller.buildTextSpan(
                          context: context,
                          style: codeStyle,
                          withComposing: false,
                        ),
                      ),
                    ),
                  ),
          ),
          
          if (isEditable)
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<int>(
                tooltip: 'Change Language',
                onSelected: _onLanguageChanged,
                itemBuilder: (context) => [
                  for (final lang in {
                    1: 'PYTHON', 2: 'DART', 3: 'TYPESCRIPT', 4: 'JAVASCRIPT',
                    5: 'JSON', 6: 'BASH', 7: 'RUST', 8: 'GO', 9: 'C++',
                    10: 'JAVA', 11: 'C#', 12: 'SWIFT', 13: 'KOTLIN',
                    14: 'RUBY', 15: 'PHP', 16: 'SQL', 17: 'HTML',
                    18: 'CSS', 19: 'YAML', 20: 'MARKDOWN',
                  }.entries)
                    PopupMenuItem<int>(
                      value: lang.key,
                      child: Text(lang.value),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badgeText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Readonly Badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
