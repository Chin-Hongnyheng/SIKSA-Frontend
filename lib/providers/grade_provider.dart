import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../service/grade_service.dart';

class GradeProvider extends ChangeNotifier {
  final GradeService _gradeService = GradeService();

  List<GradeModel> _grades = [];
  bool isLoading = false;
  String? error;

  List<GradeModel> get grades => _grades;

  /// Load all grades for a given course
  Future<void> loadGradesByCourse(String courseCode) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _gradeService.getGradesByCourse(courseCode);
      _grades = result
          .map((e) => GradeModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Save a single grade
  Future<void> saveGrade({
    required String studentId,
    required String courseCode,
    required String assessmentName,
    required double score,
    double maxScore = 100,
  }) async {
    await _gradeService.upsertGrade(
      studentId: studentId,
      courseCode: courseCode,
      assessmentName: assessmentName,
      score: score,
      maxScore: maxScore,
    );
  }

  /// Batch save multiple grades
  Future<void> saveAllGrades(List<Map<String, dynamic>> grades) async {
    await _gradeService.upsertGrades(grades);
  }

  void clearGrades() {
    _grades = [];
    notifyListeners();
  }
}
