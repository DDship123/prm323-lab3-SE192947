/// Loại mã giảm giá / khuyến mãi trong hệ thống KTX Food
enum VoucherType {
  /// Giảm trực tiếp vào phí giao hàng gom đơn (không trừ lẹm vào tiền món ăn)
  shipping,

  /// Giảm trực tiếp vào tổng tiền món ăn của quán
  order,
}

/// Model dữ liệu Mã giảm giá do Ban Quản Lý (Admin) cấu hình và ban hành
class VoucherModel {
  final String code;
  final String title;
  final String description;
  final VoucherType type;
  final double discountAmount;
  final double minOrderValue;
  final int maxUsagePerAccount;
  final int usedCount;
  final bool isActive;

  const VoucherModel({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.discountAmount,
    this.minOrderValue = 0,
    this.maxUsagePerAccount = 1,
    this.usedCount = 0,
    this.isActive = true,
  });

  /// Tính toán số tiền thực tế được giảm khi áp dụng vào đơn hàng
  /// - Với voucher phí ship: Số tiền giảm TỐI ĐA bằng đúng phí ship, KHÔNG ĐƯỢC trừ vào tiền món.
  /// - Với voucher tiền món: Số tiền giảm TỐI ĐA bằng đúng tổng tiền món.
  double calculateActualDiscount({
    required double itemsSubtotal,
    required double deliveryFee,
  }) {
    if (!isActive) return 0.0;
    if (itemsSubtotal < minOrderValue) return 0.0;

    if (type == VoucherType.shipping) {
      // Chỉ trừ tối đa bằng phí ship hiện tại
      return discountAmount > deliveryFee ? deliveryFee : discountAmount;
    } else {
      // Trừ tối đa bằng tiền món ăn
      return discountAmount > itemsSubtotal ? itemsSubtotal : discountAmount;
    }
  }

  VoucherModel copyWith({
    String? code,
    String? title,
    String? description,
    VoucherType? type,
    double? discountAmount,
    double? minOrderValue,
    int? maxUsagePerAccount,
    int? usedCount,
    bool? isActive,
  }) {
    return VoucherModel(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      discountAmount: discountAmount ?? this.discountAmount,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxUsagePerAccount: maxUsagePerAccount ?? this.maxUsagePerAccount,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type.name,
      'discountAmount': discountAmount,
      'minOrderValue': minOrderValue,
      'maxUsagePerAccount': maxUsagePerAccount,
      'usedCount': usedCount,
      'isActive': isActive,
    };
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: (json['type'] as String?) == 'order'
          ? VoucherType.order
          : VoucherType.shipping,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxUsagePerAccount: (json['maxUsagePerAccount'] as num?)?.toInt() ?? 1,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

