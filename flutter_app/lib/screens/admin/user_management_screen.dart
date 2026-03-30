import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/core/enums/user_role.dart';
import 'package:team_info_app/screens/skills/skills_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:team_info_app/screens/tasks/report_export_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _api = ApiService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    final res = await _api.get(ApiConstants.users);
    if (res.success && mounted) {
      setState(() {
        _users = (res.data as List).map((e) => UserModel.fromJson(e)).toList();
        _filteredUsers = _users;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((u) {
        return u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.department?.toLowerCase() ?? '').contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Account Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ReportExportDialog(),
              );
            },
            tooltip: 'Export Reports',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () => _showAddUserDialog(),
            label: const Text('New Member'),
            icon: const Icon(Icons.person_add_rounded),
            backgroundColor: AppColors.primary,
            elevation: 4,
          ).animate().scale(
            delay: 400.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: _filteredUsers.length,
                itemBuilder: (_, i) =>
                    _UserCard(
                          user: _filteredUsers[i],
                          onEdit: () => _showEditUserDialog(_filteredUsers[i]),
                          onDelete: () => _confirmDelete(_filteredUsers[i]),
                          onRoleChange: (r) =>
                              _updateUserRole(_filteredUsers[i].id, r),
                        )
                        .animate()
                        .fade(delay: (i * 50).ms, duration: 300.ms)
                        .slideX(begin: 0.05, end: 0),
              ),
            ),
    );
  }

  void _showAddUserDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    String selectedRole = 'MEMBER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Member',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _formField(nameC, 'Full Name', Icons.person_outline),
              const SizedBox(height: 12),
              _formField(emailC, 'Google Email', Icons.email_outlined),
              const SizedBox(height: 16),
              const Text(
                'Assigned Role',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserRole.values
                    .map(
                      (r) => ChoiceChip(
                        label: Text(
                          r.displayName,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: selectedRole == r.apiValue,
                        onSelected: (s) {
                          if (s) setModalState(() => selectedRole = r.apiValue);
                        },
                        backgroundColor: AppColors.surfaceLight,
                        selectedColor: AppColors.primary.withAlpha(50),
                        labelStyle: TextStyle(
                          color: selectedRole == r.apiValue
                              ? AppColors.primary
                              : Colors.white60,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameC.text.isEmpty || emailC.text.isEmpty) return;
                    final res = await _api.post(
                      '${ApiConstants.users}/create',
                      body: {
                        'name': nameC.text,
                        'email': emailC.text,
                        'role': selectedRole,
                      },
                    );
                    if (!context.mounted) return;
                    if (res.success) {
                      Navigator.pop(context);
                      _loadUsers();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            res.message ?? 'Failed to create account',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameC = TextEditingController(text: user.name);
    final regNoC = TextEditingController(text: user.regNo ?? '');
    final deptC = TextEditingController(text: user.department ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Member Details',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _formField(nameC, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _formField(regNoC, 'Register No', Icons.badge_outlined),
            const SizedBox(height: 12),
            _formField(deptC, 'Department', Icons.business_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final res = await _api.put(
                    '${ApiConstants.users}/${user.id}',
                    body: {
                      'name': nameC.text,
                      'regNo': regNoC.text,
                      'department': deptC.text,
                    },
                  );
                  if (!sheetContext.mounted) return;
                  if (res.success) {
                    Navigator.pop(sheetContext);
                    _loadUsers();
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

  Widget _formField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceLight.withAlpha(100),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final res = await _api.delete('${ApiConstants.users}/${user.id}');
              if (!dialogContext.mounted) return;
              if (res.success) {
                Navigator.pop(dialogContext);
                _loadUsers();
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String role) async {
    final res = await _api.put(
      '${ApiConstants.users}/$userId',
      body: {'role': role},
    );
    if (res.success) _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onRoleChange;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _userAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                if (user.department?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${user.department} • ${user.regNo ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary.withAlpha(180),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _actionMenu(context),
        ],
      ),
    );
  }

  Widget _userAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null
            ? Text(
                user.name[0].toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
    );
  }

  Widget _actionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: _MenuAction(Icons.edit_outlined, 'Edit Details'),
        ),
        const PopupMenuItem(
          value: 'skills',
          child: _MenuAction(Icons.bolt_rounded, 'Manage Skills'),
        ),
        PopupMenuItem(
          enabled: false,
          child: Container(
            height: 1,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
        ),
        ...UserRole.values.map(
          (r) => PopupMenuItem(
            value: 'role_${r.apiValue}',
            child: _MenuAction(
              Icons.shield_outlined,
              r.displayName,
              isRole: true,
              isSelected: r == user.role,
            ),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: Container(
            height: 1,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuAction(
            Icons.delete_outline_rounded,
            'Delete Account',
            isDestructive: true,
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'skills') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SkillsScreen(targetUser: user)),
          );
        }
        if (v == 'delete') onDelete();
        if (v.startsWith('role_')) onRoleChange(v.replaceFirst('role_', ''));
      },
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool isRole;
  final bool isSelected;
  const _MenuAction(
    this.icon,
    this.label, {
    this.isDestructive = false,
    this.isRole = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDestructive
              ? AppColors.error
              : (isSelected ? AppColors.primary : AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDestructive
                ? AppColors.error
                : (isSelected ? AppColors.primary : Colors.white),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
