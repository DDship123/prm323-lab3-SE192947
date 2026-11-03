/// Thực thể tóm tắt đơn hàng phục vụ chọn đơn khiếu nại tại KTX
class OrderSummaryModel {
  final int id;
  final String storeName;
  final double totalPrice;
  final String status;
  final String pickupLocation;
  final DateTime createdAt;

  const OrderSummaryModel({
    required this.id,
    required this.storeName,
    required this.totalPrice,
    required this.status,
    required this.pickupLocation,
    required this.createdAt,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderSummaryModel(
      id: json['id'] as int? ?? 0,
      storeName: json['storeName'] as String? ?? 'Quán ăn KTX',
      totalPrice: (json['finalAmount'] ?? json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'DELIVERED',
      pickupLocation: json['pickupLocation'] as String? ?? 'KTX Khu B - Trụ A1-A2',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
