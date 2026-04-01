import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ExcelExportService {
  final _storage = const FlutterSecureStorage();

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
      final token = await _storage.read(key: 'auth_token');
      
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download report: ${response.statusCode}');
      }

      // Save to temporary directory or Downloads
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory(); // Android: /storage/emulated/0/Android/data/...
      } else {
        directory = await getApplicationDocumentsDirectory(); // iOS / Other
      }

      final filePath = '${directory!.path}/$filename';
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
