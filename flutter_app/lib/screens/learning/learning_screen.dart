import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});
  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  final _api = ApiService();
  List<Learning> _learnings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLearnings();
  }

  Future<void> _loadLearnings() async {
    final res = await _api.get(ApiConstants.learning);
    if (res.success && mounted) {
      setState(() {
        _learnings = (res.data as List)
            .map((e) => Learning.fromJson(e))
            .toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Learning & Skills',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLearningDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Skill'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _learnings.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _loadLearnings,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _learnings.length,
                itemBuilder: (_, i) =>
                    _LearningCard(
                          learning: _learnings[i],
                          onRefresh: _loadLearnings,
                        )
                        .animate()
                        .fade(delay: (i * 80).ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
              ),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: AppColors.textMuted.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Learning Trackers Yet',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your learning progress and new skills!',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ],
              )
              .animate()
              .fade(duration: 600.ms)
              .scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  void _showAddLearningDialog(BuildContext context) {
    // Basic implementation for now, should be expanded for a professional look
    final skillC = TextEditingController();
    final topicsC = TextEditingController();
    String level = 'BEGINNER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track New Skill',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: skillC,
                decoration: const InputDecoration(
                  hintText: 'Skill Name (e.g., Flutter, Node.js) *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicsC,
                decoration: const InputDecoration(
                  hintText: 'Topics covered (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Proficiency Level',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED']
                    .map(
                      (l) => GestureDetector(
                        onTap: () => setModalState(() => level = l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: level == l
                                ? AppColors.primary.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: level == l
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            l,
                            style: TextStyle(
                              color: level == l
                                  ? AppColors.primary
                                  : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (skillC.text.isEmpty) return;
                    final res = await _api.post(
                      ApiConstants.learning,
                      body: {
                        'skillName': skillC.text,
                        'level': level,
                        'topics': topicsC.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                        'status': 'ONGOING',
                      },
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadLearnings();
                    }
                  },
                  child: const Text('Start Tracking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final Learning learning;
  final VoidCallback onRefresh;
  const _LearningCard({required this.learning, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learning.skillName,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      learning.level,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(learning.status),
            ],
          ),
          if (learning.topics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: learning.topics
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'COMPLETED' ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
