import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/screens/chat/personal_chat_screen.dart';
import 'package:team_info_app/screens/chat/team_chat_screen.dart';
import 'package:team_info_app/screens/home/app_shell.dart';
import 'package:team_info_app/screens/projects/project_detail_screen.dart';
import 'package:team_info_app/screens/reports/report_hub_screen.dart';
import 'package:team_info_app/screens/reports/report_review_hub.dart';
import 'package:team_info_app/screens/reports/report_submission_screen.dart';
import 'package:team_info_app/screens/tasks/task_detail_screen.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationRouteObserver extends NavigatorObserver {
  void _sync(Route<dynamic>? route) {
    NotificationService._updateCurrentRouteTargetKey(route);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _sync(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final ApiService _api = ApiService();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final NotificationRouteObserver routeObserver =
      NotificationRouteObserver();
  static String? _lastSyncedToken;
  static Map<String, dynamic>? _pendingTapData;
  static bool _isHandlingTap = false;
  static String? _lastTapTargetKey;
  static DateTime? _lastTapAt;
  static const Duration _duplicateTapWindow = Duration(milliseconds: 1200);
  static String? _currentRouteTargetKey;
  static bool isInitialized = false;
  static String? initializationError;


  static Future<void> initialize() async {
    // 1. Initialize Firebase Messaging behavior
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessageTap(initialMessage);
    }

    // 2. Handle background messages
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.notification?.title}');
      }
    });

    // 4. Initial token fetch (non-blocking)
    _fcm.onTokenRefresh.listen((newToken) async {
      _lastSyncedToken = null;
      await syncFcmTokenIfNeeded(forceToken: newToken);
    });

    isInitialized = true;
    if (kDebugMode) print('✅ NotificationService Core Initialized');
  }

  /// Force a system permission request for Android 13+ and iOS.
  /// Returns the current permission status.
  static Future<bool> requestSystemPermission() async {
    if (kIsWeb) return true;

    // 1. Use permission_handler first for the most reliable system dialog
    final status = await Permission.notification.request();
    if (kDebugMode) print('System Notification Permission Status: $status');

    // 2. Re-initialize Firebase bridge if granted
    if (status.isGranted) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Try to get token immediately
      final token = await _fcm.getToken();
      if (token != null) {
        await syncFcmTokenIfNeeded(forceToken: token);
      }
      return true;
    }
    
    return status.isGranted;
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (kDebugMode) print('Handling background message: ${message.messageId}');
  }

  static Future<void> _handleMessageTap(RemoteMessage message) async {
    await handleNotificationTap(message.data);
  }

  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) {
      _pendingTapData = Map<String, dynamic>.from(data);
      return;
    }

    if (_isHandlingTap) {
      return;
    }

    final targetKey = _buildTargetKey(data);
    if (_isAlreadyOnTarget(targetKey)) {
      return;
    }
    if (_isDuplicateTap(targetKey)) {
      return;
    }

    _isHandlingTap = true;

    try {
      final type = (data['type'] ?? '').toString();

      switch (type) {
        case 'TEAM_CHAT_MESSAGE':
          navigator.push(
            MaterialPageRoute(
              settings: const RouteSettings(name: 'team_chat'),
              builder: (_) => const TeamChatScreen(),
            ),
          );
          return;

        case 'PERSONAL_CHAT_MESSAGE':
          await _openPersonalChatFromNotification(data);
          return;

        case 'TASK_ASSIGNED':
          final taskId = (data['taskId'] ?? '').toString();
          if (taskId.isNotEmpty) {
            navigator.push(
              MaterialPageRoute(
                settings: RouteSettings(
                  name: 'task_detail',
                  arguments: {'taskId': taskId},
                ),
                builder: (_) => TaskDetailScreen(taskId: taskId),
              ),
            );
            return;
          }
          break;

        case 'REPORT_REQUEST_CREATED':
          await _openReportRequestFromNotification(data);
          return;

        case 'PROJECT_CREATED':
        case 'PROJECT_MEMBERS_ASSIGNED':
          await _openProjectFromNotification(data);
          return;
      }

      navigator.push(MaterialPageRoute(builder: (_) => const AppShell()));
    } finally {
      _isHandlingTap = false;
    }
  }

  static Future<void> flushPendingTapIfAny() async {
    if (_pendingTapData == null) {
      return;
    }

    final data = _pendingTapData;
    _pendingTapData = null;
    if (data != null) {
      await handleNotificationTap(data);
    }
  }

  static String _buildTargetKey(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'UNKNOWN').toString();
    switch (type) {
      case 'TEAM_CHAT_MESSAGE':
        return 'TEAM_CHAT';
      case 'PERSONAL_CHAT_MESSAGE':
        return 'PERSONAL_CHAT:${(data['conversationId'] ?? '').toString()}';
      case 'TASK_ASSIGNED':
        return 'TASK:${(data['taskId'] ?? '').toString()}';
      case 'REPORT_REQUEST_CREATED':
        return 'REPORT:${(data['requestId'] ?? '').toString()}';
      case 'PROJECT_CREATED':
      case 'PROJECT_MEMBERS_ASSIGNED':
        return 'PROJECT:${(data['projectId'] ?? '').toString()}';
      default:
        return type;
    }
  }

  static bool _isAlreadyOnTarget(String targetKey) {
    return _currentRouteTargetKey == targetKey;
  }

  static void _updateCurrentRouteTargetKey(Route<dynamic>? route) {
    if (route == null) {
      _currentRouteTargetKey = null;
      return;
    }

    final settings = route.settings;
    final name = settings.name;
    final args = settings.arguments;
    final mapArgs = args is Map ? Map<String, dynamic>.from(args) : null;

    switch (name) {
      case 'team_chat':
        _currentRouteTargetKey = 'TEAM_CHAT';
        return;
      case 'personal_chat':
        _currentRouteTargetKey =
            'PERSONAL_CHAT:${(mapArgs?['conversationId'] ?? '').toString()}';
        return;
      case 'task_detail':
        _currentRouteTargetKey =
            'TASK:${(mapArgs?['taskId'] ?? '').toString()}';
        return;
      case 'report_submission':
      case 'report_review':
        _currentRouteTargetKey =
            'REPORT:${(mapArgs?['requestId'] ?? '').toString()}';
        return;
      case 'project_detail':
        _currentRouteTargetKey =
            'PROJECT:${(mapArgs?['projectId'] ?? '').toString()}';
        return;
      default:
        _currentRouteTargetKey = null;
        return;
    }
  }

  static bool _isDuplicateTap(String targetKey) {
    final now = DateTime.now();
    final isDuplicate =
        _lastTapTargetKey == targetKey &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) <= _duplicateTapWindow;

    _lastTapTargetKey = targetKey;
    _lastTapAt = now;
    return isDuplicate;
  }

  static Future<void> _openPersonalChatFromNotification(
    Map<String, dynamic> data,
  ) async {
    final conversationId = (data['conversationId'] ?? '').toString();
    if (conversationId.isEmpty) return;

    final senderName = (data['senderName'] ?? '').toString();
    String otherUserName = senderName.isNotEmpty ? senderName : 'User';

    if (otherUserName == 'User') {
      try {
        final convRes = await _api.get(ApiConstants.conversations);
        if (convRes.success && convRes.data is List) {
          final matches = (convRes.data as List)
              .cast<Map<String, dynamic>>()
              .where((c) => c['id'] == conversationId)
              .toList();
          if (matches.isNotEmpty) {
            final participants = (matches.first['participants'] as List?) ?? [];
            for (final p in participants) {
              final user = (p as Map<String, dynamic>)['user'];
              if (user is Map<String, dynamic> && user['name'] != null) {
                otherUserName = user['name'].toString();
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: 'personal_chat',
          arguments: {'conversationId': conversationId},
        ),
        builder: (_) => PersonalChatScreen(
          conversationId: conversationId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  static Future<void> _openReportRequestFromNotification(
    Map<String, dynamic> data,
  ) async {
    final requestId = (data['requestId'] ?? '').toString();
    if (requestId.isEmpty) return;

    try {
      final myPendingRes = await _api.get(ApiConstants.myPendingReports);
      if (myPendingRes.success && myPendingRes.data is List) {
        final list = (myPendingRes.data as List)
            .map((e) => ReportRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        final request = list.where((r) => r.id == requestId).firstOrNull;
        if (request != null) {
          final mySubmission = request.submissions.isNotEmpty
              ? request.submissions.first
              : null;
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              settings: RouteSettings(
                name: 'report_submission',
                arguments: {'requestId': request.id},
              ),
              builder: (_) => ReportSubmissionScreen(
                request: request,
                submission: mySubmission,
              ),
            ),
          );
          return;
        }
      }

      final manageableRes = await _api.get(ApiConstants.manageableReports);
      if (manageableRes.success && manageableRes.data is List) {
        final list = (manageableRes.data as List)
            .map((e) => ReportRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        final request = list.where((r) => r.id == requestId).firstOrNull;
        if (request != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              settings: RouteSettings(
                name: 'report_review',
                arguments: {'requestId': request.id},
              ),
              builder: (_) => ReportReviewHub(request: request),
            ),
          );
          return;
        }
      }
    } catch (_) {}

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ReportHubScreen()),
    );
  }

  static Future<void> _openProjectFromNotification(
    Map<String, dynamic> data,
  ) async {
    final projectId = (data['projectId'] ?? '').toString();
    if (projectId.isEmpty) return;

    try {
      final res = await _api.get('${ApiConstants.teamProjects}/$projectId');
      if (res.success && res.data is Map<String, dynamic>) {
        final project = TeamProject.fromJson(res.data as Map<String, dynamic>);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            settings: RouteSettings(
              name: 'project_detail',
              arguments: {'projectId': project.id},
            ),
            builder: (_) => ProjectDetailScreen(project: project),
          ),
        );
        return;
      }
    } catch (_) {}

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  static Future<bool> syncFcmTokenIfNeeded({String? forceToken}) async {
    try {
      final token = forceToken ?? await _fcm.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) print('⚠️ Cannot sync FCM token: Token is null or empty');
        return false;
      }

      if (_lastSyncedToken == token && forceToken == null) {
        return true;
      }

      if (kDebugMode) print('📡 Syncing FCM Token: ${token.substring(0, 10)}...');

      final response = await _api.put(
        ApiConstants.fcmToken,
        body: {'fcmToken': token},
      );
      
      if (kDebugMode) {
        print('✅ FCM Sync Result: success=${response.success}, status=${response.statusCode}, message=${response.message}');
      }

      if (response.success) {
        _lastSyncedToken = token;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exception during FCM sync: $e');
      return false;
    }
  }
}
