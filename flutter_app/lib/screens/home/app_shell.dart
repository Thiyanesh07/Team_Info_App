import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/screens/home/home_screen.dart';
import 'package:team_info_app/screens/projects/projects_screen.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:team_info_app/screens/chat/chat_list_screen.dart';
import 'package:team_info_app/screens/tasks/tasks_screen.dart';
import 'package:team_info_app/screens/profile/profile_screen.dart';
import 'package:team_info_app/services/notification_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ProjectsScreen(),
    ChatListScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (_isOffline != isOffline && mounted) {
        setState(() => _isOffline = isOffline);
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOffline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && isOffline) setState(() => _isOffline = isOffline);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.requestSystemPermission().then((_) {
        NotificationService.syncFcmTokenIfNeeded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Global Offline Banner
          if (_isOffline)
            Container(
              width: double.infinity,
              color: AppColors.error,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                   SizedBox(width: 8),
                   Text('No Internet Connection', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

