import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý chính sách chiết khấu hoa hồng nền tảng KTX Food (Dynamic Platform Commission)
/// Ban hành bởi Role Admin và áp dụng tự động cho toàn bộ Quán ăn trong hệ thống
class CommissionPolicyService extends ChangeNotifier {
  static final CommissionPolicyService _instance = CommissionPolicyService._internal();
  factory CommissionPolicyService() => _instance;
  CommissionPolicyService._internal();

  static const String _prefKey = 'ktx_platform_commission_rate';
  double _commissionRate = 10.0; // Mặc định 10%

  double get commissionRate => _commissionRate;

  /// Tỷ lệ % thực nhận của quán sau chiết khấu (VD: 90% khi sàn thu 10%)
  double get storePayoutRate => 100.0 - _commissionRate;

  /// Tải tỷ lệ chiết khấu đã lưu từ bộ nhớ máy
  Future<double> loadCommissionRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _commissionRate = prefs.getDouble(_prefKey) ?? 10.0;
    } catch (_) {
      _commissionRate = 10.0;
    }
    notifyListeners();
    return _commissionRate;
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

