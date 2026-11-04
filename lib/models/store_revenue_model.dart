import 'owner_order_summary_model.dart';

class StoreRevenueModel {
  final double totalRevenue;
  final double codAmount;
  final double onlineAmount;
  final int totalOrders;
  final int completedOrders;
  final String shiftName;
  final List<OwnerOrderSummaryModel> orderDetails;

  StoreRevenueModel({
    required this.totalRevenue,
    required this.codAmount,
    required this.onlineAmount,
    required this.totalOrders,
    required this.completedOrders,
    required this.shiftName,
    required this.orderDetails,
  });

  factory StoreRevenueModel.fromJson(Map<String, dynamic> json) {
    return StoreRevenueModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      codAmount: (json['codAmount'] as num?)?.toDouble() ?? 0.0,
      onlineAmount: (json['onlineAmount'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      shiftName: json['shiftName'] ?? 'CA_TRUA_11H30',
      orderDetails: (json['orderDetails'] as List<dynamic>?)
              ?.map((e) => OwnerOrderSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
