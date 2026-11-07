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
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      throw Exception('Không thể tải danh sách chuyến gom đơn từ máy chủ ($e)');
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
      return false;
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
      return false;
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
      return false;
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
      return false;
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
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      throw Exception('Không thể tải thông tin ví shipper từ máy chủ ($e)');
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
      return false;
    }
  }
}