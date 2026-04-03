import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/screens/analytics/leaderboard_screen.dart';
import 'package:team_info_app/screens/analytics/reward_status_screen.dart';
import 'package:team_info_app/screens/analytics/widgets/resource_heatmap.dart';
import 'package:team_info_app/screens/analytics/widgets/velocity_chart.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  WeeklyAnalytics? _analytics;
  List<dynamic> _leaderboard = [];
  List<Map<String, dynamic>> _workload = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(appDataRepositoryProvider);

    final results = await Future.wait<Object?>([
      repo.getWeeklyAnalytics(),
      repo.getLeaderboard(),
      repo.getTeamWorkload(),
    ]);

    final analytics = results[0] as WeeklyAnalytics?;
    final leaderboard = results[1] as List<UserModel>;
    final workload =
        results[2] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];

    if (mounted) {
      setState(() {
        _analytics = analytics;
        _leaderboard = leaderboard
            .map(
              (u) => {
                'user': u.toJson(),
                'activeDays':
                    u.activityPoints % 7, // Mocking based on points for now
                'totalHours': (u.rewardPoints / 10).toStringAsFixed(1),
              },
            )
            .toList();
        _workload = workload;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Summary',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // New Reward Eligibility Card
                  _buildRewardEligibilityCard(),
                  const SizedBox(height: 16),

                  // Hours breakdown chart
                  if (_analytics != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Hours Breakdown',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: _analytics!.learningHours,
                                    title: '${_analytics!.learningHours}h',
                                    color: AppColors.secondary,
                                    radius: 60,
                                    titleStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: _analytics!.projectHours,
                                    title: '${_analytics!.projectHours}h',
                                    color: AppColors.primary,
                                    radius: 60,
                                    titleStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: _analytics!.otherHours > 0
                                        ? _analytics!.otherHours
                                        : 0.1,
                                    title: '${_analytics!.otherHours}h',
                                    color: AppColors.warning,
                                    radius: 60,
                                    titleStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Legend('Learning', AppColors.secondary),
                              _Legend('Projects', AppColors.primary),
                              _Legend('Others', AppColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            'Total Hours',
                            '${_analytics!.totalHours}h',
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            'Active Days',
                            '${_analytics!.activeDays}/7',
                            AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            'Consistency',
                            '${_analytics!.consistencyScore}%',
                            AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            'Best Day',
                            _analytics!.bestDay ?? 'N/A',
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Engineering Velocity
                  _buildChartSection(
                    'Engineering Velocity',
                    'Tracking daily activity throughput',
                    VelocityChart(
                      dailyActivityCount: _analytics?.dailyActivityCount ?? {},
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resource Allocation
                  _buildChartSection(
                    'Resource Allocation',
                    'Real-time team workload heatmap',
                    ResourceHeatmap(
                      workloadData: _workload,
                      isLoading: _loading,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  // Leaderboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🏆 Leaderboard',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._leaderboard.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final user = item['user'];
                    final medal = i == 0
                        ? '🥇'
                        : i == 1
                        ? '🥈'
                        : i == 2
                        ? '🥉'
                        : '${i + 1}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: i < 3
                            ? AppColors.primary.withAlpha(i == 0 ? 30 : 15)
                            : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: i < 3
                              ? AppColors.primary.withAlpha(50)
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceLight,
                            child: Text(
                              (user['name'] ?? 'U')[0],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${item['activeDays']} active days',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item['totalHours']}h',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildChartSection(String title, String subtitle, Widget chart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }

  Widget _buildRewardEligibilityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(40), AppColors.surfaceLight.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardStatusScreen()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Internal Marks Eligibility',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your Reward Points status relative to your year\'s average.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
