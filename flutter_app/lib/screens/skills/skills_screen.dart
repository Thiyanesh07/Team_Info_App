import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/core/services/excel_export_service.dart';
import 'package:team_info_app/core/widgets/export_selection_dialog.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/screens/shared/member_data_view_screen.dart';
import 'package:team_info_app/core/enums/user_role.dart';

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
    final currentUser = ref.watch(authProvider).user;
    final canViewOthers = currentUser != null && currentUser.role.canViewAllData;
    final title = isMe
        ? 'P Skills Portfolio'
        : '${widget.targetUser!.name.split(' ').first}\'s P Skills';

    final techSkills = _skills.where((s) => s.type == 'TECHNICAL').toList();
    final nonTechSkills = _skills.where((s) => s.type == 'NON_TECHNICAL').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (isMe && canViewOthers)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemberDataViewScreen(
                      dataType: MemberDataType.skills,
                    ),
                  ),
                );
              },
              tooltip: 'View Member Skills',
            ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _handleExport(),
            tooltip: 'Export Skills',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: (isMe || (currentUser?.role == UserRole.admin))
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSkillDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Assessment'),
              backgroundColor: AppColors.primary,
            ).animate().scale(
              delay: 500.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _skills.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadSkills,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (techSkills.isNotEmpty) ...[
                        _sectionHeader('Technical Skills', AppColors.primary),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: techSkills.length,
                          itemBuilder: (_, i) => _SkillCard(
                            skill: techSkills[i],
                            onDelete: () => _deleteSkill(techSkills[i].id),
                            onEdit: () => _showEditSkillDialog(techSkills[i]),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (nonTechSkills.isNotEmpty) ...[
                        _sectionHeader('Non-Technical Skills', AppColors.secondary),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: nonTechSkills.length,
                          itemBuilder: (_, i) => _SkillCard(
                            skill: nonTechSkills[i],
                            onDelete: () => _deleteSkill(nonTechSkills[i].id),
                            onEdit: () => _showEditSkillDialog(nonTechSkills[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _handleExport() {
    if (ref.read(authProvider).user == null) return;

    showDialog(
      context: context,
      builder: (_) => ExportSelectionDialog(
        title: 'Export P-Skills',
        onExport: (scope, selectedUserId, timeline, startDate, endDate) async {
          await _runExport(
            scope: scope,
            userId: selectedUserId,
            timeline: timeline,
            startDate: startDate,
            endDate: endDate,
          );
        },
      ),
    );
  }

  Future<void> _runExport({
    required String scope,
    String? userId,
    ExportTimeline timeline = ExportTimeline.today,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing Excel report...')),
      );

      await _excelService.downloadAndOpenReport(
        endpoint: ApiConstants.exportSkills,
        filename: 'PSkillsReport_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        queryParams: {
          'scope': scope,
          if (userId != null) 'userId': userId,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: AppColors.textMuted.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            'No Assessments Added',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your college P Skill results here.',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ],
      ).animate().fade(duration: 600.ms).scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  void _showAddSkillDialog() {
    final nameC = TextEditingController();
    final levelC = TextEditingController();
    DateTime selectedDate = DateTime.now();
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
                'Add P-Skill Assessment',
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
                  labelText: 'Assessment Name',
                  hintText: 'e.g. Python Foundation, Aptitude',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelC,
                decoration: const InputDecoration(
                  labelText: 'Level Achieved',
                  hintText: 'e.g. A Grade, 85%, Expert',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Type', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          dropdownColor: AppColors.cardDark,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TECHNICAL', child: Text('Technical')),
                            DropdownMenuItem(value: 'NON_TECHNICAL', child: Text('Non-Technical')),
                          ],
                          onChanged: (v) => setModalState(() => type = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Completed Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(primary: AppColors.primary),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setModalState(() => selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            'level': levelC.text,
                            'completedDate': selectedDate.toIso8601String(),
                            if (widget.targetUser != null) 'userId': widget.targetUser!.id,
                          },
                        );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadSkills();
                    }
                  },
                  child: const Text('Save Assessment'),
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
    final levelC = TextEditingController(text: skill.level);
    DateTime selectedDate = skill.completedDate != null ? DateTime.parse(skill.completedDate!) : DateTime.now();
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
                'Edit Assessment',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Assessment Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelC,
                decoration: const InputDecoration(labelText: 'Level Achieved'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Type', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          dropdownColor: AppColors.cardDark,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TECHNICAL', child: Text('Technical')),
                            DropdownMenuItem(value: 'NON_TECHNICAL', child: Text('Non-Technical')),
                          ],
                          onChanged: (v) => setModalState(() => type = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Completed Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setModalState(() => selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            'level': levelC.text,
                            'completedDate': selectedDate.toIso8601String(),
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



class _SkillCard extends StatelessWidget {
  final PsSkill skill;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SkillCard({
    required this.skill,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isTech = skill.type == 'TECHNICAL';
    final color = isTech ? AppColors.primary : AppColors.secondary;
    
    // Parse date
    String dateStr = 'N/A';
    if (skill.completedDate != null) {
      try {
        final d = DateTime.parse(skill.completedDate!);
        dateStr = "${d.day}/${d.month}/${d.year}";
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isTech ? 'TECH' : 'SOFT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.white60),
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                skill.skillName,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              _cardDetail(Icons.bar_chart_rounded, skill.level ?? 'No Level', color),
              const SizedBox(height: 2),
              _cardDetail(Icons.history_toggle_off_rounded, dateStr, color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardDetail(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withAlpha(200)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
