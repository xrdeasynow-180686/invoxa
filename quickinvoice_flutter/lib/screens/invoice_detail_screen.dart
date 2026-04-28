import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice_history_item.dart';
import '../services/history_storage.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceHistoryItem item;
  const InvoiceDetailScreen({super.key, required this.item});

  Future<void> _openPdf(BuildContext context) async {
    final file = File(item.pdfPath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PDF file no longer exists on this device.')),
      );
      return;
    }
    final result = await OpenFile.open(item.pdfPath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF: ${result.message}')),
      );
    }
  }

  Future<void> _sharePdf() async {
    await Share.shareXFiles(
      [XFile(item.pdfPath, mimeType: 'application/pdf')],
      text: 'Invoice ${item.invoiceNumber}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy').format(item.date);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Detail'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Invoice #', item.invoiceNumber),
            _row('Business',
                item.businessName.isEmpty ? '—' : item.businessName),
            _row('Client',
                item.clientName.isEmpty ? '—' : item.clientName),
            _row('Date', fmt),
            _row('Total',
                '${item.currency}${item.total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _row('File', item.pdfPath, multiline: true),
            const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Open PDF',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _openPdf(context),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: _sharePdf,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete from history',
                  style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await HistoryStorage.remove(item.invoiceNumber);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool multiline = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(v,
                maxLines: multiline ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15)),
          ],
        ),
      );
}
