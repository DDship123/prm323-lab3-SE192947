import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-017, API-018, API-018b (Đánh giá Quán ăn & Shipper)
class ReviewService {
  final http.Client _client;

  ReviewService({http.Client? client}) : _client = client ?? http.Client();

  /// API-017: Gửi đánh giá quán ăn & shipper (1 - 5 sao)
  Future<ReviewModel> submitReview({
    required int orderId,
    required int storeRating,
    required int shipperRating,
    required String comment,
  }) async {
    final response = await _client
        .post(
          Uri.parse(ApiConfig.reviews),
          headers: ApiConfig.headers(),
          body: jsonEncode({
            'orderId': orderId,
            'storeRating': storeRating,
            'shipperRating': shipperRating,
            'comment': comment.trim(),
          }),
        )
        .timeout(const Duration(seconds: 6));

    final jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReviewModel.fromJson(jsonMap['data'] as Map<String, dynamic>);
    }
    throw Exception(jsonMap['message'] ?? 'Không thể gửi đánh giá');
  }

  /// API-018: Lấy danh sách đánh giá của quán ăn
  Future<List<ReviewModel>> fetchStoreReviews(int storeId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.stores}/$storeId/reviews'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'];
        if (data is Map<String, dynamic> && data['content'] is List) {
          final content = data['content'] as List<dynamic>;
          return content
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  /// API-018b: Xem đánh giá của một đơn hàng cụ thể
  Future<ReviewModel?> fetchOrderReview(int orderId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.orders}/$orderId/review'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ReviewModel.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }
}
