import 'item.dart';

class Invoice {
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessEmail;
  String businessAbn;
  String clientName;
  String clientAddress;
  String invoiceNumber;
  DateTime date;
  String currency;
  List<Item> items;

  /// Pro-only configurable fields (default to free-tier behaviour).
  int dueDays;
  double discountPercent;
  double taxPercent;

  /// Raw bytes of the picked logo (so we can embed it in the PDF).
  /// Stored as bytes (not a path) so it survives across Android scoped storage.
  List<int>? logoBytes;

  Invoice({
    required this.businessName,
    required this.businessAddress,
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessAbn = '',
    required this.clientName,
    required this.clientAddress,
    required this.invoiceNumber,
    required this.date,
    required this.currency,
    required this.items,
    this.dueDays = 14,
    this.discountPercent = 0.0,
    this.taxPercent = 0.0,
    this.logoBytes,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  double get discountAmount => subtotal * (discountPercent / 100.0);

  double get afterDiscount => subtotal - discountAmount;

  double get taxAmount => afterDiscount * (taxPercent / 100.0);

  double get total => afterDiscount + taxAmount;
}
