import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now().toString().substring(0, 10);
    final records = await db.rawQuery(
      '''
      SELECT a.*, e.name, e.designation, e.department 
      FROM attendance a JOIN employees e ON a.employee_id = e.id
      WHERE a.date = ? ORDER BY e.name
    ''',
      [today],
    );
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final present = _records.where((r) => r['status'] == 'PRESENT').length;
    final absent = _records.where((r) => r['status'] == 'ABSENT').length;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.go('/attendance/qr-checkin'),
          ),
          IconButton(
            icon: const Icon(Icons.supervisor_account_outlined),
            onPressed: () => context.go('/attendance/supervisor-approval'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Present',
                    value: '$present',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.statusRunning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'Absent',
                    value: '$absent',
                    icon: Icons.cancel_outlined,
                    color: AppTheme.accentRed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'Total',
                    value: '${_records.length}',
                    icon: Icons.people_outline,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY — ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][today.month - 1]} ${today.day}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 1.0,
                  ),
                ),
                TextButton(onPressed: _load, child: const Text('Refresh')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final status = r['status'] as String;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.statusColor(
                                  status,
                                ).withValues(alpha: 0.15),
                                child: Text(
                                  (r['name'] as String)[0],
                                  style: TextStyle(
                                    color: AppTheme.statusColor(status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      '${r['designation']} • ${r['department']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    if (r['check_in'] != null)
                                      Text(
                                        'In: ${r['check_in']}  ${r['check_out'] != null ? '• Out: ${r['check_out']}' : ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: status),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrCheckinScreen extends StatelessWidget {
  const QrCheckinScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Check-in'),
        leading: BackButton(onPressed: () => context.go('/attendance')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white38,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan your employee QR code',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check-in logged successfully!'),
                  ),
                );
                context.go('/attendance');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simulate Check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

class SupervisorApprovalScreen extends StatefulWidget {
  const SupervisorApprovalScreen({super.key});
  @override
  State<SupervisorApprovalScreen> createState() =>
      _SupervisorApprovalScreenState();
}

class _SupervisorApprovalScreenState extends State<SupervisorApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Approval'),
        leading: BackButton(onPressed: () => context.go('/attendance')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentYellow.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_outlined,
                  color: AppTheme.accentYellow,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overtime Approval',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Arjun Mehta — 2.5 hrs overtime today',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Overtime approved.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusRunning,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
