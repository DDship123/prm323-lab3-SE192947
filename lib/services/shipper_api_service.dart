import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipper_batch_model.dart';
import 'api_config.dart';

class ShipperApiService {
  final http.Client _client;

  ShipperApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<ShipperBatchModel> fetchBatches({
    required String? idToken,
    required String shipperId,
    String slotTime = 'CA_TRUA_11H30',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shipper/batches?slotTime=$slotTime');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': shipperId,
      'X-User-Role': 'SHIPPER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ShipperBatchModel.fromJson(data);
        }
      }
      return _getMockBatch();
    } catch (_) {
      return _getMockBatch();
    }
  }

  Future<bool> confirmPickupAtStore({
    required int orderId,
    required String? idToken,
    required String shipperId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shipper/orders/$orderId/pickup');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': shipperId,
      'X-User-Role': 'SHIPPER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.patch(url, headers: headers).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return true; // Fallback demo
    }
  }

  ShipperBatchModel _getMockBatch() {
    return ShipperBatchModel(
      slotTime: 'CA_TRUA_11H30',
      campusZone: 'KTX Khu B – Trụ A1–A2',
      totalOrders: 2,
      totalDeliveryEarnings: 10000,
      orders: [
        ShipperBatchItemModel(
          orderId: 1045,
          orderCode: 'KTX-1045',
          storeName: 'Cơm Tấm Cô Ba - ĐHQG',
          storeAddress: 'Cổng B2 KTX ĐHQG TP.HCM',
          pickupLocation: 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
          customerName: 'Ngô Trường Đạt',
          customerPhone: '0981234567',
          paymentMethod: 'VIETQR',
          finalAmount: 45000,
          status: 'DELIVERING',
          pickupPin: '4567',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        ShipperBatchItemModel(
          orderId: 1046,
          orderCode: 'KTX-1046',
          storeName: 'Cơm Tấm Cô Ba - ĐHQG',
          storeAddress: 'Cổng B2 KTX ĐHQG TP.HCM',
          pickupLocation: 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
          customerName: 'Trần Sanh Điền',
          customerPhone: '0903334444',
          paymentMethod: 'COD',
          finalAmount: 42000,
          status: 'READY',
          pickupPin: '4444',
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      ],
    );
  }
}