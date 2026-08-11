import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../providers/active_entry_provider.dart';

class AiAssistantDrawer extends ConsumerStatefulWidget {
  final String entryId;

  const AiAssistantDrawer({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<AiAssistantDrawer> createState() => _AiAssistantDrawerState();
}

class _AiAssistantDrawerState extends ConsumerState<AiAssistantDrawer> {
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _promptController.clear();
      _isLoading = true;
    });

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final p = Packer()
        ..packMapLength(2)
        ..packString('entry_id')
        ..packString(widget.entryId)
        ..packString('prompt')
        ..packString(text);

      final resp = await hbp.send(HbpFrame.request('shua.diary', 'ai.chat', p.takeBytes()));
      String reply = 'JBC task executed successfully.';
      if (resp.payload.isNotEmpty) {
        try {
          final u = Unpacker(Uint8List.fromList(resp.payload));
          final len = u.unpackMapLength();
          for (var i = 0; i < len; i++) {
            final k = u.unpackString();
            if (k == 'content') {
              reply = u.unpackString() ?? reply;
            } else {
              _unpackValue(u);
            }
          }
        } catch (_) {}
      }

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });

      // Refresh active entry blocks in case tools mutated blocks
      ref.invalidate(activeEntryNotifierProvider(widget.entryId));
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
        _isLoading = false;
      });
    }
  }

  Future<void> _elevateEntry() async {
    final theme = Theme.of(context);
    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final p = Packer()
        ..packMapLength(1)
        ..packString('entry_id')
        ..packString(widget.entryId);

      await hbp.send(HbpFrame.request('shua.diary', 'memory.elevate', p.takeBytes()));
      ref.invalidate(activeEntryNotifierProvider(widget.entryId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Milestone elevated to Global Identity Matrix!'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Elevation failed: $e'), backgroundColor: theme.colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('JBC AI Copilot', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),

          // Global Memory Elevator Banner
          OutlinedButton.icon(
            icon: const Icon(Icons.stars, color: Colors.amber),
            label: const Text('Elevate Milestone to Global Memory'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            onPressed: _elevateEntry,
          ),

          const SizedBox(height: 12),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Ask JBC to generate checklists, analyze sentiment, or summarize study notes...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, idx) {
                      final msg = _messages[idx];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['content']!,
                            style: TextStyle(
                              color: isUser ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),

          // Prompt input box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: 'Ask JBC...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendPrompt(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: _sendPrompt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

dynamic _unpackValue(Unpacker u) {
  try { return u.unpackString(); } catch (_) {
    try { return u.unpackInt(); } catch (_) {
      try { return u.unpackBool(); } catch (_) {
        try { return u.unpackDouble(); } catch (_) {
          return null;
        }
      }
    }
  }
}
