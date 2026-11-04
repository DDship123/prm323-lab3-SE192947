import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/screen_state.dart';

/// ViewModel quản lý Trung tâm Thông báo (S12) và Khu vực Firebase Lab 3 Demo (S13)
class ProfileDemoViewModel extends ChangeNotifier {
  final NotificationService _notificationService;

  ScreenState<List<NotificationModel>> _notificationsState =
      const StateLoading();
  int _unreadCount = 0;

  // Trạng thái Firebase Demo Area tại S13
  bool _remoteConfigFreeShipBanner = true;
  int _remoteConfigMinGroupOrders = 5;
  String _lastCrashlyticsLog = 'Chưa có sự kiện lỗi nào được ghi nhận.';
  String _fcmStatusMessage = 'Đã đăng ký topic: ktx_group_orders';

  ProfileDemoViewModel({required NotificationService notificationService})
      : _notificationService = notificationService;

  ScreenState<List<NotificationModel>> get notificationsState =>
      _notificationsState;
  int get unreadCount => _unreadCount;
  bool get remoteConfigFreeShipBanner => _remoteConfigFreeShipBanner;
  int get remoteConfigMinGroupOrders => _remoteConfigMinGroupOrders;
  String get lastCrashlyticsLog => _lastCrashlyticsLog;
  String get fcmStatusMessage => _fcmStatusMessage;

  /// API-019 & API-022: Tải danh sách thông báo và số lượng chưa đọc (S12)
  Future<void> loadNotifications() async {
    _notificationsState = const StateLoading();
    notifyListeners();

    try {
      final list = await _notificationService.fetchNotifications();
      _unreadCount = list.where((n) => !n.isRead).length;
      if (list.isEmpty) {
        _notificationsState = const StateEmpty(
          message: 'Bạn chưa có thông báo đơn hàng nào.',
        );
      } else {
        _notificationsState = StateSuccess(list);
      }
    } catch (e) {
      _notificationsState = StateError(
        'Không thể tải thông báo: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  /// API-020: Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    await loadNotifications();
  }

  /// API-021: Đánh dấu toàn bộ thông báo đã đọc
  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
    await loadNotifications();
  }

  /// Giả lập Fetch & Activate Firebase Remote Config tại S13
  void toggleRemoteConfigFreeShip() {
    _remoteConfigFreeShipBanner = !_remoteConfigFreeShipBanner;
    notifyListeners();
  }

  /// Giả lập ghi nhận Non-Fatal Exception lên Firebase Crashlytics tại S13
  void triggerCrashlyticsNonFatalTest() {
    final now = DateTime.now().toIso8601String();
    _lastCrashlyticsLog =
        '[$now] Đã ghi nhận Handled Exception: SimulatedKtxPaymentTimeoutException lên Crashlytics.';
    notifyListeners();
  }

  /// Giả lập nhận FCM Push Notification mới
  void simulateIncomingFcmPush() {
    _fcmStatusMessage =
        'FCM Push vừa nhận: "Shipper đã tới Cổng B2 KTX! Mở mã QR tại S7 để nhận món."';
    _unreadCount += 1;
    notifyListeners();
  }
}
