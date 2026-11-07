import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý chính sách chiết khấu hoa hồng nền tảng KTX Food (Dynamic Platform Commission)
/// Ban hành bởi Role Admin và áp dụng tự động cho toàn bộ Quán ăn trong hệ thống
class CommissionPolicyService extends ChangeNotifier {
  static final CommissionPolicyService _instance = CommissionPolicyService._internal();
  factory CommissionPolicyService() => _instance;
  CommissionPolicyService._internal();

  static const String _prefKey = 'ktx_platform_commission_rate';
  static const String _deliveryFeePrefKey = 'ktx_platform_delivery_fee';
  double _commissionRate = 10.0; // Mặc định 10%
  double _deliveryFee = 5000.0; // Mặc định 5.000đ

  double get commissionRate => _commissionRate;
  double get deliveryFee => _deliveryFee;

  /// Tỷ lệ % thực nhận của quán sau chiết khấu (VD: 90% khi sàn thu 10%)
  double get storePayoutRate => 100.0 - _commissionRate;

  /// Tải tỷ lệ chiết khấu và phí ship đã lưu từ bộ nhớ máy
  Future<double> loadCommissionRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _commissionRate = prefs.getDouble(_prefKey) ?? 10.0;
      _deliveryFee = prefs.getDouble(_deliveryFeePrefKey) ?? 5000.0;
    } catch (_) {
      _commissionRate = 10.0;
      _deliveryFee = 5000.0;
    }
    notifyListeners();
    return _commissionRate;
  }

  /// Tải phí ship gom đơn KTX
  Future<double> loadDeliveryFee() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deliveryFee = prefs.getDouble(_deliveryFeePrefKey) ?? 5000.0;
    } catch (_) {
      _deliveryFee = 5000.0;
    }
    notifyListeners();
    return _deliveryFee;
  }

  /// Cập nhật phí ship gom đơn mới (0đ - 30.000đ)
  Future<bool> updateDeliveryFee(double newFee) async {
    if (newFee < 0.0 || newFee > 30000.0) return false;
    _deliveryFee = newFee;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_deliveryFeePrefKey, newFee);
    } catch (_) {}
    notifyListeners();
    return true;
  }

  /// Cập nhật tỷ lệ chiết khấu mới do Ban Quản Lý (Admin) cấu hình (chỉ nhập số 0 - 50%)
  Future<bool> updateCommissionRate(double newRate) async {
    if (newRate < 0.0 || newRate > 50.0) return false;
    _commissionRate = newRate;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKey, newRate);
    } catch (_) {}
    notifyListeners();
    return true;
  }

  /// Tính tiền phí hoa hồng nền tảng thu được từ giá bán món
  double calculatePlatformFee(double price) {
    if (price <= 0) return 0;
    return price * (_commissionRate / 100.0);
  }

  /// Tính tiền thực nhận chuyển về tài khoản quán ăn
  double calculateNetPayout(double price) {
    if (price <= 0) return 0;
    return price * ((100.0 - _commissionRate) / 100.0);
  }
}

