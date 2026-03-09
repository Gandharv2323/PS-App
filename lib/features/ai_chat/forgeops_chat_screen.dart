import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
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
          'ForgeOps AI online.\n\nI have live access to your floor data: attendance, inventory, machines, work orders, alerts, and payroll.\n\nWhat do you need?',
      time: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
  ];
  bool _thinking = false;

  final List<String> _quickPrompts = [
    'Floor status right now?',
    'Low stock items?',
    'Machines needing maintenance?',
    'Open work orders?',
    'Attendance today?',
    'Active alerts?',
    'Payroll this month?',
  ];

  Future<String> _queryLiveData(String userText) async {
    final db = await DatabaseHelper.instance.database;
    final lower = userText.toLowerCase();
    final today = DateTime.now().toString().substring(0, 10);
    final month = DateTime.now().toString().substring(0, 7);

    // ─── FLOOR STATUS ─────────────────────────────────────────────────
    if (lower.contains('floor') ||
        lower.contains('status') ||
        lower.contains('overview')) {
      final present = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM attendance WHERE date=? AND status='PRESENT'",
        [today],
      )).first['c'];
      final totalEmp = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM employees WHERE is_active=1",
      )).first['c'];
      final running = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM machines WHERE status='RUNNING'",
      )).first['c'];
      final totalMac = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM machines",
      )).first['c'];
      final woOpen = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM work_orders WHERE status IN ('PENDING','IN_PROGRESS')",
      )).first['c'];
      final alerts = (await db.rawQuery(
        "SELECT COUNT(*) as c FROM alerts WHERE is_resolved=0",
      )).first['c'];
      return 'Floor Status — $today:\n• 👷 Workers: $present / $totalEmp present\n• ⚙️ Machines: $running / $totalMac running\n• 📋 Open Work Orders: $woOpen\n• ⚠️ Unresolved Alerts: $alerts';
    }

    // ─── LOW STOCK / INVENTORY ─────────────────────────────────────────
    if (lower.contains('stock') ||
        lower.contains('inventory') ||
        lower.contains('item')) {
      final lowStock = await db.rawQuery(
        'SELECT name, quantity, reorder_level FROM inventory WHERE quantity <= reorder_level',
      );
      if (lowStock.isEmpty) {
        return 'Inventory: No items below reorder level. All stock levels are adequate.';
      }
      final lines = lowStock
          .map(
            (r) =>
                '• ${r['name']} — ${r['quantity']} left (reorder at ${r['reorder_level']})',
          )
          .join('\n');
      return 'Low Stock Alert (${lowStock.length} items):\n$lines\n\nRaise purchase orders immediately.';
    }

    // ─── MACHINES / MAINTENANCE ────────────────────────────────────────
    if (lower.contains('machine') ||
        lower.contains('maintenance') ||
        lower.contains('service')) {
      final overdue = await db.rawQuery(
        "SELECT name, next_service_due, status FROM machines WHERE next_service_due < ? OR status='MAINTENANCE'",
        [today],
      );
      final all = await db.query('machines');
      final running = all.where((m) => m['status'] == 'RUNNING').length;
      final idle = all.where((m) => m['status'] == 'IDLE').length;
      final offline = all.where((m) => m['status'] == 'OFFLINE').length;
      String resp =
          'Machines (${all.length} total):\n• Running: $running  Idle: $idle  Offline: $offline\n';
      if (overdue.isNotEmpty) {
        resp += '\n⚠️ Maintenance Due / Overdue:\n';
        resp += overdue
            .map((m) => '• ${m['name']} — due ${m['next_service_due']}')
            .join('\n');
        resp += '\n\nSchedule maintenance now to avoid production halt.';
      } else {
        resp += '\n✅ All machines are within service schedule.';
      }
      return resp;
    }

    // ─── WORK ORDERS ───────────────────────────────────────────────────
    if (lower.contains('work order') ||
        lower.contains('wo') ||
        lower.contains('jobs')) {
      final open = await db.rawQuery(
        "SELECT wo_number, subject, priority, status FROM work_orders WHERE status IN ('PENDING','IN_PROGRESS') ORDER BY CASE priority WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END",
      );
      if (open.isEmpty) {
        return 'Work Orders: No open work orders. All caught up.';
      }
      final lines = open
          .map(
            (w) =>
                '• ${w['wo_number']} [${w['priority']}] — ${w['subject']} (${w['status']})',
          )
          .join('\n');
      return 'Open Work Orders (${open.length}):\n$lines';
    }

    // ─── ATTENDANCE ────────────────────────────────────────────────────
    if (lower.contains('attendance') ||
        lower.contains('present') ||
        lower.contains('absent')) {
      final records = await db.rawQuery(
        '''SELECT e.name, a.status, a.check_in, a.check_out
           FROM attendance a JOIN employees e ON a.employee_id = e.id
           WHERE a.date = ? ORDER BY e.name''',
        [today],
      );
      if (records.isEmpty) {
        return 'Attendance: No records marked yet for today ($today).';
      }
      final present = records.where((r) => r['status'] == 'PRESENT').length;
      final absent = records.where((r) => r['status'] == 'ABSENT').length;
      final absentNames = records
          .where((r) => r['status'] == 'ABSENT')
          .map((r) => r['name'] as String)
          .join(', ');
      return 'Attendance — $today:\n• ✅ Present: $present\n• ❌ Absent: $absent${absentNames.isNotEmpty ? ' ($absentNames)' : ''}\n• Total tracked: ${records.length}';
    }

    // ─── ALERTS ────────────────────────────────────────────────────────
    if (lower.contains('alert') ||
        lower.contains('critical') ||
        lower.contains('warning')) {
      final alerts = await db.query(
        'alerts',
        where: 'is_resolved=0',
        orderBy: 'triggered_at DESC',
      );
      if (alerts.isEmpty) {
        return 'Alerts: No active alerts. Floor is running clean.';
      }
      final lines = alerts
          .map((a) => '• [${a['severity']}] ${a['message']}')
          .join('\n');
      return 'Active Alerts (${alerts.length}):\n$lines\n\nResolve CRITICAL alerts first.';
    }

    // ─── PAYROLL ─────────────────────────────────────────────────────
    if (lower.contains('payroll') ||
        lower.contains('salary') ||
        lower.contains('pay')) {
      final records = await db.rawQuery(
        '''SELECT e.name, p.net_pay, p.paid_days FROM payroll p
           JOIN employees e ON p.employee_id = e.id
           WHERE p.month = ?''',
        [month],
      );
      if (records.isEmpty) {
        return 'Payroll: No payslips generated for $month yet. Use the Generate All button in Payroll screen.';
      }
      final total = records.fold<double>(
        0,
        (sum, r) => sum + ((r['net_pay'] as num?)?.toDouble() ?? 0),
      );
      return 'Payroll — $month (${records.length} employees):\nTotal payout: ₹${total.toStringAsFixed(0)}\n\n${records.map((r) => '• ${r['name']}: ₹${r['net_pay']} (${r['paid_days']} days)').join('\n')}';
    }

    // ─── EMPLOYEES ────────────────────────────────────────────────────
    if (lower.contains('employee') ||
        lower.contains('staff') ||
        lower.contains('worker')) {
      final emps = await db.query(
        'employees',
        where: 'is_active=1',
        orderBy: 'name',
      );
      return 'Active Employees (${emps.length}):\n${emps.map((e) => '• ${e['name']} — ${e['designation']} (${e['department']})').join('\n')}';
    }

    // ─── CYLINDERS ────────────────────────────────────────────────────
    if (lower.contains('cylinder') || lower.contains('gas')) {
      final cyls = await db.query('cylinders');
      final empty = cyls.where((c) => c['status'] == 'EMPTY').length;
      final full = cyls.where((c) => c['status'] == 'FULL').length;
      final partial = cyls.where((c) => c['status'] == 'PARTIAL').length;
      return 'Gas Cylinders (${cyls.length} total):\n• Full: $full\n• Partial: $partial\n• Empty: $empty\n${empty > 0 ? '\n⚠️ $empty cylinders need refilling.' : ''}';
    }

    return "That query isn't in my current data scope. Try asking about: floor status, machines, inventory, work orders, attendance, alerts, payroll, cylinders, or employees.";
  }

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

    _processFullQuery(text).then((response) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(isAI: true, text: response, time: DateTime.now()),
        );
        _thinking = false;
      });
      _scrollToBottom();
    });
  }

  Future<String> _processFullQuery(String message) async {
    // 1. Get local context from offline database
    final localContext = await _queryLiveData(message);

    // 2. Read Gemini API key
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');

    // 3. Fallback to raw offline context if no API key
    if (apiKey == null || apiKey.trim().isEmpty) {
      return localContext;
    }

    // 4. Hybrid AI: Pass local SQL context tightly into Gemini
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey.trim(),
      );

      final prompt =
          '''
You are ForgeOps AI, a premium industrial manufacturing factory assistant.
Answer the user's query exactly, clearly, and conversationally.
You MUST base your answer strictly on the following Local Database Context below.
If the context says no records were found or provides an error, politely inform the user.
Keep it strictly professional and concise.

User Query: $message

Local Database Context:
$localContext
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? localContext;
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return "⚠️ **AI Generation Failed** (Network or API issue). Displaying raw local data:\n\n$localContext";
    }
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
                      'Live SQLite',
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
                      hintText: 'Ask about floor, inventory, machines...',
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
