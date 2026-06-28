import 'dart:io';

import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../service/Course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _courseService = CourseService();

  List<CourseModel> _courses = [];
  List<CourseModel> _allCourses = [];
  int _teacherStudentCount = 0;
  final Map<String, List<CourseSubscriberModel>> _courseSubscribers = {};

  bool isLoading = false;
  bool isLoadingAll = false;
  String? error;
  String? errorAll;

  List<CourseModel> get courses => _courses;
  List<CourseModel> get allCourses => _allCourses;
  int get teacherStudentCount => _teacherStudentCount;
  Map<String, List<CourseSubscriberModel>> get courseSubscribers =>
      _courseSubscribers;
  List<String> get courseCodes => _courses.map((e) => e.courseCode).toList();

  Future<void> loadCourses() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _courseService.getMyCourses();
      _courses = result.map((e) => CourseModel.fromMap(e)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllCourses() async {
    isLoadingAll = true;
    errorAll = null;
    notifyListeners();
    try {
      final result = await _courseService.getAllCourses();
      _allCourses = result.map((e) => CourseModel.fromMap(e)).toList();
    } catch (e) {
      errorAll = e.toString();
    } finally {
      isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> createCourse({
    required String courseName,
    required String courseCode,
    String? description,
  }) async {
    await _courseService.createCourse(
      courseName: courseName,
      courseCode: courseCode,
      description: description,
    );
    await loadCourses();
    await loadAllCourses();
  }

  Future<void> editCourse({
    required String courseCode,
    required String courseName,
    required String newCourseCode,
    String? description,
  }) async {
    await _courseService.editCourse(
      courseCode: courseCode,
      courseName: courseName,
      newCourseCode: newCourseCode == courseCode ? null : newCourseCode,
      description: description,
    );
    await loadCourses();
    await loadAllCourses();
  }

  Future<void> deleteCourse({required String courseCode}) async {
    await _courseService.deleteCourse(courseCode: courseCode);
    _courses.removeWhere((e) => e.courseCode == courseCode);
    _allCourses.removeWhere((e) => e.courseCode == courseCode);
    notifyListeners();
    await loadCourses();
    await loadAllCourses();
  }

  Future<void> subscribeCourse({required String courseCode}) async {
    await _courseService.subscribeCourse(courseCode: courseCode);

    for (final list in [_courses, _allCourses]) {
      final index = list.indexWhere((c) => c.courseCode == courseCode);
      if (index != -1) {
        final course = list[index];
        list[index] = course.copyWith(
          isSubscribed: true,
          subscriberCount: course.subscriberCount + 1,
        );
      }
    }
    notifyListeners();

    await loadCourses();
    await loadAllCourses();
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

  Future<String> uploadCourseImage({
    required String courseCode,
    required File imageFile,
  }) async {
    final imageUrl = await _courseService.uploadCourseImage(
      courseCode: courseCode,
      imageFile: imageFile,
    );
    await loadCourses();
    await loadAllCourses();
    return imageUrl;
  }
}
