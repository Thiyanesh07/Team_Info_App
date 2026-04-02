import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/services/api_service.dart';

enum MemberDataType {
  activities,
  learning,
  projects,
  hackathons,
  skills,
  certifications,
}

extension MemberDataTypeX on MemberDataType {
  String get label {
    switch (this) {
      case MemberDataType.activities:
        return 'Daily Logs';
      case MemberDataType.learning:
        return 'Learning';
      case MemberDataType.projects:
        return 'Projects';
      case MemberDataType.hackathons:
        return 'Hackathons';
      case MemberDataType.skills:
        return 'Skills';
      case MemberDataType.certifications:
        return 'Certificates';
    }
  }

  IconData get icon {
    switch (this) {
      case MemberDataType.activities:
        return Icons.timeline_rounded;
      case MemberDataType.learning:
        return Icons.school_rounded;
      case MemberDataType.projects:
        return Icons.code_rounded;
      case MemberDataType.hackathons:
        return Icons.emoji_events_rounded;
      case MemberDataType.skills:
        return Icons.bolt_rounded;
      case MemberDataType.certifications:
        return Icons.workspace_premium_rounded;
    }
  }
}

class MemberDataViewScreen extends StatefulWidget {
  final MemberDataType dataType;

  const MemberDataViewScreen({super.key, required this.dataType});

  @override
  State<MemberDataViewScreen> createState() => _MemberDataViewScreenState();
}

class _MemberDataViewScreenState extends State<MemberDataViewScreen> {
  final ApiService _api = ApiService();
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _projectPersonalRecords = [];
  List<Map<String, dynamic>> _projectTeamRecords = [];
  bool _loadingUsers = true;
  bool _loadingRecords = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final res = await _api.get(ApiConstants.users);

