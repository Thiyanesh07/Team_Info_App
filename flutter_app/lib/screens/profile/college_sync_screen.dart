import 'dart:async';
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
  Timer? _cookieTimer;

  String _statusMessage = 'Waiting for portal login...';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _statusMessage = 'Browsing Portal...';
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _statusMessage = 'Scanning for Session...';
            });
            // First manual check on finish
            await _extractCookieAndSync();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Portal Error: ${error.description}");
            if (mounted) {
              setState(() => _statusMessage = 'Connection issue detected.');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ps.bitsathy.ac.in/dashboard'));

    // PROACTIVE SCAN: Check for session cookie every 2 seconds
    _cookieTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isSyncing) {
        _extractCookieAndSync();
      }
    });
  }

  @override
  void dispose() {
    _cookieTimer?.cancel();
    super.dispose();
  }

  Future<void> _extractCookieAndSync() async {
    if (_isSyncing) return;
    try {
      String? psToken;
      final jsResult = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      String cleanCookies = jsResult.toString().replaceAll('"', '');
      final segments = cleanCookies.split(';');
      for (var segment in segments) {
        final pair = segment.trim().split('=');
        if (pair.length >= 2 && pair[0] == 'PS') {
          psToken = pair.sublist(1).join('=');
          break;
        }
      }

      if (psToken != null && psToken.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _isSyncing = true;
          _statusMessage = 'Session Captured! Syncing Hub...';
        });

        // Sync to backend
        final api = ApiService();
        final res = await api.put(
          ApiConstants.psSync,
          body: {'psToken': psToken},
        );

        if (!mounted) return;

        if (res.success) {
          setState(() => _statusMessage = 'Success! Updating profiles...');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity Points synced!'),
              backgroundColor: AppColors.primary,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() {
            _isSyncing = false;
            _statusMessage = 'Handshake failed. Retrying...';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Auth Error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Sync monitor issue: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Connect Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _extractCookieAndSync(),
            tooltip: 'Force Sync',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isSyncing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (!_isSyncing) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Once you log in, we\'ll sync automatically',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
