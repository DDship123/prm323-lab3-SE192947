import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipper_batch_model.dart';
import '../models/shipper_wallet_model.dart';
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

  Future<bool> cancelPickupAtStore({
    required int orderId,
    required String? idToken,
    required String shipperId,
    String? reason,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/shipper/orders/$orderId/cancel-pickup')
        .replace(queryParameters: reason != null ? {'reason': reason} : null);
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': shipperId,
      'X-User-Role': 'SHIPPER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.patch(uri, headers: headers).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> reportDeliveryFailure({
    required int orderId,
    required String? idToken,
    required String shipperId,
    String? reason,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/shipper/orders/$orderId/report-failure')
        .replace(queryParameters: reason != null ? {'reason': reason} : null);
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': shipperId,
      'X-User-Role': 'SHIPPER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await _client.post(uri, headers: headers).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> confirmDeliveryAtGate({
    required int orderId,
    required String? idToken,
    required String shipperId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shipper/orders/$orderId/deliver');
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
      return true;
    }
  }

  Future<ShipperWalletModel> fetchWallet({
    required String? idToken,
    required String shipperId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shipper/wallet');
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
          return ShipperWalletModel.fromJson(data);
        }
      }
      return _getMockWallet();
    } catch (_) {
      return _getMockWallet();
    }
  }

  Future<bool> withdrawEarnings({
    required double amount,
    required String bankName,
    required String bankAccountNumber,
    required String accountHolderName,
    required String? idToken,
    required String shipperId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shipper/withdraw');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-User-Id': shipperId,
      'X-User-Role': 'SHIPPER',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final body = jsonEncode({
      'amount': amount,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'accountHolderName': accountHolderName,
    });

    try {
      final response = await _client.post(url, headers: headers, body: body).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  ShipperWalletModel _getMockWallet() {
    return ShipperWalletModel(
      walletBalance: 350000,
      pendingEarnings: 30000,
      completedEarnings: 350000,
      completedTrips: 12,
      codCollectedToday: 87000,
      recentTransactions: [
        WalletTransactionItem(
          transactionId: 'TX-KTX-101',
          type: 'CONG_THU_LAO',
          title: 'Thù lao ca gom trưa 11:30 KTX Khu B',
          amount: 30000,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'SUCCESS',
        ),
        WalletTransactionItem(
          transactionId: 'TX-KTX-099',
          type: 'RUT_TIEN',
          title: 'Rút tiền thù lao về Vietcombank (*9876)',
          amount: -200000,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: 'SUCCESS',
        ),
      ],
    );
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