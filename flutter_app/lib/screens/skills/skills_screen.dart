import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/core/services/excel_export_service.dart';
import 'package:team_info_app/core/widgets/export_selection_dialog.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/enums/user_role.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/app_models.dart'; 
import 'package:team_info_app/core/theme/app_theme.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  final UserModel? targetUser; // If null, manage own skills
  const SkillsScreen({super.key, this.targetUser});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final _excelService = ExcelExportService();
  List<PsSkill> _skills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final url = widget.targetUser != null
        ? '${ApiConstants.psSkills}/user/${widget.targetUser!.id}'
        : ApiConstants.psSkills;

    final res = await ref.read(apiServiceProvider).get(url);
    if (res.success && mounted) {
      setState(() {
        _skills = (res.data as List).map((e) => PsSkill.fromJson(e)).toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.targetUser == null;
    final title = isMe
        ? 'Skills Portfolio'
        : '${widget.targetUser!.name.split(' ').first}\'s Skills';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _handleExport(),
            tooltip: 'Export Skills',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () => _showAddSkillDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Skill Card'),
            backgroundColor: AppColors.primary,
          ).animate().scale(
            delay: 500.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _skills.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _loadSkills,
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: _skills.length,
                itemBuilder: (_, i) =>
                    _SkillCard(
                          skill: _skills[i],
                          onDelete: () => _deleteSkill(_skills[i].id),
                          onEdit: () => _showEditSkillDialog(_skills[i]),
                          onTap: () async {
                            final res = await ref.read(apiServiceProvider).put(
                              '${ApiConstants.psSkills}/${_skills[i].id}',
                              body: {'completed': !_skills[i].completed},
                            );
                            if (res.success) _loadSkills();
                          },
                        )
                        .animate()
                        .fade(delay: (i * 50).ms, duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
              ),
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
          title: 'Export Skills',
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
        endpoint: ApiConstants.exportSkills,
        filename: 'SkillsPortfolio_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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

  Widget _emptyState() {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt_outlined,
                    size: 80,
                    color: AppColors.textMuted.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Skills Added',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Build your dynamic portfolio now!',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ],
              )
              .animate()
              .fade(duration: 600.ms)
              .scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  void _showAddSkillDialog() {
    final nameC = TextEditingController();
    String type = 'TECHNICAL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Skill Card',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  hintText: 'Skill Name (e.g. Flutter, UX Design)',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'TECHNICAL',
                    current: type,
                    onTap: () => setModalState(() => type = 'TECHNICAL'),
                  ),
                  const SizedBox(width: 10),
                  _TypeChip(
                    label: 'NON_TECHNICAL',
                    current: type,
                    onTap: () => setModalState(() => type = 'NON_TECHNICAL'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameC.text.isEmpty) return;
                    final res = await ref.read(apiServiceProvider).post(
                      ApiConstants.psSkills,
                      body: {
                        'skillName': nameC.text,
                        'type': type,
                        if (widget.targetUser != null)
                          'userId': widget.targetUser!.id,
                      },
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadSkills();
                    }
                  },
                  child: const Text('Add Card'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSkillDialog(PsSkill skill) {
    final nameC = TextEditingController(text: skill.skillName);
    String type = skill.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Skill Card',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  hintText: 'Skill Name (e.g. Flutter, UX Design)',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'TECHNICAL',
                    current: type,
                    onTap: () => setModalState(() => type = 'TECHNICAL'),
                  ),
                  const SizedBox(width: 10),
                  _TypeChip(
                    label: 'NON_TECHNICAL',
                    current: type,
                    onTap: () => setModalState(() => type = 'NON_TECHNICAL'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameC.text.isEmpty) return;
                    final res = await ref.read(apiServiceProvider).put(
                      '${ApiConstants.psSkills}/${skill.id}',
                      body: {
                        'skillName': nameC.text,
                        'type': type,
                      },
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadSkills();
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSkill(String id) async {
    final res = await ref.read(apiServiceProvider).delete('${ApiConstants.psSkills}/$id');
    if (res.success) _loadSkills();
  }
}

class _TypeChip extends StatelessWidget {
  final String label, current;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = label == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(40)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label.replaceAll('_', ' '),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final PsSkill skill;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _SkillCard({
    required this.skill,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTech = skill.type == 'TECHNICAL';
    final color = isTech ? AppColors.primary : AppColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: skill.completed ? AppColors.success : color.withAlpha(50),
          ),
          boxShadow: [
            if (skill.completed)
              BoxShadow(
                color: AppColors.success.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTech ? 'TECH' : 'SOFT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    if (skill.completed)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    skill.skillName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: -10,
              right: -10,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
