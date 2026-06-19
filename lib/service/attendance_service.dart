import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';
import '../core/utils/api_helper.dart';

class AttendanceService {
  static final String baseUrl = ApiHelper.resolveUrl(
    dotenv.env['GRAPHQL_URL'] ?? "http://127.0.0.1:3000/graphql",
  );

  static const String defaultCourseId = "course1";

  Future<Map<String, dynamic>> _postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    debugPrint("CALLING GRAPHQL API: $baseUrl");
    debugPrint("GRAPHQL VARIABLES: $variables");

    final response = await http
        .post(
          Uri.parse(baseUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"query": query, "variables": variables ?? {}}),
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

  Future<List<Map<String, dynamic>>> getCourses() async {
    return [
      {"_id": "course1", "name": "Mobile"},
      {"_id": "course2", "name": "Web"},
    ];
  }

  Future<List<Map<String, dynamic>>> getStudentsFromCourse(
    String courseId,
  ) async {
    return [
      {"_id": "student1", "userName": "student1"},
      {"_id": "student2", "userName": "student2"},
      {"_id": "student3", "userName": "student3"},
    ];
  }

  Future<AttendanceSessionModel> createAttendanceSession({
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
      return AttendanceSessionModel.fromJson(result);
    }

    throw Exception("Failed to create attendance session");
  }

  Future<AttendanceSessionModel> refreshAttendanceSessionPassword(
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
      variables: {"sessionId": sessionId},
    );

    final result = data["refreshAttendanceSessionPassword"];

    if (result is Map<String, dynamic>) {
      return AttendanceSessionModel.fromJson(result);
    }

    throw Exception("Failed to refresh attendance password");
  }

  Future<List<AttendanceSessionModel>> getAttendanceSessionsByCourse(
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
      variables: {"courseId": courseId},
    );

    final result = data["attendanceSessionsByCourse"];

    if (result is List) {
      return result
          .map(
            (item) => AttendanceSessionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    return [];
  }

  Future<bool> deleteAttendanceSession(String sessionId) async {
    const mutation = r'''
      mutation DeleteAttendanceSession($sessionId: String!) {
        deleteAttendanceSession(sessionId: $sessionId)
      }
    ''';

    final data = await _postGraphQL(
      query: mutation,
      variables: {"sessionId": sessionId},
    );

    return data["deleteAttendanceSession"] == true;
  }

  Future<List<AttendanceRecordModel>> getSessionAttendance(
    String sessionId,
  ) async {
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
      variables: {"sessionId": sessionId},
    );

    final result = data["sessionAttendance"];

    if (result is List) {
      return result
          .map(
            (item) => AttendanceRecordModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    return [];
  }

  Future<List<AttendanceRecordModel>> getStudentAttendanceRecords(
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
      variables: {"studentId": studentId},
    );

    final result = data["studentAttendance"];

    if (result is List) {
      return result
          .map(
            (item) => AttendanceRecordModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    return [];
  }

  Future<void> markAttendance({
    required String studentId,
    required String courseId,
    required String sessionId,
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
}
