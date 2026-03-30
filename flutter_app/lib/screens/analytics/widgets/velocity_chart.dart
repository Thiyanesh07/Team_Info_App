import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:team_info_app/core/theme/app_theme.dart';

class VelocityChart extends StatelessWidget {
  final Map<String, dynamic> dailyActivityCount;

  const VelocityChart({super.key, required this.dailyActivityCount});

  @override
  Widget build(BuildContext context) {
    if (dailyActivityCount.isEmpty) {
      return const Center(
        child: Text(
          'No activity data',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final sortedKeys = dailyActivityCount.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          (dailyActivityCount[sortedKeys[i]] ?? 0).toDouble(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.divider.withAlpha(50), strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: AppColors.divider.withAlpha(50), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                    final date = DateTime.parse(sortedKeys[value.toInt()]);
                    return Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedKeys.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxY(spots) + 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(30),
                    AppColors.secondary.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<FlSpot> spots) {
    double max = 0;
    for (var spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    return max < 5 ? 5 : max;
  }
}
