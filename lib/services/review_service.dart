import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-017, API-018, API-018b, API Shipper Reviews (Đánh giá Quán ăn & Shipper)
class ReviewService {
  final http.Client _client;

  // Cache cục bộ hỗ trợ trải nghiệm tức thì và mock offline
  static final List<ReviewModel> _localReviewsCache = [
    ReviewModel(
      id: 101,
      orderId: 1002,
      orderCode: '#KTX-ORD-1002',
      storeId: 1,
      storeName: 'Cơm Tấm Cô Ba - KTX Khu B',
      shipperId: 3,
      shipperName: 'Nguyễn Hùng (Shipper Đội Gom KTX)',
      userId: 1,
      userDisplayName: 'Ngô Trường Đạt (Sinh viên)',
      userAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      storeRating: 5,
      shipperRating: 5,
      comment: 'Cơm sườn nướng mật ong rất ngon, sườn mềm đậm vị, canh nóng hổi. Rất ưng ý!',
      shipperComment: 'Shipper Nguyễn Hùng đến cổng B2 rất đúng giờ, thái độ nhiệt tình lễ phép.',
      images: const [
        'https://images.unsplash.com/photo-1544025162-d76694265947',
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ReviewModel(
      id: 102,
      orderId: 998,
      orderCode: '#KTX-8829B',
      storeId: 1,
      storeName: 'Cơm Tấm Cô Ba - KTX Khu B',
      shipperId: 3,
      shipperName: 'Nguyễn Hùng (Shipper Đội Gom KTX)',
      userId: 2,
      userDisplayName: 'Lê Thùy Linh',
      userAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      storeRating: 5,
      shipperRating: 5,
      comment: 'Đồ ăn giao nóng hổi, chả trứng siêu béo mềm. Sẽ tiếp tục ủng hộ quán!',
      shipperComment: 'Anh shipper gọi trước khi tới cổng 5 phút, tiện ra lấy không phải chờ.',
      images: const [
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

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

    // Fallback trả về từ bộ nhớ cache theo storeId
    final matched = _localReviewsCache.where((r) => r.storeId == storeId).toList();
    if (matched.isNotEmpty) return matched;
    return _localReviewsCache;
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

    // Fallback danh sách đánh giá cho shipper
    final matched = _localReviewsCache.where((r) => r.shipperId == shipperId).toList();
    if (matched.isNotEmpty) return matched;
    return _localReviewsCache;
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
