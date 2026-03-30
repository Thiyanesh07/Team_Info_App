import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/screens/analytics/leaderboard_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = ApiService();
  WeeklyAnalytics? _analytics;
  List<dynamic> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final [analyticsRes, leaderboardRes] = await Future.wait([
      _api.get(ApiConstants.weeklyAnalytics),
      _api.get(ApiConstants.leaderboard),
    ]);

    if (mounted) {
      setState(() {
        if (analyticsRes.success) _analytics = WeeklyAnalytics.fromJson(analyticsRes.data);
        if (leaderboardRes.success) _leaderboard = leaderboardRes.data as List;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Summary', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 16),

                  // Hours breakdown chart
                  if (_analytics != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Text('Hours Breakdown', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _analytics!.learningHours,
                                  title: '${_analytics!.learningHours}h',
                                  color: AppColors.secondary,
                                  radius: 60,
                                  titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value: _analytics!.projectHours,
                                  title: '${_analytics!.projectHours}h',
                                  color: AppColors.primary,
                                  radius: 60,
                                  titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value: _analytics!.otherHours > 0 ? _analytics!.otherHours : 0.1,
                                  title: '${_analytics!.otherHours}h',
                                  color: AppColors.warning,
                                  radius: 60,
                                  titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                            )),
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
                        Expanded(child: _MiniStat('Total Hours', '${_analytics!.totalHours}h', AppColors.primary)),
                        const SizedBox(width: 10),
                        Expanded(child: _MiniStat('Active Days', '${_analytics!.activeDays}/7', AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _MiniStat('Consistency', '${_analytics!.consistencyScore}%', AppColors.accent)),
                        const SizedBox(width: 10),
                        Expanded(child: _MiniStat('Best Day', _analytics!.bestDay ?? 'N/A', AppColors.warning)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Leaderboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🏆 Leaderboard', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                        child: Text('View Details', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._leaderboard.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final user = item['user'];
                    final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: i < 3 ? AppColors.primary.withAlpha(i == 0 ? 30 : 15) : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: i < 3 ? AppColors.primary.withAlpha(50) : AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 18, backgroundColor: AppColors.surfaceLight,
                            child: Text((user['name'] ?? 'U')[0],
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'] ?? '', style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                Text('${item['activeDays']} active days',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('${item['totalHours']}h',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
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
        color: color.withAlpha(15), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}
