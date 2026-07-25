// ignore_for_file: unused_element_parameter, deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/modals/schedule_modal.dart';
import 'package:frontend/providers/schedule_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import '../providers/course_provider.dart';
import '../modals/create_assessment_modal.dart' show kAssessmentColors, colorToHex;
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';
import '../widgets/floating_line_background.dart';
import '../widgets/selected_card.dart';
import '../providers/notification_provider.dart';

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

  // Stored reference so dispose() never has to call context.read again.
  NotificationProvider? _notificationProvider;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place for inherited-widget lookups. Only (re)attach if the
    // provider instance actually changed, so we don't double-add listeners.
    final provider = context.read<NotificationProvider>();
    if (!identical(_notificationProvider, provider)) {
      _notificationProvider?.removeListener(_onNotificationReceived);
      _notificationProvider = provider;
      _notificationProvider!.addListener(_onNotificationReceived);
    }
  }

  @override
  void dispose() {
    // Use the stored reference — never touch context/context.read here.
    _notificationProvider?.removeListener(_onNotificationReceived);
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _readableError(String value) => value.replaceAll('Exception: ', '');

  void _onNotificationReceived() {
    if (!mounted) return;
    final messages = _notificationProvider?.messages ?? const [];
    if (messages.isEmpty) return;
    final latest = messages.first;
    if (latest.data?['screen'] == 'courseDetail') {
      _loadAllCourses();
    }
  }

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
        'colorHex': course.colorHex ?? '',
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
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF14231A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Delete Course',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete "${course.courseCode}"?\nThis will also remove all related schedules.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            entry.remove();
                            completer.complete(false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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

  /// Opens the course details sheet.
  ///
  /// [canManage] — true only for courses the current user teaches.
  /// [isEnrolled] — true only for courses the current user is subscribed to.
  /// If neither is true (e.g. browsing Discover without subscribing), the
  /// sheet shows a lightweight preview with a Subscribe CTA instead of the
  /// management/participation actions (QR code, attendance, grades, etc.).
  ///
  /// We capture a stable [rootContext] (this screen's own context) and pass
  /// it into the sheet, so any navigation triggered from inside the sheet
  /// uses a context that's still alive after the sheet itself is popped —
  /// avoiding "Looking up a deactivated widget's ancestor" errors.
  void _openCourseDetails(
    CourseModel course, {
    required bool canManage,
    required bool isEnrolled,
  }) {
    final rootContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CourseDetailsSheet(
        course: course,
        canManage: canManage,
        isEnrolled: isEnrolled,
        onSubscribe: () => _subscribeCourse(course),
        rootContext: rootContext,
      ),
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
          ? FloatingActionButton.extended(
              onPressed: _openCreateModal,
              backgroundColor: AppColors.primary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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

                  // ── Tab bar (My Courses mode only) ──────────────────
                  if (_isMyMode) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF5B6B60),
                          indicator: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          splashBorderRadius: BorderRadius.circular(11),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 17),
                                  SizedBox(width: 5),
                                  Text('Teaching'),
                                ],
                              ),
                            ),
                            Tab(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_stories_outlined, size: 17),
                                  SizedBox(width: 5),
                                  Text('Enrolled'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else
                    const SizedBox(height: 14),

                  // ── Content ────────────────────────────────────────
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
                                emptyIcon: Icons.auto_awesome_rounded,
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
                                    isEnrolled: false,
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
                                emptyIcon: Icons.explore_outlined,
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
                                    isEnrolled: true,
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
                            emptyIcon: Icons.travel_explore_rounded,
                            onEmptyAction: _loadAllCourses,
                            onRetry: _loadAllCourses,
                            readableError: _readableError,
                            itemBuilder: (course) => _CourseListCard(
                              course: course,
                              canManage: false,
                              showSubscribeButton: true,
                              onTap: () => _openCourseDetails(
                                course,
                                canManage: false,
                                isEnrolled: course.isSubscribed,
                              ),
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
                          letterSpacing: 0.2,
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
    required this.emptyIcon,
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
  final IconData emptyIcon;
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
        icon: emptyIcon,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: courses.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
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
      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Search courses',
        hintStyle: const TextStyle(color: Color(0xFF9AA5A0)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9AA5A0)),
        filled: true,
        fillColor: const Color(0xFFF4F7F4),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course list card — Udemy-style layout
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

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF\$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  bool get _isBestseller => course.subscriberCount >= 20;

  @override
  Widget build(BuildContext context) {
    final hasImage = course.courseImg != null && course.courseImg!.isNotEmpty;
    final themeColor = _colorFromHex(course.colorHex);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withOpacity(0.06),
        highlightColor: AppColors.primary.withOpacity(0.03),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFCFEFC)],
            ),
            border: Border.all(color: const Color(0xFFECF1EE)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: hasImage
                          ? Image.network(
                              course.courseImg!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _ImageFallback(courseName: course.courseName),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
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
                            )
                          : _ImageFallback(courseName: course.courseName),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 36,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (canManage)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _FloatingMenuButton(
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ),
                    if (_isBestseller)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Popular',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              Text(
                course.courseName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF16281B),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: const Color(0xFF9AA5A0),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _creatorName(course.createdBy),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 11),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _OutlinedPill(
                    icon: Icons.groups_outlined,
                    label: '${course.subscriberCount} students',
                  ),
                  _OutlinedPill(
                    icon: Icons.vpn_key_outlined,
                    label: course.courseCode,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F3F1)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: const Color(0xFF9AA5A0),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(course.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF9AA5A0),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (showSubscribeButton)
                    _SubscribeButton(
                      isSubscribed: course.isSubscribed,
                      onTap: onSubscribe,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.courseName});
  final String courseName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primary.withOpacity(0.55),
          ],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Icon(
        Icons.menu_book_rounded,
        color: Colors.white.withOpacity(0.9),
        size: 36,
      ),
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  const _OutlinedPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EBE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF4A5568)),
          const SizedBox(width: 4),
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
    required String colorHex,
  })
  onSubmit;

  @override
  State<_CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<_CourseEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  Color _selectedColor = kAssessmentColors.first;
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
    if (widget.course?.colorHex != null) {
      final color = _colorFromHex(widget.course!.colorHex!);
      if (color != null) {
        _selectedColor = color;
      }
    }
  }

  Color? _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF\$hexColor';
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return null;
    }
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
        colorHex: colorToHex(_selectedColor),
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
              const Text(
                'Choose Color',
                style: TextStyle(
                  color: Color(0xFF3A5240),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kAssessmentColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
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

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.isSubscribed, required this.onTap});
  final bool isSubscribed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isSubscribed ? null : onTap,
      icon: Icon(
        isSubscribed ? Icons.check_circle_outline : Icons.add_circle_outline,
        size: 16,
      ),
      label: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: const Color(0xFFE8F1EA),
        foregroundColor: Colors.white,
        disabledForegroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _FloatingMenuButton extends StatelessWidget {
  const _FloatingMenuButton({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                Icon(Icons.edit_outlined, size: 20, color: AppColors.success),
                const SizedBox(width: 10),
                const Text('Edit', style: TextStyle(color: AppColors.darkText)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                const SizedBox(width: 10),
                const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.darkText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course details bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CourseDetailsSheet extends StatelessWidget {
  const _CourseDetailsSheet({
    required this.course,
    required this.canManage,
    required this.isEnrolled,
    required this.onSubscribe,
    required this.rootContext,
  });

  final CourseModel course;
  final bool canManage;
  final bool isEnrolled;
  final VoidCallback onSubscribe;
  // Stable context from the parent screen — used for any navigation
  // triggered from inside this sheet, instead of the sheet's own
  // `context`, which becomes unsafe the instant we Navigator.pop it.
  final BuildContext rootContext;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final hasAccess = canManage || isEnrolled;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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

            if (course.courseImg != null && course.courseImg!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 18),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.16),
                        AppColors.primary.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
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
                          color: Color(0xFF16281B),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MiniBadge(label: course.courseCode),
                          const SizedBox(width: 6),
                          if (canManage)
                            const _MiniBadge(
                              label: 'Teaching',
                              color: Color(0xFF2B6CB0),
                              background: Color(0xFFEBF4FF),
                            )
                          else if (isEnrolled)
                            const _MiniBadge(
                              label: 'Enrolled',
                              color: Color(0xFF276749),
                              background: Color(0xFFE7F8ED),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (course.description != null &&
                course.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              MarkdownBody(
                data: course.description!,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 15,
                  color: const Color(0xFF718096),
                ),
                const SizedBox(width: 5),
                Text(
                  '${course.subscriberCount} students',
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: const Color(0xFF718096),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _creatorName(course.createdBy),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            if (!hasAccess) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7EBE8)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Subscribe to unlock this course',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF16281B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assignments, grades, and attendance appear here once you join.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: course.isSubscribed
                            ? null
                            : () {
                                Navigator.pop(context);
                                onSubscribe();
                              },
                        icon: Icon(
                          course.isSubscribed
                              ? Icons.check_circle_outline
                              : Icons.add_circle_outline,
                          size: 18,
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Teaching side ─────────────────────────────────────────
            if (canManage) ...[
              SelectedCard(
                icon: Icons.qr_code_rounded,
                iconColor: Colors.teal,
                title: 'QR Code',
                subtitle: 'Get QR code for this course',
                onTap: () {
                  Navigator.pop(context);
                  rootContext.push(
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
                  rootContext.push(
                    '/assessments',
                    extra: {'courseCode': course.courseCode},
                  );
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
                  rootContext.push(
                    '/grading',
                    extra: {'courseCode': course.courseCode},
                  );
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
                  rootContext.push(
                    '/attendance/home',
                    extra: {
                      'courseCode': course.courseCode,
                      'courseName': course.courseName,
                    },
                  );
                },
              ),
            ],

            // ── Enrolled side ─────────────────────────────────────────
            if (isEnrolled && !canManage) ...[
              SelectedCard(
                icon: Icons.assignment_outlined,
                iconColor: Colors.blue,
                title: 'Assessment',
                subtitle: 'View assessment for this course',
                onTap: () {
                  Navigator.pop(context);
                  rootContext.push(
                    '/assessments',
                    extra: {'courseCode': course.courseCode},
                  );
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
                  rootContext.push(
                    '/grading',
                    extra: {'courseCode': course.courseCode},
                  );
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
                  rootContext.push(
                    '/attendance/student/course-report',
                    extra: {
                      'studentId':
                          rootContext.read<UserProvider>().user?.id ?? '',
                      'studentName':
                          rootContext.read<UserProvider>().user?.userName ??
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
                  rootContext.push(
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
                  rootContext.push('/tasks'); // change to your route
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small pill used in the details sheet header ───────────────────────────

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    this.color = const Color(0xFF4A5568),
    this.background = const Color(0xFFF1F5F2),
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.14),
                    AppColors.primary.withOpacity(0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF16281B),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718096), height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

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
