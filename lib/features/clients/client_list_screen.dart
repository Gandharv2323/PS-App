import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/stat_card.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<Map<String, dynamic>> _clients = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final c = await db.query('clients', orderBy: 'company_name');
    setState(() {
      _clients = c;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _search.isEmpty
      ? _clients
      : _clients
            .where(
              (c) => (c['company_name'] as String).toLowerCase().contains(
                _search.toLowerCase(),
              ),
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search clients...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () =>
                                context.go('/clients/detail/${c['id']}'),
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
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (c['company_name'] as String)[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          color: AppTheme.primaryBlue,
                                        ),
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
                                          c['company_name'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          c['contact_person'] as String? ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          c['city'] as String? ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/clients/create-order'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.note_add_outlined),
      ),
    );
  }
}

class ClientDetailScreen extends StatefulWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});
  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Map<String, dynamic>? _client;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final c = await db.query(
      'clients',
      where: 'id=?',
      whereArgs: [widget.clientId],
    );
    if (c.isNotEmpty) {
      final orders = await db.query(
        'orders',
        where: 'client_id=?',
        whereArgs: [widget.clientId],
        orderBy: 'created_at DESC',
        limit: 10,
      );
      setState(() {
        _client = c.first;
        _orders = orders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_client == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/clients')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final totalValue = _orders.fold<double>(
      0,
      (s, o) => s + (o['total_amount'] as num? ?? 0).toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_client!['company_name'] as String),
        leading: BackButton(onPressed: () => context.go('/clients')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _client!['company_name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _client!['contact_person'] as String? ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_client!['city']}, ${_client!['state']}',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Orders',
                    value: '${_orders.length}',
                    icon: Icons.shopping_bag_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Total Value',
                    value: '₹${(totalValue / 1000).toStringAsFixed(0)}K',
                    icon: Icons.currency_rupee,
                    color: AppTheme.statusRunning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Phone',
                    _client!['phone'] as String? ?? 'N/A',
                    isDark,
                  ),
                  _buildInfoRow(
                    'GST',
                    _client!['gst_no'] as String? ?? 'N/A',
                    isDark,
                  ),
                  _buildInfoRow(
                    'City',
                    '${_client!['city']}, ${_client!['state']}',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/clients/create-order'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/clients/invoice-preview'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('Invoice'),
                  ),
                ),
              ],
            ),
            if (_orders.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'RECENT ORDERS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ..._orders.map(
                (o) => Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o['order_number'] as String? ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              o['created_at']?.toString().substring(0, 10) ??
                                  '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(o['total_amount'] as num? ?? 0).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) => Padding(
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
}

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  int? _selectedClient;
  String _dueDate = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.database.then((db) async {
      final c = await db.query('clients', orderBy: 'company_name');
      setState(() {
        _clients = c;
        if (c.isNotEmpty) _selectedClient = c.first['id'] as int;
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = await DatabaseHelper.instance.database;
    final count =
        (await db.rawQuery("SELECT COUNT(*) as c FROM orders")).first['c']
            as int;
    await db.insert('orders', {
      'client_id': _selectedClient,
      'order_number': 'ORD-${2100 + count}',
      'description': _descCtrl.text,
      'total_amount': double.tryParse(_amtCtrl.text) ?? 0,
      'status': 'PENDING',
      'due_date': _dueDate,
    });
    if (mounted) context.go('/clients');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        leading: BackButton(onPressed: () => context.go('/clients')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_clients.isNotEmpty) ...[
                Text(
                  'Client',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedClient,
                  onChanged: (v) => setState(() => _selectedClient = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0A0E1A)
                        : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: _clients
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text(c['company_name'] as String),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              _buildField(
                'Order Description',
                ctrl: _descCtrl,
                isDark: isDark,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Total Amount (₹)',
                ctrl: _amtCtrl,
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Due Date',
                ctrl: TextEditingController(text: _dueDate),
                isDark: isDark,
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    setState(() => _dueDate = d.toString().substring(0, 10));
                  }
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label, {
    TextEditingController? ctrl,
    required bool isDark,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A0E1A)
                : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        leading: BackButton(onPressed: () => context.go('/clients')),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
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
              Row(
                children: [
                  const Icon(
                    Icons.precision_manufacturing_rounded,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PS Laser',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const Text(
                        'Invoice #INV-2024-001',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'UNPAID',
                      style: TextStyle(
                        color: AppTheme.accentYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Bill To:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              Text(
                'Acme Corp',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Mumbai, Maharashtra',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                    children: ['Description', 'Qty', 'Rate', 'Amount']
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  ...[
                    ['Laser Cutting (Steel)', '10 pcs', '₹15,000', '₹1,50,000'],
                    ['Service Charge', '1', '₹5,000', '₹5,000'],
                  ].map(
                    (r) => TableRow(
                      children: r
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal: ₹1,55,000',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      'GST 18%: ₹27,900',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'TOTAL: ₹1,82,900',
                      style: TextStyle(
                        fontSize: 18,
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
}
