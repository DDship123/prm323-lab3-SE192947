import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import '../widgets/screen_state.dart';

/// ViewModel quản lý Trung tâm Thông báo (S12) và Khu vực Firebase Lab 3 Demo (S13)
class ProfileDemoViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final CrashlyticsService _crashlyticsService;

  ScreenState<List<NotificationModel>> _notificationsState =
      const StateLoading();
  int _unreadCount = 0;

  /// Danh sách thông báo FCM đã nhận được lưu trữ trong ứng dụng
  final List<NotificationModel> _inAppFcmNotifications = [];

  // Trạng thái Firebase Demo Area tại S13
  bool _remoteConfigFreeShipBanner = true;
  final int _remoteConfigMinGroupOrders = 5;
  String _lastCrashlyticsLog = 'Chưa có sự kiện lỗi nào được ghi nhận.';
  String _fcmStatusMessage = 'Đã đăng ký topic: ktx_group_orders';
  String? _fcmToken;
  String _fcmPermissionStatus = 'Đang kiểm tra...';

  ProfileDemoViewModel({
    required NotificationService notificationService,
    CrashlyticsService? crashlyticsService,
  })  : _notificationService = notificationService,
        _crashlyticsService = crashlyticsService ?? CrashlyticsService() {
    _unreadCount = _inAppFcmNotifications.where((n) => !n.isRead).length;
  }

  ScreenState<List<NotificationModel>> get notificationsState =>
      _notificationsState;
  int get unreadCount => _unreadCount;
  bool get remoteConfigFreeShipBanner => _remoteConfigFreeShipBanner;
  int get remoteConfigMinGroupOrders => _remoteConfigMinGroupOrders;
  String get lastCrashlyticsLog => _lastCrashlyticsLog;
  String get fcmStatusMessage => _fcmStatusMessage;
  CrashlyticsService get crashlyticsService => _crashlyticsService;
  String? get fcmToken => _fcmToken;
  String get fcmPermissionStatus => _fcmPermissionStatus;

  /// Cập nhật thông tin khởi tạo từ FcmService
  void updateFcmMetadata({String? token, required String permissionStatus}) {
    _fcmToken = token;
    _fcmPermissionStatus = permissionStatus;
    _fcmStatusMessage =
        'Quyền: $permissionStatus • Topic: ktx_group_orders';
    notifyListeners();
  }

  /// Lưu thông báo FCM vừa nhận (Foreground / Background / Terminated) vào danh sách trong app
  NotificationModel recordIncomingFcmMessage({
    required String title,
    required String body,
    required String type,
    required String appState,
    String? dataPayload,
  }) {
    final newNoti = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      title: title,
      body: body,
      type: type,
      isRead: false,
      dataPayload: dataPayload,
      createdAt: DateTime.now(),
    );

    _inAppFcmNotifications.insert(0, newNoti);
    _fcmStatusMessage = 'Vừa nhận: "$title"';
    _refreshMergedNotificationsState();
    return newNoti;
  }

  void _refreshMergedNotificationsState([List<NotificationModel>? remoteList]) {
    final currentRemote = remoteList ??
        switch (_notificationsState) {
          StateSuccess(:final data) => data
              .where(
                (item) => !_inAppFcmNotifications.any((f) => f.id == item.id),
              )
              .toList(),
          _ => <NotificationModel>[],
        };

    final merged = [..._inAppFcmNotifications, ...currentRemote];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _unreadCount = merged.where((n) => !n.isRead).length;
    if (merged.isEmpty) {
      _notificationsState = const StateEmpty(
        message: 'Bạn chưa có thông báo đơn hàng nào.',
      );
    } else {
      _notificationsState = StateSuccess(merged);
    }
    notifyListeners();
  }

  /// API-019 & API-022: Tải danh sách thông báo và gộp cùng danh sách thông báo FCM đã nhận (S12)
  Future<void> loadNotifications() async {
    _notificationsState = const StateLoading();
    notifyListeners();

    try {
      final remoteList = await _notificationService.fetchNotifications();
      _refreshMergedNotificationsState(remoteList);
    } catch (e) {
      _refreshMergedNotificationsState(const []);
    }
  }

  /// API-020: Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    final localIdx =
        _inAppFcmNotifications.indexWhere((n) => n.id == notificationId);
    if (localIdx != -1) {
      final old = _inAppFcmNotifications[localIdx];
      _inAppFcmNotifications[localIdx] = NotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        body: old.body,
        type: old.type,
        isRead: true,
        dataPayload: old.dataPayload,
        createdAt: old.createdAt,
      );
      _refreshMergedNotificationsState();
      return;
    }

    await _notificationService.markAsRead(notificationId);
    await loadNotifications();
  }

  /// API-021: Đánh dấu toàn bộ thông báo đã đọc
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _inAppFcmNotifications.length; i++) {
      final old = _inAppFcmNotifications[i];
      _inAppFcmNotifications[i] = NotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        body: old.body,
        type: old.type,
        isRead: true,
        dataPayload: old.dataPayload,
        createdAt: old.createdAt,
      );
    }
    await _notificationService.markAllAsRead();
    await loadNotifications();
  }

  /// Giả lập Fetch & Activate Firebase Remote Config tại S13
  void toggleRemoteConfigFreeShip() {
    _remoteConfigFreeShipBanner = !_remoteConfigFreeShipBanner;
    notifyListeners();
  }

  /// Ghi nhận Non-Fatal Exception lên Firebase Crashlytics tại S13
  Future<void> triggerCrashlyticsNonFatalTest() async {
    final now = DateTime.now().toIso8601String();
    await _crashlyticsService.recordNonFatalError(
      Exception('SimulatedKtxPaymentTimeoutException'),
      StackTrace.current,
      reason: 'Người dùng nhấn kiểm thử Non-Fatal lỗi thanh toán tại S13',
    );
    _lastCrashlyticsLog =
        '[$now] Đã ghi nhận Handled Exception: HandledPaymentTimeoutException lên Crashlytics.';
    notifyListeners();
  }

  /// Kích hoạt Fatal Crash gây sập ứng dụng phục vụ kiểm thử theo yêu cầu của Thầy
  void triggerFatalCrashTest() {
    _crashlyticsService.forceCrashTest(
      message: 'Demo Fatal Crash Lab 3 phục vụ chấm điểm giáo viên',
    );
  }

  /// Giả lập nhận FCM Push Notification mới và lưu vào danh sách S12
  NotificationModel simulateIncomingFcmPush({
    String type = 'ORDER_STATUS',
    String appState = 'FOREGROUND',
  }) {
    _fcmStatusMessage =
        'FCM Push vừa nhận: "Shipper đã tới Cổng B2 KTX! Mở mã QR để nhận món."';
    _unreadCount += 1;
    notifyListeners();
    if (type == 'DISPUTE_UPDATE') {
      return recordIncomingFcmMessage(
        title: 'Cập nhật khiếu nại đơn hàng KTX',
        body:
            'Quán đã phản hồi yêu cầu hoàn tiền của bạn. Nhấn vào thông báo để mở Lịch sử Khiếu nại.',
        type: 'DISPUTE_UPDATE',
        appState: appState,
        dataPayload: '102',
      );
    }
    return recordIncomingFcmMessage(
      title: 'Shipper đã tới Cổng B2 KTX!',
      body:
          'Món ăn ca gom 11:30 đã tới điểm hẹn Trụ A1–A2. Nhấn vào thông báo để xem Tiến trình & Mã QR nhận món.',
      type: 'ORDER_STATUS',
      appState: appState,
      dataPayload: '101',
    );
  }
}