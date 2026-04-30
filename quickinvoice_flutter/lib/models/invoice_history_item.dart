import 'package:flutter/foundation.dart';

/// Lightweight metadata persisted for every generated invoice.
class InvoiceHistoryItem {
  final String invoiceNumber;
  final String clientName;
  final String businessName;
  final DateTime date;
  final double total;
  final String currency;
  final String pdfPath;

  /// "paid" or "pending" — defaults to pending for new invoices.
  final String status;
  final DateTime? paidAt;

  const InvoiceHistoryItem({
    required this.invoiceNumber,
    required this.clientName,
    required this.businessName,
    required this.date,
    required this.total,
    required this.currency,
    required this.pdfPath,
    this.status = 'pending',
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  InvoiceHistoryItem copyWith({String? status, DateTime? paidAt}) =>
      InvoiceHistoryItem(
        invoiceNumber: invoiceNumber,
        clientName: clientName,
        businessName: businessName,
        date: date,
        total: total,
        currency: currency,
        pdfPath: pdfPath,
        status: status ?? this.status,
        paidAt: paidAt ?? this.paidAt,
      );

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'clientName': clientName,
        'businessName': businessName,
        'date': date.toIso8601String(),
        'total': total,
        'currency': currency,
        'pdfPath': pdfPath,
        'status': status,
        if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      };

  factory InvoiceHistoryItem.fromJson(Map<String, dynamic> j) =>
      InvoiceHistoryItem(
        invoiceNumber: (j['invoiceNumber'] as String?) ?? '',
        clientName: (j['clientName'] as String?) ?? '',
        businessName: (j['businessName'] as String?) ?? '',
        date: DateTime.tryParse((j['date'] as String?) ?? '') ??
            DateTime.now(),
        total: ((j['total'] as num?) ?? 0).toDouble(),
        currency: (j['currency'] as String?) ?? '',
        pdfPath: (j['pdfPath'] as String?) ?? '',
        status: (j['status'] as String?) ?? 'pending',
        paidAt: DateTime.tryParse((j['paidAt'] as String?) ?? ''),
      );

  @override
  bool operator ==(Object other) =>
      other is InvoiceHistoryItem && other.invoiceNumber == invoiceNumber;
  @override
  int get hashCode => invoiceNumber.hashCode;
}

@immutable
class InvoiceTotals {
  final double earnings;
  final int paidCount;
  final int pendingCount;
  const InvoiceTotals(this.earnings, this.paidCount, this.pendingCount);
}
