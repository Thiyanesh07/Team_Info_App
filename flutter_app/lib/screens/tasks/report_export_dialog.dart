import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/services/report_export_service.dart';

class ReportExportDialog extends ConsumerStatefulWidget {
  const ReportExportDialog({super.key});

  @override
  ConsumerState<ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends ConsumerState<ReportExportDialog> {
  final _api = ApiService();
  bool _loading = false;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _exporting = false;
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    _loadUsersIfNeeded();
  }

  Future<void> _loadUsersIfNeeded() async {
    final user = ref.read(authProvider).user;
    if (user?.role.canViewAllData == true) {
      setState(() => _loading = true);
      final res = await _api.get(ApiConstants.users);
      if (res.success && mounted) {
        setState(() {
          _users = (res.data as List)
              .map((e) => UserModel.fromJson(e))
              .toList();
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
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
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);

    String query =
        '?startDate=${_startDate.toIso8601String().split('T')[0]}&endDate=${_endDate.toIso8601String().split('T')[0]}';
    if (_selectedUser != null) {
      query += '&userId=${_selectedUser!.id}';
    }

    final res = await _api.get('${ApiConstants.tasks}/reports/export$query');

    if (!mounted) return;

    if (res.success && res.data != null) {
      final reports = res.data as List;
      if (reports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No reports found for this selection.')),
        );
        setState(() => _exporting = false);
        return;
      }

      final title = _selectedUser != null
          ? 'Task Report - ${_selectedUser!.name}'
          : 'Team Task Report';

      try {
        if (_format == 'PDF') {
          await ReportExportService.exportToPdf(reports, title);
        } else {
          await ReportExportService.exportToExcel(reports, title);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to export reports')),
      );
    }

    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final curUser = ref.watch(authProvider).user;
    final isLeader = curUser?.role.canViewAllData == true;

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text(
        'Export Reports',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (isLeader) ...[
                Text(
                  'Filter by Member',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserModel?>(
                      isExpanded: true,
                      dropdownColor: AppColors.cardDark,
                      value: _selectedUser,
                      hint: const Text(
                        'Entire Team',
                        style: TextStyle(color: Colors.white70),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Entire Team',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ..._users.map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedUser = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'Date Range',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('MMM dd').format(_startDate),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('MMM dd').format(_endDate),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'File Format',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _format,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _format = v);
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'PDF',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: 'PDF',
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Excel',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: 'Excel',
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exporting ? null : _exportData,
          icon: _exporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.download_rounded,
                  size: 18,
                  color: Colors.white,
                ),
          label: Text(
            _exporting ? 'Generating...' : 'Export & Share',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ],
    );
  }
}
