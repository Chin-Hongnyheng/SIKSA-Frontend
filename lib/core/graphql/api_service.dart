import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // For Chrome and LDPlayer with adb reverse tcp:3000 tcp:3000
  static const String baseUrl = "http://127.0.0.1:3000/graphql";

  static const String defaultCourseId = "course1";

  static Future<Map<String, dynamic>> _postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    debugPrint("CALLING GRAPHQL API: $baseUrl");
    debugPrint("GRAPHQL VARIABLES: $variables");

    final response = await http
        .post(
          Uri.parse(baseUrl),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "query": query,
            "variables": variables ?? {},
          }),
        )
        .timeout(const Duration(seconds: 25));

    debugPrint("GRAPHQL STATUS: ${response.statusCode}");
    debugPrint("GRAPHQL BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("GraphQL request failed: ${response.body}");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid GraphQL response");
    }

    if (decoded["errors"] != null) {
      throw Exception("GraphQL errors: ${decoded["errors"]}");
    }

    final data = decoded["data"];

    if (data is! Map<String, dynamic>) {
      throw Exception("GraphQL response has no data");
    }

    return data;
  }

  // Temporary course list until real course API is connected.
  static Future<List<dynamic>> getCourses() async {
    return [
      {
        "_id": "course1",
        "name": "Mobile",
      },
      {
        "_id": "course2",
        "name": "Web",
      },
    ];
  }

  static Future<Map<String, dynamic>> createAttendanceSession({
    required String courseId,
    required String teacherId,
    required String title,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    const mutation = r'''
      mutation CreateAttendanceSession($input: CreateAttendanceSessionInput!) {
        createAttendanceSession(input: $input) {
          id
          courseId
          teacherId
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
    ''';

    final data = await _postGraphQL(
      query: mutation,
      variables: {
        "input": {
          "courseId": courseId,
          "teacherId": teacherId,
          "title": title,
          "date": date,
          "startTime": startTime,
          "endTime": endTime,
          "passwordRefreshSeconds": 60,
          "lateAfterMinutes": 15,
        },
      },
    );

    final result = data["createAttendanceSession"];

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception("Failed to create attendance session");
  }

  static Future<Map<String, dynamic>> refreshAttendanceSessionPassword(
    String sessionId,
  ) async {
    const mutation = r'''
      mutation RefreshAttendanceSessionPassword($sessionId: String!) {
        refreshAttendanceSessionPassword(sessionId: $sessionId) {
          id
          courseId
          teacherId
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
    ''';

    final data = await _postGraphQL(
      query: mutation,
      variables: {
        "sessionId": sessionId,
      },
    );

    final result = data["refreshAttendanceSessionPassword"];

    if (result is Map<String, dynamic>) {
      return result;
    }

    throw Exception("Failed to refresh attendance password");
  }

  static Future<List<dynamic>> getAttendanceSessionsByCourse(
    String courseId,
  ) async {
    const query = r'''
      query AttendanceSessionsByCourse($courseId: String!) {
        attendanceSessionsByCourse(courseId: $courseId) {
          id
          courseId
          teacherId
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
    ''';

    final data = await _postGraphQL(
      query: query,
      variables: {
        "courseId": courseId,
      },
    );

    final result = data["attendanceSessionsByCourse"];

    if (result is List) {
      return result;
    }

    return [];
  }

  static Future<List<dynamic>> getSessionAttendance(String sessionId) async {
    const query = r'''
      query SessionAttendance($sessionId: String!) {
        sessionAttendance(sessionId: $sessionId) {
          id
          studentId
          courseId
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    ''';

    final data = await _postGraphQL(
      query: query,
      variables: {
        "sessionId": sessionId,
      },
    );

    final result = data["sessionAttendance"];

    if (result is List) {
      return result;
    }

    return [];
  }

  static Future<List<dynamic>> getStudentAttendanceRecords(
    String studentId,
  ) async {
    const query = r'''
      query StudentAttendance($studentId: String!) {
        studentAttendance(studentId: $studentId) {
          id
          studentId
          courseId
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    ''';

    final data = await _postGraphQL(
      query: query,
      variables: {
        "studentId": studentId,
      },
    );

    final result = data["studentAttendance"];

    if (result is List) {
      return result;
    }

    return [];
  }

  static Future<Map<String, dynamic>> getStudentAttendanceSummary(
    String studentId,
  ) async {
    const query = r'''
      query StudentAttendanceSummary($studentId: String!) {
        studentAttendanceSummary(studentId: $studentId) {
          present
          late
          absent
          permission
        }
      }
    ''';

    final data = await _postGraphQL(
      query: query,
      variables: {
        "studentId": studentId,
      },
    );

    final result = data["studentAttendanceSummary"];

    if (result is Map<String, dynamic>) {
      return result;
    }

    return {
      "present": 0,
      "late": 0,
      "absent": 0,
      "permission": 0,
    };
  }

  static Future<List<dynamic>> getCourseAttendance(String courseId) async {
    const query = r'''
      query CourseAttendance($courseId: String!) {
        courseAttendance(courseId: $courseId) {
          id
          studentId
          courseId
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    ''';

    final data = await _postGraphQL(
      query: query,
      variables: {
        "courseId": courseId,
      },
    );

    final result = data["courseAttendance"];

    if (result is List) {
      return result;
    }

    return [];
  }

  static Future<void> markAttendance({
    required String studentId,
    required String courseId,
    String? sessionId,
    required String date,
    required String status,
    String? checkIn,
    String? checkOut,
  }) async {
    const mutation = r'''
      mutation MarkAttendance($input: MarkAttendanceInput!) {
        markAttendance(input: $input) {
          id
          studentId
          courseId
          sessionId
          date
          status
          checkIn
          checkOut
          type
          time
        }
      }
    ''';

    await _postGraphQL(
      query: mutation,
      variables: {
        "input": {
          "studentId": studentId,
          "courseId": courseId,
          "sessionId": sessionId,
          "date": date,
          "status": status,
          "checkIn": checkIn,
          "checkOut": checkOut,
        },
      },
    );
  }

  static Future<List<dynamic>> getStudentsFromCourse(String courseId) async {
    // Temporary student list until your real Students API is connected.
    return [
      {
        "_id": "student1",
        "userName": "student1",
      },
      {
        "_id": "student2",
        "userName": "student2",
      },
      {
        "_id": "student3",
        "userName": "student3",
      },
    ];
  }
}