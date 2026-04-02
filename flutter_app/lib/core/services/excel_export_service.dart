import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:team_info_app/services/api_service.dart';
import '../constants/api_constants.dart';

class ExcelExportService {
  final _api = ApiService();

  String _timelineSuffix(Map<String, String>? queryParams) {
    if (queryParams == null) return '';

    final timeline = (queryParams['timeline'] ?? '').trim().toUpperCase();
    if (timeline.isEmpty) return '';
    if (timeline == 'TODAY') return '_today';
    if (timeline == 'ALL') return '_all';
    if (timeline == 'RANGE') {
      final start = (queryParams['startDate'] ?? '').trim();
      final end = (queryParams['endDate'] ?? '').trim();
      if (start.isNotEmpty && end.isNotEmpty) {
        return '_range_${start}_to_$end';
      }
      return '_range';
    }
    return '';
  }

  String _withSuffix(String filename, String suffix) {
    if (suffix.isEmpty) return filename;
    final dot = filename.lastIndexOf('.');
    if (dot <= 0 || dot == filename.length - 1) {
      return '$filename$suffix';
    }
    final base = filename.substring(0, dot);
    final ext = filename.substring(dot);
    return '$base$suffix$ext';
  }

  /// Download and open an Excel report from the backend.
  ///
  /// [endpoint] is the export endpoint (e.g. ApiConstants.exportActivities).
  /// [filename] is the desired filename (e.g. 'DailyActivities.xlsx').
  /// [queryParams] are optional filtering such as { 'scope': 'TEAM' }.
  Future<void> downloadAndOpenReport({
    required String endpoint,
    required String filename,
    Map<String, String>? queryParams,
  }) async {
    try {
      final token = (await _api.getToken())?.trim();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please sign in again.');
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept':
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw Exception('Unauthorized (401). Please login again and retry.');
        }
        throw Exception('Failed to download report: ${response.statusCode}');
      }

      // Save to temporary directory or Downloads
      Directory? directory;
      if (Platform.isAndroid) {
        directory =
            await getExternalStorageDirectory(); // Android: /storage/emulated/0/Android/data/...
      } else {
        directory = await getApplicationDocumentsDirectory(); // iOS / Other
      }

      final fileNameWithSuffix = _withSuffix(
        filename,
        _timelineSuffix(queryParams),
      );
      final filePath = '${directory!.path}/$fileNameWithSuffix';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Open the file
      await OpenFilex.open(filePath);
    } catch (e) {
      // In production, consider a logger or crash reporting service
      rethrow;
    }
  }
}
