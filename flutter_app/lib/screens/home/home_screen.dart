import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/screens/analytics/analytics_screen.dart';
import 'package:team_info_app/screens/admin/user_management_screen.dart';
import 'package:team_info_app/screens/activity/activity_screen.dart';
import 'package:team_info_app/screens/projects/projects_screen.dart';
import 'package:team_info_app/screens/hackathons/hackathons_screen.dart';
import 'package:team_info_app/screens/learning/learning_screen.dart';
import 'package:team_info_app/screens/skills/skills_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = ApiService();
  WeeklyAnalytics? _analytics;
  List<UserModel> _teamMembers = [];
  UserModel? _selectedUser;
  bool _loading = true;
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = ref.read(authProvider).user;
    if (user?.role.canManageUsers == true) {
      _loadTeamMembers();
    }
    _loadAnalytics();
  }

  Future<void> _loadTeamMembers() async {
    setState(() => _loadingMembers = true);
    final res = await _api.get(ApiConstants.users);
    if (res.success && mounted) {
      setState(() {
        _teamMembers = (res.data as List).map((e) => UserModel.fromJson(e)).toList();
        _loadingMembers = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    final queryParams = _selectedUser != null ? {'userId': _selectedUser!.id} : <String, String>{};
    final res = await _api.get(ApiConstants.weeklyAnalytics, queryParams: queryParams);
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(top: -100, right: -100, child: _GradientOrb(color: AppColors.primary.withAlpha(40), size: 300)),
          Positioned(bottom: -50, left: -100, child: _GradientOrb(color: AppColors.secondary.withAlpha(30), size: 400)),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    _buildHeader(user),
                    const SizedBox(height: 32),

                    // Admin View Selector
                    if (user.role.canManageUsers) ...[
                      _buildAdminSelector(),
                      const SizedBox(height: 28),
                    ],

                    // Main Stats Section
                    _buildSectionTitle(_selectedUser == null ? 'My Performance' : '${_selectedUser!.name.split(' ').first}\'s Performance'),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
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
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.cardDark,
            backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
            child: user.profileImageUrl == null
                ? Text(user.name[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, ${user.name.split(' ').first}! ✨',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Text(user.role.displayName,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        if (user.role.canManageUsers)
          _HeaderAction(
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
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
          const Icon(Icons.people_outline, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Text('Viewing Data For:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          DropdownButton<UserModel?>(
            value: _selectedUser,
            hint: const Text('My Stats', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            dropdownColor: AppColors.cardDark,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
            items: [
              const DropdownMenuItem(value: null, child: Text('My Stats', style: TextStyle(color: AppColors.primary))),
              ..._teamMembers.map((m) => DropdownMenuItem(value: m, child: Text(m.name, style: const TextStyle(fontSize: 13, color: Colors.white)))),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white));
  }

  Widget _buildStatsGrid() {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
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
          icon: Icons.timer_outlined, label: 'Total Hours',
          value: '${_analytics?.totalHours.toStringAsFixed(1) ?? 0}h',
          color: const Color(0xFF6366F1), delay: 0,
        ),
        _StatCard(
          icon: Icons.auto_graph_rounded, label: 'Learning',
          value: '${_analytics?.learningHours.toStringAsFixed(1) ?? 0}h',
          color: const Color(0xFF10B981), delay: 100,
        ),
        _StatCard(
          icon: Icons.layers_outlined, label: 'Projects',
          value: '${_analytics?.projectHours.toStringAsFixed(1) ?? 0}h',
          color: const Color(0xFFEC4899), delay: 200,
        ),
        _StatCard(
          icon: Icons.bolt_rounded, label: 'Consistency',
          value: '${_analytics?.consistencyScore ?? 0}%',
          color: const Color(0xFFF59E0B), delay: 300,
        ),
      ],
    );
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
              Text('Weekly Insight', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                child: Text('Analytics', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow('Active Days', '${_analytics?.activeDays ?? 0} / 7', Icons.calendar_today_rounded),
          _MetricRow('Peak Performance', _analytics?.bestDay ?? 'N/A', Icons.star_outline_rounded),
          _MetricRow('Avg. Intensity', '${((_analytics?.totalHours ?? 0) / 7).toStringAsFixed(1)}h/day', Icons.speed_rounded),
          _MetricRow('Logged Actions', '${_analytics?.totalActivities ?? 0}', Icons.history_edu_rounded),
        ],
      ),
    ).animate().fade(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: [
        _QuickAction(
          icon: Icons.add_task_rounded, label: 'Log Activity', color: AppColors.primary,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())),
        ),
        _QuickAction(
          icon: Icons.work_outline_rounded, label: 'Projects', color: AppColors.secondary,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen())),
        ),
        _QuickAction(
          icon: Icons.emoji_events_outlined, label: 'Hackathons', color: AppColors.accent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HackathonsScreen())),
        ),
        _QuickAction(
          icon: Icons.bolt_rounded, label: 'Skills', color: AppColors.primary,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillsScreen())),
        ),
        _QuickAction(
          icon: Icons.school_outlined, label: 'Learning', color: AppColors.warning,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningScreen())),
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

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: delay.ms, duration: 500.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
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
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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
        decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
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
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withAlpha(0)])),
    );
  }
}
