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
import 'package:team_info_app/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final TeamProject project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  late TeamProject _currentProject;
  List<ProjectMilestone> _milestones = [];
  List<ProjectUpdate> _updates = [];
  bool _loadingMilestones = true;
  bool _loadingUpdates = true;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadProjectDetails();
    _loadMilestones();
    _loadUpdates();
  }

  Future<void> _loadProjectDetails() async {
    final res = await ApiService().get('${ApiConstants.teamProjects}/${_currentProject.id}');
    if (res.success && mounted) {
      setState(() {
        _currentProject = TeamProject.fromJson(res.data);
      });
    }
  }

  Future<void> _loadMilestones() async {
    final repo = ref.read(appDataRepositoryProvider);
    final milestones = await repo.getMilestones(_currentProject.id);
    if (mounted) {
      setState(() {
        _milestones = milestones;
        _loadingMilestones = false;
      });
    }
  }

  Future<void> _loadUpdates() async {
    final res = await ApiService().get('${ApiConstants.projectUpdates}/${_currentProject.id}');
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Strike Team', Icons.groups_rounded),
                      if (_isCaptainOrAdmin())
                        TextButton.icon(
                          onPressed: _showManageMembersDialog,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Manage'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMembersList(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Recent Activity', Icons.history_rounded),
                      if (_isMemberOrAdmin())
                        TextButton.icon(
                          onPressed: () => _showUpdateDialog(),
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
    final isCaptain = _currentProject.assignedCaptain?['id'] == user?.id;
    final isMember = _currentProject.members.any((m) => m.userId == user?.id);
    return isCaptain || isMember;
  }

  bool _isCaptainOrAdmin() {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    if (user.role == UserRole.admin) return true;
    return _currentProject.assignedCaptain?['id'] == user.id;
  }

  Future<void> _showEditMissionDialog() async {
    final problemC = TextEditingController(text: _currentProject.problemStatement ?? '');
    final solutionC = TextEditingController(text: _currentProject.solution ?? '');
    String status = _currentProject.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Mission Briefing', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              const Text('Project Status', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: AppColors.surfaceLight,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceLight.withAlpha(50),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                ),
                style: const TextStyle(color: Colors.white),
                items: ['NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'ON_HOLD']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setModalState(() => status = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: problemC,
                decoration: const InputDecoration(hintText: 'Problem Statement'),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: solutionC,
                decoration: const InputDecoration(hintText: 'Proposed Solution'),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await ApiService().put('${ApiConstants.teamProjects}/${_currentProject.id}', body: {
                      'status': status,
                      'problemStatement': problemC.text,
                      'solution': solutionC.text,
                    });
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadProjectDetails();
                    }
                  },
                  child: const Text('Save Mission Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showManageMembersDialog() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await ApiService().get(ApiConstants.users);
    if (mounted && context.mounted) {
      Navigator.pop(context);
    }
    if (!mounted || !context.mounted) return;
    if (!res.success) return;

    final allUsers = (res.data as List).map((e) => UserModel.fromJson(e)).toList();
    List<String> selectedMemberIds = _currentProject.members.map((m) => m.userId).toList();

    if (!mounted || !context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          height: MediaQuery.of(modalContext).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage Strike Team', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final u = allUsers[index];
                    final isCaptain = u.id == _currentProject.assignedCaptain?['id'];
                    return CheckboxListTile(
                      value: selectedMemberIds.contains(u.id) || isCaptain,
                      title: Text(u.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(u.email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      activeColor: AppColors.primary,
                      enabled: !isCaptain,
                      onChanged: isCaptain ? null : (checked) {
                        setModalState(() {
                          if (checked == true) {
                            selectedMemberIds.add(u.id);
                          } else {
                            selectedMemberIds.remove(u.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await ApiService().post('${ApiConstants.teamProjects}/${_currentProject.id}/members', body: {
                      'memberIds': selectedMemberIds,
                    });
                    if (!context.mounted) return;
                    if (res.success && modalContext.mounted) {
                      Navigator.pop(modalContext);
                      _loadProjectDetails();
                    }
                  },
                  child: const Text('Save Team Sync'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog({ProjectUpdate? update}) {
    final isEdit = update != null;
    final titleC = TextEditingController(text: update?.title ?? '');
    final descC = TextEditingController(text: update?.description ?? '');
    DateTime selectedDate = update?.date != null ? DateTime.parse(update!.date!) : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                isEdit ? 'Edit Progress Update' : 'Post Progress Update',
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
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: AppColors.surface,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${selectedDate.toString().split(' ')[0]}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleC.text.isEmpty) return;
                    
                    final body = {
                      'title': titleC.text,
                      'description': descC.text,
                      'date': selectedDate.toIso8601String(),
                    };
                    
                    final res = isEdit
                      ? await ApiService().put('${ApiConstants.projectUpdates}/${update.id}', body: body)
                      : await ApiService().post('${ApiConstants.projectUpdates}/${_currentProject.id}', body: body);
                      
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadUpdates();
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Post Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUpdate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Update', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this update?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiService().delete('${ApiConstants.projectUpdates}/$id');
      if (res.success) _loadUpdates();
    }
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

    final currentUser = ref.read(authProvider).user;
    
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
                  (update.date ?? update.createdAt)?.split('T')[0] ?? '',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                ),
                if (currentUser?.id == update.userId || currentUser?.role == UserRole.admin)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 16),
                    padding: EdgeInsets.zero,
                    color: AppColors.surface,
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.primary))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _showUpdateDialog(update: update);
                      if (v == 'delete') _deleteUpdate(update.id);
                    },
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
          _currentProject.projectName,
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
              _StatusBadge(status: _currentProject.status),
              const Spacer(),
              Text(
                'Started ${_currentProject.startDate?.split('T')[0] ?? 'N/A'}',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Mission Briefing',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              if (_isCaptainOrAdmin()) ...[
                const Spacer(),
                InkWell(
                  onTap: _showEditMissionDialog,
                  child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentProject.problemStatement ?? 'No description provided.',
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
    final captainId = _currentProject.assignedCaptain?['id']?.toString();

    return Column(
      children: _currentProject.members
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
