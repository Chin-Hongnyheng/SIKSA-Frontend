import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';

class ScheduleService {
  Future<GraphQLClient> _getAuthClient() async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    return GraphQLClient(link: authLink, cache: GraphQLCache());
  }

  Future<String> createSchedule({
    required String courseCode,
    required String location,
    required String startTime,
    required String endTime,
    required String color,
    required int reminder,
    required String recurrenceType,
    String? date,
    String? startDate,
    String? endDate,
    List<String>? selectedDays,
  }) async {
    final client = await _getAuthClient();

    const String mutation = """
      mutation createSchedule(\$input: CreateScheduleInput!) {
        createSchedule(input: \$input) {
          message
        }
      }
    """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "courseCode": courseCode,
            "location": location,
            "startTime": startTime,
            "endTime": endTime,
            "color": color,
            "reminder": reminder,
            "recurrenceType": recurrenceType,
            "date": date,
            "startDate": startDate,
            "endDate": endDate,
            "selectedDays": selectedDays,
          },
        },
      ),
    );

    if (result.hasException) {
      final exception = result.exception!;

      if (exception.toString().contains('Unauthorized') ||
          exception.toString().contains('UNAUTHENTICATED')) {
        await AuthProvider.clearTokens();
        throw Exception('SESSION_EXPIRED');
      }

      if (exception.graphqlErrors.isNotEmpty) {
        final backendMessage = exception.graphqlErrors.first.message;

        throw Exception(backendMessage);
      }

      // Fallback
      throw Exception("Something went wrong");
    }

    return result.data!['createSchedule']['message'];
  }

  Future<String> deleteSchedule({required String scheduleId}) async {
    final client = await _getAuthClient();

    const String mutation = """
      mutation deleteSchedule(\$input: DeleteScheduleInput!) {
        deleteSchedule(input: \$input) {
          message
        }
      }
    """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"scheduleId": scheduleId},
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!['deleteSchedule']['message'];
  }

  Future<String> editSchedule({
    required String scheduleId,
    required String courseCode,
    required String location,
    required String startTime,
    required String endTime,
    required String color,
    required int reminder,
    required String recurrenceType,
    String? date,
    String? startDate,
    String? endDate,
    List<String>? selectedDays,
  }) async {
    final client = await _getAuthClient();

    const String mutation = """
      mutation editSchedule(\$input: EditScheduleInput!) {
        editSchedule(input: \$input) {
          message
        }
      }
    """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "scheduleId": scheduleId,
            "courseCode": courseCode,
            "location": location,
            "startTime": startTime,
            "endTime": endTime,
            "color": color,
            "reminder": reminder,
            "recurrenceType": recurrenceType,
            "date": date,
            "startDate": startDate,
            "endDate": endDate,
            "selectedDays": selectedDays,
          },
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!['editSchedule']['message'];
  }

  Future<List<dynamic>> getMySchedules() async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    final GraphQLClient authClient = GraphQLClient(
      link: authLink,
      cache: GraphQLCache(),
    );

    const String query = """
      query GetMySchedules {
        getMySchedules {
          scheduleId
          courseCode
          location
          startTime
          endTime
          recurrenceType
          date
          startDate
          endDate
          color
          reminder
          reminder
          selectedDays
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
    return result.data!['getMySchedules'];
  }
}
