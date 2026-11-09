/// Loại mã giảm giá / khuyến mãi trong hệ thống KTX Food
enum VoucherType {
  /// Giảm trực tiếp vào phí giao hàng (phí gom đơn KTX hoặc giao hỏa tốc)
  shipping,

  /// Giảm trực tiếp vào tổng tiền món ăn của Quán
  order,
}

/// Model dữ liệu Mã giảm giá do Quán ăn (Store) hoặc Ban Quản Lý (Admin) cấu hình
class VoucherModel {
  final String code;
  final String title;
  final String description;
  final VoucherType type;
  final double discountAmount; // Số tiền giảm cố định (hoặc số tiền giảm tối đa nếu có discountPercent)
  final double? discountPercent; // % giảm giá nếu có (VD: 10% cho đơn quán)
  final double minOrderValue;
  final int maxUsagePerAccount;
  final int usageLimit; // Tổng số lượt phát hành tối đa (VD: 50 lượt). 0 = không giới hạn
  final int usedCount; // Số lượt đã sử dụng
  final bool isActive; // Quán hoặc Admin có thể tạm dừng (Inactive) hoặc mở lại (Active)
  final int? storeId; // Null nếu là Voucher toàn KTX / Admin, khác null nếu là Voucher riêng của Quán

  const VoucherModel({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.discountAmount,
    this.discountPercent,
    this.minOrderValue = 0,
    this.maxUsagePerAccount = 1,
    this.usageLimit = 50,
    this.usedCount = 0,
    this.isActive = true,
    this.storeId,
  });

  /// Kiểm tra xem voucher đã hết lượt sử dụng chưa
  bool get isExhausted => usageLimit > 0 && usedCount >= usageLimit;

  /// Voucher có hợp lệ để sinh viên áp dụng không (phải Active và chưa Hết lượt)
  bool get isValidForStudent => isActive && !isExhausted;

  /// Số lượt còn lại
  int get remainingUses => usageLimit > 0 ? (usageLimit - usedCount).clamp(0, usageLimit) : 9999;

  /// Tính toán số tiền thực tế được giảm khi áp dụng vào đơn hàng
  /// - Với voucher phí ship: Số tiền giảm TỐI ĐA bằng đúng phí ship, KHÔNG ĐƯỢC trừ vào tiền món.
  /// - Với voucher tiền món: Số tiền giảm tính theo % hoặc số tiền cố định, TỐI ĐA bằng đúng tiền món.
  double calculateActualDiscount({
    required double itemsSubtotal,
    required double deliveryFee,
  }) {
    if (!isValidForStudent) return 0.0;
    if (itemsSubtotal < minOrderValue) return 0.0;

    if (type == VoucherType.shipping) {
      double shipDiscount = discountAmount;
      if (discountPercent != null && discountPercent! > 0) {
        shipDiscount = deliveryFee * (discountPercent! / 100.0);
      }
      // Chỉ trừ tối đa bằng đúng phí ship hiện tại
      return shipDiscount > deliveryFee ? deliveryFee : shipDiscount;
    } else {
      double foodDiscount = discountAmount;
      if (discountPercent != null && discountPercent! > 0) {
        foodDiscount = itemsSubtotal * (discountPercent! / 100.0);
        // Nếu có trần giảm giá tối đa (discountAmount > 0)
        if (discountAmount > 0 && foodDiscount > discountAmount) {
          foodDiscount = discountAmount;
        }
      }
      // Trừ tối đa bằng tiền món ăn
      return foodDiscount > itemsSubtotal ? itemsSubtotal : foodDiscount;
    }
  }

  VoucherModel copyWith({
    String? code,
    String? title,
    String? description,
    VoucherType? type,
    double? discountAmount,
    double? discountPercent,
    double? minOrderValue,
    int? maxUsagePerAccount,
    int? usageLimit,
    int? usedCount,
    bool? isActive,
    int? storeId,
  }) {
    return VoucherModel(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxUsagePerAccount: maxUsagePerAccount ?? this.maxUsagePerAccount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      storeId: storeId ?? this.storeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type.name,
      'discountAmount': discountAmount,
      if (discountPercent != null) 'discountPercent': discountPercent,
      'minOrderValue': minOrderValue,
      'maxUsagePerAccount': maxUsagePerAccount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      if (storeId != null) 'storeId': storeId,
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
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxUsagePerAccount: (json['maxUsagePerAccount'] as num?)?.toInt() ?? 1,
      usageLimit: (json['usageLimit'] as num?)?.toInt() ?? 50,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      storeId: (json['storeId'] as num?)?.toInt(),
    );
  }
}
