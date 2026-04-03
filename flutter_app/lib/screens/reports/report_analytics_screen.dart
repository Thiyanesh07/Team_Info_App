import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/services/api_service.dart';

class ReportAnalyticsScreen extends ConsumerStatefulWidget {
  final ReportRequest request;

  const ReportAnalyticsScreen({super.key, required this.request});

  @override
  ConsumerState<ReportAnalyticsScreen> createState() => _ReportAnalyticsScreenState();
}

class _ReportAnalyticsScreenState extends ConsumerState<ReportAnalyticsScreen> {
  final _api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _loading = true);
    final res = await _api.getReportAnalytics(widget.request.id);
    if (res.success && mounted) {
      setState(() {
        _analytics = res.data;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to load analytics')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Participation Audit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No data available', style: TextStyle(color: Colors.white)))
              : RefreshIndicator(
                  onRefresh: _fetchAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 32),
                        Text(
                          'Member Breakdown',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_analytics!['members'] as List).map((m) => _buildMemberTile(m)),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _analytics!['totalAssigned'] ?? 0;
    final submitted = _analytics!['totalSubmitted'] ?? 0;
    final pending = _analytics!['pendingCount'] ?? 0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Assigned', total.toString(), AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Submitted', submitted.toString(), AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Pending', pending.toString(), AppColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final bool isSubmitted = member['isSubmitted'] ?? false;
    final bool isLate = member['isLate'] ?? false;
    final status = member['status'] ?? 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLate ? AppColors.error.withOpacity(0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surface,
            backgroundImage: member['profileImageUrl'] != null ? NetworkImage(member['profileImageUrl']) : null,
            child: member['profileImageUrl'] == null ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  member['regNo'] ?? '-',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSubmitted) ...[
                Text(
                  status,
                  style: TextStyle(
                    color: isLate ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (isLate)
                  const Text(
                    'LATE SUBMISSION',
                    style: TextStyle(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                if (member['submittedAt'] != null)
                  Text(
                    DateFormat.MMMd().add_Hm().format(DateTime.parse(member['submittedAt'])),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
              ] else
                const Text(
                  'PENDING',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
