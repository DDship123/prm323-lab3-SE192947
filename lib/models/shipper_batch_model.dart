class ShipperBatchModel {
  final String slotTime;
  final String campusZone;
  final int totalOrders;
  final double totalDeliveryEarnings;
  final List<ShipperBatchItemModel> orders;

  const ShipperBatchModel({
    required this.slotTime,
    required this.campusZone,
    required this.totalOrders,
    required this.totalDeliveryEarnings,
    required this.orders,
  });

  factory ShipperBatchModel.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? [];
    return ShipperBatchModel(
      slotTime: json['slotTime'] as String? ?? 'CA_TRUA_11H30',
      campusZone: json['campusZone'] as String? ?? 'KTX_KHU_B',
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalDeliveryEarnings: (json['totalDeliveryEarnings'] as num?)?.toDouble() ?? 0.0,
      orders: rawOrders
          .map((o) => ShipperBatchItemModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShipperBatchItemModel {
  final int orderId;
  final String orderCode;
  final String storeName;
  final String storeAddress;
  final String pickupLocation;
  final String customerName;
  final String customerPhone;
  final String paymentMethod;
  final double finalAmount;
  final String status;
  final String? pickupPin;
  final String? pickupQrCode;
  final DateTime createdAt;
  final List<String> itemSummaries;

  const ShipperBatchItemModel({
    required this.orderId,
    required this.orderCode,
    required this.storeName,
    required this.storeAddress,
    required this.pickupLocation,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.finalAmount,
    required this.status,
    this.pickupPin,
    this.pickupQrCode,
    required this.createdAt,
    this.itemSummaries = const [],
  });

  factory ShipperBatchItemModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedSummaries = <String>[];
    for (final raw in rawItems) {
      if (raw is Map<String, dynamic>) {
        final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
        final name = raw['itemName'] as String? ?? 'Món ăn';
        parsedSummaries.add('${qty}x $name');
      } else if (raw is String) {
        parsedSummaries.add(raw);
      }
    }
    if (parsedSummaries.isEmpty && json['itemSummaries'] is List) {
      for (final s in (json['itemSummaries'] as List)) {
        parsedSummaries.add(s.toString());
      }
    }

    return ShipperBatchItemModel(
      orderId: (json['orderId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode'] as String? ?? '',
      storeName: json['storeName'] as String? ?? 'Quán KTX',
      storeAddress: json['storeAddress'] as String? ?? 'Cổng KTX ĐHQG TP.HCM',
      pickupLocation: json['pickupLocation'] as String? ?? 'KTX Khu B – Cổng B2',
      customerName: json['customerName'] as String? ?? 'Ngô Trường Đạt (Sinh viên)',
      customerPhone: json['customerPhone'] as String? ?? '0968097907',
      paymentMethod: json['paymentMethod'] as String? ?? 'VIETQR',
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'READY',
      pickupPin: json['pickupPin'] as String?,
      pickupQrCode: json['pickupQrCode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      itemSummaries: parsedSummaries,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderCode': orderCode,
        'storeName': storeName,
        'storeAddress': storeAddress,
        'pickupLocation': pickupLocation,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'paymentMethod': paymentMethod,
        'finalAmount': finalAmount,
        'status': status,
        'pickupPin': pickupPin,
        'pickupQrCode': pickupQrCode,
        'createdAt': createdAt.toIso8601String(),
        'itemSummaries': itemSummaries,
      };

  ShipperBatchItemModel copyWith({
    String? status,
    List<String>? itemSummaries,
  }) {
    return ShipperBatchItemModel(
      orderId: orderId,
      orderCode: orderCode,
      storeName: storeName,
      storeAddress: storeAddress,
      pickupLocation: pickupLocation,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMethod: paymentMethod,
      finalAmount: finalAmount,
      status: status ?? this.status,
      pickupPin: pickupPin,
      pickupQrCode: pickupQrCode,
      createdAt: createdAt,
      itemSummaries: itemSummaries ?? this.itemSummaries,
    );
  }
}