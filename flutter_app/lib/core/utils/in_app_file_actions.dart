import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InAppFileActions {
  static const Duration _downloadTimeout = Duration(seconds: 45);

  static Future<void> preview(
    BuildContext context,
    String fileUrl, {
    String? fileName,
  }) async {
    try {
      final normalizedUrl = _normalizeAndValidateUrl(fileUrl);
      final headers = await _headersForUrl(normalizedUrl);

      debugPrint('📂 File Preview Request:');
      debugPrint('   URL: $normalizedUrl');
      debugPrint('   Headers: ${headers.keys.join(", ")}');

      final isLocal = _isLocalHost(normalizedUrl);
      final isDoc = _looksLikeDocument(normalizedUrl, fileName);

      // We must handle documents specially:
      // 1. If auth headers are required (Internal exports)
      // 2. If it is a local network IP (Google Docs Viewer cannot see local IPs)
      if (isDoc && (headers.isNotEmpty || isLocal)) {
        final reason = isLocal ? 'Local network file' : 'Protected document';
        debugPrint('ℹ️ $reason detected, downloading for external open.');
        
        final bytes = await _downloadFileBytesInternal(
          normalizedUrl,
          headers: headers,
        );
        final safeName = _resolveFileName(normalizedUrl, fileName);
        final downloadDir = await _ensureDownloadsDir();
        final path = '${downloadDir.path}/$safeName';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(path);
        return;
      }

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _InAppFilePreviewScreen(
            url: normalizedUrl,
            fileName: fileName,
            headers: headers,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        final uri = Uri.tryParse(fileUrl);
        final host = uri?.host ?? 'unknown';
        final path = uri?.path ?? 'unknown';
        final shortPath = path.length > 20 ? '...${path.substring(path.length - 17)}' : path;
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('Preview failed: $e\nHost: $host, Path: $shortPath'),
          duration: const Duration(seconds: 10), // Longer to read debug info
          action: SnackBarAction(
            label: 'BROWSER',
            onPressed: () => _openExternally(fileUrl),
          ),
        ));
      }
    }
  }

  static Future<void> _openExternally(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await OpenFilex.open(url);
      }
    } catch (e) {
      debugPrint('⚠️ External launch failed: $e');
    }
  }

  static Future<void> downloadAndOpen(
    BuildContext context,
    String fileUrl, {
    String? fileName,
  }) async {
    try {
      final normalizedUrl = _normalizeAndValidateUrl(fileUrl);
      final headers = await _headersForUrl(normalizedUrl);

      debugPrint('📥 File Download Request:');
      debugPrint('   URL: $normalizedUrl');
      debugPrint('   Headers: ${headers.keys.join(", ")}');

      final bytes = await _downloadFileBytesInternal(
        normalizedUrl,
        headers: headers,
      );
      final safeName = _resolveFileName(normalizedUrl, fileName);
      final downloadDir = await _ensureDownloadsDir();
      final path = '${downloadDir.path}/$safeName';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloaded: $safeName')));
      }

      await OpenFilex.open(path);
    } catch (e) {
      if (context.mounted) {
        final status = e.toString().contains('HTTP') ? e.toString() : 'Network error';
        final uri = Uri.tryParse(fileUrl);
        final host = uri?.host ?? 'unknown';
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('Download failed: $status\nHost: $host'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'FORCE',
            onPressed: () => _openExternally(fileUrl),
          ),
        ));
      }
    }
  }

  static Future<Directory> _ensureDownloadsDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<int>> _downloadFileBytesInternal(
    String fileUrl, {
    Map<String, String> headers = const {},
  }) async {
    final uri = Uri.parse(fileUrl);
    var res = await http.get(uri, headers: headers).timeout(_downloadTimeout);

    // FIX: If we get a 401 and we sent headers, try ONE LAST TIME without headers.
    // Some Cloudinary setups or proxies reject requests that contain any Auth headers
    // even if the file is public.
    if (res.statusCode == 401 && headers.isNotEmpty) {
      debugPrint('⚠️ 401 Unauthorized with headers, retrying WITHOUT headers...');
      res = await http.get(uri).timeout(_downloadTimeout);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  static Future<Map<String, String>> _headersForUrl(String fileUrl) async {
    try {
      final fileUri = Uri.parse(fileUrl);
      final apiUri = Uri.parse(ApiConstants.baseUrl);

      // Path-based internal detection:
      final isInternal = fileUri.path.contains('/api/') ||
          fileUri.host == apiUri.host ||
          _isLocalHost(fileUrl);

      // Explicit External CDN whitelist (overrides internal check)
      final isKnownExternal = fileUri.host.contains('cloudinary.com') ||
          fileUri.host.contains('google.com') ||
          fileUri.host.contains('gstatic.com');

      if (!isInternal || isKnownExternal) {
        return const {};
      }

      final token = await ApiService().getToken();
      if (token == null || token.trim().isEmpty) {
        return const {};
      }

      return {'Authorization': 'Bearer ${token.trim()}'};
    } catch (e) {
      debugPrint('⚠️ Error determining headers for URL: $e');
      return const {};
    }
  }

  static bool _isLocalHost(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      // Detect localhost, 127.0.0.1, 10.*, 172.16-31.*, 192.168.*
      return host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2' ||
          host.startsWith('192.168.') ||
          host.startsWith('10.') ||
          host.startsWith('172.');
    } catch (_) {
      return false;
    }
  }

  static String _getExtension(String url, String? fileName) {
    if (fileName != null && fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.contains('.')) {
        return path.split('.').last.toLowerCase();
      }
    } catch (_) {}
    return '';
  }

  static String _normalizeAndValidateUrl(String rawUrl) {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      throw const FormatException('Invalid file URL');
    }

    if (uri.host == 'console.cloudinary.com') {
      throw const FormatException(
        'Cloudinary Console links are not direct file URLs. Use res.cloudinary.com/... delivery URL.',
      );
    }

    return url;
  }

  static String _resolveFileName(String url, String? preferredName) {
    if (preferredName != null && preferredName.trim().isNotEmpty) {
      return _sanitizeFileName(preferredName.trim());
    }
    final uri = Uri.parse(url);
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    var fallback = last.isEmpty ? 'downloaded_file' : last;
    fallback = Uri.decodeComponent(fallback.split('?').first);

    // If it's an export endpoint and lacks extension, assume .xlsx
    if (uri.path.contains('/export/') && !fallback.contains('.')) {
      fallback = '$fallback.xlsx';
    }

    return _sanitizeFileName(fallback);
  }

  static bool _looksLikeDocument(String url, String? fileName) {
    final lowerUrl = url.toLowerCase();
    final lowerFileName = fileName?.toLowerCase() ?? '';

    // Aggressive extension check anywhere in string
    final isPdf = lowerUrl.contains('.pdf') || lowerFileName.contains('.pdf');
    final isExcel = lowerUrl.contains('.xls') || lowerFileName.contains('.xls');
    final isWord = lowerUrl.contains('.doc') || lowerFileName.contains('.doc');

    if (isPdf || isExcel || isWord) return true;

    final ext = _getExtension(url, fileName);
    if (['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'].contains(ext)) {
      return true;
    }

    // Path-based document hinting (e.g., reports/submissions/xyz)
    if (lowerUrl.contains('/reports/') ||
        lowerUrl.contains('/submissions/') ||
        lowerUrl.contains('/upload/') ||
        lowerUrl.contains('/export/') ||
        lowerUrl.contains('/documents/')) {
      return true;
    }

    return false;
  }

  static String _sanitizeFileName(String fileName) {
    var value = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.isEmpty) return 'downloaded_file';
    return value;
  }
}

