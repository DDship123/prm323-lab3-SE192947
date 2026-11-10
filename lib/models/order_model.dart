/// Tùy chọn Size / Topping đã chọn cho một món ăn trong đơn hàng (Price Snapshot)
class SelectedItemOption {
  final String group;
  final String choice;
  final double extraPrice;

  const SelectedItemOption({
    required this.group,
    required this.choice,
    required this.extraPrice,
  });

  factory SelectedItemOption.fromJson(Map<String, dynamic> json) {
    return SelectedItemOption(
      group: json['group'] as String? ?? '',
      choice: json['choice'] as String? ?? '',
      extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'group': group,
        'choice': choice,
        'extraPrice': extraPrice,
      };
}

/// Chi tiết từng món ăn trong đơn hàng (OrderItemResponse - Price Snapshot)
class OrderItemModel {
  final int id;
  final int menuItemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final List<SelectedItemOption> selectedOptions;
  final double itemTotalAmount;

  const OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    this.selectedOptions = const [],
    required this.itemTotalAmount,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawOpts = json['selectedOptions'] as List<dynamic>? ?? [];
    return OrderItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      menuItemId: (json['menuItemId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedOptions: rawOpts
          .map((e) => SelectedItemOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemTotalAmount: (json['itemTotalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get subtotal => itemTotalAmount;
}

/// Món ăn trong giỏ hàng tạm (Draft Cart Item tại S2/S3/S4)
class CartItemModel {
  final int menuItemId;
  final String itemName;
  final String? imageUrl;
  final double basePrice;
  int quantity;
  final List<SelectedItemOption> selectedOptions;
  final String? itemNote;
  bool isSelected;

  CartItemModel({
    required this.menuItemId,
    required this.itemName,
    this.imageUrl,
    required this.basePrice,
    this.quantity = 1,
    this.selectedOptions = const [],
    this.itemNote,
    this.isSelected = true,
  });

  /// Chữ ký duy nhất phân biệt món có cùng ID nhưng khác Option (VD: 1 phần có xúc xích, 1 phần không có xúc xích)
  String get optionSignature {
    final opts = selectedOptions.map((o) => '${o.group}:${o.choice}:${o.extraPrice}').toList()..sort();
    final notePart = (itemNote ?? '').trim().toLowerCase();
    return '$menuItemId|${opts.join(';')}|$notePart';
  }

  double get extraPriceTotal =>
      selectedOptions.fold(0.0, (sum, opt) => sum + opt.extraPrice);

  double get unitPriceWithOptions => basePrice + extraPriceTotal;

  double get totalPrice => unitPriceWithOptions * quantity;

  Map<String, dynamic> toOrderItemRequestJson() {
    final allOpts = List<SelectedItemOption>.from(selectedOptions);
    if (itemNote != null && itemNote!.trim().isNotEmpty) {
      final exists = allOpts.any((o) => o.group == 'Ghi chú');
      if (!exists) {
        allOpts.add(SelectedItemOption(group: 'Ghi chú', choice: itemNote!.trim(), extraPrice: 0.0));
      }
    }
    return {
      'menuItemId': menuItemId,
      'quantity': quantity,
      'selectedOptions': allOpts.map((e) => e.toJson()).toList(),
    };
  }
}

/// Thực thể chi tiết đơn hàng gom đơn KTX (OrderResponse)
const _sentinel = Object();
class OrderDetailModel {
  final int id;
  final String orderCode;
  final int userId;
  final int storeId;
  final String storeName;
  final String slotTime;
  final String pickupLocation;
  final double subtotalAmount;
  final double deliveryFee;
  final double groupDiscountAmount;
  final double finalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String pickupQrCode;
  final String pickupPin;
  final String? note;
  final List<OrderItemModel> items;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final String? shipperName;
  final String? shipperPhone;
  final int? shipperId;
  final bool isShipperArrived;

  const OrderDetailModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.slotTime,
    required this.pickupLocation,
    required this.subtotalAmount,
    required this.deliveryFee,
    required this.groupDiscountAmount,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.pickupQrCode,
    required this.pickupPin,
    this.note,
    this.items = const [],
    this.deliveredAt,
    required this.createdAt,
    this.shipperName,
    this.shipperPhone,
    this.shipperId,
    this.isShipperArrived = false,
  });

  double get totalPrice => finalAmount;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OrderDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode'] as String? ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      storeId: (json['storeId'] as num?)?.toInt() ?? 1,
      storeName: json['storeName'] as String? ?? 'Quán ăn KTX',
      slotTime: json['slotTime'] as String? ?? 'CA_TRUA_11H30',
      pickupLocation: json['pickupLocation'] as String? ??
          'KTX Khu B – Trụ A1–A2 (Cổng B2)',
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      groupDiscountAmount:
          (json['groupDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'VIETQR',
      paymentStatus: json['paymentStatus'] as String? ?? 'UNPAID',
      pickupQrCode: json['pickupQrCode'] as String? ?? '',
      pickupPin: json['pickupPin'] as String? ?? '0000',
      note: json['note'] as String?,
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      shipperName: json['shipperName'] as String?,
      shipperPhone: json['shipperPhone'] as String?,
      shipperId: (json['shipperId'] as num?)?.toInt() ?? (json['shipper_id'] as num?)?.toInt(),
      isShipperArrived: json['shipperArrived'] == true || json['isShipperArrived'] == true,
    );
  }

  OrderSummaryModel toSummary() => OrderSummaryModel(
        id: id,
        storeName: storeName,
        totalPrice: finalAmount,
        status: status,
        pickupLocation: pickupLocation,
        createdAt: createdAt,
      );

  OrderDetailModel copyWith({
    int? id,
    String? orderCode,
    int? userId,
    int? storeId,
    String? storeName,
    String? slotTime,
    String? pickupLocation,
    double? subtotalAmount,
    double? deliveryFee,
    double? groupDiscountAmount,
    double? finalAmount,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? pickupQrCode,
    String? pickupPin,
    String? note,
    List<OrderItemModel>? items,
    DateTime? deliveredAt,
    DateTime? createdAt,
    Object? shipperName = _sentinel,
    Object? shipperPhone = _sentinel,
    bool? isShipperArrived,
  }) {
    return OrderDetailModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      slotTime: slotTime ?? this.slotTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      groupDiscountAmount: groupDiscountAmount ?? this.groupDiscountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      pickupQrCode: pickupQrCode ?? this.pickupQrCode,
      pickupPin: pickupPin ?? this.pickupPin,
      note: note ?? this.note,
      items: items ?? this.items,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      shipperName: shipperName == _sentinel ? this.shipperName : shipperName as String?,
      shipperPhone: shipperPhone == _sentinel ? this.shipperPhone : shipperPhone as String?,
      isShipperArrived: isShipperArrived ?? this.isShipperArrived,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PREPARING':
        return 'Quán đang chuẩn bị';
      case 'READY':
        return 'Đã gom xong';
      case 'DELIVERING':
        return 'Đang giao tới cổng KTX';
      case 'DELIVERED':
        return 'Đã giao thành công';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

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
      totalPrice:
          (json['finalAmount'] ?? json['totalPrice'] as num?)?.toDouble() ??
              0.0,
      status: json['status'] as String? ?? 'DELIVERED',
      pickupLocation:
          json['pickupLocation'] as String? ?? 'KTX Khu B - Trụ A1-A2',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
