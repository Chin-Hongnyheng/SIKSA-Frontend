// ignore_for_file: unused_local_variable, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/assessment_model.dart';
import '../models/assessment_folder_model.dart';
import '../modals/create_assessment_modal.dart';
import '../modals/create_folder_modal.dart';
import '../providers/assessment_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';
import '../widgets/loading.dart';

// ═══════════════════════════════════════════════════════════════
//  Main Screen
// ═══════════════════════════════════════════════════════════════

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  /// Active filter tab: 'all', a type key like 'lab', or a folder id.
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<AssessmentProvider>();
      p.loadAllAssessments();
      p.loadFolders();
    });
  }

  // ── Create Assessment ──

  Future<void> _openCreateModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateAssessmentModal(
        onCreate:
            (
              course,
              name,
              guide, {
              String? icon,
              String? color,
              String? imageBase64,
            }) async {
              LoadingOverlay.show(context);
              try {
                await context.read<AssessmentProvider>().createAssessment(
                  courseCode: course,
                  assessmentName: name,
                  guide: guide,
                  icon: icon,
                  color: color,
                  imageBase64: imageBase64,
                );
                await CenterToast.show(
                  context,
                  message: 'Assessment created',
                  icon: Icons.check_circle,
                  color: Colors.green,
                );
              } catch (e) {
                await CenterToast.show(
                  context,
                  message: _toReadableError(e.toString()),
                  icon: Icons.error,
                  color: Colors.red,
                );
              } finally {
                LoadingOverlay.hide();
              }
            },
      ),
    );
  }

  // ── Delete Assessment ──

  Future<void> _deleteAssessment(
    String courseCode,
    String assessmentName,
  ) async {
    final confirmed = await _showDeleteConfirmOverlay(
      courseCode,
      assessmentName,
    );

    if (!confirmed) return;

    LoadingOverlay.show(context);
    try {
      await context.read<AssessmentProvider>().deleteAssessment(
        courseCode: courseCode,
        assessmentName: assessmentName,
      );
      await CenterToast.show(
        context,
        message: 'Assessment deleted',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      await CenterToast.show(
        context,
        message: _toReadableError(e.toString()),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<bool> _showDeleteConfirmOverlay(
    String courseCode,
    String assessmentName,
  ) async {
    final completer = Completer<bool>();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delete Assessment',
                  style: TextStyle(
                    color: Color(0xFF1B3B22),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "$assessmentName" for $courseCode?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF607064),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          entry.remove();
                          completer.complete(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5ECE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF4F5F55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          entry.remove();
                          completer.complete(true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }

  Future<bool> _showDeleteFolderConfirmOverlay(String folderName) async {
    final completer = Completer<bool>();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delete Folder',
                  style: TextStyle(
                    color: Color(0xFF1B3B22),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete the "$folderName" folder?\nAssessments inside will not be deleted.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF607064),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          entry.remove();
                          completer.complete(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5ECE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF4F5F55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          entry.remove();
                          completer.complete(true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }

  // ── View Details ──

  void _showAssessmentDetails(AssessmentModel assessment) {
    final user = context.read<UserProvider>().user;
    final role = user?.role ?? 'Unknown';
    final canManage = role == 'Teacher' || role == 'Admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssessmentDetailsSheet(
        assessment: assessment,
        canManage: canManage,
        onDelete: () =>
            _deleteAssessment(assessment.courseCode, assessment.assessmentName),
      ),
    );
  }

  // ── Create Folder ──

  Future<void> _openCreateFolderModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateFolderModal(
        onSave: (name, colorHex) async {
          await context.read<AssessmentProvider>().createFolder(name, colorHex);
          await CenterToast.show(
            context,
            message: 'Folder "$name" created',
            icon: Icons.create_new_folder_rounded,
            color: AppColors.primary,
          );
        },
      ),
    );
  }

  Future<void> _openEditFolderModal(String folderId) async {
    final provider = context.read<AssessmentProvider>();
    final folder = provider.folders.firstWhere((f) => f.id == folderId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateFolderModal(
        initialName: folder.name,
        initialColorHex: folder.colorHex,
        onSave: (name, colorHex) async {
          await provider.updateFolder(folderId, name, colorHex);
          await CenterToast.show(
            context,
            message: 'Folder "$name" updated',
            icon: Icons.check_circle_rounded,
            color: AppColors.primary,
          );
        },
      ),
    );
  }

  // ── Filtering Logic ──

  List<AssessmentModel> _filterAssessments(
    List<AssessmentModel> all,
    AssessmentProvider provider,
  ) {
    if (_activeFilter == 'all') return all;

    // Check if it's a type filter (icon key)
    final iconTypes = provider.assessmentIconTypes;
    if (iconTypes.contains(_activeFilter)) {
      return all.where((a) => a.icon == _activeFilter).toList();
    }

    // Otherwise it's a folder id
    final folder = provider.folders.where((f) => f.id == _activeFilter);
    if (folder.isEmpty) return all;

    return all
        .where(
          (a) =>
              folder.first.containsAssessment(a.courseCode, a.assessmentName),
        )
        .toList();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final assessmentProvider = context.watch<AssessmentProvider>();
    final user = context.watch<UserProvider>().user;
    final assessments = assessmentProvider.allAssessments;
    final role = user?.role ?? 'Unknown';
    final canManage = role == 'Teacher' || role == 'Admin';

    final filteredAssessments = _filterAssessments(
      assessments,
      assessmentProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreateModal,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Assessment'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _AssessmentsHeader(
              title: 'Assessments',
              subtitle: canManage ? 'Teacher workspace' : 'Student workspace',
              onBackTap: () => context.pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<AssessmentProvider>().loadAllAssessments(),
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    _SummaryCard(
                      total: assessments.length,
                      role: role,
                      canManage: canManage,
                      onManageTap: canManage
                          ? () => context.push('/grading')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Folder Tab Bar ──
                    _FolderTabBar(
                      activeFilter: _activeFilter,
                      iconTypes: assessmentProvider.assessmentIconTypes,
                      folders: assessmentProvider.folders,
                      canManage: canManage,
                      onFilterChanged: (filter) {
                        setState(() => _activeFilter = filter);
                      },
                      onCreateFolder: _openCreateFolderModal,
                      onEditFolder: _openEditFolderModal,
                      onDeleteFolder: (folderId) async {
                        final folder = assessmentProvider.folders.firstWhere(
                          (f) => f.id == folderId,
                        );
                        final confirmed = await _showDeleteFolderConfirmOverlay(
                          folder.name,
                        );
                        if (!confirmed) return;

                        await assessmentProvider.deleteFolder(folderId);
                        if (_activeFilter == folderId) {
                          setState(() => _activeFilter = 'all');
                        }
                        await CenterToast.show(
                          context,
                          message: 'Folder deleted',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    if (assessmentProvider.isLoading && assessments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (assessmentProvider.error != null &&
                        assessmentProvider.error!.isNotEmpty)
                      _StatusCard(
                        icon: Icons.info_outline_rounded,
                        title: 'Unable to display assessments',
                        message: _toReadableError(assessmentProvider.error!),
                        actionLabel: 'Try again',
                        onActionTap: () => context
                            .read<AssessmentProvider>()
                            .loadAllAssessments(),
                      )
                    else if (assessments.isEmpty)
                      _StatusCard(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'No assessments yet',
                        message: canManage
                            ? 'Create an assessment so students can view it here.'
                            : 'No assessments are available for your courses yet.',
                        actionLabel: canManage
                            ? 'Create assessment'
                            : 'Refresh',
                        onActionTap: canManage
                            ? _openCreateModal
                            : () => context
                                  .read<AssessmentProvider>()
                                  .loadAllAssessments(),
                      )
                    else if (filteredAssessments.isEmpty)
                      _StatusCard(
                        icon: Icons.folder_open_rounded,
                        title: 'No assessments here',
                        message:
                            'This folder is empty. Move assessments here from their details.',
                        actionLabel: 'Show All',
                        onActionTap: () {
                          setState(() => _activeFilter = 'all');
                        },
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _activeFilter == 'all'
                              ? 'All Assessments'
                              : '${filteredAssessments.length} assessment${filteredAssessments.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B3B22),
                          ),
                        ),
                      ),
                      ...filteredAssessments.map(
                        (assessment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AssessmentCard(
                            assessment: assessment,
                            canManage: canManage,
                            onTap: () => _showAssessmentDetails(assessment),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Folder Tab Bar
// ═══════════════════════════════════════════════════════════════

class _FolderTabBar extends StatelessWidget {
  const _FolderTabBar({
    required this.activeFilter,
    required this.iconTypes,
    required this.folders,
    required this.canManage,
    required this.onFilterChanged,
    required this.onCreateFolder,
    required this.onEditFolder,
    required this.onDeleteFolder,
  });

  final String activeFilter;
  final List<String> iconTypes;
  final List<AssessmentFolderModel> folders;
  final bool canManage;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onCreateFolder;
  final ValueChanged<String> onEditFolder;
  final ValueChanged<String> onDeleteFolder;

  String _iconLabel(String key) {
    switch (key) {
      case 'lab':
        return 'Lab';
      case 'midterm':
        return 'Midterm';
      case 'quiz':
        return 'Quiz';
      case 'final':
        return 'Final';
      case 'assignment':
        return 'Assignment';
      case 'project':
        return 'Project';
      case 'presentation':
        return 'Presentation';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  IconData _iconDataFor(String key) {
    return assessmentIconFromKey(key);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // ── "All" chip ──
          _FilterChip(
            label: 'All',
            icon: Icons.dashboard_rounded,
            isActive: activeFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          const SizedBox(width: 8),

          // ── Custom folder chips ──
          ...folders.map(
            (folder) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: folder.name,
                colorDot: assessmentColorFromHex(folder.colorHex),
                isActive: activeFilter == folder.id,
                fillActiveBackground: false,
                onTap: () => onFilterChanged(folder.id),
                onEditTap: canManage && activeFilter == folder.id
                    ? () => onEditFolder(folder.id)
                    : null,
                onDeleteTap: canManage && activeFilter == folder.id
                    ? () => onDeleteFolder(folder.id)
                    : null,
              ),
            ),
          ),

          // ── "+" add folder button ──
          if (canManage)
            GestureDetector(
              onTap: onCreateFolder,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    this.colorDot,
    required this.isActive,
    this.fillActiveBackground = true,
    required this.onTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  final String label;
  final IconData? icon;
  final Color? colorDot;
  final bool isActive;
  final bool fillActiveBackground;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive && fillActiveBackground
              ? AppColors.secondary
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.secondary : const Color(0xFFD5DDD8),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (colorDot != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive && fillActiveBackground
                    ? Colors.white
                    : const Color(0xFF77887D),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive && fillActiveBackground
                    ? Colors.white
                    : const Color(0xFF3A5240),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onEditTap != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEditTap,
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: isActive && fillActiveBackground
                      ? Colors.white70
                      : AppColors.secondary,
                ),
              ),
            ],
            if (onDeleteTap != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeleteTap,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Header
// ═══════════════════════════════════════════════════════════════

class _AssessmentsHeader extends StatelessWidget {
  const _AssessmentsHeader({
    required this.title,
    required this.subtitle,
    required this.onBackTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.secondary,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        16,
        18,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color.fromARGB(210, 255, 255, 255),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Helper
// ═══════════════════════════════════════════════════════════════

String _toReadableError(String rawError) {
  if (rawError.contains('SESSION_EXPIRED')) {
    return 'Your session has expired. Please log in again.';
  }
  if (rawError.contains('Forbidden') || rawError.contains('forbidden')) {
    return 'Your account does not have permission for this assessment action.';
  }
  if (rawError.contains('You must be logged in')) {
    return 'Your session has expired. Please log in again.';
  }
  return rawError.replaceFirst('Exception: ', '');
}

// ═══════════════════════════════════════════════════════════════
//  Summary Card
// ═══════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.role,
    required this.canManage,
    this.onManageTap,
  });

  final int total;
  final String role;
  final bool canManage;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assessment Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total items - Role: $role',
                  style: const TextStyle(
                    color: Color(0xFFE5F3E7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (canManage)
            GestureDetector(
              onTap: onManageTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grading_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Manage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Status Card
// ═══════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F3525),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF607064),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onActionTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _AssessmentDetailsSheet extends StatelessWidget {
  const _AssessmentDetailsSheet({
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
              if (canManage) ...[
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

// ═══════════════════════════════════════════════════════════════
//  Assessment Card
// ═══════════════════════════════════════════════════════════════

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({
    required this.assessment,
    required this.canManage,
    required this.onTap,
  });

  final AssessmentModel assessment;
  final bool canManage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = assessment.assessmentName.trim();
    final courseCode = assessment.courseCode.trim();
    final createdAt = DateTime.tryParse(assessment.createdAt ?? '');
    final dateLabel = createdAt == null
        ? '--'
        : DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());

    final guide = assessment.guide?.trim() ?? '';
    final accentColor = assessmentColorFromHex(assessment.color);
    final iconData = assessmentIconFromKey(assessment.icon);
    final hasImage =
        assessment.imageBase64 != null && assessment.imageBase64!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5ECE7)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Color accent bar ──
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // ── Card body ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: accentColor, size: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isNotEmpty
                                    ? title
                                    : 'Untitled assessment',
                                style: const TextStyle(
                                  color: Color(0xFF1F2D22),
                                  fontSize: 18,
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Created: $dateLabel',
                                style: const TextStyle(
                                  color: Color(0xFF77887D),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasImage)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(assessment.imageBase64!),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF98A49C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
