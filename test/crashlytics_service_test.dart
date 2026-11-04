import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/services/crashlytics_service.dart';

void main() {
  group('CrashlyticsService Unit Tests', () {
    test('CrashlyticsService khởi tạo thành công với timestamp ISO', () {
      final service = CrashlyticsService();
      expect(service.nowString, isNotEmpty);
      expect(DateTime.tryParse(service.nowString), isNotNull);
    });

    test('forceCrashTest ném Exception khi chạy ngoài môi trường native', () {
      final service = CrashlyticsService();
      expect(
        () => service.forceCrashTest(message: 'UnitTest Simulated Crash'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
