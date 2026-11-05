import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Top-level function xử lý message khi app ở trạng thái Background / Terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [FCM Background Handler] Nhận thông báo ngầm: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _fcmToken;
  String _permissionStatus = 'Chưa kiểm tra';

  String? get fcmToken => _fcmToken;
  String get permissionStatus => _permissionStatus;

  Future<String?> initialize({
    required void Function(RemoteMessage message, String appState)
        onMessageReceived,
    required void Function(RemoteMessage message, String appState)
        onNotificationTapped,
  }) async {
    if (kIsWeb) return null;

    try {
      // 1. Xin cấp quyền thông báo (bắt buộc từ Android 13 / API 33+)
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _permissionStatus = settings.authorizationStatus.name;
      debugPrint('🔔 [FCM Permission] Trạng thái quyền: $_permissionStatus');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Đăng ký nhận thông báo chung theo topic gom đơn KTX
        await _messaging.subscribeToTopic('ktx_group_orders');
      }

      // Hiển thị thông báo ngay cả khi đang mở app (iOS/Android foreground options)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Trạng thái 1: FOREGROUND (Ứng dụng đang mở trực tiếp trên màn hình)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 [FCM FOREGROUND] Nhận thông báo: ${message.notification?.title}');
        onMessageReceived(message, 'FOREGROUND');
      });

      // 3. Trạng thái 2: BACKGROUND (Ứng dụng chạy ngầm, người dùng nhấn vào thông báo trên thanh trạng thái)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [FCM BACKGROUND TAP] Mở app từ thông báo: ${message.notification?.title}');
        onNotificationTapped(message, 'BACKGROUND');
      });

      // 4. Trạng thái 3: TERMINATED (Ứng dụng đã bị đóng hẳn, người dùng nhấn vào thông báo để khởi động app)
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 [FCM TERMINATED TAP] Khởi động app từ thông báo: ${initialMessage.notification?.title}');
        onNotificationTapped(initialMessage, 'TERMINATED');
      }

      // 5. Lấy FCM Registration Token để test gửi từ Firebase Console
      _fcmToken = await _messaging.getToken();
      debugPrint('🔑 [FCM TOKEN]: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('⚠️ Lỗi khởi tạo FCM: $e');
      return null;
    }
  }
}
