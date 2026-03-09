import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = context.watch<SessionProvider>().session;
    final isAdmin =
        session.role == UserRole.owner || session.role == UserRole.manager;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      session.userName.isNotEmpty ? session.userName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.userName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          session.role.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          session.department,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App Preferences
            _SettingSection('APP PREFERENCES', [
              _SettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: isDark ? 'Enabled' : 'Disabled',
                color: const Color(0xFF7C3AED),
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                  activeThumbColor: AppTheme.primaryBlue,
                ),
              ),
            ], isDark),

            // Admin settings
            if (isAdmin) ...[
              const SizedBox(height: 16),
              _SettingSection('ADMINISTRATION', [
                _SettingTile(
                  icon: Icons.business_outlined,
                  title: 'Company Profile',
                  color: AppTheme.primaryBlue,
                  onTap: () => context.go('/settings/company-profile'),
                ),
                _SettingTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'User Management',
                  color: AppTheme.accentOrange,
                  onTap: () => context.go('/settings/user-management'),
                ),
                _SettingTile(
                  icon: Icons.security_outlined,
                  title: 'Role Permissions',
                  color: const Color(0xFF7C3AED),
                  onTap: () => context.go('/settings/role-permissions'),
                ),
                _SettingTile(
                  icon: Icons.schedule_outlined,
                  title: 'Shift Templates',
                  color: AppTheme.statusRunning,
                  onTap: () => context.go('/settings/shift-templates'),
                ),
                _SettingTile(
                  icon: Icons.tune_outlined,
                  title: 'System Config',
                  color: const Color(0xFF00838F),
                  onTap: () => context.go('/settings/system-config'),
                ),
              ], isDark),
              const SizedBox(height: 16),
              _SettingSection('DATA & BACKUP', [
                _SettingTile(
                  icon: Icons.backup_outlined,
                  title: 'Backup & Restore',
                  color: AppTheme.accentYellow,
                  onTap: () => context.go('/settings/backup-restore'),
                ),
                _SettingTile(
                  icon: Icons.developer_mode_outlined,
                  title: 'Developer Tools',
                  color: AppTheme.accentRed,
                  onTap: () => context.go('/settings/developer-tools'),
                ),
              ], isDark),
            ],

            const SizedBox(height: 16),
            _SettingSection('ACCOUNT', [
              _SettingTile(
                icon: Icons.logout_outlined,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                color: AppTheme.accentRed,
                onTap: () async {
                  final sessionProv = context.read<SessionProvider>();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await sessionProv.logout();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ], isDark),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'ForgeOps v1.0.0 • PS Laser',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  final bool isDark;
  const _SettingSection(this.title, this.tiles, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: tiles
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < tiles.length - 1)
                        Divider(
                          height: 1,
                          indent: 52,
                          color: isDark
                              ? AppTheme.darkBorder
                              : const Color(0xFFF3F4F6),
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF6B7280),
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// Simple placeholder screens for sub-settings
class _PlaceholderSettings extends StatelessWidget {
  final String title;
  const _PlaceholderSettings(this.title);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: BackButton(onPressed: () => context.go('/settings')),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 64,
            color: Color(0xFF4B5563),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Under construction',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    ),
  );
}

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('Company Profile');
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('User Management');
}

class EditUserScreen extends StatelessWidget {
  const EditUserScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderSettings('Edit User');
}

class RolePermissionsScreen extends StatelessWidget {
  const RolePermissionsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('Role Permissions');
}

class ShiftTemplatesScreen extends StatelessWidget {
  const ShiftTemplatesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('Shift Templates');
}

class SystemConfigScreen extends StatelessWidget {
  const SystemConfigScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('System Config');
}

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('Backup & Restore');
}

class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderSettings('Developer Tools');
}
