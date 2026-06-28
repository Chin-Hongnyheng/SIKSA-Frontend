import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';

class CourseService {
  GraphQLClient _authClient() {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    return GraphQLClient(link: authLink, cache: GraphQLCache());
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

  Future<List<dynamic>> getMyCourses() async {
    final authClient = _authClient();

    const String query = """
      query GetMyCourses {
        getMyCourses {
          courseName
          courseCode
          description
          createdBy
          createdAt
          subscriberCount
          isSubscribed
          courseImg
          subscribers {
            id
            userName
            email
          }
        }
      }
    """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getMyCourses'];
  }

  Future<List<dynamic>> getAllCourses() async {
    final authClient = _authClient();

    const String query = """
      query GetAllCourses {
        getAllCourses {
          courseName
          courseCode
          description
          createdBy
          createdAt
          subscriberCount
          isSubscribed
          courseImg
          subscribers {
            id
            userName
            email
          }
        }
      }
    """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getAllCourses'];
  }

  Future<Map<String, dynamic>> getCourseByCode(String courseCode) async {
    final authClient = _authClient();

    const String query = """
      query GetCourseByCode(\$courseCode: String!) {
        getCourseByCode(courseCode: \$courseCode) {
          courseName
          courseCode
          description
          createdBy
          createdAt
          subscriberCount
          isSubscribed
          courseImg
          subscribers {
            id
            userName
            email
          }
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(document: gql(query), variables: {"courseCode": courseCode}),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return Map<String, dynamic>.from(result.data!['getCourseByCode']);
  }

  Future<String> createCourse({
    required String courseName,
    required String courseCode,
    String? description,
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation CreateCourse(\$input: CreateCourseInput!) {
        createCourse(input: \$input) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "courseName": courseName,
            "courseCode": courseCode,
            "description": description,
          },
        },
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['createCourse']['message'];
  }

  Future<String> editCourse({
    required String courseCode,
    String? courseName,
    String? newCourseCode,
    String? description,
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation EditCourse(\$input: EditCourseInput!) {
        editCourse(input: \$input) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "courseCode": courseCode,
            "courseName": courseName,
            "newCourseCode": newCourseCode,
            "description": description,
          },
        },
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['editCourse']['message'];
  }

  Future<String> deleteCourse({required String courseCode}) async {
    final authClient = _authClient();

    const String mutation = """
      mutation DeleteCourse(\$input: DeleteCourseInput!) {
        deleteCourse(input: \$input) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"courseCode": courseCode},
        },
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['deleteCourse']['message'];
  }

  Future<String> subscribeCourse({required String courseCode}) async {
    final authClient = _authClient();

    const String mutation = """
      mutation SubscribeCourse(\$courseCode: String!) {
        subscribeCourse(courseCode: \$courseCode) {
          message
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {"courseCode": courseCode},
      ),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['subscribeCourse']['message'];
  }

  Future<int> getMyTotalStudents() async {
    final authClient = _authClient();

    const String query = """
      query GetMyTotalStudents {
        getMyTotalStudents
      }
    """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return int.tryParse(result.data!['getMyTotalStudents'].toString()) ?? 0;
  }

  Future<List<dynamic>> getCourseSubscribers(String courseCode) async {
    final authClient = _authClient();

    const String query = """
      query GetCourseSubscribers(\$courseCode: String!) {
        getCourseSubscribers(courseCode: \$courseCode) {
          id
          userName
          email
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(document: gql(query), variables: {"courseCode": courseCode}),
    );

    if (result.hasException) {
      throw _exceptionFromResult(result);
    }

    return result.data!['getCourseSubscribers'];
  }

  Future<String> uploadCourseImage({
    required String courseCode,
    required File imageFile,
  }) async {
    final uri = Uri.parse(
      '${dotenv.env['BASE_URL']}/courses/$courseCode/image',
    );

    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer ${AuthProvider.accessToken}'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode != 200) {
      throw Exception(json['message'] ?? 'Upload failed');
    }

    return json['course_img'];
  }
}
