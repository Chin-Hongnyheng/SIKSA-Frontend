import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/attendance_session_model.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/floating_line_background.dart';
import '../../widgets/student_mini_dashboard.dart';
import '../../service/course_service.dart';

class SessionAttendancePage extends StatefulWidget {
  final String sessionId;

  const SessionAttendancePage({super.key, required this.sessionId});

  @override
  State<SessionAttendancePage> createState() => _SessionAttendancePageState();
}

class _SessionAttendancePageState extends State<SessionAttendancePage> {
  bool isLoading = true;
  String? errorMessage;

  AttendanceSessionModel? session;
  List<Map<String, dynamic>> students = [];
  Map<String, String> selectedStatus = {};

  Timer? _passwordTimer;
  Timer? _pollTimer;
  int remainingSeconds = 0;

  // Guards against calling finalizeAbsentees more than once per session.
  bool _absenteesFinalized = false;

  @override
  void initState() {
    super.initState();
    loadPage();
  }

  @override
  void dispose() {
    _passwordTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> loadPage() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final provider = context.read<AttendanceProvider>();

      final fetchedSession = await provider.getSessionById(widget.sessionId);
      if (fetchedSession == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Session not found';
        });
        return;
      }

      final rawStudents = await CourseService().getCourseSubscribers(
        fetchedSession.courseCode,
      );

      await provider.loadSessionAttendance(widget.sessionId);
      final loadedStatus = Map<String, String>.from(provider.selectedStatus);

      if (!mounted) return;

      setState(() {
        session = fetchedSession;
        students = rawStudents
            .map<Map<String, dynamic>>(
              (s) => Map<String, dynamic>.from(s as Map),
            )
            .toList();
        selectedStatus = loadedStatus;
        isLoading = false;
      });

      _startPasswordCountdown();
      _maybeFinalizeAbsentees();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      final provider = context.read<AttendanceProvider>();
      await provider.loadSessionAttendance(widget.sessionId);
      if (!mounted) return;
      setState(() {
        selectedStatus = Map<String, String>.from(provider.selectedStatus);
      });
    });
  }

  void _startPasswordCountdown() {
    _passwordTimer?.cancel();
    if (session == null) return;

    remainingSeconds = _getRemainingSeconds(session!.passwordExpiresAt);

    _passwordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds <= 0) {
        timer.cancel();
        await _refreshPassword();
        return;
      }
      setState(() => remainingSeconds--);
      // Cheap to check every tick; the guard inside makes it a no-op
      // once it has already run for this session.
      _maybeFinalizeAbsentees();
    });
  }

  int _getRemainingSeconds(String expiresAtText) {
    try {
      final ms = int.tryParse(expiresAtText);
      final expiresAt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.parse(expiresAtText).toLocal();
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns true once the current time has passed the session's end time
  /// (combining session.date + session.endTime).
  bool _isSessionEnded() {
    final s = session;
    if (s == null) return false;
    try {
      final dateParts = s.date.split('-').map(int.parse).toList();
      final timeParts = s.endTime.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length < 2) return false;
      final end = DateTime(
        dateParts[0],
        dateParts[1],
        dateParts[2],
        timeParts[0],
        timeParts[1],
      );
      return DateTime.now().isAfter(end);
    } catch (_) {
      return false;
    }
  }

  /// Auto-marks every subscriber who hasn't been checked in (manually or
  /// via QR scan) as absent, once the session's end time has passed.
  /// Runs at most once per page lifecycle via [_absenteesFinalized].
  Future<void> _maybeFinalizeAbsentees() async {
    if (_absenteesFinalized) return;
    if (session == null) return;
    if (!_isSessionEnded()) return;

    _absenteesFinalized = true;

    final subscriberIds = students
        .map((s) => s['id']?.toString())
        .whereType<String>()
        .toList();

    if (subscriberIds.isEmpty) return;

    await context.read<AttendanceProvider>().finalizeAbsentees(
      sessionId: session!.id,
      courseCode: session!.courseCode,
      date: session!.date,
      subscriberIds: subscriberIds,
    );

    if (!mounted) return;
    setState(() {
      selectedStatus = Map<String, String>.from(
        context.read<AttendanceProvider>().selectedStatus,
      );
    });
  }

  Future<void> _refreshPassword() async {
    // Don't keep refreshing the password after the session has ended.
    if (_isSessionEnded()) {
      await _maybeFinalizeAbsentees();
      return;
    }
    final updated = await context
        .read<AttendanceProvider>()
        .refreshSessionPassword(widget.sessionId);
    if (!mounted) return;
    if (updated != null) {
      setState(() => session = updated);
      _startPasswordCountdown();
    }
  }

  /// QR payload encodes both the password and sessionId so the student
  /// app can verify the session context when scanning.
  String _qrPayload() {
    final s = session;
    if (s == null) return '';
    return '{"type":"attendance","sessionId":"${s.id}","password":"${s.password}"}';
  }

  Future<void> markStudent(String studentId, String status) async {
    if (session == null) return;

    setState(() => selectedStatus[studentId] = status);

    String? checkIn;
    if (status == 'present') {
      checkIn = session!.startTime;
    } else if (status == 'late') {
      checkIn = session!.endTime;
    }

    await context.read<AttendanceProvider>().markStudent(
      studentId: studentId,
      courseCode: session!.courseCode,
      sessionId: widget.sessionId,
      date: session!.date,
      status: status,
      checkIn: checkIn,
    );

    if (!mounted) return;

    final providerStatus = context
        .read<AttendanceProvider>()
        .selectedStatus[studentId];
    if (providerStatus != null && providerStatus != selectedStatus[studentId]) {
      setState(() => selectedStatus[studentId] = providerStatus);
    }
  }

  void _showMiniDashboard(Map<String, dynamic> student) {
    final studentId = student['id']?.toString() ?? '';
    final studentName = student['userName']?.toString() ?? studentId;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$studentName Attendance',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: StudentMiniDashboard(
                    studentId: studentId,
                    studentName: studentName,
                    courseCode: session?.courseCode ?? '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton({
    required String studentId,
    required String status,
    required String label,
    required Color color,
  }) {
    final isSelected = selectedStatus[studentId] == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => markStudent(studentId, status),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentRow(Map<String, dynamic> student) {
    final studentId = student['id']?.toString() ?? '';
    final studentName = student['userName']?.toString() ?? 'No Name';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showMiniDashboard(student),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.bar_chart, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusButton(
                studentId: studentId,
                status: 'present',
                label: 'Present',
                color: Colors.green,
              ),
              _statusButton(
                studentId: studentId,
                status: 'late',
                label: 'Late',
                color: Colors.orange,
              ),
              _statusButton(
                studentId: studentId,
                status: 'absent',
                label: 'Absent',
                color: Colors.red,
              ),
              _statusButton(
                studentId: studentId,
                status: 'permission',
                label: 'Permission',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Session info card — passcode + QR side by side, shared timer beneath
  // ─────────────────────────────────────────────────────────────────────────
  Widget _sessionInfoCard() {
    if (session == null) return const SizedBox.shrink();

    final totalSeconds = session!.passwordRefreshSeconds;
    final progress = totalSeconds > 0
        ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final timerColor = remainingSeconds <= 10 ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date / time header
          Row(
            children: [
              Expanded(
                child: Text(
                  '${session!.date}  •  ${session!.startTime} – ${session!.endTime}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_isSessionEnded())
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CLOSED',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Passcode (left) + QR (right) ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: passcode block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Code',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session!.password,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Circular countdown sits below the passcode on the left
                    Row(
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(timerColor),
                              ),
                              Center(
                                child: Text(
                                  '$remainingSeconds',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: timerColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Refreshes in\n$remainingSeconds s',
                          style: TextStyle(
                            fontSize: 11,
                            color: timerColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right: QR code block
              Column(
                children: [
                  const Text(
                    'Or scan QR',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    // Key forces QR widget to rebuild when password changes
                    child: QrImageView(
                      key: ValueKey(session!.password),
                      data: _qrPayload(),
                      version: QrVersions.auto,
                      size: 120,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1B3B22),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1B3B22),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Full-width linear progress bar at the bottom
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(timerColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
              child: RefreshIndicator(
                onRefresh: loadPage,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sessionInfoCard(),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (students.isEmpty)
                      const Center(child: Text('No students found'))
                    else
                      ...students.map(_studentRow),
                  ],
                ),
              ),
            ),
          ),
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        session?.title ?? 'Attendance',
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
