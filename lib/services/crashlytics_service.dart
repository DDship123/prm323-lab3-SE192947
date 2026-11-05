import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý chẩn đoán và báo cáo sự cố qua Firebase Crashlytics
/// Bảo vệ an toàn trên Web và tương thích đa nền tảng
class CrashlyticsService {
  FirebaseCrashlytics? _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  FirebaseCrashlytics? get _safeCrashlytics {
    if (kIsWeb) return null;
    if (_crashlytics != null) return _crashlytics;
    try {
      _crashlytics = FirebaseCrashlytics.instance;
    } catch (_) {}
    return _crashlytics;
  }

  /// Thiết lập các thuộc tính định danh người dùng và vai trò KTX
  Future<void> setUserContext({
    required String userId,
    String? role,
    String? campusZone,
    String? currentScreen,
    String? ktxBuilding,
    String? ktxRoom,
  }) async {
    final client = _safeCrashlytics;
    if (client == null) return;
    try {
      await client.setUserIdentifier(userId);
      if (role != null) await client.setCustomKey('user_role', role);
      if (campusZone != null) await client.setCustomKey('ktx_campus_zone', campusZone);
      if (currentScreen != null) await client.setCustomKey('current_screen', currentScreen);
      if (ktxBuilding != null) await client.setCustomKey('ktx_building', ktxBuilding);
      if (ktxRoom != null) await client.setCustomKey('ktx_room', ktxRoom);
    } catch (e) {
      debugPrint('Không thể thiết lập context Crashlytics: $e');
    }
  }

  /// Ghi vết một sự kiện log nghiệp vụ lên Crashlytics timeline
  Future<void> logEvent(String message) async {
    final client = _safeCrashlytics;
    if (client == null) return;
    try {
      await client.log('[$nowString] $message');
    } catch (_) {}
  }

  /// Ghi nhận lỗi phi nghiêm trọng (Non-fatal handled exception)
  Future<void> recordNonFatalError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    final client = _safeCrashlytics;
    if (client == null) return;
    try {
      await client.recordError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: reason ?? 'Handled application exception',
        fatal: false,
      );
    } catch (_) {}
  }

  /// Kích hoạt sự cố nghiêm trọng (Fatal crash) phục vụ kiểm thử theo yêu cầu
  void forceCrashTest({String message = 'Test Crashlytics Fatal Crash Lab 3'}) {
    final client = _safeCrashlytics;
    if (client != null) {
      try {
        client.log('Triggered forceCrashTest: $message');
        client.crash();
        return;
      } catch (_) {}
    }
    // Fallback ném lỗi bất đồng bộ chưa bắt nếu chạy ngoài môi trường native
    throw Exception('FatalCrashTest: $message');
  }

  /// Kích hoạt lỗi thử nghiệm (Test Fatal Crash) từ bảng điều khiển S13
  void triggerTestCrash() {
    forceCrashTest(message: 'User triggered manual test crash from S13 Demo Area');
  }

  String get nowString => DateTime.now().toIso8601String();
}
