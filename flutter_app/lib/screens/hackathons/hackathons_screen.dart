import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:team_info_app/core/services/excel_export_service.dart';
import 'package:team_info_app/core/widgets/export_selection_dialog.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/enums/user_role.dart';
import 'package:team_info_app/widgets/empty_states.dart';

class HackathonsScreen extends ConsumerStatefulWidget {
  const HackathonsScreen({super.key});
  @override
  ConsumerState<HackathonsScreen> createState() => _HackathonsScreenState();
}

class _HackathonsScreenState extends ConsumerState<HackathonsScreen> {
  final _api = ApiService();
  final _excelService = ExcelExportService();
  List<Hackathon> _hackathons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHackathons();
  }

  Future<void> _loadHackathons() async {
    final res = await _api.get(ApiConstants.hackathons);
    if (res.success && mounted) {
      setState(() {
        _hackathons = (res.data as List)
            .map((e) => Hackathon.fromJson(e))
            .toList();
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
          'Hackathons',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _handleExport(),
            tooltip: 'Export Hackathons',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHackathonDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Hackathon'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hackathons.isEmpty
          ? EmptyHackathons(onAction: () => _showHackathonDialog(context))
          : RefreshIndicator(
              onRefresh: _loadHackathons,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _hackathons.length,
                itemBuilder: (_, i) =>
                    _HackathonCard(
                          hackathon: _hackathons[i],
                          onRefresh: _loadHackathons,
                          onEdit: (h) => _showHackathonDialog(context, hackathon: h),
                          onDelete: _deleteHackathon,
                        )
                        .animate()
                        .fade(delay: (i * 100).ms, duration: 400.ms)
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
          title: 'Export Hackathons',
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
        endpoint: ApiConstants.exportHackathons,
        filename: 'Hackathons_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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

  // _emptyState() removed in favor of bespoke widgets/empty_states.dart

  void _showHackathonDialog(BuildContext context, {Hackathon? hackathon}) {
    final isEdit = hackathon != null;
    final nameC = TextEditingController(text: hackathon?.hackName);
    final projectC = TextEditingController(text: hackathon?.projectName);
    final descC = TextEditingController(text: hackathon?.description);
    final contributionC = TextEditingController(text: hackathon?.contribution);
    final skillC = TextEditingController();
    final teamMemberC = TextEditingController();
    
    DateTime selectedDate = hackathon?.date != null ? DateTime.parse(hackathon!.date!) : DateTime.now();
    bool isTeam = hackathon?.isTeam ?? false;
    String status = hackathon?.status ?? 'UPCOMING';
    List<String> skills = hackathon != null ? List.from(hackathon.skillsUsed) : [];
    List<String> teamMembers = hackathon != null ? List.from(hackathon.teamMembers) : [];
    
    List<Map<String, String>> rounds = hackathon != null && hackathon.rounds.isNotEmpty
        ? hackathon.rounds.map((r) => { 'roundName': r.roundName, 'description': r.description ?? '' }).toList()
        : [{ 'roundName': 'Round 1', 'description': '' }];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (stc, setModalState) => GestureDetector(
          onTap: () => FocusScope.of(stc).unfocus(),
          child: Container(
            height: MediaQuery.of(stc).size.height * 0.85,
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(stc).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(isEdit ? 'Edit Achievement' : 'Log Competition', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 24),
                  
                  _sectionTitle('Basic Information'),
                  _textField(nameC, 'Hackathon Name *', Icons.emoji_events_outlined),
                  const SizedBox(height: 12),
                  _textField(projectC, 'Project / Product Name', Icons.rocket_launch_outlined),
                  const SizedBox(height: 12),
                  _textField(descC, 'Short Description', Icons.description_outlined, maxLines: 2),
                  const SizedBox(height: 12),
                  _textField(contributionC, 'Your Contribution', Icons.handyman_outlined, maxLines: 2),
                  const SizedBox(height: 12),

                  // Date & Status
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: stc, initialDate: selectedDate,
                              firstDate: DateTime(2020), lastDate: DateTime(2030),
                            );
                            if (d != null) setModalState(() => selectedDate = d);
                          },
                          child: _fakeField(DateFormat('dd MMM yyyy').format(selectedDate), Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdownField(
                          value: status,
                          items: ['UPCOMING', 'COMPLETED', 'PARTICIPATED', 'WINNER'],
                          onChanged: (v) => setModalState(() => status = v!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle('Participation Type'),
                  Row(
                    children: [
                      _choiceChip('Solo', !isTeam, () => setModalState(() => isTeam = false)),
                      const SizedBox(width: 12),
                      _choiceChip('Team', isTeam, () => setModalState(() => isTeam = true)),
                    ],
                  ),

                  if (isTeam) ...[
                    const SizedBox(height: 16),
                    _tagInput(
                      controller: teamMemberC,
                      hint: 'Team Member Name',
                      tags: teamMembers,
                      onAdd: (val) => setModalState(() => teamMembers.add(val)),
                      onRemove: (idx) => setModalState(() => teamMembers.removeAt(idx)),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _sectionTitle('Skills Used'),
                  _tagInput(
                    controller: skillC,
                    hint: 'e.g. Flutter, Node.js',
                    tags: skills,
                    onAdd: (val) => setModalState(() => skills.add(val)),
                    onRemove: (idx) => setModalState(() => skills.removeAt(idx)),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Competition Rounds'),
                      TextButton.icon(
                        onPressed: () => setModalState(() => rounds.add({'roundName': 'Round ${rounds.length + 1}', 'description': ''})),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add Round'),
                      ),
                    ],
                  ),
                  ...rounds.asMap().entries.map((entry) {
                    int idx = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              children: [
                                _textField(TextEditingController(text: rounds[idx]['roundName'])..selection = TextSelection.fromPosition(TextPosition(offset: rounds[idx]['roundName']!.length)), 'Round Name', Icons.label_important_outline, 
                                  onChanged: (v) => rounds[idx]['roundName'] = v),
                                const SizedBox(height: 8),
                                _textField(TextEditingController(text: rounds[idx]['description'])..selection = TextSelection.fromPosition(TextPosition(offset: rounds[idx]['description']!.length)), 'Result / Description', Icons.notes, 
                                  onChanged: (v) => rounds[idx]['description'] = v),
                              ],
                            ),
                          ),
                          if (rounds.length > 1)
                            Positioned(
                              right: 0, top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                onPressed: () => setModalState(() => rounds.removeAt(idx)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: AppColors.primary.withAlpha(100),
                      ),
                      onPressed: () async {
                        if (nameC.text.isEmpty) return;
                        final body = {
                          'hackName': nameC.text.trim(),
                          'projectName': projectC.text.trim(),
                          'description': descC.text.trim(),
                          'contribution': contributionC.text.trim(),
                          'skillsUsed': skills,
                          'date': selectedDate.toIso8601String(),
                          'isTeam': isTeam,
                          'teamMembers': teamMembers,
                          'status': status,
                          'rounds': rounds,
                        };

                        final res = isEdit 
                          ? await _api.put('${ApiConstants.hackathons}/${hackathon.id}', body: body)
                          : await _api.post(ApiConstants.hackathons, body: body);
                        
                        if (!stc.mounted) return;
                        if (res.success) {
                          Navigator.pop(stc);
                          _loadHackathons();
                        }
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Save Achievement', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteHackathon(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Log', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this competition entry?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await _api.delete('${ApiConstants.hackathons}/$id');
      if (res.success) _loadHackathons();
    }
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _fakeField(String t, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              t, 
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.cardDark,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: items.map((e) => DropdownMenuItem(
            value: e, 
            child: Text(e, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLight.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tagInput({required TextEditingController controller, required String hint, required List<String> tags, required Function(String) onAdd, required Function(int) onRemove}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {
                if (controller.text.isEmpty) return;
                onAdd(controller.text.trim());
                controller.clear();
              },
            ),
          ),
          onSubmitted: (v) {
             if (v.isEmpty) return;
             onAdd(v.trim());
             controller.clear();
          },
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: tags.asMap().entries.map((e) => Chip(
              label: Text(e.value, style: const TextStyle(fontSize: 12, color: Colors.white)),
              backgroundColor: AppColors.primary.withAlpha(50),
              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
              onDeleted: () => onRemove(e.key),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _textField(TextEditingController c, String hint, IconData icon, {int maxLines = 1, Function(String)? onChanged}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceLight.withAlpha(50),
      ),
    );
  }
}

class _HackathonCard extends StatelessWidget {
  final Hackathon hackathon;
  final VoidCallback onRefresh;
  final Function(Hackathon) onEdit;
  final Function(String) onDelete;

  const _HackathonCard({
    required this.hackathon, 
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetails = hackathon.description != null || 
                       hackathon.contribution != null || 
                       hackathon.skillsUsed.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP SECTION: HEADER & ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hackathon.hackName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (hackathon.projectName != null && hackathon.projectName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              hackathon.projectName!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _statusBadge(hackathon.status),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                    color: AppColors.cardDark,
                    onSelected: (val) {
                      if (val == 'edit') onEdit(hackathon);
                      if (val == 'delete') onDelete(hackathon.id);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                ],
              ),
            ),

            if (hasDetails) ...[
              // DESCRIPTION & CONTRIBUTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hackathon.description != null && hackathon.description!.isNotEmpty)
                      Text(
                        hackathon.description!,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                    if (hackathon.contribution != null && hackathon.contribution!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.handyman_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Contribution: ${hackathon.contribution}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // SKILLS USED
              if (hackathon.skillsUsed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: hackathon.skillsUsed.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // BOTTOM BAR: TEAM, DATE, ROUNDS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(20),
              ),
              child: Row(
                children: [
                   _infoRow(Icons.calendar_month_outlined, _formatDate(hackathon.date)),
                   const Spacer(),
                   if (hackathon.isTeam)
                      _infoRow(Icons.groups_outlined, '${hackathon.teamMembers.length + 1} members'),
                   if (hackathon.rounds.isNotEmpty) ...[
                      if (hackathon.isTeam) const SizedBox(width: 12),
                      _infoRow(Icons.layers_outlined, '${hackathon.rounds.length} rounds'),
                   ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'WINNER': color = AppColors.success; break;
      case 'PARTICIPATED': color = AppColors.primary; break;
      case 'COMPLETED': color = AppColors.accent; break;
      default: color = AppColors.warning;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
