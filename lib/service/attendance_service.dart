import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';

class AttendanceService {
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

  // ─── Session Mutations ────────────────────────────────────────────────────

  Future<AttendanceSessionModel> createAttendanceSession({
    required String courseCode,
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    int passwordRefreshSeconds = 60,
    int lateAfterMinutes = 15,
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation CreateAttendanceSession(\$input: CreateAttendanceSessionInput!) {
        createAttendanceSession(input: \$input) {
          id
          courseCode
          createdBy
          title
          date
          startTime
          endTime
          password
          passwordExpiresAt
          passwordRefreshSeconds
          lateAfterMinutes
          isActive
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "courseCode": courseCode,
            "title": title,
            "date": date,
            "startTime": startTime,
            "endTime": endTime,
            "passwordRefreshSeconds": passwordRefreshSeconds,
            "lateAfterMinutes": lateAfterMinutes,
          },
        },
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return AttendanceSessionModel.fromJson(
      Map<String, dynamic>.from(result.data!['createAttendanceSession']),
    );
  }

  Future<AttendanceSessionModel> refreshAttendanceSessionPassword(
    String sessionId,
  ) async {
    final authClient = _authClient();

    const String mutation = """
      mutation RefreshAttendanceSessionPassword(\$sessionId: String!) {
        refreshAttendanceSessionPassword(sessionId: \$sessionId) {
          id
          courseCode
          createdBy
          title
          date
          startTime
          endTime
          password
          passwordExpiresAt
          passwordRefreshSeconds
          lateAfterMinutes
          isActive
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {"sessionId": sessionId},
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return AttendanceSessionModel.fromJson(
      Map<String, dynamic>.from(
        result.data!['refreshAttendanceSessionPassword'],
      ),
    );
  }

  Future<AttendanceSessionModel> closeAttendanceSession(
    String sessionId,
  ) async {
    final authClient = _authClient();

    const String mutation = """
      mutation CloseAttendanceSession(\$sessionId: String!) {
        closeAttendanceSession(sessionId: \$sessionId) {
          id
          courseCode
          createdBy
          title
          date
          startTime
          endTime
          password
          passwordExpiresAt
          passwordRefreshSeconds
          lateAfterMinutes
          isActive
        }
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {"sessionId": sessionId},
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return AttendanceSessionModel.fromJson(
      Map<String, dynamic>.from(result.data!['closeAttendanceSession']),
    );
  }

  Future<bool> deleteAttendanceSession(String sessionId) async {
    final authClient = _authClient();

    const String mutation = """
      mutation DeleteAttendanceSession(\$sessionId: String!) {
        deleteAttendanceSession(sessionId: \$sessionId)
      }
    """;

    final result = await authClient.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {"sessionId": sessionId},
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return result.data!['deleteAttendanceSession'] == true;
  }

  // ─── Attendance Record Mutations ──────────────────────────────────────────

  Future<AttendanceRecordModel> markAttendance({
    required String studentId,
    required String courseCode,
    required String sessionId,
    required String date,
    String? status, // pass "absent" or "permission" to mark manually
    String? checkIn, // required for present/late — backend derives status
  }) async {
    final authClient = _authClient();

    const String mutation = """
      mutation MarkAttendance(\$input: MarkAttendanceInput!) {
        markAttendance(input: \$input) {
          id
          studentId
          courseCode
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    """;

    final Map<String, dynamic> input = {
      "studentId": studentId,
      "courseCode": courseCode,
      "sessionId": sessionId,
      "date": date,
    };

    if (status != null) input["status"] = status;
    if (checkIn != null) input["checkIn"] = checkIn;

    final result = await authClient.mutate(
      MutationOptions(document: gql(mutation), variables: {"input": input}),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return AttendanceRecordModel.fromJson(
      Map<String, dynamic>.from(result.data!['markAttendance']),
    );
  }

  // ─── Session Queries ──────────────────────────────────────────────────────

  Future<List<AttendanceSessionModel>> getAttendanceSessionsByCourse(
    String courseCode,
  ) async {
    final authClient = _authClient();

    const String query = """
      query AttendanceSessionsByCourse(\$courseCode: String!) {
        attendanceSessionsByCourse(courseCode: \$courseCode) {
          id
          courseCode
          createdBy
          title
          date
          startTime
          endTime
          password
          passwordExpiresAt
          passwordRefreshSeconds
          lateAfterMinutes
          isActive
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"courseCode": courseCode},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return (result.data!['attendanceSessionsByCourse'] as List)
        .map(
          (e) => AttendanceSessionModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<AttendanceSessionModel>> getActiveAttendanceSessionsByCourse(
    String courseCode,
  ) async {
    final authClient = _authClient();

    const String query = """
      query ActiveAttendanceSessionsByCourse(\$courseCode: String!) {
        activeAttendanceSessionsByCourse(courseCode: \$courseCode) {
          id
          courseCode
          createdBy
          title
          date
          startTime
          endTime
          password
          passwordExpiresAt
          passwordRefreshSeconds
          lateAfterMinutes
          isActive
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"courseCode": courseCode},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return (result.data!['activeAttendanceSessionsByCourse'] as List)
        .map(
          (e) => AttendanceSessionModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<bool> verifyAttendanceSessionPassword({
    required String sessionId,
    required String password,
  }) async {
    final authClient = _authClient();

    const String query = """
      query VerifyAttendanceSessionPassword(\$sessionId: String!, \$password: String!) {
        verifyAttendanceSessionPassword(sessionId: \$sessionId, password: \$password)
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"sessionId": sessionId, "password": password},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return result.data!['verifyAttendanceSessionPassword'] == true;
  }

  // ─── Attendance Record Queries ────────────────────────────────────────────

  Future<List<AttendanceRecordModel>> getSessionAttendance(
    String sessionId,
  ) async {
    final authClient = _authClient();

    const String query = """
      query SessionAttendance(\$sessionId: String!) {
        sessionAttendance(sessionId: \$sessionId) {
          id
          studentId
          courseCode
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"sessionId": sessionId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return (result.data!['sessionAttendance'] as List)
        .map(
          (e) => AttendanceRecordModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<AttendanceRecordModel>> getStudentAttendance(
    String studentId,
  ) async {
    final authClient = _authClient();

    const String query = """
      query StudentAttendance(\$studentId: String!) {
        studentAttendance(studentId: \$studentId) {
          id
          studentId
          courseCode
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"studentId": studentId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return (result.data!['studentAttendance'] as List)
        .map(
          (e) => AttendanceRecordModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<AttendanceRecordModel>> getCourseAttendance(
    String courseCode,
  ) async {
    final authClient = _authClient();

    const String query = """
      query CourseAttendance(\$courseCode: String!) {
        courseAttendance(courseCode: \$courseCode) {
          id
          studentId
          courseCode
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"courseCode": courseCode},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return (result.data!['courseAttendance'] as List)
        .map(
          (e) => AttendanceRecordModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<Map<String, int>> getStudentAttendanceSummary(String studentId) async {
    final authClient = _authClient();

    const String query = """
      query StudentAttendanceSummary(\$studentId: String!) {
        studentAttendanceSummary(studentId: \$studentId) {
          present
          late
          absent
          permission
        }
      }
    """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"studentId": studentId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    final data = result.data!['studentAttendanceSummary'];
    return {
      'present': data['present'] as int,
      'late': data['late'] as int,
      'absent': data['absent'] as int,
      'permission': data['permission'] as int,
    };
  }

  // Add this method inside AttendanceService class
  Future<AttendanceSessionModel> getSessionById(String sessionId) async {
    final authClient = _authClient();

    const String query = """
    query GetAttendanceSession(\$sessionId: String!) {
      attendanceSession(sessionId: \$sessionId) {
        id
        courseCode
        createdBy
        title
        date
        startTime
        endTime
        password
        passwordExpiresAt
        passwordRefreshSeconds
        lateAfterMinutes
        isActive
      }
    }
  """;

    final result = await authClient.query(
      QueryOptions(
        document: gql(query),
        variables: {"sessionId": sessionId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw _exceptionFromResult(result);
    return AttendanceSessionModel.fromJson(
      Map<String, dynamic>.from(result.data!['attendanceSession']),
    );
  }
}
