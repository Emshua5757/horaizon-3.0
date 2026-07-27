import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rich Theme-Aware Markdown & Fenced Code Block Renderer for JOSH AI Chat.
/// Renders headers, lists, inline code, and syntax-styled code cards (bash, rust, json, mermaid, batch)
/// with a 1-click "Copy Code" button and responsive theme integration.
class FormattedMarkdownContent extends StatelessWidget {
  final String content;

  const FormattedMarkdownContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final blocks = _parseBlocks(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block.isThinkingBlock) {
          return _ThinkingCard(text: block.text);
        } else if (block.isCodeBlock) {
          return _CodeBlockCard(
            language: block.language,
            code: block.text,
          );
        } else {
          return _TextBlockRenderer(text: block.text);
        }
      }).toList(),
    );
  }

  List<_ParsedBlock> _parseBlocks(String input) {
    final List<_ParsedBlock> blocks = [];
    final lines = input.split('\n');

    bool inCode = false;
    String currentLang = '';
    final List<String> currentBuffer = [];

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        if (inCode) {
          // Closing code block
          blocks.add(_ParsedBlock(
            isCodeBlock: true,
            language: currentLang,
            text: currentBuffer.join('\n'),
          ));
          currentBuffer.clear();
          inCode = false;
          currentLang = '';
        } else {
          // Opening code block
          if (currentBuffer.isNotEmpty) {
            blocks.add(_ParsedBlock(
              isCodeBlock: false,
              text: currentBuffer.join('\n'),
            ));
            currentBuffer.clear();
          }
          inCode = true;
          currentLang = line.trim().substring(3).trim();
        }
      } else {
        currentBuffer.add(line);
      }
    }

    if (currentBuffer.isNotEmpty) {
      final text = currentBuffer.join('\n');
      if (text.contains('<think>') || text.contains('🛠️ **[MCP Tool')) {
        blocks.add(_ParsedBlock(
          isThinkingBlock: true,
          text: text,
        ));
      } else {
        blocks.add(_ParsedBlock(
          isCodeBlock: inCode,
          language: inCode ? currentLang : '',
          text: text,
        ));
      }
    }

    return blocks;
  }
}

class _ParsedBlock {
  final bool isCodeBlock;
  final bool isThinkingBlock;
  final String language;
  final String text;

  _ParsedBlock({
    this.isCodeBlock = false,
    this.isThinkingBlock = false,
    this.language = '',
    required this.text,
  });
}

class _ThinkingCard extends StatefulWidget {
  final String text;

  const _ThinkingCard({required this.text});

  @override
  State<_ThinkingCard> createState() => _ThinkingCardState();
}

class _ThinkingCardState extends State<_ThinkingCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cleanedText = widget.text
        .replaceAll('<think>', '')
        .replaceAll('</think>', '')
        .trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'THINKING PHASE & AGENT CHAIN-OF-THOUGHT',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                cleanedText,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11.5,
                  height: 1.45,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeBlockCard extends StatefulWidget {
  final String language;
  final String code;

  const _CodeBlockCard({
    required this.language,
    required this.code,
  });

  @override
  State<_CodeBlockCard> createState() => _CodeBlockCardState();
}

class _CodeBlockCardState extends State<_CodeBlockCard> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayLang = widget.language.isEmpty ? 'CODE' : widget.language.toUpperCase();
    final isMermaid = displayLang == 'MERMAID' || displayLang == 'MMD';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMermaid ? cs.secondary.withValues(alpha: 0.5) : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isMermaid
                  ? cs.secondaryContainer.withValues(alpha: 0.3)
                  : cs.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(
                  isMermaid ? Icons.schema_rounded : Icons.code_rounded,
                  size: 14,
                  color: isMermaid ? cs.secondary : cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isMermaid ? 'MERMAID DIAGRAM' : displayLang,
                  style: TextStyle(
                    color: isMermaid ? cs.secondary : cs.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 12,
                          color: _copied ? Colors.green : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            color: _copied ? Colors.green : cs.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code Text Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.code.trimRight(),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                height: 1.45,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlockRenderer extends StatelessWidget {
  final String text;

  const _TextBlockRenderer({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        // Header 1 (# Header)
        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              trimmed.substring(2),
              style: TextStyle(color: cs.primary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Header 2 (## Header)
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Header 3 (### Header)
        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              trimmed.substring(4),
              style: TextStyle(color: cs.secondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Bullet Point (- item or * item)
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                Expanded(
                  child: _RichInlineText(text: trimmed.substring(2)),
                ),
              ],
            ),
          );
        }

        // Numbered List (1. item)
        final numMatch = RegExp(r'^\d+\.\s').firstMatch(trimmed);
        if (numMatch != null) {
          final prefix = numMatch.group(0)!;
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prefix, style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                Expanded(
                  child: _RichInlineText(text: trimmed.substring(prefix.length)),
                ),
              ],
            ),
          );
        }

        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _RichInlineText(text: line),
        );
      }).toList(),
    );
  }
}

class _RichInlineText extends StatelessWidget {
  final String text;

  const _RichInlineText({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];

    // Regex for bold (**text**), italics (*text*), and inline code (`code`)
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedStr.substring(2, matchedStr.length - 2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedStr.substring(1, matchedStr.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Text(
              matchedStr.substring(1, matchedStr.length - 1),
              style: TextStyle(
                color: cs.primary,
                fontSize: 11.5,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return SelectableText.rich(
      TextSpan(
        style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.45),
        children: spans,
      ),
    );
  }
}
