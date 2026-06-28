import 'package:flutter/material.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';
import '../service/attendance_service.dart';
import 'package:flutter/foundation.dart';

enum CheckInResult {
  successPresent,
  successLate,
  alreadyMarked,
  notSubscribed,
  wrongPassword,
  sessionClosed,
  sessionNotFound,
  error,
}

class CheckInOutcome {
  final CheckInResult result;
  final String? message;
  final AttendanceSessionModel? session;

  CheckInOutcome(this.result, {this.message, this.session});
}

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  bool isLoading = false;
  String? error;

  List<AttendanceSessionModel> sessions = [];
  List<AttendanceSessionModel> activeSessions = [];
  List<AttendanceRecordModel> sessionRecords = [];
  List<AttendanceRecordModel> studentRecords = [];
  Map<String, String> selectedStatus = {};
  Map<String, int> attendanceSummary = {
    'present': 0,
    'late': 0,
    'absent': 0,
    'permission': 0,
  };
  int get attendanceRate {
    final total = attendanceSummary.values.fold(0, (sum, v) => sum + v);
    if (total == 0) return 0;
    final present =
        (attendanceSummary['present'] ?? 0) + (attendanceSummary['late'] ?? 0);
    return (present / total * 100).round();
  }

  var checkInTimes;

  // ─── Session Mutations ────────────────────────────────────────────────────

  Future<AttendanceSessionModel?> createAttendanceSession({
    required String courseCode,
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    int passwordRefreshSeconds = 60,
    int lateAfterMinutes = 15,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final session = await _service.createAttendanceSession(
        courseCode: courseCode,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        passwordRefreshSeconds: passwordRefreshSeconds,
        lateAfterMinutes: lateAfterMinutes,
      );
      sessions.insert(0, session);
      activeSessions.removeWhere((s) => s.id == session.id);
      activeSessions.insert(0, session);
      return session;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceSessionModel?> refreshSessionPassword(
    String sessionId,
  ) async {
    error = null;
    try {
      final session = await _service.refreshAttendanceSessionPassword(
        sessionId,
      );
      _updateInList(sessions, session);
      _updateInList(activeSessions, session);
      notifyListeners();
      return session;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<AttendanceSessionModel?> closeSession(String sessionId) async {
    error = null;
    try {
      final session = await _service.closeAttendanceSession(sessionId);
      _updateInList(sessions, session);
      activeSessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
      return session;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    error = null;
    try {
      final success = await _service.deleteAttendanceSession(sessionId);
      if (success) {
        sessions.removeWhere((s) => s.id == sessionId);
        activeSessions.removeWhere((s) => s.id == sessionId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Attendance Record Mutations ──────────────────────────────────────────

  Future<void> markStudent({
    required String studentId,
    required String courseCode,
    required String sessionId,
    required String date,
    String? status,
    String? checkIn,
  }) async {
    error = null;
    if (status != null) {
      selectedStatus[studentId] = status;
      notifyListeners();
    }
    try {
      final record = await _service.markAttendance(
        studentId: studentId,
        courseCode: courseCode,
        sessionId: sessionId,
        date: date,
        status: status,
        checkIn: checkIn,
      );

      final idx = sessionRecords.indexWhere((r) => r.studentId == studentId);
      if (idx != -1) {
        sessionRecords[idx] = record;
      } else {
        sessionRecords.add(record);
      }

      if (record.status != null) {
        selectedStatus[studentId] = record.status!;
      }

      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Called when a student scans the attendance QR code.
  ///
  /// Validates (in order):
  ///   1. Session exists
  ///   2. Student is subscribed to the session's course
  ///   3. Session is still active / not past its end time
  ///   4. Password in the QR matches the session's *current* password
  ///   5. Student hasn't already checked in for this session
  ///
  /// Then computes present/late from `date` + `startTime` + `lateAfterMinutes`
  /// compared against the actual scan time, and records it via [markStudent].
  Future<CheckInOutcome> checkInWithQr({
    required String sessionId,
    required String password,
    required String studentId,
    required bool isSubscribed,
  }) async {
    error = null;

    final session = await getSessionById(sessionId);
    if (session == null) {
      return CheckInOutcome(
        CheckInResult.sessionNotFound,
        message: 'Attendance session not found.',
      );
    }

    if (!isSubscribed) {
      return CheckInOutcome(
        CheckInResult.notSubscribed,
        message: 'You must join this course before checking in.',
        session: session,
      );
    }

    final now = DateTime.now();
    final sessionEnd = _combineDateTime(session.date, session.endTime);
    if (!session.isActive || (sessionEnd != null && now.isAfter(sessionEnd))) {
      return CheckInOutcome(
        CheckInResult.sessionClosed,
        message: 'This attendance session has already closed.',
        session: session,
      );
    }

    final passwordOk = await verifySessionPassword(
      sessionId: sessionId,
      password: password,
    );
    if (!passwordOk) {
      return CheckInOutcome(
        CheckInResult.wrongPassword,
        message: 'This QR code has expired. Ask your teacher to refresh it.',
        session: session,
      );
    }

    // Compute present/late based on NOW vs start + lateAfterMinutes
    final sessionStart = _combineDateTime(session.date, session.startTime);
    String status = 'present';
    if (sessionStart != null) {
      final lateThreshold = sessionStart.add(
        Duration(minutes: session.lateAfterMinutes),
      );
      if (now.isAfter(lateThreshold)) {
        status = 'late';
      }
    }

    final checkInTime = _formatTime(now);

    // Always upsert — allows re-marking even if already scanned
    await markStudent(
      studentId: studentId,
      courseCode: session.courseCode,
      sessionId: sessionId,
      date: session.date,
      status: status,
      checkIn: checkInTime,
    );

    if (error != null) {
      return CheckInOutcome(
        CheckInResult.error,
        message: 'Failed to record attendance: $error',
        session: session,
      );
    }

    return CheckInOutcome(
      status == 'late'
          ? CheckInResult.successLate
          : CheckInResult.successPresent,
      message: status == 'late'
          ? 'Checked in — marked late.'
          : 'Checked in — marked present.',
      session: session,
    );
  }

  /// Marks every subscriber not already recorded as absent.
  /// Intended to run once a session's end time has passed.
  /// [subscriberIds] should be every student id enrolled in the course.
  Future<void> finalizeAbsentees({
    required String sessionId,
    required String courseCode,
    required String date,
    required List<String> subscriberIds,
  }) async {
    final missing = subscriberIds
        .where((id) => !selectedStatus.containsKey(id))
        .toList();

    for (final studentId in missing) {
      await markStudent(
        studentId: studentId,
        courseCode: courseCode,
        sessionId: sessionId,
        date: date,
        status: 'absent',
      );
    }
  }

  // ─── Session Queries ──────────────────────────────────────────────────────

  Future<List<AttendanceSessionModel>> fetchSessionsForCode(
    String courseCode,
  ) async {
    try {
      return await _service.getAttendanceSessionsByCourse(courseCode);
    } catch (_) {
      return [];
    }
  }

  Future<void> loadSessionsByCourse(String courseCode) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      sessions = await _service.getAttendanceSessionsByCourse(courseCode);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveSessionsByCourse(String courseCode) async {
    error = null;
    try {
      final fetched = await _service.getActiveAttendanceSessionsByCourse(
        courseCode,
      );
      activeSessions.removeWhere((s) => s.courseCode == courseCode);
      activeSessions.addAll(fetched);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> verifySessionPassword({
    required String sessionId,
    required String password,
  }) async {
    error = null;
    try {
      return await _service.verifyAttendanceSessionPassword(
        sessionId: sessionId,
        password: password,
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Attendance Record Queries ────────────────────────────────────────────

  Future<void> loadSessionAttendance(String sessionId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      sessionRecords = await _service.getSessionAttendance(sessionId);
      selectedStatus = {
        for (final r in sessionRecords)
          if (r.status != null) r.studentId: r.status!,
      };
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentRecords(String studentId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      studentRecords = await _service.getStudentAttendance(studentId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCourseAttendance(String courseCode) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      sessionRecords = await _service.getCourseAttendance(courseCode);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentSummary(String studentId) async {
    error = null;
    try {
      attendanceSummary = await _service.getStudentAttendanceSummary(studentId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<AttendanceSessionModel?> getSessionById(String sessionId) async {
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {}
    try {
      return activeSessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {}

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final session = await _service.getSessionById(sessionId);
      _updateInList(sessions, session);
      return session;
    } catch (e) {
      error = e.toString();
      debugPrint('getSessionById failed for sessionId="$sessionId": $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  AttendanceSessionModel? findActiveSession({
    required String courseCode,
    required String date,
    required String startTime,
    required String endTime,
  }) {
    try {
      return activeSessions.firstWhere(
        (s) =>
            s.isActive &&
            s.courseCode == courseCode &&
            s.date == date &&
            s.startTime == startTime &&
            s.endTime == endTime,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _updateInList(
    List<AttendanceSessionModel> list,
    AttendanceSessionModel updated,
  ) {
    final index = list.indexWhere((s) => s.id == updated.id);
    if (index != -1) list[index] = updated;
  }

  /// Combines a "yyyy-MM-dd" date string with an "HH:mm" time string into
  /// a local DateTime. Returns null if either piece can't be parsed.
  DateTime? _combineDateTime(String date, String time) {
    try {
      final dateParts = date.split('-').map(int.parse).toList();
      final timeParts = time.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length < 2) return null;
      return DateTime(
        dateParts[0],
        dateParts[1],
        dateParts[2],
        timeParts[0],
        timeParts[1],
      );
    } catch (_) {
      return null;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
