import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/screens/tasks/create_task_screen.dart';
import 'package:team_info_app/screens/tasks/task_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<TaskAssignment> _myTasks = [];
  List<TaskAssignment> _assignedTasks = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Tab controller length depends on role, but we'll safely initialize it with 2
    // and conditionally show tabs
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final user = ref.read(authProvider).user;
    final isLeader = user?.role.name.toUpperCase() != 'MEMBER';

    final resMy = await _api.get(ApiConstants.myTasks);
    if (resMy.success) {
      _myTasks = (resMy.data as List).map((e) => TaskAssignment.fromJson(e)).toList();
    }

    if (isLeader) {
      final resAssigned = await _api.get(ApiConstants.assignedTasks);
      if (resAssigned.success) {
        _assignedTasks = (resAssigned.data as List).map((e) => TaskAssignment.fromJson(e)).toList();
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return AppColors.success;
      case 'IN_PROGRESS': return AppColors.primary;
      case 'OVERDUE': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH': return AppColors.error;
      case 'LOW': return AppColors.success;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isLeader = user?.role.name.toUpperCase() != 'MEMBER';

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        bottom: isLeader
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'My Tasks'),
                  Tab(text: 'Assigned by Me'),
                ],
              )
            : null,
      ),
      floatingActionButton: isLeader
          ? FloatingActionButton.extended(
              heroTag: 'create_task_fab',
              onPressed: () async {
                final result = await Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
                if (result == true) _loadTasks();
              },
              icon: const Icon(Icons.add_task),
              label: const Text('Assign Task'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isLeader
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(_myTasks, isAssignedByMe: false),
                    _buildTaskList(_assignedTasks, isAssignedByMe: true),
                  ],
                )
              : _buildTaskList(_myTasks, isAssignedByMe: false),
    );
  }

  Widget _buildTaskList(List<TaskAssignment> tasks, {required bool isAssignedByMe}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: AppColors.textMuted.withAlpha(100)),
            const SizedBox(height: 16),
            Text('No tasks found', style: GoogleFonts.inter(fontSize: 18, color: AppColors.textSecondary)),
          ],
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) {
          final task = tasks[i];
          final statusColor = _getStatusColor(task.status);
          final priorityColor = _getPriorityColor(task.priority);

          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
              );
              if (result == true) _loadTasks();
            },
            child: Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(task.title,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withAlpha(100)),
                        ),
                        child: Text(task.status.replaceAll('_', ' '),
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (task.description?.isNotEmpty == true) ...[
                    Text(task.description!,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 14, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(task.priority, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      const Spacer(),
                      Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(isAssignedByMe ? (task.assignedTo?['name'] ?? 'Unknown') : (task.assignedBy?['name'] ?? 'Unknown'),
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms, delay: (i * 100).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          );
        },
      ),
    );
  }
}
