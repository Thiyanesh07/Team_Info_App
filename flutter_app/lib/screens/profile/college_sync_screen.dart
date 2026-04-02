import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

enum SyncStage {
  openingPortal,
  waitingForLogin,
  tokenCaptured,
  syncing,
  synced,
  failed,
}

class CollegeSyncScreen extends ConsumerStatefulWidget {
  const CollegeSyncScreen({super.key});

  @override
  ConsumerState<CollegeSyncScreen> createState() => _CollegeSyncScreenState();
}

class _CollegeSyncScreenState extends ConsumerState<CollegeSyncScreen> {
  late final WebViewController _controller;
  final TextEditingController _manualPointsController = TextEditingController();
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _hasPortalError = false;
  bool _portalInitialized = false;
  Timer? _cookieTimer;
  SyncStage _stage = SyncStage.openingPortal;

  String _statusMessage = 'Opening portal...';
  String? _errorMessage;
  String? _lastSyncedAt;
  int? _oldPoints;
  int? _newPoints;
  int? _delta;

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
              _isLoading = !_portalInitialized;
              _hasPortalError = false;
              if (!_portalInitialized && !_isSyncing) {
                _setStage(SyncStage.openingPortal);
              }
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _portalInitialized = true;
              if (!_isSyncing && _stage != SyncStage.synced) {
                _setStage(SyncStage.waitingForLogin);
              }
            });
            // First manual check on finish
            await _extractCookieAndSync();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Portal Error: ${error.description}");
            if (mounted) {
              setState(() {
                _hasPortalError = true;
                _setStage(SyncStage.failed);
                _errorMessage =
                    'Portal could not load in app (${error.errorCode}). Try Retry Sync or open external browser.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ps.bitsathy.ac.in/dashboard'));

    // PROACTIVE SCAN: Check for session cookie every 1 second
    _cookieTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSyncing) {
        _extractCookieAndSync();
      }
    });
  }

  @override
  void dispose() {
    _cookieTimer?.cancel();
    _manualPointsController.dispose();
    super.dispose();
  }

  void _setStage(SyncStage stage) {
    _stage = stage;
    switch (stage) {
      case SyncStage.openingPortal:
        _statusMessage = 'Opening portal';
        break;
      case SyncStage.waitingForLogin:
        _statusMessage = 'Waiting for login';
        break;
      case SyncStage.tokenCaptured:
        _statusMessage = 'Token captured';
        break;
      case SyncStage.syncing:
        _statusMessage = 'Syncing';
        break;
      case SyncStage.synced:
        final deltaText = _delta == null
            ? ''
            : _delta! >= 0
            ? ' (+${_delta!})'
            : ' (${_delta!})';
        _statusMessage = 'Synced successfully$deltaText';
        break;
      case SyncStage.failed:
        _statusMessage = 'Failed';
        break;
    }
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.parse('https://ps.bitsathy.ac.in/dashboard');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open external browser.')),
      );
    }
  }

  Future<void> _retrySync() async {
    if (_isSyncing) return;
    setState(() {
      _errorMessage = null;
      _hasPortalError = false;
      _isLoading = true;
      _setStage(SyncStage.openingPortal);
    });

    await _controller.loadRequest(
      Uri.parse('https://ps.bitsathy.ac.in/dashboard'),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    await _extractCookieAndSync();
  }

  Future<void> _extractCookieAndSync() async {
    if (_isSyncing) return;
    try {
      if (_stage == SyncStage.synced) return;

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
        await _syncWithToken(psToken);
      } else if (mounted && _stage != SyncStage.waitingForLogin) {
        setState(() => _setStage(SyncStage.waitingForLogin));
      }
    } catch (e) {
      debugPrint('Sync monitor issue: $e');
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _setStage(SyncStage.failed);
        _errorMessage =
            'Could not capture portal session. Retry sync or open in external browser.';
      });
    }
  }

  Future<void> _syncWithToken(String psToken) async {
    if (_isSyncing || psToken.trim().isEmpty || !mounted) return;

    setState(() {
      _isSyncing = true;
      _setStage(SyncStage.tokenCaptured);
      _errorMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    setState(() => _setStage(SyncStage.syncing));

    final api = ApiService();
    final res = await api.put(ApiConstants.psSync, body: {'psToken': psToken});

    if (!mounted) return;

    if (res.success) {
      final data = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      final userJson = (data['user'] is Map<String, dynamic>)
          ? data['user'] as Map<String, dynamic>
          : <String, dynamic>{};

      final newPoints = (data['newPoints'] as num?)?.toInt();
      final oldPoints = (data['oldPoints'] as num?)?.toInt();
      final delta = (data['delta'] as num?)?.toInt();
      final syncedAt = data['syncedAt']?.toString();
      final groupPoints = (userJson['groupPoints'] as num?)?.toInt();
      final contributionPercent = (userJson['contributionPercent'] as num?)
          ?.toDouble();

      ref
          .read(authProvider.notifier)
          .patchCurrentUser(
            activityPoints: newPoints,
            groupPoints: groupPoints,
            contributionPercent: contributionPercent,
          );

      setState(() {
        _isSyncing = false;
        _oldPoints = oldPoints;
        _newPoints = newPoints;
        _delta = delta;
        _lastSyncedAt = syncedAt;
        _setStage(SyncStage.synced);
      });

      _cookieTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Activity Points synced: ${oldPoints ?? '-'} -> ${newPoints ?? '-'} (${delta != null && delta >= 0 ? '+' : ''}${delta ?? 0})',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pop(context, {
          'synced': true,
          'oldPoints': oldPoints,
          'newPoints': newPoints,
          'delta': delta,
          'syncedAt': syncedAt,
        });
      }
      return;
    }

    final retryAfterSeconds =
        ((res.data is Map<String, dynamic>)
                ? (res.data as Map<String, dynamic>)['retryAfterSeconds']
                : null)
            as num?;

    setState(() {
      _isSyncing = false;
      _setStage(SyncStage.failed);
      _errorMessage = retryAfterSeconds != null
          ? 'Sync throttled. Retry in ${retryAfterSeconds.toInt()}s.'
          : (res.message ??
                'Sync failed. Retry sync or open external browser.');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message ?? 'Auth Error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _manualSyncWithPoints() async {
    final value = _manualPointsController.text.trim();
    final points = int.tryParse(value);
    if (points == null || points < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid activity points value.')),
      );
      return;
    }
    await _syncWithManualPoints(points);
  }

  Future<void> _syncWithManualPoints(int points) async {
    if (_isSyncing || !mounted) return;

    setState(() {
      _isSyncing = true;
      _setStage(SyncStage.syncing);
      _errorMessage = null;
    });

    final api = ApiService();
    final res = await api.put(
      ApiConstants.psSync,
      body: {'manualActivityPoints': points},
    );

    if (!mounted) return;

    if (res.success) {
      final data = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      final userJson = (data['user'] is Map<String, dynamic>)
          ? data['user'] as Map<String, dynamic>
          : <String, dynamic>{};

      final newPoints = (data['newPoints'] as num?)?.toInt();
      final oldPoints = (data['oldPoints'] as num?)?.toInt();
      final delta = (data['delta'] as num?)?.toInt();
      final syncedAt = data['syncedAt']?.toString();
      final groupPoints = (userJson['groupPoints'] as num?)?.toInt();
      final contributionPercent = (userJson['contributionPercent'] as num?)
          ?.toDouble();

      ref
          .read(authProvider.notifier)
          .patchCurrentUser(
            activityPoints: newPoints,
            groupPoints: groupPoints,
            contributionPercent: contributionPercent,
          );

      setState(() {
        _isSyncing = false;
        _oldPoints = oldPoints;
        _newPoints = newPoints;
        _delta = delta;
        _lastSyncedAt = syncedAt;
        _setStage(SyncStage.synced);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Activity Points synced: ${oldPoints ?? '-'} -> ${newPoints ?? '-'} (${delta != null && delta >= 0 ? '+' : ''}${delta ?? 0})',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pop(context, {
          'synced': true,
          'oldPoints': oldPoints,
          'newPoints': newPoints,
          'delta': delta,
          'syncedAt': syncedAt,
        });
      }
      return;
    }

    setState(() {
      _isSyncing = false;
      _setStage(SyncStage.failed);
      _errorMessage =
          res.message ??
          'Manual sync failed. Enter activity points again and retry.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message ?? 'Manual sync failed'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildManualFallbackPanel() {
    if (_stage == SyncStage.synced) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Manual Fallback: Enter activity points',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If portal opening fails, login in external browser, check your Activity Points, then enter the value below.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualPointsController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter activity points (e.g. 245)',
              hintStyle: GoogleFonts.inter(color: Colors.white54),
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _manualSyncWithPoints,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync using entered points'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActionPanel() {
    if (_stage != SyncStage.failed && _stage != SyncStage.synced) {
      return const SizedBox.shrink();
    }

    final textTheme = GoogleFonts.outfit(color: Colors.white);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusMessage,
            style: textTheme.copyWith(fontWeight: FontWeight.w700),
          ),
          if (_oldPoints != null || _newPoints != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Activity Points: ${_oldPoints ?? '-'} -> ${_newPoints ?? '-'} (${_delta != null && _delta! >= 0 ? '+' : ''}${_delta ?? 0})',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
          if (_lastSyncedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last Synced: $_lastSyncedAt',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: const Color(0xFFFFB3B3)),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retrySync,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Sync'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openExternalBrowser,
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open External'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            onPressed: () => _retrySync(),
            tooltip: 'Retry Sync',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          IconButton(
            onPressed: _openExternalBrowser,
            tooltip: 'Open External Browser',
            icon: const Icon(
              Icons.open_in_browser_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if ((_isLoading && !_portalInitialized) ||
              _isSyncing ||
              (_stage == SyncStage.openingPortal && !_portalInitialized) ||
              _stage == SyncStage.tokenCaptured ||
              _stage == SyncStage.syncing)
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
                    if (_stage == SyncStage.waitingForLogin) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Login in portal, then sync runs automatically',
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasPortalError ||
                    _stage == SyncStage.failed ||
                    _stage == SyncStage.synced)
                  _buildSyncActionPanel(),
                _buildManualFallbackPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
