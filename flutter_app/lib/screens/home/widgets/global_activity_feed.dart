import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:timeago/timeago.dart' as timeago;

class GlobalActivityFeed extends StatelessWidget {
  final List<ActivityItem> activities;
  final bool isLoading;

  const GlobalActivityFeed({
    super.key,
    required this.activities,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardDark.withAlpha(100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.hub_outlined,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No activity recorded yet',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = activities[index];
        return _ActivityCard(item: item);
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;

  const _ActivityCard({required this.item});

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _safeInitial(String? name) {
    final normalized = name?.trim() ?? '';
    if (normalized.isEmpty) return 'U';
    return normalized[0].toUpperCase();
  }

  String _asText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  ImageProvider? _safeNetworkImage(String? rawUrl) {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return NetworkImage(url);
  }

  String _typeLabel(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.DAILY_LOG:
        return 'DAILY LOG';
      case ActivityItemType.PROJECT_UPDATE:
        return 'PROJECT UPDATE';
      case ActivityItemType.TASK_REPORT:
        return 'TASK REPORT';
      case ActivityItemType.SYSTEM_EVENT:
        return 'SYSTEM EVENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getTypeColor(item.type);
    final IconData typeIcon = _getTypeIcon(item.type);
    final parsedTime = _tryParseDate(item.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(item),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _asText(item.user?['name'], fallback: 'System'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      parsedTime != null
                          ? timeago.format(parsedTime)
                          : 'just now',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, color: typeColor, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            _typeLabel(item.type),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _asText(item.title, fallback: 'Activity'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _asText(item.content, fallback: 'No details available'),
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ActivityItem item) {
    final avatarUrl = _asText(item.user?['profileImageUrl']);
    final name = _asText(item.user?['name'], fallback: 'U');
    final imageProvider = _safeNetworkImage(avatarUrl);

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.surfaceLight,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              _safeInitial(name),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            )
          : null,
    );
  }

  Color _getTypeColor(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.DAILY_LOG:
        return Colors.blueAccent;
      case ActivityItemType.PROJECT_UPDATE:
        return Colors.purpleAccent;
      case ActivityItemType.TASK_REPORT:
        return Colors.greenAccent;
      case ActivityItemType.SYSTEM_EVENT:
        return Colors.orangeAccent;
    }
  }

  IconData _getTypeIcon(ActivityItemType type) {
    switch (type) {
      case ActivityItemType.DAILY_LOG:
        return Icons.history_edu;
      case ActivityItemType.PROJECT_UPDATE:
        return Icons.rocket_launch;
      case ActivityItemType.TASK_REPORT:
        return Icons.assignment_turned_in;
      case ActivityItemType.SYSTEM_EVENT:
        return Icons.auto_awesome;
    }
  }
}
