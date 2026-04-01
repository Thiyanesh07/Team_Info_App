import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class CollegeSyncScreen extends StatefulWidget {
  const CollegeSyncScreen({super.key});

  @override
  State<CollegeSyncScreen> createState() => _CollegeSyncScreenState();
}

class _CollegeSyncScreenState extends State<CollegeSyncScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            _extractCookieAndSync();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ps.bitsathy.ac.in/dashboard'));
  }

  Future<void> _extractCookieAndSync() async {
    if (_isSyncing) return;
    try {
      final String cookies = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      
      // Clean up the javascript extra string quotes if any
      final cleanCookies = cookies.replaceAll('"', '');
      
      // Find PS token
      final segments = cleanCookies.split(';');
      String? psToken;
      for (var segment in segments) {
        final pair = segment.trim().split('=');
        if (pair.length >= 2 && pair[0] == 'PS') {
          psToken = pair.sublist(1).join('=');
          break;
        }
      }

      if (psToken != null && psToken.isNotEmpty) {
        setState(() {
          _isSyncing = true;
        });
        
        // Sync to backend
        final api = ApiService();
        final res = await api.put(ApiConstants.psSync, body: {
          'psToken': psToken,
        });

        if (!mounted) return;

        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity Points synced seamlessly!'), backgroundColor: AppColors.primary),
          );
          Navigator.pop(context, true); // Return true indicating success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Failed to sync with server'), backgroundColor: Colors.red),
          );
          setState(() {
            _isSyncing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Cookie extraction error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Connect Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardDark,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isSyncing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      _isSyncing ? 'Securing Data Hub...' : 'Loading Portal...',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
