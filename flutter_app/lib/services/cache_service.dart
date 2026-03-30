import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'api_cache';

  /// Saves the [data] (usually a JSON Map or List) for the [key] (usually the API path).
  static Future<void> set(String key, dynamic data) async {
    final box = Hive.box(_boxName);
    await box.put(key, jsonEncode(data));
  }

  /// Retrieves the cached data for the [key]. Returns null if not found.
  static dynamic get(String key) {
    try {
      final box = Hive.box(_boxName);
      final data = box.get(key);
      if (data != null) {
        return jsonDecode(data);
      }
    } catch (_) {
      // In case of parsing error, return null
    }
    return null;
  }

  /// Clears the entire cache (useful on logout)
  static Future<void> clearAll() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
