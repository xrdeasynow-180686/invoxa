import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/invoice_history_item.dart';

/// Persistent invoice-history store. Uses SharedPreferences as a JSON blob —
/// no new dependencies, no migration, survives app restarts/reinstalls (as
/// long as the user hasn't wiped app data).
class HistoryStorage {
  static const _key = 'invoice_history_v1';
  static const int _maxItems = 200;

  static Future<List<InvoiceHistoryItem>> getAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              InvoiceHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(InvoiceHistoryItem item) async {
    final list = await getAll();
    // De-dupe by invoice number (overwrite any previous entry with same #).
    list.removeWhere((e) => e.invoiceNumber == item.invoiceNumber);
    list.insert(0, item);
    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> remove(String invoiceNumber) async {
    final list = await getAll();
    list.removeWhere((e) => e.invoiceNumber == invoiceNumber);
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  /// Toggles or sets the paid/pending status for a given invoice.
  static Future<void> setStatus(String invoiceNumber, String status) async {
    final list = await getAll();
    final idx = list.indexWhere((e) => e.invoiceNumber == invoiceNumber);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(
      status: status,
      paidAt: status == 'paid' ? DateTime.now() : null,
    );
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
