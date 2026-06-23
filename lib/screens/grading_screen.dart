// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/grade_model.dart';
import '../providers/assessment_provider.dart';
import '../providers/course_provider.dart';
import '../providers/grade_provider.dart';
import '../widgets/center_toast.dart';
import '../widgets/loading.dart';

class GradingScreen extends StatefulWidget {
  const GradingScreen({super.key});

  @override
  State<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCourseCode;
  bool _isInitialLoading = true;

  // ── Editable score map: "studentId|assessmentName" → score string ──
  final Map<String, String> _editedScores = {};
  final Map<String, String> _originalScores = {};

  // ── Scroll controllers for synced scrolling ──
  final ScrollController _headerHorizontalCtrl = ScrollController();
  final ScrollController _bodyHorizontalCtrl = ScrollController();
  final ScrollController _bodyVerticalCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _headerHorizontalCtrl.addListener(_syncHeaderToBody);
    _bodyHorizontalCtrl.addListener(_syncBodyToHeader);
    Future.microtask(_loadInitialData);
  }

  @override
  void dispose() {
    _headerHorizontalCtrl.removeListener(_syncHeaderToBody);
    _bodyHorizontalCtrl.removeListener(_syncBodyToHeader);
    _headerHorizontalCtrl.dispose();
    _bodyHorizontalCtrl.dispose();
    _bodyVerticalCtrl.dispose();
    super.dispose();
  }

  void _syncHeaderToBody() {
    if (_bodyHorizontalCtrl.hasClients &&
        _bodyHorizontalCtrl.offset != _headerHorizontalCtrl.offset) {
      _bodyHorizontalCtrl.jumpTo(_headerHorizontalCtrl.offset);
    }
  }

  void _syncBodyToHeader() {
    if (_headerHorizontalCtrl.hasClients &&
        _headerHorizontalCtrl.offset != _bodyHorizontalCtrl.offset) {
      _headerHorizontalCtrl.jumpTo(_bodyHorizontalCtrl.offset);
    }
  }

  Future<void> _loadInitialData() async {
    final courseProvider = context.read<CourseProvider>();
    await courseProvider.loadCourses(role: 'Teacher');
    if (courseProvider.courses.isNotEmpty) {
      _selectedCourseCode = courseProvider.courses.first.courseCode;
      await _loadCourseData();
    }
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadCourseData() async {
    if (_selectedCourseCode == null) return;

    final assessmentProvider = context.read<AssessmentProvider>();
    final gradeProvider = context.read<GradeProvider>();
    final courseProvider = context.read<CourseProvider>();

    await Future.wait([
      assessmentProvider.loadAssessments(_selectedCourseCode!),
      gradeProvider.loadGradesByCourse(_selectedCourseCode!),
      courseProvider.loadCourseSubscribers(_selectedCourseCode!),
    ]);

    _buildScoreMap();
  }

  void _buildScoreMap() {
    _editedScores.clear();
    _originalScores.clear();
    final grades = context.read<GradeProvider>().grades;
    for (final g in grades) {
      final key = '${g.studentId}|${g.assessmentName}';
      final val = g.score == g.score.truncateToDouble()
          ? g.score.toInt().toString()
          : g.score.toString();
      _editedScores[key] = val;
      _originalScores[key] = val;
    }
    if (mounted) setState(() {});
  }

  bool get _hasUnsavedChanges {
    for (final entry in _editedScores.entries) {
      final original = _originalScores[entry.key] ?? '';
      if (entry.value != original && entry.value.isNotEmpty) return true;
    }
    // Check for new entries not in original
    for (final key in _editedScores.keys) {
      if (!_originalScores.containsKey(key) && _editedScores[key]!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveAllGrades() async {
    final gradeProvider = context.read<GradeProvider>();

    final List<Map<String, dynamic>> gradesToSave = [];

    for (final entry in _editedScores.entries) {
      final value = entry.value.trim();
      if (value.isEmpty) continue;

      final score = double.tryParse(value);
      if (score == null) continue;

      final original = _originalScores[entry.key];
      // Only send changed or new grades
      if (original == value) continue;

      final parts = entry.key.split('|');
      if (parts.length != 2) continue;

      gradesToSave.add({
        'studentId': parts[0],
        'courseCode': _selectedCourseCode,
        'assessmentName': parts[1],
        'score': score,
        'maxScore': 100.0,
      });
    }

    if (gradesToSave.isEmpty) {
      await CenterToast.show(
        context,
        message: 'No changes to save',
        icon: Icons.info_outline_rounded,
        color: Colors.orange,
      );
      return;
    }

    LoadingOverlay.show(context);
    try {
      await gradeProvider.saveAllGrades(gradesToSave);
      await gradeProvider.loadGradesByCourse(_selectedCourseCode!);
      _buildScoreMap();
      await CenterToast.show(
        context,
        message:
            '${gradesToSave.length} grade${gradesToSave.length == 1 ? '' : 's'} saved',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      await CenterToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      LoadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final assessmentProvider = context.watch<AssessmentProvider>();
    final gradeProvider = context.watch<GradeProvider>();

    final courses = courseProvider.courses;
    final assessments = assessmentProvider.assessments;
    final subscribers =
        courseProvider.courseSubscribers[_selectedCourseCode] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Header ──
            _GradingHeader(onBackTap: () => context.pop()),

            // ── Course Selector ──
            if (_isInitialLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              _CourseSelector(
                courses: courses,
                selectedCode: _selectedCourseCode,
                onChanged: (code) {
                  setState(() => _selectedCourseCode = code);
                  _loadCourseData();
                },
              ),

              // ── Content ──
              Expanded(
                child: gradeProvider.isLoading || assessmentProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : assessments.isEmpty
                    ? _EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No Assessments',
                        message: 'Create assessments for this course first.',
                      )
                    : subscribers.isEmpty
                    ? _EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No Students',
                        message:
                            'No students have subscribed to this course yet.',
                      )
                    : _GradingTable(
                        assessmentNames: assessments
                            .map((a) => a.assessmentName)
                            .toList(),
                        students: subscribers,
                        editedScores: _editedScores,
                        originalScores: _originalScores,
                        onScoreChanged: (key, value) {
                          setState(() {
                            _editedScores[key] = value;
                          });
                        },
                        headerHorizontalCtrl: _headerHorizontalCtrl,
                        bodyHorizontalCtrl: _bodyHorizontalCtrl,
                        bodyVerticalCtrl: _bodyVerticalCtrl,
                      ),
              ),
            ],
          ],
        ),
      ),
      // ── Save FAB ──
      floatingActionButton: _hasUnsavedChanges
          ? FloatingActionButton.extended(
              onPressed: _saveAllGrades,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save All',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Header
// ═══════════════════════════════════════════════════════════════

class _GradingHeader extends StatelessWidget {
  const _GradingHeader({required this.onBackTap});

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
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Grading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Score management',
                  style: TextStyle(
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
//  Course Selector
// ═══════════════════════════════════════════════════════════════

class _CourseSelector extends StatelessWidget {
  const _CourseSelector({
    required this.courses,
    required this.selectedCode,
    required this.onChanged,
  });

  final List courses;
  final String? selectedCode;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No courses available',
          style: TextStyle(
            color: Color(0xFF607064),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECE7)),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCode,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
                style: const TextStyle(
                  color: Color(0xFF1B3B22),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                items: courses
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(
                        value: c.courseCode,
                        child: Text(
                          '${c.courseCode} — ${c.courseName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1B3B22),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF607064),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Grading Table (Excel-like)
// ═══════════════════════════════════════════════════════════════

class _GradingTable extends StatelessWidget {
  const _GradingTable({
    required this.assessmentNames,
    required this.students,
    required this.editedScores,
    required this.originalScores,
    required this.onScoreChanged,
    required this.headerHorizontalCtrl,
    required this.bodyHorizontalCtrl,
    required this.bodyVerticalCtrl,
  });

  final List<String> assessmentNames;
  final List students;
  final Map<String, String> editedScores;
  final Map<String, String> originalScores;
  final void Function(String key, String value) onScoreChanged;
  final ScrollController headerHorizontalCtrl;
  final ScrollController bodyHorizontalCtrl;
  final ScrollController bodyVerticalCtrl;

  static const double _nameColWidth = 150.0;
  static const double _numberColWidth = 42.0;
  static const double _cellWidth = 110.0;
  static const double _cellHeight = 50.0;
  static const double _headerHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Table header ──
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                // Fixed "#" column header
                _HeaderCell(
                  text: '#',
                  width: _numberColWidth,
                  isFirst: true,
                  isNumberCol: true,
                ),
                // Fixed "Student" column header
                _HeaderCell(
                  text: 'Student',
                  width: _nameColWidth,
                  isFirst: false,
                ),
                // Divider
                Container(width: 1, color: const Color(0xFFD5DDD8)),
                // Scrollable assessment column headers
                Expanded(
                  child: SingleChildScrollView(
                    controller: headerHorizontalCtrl,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: assessmentNames
                          .map(
                            (name) =>
                                _HeaderCell(text: name, width: _cellWidth),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider between header and body
          Container(height: 1.5, color: AppColors.primary.withOpacity(0.3)),

          // ── Table body ──
          Expanded(
            child: SingleChildScrollView(
              controller: bodyVerticalCtrl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed number column
                  Column(
                    children: List.generate(students.length, (rowIndex) {
                      return _FixedNumberCell(
                        number: rowIndex + 1,
                        height: _cellHeight,
                        width: _numberColWidth,
                        isEven: rowIndex.isEven,
                      );
                    }),
                  ),
                  // Fixed student names column
                  Column(
                    children: List.generate(students.length, (rowIndex) {
                      final student = students[rowIndex];
                      return _FixedNameCell(
                        name: student.userName,
                        height: _cellHeight,
                        width: _nameColWidth,
                        isEven: rowIndex.isEven,
                      );
                    }),
                  ),
                  // Divider
                  Column(
                    children: List.generate(
                      students.length,
                      (i) => Container(
                        width: 1,
                        height: _cellHeight,
                        color: const Color(0xFFD5DDD8),
                      ),
                    ),
                  ),
                  // Scrollable score cells
                  Expanded(
                    child: SingleChildScrollView(
                      controller: bodyHorizontalCtrl,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: List.generate(students.length, (rowIndex) {
                          final student = students[rowIndex];
                          return Row(
                            children: assessmentNames.map((aName) {
                              final key = '${student.id}|$aName';
                              final currentVal = editedScores[key] ?? '';
                              final originalVal = originalScores[key] ?? '';
                              final isModified =
                                  currentVal != originalVal &&
                                  currentVal.isNotEmpty;

                              return _ScoreCell(
                                width: _cellWidth,
                                height: _cellHeight,
                                value: currentVal,
                                isModified: isModified,
                                isEven: rowIndex.isEven,
                                onChanged: (v) => onScoreChanged(key, v),
                              );
                            }).toList(),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Summary footer ──
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              border: Border(
                top: BorderSide(color: AppColors.primary.withOpacity(0.12)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 18,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${students.length} students',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.assignment_rounded,
                  size: 18,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${assessmentNames.length} assessments',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 13,
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
//  Table Cells
// ═══════════════════════════════════════════════════════════════

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.text,
    required this.width,
    this.isFirst = false,
    this.isNumberCol = false,
  });

  final String text;
  final double width;
  final bool isFirst;
  final bool isNumberCol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isNumberCol ? 4 : 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.06),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          right: BorderSide(color: const Color(0xFFD5DDD8), width: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF1B3B22),
            fontSize: isNumberCol ? 12 : 13,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _FixedNumberCell extends StatelessWidget {
  const _FixedNumberCell({
    required this.number,
    required this.height,
    required this.width,
    required this.isEven,
  });

  final int number;
  final double height;
  final double width;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF7FAF8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEDF1EE), width: 0.5),
          right: BorderSide(color: Color(0xFFEDF1EE), width: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Color(0xFF98A49C),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FixedNameCell extends StatelessWidget {
  const _FixedNameCell({
    required this.name,
    required this.height,
    required this.width,
    required this.isEven,
  });

  final String name;
  final double height;
  final double width;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF7FAF8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEDF1EE), width: 0.5),
          right: BorderSide(color: Color(0xFFD5DDD8), width: 0.5),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1F2D22),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScoreCell extends StatefulWidget {
  const _ScoreCell({
    required this.width,
    required this.height,
    required this.value,
    required this.isModified,
    required this.isEven,
    required this.onChanged,
  });

  final double width;
  final double height;
  final String value;
  final bool isModified;
  final bool isEven;
  final ValueChanged<String> onChanged;

  @override
  State<_ScoreCell> createState() => _ScoreCellState();
}

class _ScoreCellState extends State<_ScoreCell> {
  late TextEditingController _ctrl;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ScoreCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isFocused) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isFocused
        ? AppColors.primary.withOpacity(0.06)
        : widget.isModified
        ? const Color(0xFFFFF8E1)
        : widget.isEven
        ? Colors.white
        : const Color(0xFFF7FAF8);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: const BorderSide(color: Color(0xFFEDF1EE), width: 0.5),
          right: const BorderSide(color: Color(0xFFEDF1EE), width: 0.5),
          left: _isFocused
              ? BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isModified
                ? const Color(0xFFB8860B)
                : const Color(0xFF1F2D22),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '—',
            hintStyle: TextStyle(
              color: const Color(0xFFBCC5BF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            isDense: true,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
