import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  String? _error;

  // Demo credentials
  final _demoCredentials = [
    {
      'id': '1',
      'pin': '1234',
      'name': 'Ravi Shankar',
      'role': UserRole.supervisor,
      'dept': 'Fabrication',
      'shift': 'Morning',
      'teams': [12, 15, 19, 23, 27],
    },
    {
      'id': '2',
      'pin': '2345',
      'name': 'Arjun Mehta',
      'role': UserRole.worker,
      'dept': 'Fabrication',
      'shift': 'Morning',
      'teams': <int>[],
    },
    {
      'id': '4',
      'pin': '4567',
      'name': 'Priya Nair',
      'role': UserRole.manager,
      'dept': 'Operations',
      'shift': 'Morning',
      'teams': <int>[],
    },
    {
      'id': '5',
      'pin': '5678',
      'name': 'Rajesh Gupta',
      'role': UserRole.owner,
      'dept': 'Management',
      'shift': 'General',
      'teams': <int>[],
    },
  ];

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final cred = _demoCredentials
        .where(
          (c) => c['id'] == _employeeIdCtrl.text && c['pin'] == _pinCtrl.text,
        )
        .firstOrNull;

    if (cred == null) {
      setState(() {
        _isLoading = false;
        _error = 'Invalid Employee ID or PIN.';
      });
      return;
    }

    if (!mounted) return;
    await context.read<SessionProvider>().login(
      userId: int.parse(cred['id'] as String),
      userName: cred['name'] as String,
      role: cred['role'] as UserRole,
      department: cred['dept'] as String,
      shift: cred['shift'] as String,
      teamIds: List<int>.from(cred['teams'] as List),
    );
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.read<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFF0A1628),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ForgeOps',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manufacturing Intelligence Platform',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PS Laser Industries',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF93C5FD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your employee credentials',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Employee ID
                      Text(
                        'Employee ID',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _employeeIdCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 1, 2, 4, 5',
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBg
                              : const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => (v?.isEmpty ?? true)
                            ? 'Enter your employee ID'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // PIN
                      Text(
                        'PIN',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pinCtrl,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: '••••',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePin = !_obscurePin),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBg
                              : const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Enter your PIN' : null,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: AppTheme.accentRed,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Demo accounts
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEMO ACCOUNTS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      {
                        'id': '1',
                        'pin': '1234',
                        'name': 'Ravi Shankar',
                        'role': 'SUPERVISOR',
                      },
                      {
                        'id': '4',
                        'pin': '4567',
                        'name': 'Priya Nair',
                        'role': 'MANAGER',
                      },
                      {
                        'id': '5',
                        'pin': '5678',
                        'name': 'Rajesh Gupta',
                        'role': 'OWNER',
                      },
                      {
                        'id': '2',
                        'pin': '2345',
                        'name': 'Arjun Mehta',
                        'role': 'WORKER',
                      },
                    ].map(
                      (acc) => DemoAccountTile(
                        name: acc['name']!,
                        role: acc['role']!,
                        id: acc['id']!,
                        pin: acc['pin']!,
                        onTap: () {
                          _employeeIdCtrl.text = acc['id']!;
                          _pinCtrl.text = acc['pin']!;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Theme toggle
              TextButton.icon(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 18,
                  color: const Color(0xFF6B7280),
                ),
                label: Text(
                  isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoAccountTile extends StatelessWidget {
  final String name, role, id, pin;
  final VoidCallback onTap;
  const DemoAccountTile({
    super.key,
    required this.name,
    required this.role,
    required this.id,
    required this.pin,
    required this.onTap,
  });

  Color get _roleColor {
    switch (role) {
      case 'OWNER':
        return const Color(0xFF7C3AED);
      case 'MANAGER':
        return const Color(0xFF1565C0);
      case 'SUPERVISOR':
        return const Color(0xFF00838F);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _roleColor.withValues(alpha: 0.15),
              child: Text(
                name[0],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _roleColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    'ID: $id  PIN: $pin',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _roleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
