import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/providers/auth_provider.dart';

enum ExportTimeline { today, range, all }

class ExportSelectionDialog extends ConsumerStatefulWidget {
  final Function(
    String scope,
    String? userId,
    ExportTimeline timeline,
    DateTime? startDate,
    DateTime? endDate,
  )
  onExport;
  final String title;

  const ExportSelectionDialog({
    super.key,
    required this.onExport,
    this.title = 'Export Options',
  });

  @override
  ConsumerState<ExportSelectionDialog> createState() => _ExportSelectionDialogState();
}

class _ExportSelectionDialogState extends ConsumerState<ExportSelectionDialog> {
  final ApiService _api = ApiService();
  List<UserModel> _users = [];
  bool _isLoadingUsers = false;
  UserModel? _selectedUser;
  String _currentScope = 'SELF';
  ExportTimeline _timeline = ExportTimeline.today;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).user?.role.isLeader ?? false) {
        _loadUsers();
      }
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await _api.get(ApiConstants.users);
      if (res.success) {
        setState(() {
          _users = (res.data as List)
              .map((u) => UserModel.fromJson(u))
              .toList();
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
    final user = ref.watch(authProvider).user;
    final isLeader = user?.role.isLeader ?? false;

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOption('My Data Only', 'SELF', Icons.person_outline),
            if (isLeader) ...[
              const SizedBox(height: 12),
              _buildOption('Entire Team Status', 'TEAM', Icons.groups_outlined),
              const SizedBox(height: 12),
              _buildOption(
                'Specific Member',
                'USER',
                Icons.person_search_outlined,
              ),
            ],
            if (isLeader && _currentScope == 'USER') ...[
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
                      hint: const Text(
                        'Select Member',
                        style: TextStyle(color: Colors.white54),
                      ),
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
            const SizedBox(height: 18),
            const Text(
              'Timeline',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildTimelineOption(
              'Today',
              ExportTimeline.today,
              Icons.today_rounded,
            ),
            const SizedBox(height: 8),
            _buildTimelineOption(
              'Between Dates',
              ExportTimeline.range,
              Icons.date_range_rounded,
            ),
            const SizedBox(height: 8),
            _buildTimelineOption(
              'All Time',
              ExportTimeline.all,
              Icons.all_inclusive_rounded,
            ),
            if (_timeline == ExportTimeline.range) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: _dateTile(_startDate),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: _dateTile(_endDate),
                    ),
                  ),
                ],
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
                  widget.onExport(
                    _currentScope,
                    _selectedUser?.id,
                    _timeline,
                    _timeline == ExportTimeline.range ? _startDate : null,
                    _timeline == ExportTimeline.range ? _endDate : null,
                  );
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : Colors.white.withAlpha(13),
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
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineOption(
    String label,
    ExportTimeline value,
    IconData icon,
  ) {
    final isSelected = _timeline == value;
    return InkWell(
      onTap: () => setState(() => _timeline = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : Colors.white.withAlpha(13),
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
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(DateTime date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        DateFormat('MMM dd, yyyy').format(date),
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
