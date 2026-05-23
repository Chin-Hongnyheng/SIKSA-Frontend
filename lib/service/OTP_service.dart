import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  /// Send OTP to email
  static Future<void> sendOtp(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Success
        final data = jsonDecode(response.body);
        print('OTP sent: ${data['message']}');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('Send OTP Error: $e');
      rethrow;
    }
  }

  /// Verify OTP
  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Success
        final data = jsonDecode(response.body);
        print('OTP verified: ${data['message']}');
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid or expired OTP');
      }
    } catch (e) {
      print('Verify OTP Error: $e');
      rethrow;
    }
  }
}
