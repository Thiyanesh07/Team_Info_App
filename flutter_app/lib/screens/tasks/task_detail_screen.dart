import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _api = ApiService();
  bool _loading = true;
  TaskAssignment? _task;
  List<TaskReport> _reports = [];
  final _reportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    // Find the task from either my tasks or assigned tasks
    // Since there's no direct GET /api/tasks/:id, we fetch lists and filter.
    // Ideally we should add a GET /api/tasks/:id to backend, but we'll work with lists for now.

    final meRes = await _api.get(ApiConstants.myTasks);
    final asRes = await _api.get(
      ApiConstants.assignedTasks,
    ); // Might fail if not leader, that's fine

    List<dynamic> allTasks = [];
    if (meRes.success) allTasks.addAll(meRes.data as List);
    if (asRes.success) allTasks.addAll(asRes.data as List);

    final tJson = allTasks.firstWhere(
      (t) => t['id'] == widget.taskId,
      orElse: () => null,
    );

    if (tJson != null) {
      _task = TaskAssignment.fromJson(tJson);
      await _loadReports();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadReports() async {
    final res = await _api.get(
      "${ApiConstants.tasks}/${widget.taskId}/reports",
    );
    if (res.success && mounted) {
      setState(() {
        _reports = (res.data as List)
            .map((e) => TaskReport.fromJson(e))
            .toList();
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await _api.patch(
      "${ApiConstants.tasks}/${widget.taskId}/status",
      body: {'status': newStatus},
    );
    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(const SnackBar(content: Text('Status updated')));
      _loadTaskDetails();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message ?? 'Failed')));
    }
  }

  Future<void> _submitReport() async {
    if (_reportController.text.trim().isEmpty) return;

    final res = await _api.post(
      "${ApiConstants.tasks}/${widget.taskId}/reports",
      body: {'reportText': _reportController.text.trim()},
    );
    if (res.success) {
      _reportController.clear();
      _loadReports();
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      final nav = Navigator.of(context);
      final res = await _api.delete("${ApiConstants.tasks}/${widget.taskId}");
      if (!mounted) return;
      if (res.success) {
        nav.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_task == null) {
      return Scaffold(appBar: AppBar(title: const Text('Task Not Found')));
    }

    final user = ref.watch(authProvider).user;
    final isAssignee = _task!.assignedTo?['id'] == user?.id;
    final isCreator = _task!.assignedBy?['id'] == user?.id;
    final isAdmin = user?.role.name.toUpperCase() == 'ADMIN';
    final isLeader = user != null && user.role.name.toUpperCase() != 'MEMBER';
    final canUpdateStatus = isAssignee && isLeader;
    final canEditTask = isCreator || isAdmin || (isAssignee && isLeader);
    
    final now = DateTime.now();
    final deadline = _task!.deadline != null ? DateTime.parse(_task!.deadline!) : null;
    final isDeadlinePassed = deadline != null && now.isAfter(deadline);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (canEditTask) ...[
            IconButton(
              icon: const Icon(Icons.edit_calendar, color: AppColors.primary),
              onPressed: _showEditDialog,
              tooltip: 'Edit / Reopen Task',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: _deleteTask,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header
            Container(
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
                        _task!.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_task!.description != null) ...[
                        Text(
                          _task!.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.person,
                            "To: ${_task!.assignedTo?['name'] ?? 'U'}",
                          ),
                          _buildInfoChip(Icons.flag, _task!.priority),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoChip(
                            Icons.person_outline,
                            "By: ${_task!.assignedBy?['name'] ?? 'U'}",
                          ),
                          _buildInfoChip(Icons.watch_later, _task!.status),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .slideX(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                )
                .fade(duration: 400.ms),

            // Status Update (Assigned leaders only)
            if (canUpdateStatus) ...[
              const SizedBox(height: 24),
              Text(
                'Update Status',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusBtn('PENDING', Icons.pending_actions),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusBtn(
                      'IN_PROGRESS',
                      Icons.play_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusBtn(
                      'COMPLETED',
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ).animate().scale(
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
            ],

            // Reports Section
            const SizedBox(height: 24),
            Text(
              'Progress Reports',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            if (_reports.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No reports submitted yet.',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              )
            else
              ..._reports.map(
                (r) =>
                    Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage:
                                        r.user?['profileImageUrl'] != null
                                        ? NetworkImage(
                                            r.user!['profileImageUrl'],
                                          )
                                        : null,
                                    child: r.user?['profileImageUrl'] == null
                                        ? const Icon(Icons.person, size: 12)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.user?['name'] ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (r.createdAt != null)
                                    Text(
                                      DateFormat.yMMMd().format(
                                        DateTime.parse(r.createdAt!),
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  // Allow author, creator, admin, or assigned leader (canEditTask covers these)
                                  if ((r.user?['id'] == user?.id) || canEditTask)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (r.user?['id'] == user?.id)
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                                            onPressed: () => _editReport(r),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        if (r.user?['id'] == user?.id) const SizedBox(width: 8),
                                        // Only authors or leaders can delete
                                        if ((r.user?['id'] == user?.id) || canEditTask)
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  backgroundColor: AppColors.cardDark,
                                                  title: Text('Delete Update?', style: GoogleFonts.inter(color: Colors.white)),
                                                  content: Text('Are you sure you want to remove this progress update?', style: GoogleFonts.inter(color: Colors.white70)),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, true), 
                                                      child: const Text('Delete', style: TextStyle(color: AppColors.error))
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                final res = await _api.delete("${ApiConstants.tasks}/${widget.taskId}/reports/${r.id}");
                                                if (res.success) {
                                                  _loadReports();
                                                } else {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(res.message ?? 'Failed to delete report'))
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                r.reportText,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fade(
                          duration: 400.ms,
                          delay: (200 + _reports.indexOf(r) * 100).ms,
                        )
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
              ),

            // Add Report (Assignee only + Before Deadline)
            if (isAssignee) ...[
              const SizedBox(height: 16),
              if (isDeadlinePassed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Submission Closed. The deadline has passed. Please contact your leader to reopen.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reportController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Add a progress report...',
                          filled: true,
                          fillColor: AppColors.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _submitReport,
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBtn(String status, IconData icon) {
    final isSelected = _task?.status == status;
    return InkWell(
      onTap: () => _updateStatus(status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(40)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              status.split('_').join(' '),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    DateTime? newDeadline = _task!.deadline != null ? DateTime.parse(_task!.deadline!) : DateTime.now().add(const Duration(days: 1));
    final controller = TextEditingController(text: _task!.description);
    final titleController = TextEditingController(text: _task!.title);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text('Manage Task', style: GoogleFonts.inter(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.grey)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.grey)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Deadline', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    newDeadline != null ? DateFormat.yMMMd().add_Hm().format(newDeadline!) : 'No Deadline',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: newDeadline ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(newDeadline ?? DateTime.now()),
                      );
                      if (time != null) {
                        setDialogState(() {
                          newDeadline = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final res = await _api.updateTask(_task!.id, {
                  'title': titleController.text.trim(),
                  'description': controller.text.trim(),
                  'deadline': newDeadline?.toIso8601String(),
                });
                if (res.success) {
                  nav.pop();
                  _loadTaskDetails();
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editReport(TaskReport report) async {
    final controller = TextEditingController(text: report.reportText);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Edit Progress Update', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter updated progress...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final navigator = Navigator.of(ctx);
              final res = await _api.updateTaskReport(widget.taskId, report.id, controller.text.trim());
              if (res.success && mounted) {
                navigator.pop();
                _loadReports();
              }
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
