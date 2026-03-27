import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});
  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _api = ApiService();
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
        _activities = (res.data as List).map((e) => DailyActivity.fromJson(e)).toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'LEARNING': return AppColors.secondary;
      case 'PROJECT': return AppColors.primary;
      default: return AppColors.warning;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'LEARNING': return Icons.school_rounded;
      case 'PROJECT': return Icons.code_rounded;
      default: return Icons.miscellaneous_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_activity_fab',
        onPressed: () => _showAddActivityDialog(context),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline_rounded, size: 64, color: AppColors.textMuted.withAlpha(100)),
                      const SizedBox(height: 16),
                      Text('No activities logged', style: GoogleFonts.inter(fontSize: 18, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Start tracking your work!', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
              : RefreshIndicator(
                  onRefresh: _loadActivities,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length,
                    itemBuilder: (_, i) {
                      final a = _activities[i];
                      final color = _typeColor(a.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_typeIcon(a.type), color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.customType ?? a.type,
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                  if (a.description?.isNotEmpty == true)
                                    Text(a.description!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 2),
                                  const SizedBox(height: 4),
                                  Text(_formatTimeRange(a.startTime, a.endTime),
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                              onPressed: () async {
                                await _api.delete('${ApiConstants.activities}/${a.id}');
                                _loadActivities();
                              },
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 400.ms, delay: (i * 100).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                    },
                  ),
                ),
    );
  }

  String _formatTimeRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final diff = e.difference(s);
      return '${DateFormat.jm().format(s)} - ${DateFormat.jm().format(e)} (${diff.inHours}h ${diff.inMinutes % 60}m)';
    } catch (_) {
      return '$start - $end';
    }
  }

  void _showAddActivityDialog(BuildContext context) {
    String selectedType = 'LEARNING';
    final descC = TextEditingController();
    final customTypeC = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Activity', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 16),
              // Type selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'LEARNING', label: Text('Learning')),
                  ButtonSegment(value: 'PROJECT', label: Text('Project')),
                  ButtonSegment(value: 'OTHERS', label: Text('Others')),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) => setDialogState(() => selectedType = v.first),
              ),
              const SizedBox(height: 14),
              if (selectedType == 'OTHERS')
                TextField(controller: customTypeC, decoration: const InputDecoration(hintText: 'Custom Type'),
                  style: const TextStyle(color: Colors.white)),
              if (selectedType == 'OTHERS') const SizedBox(height: 12),
              TextField(controller: descC, decoration: const InputDecoration(hintText: 'Description'),
                style: const TextStyle(color: Colors.white), maxLines: 2),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: startTime);
                        if (t != null) setDialogState(() => startTime = t);
                      },
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('Start: ${startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: endTime);
                        if (t != null) setDialogState(() => endTime = t);
                      },
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('End: ${endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
                    final end = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

                    await _api.post(ApiConstants.activities, body: {
                      'type': selectedType,
                      'customType': customTypeC.text.isNotEmpty ? customTypeC.text : null,
                      'description': descC.text,
                      'startTime': start.toIso8601String(),
                      'endTime': end.toIso8601String(),
                      'date': DateTime(now.year, now.month, now.day).toIso8601String(),
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (mounted) _loadActivities();
                  },
                  child: const Text('Log Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
