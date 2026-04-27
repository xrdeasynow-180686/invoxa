import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single Pro product ID configured in Google Play Console.
/// Must match the product ID created under Monetize → Products → In-app products.
const String kProProductId = 'inovxa_pro';

/// SharedPreferences key used **only** as a cache so the UI can render the
/// correct state synchronously while the IAP plugin warms up. The cache is
/// always (re)written from BillingService when a purchase is verified or
/// restored. UI code MUST NOT write this value directly.
const String _kProCacheKey = 'is_pro';

/// Status that BillingService exposes to listeners.
enum BillingStatus {
  initialising,
  ready,
  storeUnavailable,
  purchasing,
  pending,
  error,
}

/// Centralised, singleton billing manager.
/// - Loads the [kProProductId] product from Google Play.
/// - Listens to [InAppPurchase.purchaseStream] and grants Pro entitlement
///   only after a verified PURCHASED / RESTORED status.
/// - Persists a small UI cache of `is_pro` in SharedPreferences.
/// - Restores purchases on app start so reinstalls remain Pro.
class BillingService extends ChangeNotifier {
  BillingService._();
  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  late SharedPreferences _prefs;

  ProductDetails? _product;
  BillingStatus _status = BillingStatus.initialising;
  String? _error;
  bool _isPro = false;
  bool _cacheLoaded = false;

  ProductDetails? get product => _product;
  BillingStatus get status => _status;
  String? get error => _error;
  bool get isPro => _isPro;

  /// Real, store-formatted price (e.g. "$4.99"). Empty string until the
  /// product details have loaded.
  String get formattedPrice => _product?.price ?? '';

  /// Initialises the plugin, restores prior purchases and starts listening
  /// to the purchase stream. Safe to call multiple times — subsequent calls
  /// are no-ops.
  Future<void> initialize() async {
    if (_subscription != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _isPro = _prefs.getBool(_kProCacheKey) ?? false;

      final available = await _iap.isAvailable();
      if (!available) {
        _status = BillingStatus.storeUnavailable;
        notifyListeners();
        return;
      }

      // Android-specific: pending-purchase support is required.
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        } catch (_) {
          // Older plugin versions: nothing to do.
        }
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (e) {
          _error = 'Purchase stream error: $e';
          _status = BillingStatus.error;
          notifyListeners();
        },
        onDone: () => _subscription?.cancel(),
      );

      await _loadProduct();
      // Trigger the restore flow so users who reinstalled get Pro back.
      await restorePurchases();

      _status = BillingStatus.ready;
      notifyListeners();
    } catch (e) {
      _error = 'Initialise failed: $e';
      _status = BillingStatus.error;
      notifyListeners();
    }
  }

  Future<void> _loadProduct() async {
    final response =
        await _iap.queryProductDetails(<String>{kProProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
      notifyListeners();
    } else {
      _error = response.notFoundIDs.isNotEmpty
          ? 'Product not found in store: ${response.notFoundIDs.join(", ")}'
          : 'No product details returned by store.';
      notifyListeners();
    }
  }

  /// Kicks off Google Play's purchase flow for the Pro product.
  Future<void> buyPro() async {
    if (_product == null) {
      _error = 'Product not ready yet — try again in a moment.';
      notifyListeners();
      return;
    }
    try {
      _error = null;
      _status = BillingStatus.purchasing;
      notifyListeners();
      final param = PurchaseParam(productDetails: _product!);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _error = 'Could not start purchase: $e';
      _status = BillingStatus.error;
      notifyListeners();
    }
  }

  /// Restores any previously-owned purchases for the signed-in Google
  /// account. Called automatically on init and from the paywall's restore
  /// button.
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _error = 'Restore failed: $e';
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _status = BillingStatus.pending;
          _error = null;
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == kProProductId &&
              await _verifyPurchase(p)) {
            await _grantPro();
          }
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          _status = BillingStatus.ready;
          notifyListeners();
          break;
        case PurchaseStatus.error:
          _error = p.error?.message ?? 'Purchase failed.';
          _status = BillingStatus.error;
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _error = 'Purchase cancelled.';
          _status = BillingStatus.ready;
          notifyListeners();
          break;
      }
    }
  }

  /// Verifies a purchase. Local sanity-check only; in production replace
  /// with a server-side call to Google Play Developer API.
  Future<bool> _verifyPurchase(PurchaseDetails p) async {
    return p.productID == kProProductId &&
        p.verificationData.localVerificationData.isNotEmpty;
  }

  /// Marks the user as Pro and writes the cache. ONLY called from the
  /// purchase-update handler — never from the UI layer.
  Future<void> _grantPro() async {
    _isPro = true;
    await _prefs.setBool(_kProCacheKey, true);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
