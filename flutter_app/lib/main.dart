import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/screens/auth/login_screen.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/screens/home/app_shell.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team_info_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Initialize Storage & Environment
  await Hive.initFlutter();
  await Hive.openBox('api_cache');
  await dotenv.load(fileName: "assets/.env");

  // 1. Initialize Firebase & Notifications (Required for Google Sign-In)
  try {
    if (kDebugMode) print('🚀 Initializing Firebase...');
    await Firebase.initializeApp();
    if (kDebugMode) print('✅ Firebase App Initialized');
    
    await NotificationService.initialize();
    if (kDebugMode) print('✅ NotificationService Initialized');
  } catch (e) {
    debugPrint('❌ FATAL: Firebase Initialization Failed: $e');
    NotificationService.initializationError = e.toString();
  }

  // 1. Handle UI Exceptions (Widget build errors)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong rendering this component.',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (kDebugMode) // Only show actual exact crash logic if testing locally
                Text(
                  details.exceptionAsString(),
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  };

  // 2. Handle Asynchronous Uncaught Exceptions (API timeouts, background logic)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[GLOBAL ERROR INTERCEPTOR]: $error');
    // Note: In Phase 4, we will hook Firebase Crashlytics up here!
    return true; // Prevents the app from throwing fatal freeze crashes globally
  };

  runApp(const ProviderScope(child: TeamInfoApp()));
}

class TeamInfoApp extends ConsumerWidget {
  const TeamInfoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'TMA_A74',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: NotificationService.navigatorKey,
      navigatorObservers: [NotificationService.routeObserver],
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.flushPendingTapIfAny();
        });
        return child ?? const SizedBox.shrink();
      },
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
