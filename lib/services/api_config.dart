/// Cấu hình Endpoint kết nối tới Spring Boot Backend
class ApiConfig {
  ApiConfig._();

  /// Địa chỉ Base URL kết nối Backend
  /// Khi cắm cáp USB với adb reverse tcp:8080 tcp:8080 hoặc chạy web/desktop,
  /// 127.0.0.1:8080 tự động chuyển tiếp thẳng vào Backend Spring Boot trên máy tính
  static String get baseUrl => 'http://127.0.0.1:8080/api/v1';

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
