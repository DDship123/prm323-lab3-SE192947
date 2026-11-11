import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/dispute_model.dart';
import '../models/order_model.dart';
import 'api_config.dart';

/// Dịch vụ giao tiếp RESTful API phân hệ Khiếu nại & Hoàn tiền
class DisputeService {
  final http.Client _client;

  DisputeService({http.Client? client}) : _client = client ?? http.Client();

  /// Gửi khiếu nại kèm link ảnh Cloud Storage sang Backend Spring Boot
  Future<DisputeModel> submitDispute({
    required CreateDisputeDto dto,
    required String? idToken,
    required String userId,
  }) async {
    final url = Uri.parse(ApiConfig.disputes);
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-User-Id': userId,
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      ).timeout(const Duration(seconds: 10));

      final utf8Body = utf8.decode(response.bodyBytes);
      final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final apiResp = ApiResponse.fromJson(
          jsonMap,
          (data) => DisputeModel.fromJson(data as Map<String, dynamic>),
        );
        if (apiResp.data != null) {
          return apiResp.data!;
        }
      }

      final errorMsg = jsonMap['message'] ?? 'Gửi khiếu nại thất bại (${response.statusCode})';
      throw Exception(errorMsg);
    } catch (e) {
      ApiConfig.log('DISPUTE-ERROR', '❌ Lỗi gửi khiếu nại: $e');
      rethrow;
    }
  }

  /// Lấy danh sách toàn bộ khiếu nại cho Admin Web (API-011: /api/v1/admin/disputes)
  Future<List<DisputeModel>> fetchDisputes() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/disputes');
    try {
      final response = await _client.get(
        url,
        headers: ApiConfig.headers(userId: '4'),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        return rawList.map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      ApiConfig.log('DISPUTE-ERROR', '❌ Lỗi tải khiếu nại Admin: $e');
    }
    return fetchMyDisputes(idToken: null, userId: '4');
  }

  /// Trọng tài phân xử khiếu nại từ Cổng Web Admin
  Future<DisputeModel> resolveDispute(
    int disputeId, {
    required bool isApproved,
    String? adminNotes,
    double approvedRefundAmount = 0.0,
  }) async {
    final url = Uri.parse('${ApiConfig.disputes}/$disputeId/resolve');
    try {
      final response = await _client.patch(
        url,
        headers: ApiConfig.headers(userId: '4'),
        body: jsonEncode({
          'status': isApproved ? 'APPROVED' : 'REJECTED',
          'resolutionNote': adminNotes ?? '',
          'refundApprovedAmount': approvedRefundAmount,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          return DisputeModel.fromJson(data);
        }
      }
    } catch (e) {
      ApiConfig.log('DISPUTE-ERROR', '❌ Lỗi phân xử khiếu nại: $e');
    }
    throw Exception('Không thể cập nhật kết quả phân xử khiếu nại lên máy chủ');
  }

  /// Lấy danh sách lịch sử khiếu nại của sinh viên
  Future<List<DisputeModel>> fetchMyDisputes({
    required String? idToken,
    required String userId,
  }) async {
    final url = Uri.parse(ApiConfig.disputes);
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': userId,
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        return rawList.map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Máy chủ phản hồi mã lỗi ${response.statusCode}');
    } catch (e) {
      throw Exception('Mất kết nối máy chủ khi tải khiếu nại: $e');
    }
  }

  /// Lấy danh sách đơn hàng đã nhận có thể khiếu nại
  Future<List<OrderSummaryModel>> fetchDeliveredOrders({
    required String? idToken,
    required String userId,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.orders);
      final headers = ApiConfig.headers(idToken: idToken);
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        return rawList
            .map((e) => OrderSummaryModel.fromJson(e as Map<String, dynamic>))
            .where((o) => o.status == 'DELIVERED')
            .toList();
      }
      throw Exception('Máy chủ phản hồi mã lỗi ${response.statusCode}');
    } catch (e) {
      throw Exception('Mất kết nối máy chủ khi tải đơn hàng: $e');
    }
  }
}

