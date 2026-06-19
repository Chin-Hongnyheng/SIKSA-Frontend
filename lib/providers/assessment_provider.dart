import 'package:flutter/material.dart';
import '../models/assessment_model.dart';
import '../service/Assessment_service.dart';

class AssessmentProvider extends ChangeNotifier {
  final AssessmentService _assessmentService = AssessmentService();

  List<AssessmentModel> _assessments = [];
  bool isLoading = false;
  String? error;

  List<AssessmentModel> get assessments => _assessments;
  List<String> get assessmentName =>
      _assessments.map((e) => e.assessmentName).toList();

  Future<void> loadAssessments(String courseCode) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _assessmentService.getAssessmentsByCourseCode(
        courseCode,
      );
      _assessments = result
          .map((e) => AssessmentModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<AssessmentModel> _allAssessments = [];
  List<AssessmentModel> get allAssessments => _allAssessments;
  Future<void> loadAllAssessments() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _assessmentService.getAllMyAssessments();
      _allAssessments = result
          .map((e) => AssessmentModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearAssessments() {
    _assessments = [];
    notifyListeners();
  }

  void addAssessment(AssessmentModel assessment) {
    _assessments.add(assessment);
    _allAssessments.add(assessment);
    notifyListeners();
  }

  void removeAssessment({
    required String courseCode,
    required String assessmentName,
  }) {
    _assessments.removeWhere(
      (e) => e.courseCode == courseCode && e.assessmentName == assessmentName,
    );
    _allAssessments.removeWhere(
      (e) => e.courseCode == courseCode && e.assessmentName == assessmentName,
    );
    notifyListeners();
  }

  Future<void> createAssessment({
    required String courseCode,
    required String assessmentName,
    String? guide,
    String? icon,
    String? color,
    String? imageBase64,
  }) async {
    await _assessmentService.createAssessment(
      courseCode: courseCode,
      assessmentName: assessmentName,
      guide: guide,
      icon: icon,
      color: color,
      imageBase64: imageBase64,
    );
    await loadAllAssessments();
  }

  Future<void> deleteAssessment({
    required String courseCode,
    required String assessmentName,
  }) async {
    await _assessmentService.deleteAssessment(
      courseCode: courseCode,
      assessmentName: assessmentName,
    );
    removeAssessment(courseCode: courseCode, assessmentName: assessmentName);
    await loadAllAssessments();
  }
}
