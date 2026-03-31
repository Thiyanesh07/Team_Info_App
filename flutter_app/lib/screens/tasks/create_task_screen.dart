import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});
  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _api = ApiService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  List<dynamic> _teamMembers = [];
  String? _selectedMemberId;
  String _selectedPriority = 'MEDIUM';
  DateTime? _selectedDeadline;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final res = await _api.get(ApiConstants.users);
    if (res.success && mounted) {
      setState(() => _teamMembers = res.data as List);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDeadline = date);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Assignee are required')),
      );
      return;
    }

    setState(() => _loading = true);

    final res = await _api.post(
      ApiConstants.tasks,
      body: {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'assignedToId': _selectedMemberId,
        'priority': _selectedPriority,
        if (_selectedDeadline != null) 'deadline': _selectedDeadline!.toIso8601String(),
      },
    );

    if (mounted) {
      setState(() => _loading = false);
      if (res.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Failed to assign task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Title *', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDec('e.g., Implement Login UI'),
              style: const TextStyle(color: Colors.white),
            ),
            
            const SizedBox(height: 20),
            Text('Assign To *', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMemberId,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  hint: const Text('Select team member', style: TextStyle(color: AppColors.textMuted)),
                  items: _teamMembers.map((m) => DropdownMenuItem<String>(
                    value: m['id'],
                    child: Text(m['name'], style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedMemberId = val),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text('Description', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: _inputDec('Detailed task description...'),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Priority', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            items: ['LOW', 'MEDIUM', 'HIGH'].map((p) => DropdownMenuItem(
                              value: p, child: Text(p, style: const TextStyle(color: Colors.white)),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedPriority = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deadline', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDeadline != null 
                                  ? "${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}" 
                                  : 'Select date',
                                style: TextStyle(color: _selectedDeadline != null ? Colors.white : AppColors.textMuted),
                              ),
                              const Icon(Icons.calendar_today, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Assign Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
