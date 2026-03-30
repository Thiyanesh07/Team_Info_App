import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:intl/intl.dart';

class MilestoneTimeline extends StatelessWidget {
  final List<ProjectMilestone> milestones;
  final bool isLoading;

  const MilestoneTimeline({
    super.key,
    required this.milestones,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && milestones.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (milestones.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        final isLast = index == milestones.length - 1;
        return _MilestoneItem(
          milestone: milestone,
          isLast: isLast,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            'No milestones defined for this mission',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final ProjectMilestone milestone;
  final bool isLast;

  const _MilestoneItem({required this.milestone, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = milestone.status == MilestoneStatus.COMPLETED;
    final bool isInProgress = milestone.status == MilestoneStatus.IN_PROGRESS;
    
    final Color statusColor = isCompleted 
        ? Colors.greenAccent 
        : (isInProgress ? AppColors.primary : AppColors.textMuted);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withAlpha(30),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check : (isInProgress ? Icons.rocket_launch : Icons.flag),
                    size: 12,
                    color: statusColor,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.white70 : Colors.white,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (milestone.deadline != null)
                        Text(
                          DateFormat('MMM d').format(DateTime.parse(milestone.deadline!)),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  if (milestone.description != null && milestone.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      milestone.description!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _StatusBadge(status: milestone.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MilestoneStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case MilestoneStatus.COMPLETED:
        color = Colors.greenAccent;
        label = 'COMPLETED';
        break;
      case MilestoneStatus.IN_PROGRESS:
        color = AppColors.primary;
        label = 'IN PROGRESS';
        break;
      case MilestoneStatus.PENDING:
        color = AppColors.textMuted;
        label = 'PENDING';
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
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
