import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice_history_item.dart';
import '../services/analytics_service.dart';
import '../services/history_storage.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceHistoryItem item;
  const InvoiceDetailScreen({super.key, required this.item});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  static const _primary = Color(0xFF1D2D8C);
  static const _primaryDark = Color(0xFF0E1F4D);

  late InvoiceHistoryItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _openPdf() async {
    final file = File(_item.pdfPath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PDF file no longer exists on this device.')),
      );
      return;
    }
    final result = await OpenFile.open(_item.pdfPath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF: ${result.message}')),
      );
    }
  }

  Future<void> _sharePdf() async {
    final result = await Share.shareXFiles(
      [XFile(_item.pdfPath, mimeType: 'application/pdf')],
      text: 'Invoice ${_item.invoiceNumber}',
    );
    if (result.status == ShareResultStatus.success) {
      AnalyticsService.logInvoiceShared(invoiceNumber: _item.invoiceNumber);
    }
  }

  Future<void> _toggleStatus() async {
    final next = _item.status == InvoiceStatus.paid
        ? InvoiceStatus.pending
        : InvoiceStatus.paid;
    final updated = await HistoryStorage.updateStatus(_item.invoiceNumber, next);
    if (updated != null && mounted) {
      setState(() => _item = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
              next == InvoiceStatus.paid ? 'Marked as Paid' : 'Marked as Pending'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy').format(_item.date);
    final paid = _item.status == InvoiceStatus.paid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Detail'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusBanner(paid),
              const SizedBox(height: 16),
              _row('Invoice #', _item.invoiceNumber),
              _row('Business',
                  _item.businessName.isEmpty ? '—' : _item.businessName),
              _row('Client',
                  _item.clientName.isEmpty ? '—' : _item.clientName),
              _row('Date', fmt),
              _row('Total',
                  '${_item.currency}${_item.total.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _row('File', _item.pdfPath, multiline: true),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Open PDF',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _openPdf,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryDark,
                    side: const BorderSide(color: _primary, width: 1.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: _sharePdf,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        paid ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    side: BorderSide(
                      color: paid
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF22C55E),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(paid ? Icons.schedule : Icons.check_circle),
                  label: Text(paid ? 'Mark as Pending' : 'Mark as Paid',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _toggleStatus,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete from history',
                    style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  await HistoryStorage.remove(_item.invoiceNumber);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBanner(bool paid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            paid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle : Icons.schedule,
            color: paid ? const Color(0xFF15803D) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          Text(
            paid ? 'Paid' : 'Pending payment',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color:
                  paid ? const Color(0xFF15803D) : const Color(0xFFB45309),
            ),
          ),
        ],
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
