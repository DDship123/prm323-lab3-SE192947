import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shipper_batch_model.dart';

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
  final Set<int> _arrivedOrderIds = {};
  final Map<int, ShipperBatchItemModel> _completedOrderSnapshots = {};
  double _extraShipperEarnings = 0.0;
  int _lastArrivalTimestamp = 0;

  double get extraShipperEarnings => _extraShipperEarnings;
  List<ShipperBatchItemModel> get completedOrderSnapshots =>
      _completedOrderSnapshots.values.toList();
  int get lastArrivalTimestamp => _lastArrivalTimestamp;

  bool isAnyShipperArrivedRecently({int withinSeconds = 300}) {
    if (_lastArrivalTimestamp <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastArrivalTimestamp) < (withinSeconds * 1000);
  }

  final Set<int> _poppedDialogOrderIds = {};

  bool hasPoppedDialog(int orderId) => _poppedDialogOrderIds.contains(orderId);
  void markDialogPopped(int orderId) {
    _poppedDialogOrderIds.add(orderId);
    saveToStorage();
  }

  bool isStudentConfirmed(int orderId) => _studentConfirmations[orderId] ?? false;
  bool isShipperConfirmed(int orderId) => _shipperConfirmations[orderId] ?? false;
  bool isShipperArrived(int orderId) => _arrivedOrderIds.contains(orderId);
  bool isFullyDelivered(int orderId) => _completedOrderIds.contains(orderId);

  /// Shipper bấm nút báo đã đến điểm giao hàng KTX
  void markShipperArrived(int orderId) {
    _arrivedOrderIds.add(orderId);
    _lastArrivalTimestamp = DateTime.now().millisecondsSinceEpoch;
    saveToStorage();
    notifyListeners();
  }

  /// Shipper bấm nút báo toàn bộ các đơn trong chuyến gom đã đến nơi
  void markAllShipperArrived(Iterable<int> orderIds) {
    _arrivedOrderIds.addAll(orderIds);
    _lastArrivalTimestamp = DateTime.now().millisecondsSinceEpoch;
    saveToStorage();
    notifyListeners();
  }

  /// Lưu bản chụp đơn hàng đã giao thành công để hiển thị ngay cả sau khi F5
  void saveCompletedOrderSnapshot(ShipperBatchItemModel item) {
    _completedOrderSnapshots[item.orderId] = item.copyWith(status: 'DELIVERED');
    _completedOrderIds.add(item.orderId);
    saveToStorage();
    notifyListeners();
  }

  /// Sinh viên bấm nút "Xác nhận đã nhận hàng"
  void confirmByStudent(int orderId) {
    _studentConfirmations[orderId] = true;
    if (isShipperConfirmed(orderId)) {
      _markCompleted(orderId);
    }
    saveToStorage();
    notifyListeners();
  }

  /// Shipper quét mã QR hoặc nhập đúng mã PIN 4 số của Sinh viên
  void confirmByShipper(int orderId, {ShipperBatchItemModel? snapshot}) {
    _shipperConfirmations[orderId] = true;
    if (snapshot != null) {
      _completedOrderSnapshots[orderId] = snapshot.copyWith(status: 'DELIVERED');
    }
    if (isStudentConfirmed(orderId)) {
      _markCompleted(orderId);
    }
    saveToStorage();
    notifyListeners();
  }

  /// Bàn giao hoàn tất cả 2 bên (khi cả 2 đều đã xác nhận hoặc cưỡng chế hoàn tất tại bàn)
  void forceCompleteHandover(int orderId, {ShipperBatchItemModel? snapshot}) {
    _studentConfirmations[orderId] = true;
    _shipperConfirmations[orderId] = true;
    if (snapshot != null) {
      _completedOrderSnapshots[orderId] = snapshot.copyWith(status: 'DELIVERED');
    }
    _markCompleted(orderId);
    saveToStorage();
    notifyListeners();
  }

  void _markCompleted(int orderId) {
    if (!_completedOrderIds.contains(orderId)) {
      _completedOrderIds.add(orderId);
      // Cộng 15.000đ thù lao chuyến giao vào ví shipper
      _extraShipperEarnings += 15000.0;
    }
  }

  /// Tải dữ liệu lưu trữ (chỉ phát thông báo notifyListeners khi dữ liệu thực sự thay đổi)
  Future<bool> loadSavedData({bool notify = true}) async {
    bool hasChanged = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final newTimestamp = prefs.getInt('ktx_last_shipper_arrival_time') ?? 0;
      if (newTimestamp != _lastArrivalTimestamp) {
        _lastArrivalTimestamp = newTimestamp;
        hasChanged = true;
      }
      final savedList = prefs.getStringList('ktx_completed_handover_orders') ?? [];
      for (final idStr in savedList) {
        final id = int.tryParse(idStr);
        if (id != null) {
          if (!_completedOrderIds.contains(id)) hasChanged = true;
          _completedOrderIds.add(id);
          _studentConfirmations[id] = true;
          _shipperConfirmations[id] = true;
        }
      }
      final savedArrived = prefs.getStringList('ktx_arrived_orders') ?? [];
      for (final idStr in savedArrived) {
        final id = int.tryParse(idStr);
        if (id != null) {
          if (!_arrivedOrderIds.contains(id)) hasChanged = true;
          _arrivedOrderIds.add(id);
        }
      }
      final savedPopped = prefs.getStringList('ktx_popped_dialog_orders') ?? [];
      for (final idStr in savedPopped) {
        final id = int.tryParse(idStr);
        if (id != null) {
          _poppedDialogOrderIds.add(id);
        }
      }
      final savedSnapshots = prefs.getStringList('ktx_completed_order_snapshots') ?? [];
      for (final jsonStr in savedSnapshots) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final item = ShipperBatchItemModel.fromJson(map);
          if (item.orderId > 0 && !_completedOrderSnapshots.containsKey(item.orderId)) {
            _completedOrderSnapshots[item.orderId] = item.copyWith(status: 'DELIVERED');
            _completedOrderIds.add(item.orderId);
            hasChanged = true;
          }
        } catch (_) {}
      }
      final newEarnings = prefs.getDouble('ktx_extra_shipper_earnings') ?? 0.0;
      if (newEarnings != _extraShipperEarnings) {
        _extraShipperEarnings = newEarnings;
        hasChanged = true;
      }
    } catch (_) {}

    if (notify && hasChanged) {
      notifyListeners();
    }
    return hasChanged;
  }

  /// Lưu trữ
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = _completedOrderIds.map((id) => id.toString()).toList();
      await prefs.setStringList('ktx_completed_handover_orders', strList);
      final arrivedList = _arrivedOrderIds.map((id) => id.toString()).toList();
      await prefs.setStringList('ktx_arrived_orders', arrivedList);
      final poppedList = _poppedDialogOrderIds.map((id) => id.toString()).toList();
      await prefs.setStringList('ktx_popped_dialog_orders', poppedList);
      if (_lastArrivalTimestamp > 0) {
        await prefs.setInt('ktx_last_shipper_arrival_time', _lastArrivalTimestamp);
      }
      final snapList = _completedOrderSnapshots.values
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await prefs.setStringList('ktx_completed_order_snapshots', snapList);
      await prefs.setDouble('ktx_extra_shipper_earnings', _extraShipperEarnings);
    } catch (_) {}
  }

  void resetOrder(int orderId) {
    _studentConfirmations.remove(orderId);
    _shipperConfirmations.remove(orderId);
    _completedOrderIds.remove(orderId);
    _completedOrderSnapshots.remove(orderId);
    _arrivedOrderIds.remove(orderId);
    notifyListeners();
  }
}

