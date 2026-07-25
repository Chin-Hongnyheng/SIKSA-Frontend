import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider {
  static const _storage = FlutterSecureStorage();

  static String? accessToken;
  static String? refreshToken;

  static Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
  }) async {
    AuthProvider.accessToken = accessToken;
    AuthProvider.refreshToken = refreshToken;
    await _storage.write(key: 'accessToken', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refreshToken', value: refreshToken);
    }
  }

  static Future<bool> loadTokens() async {
    accessToken = await _storage.read(key: 'accessToken');
    refreshToken = await _storage.read(key: 'refreshToken');
    return accessToken != null;
  }

  static Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }
}
