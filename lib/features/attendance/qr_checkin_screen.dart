import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_theme.dart';

class QrCheckinScreen extends StatefulWidget {
  const QrCheckinScreen({super.key});
  @override
  State<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends State<QrCheckinScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  String? _lastResult;
  String? _feedback;
  bool _success = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null || raw == _lastResult || _processing) return;

    setState(() {
      _processing = true;
      _lastResult = raw;
    });

    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now().toString().substring(0, 10);
    final now = DateTime.now().toString().substring(11, 16); // HH:MM

    int? employeeId;
    String employeeName = '';

    if (raw.startsWith('EMP:')) {
      employeeId = int.tryParse(raw.substring(4));
    } else {
      employeeId = int.tryParse(raw);
    }

    if (employeeId != null) {
      final empList = await db.query(
        'employees',
        where: 'id=? AND is_active=1',
        whereArgs: [employeeId],
      );
      if (empList.isNotEmpty) {
        employeeName = empList.first['name'] as String;
        final existing = await db.query(
          'attendance',
          where: 'employee_id=? AND date=?',
          whereArgs: [employeeId, today],
        );
        if (existing.isEmpty) {
          await db.insert('attendance', {
            'employee_id': employeeId,
            'date': today,
            'check_in': now,
            'status': 'PRESENT',
          });
          _setFeedback('✅ Check-in: $employeeName at $now', true);
        } else {
          final rec = existing.first;
          if (rec['check_out'] == null) {
            await db.update(
              'attendance',
              {'check_out': now},
              where: 'id=?',
              whereArgs: [rec['id']],
            );
            _setFeedback('🏁 Check-out: $employeeName at $now', true);
          } else {
            _setFeedback('ℹ️ $employeeName already checked out today', false);
          }
        }
      } else {
        _setFeedback('❌ Employee not found (ID: $employeeId)', false);
      }
    } else {
      _setFeedback('❌ Invalid QR code', false);
    }

    if (mounted) setState(() => _processing = false);
  }

  void _setFeedback(String msg, bool success) {
    if (!mounted) return;
    setState(() {
      _feedback = msg;
      _success = success;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _feedback = null;
          _lastResult = null;
        });
      }
    });
  }

  /// Simulate check-in for the currently logged-in user
  Future<void> _simulateCheckin() async {
    final session = context.read<SessionProvider>().session;
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now().toString().substring(0, 10);
    final now = DateTime.now().toString().substring(11, 16);
    final empId = session.userId;
    final existing = await db.query(
      'attendance',
      where: 'employee_id=? AND date=?',
      whereArgs: [empId, today],
    );
    if (!mounted) return;
    final name = session.userName;
    if (existing.isEmpty) {
      await db.insert('attendance', {
        'employee_id': empId,
        'date': today,
        'check_in': now,
        'status': 'PRESENT',
      });
      _setFeedback('✅ Check-in: $name at $now', true);
    } else {
      final rec = existing.first;
      if (rec['check_out'] == null) {
        await db.update(
          'attendance',
          {'check_out': now},
          where: 'id=?',
          whereArgs: [rec['id']],
        );
        _setFeedback('🏁 Check-out: $name at $now', true);
      } else {
        _setFeedback('ℹ️ Already checked out today', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Check-in'),
        leading: BackButton(onPressed: () => context.go('/attendance')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live camera feed
          MobileScanner(controller: _ctrl, onDetect: _onDetect),

          // Overlay frame
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _success ? AppTheme.accentGreen : AppTheme.primaryBlue,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at employee QR code',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ),

          // Feedback banner
          if (_feedback != null)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _success
                      ? AppTheme.accentGreen.withValues(alpha: 0.9)
                      : AppTheme.accentRed.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

          // Simulate check-in button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _simulateCheckin,
                icon: const Icon(Icons.person_pin_circle_outlined),
                label: const Text('My Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
