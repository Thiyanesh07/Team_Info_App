import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
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

      // WebView preview for office docs/PDF is unreliable across devices.
      // For documents, download to local storage and open with installed app.
      if (_looksLikeDocument(normalizedUrl, fileName)) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
      }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
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
    final res = await http.get(uri, headers: headers).timeout(_downloadTimeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  static Future<Map<String, String>> _headersForUrl(String fileUrl) async {
    try {
      final fileUri = Uri.parse(fileUrl);
      final apiUri = Uri.parse(ApiConstants.baseUrl);

      // CRITICAL: NEVER send Auth headers to Cloudinary or external domains.
      // 401 errors are often caused by CDNs rejecting unexpected Authorization headers.
      final isExternal = fileUri.host != apiUri.host ||
          fileUri.host.contains('cloudinary.com') ||
          fileUri.host.contains('google.com');

      if (isExternal) {
        debugPrint('ℹ️ Skipping Auth headers for external host: ${fileUri.host}');
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
    final fallback = last.isEmpty ? 'downloaded_file' : last;
    final clean = Uri.decodeComponent(fallback.split('?').first);
    return _sanitizeFileName(clean);
  }

  static bool _looksLikeDocument(String url, String? fileName) {
    final source = (fileName ?? url).toLowerCase();
    return source.endsWith('.pdf') ||
        source.endsWith('.doc') ||
        source.endsWith('.docx') ||
        source.endsWith('.ppt') ||
        source.endsWith('.pptx') ||
        source.endsWith('.xls') ||
        source.endsWith('.xlsx');
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => _loadError = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(effectiveUrl), headers: widget.headers);
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
    final source = (fileName ?? url).toLowerCase();
    return source.endsWith('.jpg') ||
        source.endsWith('.jpeg') ||
        source.endsWith('.png') ||
        source.endsWith('.webp') ||
        source.endsWith('.gif');
  }

  String _previewUrl(
    String url,
    String? fileName,
    Map<String, String> headers,
  ) {
    final source = (fileName ?? url).toLowerCase();
    final isDocument =
        source.endsWith('.pdf') ||
        source.endsWith('.doc') ||
        source.endsWith('.docx') ||
        source.endsWith('.ppt') ||
        source.endsWith('.pptx') ||
        source.endsWith('.xls') ||
        source.endsWith('.xlsx');

    final uri = Uri.tryParse(url);
    final isCloudinaryDelivery =
        uri != null && uri.host.contains('res.cloudinary.com');

    // Google docs viewer cannot access protected URLs that require auth headers,
    // and can be flaky for direct Cloudinary delivery links.
    if (isDocument && headers.isEmpty && !isCloudinaryDelivery) {
      return 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url)}';
    }

    return url;
  }
}
