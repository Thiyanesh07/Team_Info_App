import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:team_info_app/core/enums/user_role.dart';

class CreateReportRequestScreen extends ConsumerStatefulWidget {
  const CreateReportRequestScreen({super.key});

  @override
  ConsumerState<CreateReportRequestScreen> createState() => _CreateReportRequestScreenState();
}

class _CreateReportRequestScreenState extends ConsumerState<CreateReportRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _deadline;
  ReportAudience _targetAudience = ReportAudience.TEAM;
  
  final List<UserRole> _selectedRoles = [];
  final List<String> _selectedUserIds = [];
  final List<String> _selectedFormats = [".pdf", ".docx"];
  
  List<UserModel> _teamMembers = [];
  bool _loadingMembers = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final members = await ref.read(appDataRepositoryProvider).getTeamMembers();
      setState(() {
        _teamMembers = members;
        _loadingMembers = false;
      });
    } catch (e) {
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetAudience == ReportAudience.ROLE && _selectedRoles.isEmpty) {
      _showError('Please select at least one role');
      return;
    }
    if (_targetAudience == ReportAudience.INDIVIDUAL && _selectedUserIds.isEmpty) {
      _showError('Please select at least one member');
      return;
    }
    if (_selectedFormats.isEmpty) {
      _showError('Please select at least one allowed format');
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(appDataRepositoryProvider);
      final response = await repo.createReportRequest({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'deadline': _deadline?.toIso8601String(),
        'targetAudience': _targetAudience.name,
        'targetRoles': _selectedRoles.map((r) => r.name).toList(),
        'targetUserIds': _selectedUserIds,
        'allowedFormats': _selectedFormats,
      });

      if (response.success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        _showError(response.message ?? 'Failed to create request');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: AppColors.background,
       appBar: AppBar(
         title: Text('New Report Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
         backgroundColor: Colors.transparent,
         elevation: 0,
       ),
       body: Form(
         key: _formKey,
         child: ListView(
           padding: const EdgeInsets.all(24),
           children: [
             _buildTextField(_titleController, 'Report Title', 'e.g. Monthly Progress Report', Icons.title_rounded, true),
             const SizedBox(height: 20),
             _buildTextField(_descController, 'Description', 'Provide instructions for the report...', Icons.notes_rounded, false, maxLines: 3),
             const SizedBox(height: 20),
             
             _buildLabel('Deadline Date'),
             const SizedBox(height: 8),
             InkWell(
               onTap: () async {
                 final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _deadline = picked);
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                 decoration: BoxDecoration(
                   color: AppColors.cardDark,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: AppColors.divider),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                     const SizedBox(width: 12),
                     Text(
                        _deadline == null ? 'Select Deadline' : DateFormat('EEE, MMM dd, yyyy').format(_deadline!),
                        style: TextStyle(color: _deadline == null ? AppColors.textMuted : Colors.white),
                     ),
                   ],
                 ),
               ),
             ),
             
             const SizedBox(height: 24),
             _buildLabel('Target Audience'),
             const SizedBox(height: 12),
             _buildAudienceSelector(),

             if (_targetAudience == ReportAudience.ROLE) ...[
               const SizedBox(height: 24),
               _buildLabel('Select Targeted Roles'),
               const SizedBox(height: 12),
               _buildRoleChips(),
             ],

             if (_targetAudience == ReportAudience.INDIVIDUAL) ...[
               const SizedBox(height: 24),
               _buildLabel('Select Target Members'),
               const SizedBox(height: 12),
               _buildMemberSelector(),
             ],

             const SizedBox(height: 24),
             _buildLabel('Allowed Formats'),
             const SizedBox(height: 12),
             _buildFormatSelector(),

             const SizedBox(height: 40),
             SizedBox(
               height: 54,
               child: ElevatedButton(
                 onPressed: _submitting ? null : _submit,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 8,
                   shadowColor: AppColors.primary.withAlpha(50),
                 ),
                 child: _submitting 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('Publish Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
             ),
           ],
         ),
       ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, IconData icon, bool required, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: (v) => required && (v == null || v.isEmpty) ? 'Field is required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary.withAlpha(200), size: 20),
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildAudienceSelector() {
    return Row(
      children: ReportAudience.values.map((audience) {
        final isSelected = _targetAudience == audience;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Container(width: double.infinity, alignment: Alignment.center, child: Text(audience.name)),
              selected: isSelected,
              onSelected: (v) { if (v) setState(() => _targetAudience = audience); },
              backgroundColor: AppColors.cardDark,
              selectedColor: AppColors.primary.withAlpha(40),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
              showCheckmark: false,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UserRole.values.map((role) {
        final isSelected = _selectedRoles.contains(role);
        return FilterChip(
          label: Text(role.displayName, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedRoles.add(role);
              } else {
                _selectedRoles.remove(role);
              }
            });
          },
          backgroundColor: AppColors.cardDark,
          selectedColor: AppColors.secondary.withAlpha(40),
          side: BorderSide(color: isSelected ? AppColors.secondary : AppColors.divider),
          labelStyle: TextStyle(color: isSelected ? AppColors.secondary : AppColors.textMuted),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildMemberSelector() {
    if (_loadingMembers) return const Center(child: CircularProgressIndicator());
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _teamMembers.length,
        itemBuilder: (context, index) {
          final m = _teamMembers[index];
          final isSelected = _selectedUserIds.contains(m.id);
          return CheckboxListTile(
            title: Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(m.role.displayName, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            value: isSelected,
            activeColor: AppColors.primary,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedUserIds.add(m.id);
                } else {
                  _selectedUserIds.remove(m.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFormatSelector() {
    final formats = [".pdf", ".docx", ".xlsx", ".pptx"];
    return Wrap(
      spacing: 8,
      children: formats.map((f) {
        final isSelected = _selectedFormats.contains(f);
        return FilterChip(
          label: Text(f),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedFormats.add(f);
              } else {
                _selectedFormats.remove(f);
              }
            });
          },
          backgroundColor: AppColors.cardDark,
          selectedColor: AppColors.primary.withAlpha(40),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
        );
      }).toList(),
    );
  }
}
