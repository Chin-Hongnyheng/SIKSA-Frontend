import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';

class RecommendationWidget extends StatefulWidget {
  const RecommendationWidget({super.key});

  @override
  State<RecommendationWidget> createState() => _RecommendationWidgetState();
}

class _RecommendationWidgetState extends State<RecommendationWidget> {
  PageController? _pageCtrl;
  int _realIndex = 0;
  bool _userPaused = false;
  int _lastCourseCount = 0;

  // Which course (by real index, not virtual page) currently has its
  // Subscribe overlay open. Only one card can be active at a time —
  // tapping a different card closes whichever one was open before.
  int? _activeRealIndex;

  // Large multiplier so virtual list feels infinite in both directions
  static const int _mult = 500;

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  // Create (or recreate) the controller when course count changes
  void _ensureController(int count) {
    if (_lastCourseCount == count && _pageCtrl != null) return;
    _pageCtrl?.dispose();
    final initialPage = (count * _mult) ~/ 2;
    _pageCtrl = PageController(
      initialPage: initialPage,
      viewportFraction: 0.86,
    );
    _lastCourseCount = count;
    // kick off auto-play once
    if (count > 0) _startAutoPlay(count);
  }

  void _startAutoPlay(int count) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 3200));
      if (!mounted) return false;
      if (_userPaused) return true;
      final ctrl = _pageCtrl;
      if (ctrl == null || !ctrl.hasClients) return true;
      ctrl.animateToPage(
        (ctrl.page!.round()) + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      return true;
    });
  }

  void _onPageChanged(int virtualPage, int count) {
    setState(() {
      _realIndex = virtualPage % count;
      // Close any open Subscribe overlay when the user swipes away.
      _activeRealIndex = null;
    });
  }

  void _goTo(int realIdx, int count) {
    final ctrl = _pageCtrl;
    if (ctrl == null || !ctrl.hasClients) return;
    _userPaused = true;
    final current = ctrl.page?.round() ?? 0;
    final block = (current ~/ count) * count;
    ctrl.animateToPage(
      block + realIdx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _userPaused = false);
    });
  }

  void _toggleActive(int realIdx) {
    setState(() {
      _activeRealIndex = _activeRealIndex == realIdx ? null : realIdx;
    });
  }

  Future<void> _subscribe(CourseModel course) async {
    try {
      await context.read<CourseProvider>().subscribeCourse(
        courseCode: course.courseCode,
      );
      if (!mounted) return;
      setState(() => _activeRealIndex = null);
      await CenterToast.show(
        context,
        message: 'Subscribed to ${course.courseName}',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      await CenterToast.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final allCourses = context.watch<CourseProvider>().allCourses;

    final courses = allCourses
        .where((c) => c.createdBy != user?.userName && !c.isSubscribed)
        .take(5)
        .toList();

    if (courses.isEmpty) return const SizedBox.shrink();

    final count = courses.length;
    _ensureController(count);
    final ctrl = _pageCtrl!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24, thickness: 1),
        const SizedBox(height: 12),

        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Recommended for you',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Carousel — fully swipeable, infinite circular loop
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: ctrl,
            itemCount: count * _mult,
            onPageChanged: (p) => _onPageChanged(p, count),
            itemBuilder: (context, virtualPage) {
              final realIdx = virtualPage % count;
              final course = courses[realIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _RecommendationCard(
                  course: course,
                  isActive: _activeRealIndex == realIdx,
                  onTap: () => _toggleActive(realIdx),
                  onSubscribe: () => _subscribe(course),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Dots — tapping jumps to that course, swiping updates them too
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final active = i == _realIndex;
            return GestureDetector(
              onTap: () => _goTo(i, count),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Colors.white, Color(0xFFE4FFF0)],
                        )
                      : null,
                  color: active ? null : Colors.white.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual course card — same visual language as _CourseListCard on the
// Courses screen (cover image, title, creator row, pill badges, footer
// date row). There is no visible Subscribe button by default. Tapping the
// card dims it with a dark scrim and reveals a centered Subscribe button;
// tapping it again (or selecting another card) closes the overlay.
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.course,
    required this.isActive,
    required this.onTap,
    required this.onSubscribe,
  });

  final CourseModel course;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onSubscribe;

  bool get _isPopular => course.subscriberCount >= 20;

  @override
  Widget build(BuildContext context) {
    final hasImg = course.courseImg != null && course.courseImg!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withOpacity(0.06),
        highlightColor: AppColors.primary.withOpacity(0.03),
        child: Stack(
          children: [
            // ── Base card content ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFCFEFC)],
                ),
                border: Border.all(color: const Color(0xFFECF1EE)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover image ──────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: hasImg
                              ? Image.network(
                                  course.courseImg!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      _imgPlaceholder(),
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: AppColors.primary.withOpacity(
                                        0.06,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : _imgPlaceholder(),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 30,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.16),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isPopular)
                          Positioned(
                            top: 7,
                            left: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF34D399),
                                    Color(0xFF10B981),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Popular',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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

                  const SizedBox(height: 8),

                  // ── Title ────────────────────────────────────────────
                  Text(
                    course.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF16281B),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Instructor ───────────────────────────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: Color(0xFF9AA5A0),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course.createdBy ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // ── Badge row ────────────────────────────────────────
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _OutlinedPill(
                        icon: Icons.groups_outlined,
                        label: '${course.subscriberCount} students',
                      ),
                      _OutlinedPill(
                        icon: Icons.tag_rounded,
                        label: course.courseCode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFF0F3F1)),
                  const SizedBox(height: 8),

                  // ── Footer: date only, no button ─────────────────────
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
                    ],
                  ),
                ],
              ),
            ),

            // ── Dark scrim + centered Subscribe, shown when active ────
            IgnorePointer(
              ignoring: !isActive,
              child: AnimatedOpacity(
                opacity: isActive ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: onSubscribe,
                    icon: const Icon(Icons.add_circle_outline, size: 17),
                    label: const Text('Subscribe'),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(0.85),
          AppColors.primary.withOpacity(0.5),
        ],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.menu_book_rounded,
        color: Colors.white.withOpacity(0.9),
        size: 32,
      ),
    ),
  );
}

// ── Generic outlined pill (matches _OutlinedPill on the Courses screen) ──

class _OutlinedPill extends StatelessWidget {
  const _OutlinedPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE7EBE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF4A5568)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date helper (mirrors _formatDate in courses_screen.dart) ─────────────

String _formatDate(String? value) {
  if (value == null || value.isEmpty) return 'No date';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('MMM d, yyyy').format(parsed.toLocal());
}
