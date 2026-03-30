import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:team_info_app/core/theme/app_theme.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.divider,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class ShimmerTeamMember extends StatelessWidget {
  const ShimmerTeamMember({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: const Column(
        children: [
          ShimmerWidget.circular(width: 60, height: 60),
          SizedBox(height: 8),
          ShimmerWidget.rectangular(height: 12, width: 50),
        ],
      ),
    );
  }
}

class ShimmerStatsCard extends StatelessWidget {
  const ShimmerStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget.circular(width: 32, height: 32),
          SizedBox(height: 12),
          ShimmerWidget.rectangular(height: 16, width: 80),
          SizedBox(height: 8),
          ShimmerWidget.rectangular(height: 12, width: 40),
        ],
      ),
    );
  }
}
