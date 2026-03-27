import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/screens/analytics/analytics_screen.dart';
import 'package:team_info_app/screens/admin/user_management_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ApiService();
  WeeklyAnalytics? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final res = await _api.get(ApiConstants.weeklyAnalytics);
    if (res.success && res.data != null && mounted) {
      setState(() { _analytics = WeeklyAnalytics.fromJson(res.data); _loading = false; });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!) : null,
                      child: user.profileImageUrl == null
                          ? Text(user.name[0].toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${user.name.split(' ').first}! 👋',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text(user.role.displayName,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (user.role.canManageUsers)
                      IconButton(
                        icon: const Icon(Icons.admin_panel_settings, color: AppColors.secondary),
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const UserManagementScreen())),
                      ),
                  ],
                ).animate().fade(duration: 500.ms).slideY(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
                const SizedBox(height: 28),

                // Quick Stats
                Text('Weekly Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white))
                    .animate().fade(delay: 100.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 16),

                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        icon: Icons.access_time_rounded, label: 'Total Hours',
                        value: '${_analytics?.totalHours ?? 0}h',
                        gradient: const [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        icon: Icons.school_rounded, label: 'Learning',
                        value: '${_analytics?.learningHours ?? 0}h',
                        gradient: const [Color(0xFF03DAC6), Color(0xFF00BFA5)],
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        icon: Icons.code_rounded, label: 'Projects',
                        value: '${_analytics?.projectHours ?? 0}h',
                        gradient: const [Color(0xFFFF6584), Color(0xFFFF4081)],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        icon: Icons.trending_up_rounded, label: 'Consistency',
                        value: '${_analytics?.consistencyScore ?? 0}%',
                        gradient: const [Color(0xFFFF9800), Color(0xFFFF6D00)],
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Activity Summary
                  _SectionCard(
                    title: 'Activity Summary',
                    trailing: TextButton(
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                      child: Text('View All', style: GoogleFonts.inter(color: AppColors.primary)),
                    ),
                    children: [
                      _InfoRow('Active Days', '${_analytics?.activeDays ?? 0}/7 days'),
                      _InfoRow('Best Day', _analytics?.bestDay ?? 'N/A'),
                      _InfoRow('Best Day Hours', '${_analytics?.bestDayHours ?? 0}h'),
                      _InfoRow('Total Activities', '${_analytics?.totalActivities ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Text('Quick Actions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      _QuickAction(icon: Icons.add_task, label: 'Log Activity', color: AppColors.primary,
                        onTap: () {}).animate().scale(delay: 400.ms, duration: 300.ms, curve: Curves.easeOutBack),
                      _QuickAction(icon: Icons.folder_open, label: 'My Projects', color: AppColors.secondary,
                        onTap: () {}).animate().scale(delay: 500.ms, duration: 300.ms, curve: Curves.easeOutBack),
                      _QuickAction(icon: Icons.emoji_events, label: 'Hackathons', color: AppColors.accent,
                        onTap: () {}).animate().scale(delay: 600.ms, duration: 300.ms, curve: Curves.easeOutBack),
                      _QuickAction(icon: Icons.school, label: 'Learning', color: AppColors.warning,
                        onTap: () {}).animate().scale(delay: 700.ms, duration: 300.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _StatCard({required this.icon, required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gradient[0].withAlpha(30), gradient[1].withAlpha(15)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradient[0].withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gradient[0], size: 24),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({required this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
