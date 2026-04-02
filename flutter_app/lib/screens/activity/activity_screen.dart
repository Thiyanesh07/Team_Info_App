import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:team_info_app/core/services/excel_export_service.dart';
import 'package:team_info_app/core/widgets/export_selection_dialog.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/screens/shared/member_data_view_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});
  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _api = ApiService();
  final _excelService = ExcelExportService();
  List<DailyActivity> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final res = await _api.get(ApiConstants.activities);
    if (res.success && mounted) {
      setState(() {
        _activities = (res.data as List)
            .map((e) => DailyActivity.fromJson(e))
            .toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'LEARNING':
        return AppColors.secondary;
      case 'PROJECT':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'LEARNING':
        return Icons.school_rounded;
      case 'PROJECT':
        return Icons.code_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final canViewOthers = user != null && user.role.canViewAllData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Activities',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (canViewOthers)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemberDataViewScreen(
                      dataType: MemberDataType.activities,
                    ),
                  ),
                );
              },
              tooltip: 'View Member Logs',
            ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _handleExport,
            tooltip: 'Export Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActivityDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Activity'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _loadActivities,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: _activities.length,
                itemBuilder: (_, i) =>
                    _ActivityCard(
                          activity: _activities[i],
                          color: _typeColor(_activities[i].type),
                          icon: _typeIcon(_activities[i].type),
                          onEdit: () => _showEditActivityDialog(_activities[i]),
                          onDelete: () => _deleteActivity(_activities[i].id),
                        )
                        .animate()
                        .fade(delay: (i * 80).ms, duration: 400.ms)
                        .slideX(begin: 0.05, end: 0),
              ),
            ),
    );
  }

  void _handleExport() {
    if (ref.read(authProvider).user == null) return;

    showDialog(
      context: context,
      builder: (_) => ExportSelectionDialog(
        title: 'Export Activities',
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
        endpoint: ApiConstants.exportActivities,
        filename:
            'DailyActivities_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        queryParams: {
          'scope': scope,
          'timeline': timeline.name.toUpperCase(),
          if (startDate != null)
            'startDate': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'endDate': endDate.toIso8601String().split('T')[0],
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
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    size: 80,
                    color: AppColors.textMuted.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Activities Logged',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log your first daily action!',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ],
              )
              .animate()
              .fade(duration: 600.ms)
              .scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Future<void> _deleteActivity(String id) async {
    final res = await _api.delete('${ApiConstants.activities}/$id');
    if (res.success) _loadActivities();
  }

  void _showEditActivityDialog(DailyActivity activity) {
    String selectedType = activity.type;
    final descC = TextEditingController(text: activity.description ?? '');
    final customTypeC = TextEditingController(text: activity.customType ?? '');
    DateTime selectedDate = DateTime.tryParse(activity.date) ?? DateTime.now();
    final parsedStart = DateTime.tryParse(activity.startTime) ?? DateTime.now();
    final parsedEnd = DateTime.tryParse(activity.endTime) ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay(
      hour: parsedStart.hour,
      minute: parsedStart.minute,
    );
    TimeOfDay endTime = TimeOfDay(
      hour: parsedEnd.hour,
      minute: parsedEnd.minute,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
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
                'Edit Activity',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['LEARNING', 'PROJECT', 'OTHERS']
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: selectedType == t,
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedType = t);
                            },
                            selectedColor: _typeColor(t).withAlpha(50),
                            labelStyle: TextStyle(
                              color: selectedType == t
                                  ? _typeColor(t)
                                  : Colors.white60,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (selectedType == 'OTHERS')
                TextField(
                  controller: customTypeC,
                  decoration: const InputDecoration(
                    hintText: 'What kind of activity?',
                  ),
                ),
              if (selectedType == 'OTHERS') const SizedBox(height: 12),
              TextField(
                controller: descC,
                decoration: const InputDecoration(
                  hintText: 'What did you achieve?',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _DatePickerButton(
                label: 'Date',
                date: selectedDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Start',
                      time: startTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (t != null) setDialogState(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'End',
                      time: endTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (t != null) setDialogState(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final start = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final end = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    final res = await _api.put(
                      '${ApiConstants.activities}/${activity.id}',
                      body: {
                        'type': selectedType,
                        'customType': customTypeC.text.isNotEmpty
                            ? customTypeC.text
                            : null,
                        'description': descC.text,
                        'startTime': start.toIso8601String(),
                        'endTime': end.toIso8601String(),
                        'date': DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ).toIso8601String(),
                      },
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadActivities();
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

  void _showAddActivityDialog(BuildContext context) {
    String selectedType = 'LEARNING';
    final descC = TextEditingController();
    final customTypeC = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
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
                'Log Daily Action',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Type selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['LEARNING', 'PROJECT', 'OTHERS']
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: selectedType == t,
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedType = t);
                            },
                            selectedColor: _typeColor(t).withAlpha(50),
                            labelStyle: TextStyle(
                              color: selectedType == t
                                  ? _typeColor(t)
                                  : Colors.white60,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (selectedType == 'OTHERS')
                TextField(
                  controller: customTypeC,
                  decoration: const InputDecoration(
                    hintText: 'What kind of activity?',
                  ),
                ),
              if (selectedType == 'OTHERS') const SizedBox(height: 12),
              TextField(
                controller: descC,
                decoration: const InputDecoration(
                  hintText: 'What did you achieve?',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _DatePickerButton(
                label: 'Date',
                date: selectedDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Start',
                      time: startTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (t != null) setDialogState(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'End',
                      time: endTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (t != null) setDialogState(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final start = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final end = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    final res = await _api.post(
                      ApiConstants.activities,
                      body: {
                        'type': selectedType,
                        'customType': customTypeC.text.isNotEmpty
                            ? customTypeC.text
                            : null,
                        'description': descC.text,
                        'startTime': start.toIso8601String(),
                        'endTime': end.toIso8601String(),
                        'date': DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ).toIso8601String(),
                      },
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadActivities();
                    }
                  },
                  child: const Text('Confirm Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final DailyActivity activity;
  final Color color;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityCard({
    required this.activity,
    required this.color,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = _formatTime(activity.startTime);
    final endTime = _formatTime(activity.endTime);
    final displayTitle = _displayTitle();
    final displayDescription = _displayDescription();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: color.withAlpha(20),
                      child: Text(
                        (activity.user?['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activity.user?['name'] ?? 'Unknown User',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (displayDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayDescription,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(activity.date),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$startTime - $endTime',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayTitle() {
    // Learning logs may store the Learning record id in customType;
    // use the first "Topic: ..." line as human-friendly title.
    if (activity.type == 'LEARNING') {
      final topic = _extractTopicFromDescription();
      if (topic.isNotEmpty) return topic;
    }

    final custom = activity.customType?.trim();
    if (custom != null && custom.isNotEmpty && !_looksLikeUuid(custom)) {
      return custom;
    }
    return activity.type;
  }

  String _displayDescription() {
    final raw = activity.description?.trim() ?? '';
    if (raw.isEmpty) return '';

    if (activity.type == 'LEARNING') {
      final lines = raw.split('\n');
      if (lines.isNotEmpty && lines.first.trim().startsWith('Topic: ')) {
        return lines.skip(1).join('\n').trim();
      }
    }
    return raw;
  }

  String _extractTopicFromDescription() {
    final raw = activity.description?.trim() ?? '';
    if (raw.isEmpty) return '';
    final firstLine = raw.split('\n').first.trim();
    if (!firstLine.startsWith('Topic: ')) return '';
    return firstLine.substring(7).trim();
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat.jm().format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
