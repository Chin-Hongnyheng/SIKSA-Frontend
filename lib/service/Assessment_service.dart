import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';

class AssessmentService {
  Future<List<dynamic>> getMyAssessments() async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    final GraphQLClient authClient = GraphQLClient(
      cache: GraphQLCache(),
      link: authLink,
    );

    const String query = """
      query GetMyAssessments {
        getAllMyAssessments {
          assessmentName
          courseCode
          createdBy
          createdAt
        }
      }       
      """;
    final result = await authClient.query(QueryOptions(document: gql(query)));
    if (result.hasException) {
      final error = result.exception.toString();

      if (error.contains('Unauthorized') || error.contains('UNAUTHENTICATED')) {
        await AuthProvider.clearTokens();

        throw Exception('SESSION_EXPIRED');
      }

      throw Exception(error);
    }

    return result.data!['getAllMyAssessments'];
  }

  Future<List<dynamic>> getAssessmentsByCourseCode(String courseCode) async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );
    final GraphQLClient authClient = GraphQLClient(
      cache: GraphQLCache(),
      link: authLink,
    );

    const String query = """
      query GetAssessmentsByCourseCode(\$courseCode: String!) {
        getAssessmentsByCourseCode(courseCode: \$courseCode) {
          assessmentName
          courseCode
          createdBy
          createdAt
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(document: gql(query), variables: {'courseCode': courseCode}),
    );

    if (result.hasException) {
      final error = result.exception.toString();
      if (error.contains('Unauthorized') || error.contains('UNAUTHENTICATED')) {
        await AuthProvider.clearTokens();
        throw Exception('SESSION_EXPIRED');
      }
      throw Exception(error);
    }

    return result.data!['getAssessmentsByCourseCode'];
  }

  Future<List<dynamic>> getAllMyAssessments() async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    final GraphQLClient authClient = GraphQLClient(
      link: authLink,
      cache: GraphQLCache(),
    );

    const String query = """
    query {
      getAllMyAssessments {
        assessmentName
        courseCode
        createdBy
        createdAt
      }
    }
  """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      final error = result.exception.toString();
      if (error.contains("Unauthorized") || error.contains('UNAUTHORIZED')) {
        await AuthProvider.clearTokens();
        throw Exception('SESSION_EXPIRED');
      }
      throw Exception(error);
    }

    return result.data!['getAllMyAssessments'];
  }
}
