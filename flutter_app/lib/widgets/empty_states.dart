import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onAction;

  const CustomEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withAlpha(20), width: 2),
              ),
              child: Icon(icon, size: 80, color: AppColors.primary.withAlpha(40)),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 54,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: AppColors.primary.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    buttonText!,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(curve: Curves.elasticOut),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyHackathons extends StatelessWidget {
  final VoidCallback onAction;
  const EmptyHackathons({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return CustomEmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'COMMAND CENTER IDLE',
      description: 'No tactical competitions detected. Initiate a new hackathon mission to secure recognition.',
      buttonText: 'BEGIN MISSION',
      onAction: onAction,
    );
  }
}

class EmptyProjects extends StatelessWidget {
  final VoidCallback onAction;
  const EmptyProjects({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return CustomEmptyState(
      icon: Icons.rocket_launch_outlined,
      title: 'NO ACTIVE DEPLOYMENTS',
      description: 'Your project portfolio is currently offline. Log your latest innovations to build domain authority.',
      buttonText: 'NEW DEPLOYMENT',
      onAction: onAction,
    );
  }
}

class EmptyCertifications extends StatelessWidget {
  final VoidCallback onAction;
  const EmptyCertifications({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return CustomEmptyState(
      icon: Icons.workspace_premium_outlined,
      title: 'CREDENTIALS PENDING',
      description: 'No verified achievements on record. Upload your certifications to enhance your professional profile.',
      buttonText: 'UPLOAD PROOF',
      onAction: onAction,
    );
  }
}

class EmptyMessages extends StatelessWidget {
  const EmptyMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomEmptyState(
      icon: Icons.message_outlined,
      title: 'SILENT FREQUENCIES',
      description: 'No tactical transmissions received. Connect with agents to initiate real-time coordination.',
    );
  }
}
