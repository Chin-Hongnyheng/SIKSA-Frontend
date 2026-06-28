import 'package:flutter/material.dart';
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

  // Tracks which single card (by its virtual page index) is currently
  // showing its "open" overlay. Only one card can be open at a time —
  // opening another card automatically closes whichever was open before.
  int? _openVirtualPage;

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
      viewportFraction: 0.88,
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
    setState(() => _realIndex = virtualPage % count);
  }

  // Opens [virtualPage]'s overlay, closing whatever was open before it.
  // Tapping the already-open card closes it instead.
  void _toggleOpen(int virtualPage) {
    setState(() {
      if (_openVirtualPage == virtualPage) {
        _openVirtualPage = null;
        _userPaused = false;
      } else {
        _openVirtualPage = virtualPage;
        _userPaused = true;
      }
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

  Future<void> _subscribe(CourseModel course) async {
    try {
      await context.read<CourseProvider>().subscribeCourse(
        courseCode: course.courseCode,
      );
      if (!mounted) return;
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
        const Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recommended for you',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Carousel — fully swipeable, infinite circular loop
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: ctrl,
            itemCount: count * _mult,
            onPageChanged: (p) => _onPageChanged(p, count),
            itemBuilder: (context, virtualPage) {
              final course = courses[virtualPage % count];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _RecommendationCard(
                  course: course,
                  isOpen: _openVirtualPage == virtualPage,
                  onToggleOpen: () => _toggleOpen(virtualPage),
                  onSubscribe: () => _subscribe(course),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

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
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
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
// Individual course card
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.course,
    required this.isOpen,
    required this.onToggleOpen,
    required this.onSubscribe,
  });

  final CourseModel course;
  final bool isOpen;
  final VoidCallback onToggleOpen;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final hasImg = course.courseImg != null && course.courseImg!.isNotEmpty;

    return GestureDetector(
      onTap: onToggleOpen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Card ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: hasImg
                        ? Image.network(
                            course.courseImg!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder(),
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
                        : _imgPlaceholder(),
                  ),

                  // Text — tight spacing
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseCode,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.courseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1B3B22),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ── Creator + student count row ─────────────
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: Color(0xFF718096),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                course.createdBy ?? 'Unknown',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.groups_outlined,
                              size: 12,
                              color: Color(0xFF718096),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${course.subscriberCount}',
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tap overlay — only one card shows this at a time ──────
          AnimatedOpacity(
            opacity: isOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !isOpen,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        course.courseName,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: onSubscribe,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Join'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
  }

  Widget _imgPlaceholder() => Container(
    color: AppColors.primary.withOpacity(0.07),
    child: const Center(
      child: Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 36),
    ),
  );
}
