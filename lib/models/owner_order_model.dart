class OwnerOrderSummaryModel {
  final int id;
  final String orderCode;
  final String customerName;
  final String customerPhone;
  final String slotTime;
  final String pickupLocation;
  final double finalAmount;
  final String status;
  final String paymentMethod;
  final String? note;
  final DateTime createdAt;
  final List<OwnerOrderItemModel> items;

  const OwnerOrderSummaryModel({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.customerPhone,
    required this.slotTime,
    required this.pickupLocation,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    this.note,
    required this.createdAt,
    required this.items,
  });

  factory OwnerOrderSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OwnerOrderSummaryModel(
      id: json['id'] as int? ?? 0,
      orderCode: json['orderCode'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Sinh viên KTX',
      customerPhone: json['customerPhone'] as String? ?? '',
      slotTime: json['slotTime'] as String? ?? '',
      pickupLocation: json['pickupLocation'] as String? ?? '',
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'VIETQR',
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: rawItems
          .map((i) => OwnerOrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OwnerOrderItemModel {
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double itemTotalAmount;
  final String? selectedOptions;

  const OwnerOrderItemModel({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotalAmount,
    this.selectedOptions,
  });

  factory OwnerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return OwnerOrderItemModel(
      itemName: json['itemName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      itemTotalAmount: (json['itemTotalAmount'] as num?)?.toDouble() ?? 0.0,
      selectedOptions: json['selectedOptions'] as String?,
    );
  }
}