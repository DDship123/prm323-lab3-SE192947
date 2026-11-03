/// Cấu hình Endpoint kết nối tới Spring Boot Backend
class ApiConfig {
  ApiConfig._();

  /// Địa chỉ Base URL kết nối Backend
  /// Khi cắm cáp USB với adb reverse tcp:8080 tcp:8080 hoặc chạy web/desktop,
  /// 127.0.0.1:8080 tự động chuyển tiếp thẳng vào Backend Spring Boot trên máy tính
  static String get baseUrl => 'http://127.0.0.1:8080/api/v1';

  // Endpoints
  static String get disputes => '$baseUrl/disputes';
  static String get orders => '$baseUrl/orders';
}
