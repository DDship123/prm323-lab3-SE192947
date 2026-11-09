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
    String? voucherCode,
    double? groupDiscountAmount,
    double? deliveryFee,
  }) async {
    final payload = {
      'storeId': storeId,
      'slotTime': slotTime,
      'pickupLocation': pickupLocation,
      'paymentMethod': paymentMethod,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (voucherCode != null && voucherCode.trim().isNotEmpty) 'voucherCode': voucherCode.trim(),
      if (groupDiscountAmount != null && groupDiscountAmount > 0)
        'groupDiscountAmount': groupDiscountAmount,
      if (deliveryFee != null && deliveryFee >= 0)
        'deliveryFee': deliveryFee,
      'items': items.map((e) => e.toOrderItemRequestJson()).toList(),
    };

    try {
      ApiConfig.log('DB-ORDER', 'POST ${ApiConfig.orders} | Tạo đơn quán ID=$storeId (${items.length} món)');
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
        var created = OrderDetailModel.fromJson(data);

        // Bảo đảm: Nếu backend server cũ chưa kịp nạp groupDiscountAmount,
        // client sẽ áp dụng trực tiếp để màn hình thanh toán và VietQR luôn khớp 100% với giỏ hàng
        if (groupDiscountAmount != null && groupDiscountAmount > 0 && created.groupDiscountAmount <= 0) {
          final effectiveFinal = (created.subtotalAmount + created.deliveryFee - groupDiscountAmount).clamp(0.0, double.infinity);
          created = created.copyWith(
            groupDiscountAmount: groupDiscountAmount,
            finalAmount: effectiveFinal,
          );
        }

        _localOrders.insert(0, created);
        ApiConfig.log('DB-ORDER', '✅ Đã lưu đơn hàng #${created.orderCode} vào Database | Tổng: ${created.finalAmount}đ');
        return created;
      }
      throw Exception(jsonMap['message'] ?? 'Không thể tạo đơn hàng từ máy chủ (Mã: ${response.statusCode})');
    } catch (e) {
      ApiConfig.log('DB-ORDER-ERROR', '❌ Lỗi tạo đơn hàng: $e');
      rethrow;
    }
  }

  /// API-007: Lấy chi tiết đơn hàng theo ID
  Future<OrderDetailModel> fetchOrderDetail(int orderId) async {
    try {
      ApiConfig.log('DB-ORDER', 'GET ${ApiConfig.orders}/$orderId');
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
        final detail = OrderDetailModel.fromJson(data);
        ApiConfig.log('DB-ORDER', '✅ Chi tiết đơn #${detail.orderCode} | Trạng thái=${detail.status} | Số món=${detail.items.length}');
        return detail;
      }
    } catch (e) {
      ApiConfig.log('DB-ORDER-ERROR', '❌ Lỗi tải đơn #$orderId: $e');
    }

    final local = _localOrders.where((o) => o.id == orderId).firstOrNull;
    if (local != null) return local;
    throw Exception('Không tìm thấy đơn hàng #$orderId');
  }

  /// API Giám sát toàn bộ đơn hàng gom ca cho Web Admin
  Future<List<OrderDetailModel>> fetchAllOrdersForAdmin() async {
    try {
      ApiConfig.log('DB-ADMIN-ORDERS', 'GET ${ApiConfig.baseUrl}/admin/orders');
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/admin/orders'), headers: ApiConfig.headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final rawList = jsonMap['data'] as List<dynamic>? ?? [];
        final list = rawList
            .map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
            .toList();
        ApiConfig.log('DB-ADMIN-ORDERS', '✅ Đã tải ${list.length} đơn hàng toàn hệ thống từ Database');
        return list;
      }
    } catch (e) {
      ApiConfig.log('DB-ADMIN-ORDERS-ERROR', '❌ Lỗi tải danh sách đơn Admin: $e');
    }
    return fetchMyOrders();
  }

  /// API-008: Lấy danh sách lịch sử đơn hàng của sinh viên
  Future<List<OrderDetailModel>> fetchMyOrders() async {
    try {
      ApiConfig.log('DB-ORDER', 'GET ${ApiConfig.orders} (UserID=${ApiConfig.currentBackendUserId})');
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
        ApiConfig.log('DB-ORDER', '✅ Đã tải ${list.length} đơn hàng lịch sử từ Database');
        return list;
      } else {
        throw Exception('Máy chủ phản hồi mã lỗi ${response.statusCode}');
      }
    } catch (e) {
      ApiConfig.log('DB-ORDER-ERROR', '❌ Lỗi tải lịch sử đơn: $e');
      if (_localOrders.isNotEmpty) {
        return List<OrderDetailModel>.from(_localOrders);
      }
      throw Exception('Mất kết nối máy chủ: $e');
    }
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
