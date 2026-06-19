import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/api_helper.dart';
import '../providers/auth_provider.dart';

class AssessmentService {
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

  static const String _assessmentFields = '''
    assessmentName
    courseCode
    guide
    icon
    color
    imageBase64
    createdBy
    createdAt
  ''';

  Future<List<dynamic>> getMyAssessments() async {
    final authClient = _authClient();

    final String query =
        """
      query GetMyAssessments {
        getAllMyAssessments {
          $_assessmentFields
        }
      }       
      """;
    final result = await authClient.query(QueryOptions(document: gql(query)));
    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getAllMyAssessments'];
  }

  Future<List<dynamic>> getAssessmentsByCourseCode(String courseCode) async {
    final authClient = _authClient();

    final String query =
        """
      query GetAssessmentsByCourseCode(\$courseCode: String!) {
        getAssessmentsByCourseCode(courseCode: \$courseCode) {
          $_assessmentFields
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(document: gql(query), variables: {'courseCode': courseCode}),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getAssessmentsByCourseCode'];
  }

  Future<List<dynamic>> getAllMyAssessments() async {
    final authClient = _authClient();

    final String query =
        """
    query {
      getAllMyAssessments {
        $_assessmentFields
      }
    }
  """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getAllMyAssessments'];
  }

  Future<String> createAssessment({
    required String courseCode,
    required String assessmentName,
    String? guide,
    String? icon,
    String? color,
    String? imageBase64,
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation CreateAssessment(\$input: CreateAssessmentInput!) {
        createAssessment(input: \$input) {
          message
        }
      }
    """;

    final Map<String, dynamic> input = {
      "courseCode": courseCode,
      "assessmentName": assessmentName,
      "guide": guide,
    };

    if (icon != null && icon.isNotEmpty) input["icon"] = icon;
    if (color != null && color.isNotEmpty) input["color"] = color;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      input["imageBase64"] = imageBase64;
    }

    final result = await authClient.mutate(
      MutationOptions(document: gql(mutation), variables: {"input": input}),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['createAssessment']['message'];
  }

  Future<String> deleteAssessment({
    required String courseCode,
    required String assessmentName,
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation DeleteAssessment(\$input: DeleteAssessmentInput!) {
        deleteAssessment(input: \$input) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"courseCode": courseCode, "assessmentName": assessmentName},
        },
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['deleteAssessment']['message'];
  }
}
