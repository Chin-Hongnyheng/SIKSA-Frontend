import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../service/Course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _courseService = CourseService();

  List<CourseModel> _courses = [];
  int _teacherStudentCount = 0;
  final Map<String, List<CourseSubscriberModel>> _courseSubscribers = {};
  bool isLoading = false;
  String? error;

  List<CourseModel> get courses => _courses;
  int get teacherStudentCount => _teacherStudentCount;
  Map<String, List<CourseSubscriberModel>> get courseSubscribers =>
      _courseSubscribers;

  List<String> get courseCodes => _courses.map((e) => e.courseCode).toList();

  bool _canManage(String? role) {
    final normalizedRole = role?.trim().toLowerCase();
    return normalizedRole == 'teacher' || normalizedRole == 'admin';
  }

  Future<void> loadCourses({String? role}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = _canManage(role)
          ? await _courseService.getMyCourses()
          : await _courseService.getAllCourses();
      _courses = result.map((e) => CourseModel.fromMap(e)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse({
    required String courseName,
    required String courseCode,
    String? description,
    String? role,
  }) async {
    await _courseService.createCourse(
      courseName: courseName,
      courseCode: courseCode,
      description: description,
    );
    await loadCourses(role: role);
  }

  Future<void> editCourse({
    required String courseCode,
    required String courseName,
    required String newCourseCode,
    String? description,
    String? role,
  }) async {
    await _courseService.editCourse(
      courseCode: courseCode,
      courseName: courseName,
      newCourseCode: newCourseCode == courseCode ? null : newCourseCode,
      description: description,
    );
    await loadCourses(role: role);
  }

  Future<void> deleteCourse({required String courseCode, String? role}) async {
    await _courseService.deleteCourse(courseCode: courseCode);
    _courses.removeWhere((e) => e.courseCode == courseCode);
    notifyListeners();
    await loadCourses(role: role);
  }

  Future<void> subscribeCourse({
    required String courseCode,
    String? role,
  }) async {
    await _courseService.subscribeCourse(courseCode: courseCode);
    final index = _courses.indexWhere(
      (course) => course.courseCode == courseCode,
    );
    if (index != -1) {
      final course = _courses[index];
      _courses[index] = course.copyWith(
        isSubscribed: true,
        subscriberCount: course.subscriberCount + 1,
      );
      notifyListeners();
    }
    await loadCourses(role: role);
  }

  Future<CourseModel> getCourseByCode(String courseCode) async {
    final result = await _courseService.getCourseByCode(courseCode);
    return CourseModel.fromMap(result);
  }

  Future<void> loadTeacherStudentCount() async {
    try {
      _teacherStudentCount = await _courseService.getMyTotalStudents();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<List<CourseSubscriberModel>> loadCourseSubscribers(
    String courseCode,
  ) async {
    final result = await _courseService.getCourseSubscribers(courseCode);
    final subscribers = result
        .map(
          (subscriber) => CourseSubscriberModel.fromMap(
            Map<String, dynamic>.from(subscriber as Map),
          ),
        )
        .toList();
    _courseSubscribers[courseCode] = subscribers;
    notifyListeners();
    return subscribers;
  }
}
