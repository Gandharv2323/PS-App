import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ForgeOpsChatScreen extends StatefulWidget {
  const ForgeOpsChatScreen({super.key});
  @override
  State<ForgeOpsChatScreen> createState() => _ForgeOpsChatScreenState();
}

class _ForgeOpsChatScreenState extends State<ForgeOpsChatScreen> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isAI: true,
      text:
          "ForgeOps AI online.\n\nI have live access to your floor data: attendance, inventory, machines, work orders, alerts, and payroll.\n\nWhat do you need?",
      time: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
  ];
  bool _thinking = false;

  final List<String> _quickPrompts = [
    'What\'s the floor status right now?',
    'Any low stock items?',
    'Machines needing maintenance?',
    'Open work orders today?',
    'Attendance summary for today?',
    'Show critical alerts',
  ];

  final Map<String, String> _responses = {
    'floor':
        '**Floor Status — Right Now:**\n• 🟢 6/8 machines running\n• 👷 14/16 workers present\n• 📋 3 active work orders\n• ⚠️ 2 unresolved alerts\n\nEverything is within normal parameters. Machine CNC-03 is idle — unscheduled stop at 10:22 AM.',
    'stock':
        '**Low Stock Alert:**\n• Copper Nozzle (1.5mm) — 4 pcs left (reorder: 10)\n• Lens Cover Glass — 2 pcs (reorder: 5)\n• N₂ Cylinders — 1 EMPTY at Station A\n\nFlagging this: Copper Nozzle at critical level. Raise PO immediately.',
    'maintenance':
        '**Machines Due for Maintenance:**\n• CNC-03 — overdue by 12 days\n• Laser #1 — due in 3 days\n\nCNC-03 is a production risk. Schedule maintenance today.',
    'work order':
        '**Open Work Orders:**\n• WO-1041 — HIGH — SS cutting batch (In Progress)\n• WO-1042 — MEDIUM — Mild steel plates (Pending)\n• WO-1043 — HIGH — Client delivery deadline: today\n\nWO-1043 has a today deadline. Assign to Team B immediately.',
    'attendance':
        '**Attendance Today:**\n• Present: 14/16\n• Absent: Ravi Kumar (no reason filed), Priya Nair (approved leave)\n• Late arrivals: 2 workers, 18 mins avg delay\n\nAll shifts covered.',
    'alert':
        '**Active Alerts:**\n• 🔴 CRITICAL: Copper Nozzle stock below minimum\n• 🟡 WARNING: CNC-03 maintenance overdue\n• 🟡 WARNING: WO-1043 deadline today\n\n3 alerts require action today.',
  };

  void _handleSend([String? quick]) {
    final text = quick ?? _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(isAI: false, text: text, time: DateTime.now()),
      );
      _thinking = true;
      _textCtrl.clear();
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final lower = text.toLowerCase();
      String response = "That data isn't available in the current dataset.";
      for (final key in _responses.keys) {
        if (lower.contains(key)) {
          response = _responses[key]!;
          break;
        }
      }
      setState(() {
        _messages.add(
          _ChatMessage(isAI: true, text: response, time: DateTime.now()),
        );
        _thinking = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0A0E1A)
            : const Color(0xFF0D1B2A),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ForgeOps AI',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusRunning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6EE7B7)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        leading: BackButton(
          color: Colors.white,
          onPressed: () => context.go('/dashboard'),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDark
          ? const Color(0xFF060A14)
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _ThinkingBubble();
                return _MessageBubble(message: _messages[i], isDark: isDark);
              },
            ),
          ),
          // Quick prompts
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => InkWell(
                onTap: () => _handleSend(_quickPrompts[i]),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _quickPrompts[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask ForgeOps AI...',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0D1B2A)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAI
                    ? (isDark ? const Color(0xFF0D1B2A) : Colors.white)
                    : AppTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAI ? 0 : 16),
                  topRight: Radius.circular(isAI ? 16 : 0),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isAI
                    ? Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE5E7EB),
                      )
                    : null,
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isAI
                      ? (isDark ? Colors.white : const Color(0xFF111827))
                      : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppTheme.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            child: const SizedBox(
              width: 40,
              height: 8,
              child: Text(
                '• • •',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isAI;
  final String text;
  final DateTime time;
  _ChatMessage({required this.isAI, required this.text, required this.time});
}
