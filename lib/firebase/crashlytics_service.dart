import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Đính kèm User ID và Custom Keys lên Dashboard
  Future<void> setUserContext({
    required String userId,
    required String campusZone,
    required String currentScreen,
  }) async {
    if (kIsWeb) return;
    await _crashlytics.setUserIdentifier(userId);
    await _crashlytics.setCustomKey('ktx_campus_zone', campusZone);
    await _crashlytics.setCustomKey('current_screen', currentScreen);
  }

  /// 1. Gửi lỗi được xử lý (Non-Fatal Error) từ luồng thực tế
  Future<void> recordNonFatalError(
    Object exception,
    StackTrace? stackTrace, {
    required String reason,
  }) async {
    if (kIsWeb) return;
    await _crashlytics.log('Non-fatal error occurred: $reason');
    await _crashlytics.recordError(
      exception,
      stackTrace ?? StackTrace.current,
      reason: reason,
      fatal: false,
    );
  }

  /// 2. Kích hoạt lỗi thử nghiệm (Test Fatal Crash)
  void triggerTestCrash() {
    if (kIsWeb) return;
    _crashlytics.log('User triggered manual test crash from S13 Demo Area');
    _crashlytics.crash();
  }
}
