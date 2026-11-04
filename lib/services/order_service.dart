import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-006 đến API-011 (Đặt đơn gom ca KTX, Theo dõi, Hủy đơn & Nhận hàng QR/PIN)
class OrderService {
  final http.Client _client;

  /// Bộ nhớ đệm cục bộ phục vụ trường hợp demo offline
  static final List<OrderDetailModel> _localOrders = [];

  OrderService({http.Client? client}) : _client = client ?? http.Client();

  /// API-006: Tạo đơn hàng gom đơn KTX mới
  Future<OrderDetailModel> createOrder({
    required int storeId,
    required String storeName,
    required String slotTime,
    required String pickupLocation,
    required String paymentMethod,
    String? note,
    required List<CartItemModel> items,
  }) async {
    final payload = {
      'storeId': storeId,
      'slotTime': slotTime,
      'pickupLocation': pickupLocation,
      'paymentMethod': paymentMethod,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'items': items.map((e) => e.toOrderItemRequestJson()).toList(),
    };

    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.orders),
            headers: ApiConfig.headers(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      final jsonMap =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonMap['data'] as Map<String, dynamic>;
        final created = OrderDetailModel.fromJson(data);
        _localOrders.insert(0, created);
        return created;
      }
      throw Exception(jsonMap['message'] ?? 'Không thể tạo đơn hàng');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('ClientException')) {
        final subtotal =
            items.fold(0.0, (sum, item) => sum + item.totalPrice);
        const deliveryFee = 5000.0;
        final id = DateTime.now().millisecondsSinceEpoch % 100000;
        final fallbackOrder = OrderDetailModel(
          id: id,
          orderCode: 'KTX-20261104-$id',
          userId: ApiConfig.currentBackendUserId,
          storeId: storeId,
          storeName: storeName,
          slotTime: slotTime,
          pickupLocation: pickupLocation,
          subtotalAmount: subtotal,
          deliveryFee: deliveryFee,
          groupDiscountAmount: 0,
          finalAmount: subtotal + deliveryFee,
          status: paymentMethod == 'COD' ? 'CONFIRMED' : 'PENDING',
          paymentMethod: paymentMethod,
          paymentStatus: 'UNPAID',
          pickupQrCode: 'QR_KTX_$id',
          pickupPin: '3210',
          note: note,
          items: items
              .asMap()
              .entries
              .map(
                (entry) => OrderItemModel(
                  id: entry.key + 1,
                  menuItemId: entry.value.menuItemId,
                  itemName: entry.value.itemName,
                  unitPrice: entry.value.basePrice,
                  quantity: entry.value.quantity,
                  selectedOptions: entry.value.selectedOptions,
                  itemTotalAmount: entry.value.totalPrice,
                ),
              )
              .toList(),
          createdAt: DateTime.now(),
        );
        _localOrders.insert(0, fallbackOrder);
        return fallbackOrder;
      }
      rethrow;
    }
  }

  /// API-007: Lấy chi tiết đơn hàng theo ID
  Future<OrderDetailModel> fetchOrderDetail(int orderId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.orders}/$orderId'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>;
        return OrderDetailModel.fromJson(data);
      }
    } catch (_) {}

    final local = _localOrders.where((o) => o.id == orderId).firstOrNull;
    if (local != null) return local;
    throw Exception('Không tìm thấy đơn hàng #$orderId');
  }

  /// API-008: Lấy danh sách lịch sử đơn hàng của sinh viên
  Future<List<OrderDetailModel>> fetchMyOrders() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.orders), headers: ApiConfig.headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final rawList = jsonMap['data'] as List<dynamic>? ?? [];
        final list = rawList
            .map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {}

    return List<OrderDetailModel>.from(_localOrders);
  }

  /// API-009: Sinh viên hủy đơn hàng khi trạng thái đang là PENDING
  Future<OrderDetailModel> cancelOrder(int orderId) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.orders}/$orderId/cancel'),
          headers: ApiConfig.headers(),
        )
        .timeout(const Duration(seconds: 6));

    final jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return OrderDetailModel.fromJson(jsonMap['data'] as Map<String, dynamic>);
    }
    throw Exception(jsonMap['message'] ?? 'Không thể hủy đơn hàng này');
  }

  /// API-010: Chuyển trạng thái đơn hàng theo State Machine (Store/Shipper demo)
  Future<OrderDetailModel> updateOrderStatus({
    required int orderId,
    required String newStatus,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${ApiConfig.orders}/$orderId/status'),
          headers: ApiConfig.headers(),
          body: jsonEncode({'status': newStatus}),
        )
        .timeout(const Duration(seconds: 6));

    final jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return OrderDetailModel.fromJson(jsonMap['data'] as Map<String, dynamic>);
    }
    throw Exception(jsonMap['message'] ?? 'Chuyển trạng thái thất bại');
  }

  /// API-011: Xác nhận đã nhận hàng tại cổng KTX bằng QR_SCAN hoặc PIN
  Future<void> confirmPickup({
    required int orderId,
    required String verificationMethod,
    required String code,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.orders}/$orderId/confirm-pickup'),
          headers: ApiConfig.headers(),
          body: jsonEncode({
            'verificationMethod': verificationMethod,
            'code': code,
          }),
        )
        .timeout(const Duration(seconds: 6));

    final jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
          jsonMap['message'] ?? 'Mã đối soát nhận hàng không hợp lệ');
    }
  }
}
