/// Cấu hình Endpoint kết nối tới Spring Boot Backend
class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://solution-slope-creating-phillips.trycloudflare.com/api/v1',
  );

  static String _dynamicBaseUrl = _envBaseUrl;

  /// Địa chỉ Base URL kết nối Backend
  static String get baseUrl => _dynamicBaseUrl;

  /// Cập nhật địa chỉ Backend theo cấu hình động từ người dùng (VPS, Localhost, Tunnel)
  static void setDynamicBaseUrl(String newUrl) {
    if (newUrl.isNotEmpty) {
      _dynamicBaseUrl = newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
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
