/// Mô hình dữ liệu đánh giá quán ăn & shipper (ReviewResponse)
class ReviewModel {
  final int id;
  final int orderId;
  final String orderCode;
  final int storeId;
  final String storeName;
  final int? shipperId;
  final String shipperName;
  final int userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final int storeRating;
  final int shipperRating;
  final String? comment;
  final String? shipperComment;
  final List<String> images;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    this.orderCode = '',
    required this.storeId,
    required this.storeName,
    this.shipperId,
    this.shipperName = 'Tài xế Gom KTX',
    required this.userId,
    required this.userDisplayName,
    this.userAvatarUrl,
    required this.storeRating,
    required this.shipperRating,
    this.comment,
    this.shipperComment,
    this.images = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is String && (json['images'] as String).isNotEmpty) {
      parsedImages = (json['images'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return ReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode'] as String? ?? '#KTX-${json['orderId'] ?? 0}',
      storeId: (json['storeId'] as num?)?.toInt() ?? 0,
      storeName: json['storeName'] as String? ?? 'Quán ăn KTX',
      shipperId: (json['shipperId'] as num?)?.toInt(),
      shipperName: json['shipperName'] as String? ?? 'Tài xế Gom KTX',
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      userDisplayName: json['userDisplayName'] as String? ?? 'Sinh viên KTX',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      storeRating: (json['storeRating'] as num?)?.toInt() ?? 5,
      shipperRating: (json['shipperRating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      shipperComment: json['shipperComment'] as String?,
      images: parsedImages,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'orderCode': orderCode,
        'storeId': storeId,
        'storeName': storeName,
        'shipperId': shipperId,
        'shipperName': shipperName,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userAvatarUrl': userAvatarUrl,
        'storeRating': storeRating,
        'shipperRating': shipperRating,
        'comment': comment,
        'shipperComment': shipperComment,
        'images': images,
        'createdAt': createdAt.toIso8601String(),
      };
}
