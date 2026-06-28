// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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
        onCreate: (course, name) async {
          LoadingOverlay.show(context);
          try {
            await context.read<AssessmentProvider>().createAssessment(
              courseCode: course,
              assessmentName: name,
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
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete assessment'),
            content: Text('Delete "$assessmentName" for $courseCode?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

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

  @override
  Widget build(BuildContext context) {
    final assessmentProvider = context.watch<AssessmentProvider>();
    final user = context.watch<UserProvider>().user;
    final assessments = assessmentProvider.allAssessments;
    final role = user?.role ?? 'Unknown';
    final canManage = role == 'User' || role == 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openCreateModal,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _AssessmentsHeader(onBackTap: () => context.pop()),
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
                          'Assessment List',
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
                            onDelete: () => _deleteAssessment(
                              assessment.courseCode,
                              assessment.assessmentName,
                            ),
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
  const _AssessmentsHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2E7D32),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: onBackTap,
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Assessments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF2A7A39), Color(0xFF1E6B2D)],
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
          FilledButton(
            onPressed: onActionTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
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
    required this.onDelete,
  });

  final AssessmentModel assessment;
  final bool canManage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = assessment.assessmentName.trim();
    final courseCode = assessment.courseCode.trim();
    final createdAt = DateTime.tryParse(assessment.createdAt ?? '');
    final dateLabel = createdAt == null
        ? '--'
        : DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 23,
            ),
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
          if (canManage)
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
        ],
      ),
    );
  }
}
