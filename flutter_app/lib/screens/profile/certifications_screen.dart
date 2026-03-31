import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/certification_model.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class CertificationsScreen extends ConsumerStatefulWidget {
  final UserModel? targetUser; // If null, means current user's certs
  const CertificationsScreen({super.key, this.targetUser});

  @override
  ConsumerState<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen> {
  List<CertificationModel> _certs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCerts();
  }

  Future<void> _loadCerts() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);
    final userId = widget.targetUser?.id ?? 'me';
    final res = await api.get('${ApiConstants.certifications}/user/$userId');
    
    if (mounted && res.success) {
      final List data = res.data;
      setState(() {
        _certs = data.map((e) => CertificationModel.fromJson(e)).toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showAddCertDialog() {
    final skillC = TextEditingController();
    final providerC = TextEditingController();
    final descC = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Certification', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            _textField(skillC, 'Skill Name (e.g. AWS, React)', Icons.bolt_rounded),
            const SizedBox(height: 12),
            _textField(providerC, 'Provider (e.g. Coursera, Google)', Icons.business_outlined),
            const SizedBox(height: 12),
            _textField(descC, 'Description / Verification ID', Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (skillC.text.isEmpty) return;
                  final api = ref.read(apiServiceProvider);
                  final res = await api.post(ApiConstants.certifications, body: {
                    'skill': skillC.text.trim(),
                    'provider': providerC.text.trim(),
                    'description': descC.text.trim(),
                    'issuedDate': selectedDate.toIso8601String(),
                  });
                  if (mounted && res.success) {
                    Navigator.pop(context);
                    _loadCerts();
                  }
                },
                child: const Text('Add Achievement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCertDialog(CertificationModel cert) {
    final skillC = TextEditingController(text: cert.skill);
    final providerC = TextEditingController(text: cert.provider);
    final descC = TextEditingController(text: cert.description);
    DateTime selectedDate = cert.issuedDate != null ? DateTime.parse(cert.issuedDate!) : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Certification', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            _textField(skillC, 'Skill Name (e.g. AWS, React)', Icons.bolt_rounded),
            const SizedBox(height: 12),
            _textField(providerC, 'Provider (e.g. Coursera, Google)', Icons.business_outlined),
            const SizedBox(height: 12),
            _textField(descC, 'Description / Verification ID', Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (skillC.text.isEmpty) return;
                  final api = ref.read(apiServiceProvider);
                  final res = await api.put('${ApiConstants.certifications}/${cert.id}', body: {
                    'skill': skillC.text.trim(),
                    'provider': providerC.text.trim(),
                    'description': descC.text.trim(),
                    'issuedDate': selectedDate.toIso8601String(),
                  });
                  if (mounted && res.success) {
                    Navigator.pop(context);
                    _loadCerts();
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCert(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Certification', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this achievement?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      final api = ref.read(apiServiceProvider);
      final res = await api.delete('${ApiConstants.certifications}/$id');
      if (res.success) _loadCerts();
    }
  }

  Widget _textField(TextEditingController c, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceLight.withAlpha(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.targetUser == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isMe ? 'My Certifications' : '${widget.targetUser!.name}\'s Certs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: isMe ? FloatingActionButton(
        onPressed: _showAddCertDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ) : null,
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _certs.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _certs.length,
              itemBuilder: (context, index) => _buildCertCard(_certs[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 64, color: AppColors.textMuted.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            'No certifications found.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      ),
    ).animate().fade();
  }

  Widget _buildCertCard(CertificationModel cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.skill,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (cert.provider != null)
                  Text(
                    cert.provider!,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 8),
                if (cert.description != null && cert.description!.isNotEmpty)
                  Text(
                    cert.description!,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 12),
                if (cert.issuedDate != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Issued: ${DateFormat('MMM yyyy').format(DateTime.parse(cert.issuedDate!))}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (widget.targetUser == null)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
              color: AppColors.surface,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.primary))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) {
                if (v == 'edit') _showEditCertDialog(cert);
                if (v == 'delete') _deleteCert(cert.id);
              },
            ),
        ],
      ),
    ).animate().slideX(begin: 0.1, end: 0).fade();
  }
}
