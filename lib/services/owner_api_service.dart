import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/owner_order_model.dart';
import '../models/store_revenue_model.dart';
import 'api_config.dart';

class OwnerApiService {
  final http.Client _client;

  OwnerApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<OwnerOrderSummaryModel>> fetchKitchenOrders({
    required String? idToken,
    required String ownerId,
    String slotTime = 'CA_TRUA_11H30',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/owner/orders?slotTime=$slotTime');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': ownerId,
      'X-User-Role': 'STORE_OWNER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      ApiConfig.log('DB-OWNER', 'GET $url (OwnerID=$ownerId)');
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        final list = rawList.map((e) => OwnerOrderSummaryModel.fromJson(e as Map<String, dynamic>)).toList();
        ApiConfig.log('DB-OWNER', '✅ Đã tải ${list.length} đơn bếp từ Database');
        return list;
      }
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('DB-OWNER-ERROR', '❌ Lỗi tải đơn bếp: $e');
      throw Exception('Không thể tải danh sách đơn bếp từ máy chủ ($e)');
    }
  }

  Future<bool> updateItemAvailability({
    required int menuItemId,
    required bool isAvailable,
    required String? idToken,
    required String ownerId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/owner/menu-items/$menuItemId/availability');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-User-Id': ownerId,
      'X-User-Role': 'STORE_OWNER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      ApiConfig.log('DB-OWNER', 'PATCH $url | isAvailable=$isAvailable');
      final response = await _client.patch(
        url,
        headers: headers,
        body: jsonEncode({'isAvailable': isAvailable}),
      ).timeout(const Duration(seconds: 4));
      ApiConfig.log('DB-OWNER', '✅ Đổi trạng thái món ID=$menuItemId -> HTTP ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      ApiConfig.log('DB-OWNER-ERROR', '❌ Lỗi đổi trạng thái món ID=$menuItemId: $e');
      return false;
    }
  }

  Future<StoreRevenueModel> fetchRevenueReport({
    required String? idToken,
    required String ownerId,
    String slotTime = 'CA_TRUA_11H30',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/owner/revenue?slotTime=$slotTime');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': ownerId,
      'X-User-Role': 'STORE_OWNER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      ApiConfig.log('DB-OWNER', 'GET $url');
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>;
        final rev = StoreRevenueModel.fromJson(data);
        ApiConfig.log('DB-OWNER', '✅ Đã tải báo cáo doanh thu quán từ Database');
        return rev;
      }
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('DB-OWNER-ERROR', '❌ Lỗi tải báo cáo doanh thu: $e');
      throw Exception('Không thể tải báo cáo doanh thu từ máy chủ ($e)');
    }
  }
}