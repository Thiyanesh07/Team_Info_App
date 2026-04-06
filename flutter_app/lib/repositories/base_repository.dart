import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/services/api_service.dart';

class PaginatedList<T> {
  final List<T> items;
  final PaginationMetadata? metadata;

  PaginatedList({required this.items, this.metadata});
}

abstract class BaseRepository {
  final ApiService api = ApiService();

  /// A helper to safely handle API responses and cast data to the expected type
  /// using the provided [fromJson] function.
  Future<List<T>> listFromResponse<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final list = await paginatedFromResponse(response, fromJson);
    return list.items;
  }

  Future<PaginatedList<T>> paginatedFromResponse<T>(
    ApiResponse response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.success && response.data is List) {
      final parsed = <T>[];
      for (final item in (response.data as List)) {
        try {
          parsed.add(fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Skip malformed records
        }
      }

      PaginationMetadata? metadata;
      if (response.pagination != null) {
        try {
          metadata = PaginationMetadata.fromJson(response.pagination as Map<String, dynamic>);
        } catch (_) {}
      }
      return PaginatedList(items: parsed, metadata: metadata); 
    }
    return PaginatedList(items: [], metadata: null);
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
