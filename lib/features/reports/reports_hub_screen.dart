import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = [
      {
        'title': 'Attendance Report',
        'icon': Icons.people_outline,
        'color': AppTheme.primaryBlue,
        'route': '/reports/attendance',
      },
      {
        'title': 'Inventory Report',
        'icon': Icons.inventory_2_outlined,
        'color': AppTheme.accentOrange,
        'route': '/reports/inventory',
      },
      {
        'title': 'Production Report',
        'icon': Icons.precision_manufacturing_outlined,
        'color': AppTheme.statusRunning,
        'route': '/reports/production',
      },
      {
        'title': 'Financial Report',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF7C3AED),
        'route': '/reports/financial',
      },
      {
        'title': 'Work Order Report',
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFF00838F),
        'route': '/reports/work-orders',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports Hub',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Export and analyze your data',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'AVAILABLE REPORTS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = reports[i];
                return InkWell(
                  onTap: () => context.go(r['route'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (r['color'] as Color).withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            r['icon'] as IconData,
                            color: r['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            r['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : const Color(0xFF9CA3AF),
                        ),
                      ],
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

class _GenericReportScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _GenericReportScreen({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.go('/reports')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Report generation coming soon',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceReportScreen extends StatelessWidget {
  const AttendanceReportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _GenericReportScreen(
    title: 'Attendance Report',
    icon: Icons.people_outline,
    color: AppTheme.primaryBlue,
  );
}

class InventoryReportScreen extends StatelessWidget {
  const InventoryReportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _GenericReportScreen(
    title: 'Inventory Report',
    icon: Icons.inventory_2_outlined,
    color: AppTheme.accentOrange,
  );
}

class ProductionReportScreen extends StatelessWidget {
  const ProductionReportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _GenericReportScreen(
    title: 'Production Report',
    icon: Icons.precision_manufacturing_outlined,
    color: AppTheme.statusRunning,
  );
}

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _GenericReportScreen(
    title: 'Financial Report',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF7C3AED),
  );
}

class WorkOrderReportScreen extends StatelessWidget {
  const WorkOrderReportScreen({super.key});
  @override
  Widget build(BuildContext context) => const _GenericReportScreen(
    title: 'Work Order Report',
    icon: Icons.assignment_outlined,
    color: Color(0xFF00838F),
  );
}
