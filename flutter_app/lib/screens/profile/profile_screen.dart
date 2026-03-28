import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/screens/profile/edit_profile_screen.dart';
import 'package:team_info_app/screens/skills/skills_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              ref.read(authProvider.notifier).refreshUser();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + Name
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surfaceLight,
              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
              child: user.profileImageUrl == null
                  ? Text(user.name[0].toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(user.name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(user.role.displayName,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text(user.email, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Info Cards
            _InfoSection(title: 'Basic Info', children: [
              if (user.regNo != null) _InfoTile('Reg No', user.regNo!),
              if (user.department != null) _InfoTile('Department', user.department!),
              if (user.year != null) _InfoTile('Year', user.year!),
              if (user.mobile != null) _InfoTile('Mobile', user.mobile!),
              if (user.cgpa != null) _InfoTile('CGPA', user.cgpa.toString()),
            ]),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(child: _StatChip('Reward Pts', user.rewardPoints.toString(), AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: _StatChip('Activity Pts', user.activityPoints.toString(), AppColors.secondary)),
              ],
            ),
            const SizedBox(height: 16),

            // Skills Portfolio
            _InfoSection(
              title: 'Skills Portfolio',
              children: [
                _buildSkillsPreview(context, user),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillsScreen())),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Manage Portfolio Cards'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Social Links
            if (_hasSocialLinks(user)) ...[
              const SizedBox(height: 16),
              _InfoSection(title: 'Social Links', children: [
                if (user.githubUrl != null) _LinkTile('GitHub', user.githubUrl!, Icons.code),
                if (user.linkedinUrl != null) _LinkTile('LinkedIn', user.linkedinUrl!, Icons.work),
                if (user.leetcodeUrl != null) _LinkTile('LeetCode', user.leetcodeUrl!, Icons.terminal),
                if (user.twitterUrl != null) _LinkTile('Twitter', user.twitterUrl!, Icons.chat),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasSocialLinks(UserModel user) =>
      user.githubUrl != null || user.linkedinUrl != null || user.leetcodeUrl != null || user.twitterUrl != null;
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

  Widget _buildSkillsPreview(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.primarySkills.isNotEmpty) _SkillRow('Primary', user.primarySkills, AppColors.primary),
        if (user.secondarySkills.isNotEmpty) _SkillRow('Secondary', user.secondarySkills, AppColors.secondary),
        if (user.programmingLangs.isNotEmpty) _SkillRow('Langs', user.programmingLangs, AppColors.warning),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final List<String> skills;
  final Color color;
  const _SkillRow(this.label, this.skills, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(50))),
              child: Text(s, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label, url;
  final IconData icon;
  const _LinkTile(this.label, this.url, this.icon);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary)),
            const Spacer(),
            const Icon(Icons.open_in_new, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
