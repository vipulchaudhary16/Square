import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_model.dart';

/// Persists the last-fetched [DashboardData] on disk so the dashboard can
/// paint instantly on the next app open / tab switch instead of showing a
/// skeleton while the network call is in flight. Not a source of truth —
/// callers always follow a cache read with a real fetch and overwrite it.
class DashboardCache {
  static const _dataKey = 'dashboard_cache_data';

  static Future<DashboardData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dataKey);
    if (raw == null) return null;
    try {
      return DashboardData.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(DashboardData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey, jsonEncode(data.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey);
  }
}
