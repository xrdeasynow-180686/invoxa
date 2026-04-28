import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice_history_item.dart';
import '../services/history_storage.dart';
import 'invoice_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No invoices yet.\nCreate one and it will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                )
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
    );
  }
}
