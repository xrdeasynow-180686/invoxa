import 'package:flutter/material.dart';

import '../services/billing_service.dart';
import '../services/usage_storage.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _billing = BillingService.instance;
  int _selectedColor = 0;

  @override
  void initState() {
    super.initState();
    _billing.addListener(_onBilling);
    _hydrate();
  }

  @override
  void dispose() {
    _billing.removeListener(_onBilling);
    super.dispose();
  }

  void _onBilling() {
    if (!mounted) return;
    if (_billing.isPro) {
      // Auto-close shortly after a successful purchase / restore.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro unlocked. Enjoy unlimited invoices!')),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _hydrate() async {
    final idx = await UsageStorage.getColorIndex();
    if (!mounted) return;
    setState(() => _selectedColor = idx);
  }

  Future<void> _pickColor(int idx) async {
    setState(() => _selectedColor = idx);
    await UsageStorage.setColorIndex(idx);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _billing.isPro;
    final price = _billing.formattedPrice.isEmpty
        ? '—'
        : _billing.formattedPrice;
    final purchasing = _billing.status == BillingStatus.purchasing ||
        _billing.status == BillingStatus.pending;
    final storeUnavailable =
        _billing.status == BillingStatus.storeUnavailable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('InovXA Pro'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Restore purchases',
            icon: const Icon(Icons.restore),
            onPressed: _billing.restorePurchases,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Icon(Icons.workspace_premium_outlined,
                    size: 72, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              const Text(
                'Unlock Unlimited Invoices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create and send invoices without limits.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _benefit('Unlimited invoices'),
              _benefit('Professional PDF'),
              _benefit('Save business details'),
              _benefit('Choose your invoice colour theme'),
              _benefit('Custom due date, discount % and tax %'),
              const SizedBox(height: 24),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_offer, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You are a Pro user — enjoy 20% discount on future upgrades',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(price,
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('one-time payment',
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (storeUnavailable)
                _errorBanner(
                    'Google Play is unavailable on this device. Sign in with a Google account that has Play Store installed.'),
              if (_billing.error != null && !unlocked)
                _errorBanner(_billing.error!),
              if (unlocked) _colorPicker() else _purchaseButtons(purchasing),
              const SizedBox(height: 24),
              if (unlocked)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Done'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _purchaseButtons(bool busy) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_open),
            label: Text(
              busy
                  ? 'Processing...'
                  : (_billing.product == null
                      ? 'Loading product...'
                      : 'Unlock Pro'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: busy || _billing.product == null
                ? null
                : _billing.buyPro,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _billing.restorePurchases,
          child: const Text('Restore purchases'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Continue free'),
        ),
      ],
    );
  }

  Widget _colorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick your invoice colour theme',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('Used as the accent and header colour on every PDF.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < kPalettes.length; i++)
              _swatch(i, kPalettes[i]),
          ],
        ),
      ],
    );
  }

  Widget _swatch(int i, InvoicePalette p) {
    final selected = i == _selectedColor;
    return GestureDetector(
      onTap: () => _pickColor(i),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? Color(p.navy) : Colors.grey.shade300,
              width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: Color(p.accent),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(p.name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
            if (selected)
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
