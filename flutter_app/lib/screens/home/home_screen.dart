import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/screens/analytics/analytics_screen.dart';
import 'package:team_info_app/screens/analytics/leaderboard_screen.dart';
import 'package:team_info_app/screens/admin/user_management_screen.dart';
import 'package:team_info_app/screens/activity/activity_screen.dart';
import 'package:team_info_app/screens/projects/projects_screen.dart';
import 'package:team_info_app/screens/hackathons/hackathons_screen.dart';
import 'package:team_info_app/screens/learning/learning_screen.dart';
import 'package:team_info_app/screens/skills/skills_screen.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:team_info_app/core/widgets/shimmer_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  WeeklyAnalytics? _analytics;
  List<UserModel> _teamMembers = [];
  List<UserModel> _leaderboard = [];
  UserModel? _selectedUser;
  bool _loading = true;

  List<TaskAssignment> _pendingMyTasks = [];
  List<TaskAssignment> _pendingAssignedTasks = [];

  @override
  void initState() {
    super.initState();
    _tryLoadFromCache();
    _loadAll();
  }

  void _tryLoadFromCache() {
    final repo = ref.read(appDataRepositoryProvider);
    final cachedAnalytics = repo.getCachedAnalytics();
    final cachedLeaderboard = repo.getCachedLeaderboard();

    if (cachedAnalytics != null || cachedLeaderboard.isNotEmpty) {
      setState(() {
        _analytics = cachedAnalytics;
        _leaderboard = cachedLeaderboard;
        _loading = false; // Show cached data immediately
      });
    }
  }

  Future<void> _loadAll() async {
    final user = ref.read(authProvider).user;
    if (user?.role.canManageUsers == true) {
      _loadTeamMembers();
    }
    await Future.wait([
      _loadAnalytics(),
      _loadPendingTasks(),
      _loadLeaderboard(),
    ]);
  }

  Future<void> _loadLeaderboard() async {
    final users = await ref.read(appDataRepositoryProvider).getLeaderboard();
    if (mounted) {
      setState(() => _leaderboard = users);
    }
  }

  Future<void> _loadPendingTasks() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final isLeader = user.role.isLeader;
    final repo = ref.read(appDataRepositoryProvider);

    final tasks = await repo.getMyTasks();
    _pendingMyTasks = tasks.where((t) => t.status != 'COMPLETED').toList();

    if (isLeader) {
      final assigned = await repo.getAssignedTasks();
      _pendingAssignedTasks = assigned
          .where((t) => t.status != 'COMPLETED')
          .toList();
    }

    if (mounted) {
      setState(() {});
      _checkPendingTasksAlerts();
    }
  }

  Future<void> _checkPendingTasksAlerts() async {
    if (_pendingMyTasks.isEmpty && _pendingAssignedTasks.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastAlertDate = prefs.getString('last_task_alert_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastAlertDate == today) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(
              'Pending Tasks Action',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (_pendingMyTasks.isNotEmpty) ...[
                Text(
                  '⚠️ Assigned To You:',
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ..._pendingMyTasks.map((t) => _buildAlertItem(t, false)),
                const SizedBox(height: 16),
              ],
              if (_pendingAssignedTasks.isNotEmpty) ...[
                Text(
                  '👀 Pending from Team:',
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ..._pendingAssignedTasks.map((t) => _buildAlertItem(t, true)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              prefs.setString('last_task_alert_date', today);
              Navigator.pop(context);
            },
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              prefs.setString('last_task_alert_date', today);
              Navigator.pop(context);
            },
            child: const Text(
              'Go to Tasks',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(TaskAssignment t, bool isAssignedByMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAssignedByMe
                  ? 'Pending for: ${t.assignedTo?['name'] ?? 'Unknown'}'
                  : 'Status: ${t.status.replaceAll('_', ' ')}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTeamMembers() async {
    final members = await ref.read(appDataRepositoryProvider).getTeamMembers();
    if (mounted) {
      setState(() {
        _teamMembers = members;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    final analytics = await ref
        .read(appDataRepositoryProvider)
        .getWeeklyAnalytics(userId: _selectedUser?.id);
    if (mounted) {
      setState(() {
        _analytics = analytics;
        _loading = false;
      });
    }
  }

  String _safeName(String? rawName) {
    final trimmed = rawName?.trim() ?? '';
    return trimmed.isEmpty ? 'User' : trimmed;
  }

  String _safeFirstName(String? rawName) {
    return _safeName(rawName).split(RegExp(r'\s+')).first;
  }

  String _safeInitial(String? rawName) {
    return _safeName(rawName)[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: _GradientOrb(
              color: AppColors.primary.withAlpha(40),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _GradientOrb(
              color: AppColors.secondary.withAlpha(30),
              size: 400,
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    _buildHeader(user),
                    const SizedBox(height: 32),

                    // Pending Tasks Banner
                    if (_pendingMyTasks.isNotEmpty ||
                        _pendingAssignedTasks.isNotEmpty) ...[
                      _buildPendingTasksBanner(),
                      const SizedBox(height: 28),
                    ],

                    // Admin View Selector
                    if (user.role.canManageUsers) ...[
                      _buildAdminSelector(),
                      const SizedBox(height: 28),
                    ],

                    // Main Stats Section
                    _buildSectionTitle(
                      _selectedUser == null
                          ? 'My Performance'
                          : '${_safeFirstName(_selectedUser!.name)}\'s Performance',
                    ),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 28),

                    // Top Performers Leaderboard Preview
                    _buildLeaderboardPreview(),
                    const SizedBox(height: 28),

                    // Activity Section
                    _buildActivitySummary(context),
                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.cardDark,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    _safeInitial(user.name),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${_safeFirstName(user.name)}! ✨',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Text(
                  user.role.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (user.role.canManageUsers)
          _HeaderAction(
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
      ],
    ).animate().fade(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildAdminSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline,
            color: AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Viewing Data For:',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          DropdownButton<UserModel?>(
            value: _selectedUser,
            hint: const Text(
              'My Stats',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            dropdownColor: AppColors.cardDark,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  'My Stats',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              ..._teamMembers.map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m.name,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
            onChanged: (v) {
              setState(() => _selectedUser = v);
              _loadAnalytics();
            },
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPendingTasksBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Action Required',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pendingMyTasks.isNotEmpty) ...[
            Text(
              'You have ${_pendingMyTasks.length} pending tasks to complete.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
          ],
          if (_pendingAssignedTasks.isNotEmpty) ...[
            Text(
              'Your team has ${_pendingAssignedTasks.length} pending tasks to finish.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please navigate to the Tasks tab from the bottom menu.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withAlpha(50),
                foregroundColor: AppColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Pending Tasks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_loading) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: const [
          ShimmerStatsCard(),
          ShimmerStatsCard(),
          ShimmerStatsCard(),
          ShimmerStatsCard(),
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _StatCard(
          icon: Icons.timer_outlined,
          label: 'Total Hours',
          value: '${_analytics?.totalHours.toStringAsFixed(1) ?? 0}h',
          color: const Color(0xFF6366F1),
          delay: 0,
          progress: (_analytics?.totalHours ?? 0) / 40, // Assuming 40h goal
        ),
        _StatCard(
          icon: Icons.auto_graph_rounded,
          label: 'Learning',
          value: '${_analytics?.learningHours.toStringAsFixed(1) ?? 0}h',
          color: const Color(0xFF10B981),
          delay: 100,
          progress: (_analytics?.learningHours ?? 0) / 10, // Assuming 10h goal
        ),
        _StatCard(
          icon: Icons.layers_outlined,
          label: 'Projects',
          value: '${_analytics?.projectHours.toStringAsFixed(1) ?? 0}h',
          color: const Color(0xFFEC4899),
          delay: 200,
          progress: (_analytics?.projectHours ?? 0) / 20, // Assuming 20h goal
        ),
        _StatCard(
          icon: Icons.bolt_rounded,
          label: 'Consistency',
          value: '${_analytics?.consistencyScore ?? 0}%',
          color: const Color(0xFFF59E0B),
          delay: 300,
          progress: (_analytics?.consistencyScore ?? 0) / 100,
        ),
      ],
    );
  }

  Widget _buildLeaderboardPreview() {
    if (_leaderboard.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Top Performers'),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _leaderboard.take(5).length,
            itemBuilder: (context, index) {
              final user = _leaderboard[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Badge(
                      label: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: index == 0
                          ? Colors.amber
                          : index == 1
                          ? Colors.grey
                          : index == 2
                          ? Colors.brown
                          : AppColors.primary,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? Text(_safeInitial(user.name))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _safeFirstName(user.name),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${user.rewardPoints} pts',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fade(delay: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildActivitySummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(180),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Insight',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
                child: Text(
                  'Analytics',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow(
            'Active Days',
            '${_analytics?.activeDays ?? 0} / 7',
            Icons.calendar_today_rounded,
          ),
          _MetricRow(
            'Peak Performance',
            _analytics?.bestDay ?? 'N/A',
            Icons.star_outline_rounded,
          ),
          _MetricRow(
            'Avg. Intensity',
            '${((_analytics?.totalHours ?? 0) / 7).toStringAsFixed(1)}h/day',
            Icons.speed_rounded,
          ),
          _MetricRow(
            'Logged Actions',
            '${_analytics?.totalActivities ?? 0}',
            Icons.history_edu_rounded,
          ),
        ],
      ),
    ).animate().fade(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickAction(
          icon: Icons.add_task_rounded,
          label: 'Log Activity',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivityScreen()),
          ),
        ),
        _QuickAction(
          icon: Icons.work_outline_rounded,
          label: 'Projects',
          color: AppColors.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectsScreen()),
          ),
        ),
        _QuickAction(
          icon: Icons.emoji_events_outlined,
          label: 'Hackathons',
          color: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HackathonsScreen()),
          ),
        ),
        _QuickAction(
          icon: Icons.bolt_rounded,
          label: 'Skills',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SkillsScreen()),
          ),
        ),
        _QuickAction(
          icon: Icons.school_outlined,
          label: 'Learning',
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LearningScreen()),
          ),
        ),
      ],
    ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;
  final double progress;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withAlpha(100),
                    ),
                    minHeight: 4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(delay: delay.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

class _MetricRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MetricRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withAlpha(150),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

class _GradientOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GradientOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
      ),
    );
  }
}
