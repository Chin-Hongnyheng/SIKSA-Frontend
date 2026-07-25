import 'package:flutter/foundation.dart';

class ApiHelper {
  /// Resolves the backend URL based on the platform.
  /// Converts localhost to 10.0.2.2 automatically on Android.
  static String resolveUrl(String url) {
    if (kIsWeb) {
      return url;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }

    return url;
  }
}
