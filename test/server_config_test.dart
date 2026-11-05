import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/server_config_model.dart';
import 'package:prm393_lab03_se192947/services/api_config.dart';

void main() {
  group('ServerConfigModel & ApiConfig Tests', () {
    test('Khởi tạo cấu hình mặc định chính xác theo preset', () {
      final config = ServerConfigModel.defaultConfig();
      expect(config.preset, ServerEnvironmentPreset.emulator);
      expect(config.baseUrl.isNotEmpty, isTrue);
      expect(config.baseUrl.endsWith('/'), isFalse);
    });

    test('Chuyển đổi JSON sang Model và ngược lại chính xác', () {
      final model = ServerConfigModel(
        baseUrl: 'http://103.179.189.120:8080/api/v1',
        preset: ServerEnvironmentPreset.vpsServer,
        updatedAt: DateTime.parse('2026-11-05T00:00:00Z'),
      );

      final json = model.toJson();
      expect(json['baseUrl'], 'http://103.179.189.120:8080/api/v1');
      expect(json['preset'], 'vpsServer');

      final reconstructed = ServerConfigModel.fromJson(json);
      expect(reconstructed.baseUrl, model.baseUrl);
      expect(reconstructed.preset, model.preset);
    });

    test('ApiConfig cập nhật dynamicBaseUrl và chuẩn hóa dấu gạch chéo', () {
      ApiConfig.setDynamicBaseUrl('http://192.168.1.100:8080/api/v1/');
      expect(ApiConfig.baseUrl, 'http://192.168.1.100:8080/api/v1');
      expect(ApiConfig.authSync, 'http://192.168.1.100:8080/api/v1/auth/sync-user');

      ApiConfig.setDynamicBaseUrl('https://api.foodktx.vn/api/v1');
      expect(ApiConfig.baseUrl, 'https://api.foodktx.vn/api/v1');
      expect(ApiConfig.disputes, 'https://api.foodktx.vn/api/v1/disputes');
    });

    test('ServerConfigModel copyWith cập nhật đúng thuộc tính', () {
      final initial = ServerConfigModel(
        baseUrl: 'http://127.0.0.1:8080/api/v1',
        preset: ServerEnvironmentPreset.localhost,
        updatedAt: DateTime.now(),
      );

      final updated = initial.copyWith(
        baseUrl: 'http://10.0.2.2:8080/api/v1',
        preset: ServerEnvironmentPreset.emulator,
      );

      expect(updated.baseUrl, 'http://10.0.2.2:8080/api/v1');
      expect(updated.preset, ServerEnvironmentPreset.emulator);
    });
  });
}
