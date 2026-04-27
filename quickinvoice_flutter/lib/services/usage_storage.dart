import 'package:shared_preferences/shared_preferences.dart';

import 'billing_service.dart';

/// Tracks invoice usage, theme colour and Pro-only invoice options.
///
/// Pro entitlement (`isPro`) is owned exclusively by [BillingService] and
/// only mirrored here as a UI cache. UI code MUST NOT toggle Pro state.
class UsageStorage {
  static const _kCount = 'invoice_count';
  static const _kColor = 'theme_color_index';
  static const _kDueDays = 'pro_due_days';
  static const _kDiscountPct = 'pro_discount_pct';
  static const _kTaxPct = 'pro_tax_pct';

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

  // ───────── pro entitlement (read-only mirror of BillingService) ─────────
  static bool isPro() => BillingService.instance.isPro;

  /// Returns 0.2 (20%) for Pro users, 0.0 otherwise.
  /// Use this to apply a Pro-only loyalty discount on future upgrade offers.
  static double getProDiscount() => isPro() ? 0.2 : 0.0;

  /// Returns true if the user is allowed to generate the next invoice.
  static Future<bool> canGenerateInvoice() async {
    if (isPro()) return true;
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

  // ───────── Pro-only invoice options ─────────
  static Future<int> getDueDays() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kDueDays) ?? 14;
  }

  static Future<void> setDueDays(int days) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDueDays, days);
  }

  static Future<double> getDiscountPercent() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kDiscountPct) ?? 0.0;
  }

  static Future<void> setDiscountPercent(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kDiscountPct, v);
  }

  static Future<double> getTaxPercent() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kTaxPct) ?? 0.0;
  }

  static Future<void> setTaxPercent(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kTaxPct, v);
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
