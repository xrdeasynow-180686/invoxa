import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight container for the persisted business profile.
class BusinessProfile {
  final String name;
  final String address;
  final Uint8List? logoBytes;

  const BusinessProfile({
    required this.name,
    required this.address,
    this.logoBytes,
  });

  bool get isEmpty => name.trim().isEmpty && address.trim().isEmpty;
}

/// Persists the user's business name, address and logo locally
/// using SharedPreferences. No backend, no database.
class BusinessStorage {
  static const _kName = 'business_name';
  static const _kAddress = 'business_address';
  static const _kLogo = 'business_logo_b64';

  static Future<BusinessProfile> load() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_kName) ?? '';
    final address = p.getString(_kAddress) ?? '';
    final logoB64 = p.getString(_kLogo);
    Uint8List? bytes;
    if (logoB64 != null && logoB64.isNotEmpty) {
      try {
        bytes = base64Decode(logoB64);
      } catch (_) {
        bytes = null;
      }
    }
    return BusinessProfile(name: name, address: address, logoBytes: bytes);
  }

  static Future<void> save({
    required String name,
    required String address,
    List<int>? logoBytes,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name.trim());
    await p.setString(_kAddress, address.trim());
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
    await p.remove(_kLogo);
  }
}
