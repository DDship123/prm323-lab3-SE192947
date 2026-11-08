import '../services/api_config.dart';

enum ServerEnvironmentPreset {
  emulator('Máy ảo Android (10.0.2.2:8088)', 'http://10.0.2.2:8088/api/v1'),
  localhost('USB Cáp / Localhost (127.0.0.1:8088)', 'http://127.0.0.1:8088/api/v1'),
  vpsServer('Cloudflare Tunnel (Aiven MySQL Live)', 'https://robinson-roll-diesel-cars.trycloudflare.com/api/v1'),
  custom('Tùy chỉnh IP / Cloudflare Tunnel', '');

  final String label;
  final String defaultUrl;
  const ServerEnvironmentPreset(this.label, this.defaultUrl);
}

/// Mô hình lưu trữ cấu hình địa chỉ máy chủ Backend kết nối động
class ServerConfigModel {
  final String baseUrl;
  final ServerEnvironmentPreset preset;
  final DateTime updatedAt;

  const ServerConfigModel({
    required this.baseUrl,
    required this.preset,
    required this.updatedAt,
  });

  factory ServerConfigModel.defaultConfig() {
    return ServerConfigModel(
      baseUrl: ApiConfig.defaultBaseUrl,
      preset: ServerEnvironmentPreset.vpsServer,
      updatedAt: DateTime.now(),
    );
  }

  ServerConfigModel copyWith({
    String? baseUrl,
    ServerEnvironmentPreset? preset,
  }) {
    return ServerConfigModel(
      baseUrl: baseUrl ?? this.baseUrl,
      preset: preset ?? this.preset,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'preset': preset.name,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ServerConfigModel.fromJson(Map<String, dynamic> json) {
    return ServerConfigModel(
      baseUrl: json['baseUrl'] as String? ?? ServerEnvironmentPreset.emulator.defaultUrl,
      preset: ServerEnvironmentPreset.values.firstWhere(
        (p) => p.name == json['preset'],
        orElse: () => ServerEnvironmentPreset.custom,
      ),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

