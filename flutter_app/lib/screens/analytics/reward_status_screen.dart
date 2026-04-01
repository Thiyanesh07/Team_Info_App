import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RewardStatusScreen extends StatefulWidget {
  const RewardStatusScreen({super.key});

  @override
  State<RewardStatusScreen> createState() => _RewardStatusScreenState();
}

class _RewardStatusScreenState extends State<RewardStatusScreen> {
  final _api = ApiService();
  bool _loading = true;
  Map<String, dynamic>? _data;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    final res = await _api.get(ApiConstants.rewardStatus);
    if (res.success && mounted) {
      setState(() {
        _data = res.data;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to fetch status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reward Eligibility', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _fetchStatus, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No data available'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final targets = _data!['yearlyTargets'] as Map<String, dynamic>;
    final teamStatus = _data!['teamStatus'] as List;
    final summary = _data!['summary'];

    final filteredStatus = teamStatus.where((s) {
      final name = s['name'].toString().toLowerCase();
      final regNo = s['regNo'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || regNo.contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchStatus,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearlyTargets(targets),
            const SizedBox(height: 24),
            _buildSummaryCard(summary),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Standings',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${filteredStatus.length} members',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildStatusList(filteredStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyTargets(Map<String, dynamic> targets) {
    // Sort keys: I, II, III, IV, II L, OVERALL
    final order = ['I', 'II', 'III', 'IV', 'II L', 'OVERALL'];
    final keys = targets.keys.toList();
    keys.sort((a, b) {
      final idxA = order.indexOf(a);
      final idxB = order.indexOf(b);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.compareTo(b);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yearly Target (Average RP)',
          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final year = keys[index];
              final value = targets[year];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(year, style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      value.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(40), AppColors.surfaceLight.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat('Eligible', summary['eligibleCount'].toString(), Colors.green),
              _summaryStat('Below Avg', summary['belowAverageCount'].toString(), Colors.orange),
              _summaryStat('Total Team', summary['totalUsers'].toString(), Colors.blue),
            ],
          ),
          const Divider(color: AppColors.divider, height: 32),
          const Text(
            'Keep your Reward Points above your year\'s average to ensure full internal marks.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search by name or roll no...',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusList(List statusList) {
    if (statusList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No members match your search', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statusList.length,
      itemBuilder: (context, index) {
        final member = statusList[index];
        final isEligible = member['isEligible'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withAlpha(150),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isEligible ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: member['profileImageUrl'] != null ? NetworkImage(member['profileImageUrl']) : null,
                child: member['profileImageUrl'] == null ? Text(member['name'][0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${member['regNo']} • Year ${member['year']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member['rewardPoints']} RP',
                    style: GoogleFonts.outfit(
                      color: isEligible ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (!isEligible)
                    Text(
                      '-${member['pointsNeeded']} needed',
                      style: const TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  if (isEligible)
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 20).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
