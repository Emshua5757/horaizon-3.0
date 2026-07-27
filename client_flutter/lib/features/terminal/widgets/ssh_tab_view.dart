import 'package:flutter/material.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/telemetry_log_item.dart';

/// Tab 2: Raspberry Pi 5 SSH Shell Terminal Tab View
class SshTabView extends StatefulWidget {
  final List<SshOutputLine> sshHistory;
  final Function(String) onCommandSubmitted;

  const SshTabView({
    super.key,
    required this.sshHistory,
    required this.onCommandSubmitted,
  });

  @override
  State<SshTabView> createState() => _SshTabViewState();
}

class _SshTabViewState extends State<SshTabView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _stdinController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _stdinController.text.trim();
    if (text.isNotEmpty) {
      _stdinController.clear();
      widget.onCommandSubmitted(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Quick Action Command Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            child: Row(
              children: [
                Text(
                  'QUICK COMMANDS:',
                  style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 10),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickCmdChip(label: 'tailscale status', onTap: () => widget.onCommandSubmitted('tailscale status')),
                        const SizedBox(width: 6),
                        _QuickCmdChip(label: 'systemctl status shua-governor', onTap: () => widget.onCommandSubmitted('systemctl status shua-governor')),
                        const SizedBox(width: 6),
                        _QuickCmdChip(label: 'systemctl status tailscale-watchdog', onTap: () => widget.onCommandSubmitted('systemctl status tailscale-watchdog')),
                        const SizedBox(width: 6),
                        _QuickCmdChip(label: 'uptime', onTap: () => widget.onCommandSubmitted('uptime')),
                        const SizedBox(width: 6),
                        _QuickCmdChip(label: 'df -h', onTap: () => widget.onCommandSubmitted('df -h')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // SSH Terminal Output Window
          Expanded(
            child: Container(
              color: cs.surfaceContainerLowest,
              padding: const EdgeInsets.all(14),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.sshHistory.length,
                itemBuilder: (context, index) {
                  final line = widget.sshHistory[index];
                  if (line.isCommand) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${line.prompt} ',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line.text,
                              style: TextStyle(
                                color: cs.secondary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      line.text,
                      style: TextStyle(
                        color: line.isError ? const Color(0xFFEF4444) : cs.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // SSH Stdin Prompt Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Text(
                  'shua@horaizon-pi5:\$',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _stdinController,
                    style: TextStyle(color: cs.onSurface, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Enter remote bash command...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'monospace'),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, size: 16, color: cs.primary),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCmdChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickCmdChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(color: cs.primary, fontSize: 10, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
