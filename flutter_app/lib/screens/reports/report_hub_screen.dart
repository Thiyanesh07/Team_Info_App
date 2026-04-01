import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:team_info_app/screens/reports/create_report_request_screen.dart';
import 'package:team_info_app/screens/reports/report_submission_screen.dart';
import 'package:team_info_app/screens/reports/report_review_hub.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportHubScreen extends ConsumerStatefulWidget {
  const ReportHubScreen({super.key});

  @override
  ConsumerState<ReportHubScreen> createState() => _ReportHubScreenState();
}

class _ReportHubScreenState extends ConsumerState<ReportHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<ReportRequest> _myPendingReports = [];
  List<ReportRequest> _manageableRequests = [];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final isLeader = user?.role.isLeader ?? false;
    _tabController = TabController(length: isLeader ? 2 : 1, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(appDataRepositoryProvider);
      final user = ref.read(authProvider).user;
      
      final results = await Future.wait([
        repo.getMyPendingReports(),
        if (user?.role.isLeader ?? false) repo.getManageableRequests(),
      ]);

      if (mounted) {
        setState(() {
          _myPendingReports = results[0] as List<ReportRequest>;
          if (results.length > 1) {
            _manageableRequests = results[1] as List<ReportRequest>;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isLeader = user?.role.isLeader ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Report Center', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: isLeader ? TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Assigned to Me'),
            Tab(text: 'Manage Requests'),
          ],
        ) : null,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildAssignedList(),
              if (isLeader) _buildManageableList(),
            ],
          ),
      floatingActionButton: isLeader ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReportRequestScreen()),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ) : null,
    );
  }

  Widget _buildAssignedList() {
    if (_myPendingReports.isEmpty) {
      return _buildEmptyState('No reports assigned to you right now.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPendingReports.length,
      itemBuilder: (context, index) {
        final request = _myPendingReports[index];
        // User's submission for this request (might be none)
        final mySubmission = request.submissions.isNotEmpty ? request.submissions.first : null;
        
        return _ReportCard(
          request: request,
          submission: mySubmission,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportSubmissionScreen(request: request, submission: mySubmission),
              ),
            );
            if (result == true) _loadData();
          },
        );
      },
    );
  }

  Widget _buildManageableList() {
     if (_manageableRequests.isEmpty) {
      return _buildEmptyState('You haven\'t created any report requests yet.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _manageableRequests.length,
      itemBuilder: (context, index) {
        final request = _manageableRequests[index];
        return Card(
          color: AppColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(request.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  request.description ?? 'No description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${request.targetAudience.name}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.description_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    // Accessing dynamic count from the backend _count property
                    Text(
                      'Submissions: ${request.submissions.length}',
                      style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportReviewHub(request: request),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.primary.withAlpha(50)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportRequest request;
  final ReportSubmission? submission;
  final VoidCallback onTap;

  const _ReportCard({
    required this.request,
    required this.submission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = submission?.status ?? ReportSubmissionStatus.PENDING;
    final isRedo = status == ReportSubmissionStatus.REDO;

    return Card(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRedo ? const BorderSide(color: AppColors.error, width: 1.5) : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned by: ${request.assignedBy?['name'] ?? 'Team Leader'}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${request.deadline != null ? request.deadline!.substring(0, 10) : "No Deadline"}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.file_present, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    request.allowedFormats.join(', '),
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (isRedo && submission?.reviewerNotes != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.refresh_rounded, color: AppColors.error, size: 14),
                          SizedBox(width: 4),
                          Text('REDO FEEDBACK', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(submission!.reviewerNotes!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportSubmissionStatus status) {
    Color color;
    String label;
    switch (status) {
      case ReportSubmissionStatus.PENDING:
        color = AppColors.warning;
        label = 'AWAITING';
        break;
      case ReportSubmissionStatus.COMPLETED:
        color = AppColors.success;
        label = 'COMPLETED';
        break;
      case ReportSubmissionStatus.REDO:
        color = AppColors.error;
        label = 'REDO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
