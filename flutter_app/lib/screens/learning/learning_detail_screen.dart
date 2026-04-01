import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/enums/user_role.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LearningDetailScreen extends ConsumerStatefulWidget {
  final Learning learning;
  const LearningDetailScreen({super.key, required this.learning});

  @override
  ConsumerState<LearningDetailScreen> createState() =>
      _LearningDetailScreenState();
}

class _LearningDetailScreenState extends ConsumerState<LearningDetailScreen> {
  final _api = ApiService();
  List<DailyActivity> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final res = await _api.get('${ApiConstants.activities}?type=LEARNING&customType=${widget.learning.id}');
    if (res.success && mounted) {
      setState(() {
        _sessions = (res.data as List)
            .map((e) => DailyActivity.fromJson(e))
            .toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showLogSessionDialog({DailyActivity? session}) {
    final isEdit = session != null;
    
    String initialTopic = '';
    String initialDesc = '';
    if (isEdit) {
      final lines = session.description?.split('\n') ?? [];
      if (lines.isNotEmpty && lines[0].startsWith('Topic: ')) {
        initialTopic = lines[0].substring(7);
        if (lines.length > 1) initialDesc = lines.sublist(1).join('\n');
      } else {
        initialDesc = session.description ?? '';
      }
    }

    final topicC = TextEditingController(text: initialTopic);
    final descC = TextEditingController(text: initialDesc);
    DateTime date = isEdit ? DateTime.parse(session.date).toLocal() : DateTime.now();
    TimeOfDay startTime = isEdit ? TimeOfDay.fromDateTime(DateTime.parse(session.startTime).toLocal()) : TimeOfDay.now();
    TimeOfDay endTime = isEdit ? TimeOfDay.fromDateTime(DateTime.parse(session.endTime).toLocal()) : TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

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
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Study Session' : 'Log Study Session',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicC,
                decoration: const InputDecoration(hintText: 'Current Topic (e.g. State Management) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descC,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'What did you study/accomplish?'),
              ),
              const SizedBox(height: 16),
              
              // Date Picker
              _buildPickerField(
                icon: Icons.calendar_today_outlined,
                text: 'Date: ${DateFormat('MMM dd, yyyy').format(date)}',
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => _datePickerTheme(child),
                  );
                  if (d != null) setModalState(() => date = d);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildPickerField(
                      icon: Icons.access_time_outlined,
                      text: startTime.format(context),
                      label: 'Start Time',
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context, initialTime: startTime,
                          builder: (context, child) => _datePickerTheme(child),
                        );
                        if (t != null) setModalState(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerField(
                      icon: Icons.access_time_filled,
                      text: endTime.format(context),
                      label: 'End Time',
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context, initialTime: endTime,
                          builder: (context, child) => _datePickerTheme(child),
                        );
                        if (t != null) setModalState(() => endTime = t);
                      },
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
                    if (topicC.text.isEmpty) return;

                    // Compute precise DateTimes
                    final startDt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
                    var endDt = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);
                    
                    if (endDt.isBefore(startDt)) {
                      endDt = endDt.add(const Duration(days: 1)); // Cross-midnight
                    }

                    final body = {
                      'type': 'LEARNING',
                      'customType': widget.learning.id,
                      'description': 'Topic: ${topicC.text}${descC.text.isNotEmpty ? '\n${descC.text}' : ''}',
                      'date': startDt.toUtc().toIso8601String(),
                      'startTime': startDt.toUtc().toIso8601String(),
                      'endTime': endDt.toUtc().toIso8601String(),
                    };

                    final res = isEdit
                      ? await _api.put('${ApiConstants.activities}/${session.id}', body: body)
                      : await _api.post(ApiConstants.activities, body: body);

                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadSessions();
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Save Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this study session?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await _api.delete('${ApiConstants.activities}/$id');
      if (res.success) _loadSessions();
    }
  }

  Widget _buildPickerField({required IconData icon, required String text, String? label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePickerTheme(Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: Colors.white,
      ),
    ),
    child: child!,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tracker Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogSessionDialog,
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Log Session'),
        backgroundColor: AppColors.primary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Study Timeline',
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white
                ),
              ),
            ),
          ),
          _loading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : _sessions.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text('No study sessions logged yet.', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildSessionCard(_sessions[i]),
                      childCount: _sessions.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      widget.learning.skillName,
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      widget.learning.level,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.learning.topics.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: widget.learning.topics.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildSessionCard(DailyActivity session) {
    final start = DateTime.parse(session.startTime).toLocal();
    final end = DateTime.parse(session.endTime).toLocal();
    final diff = end.difference(start);
    final hours = diff.inMinutes / 60.0;
    
    // Extract topic out of description which was saved as "Topic: xyz\nReal description"
    final lines = session.description?.split('\n') ?? [];
    String topic = '';
    String desc = '';
    if (lines.isNotEmpty && lines[0].startsWith('Topic: ')) {
      topic = lines[0].substring(7);
      if (lines.length > 1) {
        desc = lines.sublist(1).join('\n');
      }
    } else {
      desc = session.description ?? '';
    }

    final currentUser = ref.read(authProvider).user;
    final canEdit = currentUser?.id == session.userId || currentUser?.role == UserRole.admin;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              const Icon(Icons.calendar_month, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM dd, yyyy').format(start),
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${hours.toStringAsFixed(1)} hrs',
                      style: GoogleFonts.inter(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  color: AppColors.surface,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.primary))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') _showLogSessionDialog(session: session);
                    if (v == 'delete') _deleteSession(session.id);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (topic.isNotEmpty) ...[
            Text(topic, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
          ],
          if (desc.isNotEmpty) Text(desc, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 12),
          Text(
            '${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
