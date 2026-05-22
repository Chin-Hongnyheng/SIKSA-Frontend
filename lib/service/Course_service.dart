import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';

class CourseService {
  Future<List<dynamic>> getMyCourses() async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    final GraphQLClient authClient = GraphQLClient(
      link: authLink,
      cache: GraphQLCache(),
    );

    const String query = """
      query GetMyCourses {
        getMyCourses {
          courseName
          courseCode
          description
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

    return result.data!['getMyCourses'];
  }
}
