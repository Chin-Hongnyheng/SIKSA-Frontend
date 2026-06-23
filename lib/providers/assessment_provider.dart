import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/assessment_model.dart';
import '../models/assessment_folder_model.dart';
import '../service/Assessment_service.dart';

class AssessmentProvider extends ChangeNotifier {
  final AssessmentService _assessmentService = AssessmentService();
  static const _folderStorageKey = 'assessment_folders';

  List<AssessmentModel> _assessments = [];
  bool isLoading = false;
  String? error;

  List<AssessmentModel> get assessments => _assessments;
  List<String> get assessmentName =>
      _assessments.map((e) => e.assessmentName).toList();

  // ── Per-course assessments ──

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

  // ── All assessments ──

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

    // Also remove from any folder
    final key = '$courseCode|$assessmentName';
    for (final folder in _folders) {
      folder.assessmentKeys.remove(key);
    }
    await _saveFolders();

    await loadAllAssessments();
  }

  // ═══════════════════════════════════════════════════════════════
  //  Folder Management (persisted via SharedPreferences)
  // ═══════════════════════════════════════════════════════════════

  List<AssessmentFolderModel> _folders = [];
  List<AssessmentFolderModel> get folders => List.unmodifiable(_folders);

  /// Get the unique assessment icon types present in all assessments.
  /// Used to generate the auto type tabs (Lab, Midterm, Quiz, etc.)
  List<String> get assessmentIconTypes {
    final types = <String>{};
    for (final a in _allAssessments) {
      if (a.icon != null && a.icon!.isNotEmpty) {
        types.add(a.icon!);
      }
    }
    return types.toList()..sort();
  }

  /// Load folders from SharedPreferences.
  Future<void> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_folderStorageKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      _folders = AssessmentFolderModel.decodeList(jsonStr);
    } else {
      _folders = [];
    }
    notifyListeners();
  }

  /// Save folders to SharedPreferences.
  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _folderStorageKey,
      AssessmentFolderModel.encodeList(_folders),
    );
    notifyListeners();
  }

  /// Update an existing folder's name and color.
  Future<void> updateFolder(String folderId, String name, String colorHex) async {
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      _folders[idx] = _folders[idx].copyWith(name: name, colorHex: colorHex);
      await _saveFolders();
      notifyListeners();
    }
  }

  /// Create a new custom folder.
  Future<void> createFolder(String name, String colorHex) async {
    final folder = AssessmentFolderModel(
      id: const Uuid().v4(),
      name: name,
      colorHex: colorHex,
    );
    _folders.add(folder);
    await _saveFolders();
  }

  /// Delete a custom folder by id.
  Future<void> deleteFolder(String folderId) async {
    _folders.removeWhere((f) => f.id == folderId);
    await _saveFolders();
  }

  /// Assign an assessment to a folder (removes from any previous folder).
  Future<void> addToFolder(
    String folderId,
    String courseCode,
    String assessmentName,
  ) async {
    final key = '$courseCode|$assessmentName';

    // Remove from any existing folder first
    for (final folder in _folders) {
      folder.assessmentKeys.remove(key);
    }

    // Add to the target folder
    final target = _folders.firstWhere((f) => f.id == folderId);
    target.assessmentKeys.add(key);
    await _saveFolders();
  }

  /// Remove an assessment from its current folder.
  Future<void> removeFromFolder(
    String courseCode,
    String assessmentName,
  ) async {
    final key = '$courseCode|$assessmentName';
    for (final folder in _folders) {
      folder.assessmentKeys.remove(key);
    }
    await _saveFolders();
  }

  /// Get the folder that contains a specific assessment, or null.
  AssessmentFolderModel? getFolderForAssessment(
    String courseCode,
    String assessmentName,
  ) {
    final key = '$courseCode|$assessmentName';
    for (final folder in _folders) {
      if (folder.assessmentKeys.contains(key)) return folder;
    }
    return null;
  }
}
