import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('forgeops.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE work_orders ADD COLUMN timer_start TEXT',
          );
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        designation TEXT,
        department TEXT,
        contact TEXT,
        shift TEXT,
        skills TEXT,
        role TEXT DEFAULT 'WORKER',
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        check_in TEXT,
        check_out TEXT,
        hours_worked REAL DEFAULT 0,
        overtime_hours REAL DEFAULT 0,
        status TEXT DEFAULT 'PRESENT',
        leave_type TEXT,
        approval_status TEXT DEFAULT 'PENDING',
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        category TEXT,
        current_qty REAL DEFAULT 0,
        reorder_level REAL DEFAULT 0,
        unit TEXT DEFAULT 'pcs',
        location TEXT,
        last_transaction_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE inventory_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        qty REAL NOT NULL,
        reference TEXT,
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (item_id) REFERENCES inventory(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE machines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT UNIQUE NOT NULL,
        status TEXT DEFAULT 'IDLE',
        location TEXT,
        current_operator INTEGER,
        capacity REAL,
        last_serviced_date TEXT,
        next_service_due TEXT,
        runtime_today REAL DEFAULT 0,
        runtime_month REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE cylinders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_no TEXT UNIQUE NOT NULL,
        gas_type TEXT NOT NULL,
        capacity REAL,
        status TEXT DEFAULT 'FULL',
        last_refill_date TEXT,
        current_location TEXT,
        current_machine INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE work_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wo_number TEXT UNIQUE NOT NULL,
        subject TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'PENDING',
        priority TEXT DEFAULT 'MEDIUM',
        machine_id INTEGER,
        assigned_to INTEGER,
        deadline TEXT,
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        timer_start TEXT,
        FOREIGN KEY (machine_id) REFERENCES machines(id),
        FOREIGN KEY (assigned_to) REFERENCES employees(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        leave_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        duration INTEGER DEFAULT 1,
        reason TEXT,
        status TEXT DEFAULT 'PENDING',
        approver_id INTEGER,
        rejection_reason TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE payroll (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        base_salary REAL DEFAULT 0,
        paid_days INTEGER DEFAULT 0,
        overtime_pay REAL DEFAULT 0,
        deductions REAL DEFAULT 0,
        net_pay REAL DEFAULT 0,
        is_paid INTEGER DEFAULT 0,
        payment_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gstin TEXT,
        contact TEXT,
        email TEXT,
        address TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        order_number TEXT UNIQUE NOT NULL,
        status TEXT DEFAULT 'PENDING',
        is_approved INTEGER DEFAULT 0,
        invoice_total REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES clients(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        entity_name TEXT,
        severity TEXT DEFAULT 'INFO',
        is_resolved INTEGER DEFAULT 0,
        triggered_at TEXT DEFAULT CURRENT_TIMESTAMP,
        resolved_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        source TEXT DEFAULT 'APP',
        details TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Seed sample data
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Use relative dates from today for realistic demo
    final now = DateTime.now();
    final today = now.toString().substring(0, 10);
    final yesterday = now
        .subtract(const Duration(days: 1))
        .toString()
        .substring(0, 10);
    final lastMonth = DateTime(
      now.year,
      now.month - 1,
      1,
    ).toString().substring(0, 10);
    final nextMonth = DateTime(
      now.year,
      now.month + 1,
      15,
    ).toString().substring(0, 10);
    final twoWeeksAgo = now
        .subtract(const Duration(days: 14))
        .toString()
        .substring(0, 10);
    final threeWeeksAgo = now
        .subtract(const Duration(days: 21))
        .toString()
        .substring(0, 10);
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // ── Employees ──────────────────────────────────────────────
    await db.insert('employees', {
      'name': 'Ravi Shankar',
      'designation': 'Supervisor',
      'department': 'Fabrication',
      'contact': '+91-9876543210',
      'shift': 'Morning',
      'skills': 'Laser Cutting,QC',
      'role': 'SUPERVISOR',
      'is_active': 1,
    });
    await db.insert('employees', {
      'name': 'Arjun Mehta',
      'designation': 'Operator',
      'department': 'Fabrication',
      'contact': '+91-9876543211',
      'shift': 'Morning',
      'skills': 'CNC,Laser',
      'role': 'WORKER',
      'is_active': 1,
    });
    await db.insert('employees', {
      'name': 'Suresh Kumar',
      'designation': 'Operator',
      'department': 'Fabrication',
      'contact': '+91-9876543212',
      'shift': 'Morning',
      'skills': 'Laser Cutting',
      'role': 'WORKER',
      'is_active': 1,
    });
    await db.insert('employees', {
      'name': 'Priya Nair',
      'designation': 'Manager',
      'department': 'Operations',
      'contact': '+91-9876543213',
      'shift': 'Morning',
      'skills': 'Management,Planning',
      'role': 'MANAGER',
      'is_active': 1,
    });
    await db.insert('employees', {
      'name': 'Rajesh Gupta',
      'designation': 'Owner',
      'department': 'Management',
      'contact': '+91-9876543214',
      'shift': 'General',
      'skills': 'All',
      'role': 'OWNER',
      'is_active': 1,
    });

    // ── Machines ──────────────────────────────────────────────
    await db.insert('machines', {
      'name': 'Laser Cutter Alpha',
      'code': 'MCH-001',
      'status': 'RUNNING',
      'location': 'Bay 2, Floor 1',
      'capacity': 200.0,
      'last_serviced_date': twoWeeksAgo,
      'next_service_due': nextMonth,
      'runtime_today': 3.5,
      'runtime_month': 120.5,
    });
    await db.insert('machines', {
      'name': 'Laser Cutter Beta',
      'code': 'MCH-002',
      'status': 'RUNNING',
      'location': 'Bay 2, Floor 1',
      'capacity': 200.0,
      'last_serviced_date': twoWeeksAgo,
      'next_service_due': nextMonth,
      'runtime_today': 2.8,
      'runtime_month': 98.0,
    });
    await db.insert('machines', {
      'name': 'CNC Mill Delta', 'code': 'MCH-012',
      'status': 'MAINTENANCE', 'location': 'Bay 3, Floor 1',
      'capacity': 150.0,
      'last_serviced_date': threeWeeksAgo,
      // Overdue: set 2 days ago so maintenance badge shows
      'next_service_due': yesterday,
      'runtime_today': 0.0, 'runtime_month': 45.0,
    });
    await db.insert('machines', {
      'name': 'Laser Cutter Gamma',
      'code': 'MCH-005',
      'status': 'IDLE',
      'location': 'Bay 1, Floor 2',
      'capacity': 250.0,
      'last_serviced_date': threeWeeksAgo,
      'next_service_due': yesterday,
      'runtime_today': 0.0,
      'runtime_month': 67.5,
    });
    await db.insert('machines', {
      'name': 'Plasma Cutter Zeta',
      'code': 'MCH-009',
      'status': 'RUNNING',
      'location': 'Bay 1, Floor 1',
      'capacity': 180.0,
      'last_serviced_date': twoWeeksAgo,
      'next_service_due': nextMonth,
      'runtime_today': 4.2,
      'runtime_month': 132.0,
    });

    // ── Inventory ─────────────────────────────────────────────
    await db.insert('inventory', {
      'name': 'Nitrogen Gas Cylinder',
      'sku': 'GAS-N2-001',
      'category': 'Gas',
      'current_qty': 3,
      'reorder_level': 5,
      'unit': 'cylinders',
      'location': 'Gas Store',
    });
    await db.insert('inventory', {
      'name': 'Laser Lens 20mm',
      'sku': 'LNS-020-001',
      'category': 'Optics',
      'current_qty': 12,
      'reorder_level': 5,
      'unit': 'pcs',
      'location': 'Tools Store',
    });
    await db.insert('inventory', {
      'name': 'Copper Nozzle 1.5mm',
      'sku': 'NZL-CU-015',
      'category': 'Consumables',
      'current_qty': 45,
      'reorder_level': 20,
      'unit': 'pcs',
      'location': 'Tools Store',
    });
    await db.insert('inventory', {
      'name': 'SS 304 Plate (2mm)',
      'sku': 'PLT-SS304-2',
      'category': 'Raw Material',
      'current_qty': 28,
      'reorder_level': 10,
      'unit': 'sheets',
      'location': 'Raw Material Store',
    });
    await db.insert('inventory', {
      'name': 'Focus Lens FL-002',
      'sku': 'FL-002',
      'category': 'Optics',
      'current_qty': 3,
      'reorder_level': 5,
      'unit': 'pcs',
      'location': 'Tools Store',
    });
    await db.insert('inventory', {
      'name': 'CO2 Gas',
      'sku': 'GAS-CO2-001',
      'category': 'Gas',
      'current_qty': 2,
      'reorder_level': 5,
      'unit': 'cylinders',
      'location': 'Gas Store',
    });

    // ── Cylinders ─────────────────────────────────────────────
    await db.insert('cylinders', {
      'serial_no': 'CYL-N2-001',
      'gas_type': 'Nitrogen',
      'capacity': 50.0,
      'status': 'FULL',
      'last_refill_date': twoWeeksAgo,
      'current_location': 'Gas Store',
    });
    await db.insert('cylinders', {
      'serial_no': 'CYL-N2-002',
      'gas_type': 'Nitrogen',
      'capacity': 50.0,
      'status': 'IN_USE',
      'last_refill_date': threeWeeksAgo,
      'current_location': 'Bay 2',
    });
    await db.insert('cylinders', {
      'serial_no': 'CYL-O2-001',
      'gas_type': 'Oxygen',
      'capacity': 40.0,
      'status': 'EMPTY',
      'last_refill_date': threeWeeksAgo,
      'current_location': 'Gas Store',
    });
    await db.insert('cylinders', {
      'serial_no': 'CYL-CO2-001',
      'gas_type': 'CO2',
      'capacity': 30.0,
      'status': 'FULL',
      'last_refill_date': twoWeeksAgo,
      'current_location': 'Gas Store',
    });

    // ── Work Orders ───────────────────────────────────────────
    await db.insert('work_orders', {
      'wo_number': 'WO-1042',
      'subject': 'Cut 50 SS Plates for Client #3',
      'status': 'IN_PROGRESS',
      'priority': 'HIGH',
      'machine_id': 1,
      'assigned_to': 2,
      'deadline': today,
      'created_by': 1,
    });
    await db.insert('work_orders', {
      'wo_number': 'WO-1043',
      'subject': 'Laser Engrave Logo Batch',
      'status': 'PENDING',
      'priority': 'MEDIUM',
      'machine_id': 2,
      'assigned_to': 3,
      'deadline': nextMonth,
      'created_by': 1,
    });
    await db.insert('work_orders', {
      'wo_number': 'WO-1039',
      'subject': 'Plasma Cut Aluminum Profiles',
      'status': 'COMPLETED',
      'priority': 'LOW',
      'machine_id': 5,
      'assigned_to': 2,
      'deadline': yesterday,
      'created_by': 1,
    });
    await db.insert('work_orders', {
      'wo_number': 'WO-1044',
      'subject': 'Fabricate Safety Guards Batch',
      'status': 'PENDING',
      'priority': 'HIGH',
      'machine_id': 1,
      'assigned_to': 1,
      'deadline': nextMonth,
      'created_by': 4,
    });

    // ── Attendance ────────────────────────────────────────────
    await db.insert('attendance', {
      'employee_id': 1,
      'date': today,
      'check_in': '07:58',
      'check_out': null,
      'hours_worked': 5.5,
      'overtime_hours': 0.5,
      'status': 'PRESENT',
      'approval_status': 'APPROVED',
    });
    await db.insert('attendance', {
      'employee_id': 2,
      'date': today,
      'check_in': '08:02',
      'check_out': null,
      'hours_worked': 5.2,
      'overtime_hours': 0.0,
      'status': 'PRESENT',
      'approval_status': 'APPROVED',
    });
    await db.insert('attendance', {
      'employee_id': 3,
      'date': today,
      'check_in': null,
      'check_out': null,
      'hours_worked': 0.0,
      'overtime_hours': 0.0,
      'status': 'ABSENT',
      'approval_status': 'PENDING',
    });
    await db.insert('attendance', {
      'employee_id': 4,
      'date': today,
      'check_in': '09:00',
      'check_out': null,
      'hours_worked': 4.0,
      'overtime_hours': 0.0,
      'status': 'PRESENT',
      'approval_status': 'APPROVED',
    });
    await db.insert('attendance', {
      'employee_id': 5,
      'date': today,
      'check_in': '09:30',
      'check_out': null,
      'hours_worked': 3.5,
      'overtime_hours': 0.0,
      'status': 'PRESENT',
      'approval_status': 'APPROVED',
    });
    // Yesterday's attendance
    await db.insert('attendance', {
      'employee_id': 1,
      'date': yesterday,
      'check_in': '08:00',
      'check_out': '17:00',
      'hours_worked': 9.0,
      'overtime_hours': 1.0,
      'status': 'PRESENT',
      'approval_status': 'APPROVED',
    });
    await db.insert('attendance', {
      'employee_id': 2,
      'date': yesterday,
      'check_in': '08:05',
      'check_out': '17:00',
      'hours_worked': 8.9,
      'overtime_hours': 0.0,
      'status': 'PRESENT',
      'approval_status': 'APPROVED',
    });

    // ── Leaves ───────────────────────────────────────────────
    final prevWeek = now
        .subtract(const Duration(days: 7))
        .toString()
        .substring(0, 10);
    final prevWeekEnd = now
        .subtract(const Duration(days: 5))
        .toString()
        .substring(0, 10);
    await db.insert('leaves', {
      'employee_id': 1,
      'leave_type': 'SICK',
      'start_date': prevWeek,
      'end_date': prevWeekEnd,
      'from_date': prevWeek,
      'to_date': prevWeekEnd,
      'duration': 3,
      'reason': 'Fever and rest',
      'status': 'APPROVED',
      'approver_id': 4,
    });
    await db.insert('leaves', {
      'employee_id': 2,
      'leave_type': 'CASUAL',
      'start_date': yesterday,
      'end_date': yesterday,
      'from_date': yesterday,
      'to_date': yesterday,
      'duration': 1,
      'reason': 'Family function',
      'status': 'PENDING',
    });

    // ── Payroll (current month) ───────────────────────────────
    await db.insert('payroll', {
      'employee_id': 1,
      'month': currentMonth,
      'base_salary': 35000,
      'paid_days': 26,
      'overtime_pay': 2400,
      'deductions': 1500,
      'net_pay': 35900,
      'is_paid': 0,
    });
    await db.insert('payroll', {
      'employee_id': 2,
      'month': currentMonth,
      'base_salary': 22000,
      'paid_days': 25,
      'overtime_pay': 0,
      'deductions': 800,
      'net_pay': 21200,
      'is_paid': 0,
    });
    await db.insert('payroll', {
      'employee_id': 3,
      'month': currentMonth,
      'base_salary': 20000,
      'paid_days': 22,
      'overtime_pay': 0,
      'deductions': 1500,
      'net_pay': 18500,
      'is_paid': 0,
    });
    await db.insert('payroll', {
      'employee_id': 4,
      'month': currentMonth,
      'base_salary': 55000,
      'paid_days': 26,
      'overtime_pay': 0,
      'deductions': 4500,
      'net_pay': 50500,
      'is_paid': 1,
      'payment_date': yesterday,
    });
    await db.insert('payroll', {
      'employee_id': 5,
      'month': currentMonth,
      'base_salary': 120000,
      'paid_days': 26,
      'overtime_pay': 0,
      'deductions': 12000,
      'net_pay': 108000,
      'is_paid': 1,
      'payment_date': yesterday,
    });
    // Last month's payroll
    await db.insert('payroll', {
      'employee_id': 1,
      'month': lastMonth,
      'base_salary': 35000,
      'paid_days': 26,
      'overtime_pay': 1800,
      'deductions': 1500,
      'net_pay': 35300,
      'is_paid': 1,
      'payment_date': threeWeeksAgo,
    });
    await db.insert('payroll', {
      'employee_id': 2,
      'month': lastMonth,
      'base_salary': 22000,
      'paid_days': 26,
      'overtime_pay': 0,
      'deductions': 800,
      'net_pay': 21200,
      'is_paid': 1,
      'payment_date': threeWeeksAgo,
    });

    // ── Clients ───────────────────────────────────────────────
    await db.insert('clients', {
      'name': 'Tata Steel Ltd',
      'gstin': '27AAACT1234F1Z5',
      'contact': '+91-22-6665-7000',
      'email': 'procurement@tata.com',
      'address': 'Mumbai, Maharashtra',
    });
    await db.insert('clients', {
      'name': 'Mahindra Fabrications',
      'gstin': '27AAACM5678G2H7',
      'contact': '+91-20-2721-2121',
      'email': 'orders@mahindrafab.com',
      'address': 'Pune, Maharashtra',
    });
    await db.insert('clients', {
      'name': 'Larsen & Toubro Ltd',
      'gstin': '27AAACL9012H3Z2',
      'contact': '+91-22-6752-5656',
      'email': 'vendor@lntecc.com',
      'address': 'Navi Mumbai, Maharashtra',
    });

    // ── Alerts ────────────────────────────────────────────────
    await db.insert('alerts', {
      'type': 'LOW_STOCK',
      'message': 'Nitrogen Gas Cylinder below reorder level (3 of 5)',
      'entity_name': 'Nitrogen Gas Cylinder',
      'severity': 'CRITICAL',
      'is_resolved': 0,
    });
    await db.insert('alerts', {
      'type': 'MAINTENANCE_DUE',
      'message': 'CNC Mill Delta is overdue for maintenance',
      'entity_name': 'CNC Mill Delta',
      'severity': 'WARNING',
      'is_resolved': 0,
    });
    await db.insert('alerts', {
      'type': 'DEADLINE_APPROACHING',
      'message': 'WO-1042 deadline is today',
      'entity_name': 'WO-1042',
      'severity': 'WARNING',
      'is_resolved': 0,
    });
    await db.insert('alerts', {
      'type': 'LOW_STOCK',
      'message': 'CO2 Gas below reorder level (2 of 5)',
      'entity_name': 'CO2 Gas',
      'severity': 'CRITICAL',
      'is_resolved': 0,
    });
    await db.insert('alerts', {
      'type': 'ABSENT',
      'message': 'Suresh Kumar absent today — no check-in recorded',
      'entity_name': 'Suresh Kumar',
      'severity': 'INFO',
      'is_resolved': 0,
    });
  }

  // ── Helper: leave balance for an employee ──────────────────
  /// Returns map of { leaveType: usedDays } for current year
  Future<Map<String, int>> getLeaveUsed(int employeeId) async {
    final db = await database;
    final year = DateTime.now().year.toString();
    final rows = await db.rawQuery(
      '''
      SELECT leave_type, SUM(duration) as used
      FROM leaves
      WHERE employee_id = ? AND status = 'APPROVED'
        AND (from_date LIKE ? OR start_date LIKE ?)
      GROUP BY leave_type
      ''',
      [employeeId, '$year%', '$year%'],
    );
    final Map<String, int> result = {};
    for (final r in rows) {
      result[r['leave_type'] as String] = (r['used'] as num?)?.toInt() ?? 0;
    }
    return result;
  }

  /// Annual leave quota per type (configurable)
  static const Map<String, int> leaveQuota = {
    'SICK': 12,
    'CASUAL': 8,
    'EARNED': 15,
    'MATERNITY': 90,
  };
}
