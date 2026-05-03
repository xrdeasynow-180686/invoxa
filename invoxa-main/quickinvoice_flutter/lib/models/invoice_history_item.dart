/// Payment status of a past invoice.
/// Kept as a two-value enum for simplicity — tradies only need to know
/// "has the customer paid yet or not".
enum InvoiceStatus {
  pending,
  paid;

  String get label => switch (this) {
        InvoiceStatus.paid => 'Paid',
        InvoiceStatus.pending => 'Pending',
      };

  static InvoiceStatus fromString(String? s) {
    if (s == null) return InvoiceStatus.pending;
    return switch (s.toLowerCase().trim()) {
      'paid' => InvoiceStatus.paid,
      _ => InvoiceStatus.pending,
    };
  }
}

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
  final InvoiceStatus status;

  const InvoiceHistoryItem({
    required this.invoiceNumber,
    required this.clientName,
    required this.businessName,
    required this.date,
    required this.total,
    required this.currency,
    required this.pdfPath,
    this.status = InvoiceStatus.pending,
  });

  InvoiceHistoryItem copyWith({InvoiceStatus? status}) =>
      InvoiceHistoryItem(
        invoiceNumber: invoiceNumber,
        clientName: clientName,
        businessName: businessName,
        date: date,
        total: total,
        currency: currency,
        pdfPath: pdfPath,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'clientName': clientName,
        'businessName': businessName,
        'date': date.toIso8601String(),
        'total': total,
        'currency': currency,
        'pdfPath': pdfPath,
        'status': status.name,
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
        status: InvoiceStatus.fromString(j['status'] as String?),
      );
}
