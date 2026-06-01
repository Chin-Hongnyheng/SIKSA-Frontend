import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/authentication_service.dart';

class AssessmentsState {
  final bool isLoading;
  final List<Map<String, dynamic>> assessments;
  final String? role;
  final String? errorMessage;

  const AssessmentsState({
    this.isLoading = false,
    this.assessments = const [],
    this.role,
    this.errorMessage,
  });

  AssessmentsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? assessments,
    String? role,
    String? errorMessage,
    bool clearError = false,
    bool clearRole = false,
  }) {
    return AssessmentsState(
      isLoading: isLoading ?? this.isLoading,
      assessments: assessments ?? this.assessments,
      role: clearRole ? null : (role ?? this.role),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AssessmentsNotifier extends Notifier<AssessmentsState> {
  late final GraphQLService _graphqlService;

  @override
  AssessmentsState build() {
    _graphqlService = GraphQLService();
    // kick off initial load
    fetchData(silent: true);
    return const AssessmentsState();
  }

  Future<void> fetchData({bool silent = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    String? role;
    try {
      final user = await _graphqlService.me();
      role = user['role'] as String?;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearRole: true,
        errorMessage: e.toString(),
      );
      if (!silent) rethrow;
      return;
    }

    final canManage = role == 'Teacher' || role == 'Admin';
    if (!canManage) {
      state = state.copyWith(
        isLoading: false,
        role: role,
        assessments: const [],
        errorMessage:
            'Your current role ($role) cannot access this assessment list.',
      );
      return;
    }

    try {
      final list = await _graphqlService.getAllMyAssessments();
      state = state.copyWith(
        assessments: list,
        role: role,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        role: role,
        errorMessage: e.toString(),
      );
      if (!silent) rethrow;
    }
  }

  Future<void> createAssessment({
    required String courseCode,
    required String assessmentName,
  }) async {
    await _graphqlService.createAssessment(
      courseCode: courseCode,
      assessmentName: assessmentName,
    );
    await fetchData(silent: true);
  }

  Future<void> deleteAssessment({
    required String courseCode,
    required String assessmentName,
  }) async {
    await _graphqlService.deleteAssessment(
      courseCode: courseCode,
      assessmentName: assessmentName,
    );
    await fetchData(silent: true);
  }
}

final assessmentsProvider =
    NotifierProvider<AssessmentsNotifier, AssessmentsState>(
      AssessmentsNotifier.new,
    );
