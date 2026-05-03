import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last client name used so the Quick Invoice screen can
/// pre-fill it on the next job (common for tradies billing the same
/// site / customer repeatedly).
class LastClientStorage {
  static const _kLastClient = 'last_client_name';

  static Future<String> get() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLastClient) ?? '';
  }

  static Future<void> set(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastClient, name.trim());
  }
}
