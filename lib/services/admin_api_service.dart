import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_dashboard_model.dart';
import '../models/dispute_model.dart';
import 'api_config.dart';

class AdminApiService {
  final http.Client _client;

  AdminApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<AdminDashboardStatsModel> fetchDashboardStats({
    required String adminId,
    String? idToken,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/dashboard-stats');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': adminId,
      'X-User-Role': 'ADMIN',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      ApiConfig.log('DB-ADMIN', 'GET $url');
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>? ?? {};
        final stats = AdminDashboardStatsModel.fromJson(data);
        ApiConfig.log('DB-ADMIN', '✅ Đã tải thống kê Admin Dashboard từ Database');
        return stats;
      }
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('DB-ADMIN-ERROR', '❌ Lỗi tải thống kê Admin: $e');
      throw Exception('Không thể tải số liệu thống kê quản trị từ máy chủ ($e)');
    }
  }

  Future<List<DisputeModel>> fetchAllDisputes({
    required String? idToken,
    required String adminId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/disputes');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': adminId,
      'X-User-Role': 'ADMIN',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      ApiConfig.log('DB-ADMIN', 'GET $url');
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        final list = rawList.map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
        ApiConfig.log('DB-ADMIN', '✅ Đã tải ${list.length} khiếu nại từ Database');
        return list;
      }
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('DB-ADMIN-ERROR', '❌ Lỗi tải danh sách khiếu nại: $e');
      throw Exception('Không thể tải danh sách khiếu nại từ máy chủ ($e)');
    }
  }

  Future<bool> resolveDispute({
    required int disputeId,
    required String status,
    required String resolutionNote,
    required double approvedRefundAmount,
    required String? idToken,
    required String adminId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/disputes/$disputeId/resolve');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-User-Id': adminId,
      'X-User-Role': 'ADMIN',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.patch(
        url,
        headers: headers,
        body: jsonEncode({
          'status': status,
          'resolutionNote': resolutionNote,
          'refundApprovedAmount': approvedRefundAmount,
        }),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}