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
import '../modals/assessment_details_modal.dart';
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

  bool _isCustomizingAssessments = false;
  List<AssessmentFolderModel> _editableFolders = [];

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
      builder: (ctx) => AssessmentDetailsModal(
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
          final newFolder = await context
              .read<AssessmentProvider>()
              .createFolder(name, colorHex);
          setState(() {
            if (_isCustomizingAssessments) {
              _editableFolders.add(newFolder);
            }
            _activeFilter = newFolder.id;
          });
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
          setState(() {
            if (_isCustomizingAssessments) {
              final idx = _editableFolders.indexWhere((f) => f.id == folderId);
              if (idx != -1) {
                _editableFolders[idx] = _editableFolders[idx].copyWith(
                  name: name,
                  colorHex: colorHex,
                );
              }
            }
          });
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
                      canManage: canManage,
                      isCustomizing: _isCustomizingAssessments,
                      onManageTap: canManage
                          ? () => context.push('/grading')
                          : null,
                      onCustomizingToggle: canManage
                          ? () {
                              final provider = context
                                  .read<AssessmentProvider>();
                              setState(() {
                                if (_isCustomizingAssessments) {
                                  _isCustomizingAssessments = false;
                                  provider.reorderFolders(_editableFolders);
                                } else {
                                  _isCustomizingAssessments = true;
                                  _editableFolders = List.from(
                                    provider.folders,
                                  );
                                }
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Folder Tab Bar ──
                    _FolderTabBar(
                      activeFilter: _activeFilter,
                      iconTypes: assessmentProvider.assessmentIconTypes,
                      folders: _isCustomizingAssessments
                          ? _editableFolders
                          : assessmentProvider.folders,
                      canManage: canManage,
                      isEditing: _isCustomizingAssessments,
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
                        setState(() {
                          if (_isCustomizingAssessments) {
                            _editableFolders.removeWhere(
                              (f) => f.id == folderId,
                            );
                          }
                          if (_activeFilter == folderId) {
                            _activeFilter = 'all';
                          }
                        });
                        await CenterToast.show(
                          context,
                          message: 'Folder deleted',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        );
                      },
                      onReorderFolders: (oldIndex, newIndex) {
                        setState(() {
                          final item = _editableFolders.removeAt(oldIndex);
                          _editableFolders.insert(newIndex, item);
                        });
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _activeFilter == 'all'
                                  ? 'All Assessments'
                                  : '${filteredAssessments.length} assessment${filteredAssessments.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B3B22),
                              ),
                            ),
                            if (_isCustomizingAssessments)
                              GestureDetector(
                                onTap: () => assessmentProvider
                                    .sortAssessmentsAlphabetically(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Sort (A-Z)',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
    required this.isEditing,
    required this.onFilterChanged,
    required this.onCreateFolder,
    required this.onEditFolder,
    required this.onDeleteFolder,
    required this.onReorderFolders,
  });

  final String activeFilter;
  final List<String> iconTypes;
  final List<AssessmentFolderModel> folders;
  final bool canManage;
  final bool isEditing;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onCreateFolder;
  final ValueChanged<String> onEditFolder;
  final ValueChanged<String> onDeleteFolder;
  final void Function(int, int)? onReorderFolders;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return SizedBox(
        height: 44,
        child: ReorderableListView(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: child,
                );
              },
          onReorder: (oldIndex, newIndex) {
            if (oldIndex == 0 || oldIndex == folders.length + 1) return;
            if (newIndex <= 1) newIndex = 1;
            if (newIndex > folders.length + 1) newIndex = folders.length + 1;
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            onReorderFolders?.call(oldIndex - 1, newIndex - 1);
          },
          children: [
            Padding(
              key: const ValueKey('filter_all'),
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: 'All',
                icon: Icons.dashboard_rounded,
                isActive: activeFilter == 'all' && !isEditing,
                onTap: () => onFilterChanged('all'),
              ),
            ),
            for (int i = 0; i < folders.length; i++)
              ReorderableDelayedDragStartListener(
                key: ValueKey('folder_${folders[i].id}'),
                index: i + 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _EditableFolderChip(
                    folder: folders[i],
                    onDelete: () => onDeleteFolder(folders[i].id),
                    onRename: () => onEditFolder(folders[i].id),
                  ),
                ),
              ),
            if (canManage)
              Padding(
                key: const ValueKey('new_folder_btn'),
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: onCreateFolder,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'New Folder',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
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
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _EditableFolderChip extends StatelessWidget {
  const _EditableFolderChip({
    required this.folder,
    required this.onDelete,
    required this.onRename,
  });

  final AssessmentFolderModel folder;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final color = assessmentColorFromHex(folder.colorHex);
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5DDD8), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Color dot ──
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),

          // ── Label ──
          Text(
            folder.name,
            style: const TextStyle(
              color: Color(0xFF3A5240),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),

          // ── Edit (pencil) icon ──
          GestureDetector(
            onTap: onRename,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.secondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // ── Delete icon ──
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE25B4C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
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
    required this.canManage,
    required this.isCustomizing,
    this.onManageTap,
    this.onCustomizingToggle,
  });

  final int total;
  final bool canManage;
  final bool isCustomizing;
  final VoidCallback? onManageTap;
  final VoidCallback? onCustomizingToggle;

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
                  'Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total items',
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
          if (canManage) const SizedBox(width: 8),
          if (canManage)
            GestureDetector(
              onTap: onCustomizingToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
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
                child: Text(
                  isCustomizing ? 'Done' : 'Custom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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
