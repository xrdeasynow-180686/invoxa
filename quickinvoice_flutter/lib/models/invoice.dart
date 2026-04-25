import 'item.dart';

class Invoice {
  String businessName;
  String businessAddress;
  String clientName;
  String clientAddress;
  String invoiceNumber;
  DateTime date;
  String currency;
  List<Item> items;

  /// Raw bytes of the picked logo (so we can embed it in the PDF).
  /// Stored as bytes (not a path) so it survives across Android scoped storage.
  List<int>? logoBytes;

  Invoice({
    required this.businessName,
    required this.businessAddress,
    required this.clientName,
    required this.clientAddress,
    required this.invoiceNumber,
    required this.date,
    required this.currency,
    required this.items,
    this.logoBytes,
  });

  double get total =>
      items.fold(0.0, (sum, item) => sum + item.total);
}
