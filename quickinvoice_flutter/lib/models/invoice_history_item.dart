/// Lightweight metadata persisted for every generated invoice.
/// Not the full [Invoice] — only what the History screen needs.
class InvoiceHistoryItem {
  final String invoiceNumber;
  final String clientName;
  final String businessName;
  final DateTime date;
  final double total;
  final String currency;
  final String pdfPath;

  const InvoiceHistoryItem({
    required this.invoiceNumber,
    required this.clientName,
    required this.businessName,
    required this.date,
    required this.total,
    required this.currency,
    required this.pdfPath,
  });

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'clientName': clientName,
        'businessName': businessName,
        'date': date.toIso8601String(),
        'total': total,
        'currency': currency,
        'pdfPath': pdfPath,
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
      );
}
