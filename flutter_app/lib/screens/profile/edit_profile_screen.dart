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
  late TextEditingController _nameC, _regNoC, _enrollmentNoC, _deptC, _yearC, _mobileC, _cgpaC;
  late TextEditingController _rewardPointsC, _activityPointsC;
  late TextEditingController _linkedinC, _githubC, _leetcodeC, _twitterC;
  late TextEditingController _primarySkill1C, _primarySkill2C;
  late TextEditingController _secondarySkill1C, _secondarySkill2C;
  late TextEditingController _specialSkill1C, _specialSkill2C;
  final List<TextEditingController> _langControllers = [];
  List<String> _primarySkills = [],
      _secondarySkills = [],
      _specialSkills = [],
      _langs = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _nameC = TextEditingController(text: user.name);
    _regNoC = TextEditingController(text: user.regNo ?? '');
    _enrollmentNoC = TextEditingController(text: user.enrollmentNo ?? '');
    _deptC = TextEditingController(text: user.department ?? '');
    _yearC = TextEditingController(text: user.year ?? '');
    _mobileC = TextEditingController(text: user.mobile ?? '');
    _cgpaC = TextEditingController(text: user.cgpa?.toString() ?? '');
    _rewardPointsC = TextEditingController(text: user.rewardPoints.toString());
    _activityPointsC = TextEditingController(text: user.activityPoints.toString());
    _linkedinC = TextEditingController(text: user.linkedinUrl ?? '');
    _githubC = TextEditingController(text: user.githubUrl ?? '');
    _leetcodeC = TextEditingController(text: user.leetcodeUrl ?? '');
    _twitterC = TextEditingController(text: user.twitterUrl ?? '');
    _primarySkills = List.from(user.primarySkills);
    _secondarySkills = List.from(user.secondarySkills);
    _specialSkills = List.from(user.specialSkills);
    _langs = List.from(user.programmingLangs);

    _primarySkill1C = TextEditingController(
      text: _primarySkills.isNotEmpty ? _primarySkills[0] : '',
    );
    _primarySkill2C = TextEditingController(
      text: _primarySkills.length > 1 ? _primarySkills[1] : '',
    );
    _secondarySkill1C = TextEditingController(
      text: _secondarySkills.isNotEmpty ? _secondarySkills[0] : '',
    );
    _secondarySkill2C = TextEditingController(
      text: _secondarySkills.length > 1 ? _secondarySkills[1] : '',
    );
    _specialSkill1C = TextEditingController(
      text: _specialSkills.isNotEmpty ? _specialSkills[0] : '',
    );
    _specialSkill2C = TextEditingController(
      text: _specialSkills.length > 1 ? _specialSkills[1] : '',
    );

    if (_langs.isEmpty) {
      _langControllers.add(TextEditingController());
    } else {
      for (final lang in _langs) {
        _langControllers.add(TextEditingController(text: lang));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    _primarySkills = [
      _primarySkill1C.text.trim(),
      _primarySkill2C.text.trim(),
    ].where((s) => s.isNotEmpty).toList();
    _secondarySkills = [
      _secondarySkill1C.text.trim(),
      _secondarySkill2C.text.trim(),
    ].where((s) => s.isNotEmpty).toList();
    _specialSkills = [
      _specialSkill1C.text.trim(),
      _specialSkill2C.text.trim(),
    ].where((s) => s.isNotEmpty).toList();

    final rawLangs = _langControllers
        .map((controller) => controller.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final seen = <String>{};
    _langs = rawLangs.where((lang) {
      final key = lang.toLowerCase();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    final res = await _api.put(
      ApiConstants.updateProfile,
      body: {
        'name': _nameC.text,
        'regNo': _regNoC.text,
        'enrollmentNo': _enrollmentNoC.text,
        'department': _deptC.text,
        'year': _yearC.text,
        'mobile': _mobileC.text,
        'cgpa': _cgpaC.text.isNotEmpty ? double.tryParse(_cgpaC.text) : null,
        'linkedinUrl': _linkedinC.text.isNotEmpty ? _linkedinC.text : null,
        'githubUrl': _githubC.text.isNotEmpty ? _githubC.text : null,
        'leetcodeUrl': _leetcodeC.text.isNotEmpty ? _leetcodeC.text : null,
        'twitterUrl': _twitterC.text.isNotEmpty ? _twitterC.text : null,
        'primarySkills': _primarySkills,
        'secondarySkills': _secondarySkills,
        'specialSkills': _specialSkills,
        'programmingLangs': _langs,
        'rewardPoints': int.tryParse(_rewardPointsC.text) ?? 0,
        'activityPoints': int.tryParse(_activityPointsC.text) ?? 0,
      },
    );

    setState(() => _saving = false);
    if (res.success && mounted) {
      ref.read(authProvider.notifier).refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              _field(
                _nameC,
                'Full Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              _field(_regNoC, 'Register No.'),
              _field(_enrollmentNoC, 'Enrollment No. (Portal ID)'),
              _field(_deptC, 'Department'),
              _field(_mobileC, 'Mobile', keyboardType: TextInputType.phone),
              _field(_cgpaC, 'CGPA', keyboardType: TextInputType.number),
              _field(_rewardPointsC, 'Reward Points', keyboardType: TextInputType.number),
              _field(_activityPointsC, 'Activity Points', keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              _sectionTitle('Skills'),
              _skillPairInput(
                'Primary Skills',
                _primarySkill1C,
                _primarySkill2C,
                AppColors.primary,
              ),
              _skillPairInput(
                'Secondary Skills',
                _secondarySkill1C,
                _secondarySkill2C,
                AppColors.secondary,
              ),
              _skillPairInput(
                'Special Skills',
                _specialSkill1C,
                _specialSkill2C,
                AppColors.accent,
              ),
              _dynamicLanguagesInput(
                'Programming Languages',
                AppColors.warning,
              ),
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
    child: Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(hintText: hint),
      style: const TextStyle(color: Colors.white),
    ),
  );

  Widget _skillPairInput(
    String label,
    TextEditingController first,
    TextEditingController second,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: first,
                  decoration: InputDecoration(
                    hintText: 'Skill 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color.withAlpha(70)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: second,
                  decoration: InputDecoration(
                    hintText: 'Skill 2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color.withAlpha(70)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dynamicLanguagesInput(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_langControllers.length, (index) {
            final isLast = index == _langControllers.length - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _langControllers[index],
                      decoration: InputDecoration(
                        hintText: 'Language ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: color.withAlpha(70)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isLast)
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: color),
                      tooltip: 'Add language',
                      onPressed: () {
                        setState(() {
                          _langControllers.add(TextEditingController());
                        });
                      },
                    ),
                  if (_langControllers.length > 1)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.error,
                      ),
                      tooltip: 'Remove language',
                      onPressed: () {
                        setState(() {
                          _langControllers[index].dispose();
                          _langControllers.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose();
    _regNoC.dispose();
    _enrollmentNoC.dispose();
    _deptC.dispose();
    _yearC.dispose();
    _mobileC.dispose();
    _cgpaC.dispose();
    _linkedinC.dispose();
    _githubC.dispose();
    _leetcodeC.dispose();
    _twitterC.dispose();
    _primarySkill1C.dispose();
    _primarySkill2C.dispose();
    _secondarySkill1C.dispose();
    _secondarySkill2C.dispose();
    _specialSkill1C.dispose();
    _specialSkill2C.dispose();
    for (final controller in _langControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
