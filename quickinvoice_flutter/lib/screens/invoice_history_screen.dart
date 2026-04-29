import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice_history_item.dart';
import '../services/history_storage.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

/// Home screen: shows every persisted invoice and offers a FAB to create
/// a new one. After a successful creation the form pops back here, the
/// list refreshes and the new invoice appears at the top.
class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<InvoiceHistoryItem> _items = [];
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

  Future<void> _openForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
    );
    _load(); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InovXA'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final it = _items[i];
                      return Card(
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            child: const Icon(Icons.receipt_long,
                                color: Colors.indigo),
                          ),
                          title: Text(
                            it.clientName.isEmpty
                                ? 'Unknown client'
                                : it.clientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${it.invoiceNumber}\n${DateFormat('dd MMM yyyy').format(it.date)}'),
                          isThreeLine: true,
                          trailing: Text(
                              '${it.currency}${it.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceDetailScreen(item: it),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
        onPressed: _openForm,
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      // ListView so RefreshIndicator still works on empty state
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.receipt_long_outlined,
            size: 64, color: Colors.indigo),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'No invoices yet',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap "New invoice" below to create your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}
