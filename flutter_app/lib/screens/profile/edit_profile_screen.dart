import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameC, _regNoC, _deptC, _yearC, _mobileC, _cgpaC;
  late TextEditingController _linkedinC, _githubC, _leetcodeC, _twitterC;
  List<String> _primarySkills = [], _secondarySkills = [], _specialSkills = [], _langs = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _nameC = TextEditingController(text: user.name);
    _regNoC = TextEditingController(text: user.regNo ?? '');
    _deptC = TextEditingController(text: user.department ?? '');
    _yearC = TextEditingController(text: user.year ?? '');
    _mobileC = TextEditingController(text: user.mobile ?? '');
    _cgpaC = TextEditingController(text: user.cgpa?.toString() ?? '');
    _linkedinC = TextEditingController(text: user.linkedinUrl ?? '');
    _githubC = TextEditingController(text: user.githubUrl ?? '');
    _leetcodeC = TextEditingController(text: user.leetcodeUrl ?? '');
    _twitterC = TextEditingController(text: user.twitterUrl ?? '');
    _primarySkills = List.from(user.primarySkills);
    _secondarySkills = List.from(user.secondarySkills);
    _specialSkills = List.from(user.specialSkills);
    _langs = List.from(user.programmingLangs);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final res = await _api.put(ApiConstants.updateProfile, body: {
      'name': _nameC.text, 'regNo': _regNoC.text, 'department': _deptC.text,
      'year': _yearC.text, 'mobile': _mobileC.text,
      'cgpa': _cgpaC.text.isNotEmpty ? double.tryParse(_cgpaC.text) : null,
      'linkedinUrl': _linkedinC.text.isNotEmpty ? _linkedinC.text : null,
      'githubUrl': _githubC.text.isNotEmpty ? _githubC.text : null,
      'leetcodeUrl': _leetcodeC.text.isNotEmpty ? _leetcodeC.text : null,
      'twitterUrl': _twitterC.text.isNotEmpty ? _twitterC.text : null,
      'primarySkills': _primarySkills, 'secondarySkills': _secondarySkills,
      'specialSkills': _specialSkills, 'programmingLangs': _langs,
    });

    setState(() => _saving = false);
    if (res.success && mounted) {
      ref.read(authProvider.notifier).refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Update failed'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Basic Information'),
              _field(_nameC, 'Full Name', validator: (v) => v!.isEmpty ? 'Required' : null),
              _field(_regNoC, 'Register No.'),
              _field(_deptC, 'Department'),
              _field(_yearC, 'Year'),
              _field(_mobileC, 'Mobile', keyboardType: TextInputType.phone),
              _field(_cgpaC, 'CGPA', keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              _sectionTitle('Skills'),
              _chipInput('Primary Skills', _primarySkills, AppColors.primary),
              _chipInput('Secondary Skills', _secondarySkills, AppColors.secondary),
              _chipInput('Special Skills', _specialSkills, AppColors.accent),
              _chipInput('Programming Languages', _langs, AppColors.warning),
              const SizedBox(height: 20),

              _sectionTitle('Social Links'),
              _field(_linkedinC, 'LinkedIn URL'),
              _field(_githubC, 'GitHub URL'),
              _field(_leetcodeC, 'LeetCode URL'),
              _field(_twitterC, 'Twitter URL'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
  );

  Widget _field(TextEditingController c, String hint, {
    TextInputType? keyboardType, String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c, keyboardType: keyboardType, validator: validator,
      decoration: InputDecoration(hintText: hint),
      style: const TextStyle(color: Colors.white),
    ),
  );

  Widget _chipInput(String label, List<String> items, Color color) {
    final controller = TextEditingController();
    return StatefulBuilder(
      builder: (context, setSectionState) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                ...items.map((s) => Chip(
                  label: Text(s, style: TextStyle(fontSize: 12, color: color)),
                  backgroundColor: color.withAlpha(20),
                  deleteIcon: Icon(Icons.close, size: 14, color: color),
                  onDeleted: () => setSectionState(() { items.remove(s); setState(() {}); }),
                  side: BorderSide(color: color.withAlpha(50)),
                )),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add...', isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withAlpha(50))),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        setSectionState(() { items.add(v.trim()); controller.clear(); setState(() {}); });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose(); _regNoC.dispose(); _deptC.dispose(); _yearC.dispose();
    _mobileC.dispose(); _cgpaC.dispose(); _linkedinC.dispose(); _githubC.dispose();
    _leetcodeC.dispose(); _twitterC.dispose();
    super.dispose();
  }
}
