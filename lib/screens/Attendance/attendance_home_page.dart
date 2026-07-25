import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_session_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/center_toast.dart';
import '../../widgets/floating_line_background.dart';
import 'session_attendance_page.dart';

class AttendanceHomePage extends StatefulWidget {
  /// When provided, this page only shows sessions for this course and the
  /// "Create" flow / session list it links to are scoped to this course
  /// too. When null, behaves as before (all courses the user teaches).
  final String? courseCode;

  /// Optional display name to show in the header when scoped to a course.
  final String? courseName;

  const AttendanceHomePage({super.key, this.courseCode, this.courseName});

  bool get isScoped => courseCode != null;

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final provider = context.read<AttendanceProvider>();
    final schedules = context.read<ScheduleProvider>().schedules;

    // Scope to a single course if one was passed in, otherwise use every
    // course the user teaches (original behaviour).
    final courseCodes = widget.isScoped
        ? {widget.courseCode!}
        : schedules.map((s) => s.courseCode).toSet();

    if (courseCodes.isEmpty) {
      provider.sessions = [];
      provider.notifyListeners();
      return;
    }

    provider.isLoading = true;
    provider.error = null;
    provider.notifyListeners();

    try {
      final results = await Future.wait(
        courseCodes.map((code) => provider.fetchSessionsForCode(code)),
      );
      provider.sessions = results.expand((list) => list).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      provider.error = e.toString();
    } finally {
      provider.isLoading = false;
      provider.notifyListeners();
    }
  }

  Future<void> _openActive(AttendanceSessionModel session) async {
    await context.push('/attendance/home/list/create/${session.id}');
    if (mounted) _reload();
  }

  // ← Now uses GoRouter with session passed as extra
  Future<void> _openReport(AttendanceSessionModel session) async {
    await context.push('/attendance/report', extra: session);
    if (mounted) _reload();
  }

  Future<void> _deleteSession(AttendanceSessionModel session) async {
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    bool? confirm;

    entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, color: Colors.red, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Delete Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${session.title}"?\n\nThis will also delete all attendance records inside this session.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          confirm = false;
                          entry.remove();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
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
                        onTap: () async {
                          confirm = true;
                          entry.remove();
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
                                fontWeight: FontWeight.w600,
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

    overlayState.insert(entry);

    // Wait until user taps a button
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return confirm == null;
    });

    if (confirm != true || !mounted) return;

    final success = await context.read<AttendanceProvider>().deleteSession(
      session.id,
    );
    if (!mounted) return;

    CenterToast.show(
      context,
      message: success
          ? 'Session deleted successfully'
          : 'Session not found or already deleted',
      icon: success ? Icons.check_circle : Icons.warning_amber_rounded,
      color: success ? Colors.green : Colors.orange,
    );
  }

  String _statusLabel(AttendanceSessionModel session) {
    if (!session.isActive) return 'Closed';
    try {
      final now = DateTime.now();
      final dateParts = session.date.split('-');
      final sp = session.startTime.split(':');
      final ep = session.endTime.split(':');

      final start = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(sp[0]),
        int.parse(sp[1]),
      );
      final end = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(ep[0]),
        int.parse(ep[1]),
      );

      if (now.isBefore(start)) return 'Upcoming';
      if (now.isAfter(end)) return 'Finished';
      return 'Active';
    } catch (_) {
      return 'Unknown';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Upcoming':
        return Colors.orange;
      case 'Finished':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool _isLive(AttendanceSessionModel s) => _statusLabel(s) == 'Active';

  Widget _buildSessionCard(AttendanceSessionModel session) {
    final status = _statusLabel(session);
    final color = _statusColor(status);
    final live = status == 'Active';
    final onTap = live
        ? () => _openActive(session)
        : () => _openReport(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (live)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(
                        live
                            ? Icons.radio_button_checked
                            : Icons.assignment_outlined,
                        color: color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${session.courseCode}  •  ${session.date}  •  ${session.startTime} – ${session.endTime}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: onTap,
                      icon: Icon(
                        live
                            ? Icons.how_to_reg_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      tooltip: live ? 'Take attendance' : 'View report',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: () => _deleteSession(session),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const headerTitle = 'Attendance';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated green background (matches AttendanceScreen) ──────
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
              // ← Changed from Color(0xFFF2F2F2) to white, matching AttendanceScreen
              decoration: const BoxDecoration(color: Colors.white),
              child: Consumer<AttendanceProvider>(
                builder: (context, provider, _) {
                  final live = provider.sessions.where(_isLive).toList();
                  final past = provider.sessions
                      .where((s) => !_isLive(s))
                      .toList();

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── Create session card ───────────────────────
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              await context.push(
                                '/attendance/home/list',
                                extra: widget.isScoped
                                    ? {
                                        'courseCode': widget.courseCode,
                                        'courseName': widget.courseName,
                                      }
                                    : null,
                              );
                              if (mounted) _reload();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.12),
                                ),
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
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.green.withOpacity(
                                      0.12,
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Create Attendance Session',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.isScoped
                                              ? 'Create a session for ${widget.courseCode}'
                                              : 'Create a class session and mark attendance',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (provider.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (provider.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              provider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else ...[
                          if (live.isNotEmpty) ...[
                            _sectionHeader('Active Sessions', Colors.green),
                            ...live.map(_buildSessionCard),
                            const SizedBox(height: 16),
                          ],
                          _sectionHeader(
                            'Past Sessions',
                            provider.sessions.isEmpty
                                ? Colors.black54
                                : Colors.black87,
                          ),
                          if (past.isEmpty && live.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text('No attendance sessions yet'),
                              ),
                            )
                          else if (past.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No past sessions',
                                  style: TextStyle(color: Colors.black38),
                                ),
                              ),
                            )
                          else
                            ...past.map(_buildSessionCard),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Top header ────────────────────────────────────────────────
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
                        headerTitle,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
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
