import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invoice_history_item.dart';
import 'history_storage.dart';

/// Thin Provider-friendly wrapper around the existing [HistoryStorage].
/// Exposes the cached list, derived totals, theme mode, and CRUD helpers
/// — all UI binds to this single source of truth.
class InvoiceStore extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode';

  List<InvoiceHistoryItem> _items = [];
  bool _loading = true;
  ThemeMode _themeMode = ThemeMode.system;

  List<InvoiceHistoryItem> get items => _items;
  bool get loading => _loading;
  ThemeMode get themeMode => _themeMode;

  InvoiceTotals get totals {
    double earnings = 0;
    int paid = 0, pending = 0;
    for (final it in _items) {
      if (it.isPaid) {
        earnings += it.total;
        paid++;
      } else {
        pending++;
      }
    }
    return InvoiceTotals(earnings, paid, pending);
  }

  Future<void> bootstrap() async {
    await Future.wait([reload(), _loadTheme()]);
  }

  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    _items = await HistoryStorage.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> setStatus(String invoiceNumber, String status) async {
    await HistoryStorage.setStatus(invoiceNumber, status);
    await reload();
  }

  Future<void> remove(String invoiceNumber) async {
    await HistoryStorage.remove(invoiceNumber);
    await reload();
  }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kThemeMode) ?? 'system';
    _themeMode = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kThemeMode,
        m == ThemeMode.dark
            ? 'dark'
            : m == ThemeMode.light
                ? 'light'
                : 'system');
  }
}
