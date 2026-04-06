import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/cache_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token'; // Actually the accessToken
  static const _refreshTokenKey = 'refresh_token';
  String? _inMemoryToken;
  String? _inMemoryRefreshToken;
  static const Duration _requestTimeout = Duration(seconds: 30);
  bool _isRefreshing = false;

  // ─── Token Management ──────────────────────
  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    final token = await _storage.read(key: _tokenKey);
    _inMemoryToken = token;
    return token;
  }

  Future<String?> getRefreshToken() async {
    if (_inMemoryRefreshToken != null && _inMemoryRefreshToken!.isNotEmpty) {
      return _inMemoryRefreshToken;
    }
    final token = await _storage.read(key: _refreshTokenKey);
    _inMemoryRefreshToken = token;
    return token;
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _inMemoryToken = accessToken;
    _inMemoryRefreshToken = refreshToken;
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteTokens() async {
    _inMemoryToken = null;
    _inMemoryRefreshToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
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

  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function(Map<String, String> headers) sender, {
    bool withAuth = true,
  }) async {
    var headers = await _headers(withAuth: withAuth);
    var response = await sender(headers).timeout(_requestTimeout);

    if (withAuth && response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final success = await _refreshAccessToken();
        if (success) {
          // Retry original request with NEW headers
          headers = await _headers(withAuth: withAuth);
          response = await sender(headers).timeout(_requestTimeout);
        }
      } finally {
        _isRefreshing = false;
      }
    }

    return response;
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final newAccessToken = data['data']['accessToken'];
          final newRefreshToken = data['data']['refreshToken'];
          await saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
          return true;
        }
      }
      
      // If refresh fails, we might want to clear tokens to force login
      if (response.statusCode == 401) {
        await deleteTokens();
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
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
      final response = await _requestWithRetry(
        (headers) => http.get(uri, headers: headers),
      );
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
      final response = await _requestWithRetry(
        (headers) => http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
        withAuth: withAuth,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await _requestWithRetry(
        (headers) => http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await _requestWithRetry(
        (headers) => http.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await _requestWithRetry(
        (headers) => http.delete(uri, headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // ─── Multipart Upload ──────────────────────
  Future<ApiResponse> uploadFile(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    String? folder,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      final token = await getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      if (fileName != null && fileName.isNotEmpty) {
        request.fields['fileName'] = fileName;
      }
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Upload error: $e');
    }
  }

  Future<ApiResponse> uploadImage(
    String filePath, {
    String? folder,
    String? fileName,
  }) async {
    return uploadFile(
      ApiConstants.uploadImage,
      filePath,
      fieldName: 'file',
      folder: folder,
      fileName: fileName,
    );
  }

  // ─── Task Management Helpers ────────────────
  Future<ApiResponse> updateTask(String taskId, Map<String, dynamic> body) async {
    return put("${ApiConstants.tasks}/$taskId", body: body);
  }

  Future<ApiResponse> reopenTask(String taskId, DateTime newDeadline) async {
    return post("${ApiConstants.tasks}/$taskId/reopen", body: {
      'newDeadline': newDeadline.toIso8601String(),
    });
  }

  // ─── Report Management Helpers ──────────────
  Future<ApiResponse> updateReportRequest(String requestId, Map<String, dynamic> body) async {
    return put("${ApiConstants.reportRequest}/$requestId", body: body);
  }

  Future<ApiResponse> reopenReport(String requestId, DateTime newDeadline) async {
    return post("/reports/reopen/$requestId", body: {
      'newDeadline': newDeadline.toIso8601String(),
    });
  }

  Future<ApiResponse> getReportAnalytics(String requestId) async {
    return get("/reports/analytics/$requestId");
  }

  Future<ApiResponse> updateTaskReport(String taskId, String reportId, String reportText) async {
    return put("/tasks/$taskId/reports/$reportId", body: {
      'reportText': reportText,
    });
  }

  // ─── P Skill Export Helper ─────────────────
  Future<String?> getPSkillsExportUrl({String? userId, String? scope}) async {
    final token = await getToken();
    if (token == null) return null;
    
    final baseUrl = ApiConstants.baseUrl;
    final queryParams = <String, String>{'token': token};
    if (userId != null) queryParams['userId'] = userId;
    if (scope != null) queryParams['scope'] = scope;
    
    final uri = Uri.parse("$baseUrl/export/p-skills").replace(queryParameters: queryParams);
    return uri.toString();
  }

  // ─── Response Handler ──────────────────────
  ApiResponse _handleResponse(http.Response response) {
    try {
      if (response.body.trim().isEmpty) {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          statusCode: response.statusCode,
        );
      }
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: body['success'] ?? true,
          data: body['data'],
          pagination: body['pagination'],
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
  final dynamic pagination; // New field for pagination metadata
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.pagination,
    this.message,
    this.statusCode,
  });
}
