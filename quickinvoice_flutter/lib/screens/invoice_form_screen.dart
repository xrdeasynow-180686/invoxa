import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice.dart';
import '../models/item.dart';
import '../services/business_storage.dart';
import '../services/pdf_service.dart';
import '../services/usage_storage.dart';
import '../widgets/item_input_widget.dart';
import 'paywall_screen.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessName = TextEditingController();
  final _businessAddress = TextEditingController();
  final _businessPhone = TextEditingController();
  final _businessEmail = TextEditingController();
  final _businessAbn = TextEditingController();
  final _clientName = TextEditingController();
  final _clientAddress = TextEditingController();
  final _currency = TextEditingController(text: r'$');

  late String _invoiceNumber;
  DateTime _date = DateTime.now();
  List<int>? _logoBytes;
  Uint8List? _defaultLogoBytes;
  final List<Item> _items = [Item()];
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _invoiceNumber = _generateInvoiceNumber();
    _loadDefaultLogo();
    _loadSavedBusiness();
  }

  Future<void> _loadDefaultLogo() async {
    try {
      final bd = await rootBundle.load('assets/default_invoice_logo.png');
      if (!mounted) return;
      setState(() => _defaultLogoBytes = bd.buffer.asUint8List());
    } catch (_) {/* no-op */}
  }

  Future<void> _loadSavedBusiness() async {
    try {
      final profile = await BusinessStorage.load();
      if (!mounted) return;
      if (profile.isEmpty && profile.logoBytes == null) {
        // First launch — gently prompt the user.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showSnack('Welcome! Please enter your business details — they will be saved automatically.');
          _attachAutoSaveListeners();
        });
        return;
      }
      setState(() {
        _businessName.text = profile.name;
        _businessAddress.text = profile.address;
        _businessPhone.text = profile.phone;
        _businessEmail.text = profile.email;
        _businessAbn.text = profile.abn;
        if (profile.logoBytes != null) {
          _logoBytes = profile.logoBytes!.toList();
        }
      });
      _attachAutoSaveListeners();
    } catch (_) {
      // Ignore storage errors silently — the form remains usable.
      _attachAutoSaveListeners();
    }
  }

  bool _listenersAttached = false;
  void _attachAutoSaveListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    for (final c in [
      _businessName,
      _businessAddress,
      _businessPhone,
      _businessEmail,
      _businessAbn,
    ]) {
      c.addListener(_persistBusiness);
    }
  }

  Future<void> _persistBusiness() async {
    await BusinessStorage.save(
      name: _businessName.text,
      address: _businessAddress.text,
      phone: _businessPhone.text,
      email: _businessEmail.text,
      abn: _businessAbn.text,
      logoBytes: _logoBytes,
    );
  }

  Future<void> _clearSavedBusiness() async {
    await BusinessStorage.clear();
    if (!mounted) return;
    setState(() {
      _businessName.clear();
      _businessAddress.clear();
      _businessPhone.clear();
      _businessEmail.clear();
      _businessAbn.clear();
      _logoBytes = null;
    });
    _showSnack('Saved business details cleared.');
  }

  @override
  void dispose() {
    for (final c in [
      _businessName,
      _businessAddress,
      _businessPhone,
      _businessEmail,
      _businessAbn,
    ]) {
      c.removeListener(_persistBusiness);
    }
    _businessName.dispose();
    _businessAddress.dispose();
    _businessPhone.dispose();
    _businessEmail.dispose();
    _businessAbn.dispose();
    _clientName.dispose();
    _clientAddress.dispose();
    _currency.dispose();
    super.dispose();
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch.toString();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${ts.substring(ts.length - 5)}';
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      setState(() => _logoBytes = bytes);
      await _persistBusiness(); // save logo immediately
    } catch (e) {
      _showSnack('Could not pick image: $e');
    }
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  void _addItem() => setState(() => _items.add(Item()));

  void _removeItem(int index) {
    if (_items.length == 1) {
      _showSnack('At least one item is required.');
      return;
    }
    setState(() => _items.removeAt(index));
  }

  double get _total => _items.fold(0.0, (s, i) => s + i.total);

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _generateAndShare() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fix the errors in the form.');
      return;
    }
    if (_items.isEmpty) {
      _showSnack('Add at least one item.');
      return;
    }

    // Paywall gate — block when free quota is exhausted and user is not Pro.
    final allowed = await UsageStorage.canGenerateInvoice();
    if (!allowed) {
      if (!mounted) return;
      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      // Re-check after returning — proceed only if Pro is now active.
      if (unlocked != true && !(await UsageStorage.isPro())) {
        return;
      }
    }

    setState(() => _generating = true);
    try {
      // Persist business details locally for next time.
      await _persistBusiness();

      final invoice = Invoice(
        businessName: _businessName.text.trim(),
        businessAddress: _businessAddress.text.trim(),
        businessPhone: _businessPhone.text.trim(),
        businessEmail: _businessEmail.text.trim(),
        businessAbn: _businessAbn.text.trim(),
        clientName: _clientName.text.trim(),
        clientAddress: _clientAddress.text.trim(),
        invoiceNumber: _invoiceNumber,
        date: _date,
        currency: _currency.text.trim(),
        items: _items,
        logoBytes: _logoBytes,
      );

      final bytes = await PdfService.buildPdf(invoice);
      final path = await PdfService.savePdf(bytes, invoice.invoiceNumber);

      // Count this invoice toward the free quota.
      await UsageStorage.incrementInvoiceCount();

      if (!mounted) return;

      // Offer Preview / Share / Save options
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.indigo),
                title: const Text('Preview / Print'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.indigo),
                title: const Text('Share PDF'),
                subtitle: const Text('WhatsApp, Email, etc.'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Share.shareXFiles(
                    [XFile(path, mimeType: 'application/pdf')],
                    text: 'Invoice ${invoice.invoiceNumber}',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Saved locally'),
                subtitle: Text(path, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      _showSnack('Failed to generate PDF: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('InovXA'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Clear saved business',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearSavedBusiness,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _logoSection(),
              const SizedBox(height: 16),
              _section('Business'),
              TextFormField(
                controller: _businessName,
                decoration: _dec('Business name'),
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessAddress,
                decoration: _dec('Business address'),
                maxLines: 2,
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessPhone,
                decoration: _dec('Phone number'),
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessEmail,
                decoration: _dec('Email address'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                  return ok ? null : 'Invalid email';
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessAbn,
                decoration: _dec('Business / Tax number (optional)'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              _section('Client'),
              TextFormField(
                controller: _clientName,
                decoration: _dec('Client name'),
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientAddress,
                decoration: _dec('Client address'),
                maxLines: 2,
                validator: _required,
              ),
              const SizedBox(height: 16),
              _section('Invoice details'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InputDecorator(
                      decoration: _dec('Invoice #'),
                      child: Text(_invoiceNumber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _currency,
                      decoration: _dec('Currency'),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _dec('Date').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(dateStr),
                ),
              ),
              const SizedBox(height: 16),
              _section('Items'),
              ..._items.asMap().entries.map((e) => ItemInputWidget(
                    key: ValueKey('item-${e.key}-${_items.length}'),
                    index: e.key,
                    item: e.value,
                    onRemove: () => _removeItem(e.key),
                    onChanged: () => setState(() {}),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${_currency.text} ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _generating ? null : _generateAndShare,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    _generating ? 'Generating...' : 'Generate Invoice',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _logoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _logoBytes == null
                  ? (_defaultLogoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_defaultLogoBytes!,
                              fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Add logo',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        Uint8List.fromList(_logoBytes!),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          if (_logoBytes == null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Tap to upload your own logo',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          if (_logoBytes != null)
            TextButton.icon(
              onPressed: () async {
                setState(() => _logoBytes = null);
                await _persistBusiness();
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Use default logo'),
            ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            )),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
