import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart';

class JbcMessage {
  final String sender; // 'user' | 'assistant'
  final String text;
  final List<dynamic>? mutations;
  final String? mutationsSummary;
  final bool isStreaming;

  JbcMessage({
    required this.sender,
    required this.text,
    this.mutations,
    this.mutationsSummary,
    this.isStreaming = false,
  });

  JbcMessage copyWith({
    String? text,
    List<dynamic>? mutations,
    String? mutationsSummary,
    bool? isStreaming,
  }) {
    return JbcMessage(
      sender: sender,
      text: text ?? this.text,
      mutations: mutations ?? this.mutations,
      mutationsSummary: mutationsSummary ?? this.mutationsSummary,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class SduiJbcPanel extends ConsumerStatefulWidget {
  final String entryId;
  final String screenId;
  final List<SduiNode> localNodes;

  const SduiJbcPanel({
    super.key,
    required this.entryId,
    required this.screenId,
    required this.localNodes,
  });

  @override
  ConsumerState<SduiJbcPanel> createState() => _SduiJbcPanelState();
}

class _SduiJbcPanelState extends ConsumerState<SduiJbcPanel> {
  final List<JbcMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _activeTransactionId;

  @override
  void initState() {
    super.initState();
    // Pre-populate with welcome message
    _messages.add(JbcMessage(
      sender: 'assistant',
      text: 'Hello! I am your JBC Copilot. Ask me to refactor, format, or insert sections in your journal entry.',
    ));
  }

  @override
  void dispose() {
    _cleanupActiveStream();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cleanupActiveStream() {
    if (_activeTransactionId != null) {
      final socket = ref.read(sduiSocketProvider).socketForScreen(widget.screenId);
      socket?.off('stream_chunk_$_activeTransactionId');
      _activeTransactionId = null;
    }
  }

  List<Map<String, dynamic>> _extractCurrentBlocks() {
    // Find blocks_list node recursively
    SduiNode? findBlocksList(List<SduiNode> list) {
      for (final node in list) {
        if (node.id.endsWith(':blocks_list')) return node;
        if (node.children != null) {
          final found = findBlocksList(node.children!);
          if (found != null) return found;
        }
      }
      return null;
    }

    final blocksListNode = findBlocksList(widget.localNodes);
    if (blocksListNode == null || blocksListNode.children == null) return [];

    final List<Map<String, dynamic>> blocks = [];
    final vault = ref.read(sduiStateVaultProvider);

    for (final wrapper in blocksListNode.children!) {
      final match = RegExp(r':block_(.+?):wrapper').firstMatch(wrapper.id);
      if (match != null) {
        final blockId = match.group(1)!;

        // Find content node inside wrapper
        final contentNode = wrapper.children?.firstWhere(
          (c) => c.id.endsWith(':content'),
          orElse: () => wrapper,
        );

        final typeId = contentNode?.typeId ?? 1;

        // Map typeId and behaviors to logical BlockType
        String blockType = 'body';
        if (typeId == 1) {
          final isHeading = contentNode?.behavior<dynamic>(100) != null;
          blockType = isHeading ? 'heading_1' : 'body';
        } else if (typeId == 8) {
          blockType = 'checklist';
        }

        // Retrieve content from vault
        final vaultKey = '${widget.screenId}:block_$blockId:content';
        final content = vault[vaultKey]?.toString() ?? '';

        blocks.add({
          'id': blockId,
          'blockType': blockType,
          'content': content,
        });
      }
    }
    return blocks;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(JbcMessage(sender: 'user', text: text));
      _messages.add(JbcMessage(sender: 'assistant', text: '', isStreaming: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final socketManager = ref.read(sduiSocketProvider);
    final socket = socketManager.socketForScreen(widget.screenId);
    if (socket == null) return;

    final transactionId = 'tx_${DateTime.now().millisecondsSinceEpoch}';
    _activeTransactionId = transactionId;

    // Listen to WebSocket stream chunks
    socket.on('stream_chunk_$transactionId', (data) {
      try {
        final Uint8List bytes = data is Uint8List
            ? data
            : Uint8List.fromList(List<int>.from(data as List));
        final Map decoded = deserialize(bytes) as Map;

        final String chunk = (decoded[1] ?? decoded['1']) as String? ?? '';
        final bool isFinal = (decoded[2] ?? decoded['2']) as bool? ?? false;

        if (mounted) {
          setState(() {
            final lastIndex = _messages.length - 1;
            if (lastIndex >= 0 && _messages[lastIndex].sender == 'assistant') {
              final currentMsg = _messages[lastIndex];
              _messages[lastIndex] = currentMsg.copyWith(
                text: currentMsg.text + chunk,
                isStreaming: !isFinal,
              );
            }
          });
          _scrollToBottom();
        }
      } catch (e) {
        gLog.log(HbpLogLevel.ERROR, 'jbc_panel', 'Failed to parse stream chunk: $e', tags: HbpLogTag.SDUI | HbpLogTag.AI);
      }
    });

    try {
      final currentBlocks = _extractCurrentBlocks();
      
      // Request chat stream and await final compiled bytecode plan
      final response = await socketManager.sendRpcWithResponse(
        'shua.diary.chat',
        {
          'entry_id': widget.entryId,
          'prompt': text,
          'blocks': currentBlocks,
          'history': _messages
              .take(_messages.length - 2) // exclude the current prompts
              .map((m) => {'role': m.sender == 'user' ? 'user' : 'assistant', 'content': m.text})
              .toList(),
        },
        transactionId,
      );

      _cleanupActiveStream();

      // RPC response key 1 contains the plan (JbcPlanResult)
      final planData = (response[1] ?? response['1']) as Map?;
      if (planData != null && mounted) {
        setState(() {
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0 && _messages[lastIndex].sender == 'assistant') {
            final mutations = planData['mutations'] as List?;
            final summary = planData['mutationsSummary'] as String?;
            _messages[lastIndex] = _messages[lastIndex].copyWith(
              mutations: mutations,
              mutationsSummary: summary,
              isStreaming: false,
            );
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'jbc_panel', 'Error invoking chat RPC: $e', tags: HbpLogTag.SDUI | HbpLogTag.AI);
      _cleanupActiveStream();
      if (mounted) {
        setState(() {
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0 && _messages[lastIndex].sender == 'assistant') {
            _messages[lastIndex] = _messages[lastIndex].copyWith(
              text: 'Error: Failed to fetch response from Copilot.',
              isStreaming: false,
            );
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptMutations(List<dynamic> mutations) async {
    setState(() => _isLoading = true);
    final socketManager = ref.read(sduiSocketProvider);
    final transactionId = 'apply_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await socketManager.sendRpcWithResponse(
        'shua.diary.apply_mutations',
        {
          'entry_id': widget.entryId,
          'mutations': mutations,
        },
        transactionId,
      );
      if (mounted) {
        Navigator.of(context).pop(); // Close the drawer on success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Refactoring applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'jbc_panel', 'Failed to apply mutations: $e', tags: HbpLogTag.SDUI | HbpLogTag.DATABASE);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply refactoring: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildVisualDiff(List<dynamic> mutations) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                const Text(
                  'Proposed Mutations',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          ...mutations.map((m) {
            final action = m['action'] as String;
            final typeName = m['type'] as String? ?? 'block';
            final content = m['content'] as String? ?? '';
            
            Color color;
            IconData icon;
            String label;

            if (action == 'INSERT') {
              color = Colors.greenAccent;
              icon = Icons.add_circle_outline;
              label = 'Add $typeName';
            } else if (action == 'UPDATE') {
              color = Colors.amberAccent;
              icon = Icons.change_circle_outlined;
              label = 'Edit $typeName';
            } else {
              color = Colors.redAccent;
              icon = Icons.remove_circle_outline;
              label = 'Delete $typeName';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        if (content.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            content,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Drawer(
      width: 380,
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'JBC Copilot Assistant',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isAssistant = message.sender == 'assistant';

                  return Align(
                    alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isAssistant 
                            ? Colors.white.withValues(alpha: 0.06) 
                            : accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12.0),
                          topRight: const Radius.circular(12.0),
                          bottomLeft: Radius.circular(isAssistant ? 0.0 : 12.0),
                          bottomRight: Radius.circular(isAssistant ? 12.0 : 0.0),
                        ),
                        border: Border.all(
                          color: isAssistant 
                              ? Colors.white10 
                              : accentColor.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAssistant && message.text.isEmpty && message.isStreaming)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            )
                          else
                            MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                p: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                                code: theme.textTheme.bodySmall?.copyWith(
                                  backgroundColor: Colors.black54,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          if (message.mutations != null && message.mutations!.isNotEmpty) ...[
                            _buildVisualDiff(message.mutations!),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _messages.removeAt(index);
                                    });
                                  },
                                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _acceptMutations(message.mutations!),
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Accept Changes', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Field Area
            const Divider(height: 1, color: Colors.white12),
            Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask JBC Copilot...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 1.0),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: accentColor),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
