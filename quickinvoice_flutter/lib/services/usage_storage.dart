import 'package:shared_preferences/shared_preferences.dart';

/// Tracks invoice usage, Pro entitlement, and the chosen invoice colour theme.
/// All persistence is local (SharedPreferences). No backend.
class UsageStorage {
  static const _kCount = 'invoice_count';
  static const _kPro = 'is_pro';
  static const _kColor = 'theme_color_index';

  /// Free invoices a user can create before the paywall appears.
  static const int freeInvoiceLimit = 3;

  // ───────── invoice count ─────────
  static Future<int> getInvoiceCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kCount) ?? 0;
  }

  static Future<int> incrementInvoiceCount() async {
    final p = await SharedPreferences.getInstance();
    final next = (p.getInt(_kCount) ?? 0) + 1;
    await p.setInt(_kCount, next);
    return next;
  }

  // ───────── pro entitlement ─────────
  static Future<bool> isPro() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kPro) ?? false;
  }

  static Future<void> setPro(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPro, value);
  }

  /// Returns true if the user is allowed to generate the next invoice.
  static Future<bool> canGenerateInvoice() async {
    if (await isPro()) return true;
    final count = await getInvoiceCount();
    return count < freeInvoiceLimit;
  }

  // ───────── theme colour ─────────
  static Future<int> getColorIndex() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kColor) ?? 0;
  }

  static Future<void> setColorIndex(int idx) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kColor, idx);
  }
}

/// A pair of brand colours used by the invoice PDF.
class InvoicePalette {
  final String name;
  final int accent;
  final int navy;
  final int accentSoft;
  const InvoicePalette(this.name, this.accent, this.navy, this.accentSoft);
}

/// Catalogue of palettes — index 0 is the default ocean blue.
const List<InvoicePalette> kPalettes = [
  InvoicePalette('Ocean', 0xFF1F6FEB, 0xFF0E1F4D, 0xFFEFF4FF),
  InvoicePalette('Forest', 0xFF059669, 0xFF064E3B, 0xFFECFDF5),
  InvoicePalette('Royal', 0xFF7C3AED, 0xFF3B0764, 0xFFF5F3FF),
  InvoicePalette('Crimson', 0xFFDC2626, 0xFF7F1D1D, 0xFFFEF2F2),
  InvoicePalette('Sunset', 0xFFEA580C, 0xFF7C2D12, 0xFFFFF7ED),
  InvoicePalette('Slate', 0xFF475569, 0xFF1E293B, 0xFFF1F5F9),
];
