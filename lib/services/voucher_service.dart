import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voucher_model.dart';

/// Kết quả kiểm tra tính hợp lệ của Voucher
class VoucherValidationResult {
  final bool isValid;
  final String message;
  final VoucherModel? voucher;
  final double discountApplied;

  const VoucherValidationResult({
    required this.isValid,
    required this.message,
    this.voucher,
    this.discountApplied = 0.0,
  });
}

/// Dịch vụ quản lý mã giảm giá / khuyến mãi toàn hệ thống KTX Food (Admin Configurable)
class VoucherService extends ChangeNotifier {
  static final VoucherService _instance = VoucherService._internal();
  factory VoucherService() => _instance;
  VoucherService._internal();

  static const String _prefKey = 'ktx_platform_vouchers';
  List<VoucherModel> _vouchers = [];

  List<VoucherModel> get vouchers => List.unmodifiable(_vouchers);

  /// Danh sách voucher còn hiệu lực dành cho sinh viên
  List<VoucherModel> get activeVouchers =>
      _vouchers.where((v) => v.isActive).toList();

  /// Khởi tạo danh sách voucher mặc định hệ thống KTX Food
  List<VoucherModel> _getDefaultVouchers() {
    return [
      const VoucherModel(
        code: 'SINHVIENKTX',
        title: 'Trợ giá ship KTX',
        description: 'Giảm tối đa 10.000đ phí giao gom chung theo ca KTX',
        type: VoucherType.shipping,
        discountAmount: 10000,
        minOrderValue: 0,
        maxUsagePerAccount: 5,
        usedCount: 142,
        isActive: true,
      ),
      const VoucherModel(
        code: 'FREESHIP5K',
        title: 'Miễn phí gom đơn 5K',
        description: 'Miễn 100% phí ship gom đơn cho sinh viên KTX Khu A & Khu B',
        type: VoucherType.shipping,
        discountAmount: 5000,
        minOrderValue: 0,
        maxUsagePerAccount: 3,
        usedCount: 89,
        isActive: true,
      ),
      const VoucherModel(
        code: 'KTXDISCOUNT10K',
        title: 'Giảm 10.000đ tiền món',
        description: 'Giảm trực tiếp 10.000đ tiền món ăn cho đơn từ 50.000đ',
        type: VoucherType.order,
        discountAmount: 10000,
        minOrderValue: 50000,
        maxUsagePerAccount: 1,
        usedCount: 45,
        isActive: true,
      ),
    ];
  }

  /// Tải danh sách voucher từ bộ nhớ máy
  Future<void> loadVouchers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_prefKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        _vouchers = decoded.map((item) => VoucherModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        _vouchers = _getDefaultVouchers();
        await _saveToStorage();
      }
    } catch (_) {
      _vouchers = _getDefaultVouchers();
    }
    notifyListeners();
  }

  /// Lưu danh sách voucher vào bộ nhớ
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_vouchers.map((v) => v.toJson()).toList());
      await prefs.setString(_prefKey, raw);
    } catch (_) {}
  }

  /// Tìm voucher theo mã code
  VoucherModel? findByCode(String code) {
    try {
      return _vouchers.firstWhere(
        (v) => v.code.trim().toUpperCase() == code.trim().toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Xác thực mã voucher khi sinh viên nhập hoặc chọn áp dụng
  VoucherValidationResult validateVoucher({
    required String code,
    required double itemsSubtotal,
    required double deliveryFee,
  }) {
    final voucher = findByCode(code);
    if (voucher == null) {
      return const VoucherValidationResult(
        isValid: false,
        message: 'Mã giảm giá không tồn tại trong hệ thống',
      );
    }

    if (!voucher.isActive) {
      return VoucherValidationResult(
        isValid: false,
        message: 'Mã "${voucher.code}" đã bị Ban Quản Lý KTX tạm ngưng kích hoạt!',
        voucher: voucher,
      );
    }

    if (itemsSubtotal < voucher.minOrderValue) {
      return VoucherValidationResult(
        isValid: false,
        message: 'Đơn hàng chưa đủ giá trị tối thiểu ${voucher.minOrderValue.toInt()}đ để dùng mã này!',
        voucher: voucher,
      );
    }

    final discount = voucher.calculateActualDiscount(
      itemsSubtotal: itemsSubtotal,
      deliveryFee: deliveryFee,
    );

    return VoucherValidationResult(
      isValid: true,
      message: 'Áp dụng mã ${voucher.code} thành công',
      voucher: voucher,
      discountApplied: discount,
    );
  }

  /// Bật / Tắt trạng thái hoạt động của Voucher (Dành cho Admin)
  Future<void> toggleVoucherStatus(String code, bool isActive) async {
    final index = _vouchers.indexWhere(
      (v) => v.code.trim().toUpperCase() == code.trim().toUpperCase(),
    );
    if (index != -1) {
      _vouchers[index] = _vouchers[index].copyWith(isActive: isActive);
      await _saveToStorage();
      notifyListeners();
    }
  }

  /// Cập nhật thông tin voucher (Số tiền giảm, số lượt dùng, đơn tối thiểu, ...)
  Future<void> updateVoucher(VoucherModel updated) async {
    final index = _vouchers.indexWhere(
      (v) => v.code.trim().toUpperCase() == updated.code.trim().toUpperCase(),
    );
    if (index != -1) {
      _vouchers[index] = updated;
      await _saveToStorage();
      notifyListeners();
    }
  }

  /// Tạo voucher mới do Admin cấu hình
  Future<bool> createVoucher(VoucherModel newVoucher) async {
    final exists = _vouchers.any(
      (v) => v.code.trim().toUpperCase() == newVoucher.code.trim().toUpperCase(),
    );
    if (exists) return false;

    _vouchers.insert(0, newVoucher);
    await _saveToStorage();
    notifyListeners();
    return true;
  }

  /// Xóa voucher khỏi hệ thống
  Future<void> deleteVoucher(String code) async {
    _vouchers.removeWhere(
      (v) => v.code.trim().toUpperCase() == code.trim().toUpperCase(),
    );
    await _saveToStorage();
    notifyListeners();
  }

  /// Đặt lại danh sách mặc định
  Future<void> resetToDefaults() async {
    _vouchers = _getDefaultVouchers();
    await _saveToStorage();
    notifyListeners();
  }
}
