import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/utils/in_app_file_actions.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:team_info_app/screens/reports/report_analytics_screen.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/services/api_service.dart';

class ReportReviewHub extends ConsumerStatefulWidget {
  final ReportRequest request;

  const ReportReviewHub({super.key, required this.request});

  @override
  ConsumerState<ReportReviewHub> createState() => _ReportReviewHubState();
}

class _ReportReviewHubState extends ConsumerState<ReportReviewHub> {
  bool _loading = true;
  List<ReportSubmission> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _loading = true);
    try {
      final subs = await ref
          .read(appDataRepositoryProvider)
          .getSubmissionsForRequest(widget.request.id);
      if (mounted) {
        setState(() {
          _submissions = subs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteRequest() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Delete Request?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this report request and all associated submissions?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete ALL',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      final response = await ref
          .read(appDataRepositoryProvider)
          .deleteReportRequest(widget.request.id);
      if (response.success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role.name.toUpperCase() == 'ADMIN';
    final isCreator = widget.request.assignedBy?['id'] == user?.id;
    final canManage = isCreator || isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reports Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (canManage) ...[
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: AppColors.secondary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportAnalyticsScreen(request: widget.request),
                  ),
                );
              },
              tooltip: 'View Participation',
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar, color: AppColors.primary),
              onPressed: _showEditDialog,
              tooltip: 'Edit / Reopen',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              onPressed: _deleteRequest,
              tooltip: 'Delete Request',
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Submissions (${_submissions.length})',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _submissions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _submissions.length,
                    itemBuilder: (context, index) => _SubmissionReviewCard(
                      submission: _submissions[index],
                      onUpdate: _loadSubmissions,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.request.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.request.description ?? 'No description',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallBadge(
                Icons.group,
                'Audience: ${widget.request.targetAudience.name}',
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildSmallBadge(
                Icons.calendar_today,
                widget.request.deadline != null
                    ? DateFormat.yMMMd().add_Hm().format(DateTime.parse(widget.request.deadline!))
                    : 'No Deadline',
                AppColors.secondary,
              ),
            ],
          ),
          if (widget.request.originalDeadline != null && widget.request.deadline != widget.request.originalDeadline) ...[
            const SizedBox(height: 8),
            _buildSmallBadge(
              Icons.history,
              'Original: ${DateFormat.yMMMd().add_Hm().format(DateTime.parse(widget.request.originalDeadline!))}',
              AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final api = ApiService();
    DateTime? newDeadline = widget.request.deadline != null ? DateTime.parse(widget.request.deadline!) : DateTime.now().add(const Duration(days: 1));
    final titleController = TextEditingController(text: widget.request.title);
    final descController = TextEditingController(text: widget.request.description);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Manage Report Request', style: TextStyle(color: Colors.white)),
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
                  controller: descController,
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
                    if (picked != null) {
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
                final res = await api.updateReportRequest(widget.request.id, {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'deadline': newDeadline?.toIso8601String(),
                });
                if (res.success) {
                  nav.pop();
                  _loadSubmissions();
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: AppColors.primary.withAlpha(50),
          ),
          const SizedBox(height: 16),
          const Text(
            'No submissions yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SubmissionReviewCard extends ConsumerStatefulWidget {
  final ReportSubmission submission;
  final VoidCallback onUpdate;

  const _SubmissionReviewCard({
    required this.submission,
    required this.onUpdate,
  });

  @override
  ConsumerState<_SubmissionReviewCard> createState() =>
      _SubmissionReviewCardState();
}

class _SubmissionReviewCardState extends ConsumerState<_SubmissionReviewCard> {
  bool _processing = false;

  Future<void> _openPreview(String url) async {
    await InAppFileActions.preview(
      context,
      url,
      // fileName: widget.submission.fileName,
    );
  }

  Future<void> _downloadOriginal(String url) async {
    await InAppFileActions.downloadAndOpen(
      context,
      url,
      // fileName: widget.submission.fileName,
    );
  }

  Future<void> _showReviewDialog() async {
    final notesController = TextEditingController(
      text: widget.submission.reviewerNotes,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Review Submission',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add feedback or instructions for the team member:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Please clarify section 2...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _updateStatus(
              ReportSubmissionStatus.REDO,
              notesController.text,
              true,
            ),
            child: const Text(
              'Request REDO',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _updateStatus(
              ReportSubmissionStatus.COMPLETED,
              notesController.text,
              true,
            ),
            child: const Text(
              'Approve Document',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    ReportSubmissionStatus status,
    String notes,
    bool popDialog,
  ) async {
    if (popDialog) Navigator.pop(context);

    setState(() => _processing = true);
    try {
      final repo = ref.read(appDataRepositoryProvider);
      final res = await repo.reviewSubmission(
        widget.submission.id,
        status.name,
        notes,
      );
      if (res.success) {
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (widget.submission.status) {
      case ReportSubmissionStatus.PENDING:
        statusColor = AppColors.warning;
        break;
      case ReportSubmissionStatus.COMPLETED:
        statusColor = AppColors.success;
        break;
      case ReportSubmissionStatus.REDO:
        statusColor = AppColors.error;
        break;
    }

    return Card(
      color: AppColors.surfaceLight.withAlpha(50),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.cardDark,
                  backgroundImage:
                      widget.submission.user?['profileImageUrl'] != null
                      ? NetworkImage(widget.submission.user!['profileImageUrl'])
                      : null,
                  child: widget.submission.user?['profileImageUrl'] == null
                      ? Text(widget.submission.user?['name']?[0] ?? '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.submission.user?['name'] ?? 'Team Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.submission.user?['regNo'] ?? 'No ID',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(widget.submission.status, statusColor),
              ],
            ),
            const Divider(height: 24, color: AppColors.divider),
            if (widget.submission.notes != null &&
                widget.submission.notes!.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notes: ${widget.submission.notes}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openPreview(widget.submission.fileUrl),
                  icon: const Icon(Icons.preview_outlined, size: 16),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _downloadOriginal(widget.submission.fileUrl),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ElevatedButton(
                  onPressed: _processing ? null : _showReviewDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _processing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportSubmissionStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
