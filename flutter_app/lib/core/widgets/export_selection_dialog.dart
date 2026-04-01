import 'package:flutter/material.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';

class ExportSelectionDialog extends StatefulWidget {
  final Function(String scope, String? userId) onExport;
  final String title;

  const ExportSelectionDialog({
    super.key,
    required this.onExport,
    this.title = 'Export Options',
  });

  @override
  State<ExportSelectionDialog> createState() => _ExportSelectionDialogState();
}

class _ExportSelectionDialogState extends State<ExportSelectionDialog> {
  final ApiService _api = ApiService();
  List<UserModel> _users = [];
  bool _isLoadingUsers = false;
  UserModel? _selectedUser;
  String _currentScope = 'SELF';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await _api.get(ApiConstants.users);
      if (res.success) {
        setState(() {
          _users = (res.data as List).map((u) => UserModel.fromJson(u)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading users for export: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOption(
              'My Data Only',
              'SELF',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildOption(
              'Entire Team Status',
              'TEAM',
              Icons.groups_outlined,
            ),
            const SizedBox(height: 12),
            _buildOption(
              'Specific Member',
              'USER',
              Icons.person_search_outlined,
            ),
            if (_currentScope == 'USER') ...[
              const SizedBox(height: 16),
              if (_isLoadingUsers)
                const Center(child: CircularProgressIndicator())
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserModel>(
                      value: _selectedUser,
                      dropdownColor: AppColors.cardDark,
                      hint: const Text('Select Member', style: TextStyle(color: Colors.white54)),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      items: _users.map((user) {
                        return DropdownMenuItem(
                          value: user,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedUser = val);
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: (_currentScope == 'USER' && _selectedUser == null)
              ? null
              : () {
                  widget.onExport(_currentScope, _selectedUser?.id);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Export Excel'),
        ),
      ],
    );
  }

  Widget _buildOption(String label, String value, IconData icon) {
    final isSelected = _currentScope == value;
    return InkWell(
      onTap: () => setState(() => _currentScope = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.white54),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
