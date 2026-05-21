import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../graphql/graphql_service.dart';

class AssessmentsState {
  final bool isLoading;
  final List<Map<String, dynamic>> assessments;
  final String? role;

  const AssessmentsState({
    this.isLoading = false,
    this.assessments = const [],
    this.role,
  });

  AssessmentsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? assessments,
    String? role,
  }) {
    return AssessmentsState(
      isLoading: isLoading ?? this.isLoading,
      assessments: assessments ?? this.assessments,
      role: role ?? this.role,
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
    state = state.copyWith(isLoading: true);
    String? role;
    try {
      final user = await _graphqlService.me();
      role = user['role'] as String?;
    } catch (_) {
      role = null;
    }

    try {
      final list = await _graphqlService.getAllMyAssessments();
      state = state.copyWith(assessments: list, role: role, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, role: role);
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
