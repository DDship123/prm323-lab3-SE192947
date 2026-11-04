import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dispute_model.dart';
import 'api_config.dart';

class AdminApiService {
  final http.Client _client;

  AdminApiService({http.Client? client}) : _client = client ?? http.Client();

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
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        return rawList.map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return _getMockAllDisputes();
    } catch (_) {
      return _getMockAllDisputes();
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
      return true; // Fallback demo
    }
  }

  List<DisputeModel> _getMockAllDisputes() {
    return [
      DisputeModel(
        id: 1,
        orderId: 1045,
        storeName: 'Cơm Tấm Cô Ba - ĐHQG',
        reason: 'Món ăn có dị vật / Hỏng vị',
        description: 'Cơm sườn bị chua và không có thìa dĩa.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
        requestedRefundAmount: 45000,
        approvedRefundAmount: 45000,
        status: DisputeStatus.pending,
        adminNote: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      DisputeModel(
        id: 2,
        orderId: 1042,
        storeName: 'Bún Bò Huế O Xuân - Khu A',
        reason: 'Giao thiếu món trong đơn',
        description: 'Thiếu 01 ly trà tắc khổng lồ.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
        requestedRefundAmount: 15000,
        approvedRefundAmount: 15000,
        status: DisputeStatus.approved,
        adminNote: 'Đã hoàn 15.000đ vào ví sinh viên',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}