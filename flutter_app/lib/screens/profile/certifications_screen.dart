import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:team_info_app/models/certification_model.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/services/excel_export_service.dart';
import 'package:team_info_app/core/widgets/export_selection_dialog.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/core/utils/in_app_file_actions.dart';
import 'package:team_info_app/widgets/empty_states.dart';
import 'package:team_info_app/screens/shared/member_data_view_screen.dart';

class CertificationsScreen extends ConsumerStatefulWidget {
  final UserModel? targetUser; // If null, means current user's certs
  const CertificationsScreen({super.key, this.targetUser});

  @override
  ConsumerState<CertificationsScreen> createState() =>
      _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen> {
  final _excelService = ExcelExportService();
  List<CertificationModel> _certs = [];
  bool _loading = true;

  Future<void> _previewProof(String proofUrl) async {
    await InAppFileActions.preview(context, proofUrl);
  }

  @override
  void initState() {
    super.initState();
    _loadCerts();
  }

  Future<void> _loadCerts() async {
    setState(() => _loading = true);
    final api = ref.read(apiServiceProvider);

    final endpoint = widget.targetUser == null
        ? ApiConstants.certifications
        : '${ApiConstants.certifications}/user/${widget.targetUser!.id}';

    final res = await api.get(endpoint);

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
    String? proofUrl;
    bool isUploading = false;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Certification',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _textField(
                skillC,
                'Skill Name (e.g. AWS, React)',
                Icons.bolt_rounded,
              ),
              const SizedBox(height: 12),
              _textField(
                providerC,
                'Provider (e.g. Coursera, Google)',
                Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                descC,
                'Description / Verification ID',
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date Picker Trigger
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: AppColors.surface,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Issued Date: ${DateFormat('MMM yyyy').format(selectedDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_calendar_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PROOF UPLOADER
              InkWell(
                onTap: isUploading
                    ? null
                    : () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            );

                        if (result != null) {
                          setModalState(() {
                            isUploading = true;
                            fileName = result.files.single.name;
                          });

                          try {
                            final api = ref.read(apiServiceProvider);
                            final uploadRes = await api.uploadFile(
                              '/upload/image',
                              result.files.single.path!,
                              fieldName: 'file',
                              folder: 'certifications/proof',
                            );

                            if (uploadRes.success) {
                              setModalState(() {
                                proofUrl = uploadRes.data['url'];
                                isUploading = false;
                              });
                            } else {
                              setModalState(() {
                                isUploading = false;
                                fileName = null;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Upload failed: ${uploadRes.message}',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setModalState(() {
                              isUploading = false;
                              fileName = null;
                            });
                          }
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isUploading ? 10 : 20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(30),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isUploading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.primary,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUploading
                                  ? 'Uploading Evidence...'
                                  : (fileName ?? 'Upload Proof (PDF/Image)'),
                              style: GoogleFonts.inter(
                                color: proofUrl != null
                                    ? AppColors.primary
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (proofUrl != null)
                              Text(
                                'Click to change file',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (proofUrl != null)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),

              if (proofUrl != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _previewProof(proofUrl!),
                    icon: const Icon(Icons.preview_outlined, size: 16),
                    label: const Text('Preview Proof'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (skillC.text.isEmpty) return;
                    final api = ref.read(apiServiceProvider);
                    final res = await api.post(
                      ApiConstants.certifications,
                      body: {
                        'skill': skillC.text.trim(),
                        'provider': providerC.text.trim(),
                        'description': descC.text.trim(),
                        'issuedDate': selectedDate.toIso8601String(),
                        'proofUrl': proofUrl,
                      },
                    );
                    if (!modalContext.mounted) return;
                    if (res.success) {
                      Navigator.pop(modalContext);
                      _loadCerts();
                    }
                  },
                  child: const Text('Add Achievement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCertDialog(CertificationModel cert) {
    final skillC = TextEditingController(text: cert.skill);
    final providerC = TextEditingController(text: cert.provider);
    final descC = TextEditingController(text: cert.description);
    DateTime selectedDate = cert.issuedDate != null
        ? DateTime.parse(cert.issuedDate!)
        : DateTime.now();
    String? proofUrl = cert.proofUrl;
    bool isUploading = false;
    String? fileName = cert.proofUrl != null ? 'Current Proof' : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Certification',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _textField(
                skillC,
                'Skill Name (e.g. AWS, React)',
                Icons.bolt_rounded,
              ),
              const SizedBox(height: 12),
              _textField(
                providerC,
                'Provider (e.g. Coursera, Google)',
                Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                descC,
                'Description / Verification ID',
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date Picker Trigger
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: AppColors.surface,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Issued Date: ${DateFormat('MMM yyyy').format(selectedDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_calendar_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PROOF UPLOADER (EDIT MODE)
              InkWell(
                onTap: isUploading
                    ? null
                    : () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            );

                        if (result != null) {
                          setModalState(() {
                            isUploading = true;
                            fileName = result.files.single.name;
                          });

                          try {
                            final api = ref.read(apiServiceProvider);
                            final uploadRes = await api.uploadFile(
                              '/upload/image',
                              result.files.single.path!,
                              fieldName: 'file',
                              folder: 'certifications/proof',
                            );

                            if (uploadRes.success) {
                              setModalState(() {
                                proofUrl = uploadRes.data['url'];
                                isUploading = false;
                              });
                            } else {
                              setModalState(() {
                                isUploading = false;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Upload failed: ${uploadRes.message}',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setModalState(() {
                              isUploading = false;
                            });
                          }
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isUploading ? 10 : 20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(30),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isUploading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.primary,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUploading
                                  ? 'Uploading Evidence...'
                                  : (fileName ?? 'Upload Proof (PDF/Image)'),
                              style: GoogleFonts.inter(
                                color: proofUrl != null
                                    ? AppColors.primary
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (proofUrl != null)
                              Text(
                                'Click to change evidence',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (proofUrl != null)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),

              if (proofUrl != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _previewProof(proofUrl!),
                    icon: const Icon(Icons.preview_outlined, size: 16),
                    label: const Text('Preview Proof'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (skillC.text.isEmpty) return;
                    final api = ref.read(apiServiceProvider);
                    final res = await api.put(
                      '${ApiConstants.certifications}/${cert.id}',
                      body: {
                        'skill': skillC.text.trim(),
                        'provider': providerC.text.trim(),
                        'description': descC.text.trim(),
                        'issuedDate': selectedDate.toIso8601String(),
                        'proofUrl': proofUrl,
                      },
                    );
                    if (!modalContext.mounted) return;
                    if (res.success) {
                      Navigator.pop(modalContext);
                      _loadCerts();
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCert(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Certification',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this achievement?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final api = ref.read(apiServiceProvider);
      final res = await api.delete('${ApiConstants.certifications}/$id');
      if (res.success) _loadCerts();
    }
  }

  Widget _textField(
    TextEditingController c,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
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
    final user = ref.watch(authProvider).user;
    final canViewOthers = user != null && user.role.canViewAllData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isMe ? 'My Certifications' : '${widget.targetUser!.name}\'s Certs',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isMe && canViewOthers)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemberDataViewScreen(
                      dataType: MemberDataType.certifications,
                    ),
                  ),
                );
              },
              tooltip: 'View Member Certificates',
            ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _handleExport(),
            tooltip: 'Export Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isMe
          ? FloatingActionButton(
              onPressed: _showAddCertDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certs.isEmpty
          ? EmptyCertifications(onAction: _showAddCertDialog)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _certs.length,
              itemBuilder: (context, index) => _buildCertCard(_certs[index]),
            ),
    );
  }

  void _handleExport() {
    if (ref.read(authProvider).user == null) return;

    showDialog(
      context: context,
      builder: (_) => ExportSelectionDialog(
        title: 'Export Certifications',
        onExport: (scope, selectedUserId, timeline, startDate, endDate) async {
          await _runExport(
            scope: scope,
            userId: selectedUserId,
            timeline: timeline,
            startDate: startDate,
            endDate: endDate,
          );
        },
      ),
    );
  }

  Future<void> _runExport({
    required String scope,
    String? userId,
    ExportTimeline timeline = ExportTimeline.today,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing Excel report...')),
      );

      await _excelService.downloadAndOpenReport(
        endpoint: ApiConstants.exportCertifications,
        filename:
            'Certifications_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        queryParams: {
          'scope': scope,
          'timeline': timeline.name.toUpperCase(),
          if (startDate != null)
            'startDate': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'endDate': endDate.toIso8601String().split('T')[0],
          if (userId != null) 'userId': userId,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // _buildEmptyState() replaced by bespoke widgets/empty_states.dart

  Widget _buildCertCard(CertificationModel cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.skill,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (cert.provider != null)
                  Text(
                    cert.provider!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                if (cert.description != null && cert.description!.isNotEmpty)
                  Text(
                    cert.description!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 12),
                if (cert.issuedDate != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Issued: ${DateFormat('MMM yyyy').format(DateTime.parse(cert.issuedDate!))}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (cert.proofUrl != null && cert.proofUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () {
                  _previewProof(cert.proofUrl!);
                },
                tooltip: 'View Proof',
              ),
            ),
          if (widget.targetUser == null)
            PopupMenuButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textMuted,
                size: 20,
              ),
              color: AppColors.surface,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Edit',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
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
