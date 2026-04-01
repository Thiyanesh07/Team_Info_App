import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:team_info_app/screens/projects/project_detail_screen.dart';
import 'package:team_info_app/core/enums/user_role.dart';
import 'package:team_info_app/core/services/excel_export_service.dart';
import 'package:team_info_app/core/widgets/export_selection_dialog.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _excelService = ExcelExportService();
  late TabController _tabController;
  List<PersonalProject> _personalProjects = [];
  List<TeamProject> _teamProjects = [];
  List<dynamic> _allUsers = [];
  bool _loadingPersonal = true, _loadingTeam = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadPersonalProjects();
    _loadTeamProjects();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final res = await _api.get(ApiConstants.users);
    if (res.success && mounted) {
      setState(() => _allUsers = res.data as List);
    }
  }

  Future<void> _loadPersonalProjects() async {
    final repo = ref.read(appDataRepositoryProvider);
    final projects = await repo.getPersonalProjects();
    if (mounted) {
      setState(() {
        _personalProjects = projects;
        _loadingPersonal = false;
      });
    }
  }

  Future<void> _loadTeamProjects() async {
    final repo = ref.read(appDataRepositoryProvider);
    final projects = await repo.getTeamProjects();
    if (mounted) {
      setState(() {
        _teamProjects = projects;
        _loadingTeam = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Projects',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _handleExport(),
            tooltip: 'Export Team Projects',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Team'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_project_fab',
        onPressed: () => _showAddDialog(context, user),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPersonalTab(), _buildTeamTab()],
      ),
    );
  }

  Widget _buildPersonalTab() {
    if (_loadingPersonal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_personalProjects.isEmpty) {
      return _emptyState('No personal projects yet', 'Add your first project!');
    }

    return RefreshIndicator(
      onRefresh: _loadPersonalProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _personalProjects.length,
        itemBuilder: (_, i) =>
            _PersonalProjectCard(
                  project: _personalProjects[i],
                  onDelete: () => _deletePersonalProject(_personalProjects[i].id),
                  onEdit: () => _showEditPersonalProjectDialog(_personalProjects[i]),
                )
                .animate()
                .fade(duration: 400.ms, delay: (i * 100).ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  void _handleExport() {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final isLeader = [UserRole.admin, UserRole.captain, UserRole.viceCaptain, UserRole.strategist, UserRole.manager]
        .contains(user.role);

    if (isLeader) {
      showDialog(
        context: context,
        builder: (_) => ExportSelectionDialog(
          title: 'Export Team Projects',
          onExport: (scope, selectedUserId) async {
            await _runExport(scope: scope, userId: selectedUserId);
          },
        ),
      );
    } else {
      _runExport(scope: 'SELF');
    }
  }

  Future<void> _runExport({required String scope, String? userId}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing Excel report...')),
      );

      await _excelService.downloadAndOpenReport(
        endpoint: ApiConstants.exportProjects,
        filename: 'TeamProjects_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        queryParams: {
          'scope': scope,
          if (userId != null) 'userId': userId,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildTeamTab() {
    if (_loadingTeam) return const Center(child: CircularProgressIndicator());
    if (_teamProjects.isEmpty) {
      return _emptyState(
        'No team projects',
        'Create or get assigned to a project',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeamProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _teamProjects.length,
        itemBuilder: (_, i) {
          final user = ref.read(authProvider).user;
          final isCreator = _teamProjects[i].createdBy?['id'] == user?.id;
          final isAdmin = user?.role == UserRole.admin;
          return _TeamProjectCard(
                project: _teamProjects[i],
                onDelete: (isCreator || isAdmin) ? () => _deleteTeamProject(_teamProjects[i].id) : null,
                onEdit: (isCreator || isAdmin) ? () => _showEditTeamProjectDialog(_teamProjects[i]) : null,
              )
              .animate()
              .fade(duration: 400.ms, delay: (i * 100).ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: AppColors.textMuted.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: -5,
                end: 5,
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
    );
  }

  void _showAddDialog(BuildContext context, dynamic user) {
    final isPersonalTab = _tabController.index == 0;
    if (isPersonalTab) {
      _showAddPersonalProjectDialog(context);
    } else if (user != null && user.role.canCreateTeamProject) {
      _showAddTeamProjectDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only leaders can create team projects')),
      );
    }
  }

  void _showAddPersonalProjectDialog(BuildContext context) {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final githubC = TextEditingController();
    final liveC = TextEditingController();

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
              'Add Personal Project',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(hintText: 'Project Name *'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descC,
              decoration: const InputDecoration(hintText: 'Description'),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: githubC,
              decoration: const InputDecoration(hintText: 'GitHub Link'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: liveC,
              decoration: const InputDecoration(hintText: 'Live Link'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameC.text.isEmpty) return;
                  final body = {
                    'name': nameC.text,
                    'description': descC.text,
                    'githubLink': githubC.text,
                    'liveLink': liveC.text,
                  };
                  final res = await _api.post(ApiConstants.personalProjects, body: body);
                  if (!context.mounted) return;
                  if (res.success) {
                    Navigator.pop(context);
                    if (mounted) _loadPersonalProjects();
                  }
                },
                child: const Text('Create Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPersonalProjectDialog(PersonalProject project) {
    final nameC = TextEditingController(text: project.name);
    final descC = TextEditingController(text: project.description);
    final githubC = TextEditingController(text: project.githubLink);
    final liveC = TextEditingController(text: project.liveLink);

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
              'Edit Personal Project',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(hintText: 'Project Name *'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descC,
              decoration: const InputDecoration(hintText: 'Description'),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: githubC,
              decoration: const InputDecoration(hintText: 'GitHub Link'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: liveC,
              decoration: const InputDecoration(hintText: 'Live Link'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameC.text.isEmpty) return;
                  final body = {
                    'name': nameC.text,
                    'description': descC.text,
                    'githubLink': githubC.text,
                    'liveLink': liveC.text,
                  };
                  final res = await _api.put('${ApiConstants.personalProjects}/${project.id}', body: body);
                  if (!mounted) return;
                  if (res.success && context.mounted) {
                    Navigator.pop(context);
                    if (mounted) _loadPersonalProjects();
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTeamProjectDialog(BuildContext context) {
    if (_allUsers.isEmpty) _loadUsers();
    final nameC = TextEditingController();
    final domainC = TextEditingController();
    final problemC = TextEditingController();
    String? selectedCaptainId;
    List<String> selectedMemberIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Team Project',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(hintText: 'Project Name *'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainC,
                  decoration: const InputDecoration(hintText: 'Domain'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: problemC,
                  decoration: const InputDecoration(hintText: 'Problem Statement'),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Text('Assigned Captain', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCaptainId,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      hint: const Text('Select captain', style: TextStyle(color: AppColors.textMuted)),
                      items: _allUsers.map((u) => DropdownMenuItem(
                        value: u['id'] as String,
                        child: Text(u['name'], style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedCaptainId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Team Members', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allUsers.map((u) {
                    final isSelected = selectedMemberIds.contains(u['id']);
                    return FilterChip(
                      label: Text(u['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                      selected: isSelected,
                      onSelected: (val) {
                        setModalState(() {
                          if (val) {
                            selectedMemberIds.add(u['id']);
                          } else {
                            selectedMemberIds.remove(u['id']);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withAlpha(100),
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameC.text.isEmpty) return;
                      final res = await _api.post(
                        ApiConstants.teamProjects,
                        body: {
                          'projectName': nameC.text,
                          'domain': domainC.text,
                          'problemStatement': problemC.text,
                          'assignedCaptainId': selectedCaptainId,
                          'memberIds': selectedMemberIds,
                        },
                      );
                      if (!context.mounted) return;
                      if (res.success) {
                        Navigator.pop(context);
                        if (mounted) _loadTeamProjects();
                      }
                    },
                    child: const Text('Create Project'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTeamProjectDialog(TeamProject project) {
    final nameC = TextEditingController(text: project.projectName);
    final domainC = TextEditingController(text: project.domain);
    final problemC = TextEditingController(text: project.problemStatement);
    String? selectedCaptainId = project.assignedCaptain?['id'];
    List<String> selectedMemberIds = project.members.map((m) => m.userId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Team Project',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(hintText: 'Project Name *'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainC,
                  decoration: const InputDecoration(hintText: 'Domain'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: problemC,
                  decoration: const InputDecoration(hintText: 'Problem Statement'),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Text('Assigned Captain', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCaptainId,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      hint: const Text('Select captain', style: TextStyle(color: AppColors.textMuted)),
                      items: _allUsers.map((u) => DropdownMenuItem(
                        value: u['id'] as String,
                        child: Text(u['name'], style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedCaptainId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Team Members', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allUsers.map((u) {
                    final isSelected = selectedMemberIds.contains(u['id']);
                    return FilterChip(
                      label: Text(u['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                      selected: isSelected,
                      onSelected: (val) {
                        setModalState(() {
                          if (val) {
                            selectedMemberIds.add(u['id']);
                          } else {
                            selectedMemberIds.remove(u['id']);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withAlpha(100),
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameC.text.isEmpty) return;
                      final res = await _api.put(
                        '${ApiConstants.teamProjects}/${project.id}',
                        body: {
                          'projectName': nameC.text,
                          'domain': domainC.text,
                          'problemStatement': problemC.text,
                          'assignedCaptainId': selectedCaptainId,
                          'memberIds': selectedMemberIds,
                        },
                      );
                      if (!context.mounted) return;
                      if (res.success) {
                        Navigator.pop(context);
                        if (mounted) _loadTeamProjects();
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTeamProject(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Project', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this team project?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _api.delete('${ApiConstants.teamProjects}/$id');
      if (res.success) _loadTeamProjects();
    }
  }

  Future<void> _deletePersonalProject(String id) async {
    final res = await _api.delete('${ApiConstants.personalProjects}/$id');
    if (res.success) _loadPersonalProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _PersonalProjectCard extends StatelessWidget {
  final PersonalProject project;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _PersonalProjectCard({
    required this.project,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.code,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                color: AppColors.surface,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      'Edit',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
          if (project.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              project.description!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
            ),
          ],
          if (project.skillsUsed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: project.skillsUsed
                  .map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamProjectCard extends StatelessWidget {
  final TeamProject project;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  const _TeamProjectCard({required this.project, this.onDelete, this.onEdit});

  Color get _statusColor {
    switch (project.status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'ON_HOLD':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  double get _progressValue {
    switch (project.status) {
      case 'COMPLETED':
        return 1.0;
      case 'IN_PROGRESS':
        return 0.6;
      case 'ON_HOLD':
        return 0.3;
      default:
        return 0.1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 4,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _statusColor.withAlpha(100),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.groups,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.projectName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (project.domain != null)
                                Text(
                                  project.domain!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            project.status.replaceAll('_', ' '),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            color: AppColors.surface,
                            itemBuilder: (_) => [
                              if (onEdit != null)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                              if (onDelete != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                            ],
                            onSelected: (v) {
                              if (v == 'edit') onEdit!();
                              if (v == 'delete') onDelete!();
                            },
                          ),
                      ],
                    ),
                    if (project.members.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${project.members.length} member${project.members.length > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
