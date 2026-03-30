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
      return (response.data as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<T?> itemFromResponse<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.success && response.data != null) {
      return fromJson(response.data as Map<String, dynamic>);
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
      return cachedData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
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
      return fromJson(cachedData as Map<String, dynamic>);
    }
    return null;
  }
}
