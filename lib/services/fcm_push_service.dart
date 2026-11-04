import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

typedef FcmMessageCallback = void Function(String title, String body, Map<String, dynamic> data);

/// Dịch vụ quản lý chu trình Push Notification Firebase Cloud Messaging (FCM)
class FcmPushService {
  final http.Client _client;
  String? _cachedFcmToken;
  FcmMessageCallback? _onMessageReceived;

  FcmPushService({http.Client? client}) : _client = client ?? http.Client();

  String? get cachedToken => _cachedFcmToken;

  /// Đăng ký bộ lắng nghe khi có tin nhắn thông báo đẩy đến (Foreground/In-App)
  void setOnMessageReceived(FcmMessageCallback callback) {
    _onMessageReceived = callback;
  }

  /// Khởi tạo và đồng bộ FCM Token của thiết bị lên máy chủ Backend
  Future<String> syncDeviceFcmToken({String? customToken}) async {
    final token = customToken ?? _cachedFcmToken ?? _generateFallbackToken();
    _cachedFcmToken = token;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/me/fcm-token');
      await _client
          .post(
            url,
            headers: ApiConfig.headers(),
            body: jsonEncode({
              'fcmToken': token,
              'deviceType': kIsWeb ? 'WEB' : (defaultTargetPlatform == TargetPlatform.android ? 'ANDROID' : 'IOS'),
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    return token;
  }

  /// Mô phỏng hoặc tiếp nhận Push Notification gửi từ Backend
  void handleIncomingPush({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) {
    if (_onMessageReceived != null) {
      _onMessageReceived!(title, body, data);
    }
  }

  String _generateFallbackToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'fcm_ktx_dev_token_${now.toRadixString(16)}';
  }
}

