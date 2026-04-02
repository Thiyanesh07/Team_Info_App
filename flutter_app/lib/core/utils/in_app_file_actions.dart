import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InAppFileActions {
  static Future<void> preview(
    BuildContext context,
    String fileUrl, {
    String? fileName,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _InAppFilePreviewScreen(url: fileUrl, fileName: fileName),
      ),
    );
  }

  static Future<void> downloadAndOpen(
    BuildContext context,
    String fileUrl, {
    String? fileName,
  }) async {
    try {
      final bytes = await _downloadFileBytes(fileUrl);
      final safeName = _resolveFileName(fileUrl, fileName);
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

  static Future<List<int>> _downloadFileBytes(String fileUrl) async {
    final uri = Uri.parse(fileUrl);
    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  static String _resolveFileName(String url, String? preferredName) {
    if (preferredName != null && preferredName.trim().isNotEmpty) {
      return preferredName.trim();
    }
    final uri = Uri.parse(url);
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final fallback = last.isEmpty ? 'downloaded_file' : last;
    final clean = fallback.split('?').first;
    return clean;
  }
}

class _InAppFilePreviewScreen extends StatefulWidget {
  final String url;
  final String? fileName;

  const _InAppFilePreviewScreen({required this.url, this.fileName});

  @override
  State<_InAppFilePreviewScreen> createState() =>
      _InAppFilePreviewScreenState();
}

class _InAppFilePreviewScreenState extends State<_InAppFilePreviewScreen> {
  late final WebViewController _controller;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    _isImage = _looksLikeImage(widget.url, widget.fileName);

    final effectiveUrl = _previewUrl(widget.url, widget.fileName);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(effectiveUrl));
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
                child: Image.network(widget.url, fit: BoxFit.contain),
              ),
            )
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

  String _previewUrl(String url, String? fileName) {
    final source = (fileName ?? url).toLowerCase();
    final isDocument =
        source.endsWith('.pdf') ||
        source.endsWith('.doc') ||
        source.endsWith('.docx') ||
        source.endsWith('.ppt') ||
        source.endsWith('.pptx') ||
        source.endsWith('.xls') ||
        source.endsWith('.xlsx');

    if (isDocument) {
      return 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url)}';
    }

    return url;
  }
}
