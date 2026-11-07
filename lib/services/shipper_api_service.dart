import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipper_batch_model.dart';
import '../models/shipper_wallet_model.dart';
import 'api_config.dart';
import 'delivery_handshake_service.dart';

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
      await DeliveryHandshakeService().loadSavedData();
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(utf8Body) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          final baseBatch = ShipperBatchModel.fromJson(data);
          return await _enrichWithCompletedAndItems(baseBatch, headers);
        }
      }
      throw Exception('Lỗi máy chủ: ${response.statusCode}');
    } catch (e) {
      throw Exception('Không thể tải danh sách chuyến gom đơn từ máy chủ ($e)');
    }
  }

  /// Bổ sung danh sách món ăn chi tiết và toàn bộ các đơn đã hoàn tất (DELIVERED) từ Backend & bộ nhớ
  Future<ShipperBatchModel> _enrichWithCompletedAndItems(
    ShipperBatchModel baseBatch,
    Map<String, String> headers,
  ) async {
    final Map<int, ShipperBatchItemModel> orderMap = {
      for (final item in baseBatch.orders) item.orderId: item,
    };

    try {
      final allOrdersUrl = Uri.parse('${ApiConfig.baseUrl}/admin/orders');
      final allRes = await _client.get(allOrdersUrl, headers: headers).timeout(const Duration(seconds: 4));
      if (allRes.statusCode == 200) {
        final allJson = jsonDecode(utf8.decode(allRes.bodyBytes)) as Map<String, dynamic>;
        final rawList = allJson['data'] as List<dynamic>? ?? [];
        for (final raw in rawList) {
          if (raw is! Map<String, dynamic>) continue;
          final parsed = ShipperBatchItemModel.fromJson(raw);
          if (parsed.orderId <= 0) continue;

          if (orderMap.containsKey(parsed.orderId)) {
            final existing = orderMap[parsed.orderId]!;
            orderMap[parsed.orderId] = existing.copyWith(
              itemSummaries: parsed.itemSummaries.isNotEmpty
                  ? parsed.itemSummaries
                  : existing.itemSummaries,
            );
          } else if (parsed.status == 'DELIVERED') {
            orderMap[parsed.orderId] = parsed;
            DeliveryHandshakeService().saveCompletedOrderSnapshot(parsed);
          }
        }
      }
    } catch (_) {}

    // Bổ sung các đơn đã giao lưu trong DeliveryHandshakeService (nếu chưa có trong map)
    for (final snap in DeliveryHandshakeService().completedOrderSnapshots) {
      if (!orderMap.containsKey(snap.orderId)) {
        orderMap[snap.orderId] = snap;
      } else if (DeliveryHandshakeService().isFullyDelivered(snap.orderId)) {
        orderMap[snap.orderId] = orderMap[snap.orderId]!.copyWith(
          status: 'DELIVERED',
          itemSummaries: orderMap[snap.orderId]!.itemSummaries.isNotEmpty
              ? orderMap[snap.orderId]!.itemSummaries
              : snap.itemSummaries,
        );
      }
    }

    final mergedOrders = orderMap.values.toList()
      ..sort((a, b) => b.orderId.compareTo(a.orderId));

    return ShipperBatchModel(
      slotTime: baseBatch.slotTime,
      campusZone: baseBatch.campusZone,
      totalOrders: mergedOrders.length,
      totalDeliveryEarnings: baseBatch.totalDeliveryEarnings,
      orders: mergedOrders,
    );
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