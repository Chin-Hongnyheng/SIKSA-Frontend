// ignore_for_file: unused_element_parameter, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/modals/schedule_modal.dart';
import 'package:frontend/providers/schedule_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';
import '../widgets/floating_line_background.dart';
import '../widgets/selected_card.dart';

const int _kTeachingTab = 0;
const int _kEnrolledTab = 1;

/// Controls which set of tabs/content the CoursesScreen shows.
enum CourseScreenMode {
  /// Shows "Teaching" + "Enrolled" tabs only.
  my,

  /// Shows the "Discover" list only, no tab bar.
  discover,
}

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({
    super.key,
    this.showSearch = true,
    CourseScreenMode? mode,
  }) : mode = mode ?? CourseScreenMode.my;

  final bool showSearch;
  final CourseScreenMode mode;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  bool get _isMyMode => widget.mode == CourseScreenMode.my;

  @override
  void initState() {
    super.initState();
    if (_isMyMode) {
      _tabController = TabController(length: 2, vsync: this);
    }
    Future.microtask(_loadAll);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _readableError(String value) => value.replaceAll('Exception: ', '');

  Future<void> _loadAll() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.user == null) await userProvider.loadUser();
    if (!mounted) return;
    await context.read<CourseProvider>().loadCourses();
    await context.read<CourseProvider>().loadAllCourses();
  }

  Future<void> _loadAllCourses() async {
    if (!mounted) return;
    await context.read<CourseProvider>().loadCourses();
    await context.read<CourseProvider>().loadAllCourses();
  }

  void _openCreateModal() {
    showCreateScheduleModal(
      context,
      onSubmit: (_) async {
        await context.read<ScheduleProvider>().loadSchedules();
        await context.read<CourseProvider>().loadCourses();
        await context.read<CourseProvider>().loadAllCourses();
      },
    );
  }

  List<CourseModel> _filtered(List<CourseModel> courses) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return courses;
    return courses.where((c) {
      return c.courseName.toLowerCase().contains(query) ||
          c.courseCode.toLowerCase().contains(query) ||
          (c.description ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openCourseEditor({required CourseModel course}) async {
    final scheduleProvider = context.read<ScheduleProvider>();

    final ScheduleModel? existing = scheduleProvider.schedules
        .where((s) => s.courseCode == course.courseCode)
        .firstOrNull;

    await showCreateScheduleModal(
      context,
      title: 'Edit Course',
      scheduleId: existing?.scheduleId,
      initialData: {
        'courseCode': course.courseCode,
        'courseName': course.courseName,
        'description': course.description ?? '',
        'location': existing?.location ?? '',
        'startTime': existing?.startTime ?? '',
        'endTime': existing?.endTime ?? '',
      },
      onSubmit: (_) async {
        if (!mounted) return;
        await scheduleProvider.loadSchedules();
        await context.read<CourseProvider>().loadCourses();
        await context.read<CourseProvider>().loadAllCourses();
      },
    );
  }

  Future<void> _deleteCourse(CourseModel course) async {
    final confirmed = await _showDeleteConfirmOverlay(course);
    if (!confirmed || !mounted) return;

    try {
      await context.read<CourseProvider>().deleteCourse(
        courseCode: course.courseCode,
      );
      if (!mounted) return;
      await context.read<ScheduleProvider>().loadSchedules();
      await CenterToast.show(
        context,
        message: 'Course deleted',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      await CenterToast.show(
        context,
        message: _readableError(e.toString()),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<bool> _showDeleteConfirmOverlay(CourseModel course) async {
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
                  'Delete Course',
                  style: TextStyle(
                    color: Color(0xFF1B3B22),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${course.courseCode}"?\nThis will also remove all related schedules.',
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

  Future<void> _subscribeCourse(CourseModel course) async {
    try {
      await context.read<CourseProvider>().subscribeCourse(
        courseCode: course.courseCode,
      );
      if (!mounted) return;
      await CenterToast.show(
        context,
        message: 'Subscribed',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      await CenterToast.show(
        context,
        message: _readableError(e.toString()),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  void _openCourseDetails(CourseModel course, {required bool canManage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CourseDetailsSheet(course: course, canManage: canManage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final courseProvider = context.watch<CourseProvider>();
    final user = context.watch<UserProvider>().user;
    final currentUserName = user?.userName;

    final isLoading =
        courseProvider.isLoadingAll && courseProvider.allCourses.isEmpty;
    final error = courseProvider.errorAll;

    final teachingCourses = _filtered(
      courseProvider.allCourses
          .where((c) => c.createdBy == currentUserName)
          .toList(),
    );

    final enrolledCourses = _filtered(
      courseProvider.allCourses
          .where((c) => c.isSubscribed && c.createdBy != currentUserName)
          .toList(),
    );

    final discoverCourses = _filtered(
      courseProvider.allCourses
          .where((c) => c.createdBy != currentUserName)
          .toList(),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isMyMode
          ? FloatingActionButton(
              onPressed: _openCreateModal,
              backgroundColor: AppColors.primary,
              tooltip: 'Create Course',
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: Stack(
        children: [
          // ── Animated green background ──────────────────────────────────
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),

          // ── White body panel ───────────────────────────────────────────
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  // ── Search field (Discover mode only) ───────────────────
                  if (widget.showSearch && !_isMyMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _CourseSearchField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchText = value),
                      ),
                    ),

                  // ── Tab bar (My Courses mode only) ──────────────────────
                  if (_isMyMode) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.primary,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Text('Teaching'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_stories_outlined, size: 16),
                                  SizedBox(width: 4),
                                  Text('Enrolled'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const SizedBox(height: 16),

                  // ── Content ──────────────────────────────────────────────
                  Expanded(
                    child: _isMyMode
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              _CourseTabView(
                                courses: teachingCourses,
                                isLoading: isLoading,
                                error: error,
                                emptyTitle: _searchText.trim().isEmpty
                                    ? 'No courses created'
                                    : 'No matching courses',
                                emptyMessage:
                                    'Create a course to make it available here.',
                                emptyActionLabel: 'Create course',
                                onEmptyAction: _openCreateModal,
                                onRetry: _loadAllCourses,
                                readableError: _readableError,
                                itemBuilder: (course) => _CourseListCard(
                                  course: course,
                                  canManage: true,
                                  showSubscribeButton: false,
                                  onTap: () => _openCourseDetails(
                                    course,
                                    canManage: true,
                                  ),
                                  onEdit: () =>
                                      _openCourseEditor(course: course),
                                  onDelete: () => _deleteCourse(course),
                                  onSubscribe: () => _subscribeCourse(course),
                                ),
                              ),
                              _CourseTabView(
                                courses: enrolledCourses,
                                isLoading: isLoading,
                                error: error,
                                emptyTitle: _searchText.trim().isEmpty
                                    ? 'Not enrolled in any courses'
                                    : 'No matching enrolled courses',
                                emptyMessage:
                                    'Subscribe to a course in Discover to see it here.',
                                emptyActionLabel: 'Discover courses',
                                onEmptyAction: () =>
                                    context.push('/courses/discover'),
                                onRetry: _loadAllCourses,
                                readableError: _readableError,
                                itemBuilder: (course) => _CourseListCard(
                                  course: course,
                                  canManage: false,
                                  showSubscribeButton: false,
                                  onTap: () => _openCourseDetails(
                                    course,
                                    canManage: false,
                                  ),
                                  onEdit: () {},
                                  onDelete: () {},
                                  onSubscribe: () => _subscribeCourse(course),
                                ),
                              ),
                            ],
                          )
                        : _CourseTabView(
                            courses: discoverCourses,
                            isLoading: isLoading,
                            error: error,
                            emptyTitle: _searchText.trim().isEmpty
                                ? 'No courses available'
                                : 'No matching courses',
                            emptyMessage:
                                'Courses created by other users will appear here.',
                            emptyActionLabel: 'Refresh',
                            onEmptyAction: _loadAllCourses,
                            onRetry: _loadAllCourses,
                            readableError: _readableError,
                            itemBuilder: (course) => _CourseListCard(
                              course: course,
                              canManage: false,
                              showSubscribeButton: true,
                              onTap: () =>
                                  _openCourseDetails(course, canManage: false),
                              onEdit: () {},
                              onDelete: () {},
                              onSubscribe: () => _subscribeCourse(course),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top header (floats over the green background) ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        _isMyMode ? 'My Courses' : 'Discover Courses',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable tab content
// ─────────────────────────────────────────────────────────────────────────────

class _CourseTabView extends StatelessWidget {
  const _CourseTabView({
    required this.courses,
    required this.isLoading,
    required this.error,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyActionLabel,
    required this.onEmptyAction,
    required this.onRetry,
    required this.readableError,
    required this.itemBuilder,
  });

  final List<CourseModel> courses;
  final bool isLoading;
  final String? error;
  final String emptyTitle;
  final String emptyMessage;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;
  final VoidCallback onRetry;
  final String Function(String) readableError;
  final Widget Function(CourseModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (error != null && error!.isNotEmpty) {
      return _StatusPanel(
        icon: Icons.info_outline_rounded,
        title: 'Unable to display courses',
        message: readableError(error!),
        actionLabel: 'Try again',
        onActionTap: onRetry,
      );
    }
    if (courses.isEmpty) {
      return _StatusPanel(
        icon: Icons.menu_book_outlined,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onActionTap: onEmptyAction,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRetry(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        itemCount: courses.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: itemBuilder(courses[index]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class _CourseSearchField extends StatelessWidget {
  const _CourseSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search courses',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF4F7F4),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course list card
// ─────────────────────────────────────────────────────────────────────────────

class _CourseListCard extends StatelessWidget {
  const _CourseListCard({
    required this.course,
    required this.canManage,
    required this.showSubscribeButton,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSubscribe,
  });

  final CourseModel course;
  final bool canManage;
  final bool showSubscribeButton;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final description = course.description?.trim();
    final hasImage = course.courseImg != null && course.courseImg!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header image ───────────────────────────────────────
                if (hasImage)
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Image.network(
                      course.courseImg!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withOpacity(0.08),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.primary.withOpacity(0.06),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // ── Card content ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.courseName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1B3B22),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  course.courseCode,
                                  style: const TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canManage)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              tooltip: 'Course actions',
                              onSelected: (value) {
                                if (value == 'edit') onEdit();
                                if (value == 'delete') onDelete();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF718096),
                            ),
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CourseChip(
                            icon: Icons.person_outline_rounded,
                            label: 'Creator ${_creatorName(course.createdBy)}',
                          ),
                          _CourseChip(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(course.createdAt),
                          ),
                          _CourseChip(
                            icon: Icons.groups_outlined,
                            label: '${course.subscriberCount} students',
                          ),
                        ],
                      ),
                      if (showSubscribeButton) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: course.isSubscribed ? null : onSubscribe,
                            icon: Icon(
                              course.isSubscribed
                                  ? Icons.check_circle_outline
                                  : Icons.add_circle_outline,
                            ),
                            label: Text(
                              course.isSubscribed ? 'Subscribed' : 'Subscribe',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: const Color(0xFFE8F1EA),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: AppColors.primary,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(44),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small chip
// ─────────────────────────────────────────────────────────────────────────────

class _CourseChip extends StatelessWidget {
  const _CourseChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseEditorSheet extends StatefulWidget {
  const _CourseEditorSheet({this.course, required this.onSubmit});

  final CourseModel? course;
  final Future<void> Function({
    required String courseName,
    required String courseCode,
    required String? description,
  })
  onSubmit;

  @override
  State<_CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<_CourseEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.course?.courseName ?? '',
    );
    _codeController = TextEditingController(
      text: widget.course?.courseCode ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.course?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      await CenterToast.show(
        context,
        message: 'Course name and code are required',
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        courseName: name,
        courseCode: code,
        description: description.isEmpty ? null : description,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      await CenterToast.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                isEditing ? 'Edit Course' : 'Create Course',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B3B22),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g. Introduction to Programming',
                  hintStyle: TextStyle(color: AppColors.caption),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g. CS101',
                  hintStyle: TextStyle(color: AppColors.caption),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Brief summary of topics and objectives',
                  hintStyle: TextStyle(color: AppColors.caption),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? 'Save Course' : 'Create Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course details bottom sheet
// ─────────────────────────────────────────────────────────────────────────────


class _CourseDetailsSheet extends StatelessWidget {
  const _CourseDetailsSheet({required this.course, required this.canManage});

  final CourseModel course;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    // Adds the device's bottom safe-area inset (home indicator / gesture
    // bar / rounded corners) directly into the sheet's own background so
    // there is no gap showing the page behind it on any phone shape.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        color: Color(0xFF1B3B22),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.courseCode,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ── Course image ──────────────────────────────────────────
          if (course.courseImg != null && course.courseImg!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                course.courseImg!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 160,
                    color: AppColors.primary.withOpacity(0.06),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (course.courseImg != null && course.courseImg!.isNotEmpty)
            const SizedBox(height: 22),

          // ── Teaching side ─────────────────────────────────────────────
          if (canManage) ...[
            SelectedCard(
              icon: Icons.qr_code_rounded,
              iconColor: Colors.teal,
              title: 'QR Code',
              subtitle: 'Get QR code for this course',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/courses/qr',
                  extra: {
                    'courseCode': course.courseCode,
                    'courseName': course.courseName,
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            SelectedCard(
              icon: Icons.assignment_outlined,
              iconColor: Colors.blue,
              title: 'Assessment',
              subtitle: 'Manage assessment for this course',
              onTap: () {
                Navigator.pop(context);
                context.push('/assessment');
              },
            ),
            const SizedBox(height: 12),
            SelectedCard(
              icon: Icons.grade_outlined,
              iconColor: Colors.amber,
              title: 'Grade',
              subtitle: 'Manage grade from this course',
              onTap: () {
                Navigator.pop(context);
                context.push('');
              },
            ),
            const SizedBox(height: 12),
            SelectedCard(
              icon: Icons.fact_check_outlined,
              iconColor: Colors.orange,
              title: 'Attendance',
              subtitle: 'Manage attendance for this course',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/attendance/home',
                  extra: {
                    'courseCode': course.courseCode,
                    'courseName': course.courseName,
                  },
                );
              },
            ),
          ],

          // ── Enrolled side ─────────────────────────────────────────────
          if (!canManage) ...[
            SelectedCard(
              icon: Icons.assignment_outlined,
              iconColor: Colors.blue,
              title: 'Assessment',
              subtitle: 'View assessment for this course',
              onTap: () {
                Navigator.pop(context);
                context.push('/assessment');
              },
            ),
            const SizedBox(height: 12),
            SelectedCard(
              icon: Icons.grade_outlined,
              iconColor: Colors.amber,
              title: 'Grade',
              subtitle: 'View grade from this course',
              onTap: () {
                Navigator.pop(context);
                context.push('');
              },
            ),
            const SizedBox(height: 12),
            SelectedCard(
              icon: Icons.fact_check_outlined,
              iconColor: Colors.yellow,
              title: 'Attendance',
              subtitle: 'View attendance for this course',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/attendance/student/course-report',
                  extra: {
                    'studentId': context.read<UserProvider>().user?.id ?? '',
                    'studentName':
                        context.read<UserProvider>().user?.userName ??
                        'Student',
                    'courseCode': course.courseCode,
                    'courseName': course.courseName,
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            SelectedCard(
              icon: Icons.how_to_reg_rounded,
              iconColor: Colors.orange,
              title: 'Mark Attendance',
              subtitle: 'Mark your own attendance for an active session',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/attendance/mark',
                  extra: {'courseCode': course.courseCode},
                );
              },
            ),
            const SizedBox(height: 12),
            SelectedCard(
              icon: Icons.task_alt_outlined,
              iconColor: Colors.indigo,
              title: 'Tasks',
              subtitle: 'View assigned tasks for this course',
              onTap: () {
                Navigator.pop(context);
                context.push('/tasks'); // change to your route
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status / empty-state panel
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 38),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B3B22),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718096), height: 1.35),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onActionTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _creatorName(String? value) {
  if (value == null || value.isEmpty) return 'Unknown';
  return value;
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) return 'No date';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('MMM d, yyyy').format(parsed.toLocal());
}
