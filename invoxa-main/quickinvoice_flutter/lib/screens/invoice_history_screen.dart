import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice_history_item.dart';
import '../services/history_storage.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';
import 'quick_invoice_screen.dart';

/// Home screen rebuilt for tradies: greeting, lightweight stats, one
/// giant primary "Create Invoice" action, and a readable recent-invoices
/// list with Paid / Pending status badges.
class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  static const _primary = Color(0xFF1D2D8C);
  static const _primaryDark = Color(0xFF0E1F4D);
  static const _bg = Color(0xFFF4F6FB);

  List<InvoiceHistoryItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await HistoryStorage.getAll();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _openQuickInvoice() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickInvoiceScreen()),
    );
    _load();
  }

  Future<void> _openDetailedForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
    );
    _load();
  }

  // ─────────────────── stats ───────────────────
  int get _monthCount {
    final now = DateTime.now();
    return _items
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .length;
  }

  double get _paidTotal => _items
      .where((e) => e.status == InvoiceStatus.paid)
      .fold(0.0, (s, e) => s + e.total);

  double get _pendingTotal => _items
      .where((e) => e.status == InvoiceStatus.pending)
      .fold(0.0, (s, e) => s + e.total);

  String get _currencyPrefix {
    if (_items.isEmpty) return r'$';
    return _items.first.currency.trim().isEmpty
        ? r'$'
        : _items.first.currency.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'InovXA',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            // data-testid-equivalent semantic label for debug/inspection
            key: const Key('home-refresh-btn'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _headerCard(),
                  _primaryCta(),
                  _secondaryCta(),
                  const SizedBox(height: 16),
                  _recentHeader(),
                  if (_items.isEmpty) _emptyState() else _invoiceList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─────────────────── header + stats ───────────────────
  Widget _headerCard() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to invoice your job?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _statsRow(),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final cur = _currencyPrefix;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'This month',
            value: '$_monthCount',
            icon: Icons.receipt_long,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Paid',
            value: '$cur${_paidTotal.toStringAsFixed(0)}',
            icon: Icons.check_circle,
            valueColor: const Color(0xFF22C55E),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Pending',
            value: '$cur${_pendingTotal.toStringAsFixed(0)}',
            icon: Icons.schedule,
            valueColor: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  // ─────────────────── CTAs ───────────────────
  Widget _primaryCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 72,
        child: ElevatedButton.icon(
          key: const Key('home-create-invoice-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _openQuickInvoice,
          icon: const Icon(Icons.add, size: 28),
          label: const Text(
            'Create Invoice',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          key: const Key('home-detailed-invoice-btn'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryDark,
            side: const BorderSide(color: _primary, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _openDetailedForm,
          icon: const Icon(Icons.edit_note),
          label: const Text(
            'Detailed invoice (items, tax…)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ─────────────────── recent list ───────────────────
  Widget _recentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Row(
        children: [
          const Text(
            'Recent invoices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryDark,
            ),
          ),
          const Spacer(),
          if (_items.isNotEmpty)
            Text(
              '${_items.length} total',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
        ],
      ),
    );
  }

  Widget _invoiceList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _InvoiceCard(
        item: _items[i],
        onTap: () => _openDetail(_items[i]),
      ),
    );
  }

  Future<void> _openDetail(InvoiceHistoryItem it) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(item: it)),
    );
    _load();
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: _primary),
            SizedBox(height: 12),
            Text(
              'No invoices yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Tap “+ Create Invoice” to send your first invoice in seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── stat tile ───────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── invoice card ───────────────────
class _InvoiceCard extends StatelessWidget {
  final InvoiceHistoryItem item;
  final VoidCallback onTap;

  const _InvoiceCard({required this.item, required this.onTap});

  static const _primaryDark = Color(0xFF0E1F4D);

  @override
  Widget build(BuildContext context) {
    final paid = item.status == InvoiceStatus.paid;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName.isEmpty
                          ? 'Unknown client'
                          : item.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StatusBadge(paid: paid),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            DateFormat('dd MMM yyyy').format(item.date),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.currency}${item.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool paid;
  const _StatusBadge({required this.paid});

  @override
  Widget build(BuildContext context) {
    final bg = paid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final fg = paid ? const Color(0xFF15803D) : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        paid ? 'Paid' : 'Pending',
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
