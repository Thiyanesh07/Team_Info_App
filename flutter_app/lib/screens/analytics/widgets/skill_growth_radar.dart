import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';

class SkillGrowthRadar extends StatelessWidget {
  final Map<String, int> skillData;

  const SkillGrowthRadar({super.key, required this.skillData});

  @override
  Widget build(BuildContext context) {
    if (skillData.isEmpty) {
      return const Center(child: Text('No skill data', style: TextStyle(color: AppColors.textMuted)));
    }

    final keys = skillData.keys.toList();
    final dataSets = [
      RadarDataSet(
        fillColor: AppColors.primary.withAlpha(50),
        borderColor: AppColors.primary,
        entryRadius: 3,
        dataEntries: keys.map((k) => RadarEntry(value: skillData[k]!.toDouble())).toList(),
        borderWidth: 2,
      ),
    ];

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBorderData: const BorderSide(color: Colors.transparent),
          gridBorderData: BorderSide(color: AppColors.divider.withAlpha(50), width: 1),
          tickBorderData: BorderSide(color: AppColors.divider.withAlpha(30), width: 1),
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 8),
          titlePositionPercentageOffset: 0.15,
          titleTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          getTitle: (index, angle) {
            String label = keys[index];
            return RadarChartTitle(text: label, angle: angle);
          },
          dataSets: dataSets,
        ),
      ),
    );
  }
}
