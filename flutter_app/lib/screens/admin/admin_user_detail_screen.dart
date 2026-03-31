import 'package:flutter/material.dart';
import 'package:team_info_app/screens/profile/certifications_screen.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    setState(() => _loading = true);
    final res = await _api.get('${ApiConstants.adminUserDetail}/${widget.userId}/detail');
    if (res.success && mounted) {
      setState(() {
        _userData = res.data;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Inspection: ${widget.userName.split(' ').first}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('Failed to load user detail'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSectionHeader('📈 Performance Stats'),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader('🛠️ Skills Portfolio'),
          _buildSkillsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('🚀 Team Projects'),
          _buildProjectsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('🏆 Hackathons & Learning'),
          _buildGrowthSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('📜 Certifications'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
            title: const Text('Professional Certifications', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('View verified achievements and licenses', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CertificationsScreen(targetUser: UserModel.fromJson(_userData!))),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('📝 Daily Activity Log'),
          _buildActivitiesSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _userData!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage: user['profileImageUrl'] != null ? NetworkImage(user['profileImageUrl']) : null,
            child: user['profileImageUrl'] == null ? Text(user['name'][0].toUpperCase(), style: const TextStyle(fontSize: 32, color: AppColors.primary)) : null,
          ).animate().scale(duration: 400.ms),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  user['email'],
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(100)),
                  ),
                  child: Text(
                    user['role'] ?? 'MEMBER',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final user = _userData!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildStatTile('Reward Points', user['rewardPoints'].toString(), Icons.stars_rounded, Colors.orange),
        _buildStatTile('Activity Points', user['activityPoints'].toString(), Icons.local_fire_department, Colors.deepOrange),
        _buildStatTile('Tasks Done', (user['taskReports'] as List).length.toString(), Icons.task_alt_rounded, Colors.green),
        _buildStatTile('Projects', (user['teamMemberships'] as List).length.toString(), Icons.rocket_launch_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final user = _userData!;
    final skills = [
      ...(user['primarySkills'] as List? ?? []),
      ...(user['secondarySkills'] as List? ?? []),
      ...(user['specialSkills'] as List? ?? []),
    ];

    if (skills.isEmpty) return _buildEmptyNote('No skills added yet');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withAlpha(100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      )).toList(),
    );
  }

  Widget _buildProjectsSection() {
    final projects = _userData!['teamMemberships'] as List;
    if (projects.isEmpty) return _buildEmptyNote('No team projects found');

    return Column(
      children: projects.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_open_rounded, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(p['teamProject']['projectName'], style: const TextStyle(color: Colors.white, fontSize: 14))),
            Text(p['teamProject']['status'], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildGrowthSection() {
    final hackathons = _userData!['hackathons'] as List;
    final learnings = _userData!['learnings'] as List;

    return Column(
      children: [
        if (hackathons.isEmpty && learnings.isEmpty) _buildEmptyNote('No growth records found'),
        ...hackathons.map((h) => _buildGrowthItem(h['hackName'], 'Hackathon', Icons.emoji_events, Colors.purple)),
        ...learnings.map((l) => _buildGrowthItem(l['skillName'], 'Learning', Icons.school, Colors.teal)),
      ],
    );
  }

  Widget _buildGrowthItem(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      dense: true,
    );
  }

  Widget _buildActivitiesSection() {
    final activities = _userData!['dailyActivities'] as List;
    if (activities.isEmpty) return _buildEmptyNote('No daily logs found');

    return Column(
      children: activities.take(5).map((a) {
        final date = DateTime.parse(a['date']);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(a['description'] ?? 'Work session', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          subtitle: Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          trailing: Text(a['type'], style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyNote(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
    );
  }
}
