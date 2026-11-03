import 'dart:io';
import 'package:flutter/foundation.dart';

/// Cấu hình Endpoint kết nối tới Spring Boot Backend
class ApiConfig {
  ApiConfig._();

  /// Địa chỉ Base URL tự động nhận diện theo nền tảng
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (Platform.isAndroid) {
      // Android Emulator ánh xạ localhost của máy host qua 10.0.2.2
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  // Endpoints
  static String get disputes => '$baseUrl/disputes';
  static String get orders => '$baseUrl/orders';
}
