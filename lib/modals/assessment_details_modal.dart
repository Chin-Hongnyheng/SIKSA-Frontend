import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/assessment_model.dart';
import '../models/assessment_folder_model.dart';
import '../providers/assessment_provider.dart';
import '../widgets/center_toast.dart';
import '../modals/create_assessment_modal.dart';

// ═══════════════════════════════════════════════════════════════
//  Details Header Helper
// ═══════════════════════════════════════════════════════════════

String getDetailsHeader(String? iconKey) {
  switch (iconKey?.toLowerCase()) {
    case 'lab':
      return 'Lab Instructions';
    case 'midterm':
    case 'final':
      return 'Exam Details';
    case 'quiz':
      return 'Quiz Instructions';
    case 'assignment':
      return 'Assignment Guidelines';
    case 'project':
      return 'Project Guidelines';
    case 'presentation':
      return 'Presentation Guidelines';
    default:
      return 'Instructions & Details';
  }
}

// ═══════════════════════════════════════════════════════════════
//  Assessment Details Sheet (with Move to Folder)
// ═══════════════════════════════════════════════════════════════

class AssessmentDetailsModal extends StatelessWidget {
  const AssessmentDetailsModal({
    super.key,
    required this.assessment,
    required this.canManage,
    this.onDelete,
  });

  final AssessmentModel assessment;
  final bool canManage;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final title = assessment.assessmentName.trim();
    final courseCode = assessment.courseCode.trim();
    final guide = assessment.guide?.trim();
    final createdAt = DateTime.tryParse(assessment.createdAt ?? '');
    final dateLabel = createdAt == null
        ? '--'
        : DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());

    final accentColor = assessmentColorFromHex(assessment.color);
    final iconData = assessmentIconFromKey(assessment.icon);
    final hasImage =
        assessment.imageBase64 != null && assessment.imageBase64!.isNotEmpty;

    final currentFolder = provider.getFolderForAssessment(
      assessment.courseCode,
      assessment.assessmentName,
    );

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Header: Icon + Title ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: accentColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isNotEmpty ? title : 'Untitled assessment',
                          style: const TextStyle(
                            color: Color(0xFF1F2D22),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          courseCode.isNotEmpty
                              ? 'Course: $courseCode'
                              : 'Course not set',
                          style: const TextStyle(
                            color: Color(0xFF607064),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Image ──
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(assessment.imageBase64!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ── Created date ──
              _DetailRow(
                icon: Icons.event_outlined,
                label: 'Created',
                value: dateLabel,
                accentColor: accentColor,
              ),

              // ── Current folder badge ──
              if (currentFolder != null) ...[
                const SizedBox(height: 4),
                _DetailRow(
                  icon: Icons.folder_rounded,
                  label: 'Folder',
                  value: currentFolder.name,
                  accentColor: assessmentColorFromHex(currentFolder.colorHex),
                ),
              ],

              const SizedBox(height: 18),

              // ── Dynamic Header based on Type ──
              Text(
                getDetailsHeader(assessment.icon),
                style: const TextStyle(
                  color: Color(0xFF1B3B22),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (guide != null && guide.isNotEmpty)
                MarkdownBody(
                  data: guide,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: Color(0xFF4F5F55),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                    h1: TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    h2: TextStyle(
                      color: accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    strong: const TextStyle(
                      color: Color(0xFF1B3B22),
                      fontWeight: FontWeight.w800,
                    ),
                    em: const TextStyle(
                      color: Color(0xFF607064),
                      fontStyle: FontStyle.italic,
                    ),
                    listBullet: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Text(
                  'No information has been added for this assessment yet.',
                  style: TextStyle(
                    color: Color(0xFF4F5F55),
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              // ── Move to Folder button ──
              if (canManage && provider.folders.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showFolderPicker(context, provider),
                    icon: const Icon(Icons.drive_file_move_rounded),
                    label: Text(
                      currentFolder != null
                          ? 'Move to Folder (${currentFolder.name})'
                          : 'Move to Folder',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // ── Delete button ──
              if (canManage && onDelete != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text(
                      'Delete Assessment',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      overlayColor: Colors.red.withOpacity(0.08),
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context, AssessmentProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FolderPickerSheet(
        folders: provider.folders,
        currentFolderId: provider
            .getFolderForAssessment(
              assessment.courseCode,
              assessment.assessmentName,
            )
            ?.id,
        onSelect: (folderId) async {
          if (folderId == null) {
            await provider.removeFromFolder(
              assessment.courseCode,
              assessment.assessmentName,
            );
            await CenterToast.show(
              context,
              message: 'Removed from folder',
              icon: Icons.folder_off_rounded,
              color: Colors.orange,
            );
          } else {
            await provider.addToFolder(
              folderId,
              assessment.courseCode,
              assessment.assessmentName,
            );
            final folderName = provider.folders
                .firstWhere((f) => f.id == folderId)
                .name;
            await CenterToast.show(
              context,
              message: 'Moved to "$folderName"',
              icon: Icons.folder_rounded,
              color: AppColors.primary,
            );
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Folder Picker Sheet
// ═══════════════════════════════════════════════════════════════

class _FolderPickerSheet extends StatelessWidget {
  const _FolderPickerSheet({
    required this.folders,
    required this.currentFolderId,
    required this.onSelect,
  });

  final List<AssessmentFolderModel> folders;
  final String? currentFolderId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Move to Folder',
              style: TextStyle(
                color: Color(0xFF1B3B22),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a folder or remove from current folder',
              style: TextStyle(
                color: Color(0xFF607064),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // ── "Remove from folder" option ──
            if (currentFolderId != null) ...[
              _FolderOption(
                name: 'Remove from folder',
                color: Colors.red,
                icon: Icons.folder_off_rounded,
                isSelected: false,
                onTap: () => onSelect(null),
              ),
              const SizedBox(height: 8),
              Divider(color: const Color(0xFFE5ECE7), height: 1),
              const SizedBox(height: 8),
            ],

            // ── Folder options ──
            ...folders.map(
              (folder) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _FolderOption(
                  name: folder.name,
                  color: assessmentColorFromHex(folder.colorHex),
                  icon: Icons.folder_rounded,
                  isSelected: folder.id == currentFolderId,
                  onTap: () => onSelect(folder.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderOption extends StatelessWidget {
  const _FolderOption({
    required this.name,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5ECE7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: color == Colors.red
                      ? Colors.red
                      : const Color(0xFF1B3B22),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Detail Row
// ═══════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF77887D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF26382C),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
