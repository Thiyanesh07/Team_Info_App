import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HackathonsScreen extends ConsumerStatefulWidget {
  const HackathonsScreen({super.key});
  @override
  ConsumerState<HackathonsScreen> createState() => _HackathonsScreenState();
}

class _HackathonsScreenState extends ConsumerState<HackathonsScreen> {
  final _api = ApiService();
  List<Hackathon> _hackathons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHackathons();
  }

  Future<void> _loadHackathons() async {
    final res = await _api.get(ApiConstants.hackathons);
    if (res.success && mounted) {
      setState(() {
        _hackathons = (res.data as List).map((e) => Hackathon.fromJson(e)).toList();
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
        title: Text('Hackathons', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHackathonDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Hackathon'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hackathons.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadHackathons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _hackathons.length,
                    itemBuilder: (_, i) => _HackathonCard(
                      hackathon: _hackathons[i],
                      onRefresh: _loadHackathons,
                    ).animate().fade(delay: (i * 100).ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: AppColors.textMuted.withAlpha(50)),
          const SizedBox(height: 16),
          Text('No Hackathons Yet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Log your first hackathon participation!', style: GoogleFonts.inter(color: AppColors.textMuted)),
        ],
      ).animate().fade(duration: 600.ms).scale(duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  void _showAddHackathonDialog(BuildContext context) {
    // Basic implementation for now, should be expanded for a professional look
    final nameC = TextEditingController();
    final projectC = TextEditingController();
    final descC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Hackathon', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(controller: nameC, decoration: const InputDecoration(hintText: 'Hackathon Name *')),
            const SizedBox(height: 12),
            TextField(controller: projectC, decoration: const InputDecoration(hintText: 'Project Name')),
            const SizedBox(height: 12),
            TextField(controller: descC, decoration: const InputDecoration(hintText: 'Description'), maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameC.text.isEmpty) return;
                  final res = await _api.post(ApiConstants.hackathons, body: {
                    'hackName': nameC.text, 'projectName': projectC.text, 'description': descC.text,
                    'status': 'ONGOING',
                  });
                  if (!mounted) return;
                  if (res.success) {
                    Navigator.pop(context);
                    _loadHackathons();
                  }
                },
                child: const Text('Save Hackathon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HackathonCard extends StatelessWidget {
  final Hackathon hackathon;
  final VoidCallback onRefresh;
  const _HackathonCard({required this.hackathon, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.accent.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emoji_events, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hackathon.hackName, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (hackathon.projectName != null)
                      Text(hackathon.projectName!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _statusBadge(hackathon.status),
            ],
          ),
          if (hackathon.description != null) ...[
            const SizedBox(height: 14),
            Text(hackathon.description!, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          _infoRow(Icons.calendar_today_rounded, hackathon.date ?? 'No date set'),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'WINNER' ? AppColors.success : (status == 'PARTICIPATED' ? AppColors.primary : AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(50))),
      child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
