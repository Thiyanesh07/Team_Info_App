import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:team_info_app/screens/projects/widgets/milestone_timeline.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/enums/user_role.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final TeamProject project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  List<ProjectMilestone> _milestones = [];
  List<ProjectUpdate> _updates = [];
  bool _loadingMilestones = true;
  bool _loadingUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadMilestones();
    _loadUpdates();
  }

  Future<void> _loadMilestones() async {
    final repo = ref.read(appDataRepositoryProvider);
    final milestones = await repo.getMilestones(widget.project.id);
    if (mounted) {
      setState(() {
        _milestones = milestones;
        _loadingMilestones = false;
      });
    }
  }

  Future<void> _loadUpdates() async {
    final res = await ApiService().get('${ApiConstants.teamProjects}/${widget.project.id}/progress');
    if (res.success && mounted) {
      setState(() {
        _updates = (res.data as List).map((e) => ProjectUpdate.fromJson(e)).toList();
        _loadingUpdates = false;
      });
    } else if (mounted) {
      setState(() => _loadingUpdates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Mission Objectives', Icons.flag_rounded),
                  const SizedBox(height: 16),
                  MilestoneTimeline(
                    milestones: _milestones,
                    isLoading: _loadingMilestones,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Strike Team', Icons.groups_rounded),
                  const SizedBox(height: 16),
                  _buildMembersList(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Recent Activity', Icons.history_rounded),
                      if (_isMemberOrAdmin())
                        TextButton.icon(
                          onPressed: () => _showAddUpdateDialog(),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('New Update'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUpdatesList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMemberOrAdmin() {
    final user = ref.read(authProvider).user;
    if (user?.role == UserRole.admin) return true;
    final isCaptain = widget.project.assignedCaptain?['id'] == user?.id;
    final isMember = widget.project.members.any((m) => m.userId == user?.id);
    return isCaptain || isMember;
  }

  void _showAddUpdateDialog() {
    final titleC = TextEditingController();
    final descC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post Progress Update',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleC,
              decoration: const InputDecoration(hintText: 'Update Title (e.g., Completed API integration) *'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descC,
              decoration: const InputDecoration(hintText: 'Detailed description...'),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleC.text.isEmpty) return;
                  final res = await ApiService().post(
                    '${ApiConstants.teamProjects}/${widget.project.id}/progress',
                    body: {
                      'title': titleC.text,
                      'description': descC.text,
                    },
                  );
                  if (!context.mounted) return;
                  if (res.success) {
                    Navigator.pop(context);
                    // Refresh the updates list
                    _loadUpdates();
                  }
                },
                child: const Text('Post Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesList() {
    if (_loadingUpdates) return const Center(child: CircularProgressIndicator());
    if (_updates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No progress updates yet.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _updates.map((update) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.secondary.withAlpha(30),
                  child: Text(
                    (update.user?['name'] ?? 'U')[0],
                    style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  update.user?['name'] ?? 'Unknown',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  update.createdAt?.split('T')[0] ?? '',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              update.title,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            if (update.description != null && update.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                update.description!,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.project.projectName,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withAlpha(50), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(status: widget.project.status),
              const Spacer(),
              Text(
                'Started ${widget.project.startDate?.split('T')[0] ?? 'N/A'}',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mission Briefing',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.project.problemStatement ?? 'No description provided.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    final captainId = widget.project.assignedCaptain?['id']?.toString();

    return Column(
      children: widget.project.members
          .map(
            (member) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    child: Text(
                      (member.user?['name'] ?? 'U')[0],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      member.user?['name'] ?? 'Unknown User',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (captainId != null && member.userId == captainId)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CAPTAIN',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    if (status == 'COMPLETED') color = AppColors.success;
    if (status == 'ON_HOLD') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
