import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-017, API-018, API-018b, API Shipper Reviews (Đánh giá Quán ăn & Shipper)
class ReviewService {
  final http.Client _client;

  // Cache cục bộ lưu các đánh giá vừa gửi trong phiên hiện tại
  static final List<ReviewModel> _localReviewsCache = [];

  ReviewService({http.Client? client}) : _client = client ?? http.Client();

  /// API-017: Gửi đánh giá quán ăn & shipper (1 - 5 sao, cmt và ảnh tối đa 3 không ràng buộc)
  Future<ReviewModel> submitReview({
    required int orderId,
    required int storeRating,
    required int shipperRating,
    String? comment,
    String? shipperComment,
    List<String> images = const [],
    String storeName = 'Cơm Tấm Cô Ba - KTX Khu B',
    String shipperName = 'Nguyễn Hùng (Shipper Đội Gom KTX)',
    String userDisplayName = 'Ngô Trường Đạt (Sinh viên)',
    String? userAvatarUrl,
    int storeId = 1,
    int shipperId = 3,
  }) async {
    final sanitizedImages = images.take(3).toList();
    final bodyPayload = {
      'orderId': orderId,
      'storeRating': storeRating,
      'shipperRating': shipperRating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      if (shipperComment != null && shipperComment.trim().isNotEmpty)
        'shipperComment': shipperComment.trim(),
      if (sanitizedImages.isNotEmpty) 'images': sanitizedImages,
    };

    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.reviews),
            headers: ApiConfig.headers(),
            body: jsonEncode(bodyPayload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          final review = ReviewModel.fromJson(data);
          _localReviewsCache.removeWhere((r) => r.orderId == orderId);
          _localReviewsCache.insert(0, review);
          return review;
        }
      }
    } catch (_) {}

    // Fallback tạo model lưu vào bộ nhớ cache nội bộ
    final fallbackReview = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch,
      orderId: orderId,
      orderCode: '#KTX-$orderId',
      storeId: storeId,
      storeName: storeName,
      shipperId: shipperId,
      shipperName: shipperName,
      userId: ApiConfig.currentBackendUserId,
      userDisplayName: userDisplayName,
      userAvatarUrl: userAvatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      storeRating: storeRating,
      shipperRating: shipperRating,
      comment: comment?.trim(),
      shipperComment: shipperComment?.trim(),
      images: sanitizedImages,
      createdAt: DateTime.now(),
    );

    _localReviewsCache.removeWhere((r) => r.orderId == orderId);
    _localReviewsCache.insert(0, fallbackReview);
    return fallbackReview;
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
          final list = content
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    // Fallback trả về từ bộ nhớ cache theo storeId nếu có
    return _localReviewsCache.where((r) => r.storeId == storeId).toList();
  }

  /// Lấy danh sách đánh giá của Shipper kèm avt, username, ảnh
  Future<List<ReviewModel>> fetchShipperReviews(int shipperId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.shippers}/$shipperId/reviews'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'];
        if (data is Map<String, dynamic> && data['content'] is List) {
          final content = data['content'] as List<dynamic>;
          final list = content
              .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {}

    // Fallback danh sách đánh giá cho shipper nếu có
    return _localReviewsCache.where((r) => r.shipperId == shipperId).toList();
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

    return _localReviewsCache.where((r) => r.orderId == orderId).firstOrNull;
  }
}
