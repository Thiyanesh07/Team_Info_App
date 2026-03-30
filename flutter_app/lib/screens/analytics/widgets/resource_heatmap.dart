import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';

class ResourceHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> workloadData;
  final bool isLoading;

  const ResourceHeatmap({
    super.key,
    required this.workloadData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (workloadData.isEmpty) {
      return _buildEmptyState();
    }

    // Get unique days from the data (sorted desc)
    final days = workloadData.first['dailyHours'].keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              // Header Row (Dates)
              TableRow(
                children: [
                  const SizedBox(width: 80), // User Name column
                  ...days.map(
                    (day) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _formatDateLabel(day),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              // User Rows
              ...workloadData.map(
                (data) => TableRow(
                  children: [
                    // User Label
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 8.0,
                      ),
                      child: Text(
                        data['user']['name'].split(' ').first,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Heatmap Cells
                    ...days.map((day) {
                      final double hours = (data['dailyHours'][day] ?? 0)
                          .toDouble();
                      return _buildHeatmapCell(hours);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildHeatmapCell(double hours) {
    Color color;
    if (hours == 0) {
      color = AppColors.cardDark;
    } else if (hours < 2) {
      color = Colors.green.withAlpha(50);
    } else if (hours < 5) {
      color = Colors.green.withAlpha(150);
    } else if (hours < 8) {
      color = Colors.green;
    } else {
      color = Colors.redAccent; // Over-allocated
    }

    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider.withAlpha(50)),
      ),
      child: Center(
        child: Text(
          hours > 0 ? hours.toStringAsFixed(1) : '',
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Load: ',
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
        ),
        _LegendItem(color: AppColors.cardDark, label: '0h'),
        _LegendItem(color: Colors.green.withAlpha(150), label: 'Part'),
        _LegendItem(color: Colors.green, label: 'Full'),
        _LegendItem(color: Colors.redAccent, label: 'Over'),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No workload data available',
        style: GoogleFonts.inter(color: AppColors.textMuted),
      ),
    );
  }

  String _formatDateLabel(String isoDate) {
    final date = DateTime.parse(isoDate);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}\n${date.day}/${date.month}';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
