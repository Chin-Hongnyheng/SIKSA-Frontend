import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course_model.dart';
import '../../widgets/floating_line_background.dart';
// import 'student_course_attendance_report_page.dart';

class StudentAttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentAttendancePage({
    super.key,
    this.studentId = 'student1',
    this.studentName = 'Student',
  });

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadAllCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Green gradient background ──────────────────────────────────
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
              decoration: const BoxDecoration(color: Color(0xFFF5F6FA)),
              child: Consumer<CourseProvider>(
                builder: (context, courseProvider, _) {
                  if (courseProvider.isLoadingAll) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E6B2D),
                      ),
                    );
                  }

                  if (courseProvider.errorAll != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load courses',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                context.read<CourseProvider>().loadCourses(),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF1E6B2D),
                            ),
                            label: const Text(
                              'Try again',
                              style: TextStyle(color: Color(0xFF1E6B2D)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Only show courses the student is subscribed to
                  final enrolledCourses = courseProvider.allCourses
                      .where((c) => c.isSubscribed == true)
                      .toList();

                  if (enrolledCourses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No enrolled courses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Subscribe to a course to see your attendance',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Your Courses',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      ...enrolledCourses.map(
                        (course) => _CourseAttendanceCard(
                          course: course,
                          studentId: widget.studentId,
                          studentName: widget.studentName,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Top header ─────────────────────────────────────────────────
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    const Expanded(
                      child: Text(
                        'My Attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
// Course card
// ─────────────────────────────────────────────────────────────────────────────

class _CourseAttendanceCard extends StatelessWidget {
  const _CourseAttendanceCard({
    required this.course,
    required this.studentId,
    required this.studentName,
  });

  final CourseModel course;
  final String studentId;
  final String studentName;

  // Assign a consistent accent color per course based on courseCode hash
  Color _accentColor() {
    const colors = [
      Color(0xFF1E6B2D),
      Color(0xFF1565C0),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
      Color(0xFF00695C),
      Color(0xFFC62828),
    ];
    return colors[course.courseCode.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              '/attendance/student/course-report',
              extra: {
                'studentId': studentId,
                'studentName': studentName,
                'courseCode': course.courseCode,
                'courseName': course.courseName,
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Color dot / icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      course.courseName.isNotEmpty
                          ? course.courseName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.courseCode,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
