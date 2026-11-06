import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý Cơ chế Đối soát & Xác nhận 2 chiều (Handshake) giữa Sinh viên & Shipper
/// Quy tắc:
/// Đơn hàng hoàn tất (DELIVERED) khi thỏa mãn 2 điều kiện (không phân biệt ai làm trước ai làm sau):
/// 1. Sinh viên bấm "Xác nhận đã nhận hàng" trên app Sinh viên
/// 2. Shipper quét mã QR của Sinh viên HOẶC Shipper nhập đúng mã PIN 4 số mà Sinh viên cung cấp
class DeliveryHandshakeService extends ChangeNotifier {
  static final DeliveryHandshakeService _instance = DeliveryHandshakeService._internal();
  factory DeliveryHandshakeService() => _instance;
  DeliveryHandshakeService._internal();

  final Map<int, bool> _studentConfirmations = {};
  final Map<int, bool> _shipperConfirmations = {};
  final Set<int> _completedOrderIds = {};
  double _extraShipperEarnings = 0.0;

  double get extraShipperEarnings => _extraShipperEarnings;

  bool isStudentConfirmed(int orderId) => _studentConfirmations[orderId] ?? false;
  bool isShipperConfirmed(int orderId) => _shipperConfirmations[orderId] ?? false;
  bool isFullyDelivered(int orderId) => _completedOrderIds.contains(orderId);

  /// Sinh viên bấm nút "Xác nhận đã nhận hàng"
  void confirmByStudent(int orderId) {
    _studentConfirmations[orderId] = true;
    if (isShipperConfirmed(orderId)) {
      _markCompleted(orderId);
    }
    notifyListeners();
  }

  /// Shipper quét mã QR hoặc nhập đúng mã PIN 4 số của Sinh viên
  void confirmByShipper(int orderId) {
    _shipperConfirmations[orderId] = true;
    if (isStudentConfirmed(orderId)) {
      _markCompleted(orderId);
    }
    notifyListeners();
  }

  /// Bàn giao hoàn tất cả 2 bên (khi cả 2 đều đã xác nhận hoặc cưỡng chế hoàn tất tại bàn)
  void forceCompleteHandover(int orderId) {
    _studentConfirmations[orderId] = true;
    _shipperConfirmations[orderId] = true;
    _markCompleted(orderId);
    notifyListeners();
  }

  void _markCompleted(int orderId) {
    if (!_completedOrderIds.contains(orderId)) {
      _completedOrderIds.add(orderId);
      // Cộng 15.000đ thù lao chuyến giao vào ví shipper
      _extraShipperEarnings += 15000.0;
    }
  }

  /// Tải dữ liệu lưu trữ
  Future<void> loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('ktx_completed_handover_orders') ?? [];
      for (final idStr in savedList) {
        final id = int.tryParse(idStr);
        if (id != null) {
          _completedOrderIds.add(id);
          _studentConfirmations[id] = true;
          _shipperConfirmations[id] = true;
        }
      }
      _extraShipperEarnings = prefs.getDouble('ktx_extra_shipper_earnings') ?? 0.0;
    } catch (_) {}
    notifyListeners();
  }

  /// Lưu trữ
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = _completedOrderIds.map((id) => id.toString()).toList();
      await prefs.setStringList('ktx_completed_handover_orders', strList);
      await prefs.setDouble('ktx_extra_shipper_earnings', _extraShipperEarnings);
    } catch (_) {}
  }

  void resetOrder(int orderId) {
    _studentConfirmations.remove(orderId);
    _shipperConfirmations.remove(orderId);
    _completedOrderIds.remove(orderId);
    notifyListeners();
  }
}
