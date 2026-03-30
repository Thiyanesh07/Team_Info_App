import 'package:team_info_app/services/api_service.dart';

abstract class BaseRepository {
  final ApiService api = ApiService();

  /// A helper to safely handle API responses and cast data to the expected type
  /// using the provided [fromJson] function.
  Future<List<T>> listFromResponse<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.success && response.data is List) {
      final parsed = <T>[];
      for (final item in (response.data as List)) {
        try {
          parsed.add(fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Skip malformed records so one bad item cannot crash the screen.
        }
      }
      return parsed;
    }
    return [];
  }

  Future<T?> itemFromResponse<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.success && response.data != null) {
      try {
        return fromJson(response.data as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Synchronously retrieve cached data for instant UI loading
  List<T> getCachedList<T>(
    String endpoint,
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final cachedData = api.getCached(endpoint, queryParams: queryParams);
    if (cachedData is List) {
      final parsed = <T>[];
      for (final item in cachedData) {
        try {
          parsed.add(fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Skip malformed cached entries.
        }
      }
      return parsed;
    }
    return [];
  }

  T? getCachedItem<T>(
    String endpoint,
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final cachedData = api.getCached(endpoint, queryParams: queryParams);
    if (cachedData != null) {
      try {
        return fromJson(cachedData as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
