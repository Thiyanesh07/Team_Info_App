import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/cache_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  String? _inMemoryToken;

  // ─── Token Management ──────────────────────
  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    final token = await _storage.read(key: _tokenKey);
    _inMemoryToken = token;
    return token;
  }

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    _inMemoryToken = null;
    await _storage.delete(key: _tokenKey);
  }

  // ─── Headers ───────────────────────────────
  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = (await getToken())?.trim();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ─── HTTP Methods ──────────────────────────
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool useCache = false,
  }) async {
    final cacheKey = queryParams != null
        ? '$endpoint?${queryParams.toString()}'
        : endpoint;

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}$endpoint',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _headers());
      final apiResponse = _handleResponse(response);

      if (useCache && apiResponse.success) {
        await CacheService.set(cacheKey, apiResponse.data);
      }

      return apiResponse;
    } catch (e) {
      if (useCache) {
        final cachedData = CacheService.get(cacheKey);
        if (cachedData != null) {
          return ApiResponse(
            success: true,
            data: cachedData,
            message: 'Loaded from cache (Offline)',
          );
        }
      }
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Manually get cached data
  dynamic getCached(String endpoint, {Map<String, String>? queryParams}) {
    final cacheKey = queryParams != null
        ? '$endpoint?${queryParams.toString()}'
        : endpoint;
    return CacheService.get(cacheKey);
  }

  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: await _headers(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.patch(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await http.delete(uri, headers: await _headers());
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // ─── Multipart Upload ──────────────────────
  Future<ApiResponse> uploadImage(String filePath) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.uploadImage}',
      );
      final request = http.MultipartRequest('POST', uri);
      final token = await getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Upload error: $e');
    }
  }

  // ─── Response Handler ──────────────────────
  ApiResponse _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: body['success'] ?? true,
          data: body['data'],
          message: body['message'],
        );
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Unauthorized',
          statusCode: 401,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Error occurred',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to parse response');
    }
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}
