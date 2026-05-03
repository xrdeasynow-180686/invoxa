import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin, fire-and-forget wrapper around Firebase Analytics.
///
/// All calls are defensive — if Firebase has not been initialised (for
/// example during local dev before `google-services.json` is added) the
/// events are silently swallowed so the UI stays snappy and never crashes.
///
/// Only three events are tracked, as requested for the Tradie MVP:
///   • app_open
///   • invoice_created
///   • invoice_shared
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;
  static bool _enabled = false;

  /// Must be called AFTER `Firebase.initializeApp()` succeeds.
  /// Safe to call multiple times. If Firebase is not configured, analytics
  /// stays disabled and every [log*] call becomes a no-op.
  static void enable() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _enabled = true;
    } catch (e) {
      _enabled = false;
      if (kDebugMode) {
        debugPrint('[AnalyticsService] disabled: $e');
      }
    }
  }

  static Future<void> logAppOpen() => _log('app_open');

  static Future<void> logInvoiceCreated({
    required double total,
    required String currency,
    required int itemCount,
  }) =>
      _log('invoice_created', {
        'total': total,
        'currency': currency,
        'item_count': itemCount,
      });

  static Future<void> logInvoiceShared({
    required String invoiceNumber,
  }) =>
      _log('invoice_shared', {'invoice_number': invoiceNumber});

  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (!_enabled || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] logEvent($name) failed: $e');
      }
    }
  }
}
