/// Mô hình dữ liệu đánh giá quán ăn & shipper (ReviewResponse)
class ReviewModel {
  final int id;
  final int orderId;
  final int storeId;
  final String storeName;
  final int userId;
  final String userDisplayName;
  final int storeRating;
  final int shipperRating;
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.userId,
    required this.userDisplayName,
    required this.storeRating,
    required this.shipperRating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      storeId: (json['storeId'] as num?)?.toInt() ?? 0,
      storeName: json['storeName'] as String? ?? 'Quán ăn KTX',
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      userDisplayName: json['userDisplayName'] as String? ?? 'Sinh viên KTX',
      storeRating: (json['storeRating'] as num?)?.toInt() ?? 5,
      shipperRating: (json['shipperRating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