class _InAppFilePreviewScreen extends StatefulWidget {
  final String url;
  final String? fileName;
  final Map<String, String> headers;

  const _InAppFilePreviewScreen({
    required this.url,
    this.fileName,
    this.headers = const {},
  });

  @override
  State<_InAppFilePreviewScreen> createState() =>
      _InAppFilePreviewScreenState();
}

class _InAppFilePreviewScreenState extends State<_InAppFilePreviewScreen> {
  late final WebViewController _controller;
  bool _isImage = false;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _isImage = _looksLikeImage(widget.url, widget.fileName);

    final effectiveUrl = _previewUrl(
      widget.url,
      widget.fileName,
      widget.headers,
    );
    final isGoogleDocs = effectiveUrl.startsWith('https://docs.google.com');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint('🌐 WebView Error: ${error.description}');
            if (mounted) {
              setState(() => _loadError = true);
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(effectiveUrl),
        // CRITICAL: Never send our internal tokens to Google Docs Viewer.
        headers: isGoogleDocs ? const {} : widget.headers,
      );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.fileName?.isNotEmpty == true
        ? widget.fileName!
        : 'File Preview';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isImage
          ? InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.url,
                  fit: BoxFit.contain,
                  headers: widget.headers,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text('No preview available')),
                ),
              ),
            )
          : _loadError
          ? const Center(child: Text('No preview available'))
          : WebViewWidget(controller: _controller),
    );
  }

  bool _looksLikeImage(String url, String? fileName) {
    final ext = InAppFileActions._getExtension(url, fileName);
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  String _previewUrl(
    String url,
    String? fileName,
    Map<String, String> headers,
  ) {
    final isDocument = InAppFileActions._looksLikeDocument(url, fileName);

    // Google docs viewer only works for public URLs without headers.
    // Cloudinary public delivery URLs are safe to use with it.
    if (isDocument && headers.isEmpty) {
      return 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url)}';
    }

    return url;
  }
}
