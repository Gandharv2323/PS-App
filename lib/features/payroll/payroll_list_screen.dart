import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({super.key});
  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  List<Map<String, dynamic>> _payroll = [];
  bool _loading = true;
  final String _month = DateTime.now().toString().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final records = await db.rawQuery(
      '''
      SELECT p.*, e.name, e.designation, e.department FROM payroll p
      JOIN employees e ON p.employee_id = e.id
      WHERE p.month = ? ORDER BY e.name
    ''',
      [_month],
    );
    if (!mounted) return;
    setState(() {
      _payroll = records;
      _loading = false;
    });
  }

  Future<void> _generateAll() async {
    // Only managers/owners can generate payroll
    final session = context.read<SessionProvider>().session;
    if (!session.canViewPayroll) return;

    final db = await DatabaseHelper.instance.database;
    // Get all active employees
    final employees = await db.query('employees', where: 'is_active = 1');
    int generated = 0;
    for (final emp in employees) {
      final empId = emp['id'] as int;
      // Check if payslip already exists for this month
      final existing = await db.query(
        'payroll',
        where: 'employee_id = ? AND month = ?',
        whereArgs: [empId, _month],
      );
      if (existing.isNotEmpty) continue;

      // Count paid attendance days this month
      final attRows = await db.rawQuery(
        '''
        SELECT COUNT(*) as days, SUM(overtime_hours) as ot
        FROM attendance
        WHERE employee_id = ? AND date LIKE ? AND status = 'PRESENT'
        ''',
        [empId, '$_month%'],
      );
      final paidDays = (attRows.first['days'] as num?)?.toInt() ?? 0;
      final otHours = (attRows.first['ot'] as num?)?.toDouble() ?? 0.0;

      // Base salary by role
      final role = emp['role'] as String;
      final baseSalary = switch (role) {
        'OWNER' => 120000.0,
        'MANAGER' => 55000.0,
        'SUPERVISOR' => 35000.0,
        _ => 22000.0,
      };
      final dailyRate = baseSalary / 26;
      final overtimePay = otHours * (dailyRate / 8) * 1.5;
      const deductions = 1200.0;
      final netPay = (dailyRate * paidDays) + overtimePay - deductions;

      await db.insert('payroll', {
        'employee_id': empId,
        'month': _month,
        'base_salary': baseSalary,
        'paid_days': paidDays,
        'overtime_pay': overtimePay.roundToDouble(),
        'deductions': deductions,
        'net_pay': netPay.roundToDouble(),
        'is_paid': 0,
      });
      generated++;
    }
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          generated > 0
              ? 'Generated $generated payslip${generated > 1 ? 's' : ''} for $_month'
              : 'All payslips already generated for $_month',
        ),
        backgroundColor: generated > 0
            ? AppTheme.statusRunning
            : AppTheme.accentOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalNet = _payroll.fold<double>(
      0,
      (sum, r) => sum + (r['net_pay'] as num? ?? 0).toDouble(),
    );
    final processed = _payroll.where((r) => r['status'] == 'PAID').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton(
            onPressed: _generateAll,
            child: const Text(
              'Generate',
              style: TextStyle(color: AppTheme.accentOrange),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYROLL SUMMARY — $_month',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Payout',
                              value:
                                  '₹${(totalNet / 1000).toStringAsFixed(0)}K',
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Processed',
                              value: '$processed/${_payroll.length}',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.statusRunning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _payroll.isEmpty
                      ? const Center(
                          child: Text(
                            'No payroll data for this period',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _payroll.length,
                          itemBuilder: (_, i) {
                            final p = _payroll[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () =>
                                    context.go('/payroll/payslip/${p['id']}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkCard
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
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
                                        backgroundColor: AppTheme.primaryBlue
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          (p['name'] as String)[0],
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['name'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                            Text(
                                              p['designation'] as String,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${(p['net_pay'] as num? ?? 0.0).toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          StatusBadge(
                                            status:
                                                p['status'] as String? ??
                                                'PENDING',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class PayslipPreviewScreen extends StatefulWidget {
  final int payslipId;
  const PayslipPreviewScreen({super.key, required this.payslipId});
  @override
  State<PayslipPreviewScreen> createState() => _PayslipPreviewScreenState();
}

class _PayslipPreviewScreenState extends State<PayslipPreviewScreen> {
  Map<String, dynamic>? _payslip;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final p = await db.rawQuery(
      'SELECT p.*, e.name, e.designation, e.department, e.mobile FROM payroll p JOIN employees e ON p.employee_id = e.id WHERE p.id=?',
      [widget.payslipId],
    );
    if (p.isNotEmpty && mounted) setState(() => _payslip = p.first);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_payslip == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/payroll')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final p = _payslip!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip'),
        leading: BackButton(onPressed: () => context.go('/payroll')),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.precision_manufacturing_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PS Laser',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Payslip — ${p['month']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildEmpRow('Employee', p['name'] as String, isDark),
              _buildEmpRow('Designation', p['designation'] as String, isDark),
              _buildEmpRow('Department', p['department'] as String, isDark),
              const Divider(height: 24),
              Text(
                'EARNINGS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              _buildAmtRow(
                'Basic Salary',
                '₹${(p['basic'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
              ),
              _buildAmtRow(
                'HRA',
                '₹${(p['hra'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
              ),
              _buildAmtRow(
                'Allowances',
                '₹${(p['allowances'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
              ),
              _buildAmtRow(
                'Gross Pay',
                '₹${(p['gross_pay'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
                bold: true,
              ),
              const Divider(height: 24),
              Text(
                'DEDUCTIONS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              _buildAmtRow(
                'PF',
                '₹${(p['pf'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
                color: AppTheme.accentRed,
              ),
              _buildAmtRow(
                'ESI',
                '₹${(p['esi'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
                color: AppTheme.accentRed,
              ),
              _buildAmtRow(
                'TDS',
                '₹${(p['tds'] as num? ?? 0).toStringAsFixed(0)}',
                isDark,
                color: AppTheme.accentRed,
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NET PAY',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      '₹${(p['net_pay'] as num? ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    ),
  );

  Widget _buildAmtRow(
    String label,
    String value,
    bool isDark, {
    bool bold = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF6B7280),
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? (isDark ? Colors.white : const Color(0xFF111827)),
          ),
        ),
      ],
    ),
  );
}
