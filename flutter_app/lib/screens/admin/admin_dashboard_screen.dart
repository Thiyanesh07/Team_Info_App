import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/screens/admin/user_management_screen.dart';
import 'package:team_info_app/screens/admin/audit_log_screen.dart';
import 'package:team_info_app/screens/admin/admin_user_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:team_info_app/providers/system_config_provider.dart';
import 'package:team_info_app/screens/profile/college_sync_screen.dart';
import 'package:team_info_app/core/widgets/shimmer_loading.dart';
import 'package:team_info_app/services/api_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  Map<String, dynamic>? _overviewData;
  List<UserModel> _allUsers = [];
  bool _loadingOverview = true;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOverview();
    _loadAllUsers();
  }

  Future<void> _loadOverview() async {
    final res = await _api.get(ApiConstants.adminOverview);
    if (res.success && mounted) {
      setState(() {
        _overviewData = res.data;
        _loadingOverview = false;
      });
    }
  }

  Future<void> _loadAllUsers() async {
    final res = await _api.get(ApiConstants.users);
    if (res.success && mounted) {
      setState(() {
        _allUsers = (res.data as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
        _loadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Command Center',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              text: '📊 Dashboard',
              icon: Icon(Icons.dashboard_rounded, size: 20),
            ),
            Tab(
              text: '👥 Members',
              icon: Icon(Icons.people_alt_rounded, size: 20),
            ),
            Tab(
              text: '📋 Inspection',
              icon: Icon(Icons.assignment_ind_rounded, size: 20),
            ),
            Tab(text: '🔒 Audit', icon: Icon(Icons.security_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          const UserManagementScreen(),
          _buildInspectionTab(),
          const AuditLogScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_loadingOverview) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(4, (_) => const ShimmerStatsCard()),
      );
    }
    if (_overviewData == null) {
      return const Center(child: Text('Failed to load stats'));
    }

    final stats = _overviewData!;
    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Pulse',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatGrid(stats),
            const SizedBox(height: 24),

            // New Sync Section
            _buildSyncSection(),
            const SizedBox(height: 24),

            Text(
              'Recent Activities',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentActivityList(stats['recentActivities'] as List),
            const SizedBox(height: 32),

            // System Controls Section
            _buildSystemControls(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemControls() {
    final configAsync = ref.watch(systemConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Controls',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: configAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => ListTile(
              title: const Text('Error loading config',
                  style: TextStyle(color: AppColors.error)),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    ref.read(systemConfigProvider.notifier).fetchConfig(),
              ),
            ),
            data: (config) => SwitchListTile(
              activeThumbColor: AppColors.primary,
              title: Text(
                'AP Sync via Portal',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Allow users to synchronize Activity Points via the Bitsathy portal. If off, users must update points manually.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              value: config.apSyncEnabled,
              onChanged: (val) async {
                final success = await ref
                    .read(systemConfigProvider.notifier)
                    .updateConfig(apSyncEnabled: val);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Portal Sync ${val ? 'Enabled' : 'Disabled'}'),
                      backgroundColor: val ? Colors.green : Colors.orange,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          stats['totalUsers'].toString(),
          Icons.group,
          AppColors.primary,
        ),
        _buildStatCard(
          'Active Tasks',
          stats['tasks']['total'].toString(),
          Icons.task_alt,
          AppColors.secondary,
        ),
        _buildStatCard(
          'Team Projects',
          stats['projects']['total'].toString(),
          Icons.rocket_launch,
          Colors.orange,
        ),
        _buildStatCard(
          'Hackathons',
          stats['counts']['hackathons'].toString(),
          Icons.emoji_events,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSyncSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(50),
            AppColors.surfaceLight.withAlpha(30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Data Synchronization',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Fetch reward points for all teammates using each member\'s roll number from Hugging Face.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showSyncConfirmation,
                icon: const Icon(Icons.stars_rounded, size: 18),
                label: const Text('Sync Reward Points (All Teammates)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showActivitySyncDialog,
                icon: const Icon(Icons.local_fire_department_outlined, size: 18),
                label: const Text('Sync Team Activity Points (Portal)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _showActivitySyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Sync Team Points',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: const Text(
          'We will open the portal login. Once you log in, we will automatically sync activity points for the entire team.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CollegeSyncScreen(isAdminMode: true),
                ),
              );

              if (result != null && result['psToken'] != null) {
                _syncTeamActivityPoints(result['psToken']);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Login & Sync'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncTeamActivityPoints(String psToken) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _api.post(
      ApiConstants.syncTeamActivity,
      body: {'psToken': psToken},
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (res.success) {
      final data = res.data as Map;
      _showActivitySyncSummary(data);
      _loadOverview();
      _loadAllUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Batch sync failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showActivitySyncSummary(Map data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              'Batch Sync Completed',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryItem(
              'Members Updated',
              (data['updatedCount'] ?? 0).toString(),
              Colors.green,
            ),
            _summaryItem(
              'Failed / Partial',
              (data['failedCount'] ?? 0).toString(),
              Colors.orange,
            ),
            _summaryItem(
              'Total Members',
              (data['total'] ?? 0).toString(),
              Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSyncConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Trigger Global Sync?',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: const Text(
          'This will fetch reward points for all teammates from Hugging Face using stored roll numbers and update the database. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _syncRewardPoints();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Start Sync'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncRewardPoints() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _api.post(ApiConstants.syncRewards);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (res.success) {
      final summary =
          (res.data['summary'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      _showSyncSummary(summary);
      _loadOverview();
      _loadAllUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Sync failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSyncSummary(Map<String, dynamic> summary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              'Sync Successful',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryItem(
              'Users Updated',
              (summary['updatedCount'] ?? 0).toString(),
              Colors.green,
            ),
            _summaryItem(
              'No Data / Failed',
              (summary['failedCount'] ?? 0).toString(),
              Colors.orange,
            ),
            _summaryItem(
              'Total Processed',
              (summary['total'] ?? 0).toString(),
              Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(List activities) {
    if (activities.isEmpty) return const Text('No recent activities');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              backgroundImage: activity['user']?['profileImageUrl'] != null
                  ? CachedNetworkImageProvider(activity['user']['profileImageUrl'])
                  : null,
              child: activity['user']?['profileImageUrl'] == null
                  ? const Icon(Icons.person, size: 20, color: AppColors.primary)
                  : null,
            ),
            title: Text(
              activity['title'] ?? 'Activity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              activity['content'] ?? '',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspectionTab() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserDetailScreen(
                          userId: user.id,
                          userName: user.name,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: user.profileImageUrl != null
                        ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(user.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: (index * 30).ms)
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }
}
