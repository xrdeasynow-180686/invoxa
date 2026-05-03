import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight container for the persisted business profile.
class BusinessProfile {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String abn;
  final Uint8List? logoBytes;

  const BusinessProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.abn,
    this.logoBytes,
  });

  bool get isEmpty =>
      name.trim().isEmpty &&
      address.trim().isEmpty &&
      phone.trim().isEmpty &&
      email.trim().isEmpty &&
      abn.trim().isEmpty;
}

/// Persists the user's business profile locally using SharedPreferences.
/// No backend, no database.
class BusinessStorage {
  static const _kName = 'business_name';
  static const _kAddress = 'business_address';
  static const _kPhone = 'business_phone';
  static const _kEmail = 'business_email';
  static const _kAbn = 'business_abn';
  static const _kLogo = 'business_logo_b64';

  static Future<BusinessProfile> load() async {
    final p = await SharedPreferences.getInstance();
    final logoB64 = p.getString(_kLogo);
    Uint8List? bytes;
    if (logoB64 != null && logoB64.isNotEmpty) {
      try {
        bytes = base64Decode(logoB64);
      } catch (_) {
        bytes = null;
      }
    }
    return BusinessProfile(
      name: p.getString(_kName) ?? '',
      address: p.getString(_kAddress) ?? '',
      phone: p.getString(_kPhone) ?? '',
      email: p.getString(_kEmail) ?? '',
      abn: p.getString(_kAbn) ?? '',
      logoBytes: bytes,
    );
  }

  static Future<void> save({
    required String name,
    required String address,
    required String phone,
    required String email,
    required String abn,
    List<int>? logoBytes,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name.trim());
    await p.setString(_kAddress, address.trim());
    await p.setString(_kPhone, phone.trim());
    await p.setString(_kEmail, email.trim());
    await p.setString(_kAbn, abn.trim());
    if (logoBytes != null && logoBytes.isNotEmpty) {
      await p.setString(_kLogo, base64Encode(logoBytes));
    } else {
      await p.remove(_kLogo);
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kName);
    await p.remove(_kAddress);
    await p.remove(_kPhone);
    await p.remove(_kEmail);
    await p.remove(_kAbn);
    await p.remove(_kLogo);
  }
}
