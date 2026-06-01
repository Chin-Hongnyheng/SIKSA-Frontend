import 'package:flutter/material.dart';

import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';
import '../service/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  bool isLoading = false;
  String? errorMessage;

  List<AttendanceSessionModel> sessions = [];
  List<AttendanceRecordModel> sessionRecords = [];
  List<AttendanceRecordModel> studentRecords = [];

  Map<String, String> selectedStatus = {};

  Future<List<Map<String, dynamic>>> getCourses() {
    return _service.getCourses();
  }

  Future<List<Map<String, dynamic>>> getStudentsFromCourse(String courseId) {
    return _service.getStudentsFromCourse(courseId);
  }

  Future<AttendanceSessionModel?> createAttendanceSession({
    required String courseId,
    required String teacherId,
    required String title,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final session = await _service.createAttendanceSession(
        courseId: courseId,
        teacherId: teacherId,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );

      isLoading = false;
      notifyListeners();

      return session;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadSessionsByCourse(String courseId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      sessions = await _service.getAttendanceSessionsByCourse(courseId);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSessionAttendance(String sessionId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      sessionRecords = await _service.getSessionAttendance(sessionId);

      selectedStatus = {};
      for (final record in sessionRecords) {
        selectedStatus[record.studentId] = record.status;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadStudentRecords(String studentId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      studentRecords = await _service.getStudentAttendanceRecords(studentId);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markStudent({
    required String studentId,
    required String courseId,
    required String sessionId,
    required String date,
    required String status,
    String? checkIn,
    String? checkOut,
  }) async {
    selectedStatus[studentId] = status;
    notifyListeners();

    try {
      await _service.markAttendance(
        studentId: studentId,
        courseId: courseId,
        sessionId: sessionId,
        date: date,
        status: status,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      await loadSessionAttendance(sessionId);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}