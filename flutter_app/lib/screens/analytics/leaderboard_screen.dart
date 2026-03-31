import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<UserModel> _topUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final users = await ref.read(appDataRepositoryProvider).getLeaderboard();
    if (mounted) {
      setState(() {
        _topUsers = users;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _topUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: AppColors.textMuted.withAlpha(100),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ranking data yet',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keep working to appear on the leaderboard!',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: CustomScrollView(
                    slivers: [
                      if (_topUsers.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: _Podium(top3: _topUsers.take(3).toList()),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Start from index 3 if we showed podium
                              final actualIndex = _topUsers.length >= 3
                                  ? index + 3
                                  : index;
                              if (actualIndex >= _topUsers.length) return null;

                              final user = _topUsers[actualIndex];
                              return _LeaderboardItem(
                                user: user,
                                rank: actualIndex + 1,
                              );
                            },
                            childCount: _topUsers.length >= 3
                                ? (_topUsers.length - 3).clamp(0, 100)
                                : _topUsers.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<UserModel> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (top3.length > 1)
          _PodiumSpot(
            user: top3[1],
            rank: 2,
            height: 140,
            color: const Color(0xFFC0C0C0),
          ),
        const SizedBox(width: 12),
        // 1st Place
        _PodiumSpot(
          user: top3[0],
          rank: 1,
          height: 180,
          color: const Color(0xFFFFD700),
          isCenter: true,
        ),
        const SizedBox(width: 12),
        // 3rd Place
        if (top3.length > 2)
          _PodiumSpot(
            user: top3[2],
            rank: 3,
            height: 120,
            color: const Color(0xFFCD7F32),
          ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0);
  }
}

class _PodiumSpot extends StatelessWidget {
  final UserModel user;
  final int rank;
  final double height;
  final Color color;
  final bool isCenter;

  const _PodiumSpot({
    required this.user,
    required this.rank,
    required this.height,
    required this.color,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: isCenter ? 40 : 32,
          backgroundColor: color.withAlpha(50),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: isCenter ? 36 : 28,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name[0],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.name.split(' ').first,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isCenter ? 16 : 14,
          ),
        ),
        Text(
          '${user.rewardPoints} pts',
          style: GoogleFonts.inter(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withAlpha(200), color.withAlpha(50)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(30),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(150),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final UserModel user;
  final int rank;

  const _LeaderboardItem({required this.user, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null ? Text(user.name[0]) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user.rankName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${user.rewardPoints} pts',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
