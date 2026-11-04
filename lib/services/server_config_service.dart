import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config_model.dart';
import 'api_config.dart';

/// Dịch vụ quản lý lưu trữ và chuyển đổi địa chỉ máy chủ Backend động
class ServerConfigService {
  static const String _storageKey = 'prm_custom_server_config';
  final http.Client _client;

  ServerConfigService({http.Client? client}) : _client = client ?? http.Client();

  /// Tải cấu hình máy chủ từ SharedPreferences
  Future<ServerConfigModel> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final config = ServerConfigModel.fromJson(map);
        ApiConfig.setDynamicBaseUrl(config.baseUrl);
        return config;
      }
    } catch (_) {}

    final defaultConfig = ServerConfigModel.defaultConfig();
    ApiConfig.setDynamicBaseUrl(defaultConfig.baseUrl);
    return defaultConfig;
  }

  /// Lưu cấu hình máy chủ mới và cập nhật tức thì vào ApiConfig
  Future<void> saveConfig(ServerConfigModel config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(config.toJson()));
    } catch (_) {}
    ApiConfig.setDynamicBaseUrl(config.baseUrl);
  }

  /// Ping kiểm tra khả năng phản hồi của URL máy chủ trước khi lưu
  Future<bool> pingServer(String baseUrl) async {
    final sanitized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final pingUrl = Uri.parse('$sanitized/health');

    try {
      final res = await _client.get(pingUrl).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
