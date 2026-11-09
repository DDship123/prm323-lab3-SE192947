import 'package:flutter/foundation.dart';

/// Cấu hình Endpoint kết nối tới Spring Boot Backend
class ApiConfig {
  ApiConfig._();

  /// URL Cloudflare Tunnel đang hoạt động kết nối trực tiếp tới Backend & Database
  static const String activeCloudflareUrl =
      'https://barry-past-london-drugs.trycloudflare.com/api/v1';

  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: activeCloudflareUrl,
  );

  /// Kiểm tra xem một URL có phải là tunnel cũ đã ngừng hoạt động hay không
  static bool isDeprecatedTunnelUrl(String url) {
    final trimmed = url.trim();
    return trimmed.isEmpty ||
        trimmed.contains('dennis-walter') ||
        trimmed.contains('seconds-fitness-academic-media') ||
        trimmed.contains('breath-levy-importantly-mailman') ||
        trimmed.contains('robinson-roll-diesel-cars');
  }

  static String get defaultBaseUrl {
    if (!isDeprecatedTunnelUrl(_envApiUrl)) return _envApiUrl.trim();
    if (!isDeprecatedTunnelUrl(_envBaseUrl)) return _envBaseUrl.trim();
    return activeCloudflareUrl;
  }

  static String _dynamicBaseUrl = defaultBaseUrl;

  /// Địa chỉ Base URL kết nối Backend
  static String get baseUrl {
    if (isDeprecatedTunnelUrl(_dynamicBaseUrl)) {
      _dynamicBaseUrl = activeCloudflareUrl;
    }
    return _dynamicBaseUrl;
  }

  /// Ghi log trực tiếp ra Browser Console (F12) ở cả chế độ Debug và Release (Vercel)
  static void log(String tag, String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    // ignore: avoid_print
    print('[$ts][$tag] $message');
  }

  /// Cập nhật địa chỉ Backend theo cấu hình động từ người dùng (VPS, Localhost, Tunnel)
  static void setDynamicBaseUrl(String newUrl) {
    if (newUrl.isNotEmpty) {
      if (isDeprecatedTunnelUrl(newUrl)) {
        _dynamicBaseUrl = activeCloudflareUrl;
      } else {
        _dynamicBaseUrl =
            newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
      }
      log('KTX-API-CONFIG', '🌐 Đang kết nối Backend tại: $_dynamicBaseUrl');
    }
  }

  /// ID người dùng đồng bộ từ Backend (mặc định 1 nếu chưa sync)
  static int currentBackendUserId = 1;

  // Endpoints
  static String get authSync => '$baseUrl/auth/sync-user';
  static String get usersMe => '$baseUrl/users/me';
  static String get stores => '$baseUrl/stores';
  static String get menuItems => '$baseUrl/menu-items';
  static String get orders => '$baseUrl/orders';
  static String get payments => '$baseUrl/payments';
  static String get disputes => '$baseUrl/disputes';
  static String get reviews => '$baseUrl/reviews';
  static String get notifications => '$baseUrl/notifications';

  static Map<String, String> headers({String? userId, String? idToken}) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-User-Id': userId ?? '$currentBackendUserId',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
  }
}
