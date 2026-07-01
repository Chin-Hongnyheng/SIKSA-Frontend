import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/assessment_model.dart';
import '../models/assessment_folder_model.dart';
import '../service/assessment_service.dart';
import 'dart:convert';


class AssessmentProvider extends ChangeNotifier {
  final AssessmentService _assessmentService = AssessmentService();
  static const _folderStorageKey = 'assessment_folders';

  List<AssessmentModel> _assessments = [];
  bool isLoading = false;
  String? error;

  List<AssessmentModel> get assessments {
    final list = List<AssessmentModel>.from(_assessments);
    list.sort((a, b) {
      final aKey = '${a.courseCode}|${a.assessmentName}';
      final bKey = '${b.courseCode}|${b.assessmentName}';
      final aIdx = _customAssessmentOrder.indexOf(aKey);
      final bIdx = _customAssessmentOrder.indexOf(bKey);

      if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
      if (aIdx != -1) return -1;
      if (bIdx != -1) return 1;
      return 0;
    });
    return list;
  }

  List<String> get assessmentName =>
      assessments.map((e) => e.assessmentName).toList();

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

  List<AssessmentModel> get allAssessments {
    final list = List<AssessmentModel>.from(_allAssessments);

    list.sort((a, b) {
      final aKey = '${a.courseCode}|${a.assessmentName}';
      final bKey = '${b.courseCode}|${b.assessmentName}';
      final aIdx = _customAssessmentOrder.indexOf(aKey);
      final bIdx = _customAssessmentOrder.indexOf(bKey);

      if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
      if (aIdx != -1) return -1;
      if (bIdx != -1) return 1;
      return 0; // Both not in order, keep original
    });

    return list;
  }

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
      _syncCustomOrder();
      isLoading = false;
      notifyListeners();
    }
  }

  void _syncCustomOrder() {
    // Ensure all current assessments are in the custom order list
    bool changed = false;
    for (final a in _allAssessments) {
      final key = '${a.courseCode}|${a.assessmentName}';
      if (!_customAssessmentOrder.contains(key)) {
        _customAssessmentOrder.add(key);
        changed = true;
      }
    }
    // Remove stale keys
    final currentKeys = _allAssessments
        .map((a) => '${a.courseCode}|${a.assessmentName}')
        .toSet();
    final previousLength = _customAssessmentOrder.length;
    _customAssessmentOrder.removeWhere((key) => !currentKeys.contains(key));
    if (changed || _customAssessmentOrder.length != previousLength) {
      _saveSortPreferences();
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
      if (folder.assessmentKeys.contains(key)) {
        await removeFromFolder(courseCode, assessmentName);
      }
    }

    await loadAllAssessments();
  }

  // ═══════════════════════════════════════════════════════════════
  //  Folder Management (persisted via Database API)
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

  /// Load folders from API (and migrate from SharedPreferences if needed).
  Future<void> loadFolders() async {
    try {
      final result = await _assessmentService.getMyAssessmentFolders();
      _folders = result
          .map(
            (e) => AssessmentFolderModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
      _folders.sort((a, b) => a.order.compareTo(b.order));

      // Migration from local storage
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_folderStorageKey);
      if (_folders.isEmpty && jsonStr != null && jsonStr.isNotEmpty) {
        final localFolders = AssessmentFolderModel.decodeList(jsonStr);
        if (localFolders.isNotEmpty) {
          for (final localFolder in localFolders) {
            final newFolderData = await _assessmentService
                .createAssessmentFolder(
                  name: localFolder.name,
                  colorHex: localFolder.colorHex,
                  assessmentKeys: localFolder.assessmentKeys,
                );
            _folders.add(
              AssessmentFolderModel.fromJson(
                Map<String, dynamic>.from(newFolderData),
              ),
            );
          }
          await prefs.remove(_folderStorageKey);
        }
      }
    } catch (e) {
      // In case of error, just set to empty or fallback to local
      _folders = [];
    }

    // Load sort preferences for assessments
    final prefs = await SharedPreferences.getInstance();
    final orderStr = prefs.getString(_customOrderStorageKey);
    if (orderStr != null && orderStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(orderStr);
        _customAssessmentOrder = decoded.cast<String>();
      } catch (_) {
        _customAssessmentOrder = [];
      }
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  Assessment Sorting
  // ═══════════════════════════════════════════════════════════════

  static const _customOrderStorageKey = 'assessment_custom_order';

  List<String> _customAssessmentOrder = [];

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customOrderStorageKey,
      jsonEncode(_customAssessmentOrder),
    );
  }

  void sortAssessmentsAlphabetically() {
    final list = List<AssessmentModel>.from(_allAssessments);
    list.sort(
      (a, b) => a.assessmentName.toLowerCase().compareTo(
        b.assessmentName.toLowerCase(),
      ),
    );
    _customAssessmentOrder = list
        .map((a) => '${a.courseCode}|${a.assessmentName}')
        .toList();
    _saveSortPreferences();
    notifyListeners();
  }

  void reorderAssessments(
    int oldIndex,
    int newIndex,
    List<AssessmentModel> displayedList,
  ) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = displayedList[oldIndex];
    final key = '${item.courseCode}|${item.assessmentName}';

    // The displayed list without the moved item
    final remainingDisplayed = List<AssessmentModel>.from(displayedList)
      ..removeAt(oldIndex);

    // Remove the item from the custom order list
    _customAssessmentOrder.remove(key);

    if (newIndex < remainingDisplayed.length) {
      // Find the item that will immediately follow our moved item
      final targetItem = remainingDisplayed[newIndex];
      final targetKey = '${targetItem.courseCode}|${targetItem.assessmentName}';

      final targetIdx = _customAssessmentOrder.indexOf(targetKey);
      if (targetIdx != -1) {
        _customAssessmentOrder.insert(targetIdx, key);
      } else {
        _customAssessmentOrder.add(key);
      }
    } else {
      // If it's placed at the end of the displayed list
      if (remainingDisplayed.isNotEmpty) {
        final lastItem = remainingDisplayed.last;
        final lastKey = '${lastItem.courseCode}|${lastItem.assessmentName}';
        final lastIdx = _customAssessmentOrder.indexOf(lastKey);
        if (lastIdx != -1) {
          _customAssessmentOrder.insert(lastIdx + 1, key);
        } else {
          _customAssessmentOrder.add(key);
        }
      } else {
        _customAssessmentOrder.add(key);
      }
    }

    _saveSortPreferences();
    notifyListeners();
  }

  /// Update an existing folder's name and color.
  Future<void> updateFolder(
    String folderId,
    String name,
    String colorHex,
  ) async {
    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      try {
        final updatedData = await _assessmentService.updateAssessmentFolder(
          id: folderId,
          name: name,
          colorHex: colorHex,
        );
        _folders[idx] = AssessmentFolderModel.fromJson(
          Map<String, dynamic>.from(updatedData),
        );
        notifyListeners();
      } catch (e) {
        // Handle error
      }
    }
  }

  /// Create a new custom folder.
  Future<AssessmentFolderModel> createFolder(
    String name,
    String colorHex,
  ) async {
    try {
      final folderData = await _assessmentService.createAssessmentFolder(
        name: name,
        colorHex: colorHex,
      );
      final folder = AssessmentFolderModel.fromJson(
        Map<String, dynamic>.from(folderData),
      );
      _folders.add(folder);
      notifyListeners();
      return folder;
    } catch (e) {
      // Fallback
      return AssessmentFolderModel(id: '', name: name, colorHex: colorHex);
    }
  }

  /// Delete a custom folder by id.
  Future<void> deleteFolder(String folderId) async {
    try {
      await _assessmentService.deleteAssessmentFolder(folderId);
      _folders.removeWhere((f) => f.id == folderId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Reorder folders by replacing the list with a new ordering.
  Future<void> reorderFolders(List<AssessmentFolderModel> newOrder) async {
    _folders = List.from(newOrder);
    notifyListeners();
    try {
      await _assessmentService.reorderAssessmentFolders(
        _folders.map((e) => e.id).toList(),
      );
    } catch (e) {
      // Handle error
    }
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

    try {
      // Add to the target folder
      final target = _folders.firstWhere((f) => f.id == folderId);
      final updatedKeys = List<String>.from(target.assessmentKeys)..add(key);

      final updatedData = await _assessmentService.updateAssessmentFolder(
        id: folderId,
        assessmentKeys: updatedKeys,
      );

      final idx = _folders.indexWhere((f) => f.id == folderId);
      if (idx != -1) {
        _folders[idx] = AssessmentFolderModel.fromJson(
          Map<String, dynamic>.from(updatedData),
        );
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Remove an assessment from its current folder.
  Future<void> removeFromFolder(
    String courseCode,
    String assessmentName,
  ) async {
    final key = '$courseCode|$assessmentName';
    for (int i = 0; i < _folders.length; i++) {
      if (_folders[i].assessmentKeys.contains(key)) {
        try {
          final updatedKeys = List<String>.from(_folders[i].assessmentKeys)
            ..remove(key);
          final updatedData = await _assessmentService.updateAssessmentFolder(
            id: _folders[i].id,
            assessmentKeys: updatedKeys,
          );
          _folders[i] = AssessmentFolderModel.fromJson(
            Map<String, dynamic>.from(updatedData),
          );
          notifyListeners();
        } catch (e) {
          // Handle error
        }
      }
    }
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
