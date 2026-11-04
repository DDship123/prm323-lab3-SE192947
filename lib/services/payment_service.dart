import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-012 & API-013 (Thanh toán VietQR Napas 247 & Dự phòng COD Fallback)
class PaymentService {
  final http.Client _client;

  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  /// API-012: Sinh link và mã VietQR thanh toán cho đơn hàng
  Future<PaymentModel> generateVietQr({
    required int orderId,
    required double fallbackAmount,
    required String fallbackOrderCode,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.payments}/$orderId/generate-qr'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>;
        return PaymentModel.fromJson(data);
      }
    } catch (_) {}

    final content = 'ORD_$orderId';
    final intAmount = fallbackAmount.round();
    return PaymentModel(
      id: orderId,
      orderId: orderId,
      orderCode: fallbackOrderCode,
      paymentMethod: 'VIETQR',
      amount: fallbackAmount,
      status: 'UNPAID',
      vietqrContent: content,
      qrUrl:
          'https://img.vietqr.io/image/970422-0987654321-compact2.png?amount=$intAmount&addInfo=$content&accountName=KTX+FOOD+ORDERING',
      bankBin: '970422',
      bankName: 'MBBank',
      accountNumber: '0987654321',
      accountName: 'KTX FOOD ORDERING',
    );
  }

  /// API-013: Đổi phương thức thanh toán sang Tiền mặt (COD Fallback)
  Future<PaymentModel> switchToCod(int orderId) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.payments}/$orderId/switch-to-cod'),
          headers: ApiConfig.headers(),
        )
        .timeout(const Duration(seconds: 6));

    final jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return PaymentModel.fromJson(jsonMap['data'] as Map<String, dynamic>);
    }
    throw Exception(jsonMap['message'] ?? 'Không thể chuyển sang COD');
  }

  /// Xác nhận thanh toán VietQR thành công (dùng cho demo)
  Future<PaymentModel> confirmPaymentSuccess(int orderId) async {
    final txRef = 'VQR_${DateTime.now().millisecondsSinceEpoch}';
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.payments}/$orderId/confirm-success'),
          headers: ApiConfig.headers(),
          body: jsonEncode({'transactionRef': txRef}),
        )
        .timeout(const Duration(seconds: 6));

    final jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return PaymentModel.fromJson(jsonMap['data'] as Map<String, dynamic>);
    }
    throw Exception(jsonMap['message'] ?? 'Xác nhận thanh toán thất bại');
  }
}