    if (res.success && mounted) {
      final users = (res.data as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _users = users;
        _selectedUser = users.isNotEmpty ? users.first : null;
        _loadingUsers = false;
      });
      if (_selectedUser != null) {
        await _loadRecords();
      }
    } else if (mounted) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadRecords() async {
    final user = _selectedUser;
    if (user == null) return;

    setState(() => _loadingRecords = true);

    late final dynamic res;
    switch (widget.dataType) {
      case MemberDataType.activities:
        res = await _api.get(
          ApiConstants.activities,
          queryParams: {'userId': user.id},
        );
        break;
      case MemberDataType.learning:
        res = await _api.get('${ApiConstants.learning}/user/${user.id}');
        break;
      case MemberDataType.projects:
        final results = await Future.wait([
          _api.get(
            ApiConstants.personalProjects,
            queryParams: {'userId': user.id},
          ),
          _api.get(ApiConstants.teamProjects),
        ]);

        final personalRes = results[0];
        final teamRes = results[1];

        if (mounted) {
          final personal = personalRes.success
              ? (personalRes.data as List)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
              : <Map<String, dynamic>>[];

          final allTeam = teamRes.success
              ? (teamRes.data as List)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
              : <Map<String, dynamic>>[];

          final filteredTeam = allTeam.where((project) {
            final createdById = project['createdBy'] is Map
                ? (project['createdBy']['id']?.toString() ?? '')
                : '';
            final assignedCaptainId = project['assignedCaptain'] is Map
                ? (project['assignedCaptain']['id']?.toString() ?? '')
                : '';
            final members = (project['members'] as List?) ?? const [];
            final isMember = members.any((m) {
              if (m is! Map) return false;
              return (m['userId']?.toString() ?? '') == user.id;
            });

            return createdById == user.id ||
                assignedCaptainId == user.id ||
                isMember;
          }).toList();

          setState(() {
            _projectPersonalRecords = personal;
            _projectTeamRecords = filteredTeam;
            _loadingRecords = false;
          });
        }
        return;
      case MemberDataType.hackathons:
        res = await _api.get('${ApiConstants.hackathons}/user/${user.id}');
        break;
      case MemberDataType.skills:
        res = await _api.get('${ApiConstants.psSkills}/user/${user.id}');
        break;
      case MemberDataType.certifications:
        res = await _api.get('${ApiConstants.certifications}/user/${user.id}');
        break;
    }

    if (res.success && mounted) {
      setState(() {
        _records = (res.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loadingRecords = false;
      });
    } else if (mounted) {
      setState(() {
        _records = [];
        _loadingRecords = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.dataType.label} Viewer',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildMemberSelector(),
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_loadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.dataType == MemberDataType.projects) {
      return _buildProjectTabs();
    }

    if (_records.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: widget.dataType == MemberDataType.activities
          ? _buildActivityTimeline()
          : _buildGenericRecords(),
    );
  }

  Widget _buildProjectTabs() {
    final hasPersonal = _projectPersonalRecords.isNotEmpty;
    final hasTeam = _projectTeamRecords.isNotEmpty;
    final personalCount = _projectPersonalRecords.length;
    final teamCount = _projectTeamRecords.length;
    if (!hasPersonal && !hasTeam) {
      return _buildEmptyState();
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              indicatorColor: AppColors.primary,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                Tab(text: 'Personal ($personalCount)'),
                Tab(text: 'Team ($teamCount)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProjectList(_projectPersonalRecords, isTeam: false),
                _buildProjectList(_projectTeamRecords, isTeam: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(
    List<Map<String, dynamic>> data, {
    required bool isTeam,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          isTeam
              ? 'No team projects for selected member'
              : 'No personal projects for selected member',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: data.length,
        itemBuilder: (context, i) {
          final row = data[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: isTeam
                ? _teamProjectContent(row)
                : _personalProjectContent(row),
          ).animate().fade(duration: 300.ms, delay: (i * 40).ms);
        },
      ),
    );
  }

  Widget _personalProjectContent(Map<String, dynamic> row) {
    return _twoLine(
      title: (row['name'] ?? 'Untitled Project').toString(),
      subtitle: (row['description'] ?? '').toString(),
      detail: _joinList(row['skillsUsed']),
    );
  }

  Widget _teamProjectContent(Map<String, dynamic> row) {
    final status = (row['status'] ?? '').toString();
    final domain = (row['domain'] ?? '').toString();
    final subtitle = domain.isNotEmpty
        ? '$domain${status.isNotEmpty ? ' • $status' : ''}'
        : status;

    return _twoLine(
      title: (row['projectName'] ?? 'Untitled Team Project').toString(),
      subtitle: subtitle,
      detail: (row['problemStatement'] ?? '').toString(),
    );
  }

  Widget _buildMemberSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: _loadingUsers
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<UserModel>(
                value: _selectedUser,
                hint: const Text(
                  'Select Member',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                dropdownColor: AppColors.cardDark,
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                items: _users
                    .map(
                      (u) => DropdownMenuItem<UserModel>(
                        value: u,
                        child: Text('${u.name} (${u.role.displayName})'),
                      ),
                    )
                    .toList(),
                onChanged: (user) async {
                  if (user == null) return;
                  setState(() => _selectedUser = user);
                  await _loadRecords();
                },
              ),
            ),
    );
  }

  Widget _buildActivityTimeline() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in _records) {
      final rawDate = row['date']?.toString() ?? '';
      final key = _dateKey(rawDate);
      grouped.putIfAbsent(key, () => []).add(row);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final dateKey = sortedKeys[i];
        final dayRows = grouped[dateKey] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              _prettyDate(dateKey),
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ...dayRows.map(_buildActivityCard),
            const SizedBox(height: 10),
          ],
        ).animate().fade(duration: 300.ms, delay: (i * 40).ms);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> row) {
    final type = (row['type'] ?? 'OTHERS').toString();
    final customType = (row['customType'] ?? '').toString().trim();
    final description = (row['description'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customType.isNotEmpty ? customType : type,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericRecords() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _records.length,
      itemBuilder: (context, i) {
        final row = _records[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: _genericContent(row),
        ).animate().fade(duration: 300.ms, delay: (i * 40).ms);
      },
    );
  }

  Widget _genericContent(Map<String, dynamic> row) {
    switch (widget.dataType) {
      case MemberDataType.learning:
        return _twoLine(
          title: (row['skillName'] ?? 'Untitled').toString(),
          subtitle:
              'Level: ${row['level'] ?? '-'} • Status: ${row['status'] ?? '-'}',
          detail: _joinList(row['topics']),
        );
      case MemberDataType.projects:
        return _personalProjectContent(row);
      case MemberDataType.hackathons:
        return _twoLine(
          title: (row['hackName'] ?? 'Hackathon').toString(),
          subtitle: (row['projectName'] ?? '').toString(),
          detail: (row['status'] ?? '').toString(),
        );
      case MemberDataType.skills:
        return _twoLine(
          title: (row['skillName'] ?? 'Skill').toString(),
          subtitle: (row['type'] ?? '').toString(),
          detail: (row['completed'] == true) ? 'Completed' : 'In Progress',
        );
      case MemberDataType.certifications:
        return _twoLine(
          title: (row['skill'] ?? 'Certification').toString(),
          subtitle: (row['provider'] ?? '').toString(),
          detail: (row['description'] ?? '').toString(),
        );
      case MemberDataType.activities:
        return const SizedBox.shrink();
    }
  }

  Widget _twoLine({
    required String title,
    required String subtitle,
    required String detail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (detail.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No ${widget.dataType.label.toLowerCase()} found for selected member',
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  String _dateKey(String rawDate) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  String _prettyDate(String dateKey) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dateKey));
    } catch (_) {
      return dateKey;
    }
  }

  String _joinList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().join(', ');
    }
    return '';
  }
}
