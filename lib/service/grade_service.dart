import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/api_helper.dart';
import '../providers/auth_provider.dart';

class GradeService {
  GraphQLClient _authClient() {
    final Link authLink = HttpLink(
      ApiHelper.resolveUrl(dotenv.env['GRAPHQL_URL']!),
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    return GraphQLClient(cache: GraphQLCache(), link: authLink);
  }

  Exception _exceptionFromResult(QueryResult result) {
    final error = result.exception.toString();

    if (error.contains('Unauthorized') || error.contains('UNAUTHENTICATED')) {
      unawaited(AuthProvider.clearTokens());
      return Exception('SESSION_EXPIRED');
    }

    final message = result.exception?.graphqlErrors.isNotEmpty == true
        ? result.exception!.graphqlErrors.first.message
        : error;

    return Exception(message);
  }

  static const String _gradeFields = '''
    studentId
    studentName
    courseCode
    assessmentName
    score
    maxScore
    gradedBy
    gradedAt
  ''';

  /// Fetch all grades for a specific course
  Future<List<dynamic>> getGradesByCourse(String courseCode) async {
    final authClient = _authClient();

    final String query =
        """
      query GetGradesByCourse(\$courseCode: String!) {
        getGradesByCourse(courseCode: \$courseCode) {
          $_gradeFields
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(document: gql(query), variables: {'courseCode': courseCode}),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getGradesByCourse'];
  }

  /// Upsert a single grade
  Future<String> upsertGrade({
    required String studentId,
    required String courseCode,
    required String assessmentName,
    required double score,
    double maxScore = 100,
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation UpsertGrade(\$input: UpsertGradeInput!) {
        upsertGrade(input: \$input) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "studentId": studentId,
            "courseCode": courseCode,
            "assessmentName": assessmentName,
            "score": score,
            "maxScore": maxScore,
          },
        },
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['upsertGrade']['message'];
  }

  /// Batch upsert multiple grades at once
  Future<String> upsertGrades(List<Map<String, dynamic>> grades) async {
    final authClient = _authClient();

    const String mutation = """
      mutation UpsertGrades(\$input: UpsertGradesInput!) {
        upsertGrades(input: \$input) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"grades": grades},
        },
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['upsertGrades']['message'];
  }
}
