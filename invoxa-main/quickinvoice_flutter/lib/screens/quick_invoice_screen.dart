import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice.dart';
import '../models/invoice_history_item.dart';
import '../models/item.dart';
import '../services/analytics_service.dart';
import '../services/business_storage.dart';
import '../services/history_storage.dart';
import '../services/last_client_storage.dart';
import '../services/pdf_service.dart';
import '../services/usage_storage.dart';

/// Quick Invoice Mode — the fast path optimised for tradies finishing a
/// job on-site. Goal: job done → invoice created → sent via WhatsApp in
/// under 15 seconds.
///
/// Three fields only: client name, amount, optional note. Business
/// details, currency and the default "Service Work" item are auto-filled
/// from local storage.
class QuickInvoiceScreen extends StatefulWidget {
  const QuickInvoiceScreen({super.key});

  @override
  State<QuickInvoiceScreen> createState() => _QuickInvoiceScreenState();
}

class _QuickInvoiceScreenState extends State<QuickInvoiceScreen> {
  static const _primary = Color(0xFF1D2D8C); // stronger indigo, sunlight friendly
  static const _primaryDark = Color(0xFF0E1F4D);

  final _formKey = GlobalKey<FormState>();
  final _clientName = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  BusinessProfile? _profile;
  String _currency = r'$';
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final profile = await BusinessStorage.load();
    final last = await LastClientStorage.get();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _clientName.text = last;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _clientName.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _applyQuickAdd(String itemName, double price) {
    _amount.text = price.toStringAsFixed(2);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('$itemName applied'),
      ),
    );
  }

  Future<void> _generateAndShare() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final business = _profile;
    if (business == null || business.isEmpty) {
      _promptBusinessDetails();
      return;
    }

    setState(() => _generating = true);
    try {
      final amount = double.tryParse(_amount.text.trim()) ?? 0.0;
      final itemName = _note.text.trim().isEmpty
          ? 'Service Work'
          : _note.text.trim();

      final invoiceNumber = _generateInvoiceNumber();
      final invoice = Invoice(
        businessName: business.name,
        businessAddress: business.address,
        businessPhone: business.phone,
        businessEmail: business.email,
        businessAbn: business.abn,
        clientName: _clientName.text.trim(),
        clientAddress: '',
        invoiceNumber: invoiceNumber,
        date: DateTime.now(),
        currency: _currency,
        items: [Item(name: itemName, quantity: 1, price: amount)],
        dueDays: await UsageStorage.getDueDays(),
        discountPercent: 0.0,
        taxPercent: 0.0,
        logoBytes: business.logoBytes?.toList(),
      );

      final bytes = await PdfService.buildPdf(invoice);
      final path = await PdfService.savePdf(bytes, invoiceNumber);

      await HistoryStorage.add(InvoiceHistoryItem(
        invoiceNumber: invoiceNumber,
        clientName: invoice.clientName,
        businessName: invoice.businessName,
        date: invoice.date,
        total: invoice.total,
        currency: '$_currency ',
        pdfPath: path,
        status: InvoiceStatus.pending,
      ));
      await UsageStorage.incrementInvoiceCount();
      await LastClientStorage.set(invoice.clientName);

      // Analytics — fire and forget.
      AnalyticsService.logInvoiceCreated(
        total: invoice.total,
        currency: _currency,
        itemCount: invoice.items.length,
      );

      if (!mounted) return;
      // Fire the share sheet immediately — this is the "fast path".
      final result = await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf')],
        text: 'Invoice $invoiceNumber',
      );
      if (result.status == ShareResultStatus.success) {
        AnalyticsService.logInvoiceShared(invoiceNumber: invoiceNumber);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true); // tell home screen to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch.toString();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${ts.substring(ts.length - 5)}';
  }

  void _promptBusinessDetails() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add your business details'),
        content: const Text(
          'Quick Invoice needs your business name and contact details so it '
          'can fill them in automatically. Open "Detailed invoice" once to '
          'save them — it is a one-time step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Quick Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              _sectionLabel('Client'),
              _bigField(
                controller: _clientName,
                label: 'Client name',
                hint: 'e.g. Dave — 42 Baker St',
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              const SizedBox(height: 20),
              _sectionLabel('Amount'),
              _bigField(
                controller: _amount,
                label: 'Amount',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                prefix: Text(
                  '$_currency ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _quickAddRow(),
              const SizedBox(height: 20),
              _sectionLabel('Note (optional)'),
              _bigField(
                controller: _note,
                label: 'What was the job?',
                hint: 'Defaults to "Service Work"',
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 28),
              _generateButton(),
              const SizedBox(height: 12),
              _businessSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: _primaryDark,
          ),
        ),
      );

  Widget _bigField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefix: prefix,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: _primaryDark,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }

  Widget _quickAddRow() {
    return Row(
      children: [
        Expanded(
          child: _QuickAddButton(
            icon: Icons.directions_car_filled,
            label: 'Call-out Fee',
            onTap: () => _applyQuickAdd('Call-out Fee', 80),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAddButton(
            icon: Icons.access_time_filled,
            label: 'Hourly Rate',
            onTap: () => _applyQuickAdd('Hourly Rate', 95),
          ),
        ),
      ],
    );
  }

  Widget _generateButton() {
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withOpacity(0.6),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _generating ? null : _generateAndShare,
        icon: _generating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.ios_share, size: 24),
        label: Text(
          _generating ? 'Generating…' : 'Generate & Share Invoice',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _businessSummary() {
    final p = _profile;
    if (p == null || p.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add your business details once in "Detailed invoice" to enable Quick Invoice.',
                style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 18, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Billing as ${p.name.isEmpty ? "your business" : p.name}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8EDFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1D2D8C), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E1F4D),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
