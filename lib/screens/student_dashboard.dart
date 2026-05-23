import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../graphql/graphql_service.dart';
import '../providers/assessments_provider.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  final GraphQLService _graphqlService = GraphQLService();
  Map<String, dynamic>? _user;
  bool _isUserLoading = true;
  String? _userError;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() {
      _isUserLoading = true;
      _userError = null;
    });

    try {
      final user = await _graphqlService.me();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isUserLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUserLoading = false;
        _userError = 'Unable to load profile';
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _loadUser(),
      ref.read(assessmentsProvider.notifier).fetchData(silent: true),
    ]);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  List<Map<String, dynamic>> _sortedUpcomingTasks(
    List<Map<String, dynamic>> source,
  ) {
    final tasks = [...source];
    tasks.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '');

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return tasks.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentsProvider);
    final upcomingTasks = _sortedUpcomingTasks(assessmentState.assessments);
    final userName = (_user?['userName'] as String?)?.trim();
    final role = (_user?['role'] as String?)?.trim();
    final displayName = (userName?.isNotEmpty == true) ? userName! : 'Student';
    final displayRole = (role?.isNotEmpty == true) ? role! : 'Learner';

    final quickActions = <_QuickAction>[
      _QuickAction(
        title: 'Courses',
        icon: Icons.menu_book_outlined,
        accent: AppColors.secondary,
        onTap: () => _showComingSoon('Courses'),
      ),
      _QuickAction(
        title: 'Assessments',
        icon: Icons.assignment_outlined,
        accent: AppColors.secondary,
        onTap: () => context.push('/assessments'),
      ),
      _QuickAction(
        title: 'Schedule',
        icon: Icons.calendar_month_outlined,
        accent: AppColors.secondary,
        onTap: () => _showComingSoon('Schedule'),
      ),
      _QuickAction(
        title: 'Attendance',
        icon: Icons.fact_check_outlined,
        accent: AppColors.secondary,
        onTap: () => _showComingSoon('Attendance'),
      ),
      // _QuickAction(
      //   title: 'Results',
      //   icon: Icons.bar_chart_rounded,
      //   accent: const Color(0xFF498D35),
      //   onTap: () => _showComingSoon('Results'),
      // ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _DashboardTopSection(
                name: displayName,
                role: displayRole,
                isLoading: _isUserLoading,
                hasError: _userError != null,
                onProfileTap: () => context.push('/profile'),
                onBellTap: () => context.push('/notifications'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickActionsCard(actions: quickActions),
                    const SizedBox(height: 24),
                    _UpcomingTasksSection(
                      tasks: upcomingTasks,
                      isLoading: assessmentState.isLoading,
                      onViewAllTap: () => context.push('/assessments'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTopSection extends StatelessWidget {
  const _DashboardTopSection({
    required this.name,
    required this.role,
    required this.isLoading,
    required this.hasError,
    required this.onProfileTap,
    required this.onBellTap,
  });

  final String name;
  final String role;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onProfileTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 14,
        16,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.22),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading ? 'Loading profile...' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasError ? 'View Profile' : '$role • View Profile',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onBellTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _HeroBanner(),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A7A39), Color(0xFF1E6B2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to SIKSA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Enjoy your learning journey!',
                      style: TextStyle(
                        color: Color(0xFFE8F5E9),
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9EBAA6), Color(0xFF8FAE9B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logov3.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14972D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Shortcuts for your student workflow',
            style: TextStyle(
              color: Color(0xFF6A7E6F),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: actions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EEE8)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: action.accent.withOpacity(0.16),
                        ),
                        child: Icon(
                          action.icon,
                          color: action.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF294330),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UpcomingTasksSection extends StatelessWidget {
  const _UpcomingTasksSection({
    required this.tasks,
    required this.isLoading,
    required this.onViewAllTap,
  });

  final List<Map<String, dynamic>> tasks;
  final bool isLoading;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Upcoming Tasks',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14972D),
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAllTap,
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (isLoading && tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECE9)),
            ),
            child: const Text(
              'No tasks yet. You are all caught up.',
              style: TextStyle(
                color: Color(0xFF6B7A6F),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Column(
            children: tasks
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpcomingTaskTile(task: task),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  const _UpcomingTaskTile({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(task['createdAt']?.toString() ?? '');
    final monthLabel = date == null
        ? '--'
        : DateFormat('MMM').format(date).toUpperCase();
    final dayLabel = date == null ? '--' : DateFormat('dd').format(date);
    final title = (task['assessmentName'] as String?)?.trim();
    final course = (task['courseCode'] as String?)?.trim();

    final isFresh = date != null && DateTime.now().difference(date).inDays <= 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                    color: Color(0xFF5E6F62),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayLabel,
                  style: const TextStyle(
                    color: Color(0xFF1D3624),
                    fontWeight: FontWeight.w900,
                    fontSize: 23,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (title?.isNotEmpty == true) ? title! : 'Untitled Task',
                  style: const TextStyle(
                    color: Color(0xFF1F2A22),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (course?.isNotEmpty == true) ? course! : 'Course not set',
                  style: const TextStyle(
                    color: Color(0xFF5F6D63),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFresh
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF3F6F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFresh ? 'New' : 'Planned',
              style: TextStyle(
                color: isFresh ? AppColors.primary : const Color(0xFF64756A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}
