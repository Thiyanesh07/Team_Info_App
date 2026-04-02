import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/repositories/app_data_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportSubmissionScreen extends ConsumerStatefulWidget {
  final ReportRequest request;
  final ReportSubmission? submission;

  const ReportSubmissionScreen({
    super.key,
    required this.request,
    this.submission,
  });

  @override
  ConsumerState<ReportSubmissionScreen> createState() =>
      _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState
    extends ConsumerState<ReportSubmissionScreen> {
  final _notesController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _submitting = false;
  String? _uploadUrl;

  Future<void> _openPreview(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  String _toCloudinaryDownloadUrl(String url) {
    if (!url.contains('/upload/')) return url;
    if (url.contains('/upload/fl_attachment/')) return url;
    return url.replaceFirst('/upload/', '/upload/fl_attachment/');
  }

  Future<void> _downloadOriginal(String url) async {
    final uri = Uri.parse(_toCloudinaryDownloadUrl(url));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    if (widget.submission != null) {
      _notesController.text = widget.submission!.notes ?? '';
      _uploadUrl = widget.submission!.fileUrl;
    }
  }

  Future<void> _pickFile() async {
    // Only allow formats specified in request
    // Prisma stores e.g. [".pdf", ".docx"]
    final List<String> extensions = widget.request.allowedFormats
        .map((e) => e.replaceAll('.', ''))
        .toList();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null && _uploadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiServiceProvider);
      final repo = ref.read(appDataRepositoryProvider);

      String? finalUrl = _uploadUrl;

      // 1. Upload file if a new one is selected
      if (_selectedFile != null) {
        final uploadRes = await api.uploadImage(
          _selectedFile!.path!,
          folder: 'reports/submissions',
        );
        if (uploadRes.success) {
          finalUrl = uploadRes.data['url'];
        } else {
          throw Exception(uploadRes.message ?? 'Upload failed');
        }
      }

      // 2. Submit record
      final response = await repo.submitReport(
        widget.request.id,
        finalUrl!,
        _notesController.text.trim(),
      );

      if (response.success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteSubmission() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Delete Submission?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your report submission?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _submitting = true);
      try {
        final response = await ref
            .read(appDataRepositoryProvider)
            .deleteReportSubmission(widget.submission!.id);
        if (response.success) {
          if (mounted) Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('Delete failed: $e');
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.submission?.status ?? ReportSubmissionStatus.PENDING;
    final isLocked = status == ReportSubmissionStatus.COMPLETED;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Report Submission',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.submission != null && !isLocked)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _submitting ? null : _deleteSubmission,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            _buildDetailsCard(),
            const SizedBox(height: 32),

            if (isLocked)
              _buildLockedAlert()
            else ...[
              _buildLabel('Submission Notes'),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add any notes for the team leader...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Upload Document'),
              const SizedBox(height: 12),
              _buildFilePicker(),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.submission == null
                              ? 'Submit Report'
                              : 'Update Submission',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.request.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.request.description ?? 'No specific instructions provided.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Divider(height: 32, color: AppColors.divider),
          _buildDetailRow(
            Icons.person_outline,
            'Assigned By',
            widget.request.assignedBy?['role'] == 'ADMIN'
                ? 'Admin'
                : (widget.request.assignedBy?['name'] ?? 'Team Leader'),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_month_outlined,
            'Deadline',
            widget.request.deadline != null
                ? DateFormat(
                    'MMM dd, yyyy',
                  ).format(DateTime.parse(widget.request.deadline!))
                : 'Open',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.file_copy_outlined,
            'Formats',
            widget.request.allowedFormats.join(', '),
          ),

          if (widget.submission?.status == ReportSubmissionStatus.REDO &&
              widget.submission?.reviewerNotes != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        color: AppColors.error,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'REVISION REQUESTED',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.submission!.reviewerNotes!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null
                  ? Icons.check_circle
                  : Icons.cloud_upload_outlined,
              size: 48,
              color: _selectedFile != null
                  ? AppColors.success
                  : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile?.name ??
                  (_uploadUrl != null
                      ? 'Update existing file'
                      : 'Tap to select document'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _selectedFile != null
                    ? Colors.white
                    : AppColors.textMuted,
                fontWeight: _selectedFile != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 4),
              Text(
                '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
            if (_uploadUrl != null && _selectedFile == null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _openPreview(_uploadUrl!),
                    icon: const Icon(Icons.preview_outlined, size: 14),
                    label: const Text(
                      'Preview',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _downloadOriginal(_uploadUrl!),
                    icon: const Icon(Icons.download_outlined, size: 14),
                    label: const Text(
                      'Download',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockedAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_person_outlined,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Submission Approved',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This report has been reviewed and marked as completed. You can no longer edit this submission.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_uploadUrl != null)
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openPreview(_uploadUrl!),
                  icon: const Icon(Icons.remove_red_eye_outlined),
                  label: const Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success.withAlpha(50),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _downloadOriginal(_uploadUrl!),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download Original'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success.withAlpha(50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}
