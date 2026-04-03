import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/screens/profile/edit_profile_screen.dart';
import 'package:team_info_app/screens/skills/skills_screen.dart';
import 'package:team_info_app/screens/profile/certifications_screen.dart';

import 'package:team_info_app/core/enums/user_role.dart';
import 'package:team_info_app/screens/profile/college_sync_screen.dart';
import 'package:team_info_app/providers/system_config_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _api = ApiService();
  String? _lastPortalSyncedAt;
  String? _lastPortalDeltaText;

  Future<void> _editPoints({
    required String fieldKey,
    required String label,
    required int currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update $label',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                suffixText: 'pts',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final parsed = int.tryParse(controller.text.trim());
                  if (parsed == null || parsed < 0) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid number (0 or greater)'),
                      ),
                    );
                    return;
                  }

                  final res = await _api.patch(
                    ApiConstants.updateOwnPoints,
                    body: {fieldKey: parsed},
                  );

                  if (!sheetContext.mounted) return;
                  if (res.success) {
                    await ref.read(authProvider.notifier).refreshUser();
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$label updated')));
                  } else {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(res.message ?? 'Failed to update $label'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              ref.read(authProvider.notifier).refreshUser();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to exit the Command Center?',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
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
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role.displayName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Info Cards (Hide for Admin as they aren't students)
            if (user.role != UserRole.admin) ...[
              _InfoSection(
                title: 'Basic Info',
                children: [
                  if (user.regNo != null) _InfoTile('Reg No', user.regNo!),
                  if (user.department != null)
                    _InfoTile('Department', user.department!),
                  if (user.year != null) _InfoTile('Year', user.year!),
                  if (user.mobile != null) _InfoTile('Mobile', user.mobile!),
                  if (user.cgpa != null)
                    _InfoTile('CGPA', user.cgpa.toString()),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Stats
            ...[
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      'Activity Pts',
                      user.activityPoints.toString(),
                      AppColors.primary,
                      onTap: () => _editPoints(
                        fieldKey: 'activityPoints',
                        label: 'Activity Points',
                        currentValue: user.activityPoints,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      'Reward Pts',
                      user.rewardPoints.toString(),
                      AppColors.secondary,
                      onTap: () => _editPoints(
                        fieldKey: 'rewardPoints',
                        label: 'Reward Points',
                        currentValue: user.rewardPoints,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Bitsathy API Connection
            if (user.role != UserRole.admin && 
                ref.watch(systemConfigProvider).when(
                  data: (config) => config.apSyncEnabled,
                  loading: () => true,
                  error: (_, __) => true,
                )) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final syncResult = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CollegeSyncScreen(),
                      ),
                    );
                    if (!mounted) return;

                    if (syncResult is Map && syncResult['synced'] == true) {
                      final oldPoints = (syncResult['oldPoints'] as num?)
                          ?.toInt();
                      final newPoints = (syncResult['newPoints'] as num?)
                          ?.toInt();
                      final delta = (syncResult['delta'] as num?)?.toInt();
                      final syncedAt = syncResult['syncedAt']?.toString();

                      setState(() {
                        _lastPortalSyncedAt = syncedAt;
                        _lastPortalDeltaText =
                            '${oldPoints ?? '-'} -> ${newPoints ?? '-'} (${delta != null && delta >= 0 ? '+' : ''}${delta ?? 0})';
                      });

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Activity Points: ${_lastPortalDeltaText ?? 'Synced'}',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync College Portal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.primary.withAlpha(50)),
                    ),
                  ),
                ),
              ),
              if (_lastPortalDeltaText != null || _lastPortalSyncedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_lastPortalDeltaText != null)
                        Text(
                          'Activity Points: $_lastPortalDeltaText',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      if (_lastPortalSyncedAt != null)
                        Text(
                          'Last Synced: $_lastPortalSyncedAt',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Skills Portfolio
            _InfoSection(
              title: 'Skills Portfolio',
              children: [
                _buildSkillsPreview(context, user),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SkillsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Skills'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CertificationsScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                        ),
                        label: const Text('Certs'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Social Links (Hide for Admin)
            if (user.role != UserRole.admin && _hasSocialLinks(user)) ...[
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Social Links',
                children: [
                  if (user.githubUrl != null)
                    _LinkTile('GitHub', user.githubUrl!, Icons.code),
                  if (user.linkedinUrl != null)
                    _LinkTile('LinkedIn', user.linkedinUrl!, Icons.work),
                  if (user.leetcodeUrl != null)
                    _LinkTile('LeetCode', user.leetcodeUrl!, Icons.terminal),
                  if (user.twitterUrl != null)
                    _LinkTile('Twitter', user.twitterUrl!, Icons.chat),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasSocialLinks(UserModel user) =>
      user.githubUrl != null ||
      user.linkedinUrl != null ||
      user.leetcodeUrl != null ||
      user.twitterUrl != null;

  Widget _buildSkillsPreview(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.primarySkills.isNotEmpty)
          _SkillRow('Primary', user.primarySkills, AppColors.primary),
        if (user.secondarySkills.isNotEmpty)
          _SkillRow('Secondary', user.secondarySkills, AppColors.secondary),
        if (user.specialSkills.isNotEmpty)
          _SkillRow('Special', user.specialSkills, AppColors.accent),
        if (user.programmingLangs.isNotEmpty)
          _SkillRow('Langs', user.programmingLangs, AppColors.warning),
      ],
    );
  }
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
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final VoidCallback? onTap;
  const _StatChip(this.label, this.value, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (onTap != null)
              Text(
                'Tap to edit',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
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
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(50)),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
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
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary),
            ),
            const Spacer(),
            const Icon(Icons.open_in_new, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
