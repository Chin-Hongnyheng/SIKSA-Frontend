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
import '../modals/create_assessment_modal.dart';
import '../providers/assessment_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';
import '../widgets/loading.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AssessmentProvider>().loadAllAssessments(),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final assessmentProvider = context.watch<AssessmentProvider>();
    final user = context.watch<UserProvider>().user;
    final assessments = assessmentProvider.allAssessments;
    final role = user?.role ?? 'Unknown';
    final canManage = role == 'Teacher' || role == 'Admin';

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
                    ),
                    const SizedBox(height: 16),
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
                    else ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Assessments List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B3B22),
                          ),
                        ),
                      ),
                      ...assessments.map(
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.role,
    required this.canManage,
  });

  final int total;
  final String role;
  final bool canManage;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Manage',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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

String getDetailsHeader(String? iconKey) {
  switch (iconKey?.toLowerCase()) {
    case 'lecture':
      return 'Lecture Notes';
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

              // ── Delete button ──
              if (canManage) ...[
                const SizedBox(height: 32),
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
}

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
