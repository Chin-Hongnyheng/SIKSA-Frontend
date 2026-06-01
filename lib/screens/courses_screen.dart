import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({
    super.key,
    this.onlySubscribed = false,
    this.showSearch = true,
  });

  final bool onlySubscribed;
  final bool showSearch;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadCoursesForRole);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canManage(String? role) {
    final normalizedRole = role?.trim().toLowerCase();
    return normalizedRole == 'teacher' || normalizedRole == 'admin';
  }

  String _readableError(String value) {
    return value.replaceAll('Exception: ', '');
  }

  Future<void> _loadCoursesForRole() async {
    final userProvider = context.read<UserProvider>();

    if (userProvider.user == null) {
      await userProvider.loadUser();
    }

    final role = userProvider.user?.role;
    if (!mounted) return;

    await context.read<CourseProvider>().loadCourses(role: role);
  }

  List<CourseModel> _filteredCourses(List<CourseModel> courses) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return courses;

    return courses.where((course) {
      return course.courseName.toLowerCase().contains(query) ||
          course.courseCode.toLowerCase().contains(query) ||
          (course.description ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openCourseEditor({CourseModel? course}) async {
    final role = context.read<UserProvider>().user?.role;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseEditorSheet(
        course: course,
        onSubmit:
            ({
              required courseName,
              required courseCode,
              required description,
            }) async {
              final provider = context.read<CourseProvider>();

              if (course == null) {
                await provider.createCourse(
                  courseName: courseName,
                  courseCode: courseCode,
                  description: description,
                  role: role,
                );
              } else {
                await provider.editCourse(
                  courseCode: course.courseCode,
                  courseName: courseName,
                  newCourseCode: courseCode,
                  description: description,
                  role: role,
                );
              }

              if (!mounted) return;
              await CenterToast.show(
                context,
                message: course == null ? 'Course created' : 'Course updated',
                icon: Icons.check_circle,
                color: Colors.green,
              );
            },
      ),
    );
  }

  Future<void> _deleteCourse(CourseModel course) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete course'),
            content: Text('Delete ${course.courseCode}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    final role = context.read<UserProvider>().user?.role;

    try {
      await context.read<CourseProvider>().deleteCourse(
        courseCode: course.courseCode,
        role: role,
      );
      if (!mounted) return;
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

  Future<void> _subscribeCourse(CourseModel course) async {
    final role = context.read<UserProvider>().user?.role;

    try {
      await context.read<CourseProvider>().subscribeCourse(
        courseCode: course.courseCode,
        role: role,
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

  void _openCourseDetails(CourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseDetailsSheet(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final user = context.watch<UserProvider>().user;
    final canManage = _canManage(user?.role);
    // apply search filtering first
    var courses = _filteredCourses(courseProvider.courses);

    // if requested, show only subscribed courses (used by Dashboard -> My Courses)
    if (widget.onlySubscribed) {
      courses = courses.where((c) => c.isSubscribed).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openCourseEditor(),
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
            _CoursesHeader(
              title: (widget.onlySubscribed && !canManage)
                  ? 'Courses'
                  : 'Courses',
              subtitle: canManage ? 'Teacher workspace' : 'Student courses',
              onBackTap: () => context.pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadCoursesForRole,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  children: [
                    if (widget.showSearch)
                      _CourseSearchField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),
                    const SizedBox(height: 14),
                    _CourseSummary(
                      total: widget.onlySubscribed
                          ? courseProvider.courses
                                .where((c) => c.isSubscribed)
                                .length
                          : courseProvider.courses.length,
                      canManage: canManage,
                      studentSubscribed: widget.onlySubscribed && !canManage,
                    ),
                    const SizedBox(height: 16),
                    if (courseProvider.isLoading &&
                        courseProvider.courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (courseProvider.error != null &&
                        courseProvider.error!.isNotEmpty)
                      _StatusPanel(
                        icon: Icons.info_outline_rounded,
                        title: 'Unable to display courses',
                        message: _readableError(courseProvider.error!),
                        actionLabel: 'Try again',
                        onActionTap: _loadCoursesForRole,
                      )
                    else if (courses.isEmpty)
                      _StatusPanel(
                        icon: Icons.menu_book_outlined,
                        title: _searchText.trim().isEmpty
                            ? (widget.onlySubscribed
                                  ? 'No subscribed courses'
                                  : 'No courses yet')
                            : 'No matching courses',
                        message: canManage
                            ? 'Create a course to make it available here.'
                            : (widget.onlySubscribed
                                  ? 'You have not subscribed to any courses yet.'
                                  : 'Courses created by teachers will appear here.'),
                        actionLabel: canManage
                            ? 'Create course'
                            : (widget.onlySubscribed
                                  ? 'Browse courses'
                                  : 'Refresh'),
                        onActionTap: canManage
                            ? () => _openCourseEditor()
                            : (widget.onlySubscribed
                                  ? () => context.push('/courses')
                                  : _loadCoursesForRole),
                      )
                    else ...[
                      Text(
                        canManage
                            ? 'My Courses'
                            : (widget.onlySubscribed
                                  ? 'Courses Subscribed'
                                  : 'Available Courses'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3B22),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...courses.map(
                        (course) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CourseListCard(
                            course: course,
                            canManage: canManage,
                            onTap: () => _openCourseDetails(course),
                            onEdit: () => _openCourseEditor(course: course),
                            onDelete: () => _deleteCourse(course),
                            onSubscribe: () => _subscribeCourse(course),
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

class _CoursesHeader extends StatelessWidget {
  const _CoursesHeader({
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({
    required this.total,
    required this.canManage,
    this.studentSubscribed = false,
  });

  final int total;
  final bool canManage;
  final bool studentSubscribed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              canManage ? Icons.edit_note_rounded : Icons.auto_stories_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canManage
                      ? 'Created Courses'
                      : (studentSubscribed
                            ? 'Courses Attended'
                            : 'Courses Available'),
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total courses',
                  style: const TextStyle(
                    color: Color(0xFF1B3B22),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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

class _CourseListCard extends StatelessWidget {
  const _CourseListCard({
    required this.course,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSubscribe,
  });

  final CourseModel course;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final description = course.description?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          ),
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
                                style: TextStyle(color: AppColors.darkText),
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
                                style: TextStyle(color: AppColors.darkText),
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
              if (!canManage) ...[
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
      ),
    );
  }
}

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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
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

class _CourseDetailsSheet extends StatelessWidget {
  const _CourseDetailsSheet({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final description = course.description?.trim();

    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const Text(
              'Description',
              style: TextStyle(
                color: Color(0xFF1B3B22),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description == null || description.isEmpty
                  ? 'No description provided.'
                  : description,
              style: const TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
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
              ],
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
