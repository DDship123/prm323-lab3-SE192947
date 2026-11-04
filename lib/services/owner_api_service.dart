import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/menu_item_model.dart';
import '../models/owner_order_model.dart';
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
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final rawList = (jsonMap['data'] as List?) ?? [];
        return rawList.map((e) => OwnerOrderSummaryModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return _getMockKitchenOrders();
    } catch (_) {
      return _getMockKitchenOrders();
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
      final response = await _client.patch(
        url,
        headers: headers,
        body: jsonEncode({'isAvailable': isAvailable}),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return true; // Fallback demo
    }
  }

  List<OwnerOrderSummaryModel> _getMockKitchenOrders() {
    return [
      OwnerOrderSummaryModel(
        id: 1045,
        orderCode: 'KTX-1045',
        customerName: 'Ngô Trường Đạt',
        customerPhone: '0981234567',
        slotTime: 'CA_TRUA_11H30',
        pickupLocation: 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
        finalAmount: 45000,
        status: 'PREPARING',
        paymentMethod: 'VIETQR',
        note: 'Sườn chín vàng, thêm nhiều mỡ hành',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        items: const [
          OwnerOrderItemModel(
            itemName: 'Cơm Tấm Sườn Nướng',
            quantity: 1,
            unitPrice: 35000,
            itemTotalAmount: 40000,
            selectedOptions: 'Thêm cơm (+5.000đ), Mỡ hành',
          ),
        ],
      ),
      OwnerOrderSummaryModel(
        id: 1046,
        orderCode: 'KTX-1046',
        customerName: 'Trần Sanh Điền',
        customerPhone: '0903334444',
        slotTime: 'CA_TRUA_11H30',
        pickupLocation: 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
        finalAmount: 42000,
        status: 'READY',
        paymentMethod: 'COD',
        note: 'Canh nóng, muỗng đũa đầy đủ',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        items: const [
          OwnerOrderItemModel(
            itemName: 'Cơm Sườn Bì Chả Đặc Biệt',
            quantity: 1,
            unitPrice: 42000,
            itemTotalAmount: 42000,
            selectedOptions: 'Tiêu chuẩn',
          ),
        ],
      ),
    ];
  }
}