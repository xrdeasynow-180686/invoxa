import 'package:flutter/material.dart';

import '../services/usage_storage.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _unlocked = false;
  bool _busy = false;
  int _selectedColor = 0;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final pro = await UsageStorage.isPro();
    final idx = await UsageStorage.getColorIndex();
    if (!mounted) return;
    setState(() {
      _unlocked = pro;
      _selectedColor = idx;
    });
  }

  Future<void> _unlockPro() async {
    setState(() => _busy = true);
    // TEST MODE — flip the local flag.
    await UsageStorage.setPro(true);
    if (!mounted) return;
    setState(() {
      _unlocked = true;
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pro unlocked! Enjoy unlimited invoices.')),
    );
  }

  Future<void> _pickColor(int idx) async {
    setState(() => _selectedColor = idx);
    await UsageStorage.setColorIndex(idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InovXA Pro'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      r'$4.99',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text('one-time payment',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_unlocked) _colorPicker() else _purchaseButtons(),
              const SizedBox(height: 24),
              if (_unlocked)
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

  Widget _purchaseButtons() {
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
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_open),
            label: Text(_busy ? 'Unlocking...' : 'Unlock Pro',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _busy ? null : _unlockPro,
          ),
        ),
        const SizedBox(height: 8),
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
}
