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
      _assessments = result.map((e) => AssessmentModel.fromMap(e)).toList();
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
      _allAssessments = result.map((e) => AssessmentModel.fromMap(e)).toList();
      _assessments = List<AssessmentModel>.from(_allAssessments);
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

  void removeAssessment(String assessmentId) {
    _assessments.removeWhere(
      (assessment) => assessment.assessmentName == assessmentId,
    );
    _allAssessments.removeWhere(
      (assessment) => assessment.assessmentName == assessmentId,
    );
    notifyListeners();
  }

  Future<void> createAssessment({
    required String courseCode,
    required String assessmentName,
  }) async {
    await _assessmentService.createAssessment(
      courseCode: courseCode,
      assessmentName: assessmentName,
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
    _assessments.removeWhere(
      (assessment) =>
          assessment.courseCode == courseCode &&
          assessment.assessmentName == assessmentName,
    );
    _allAssessments.removeWhere(
      (assessment) =>
          assessment.courseCode == courseCode &&
          assessment.assessmentName == assessmentName,
    );
    notifyListeners();
  }
}
