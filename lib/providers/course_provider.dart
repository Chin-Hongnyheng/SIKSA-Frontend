import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../service/Course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _courseService = CourseService();

  List<CourseModel> _courses = [];
  bool isLoading = false;
  String? error;

  List<CourseModel> get courses => _courses;

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

  void addCourse(CourseModel course) {
    _courses.add(course);
    notifyListeners();
  }

  void removeCourse(String courseCode) {
    _courses.removeWhere((e) => e.courseCode == courseCode);
    notifyListeners();
  }
}
