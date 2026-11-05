import 'package:flutter/foundation.dart';
import '../models/owner_order_model.dart';
import '../models/store_revenue_model.dart';
import '../services/owner_api_service.dart';
import '../widgets/screen_state.dart';

class OwnerViewModel extends ChangeNotifier {
  final OwnerApiService _apiService;

  OwnerViewModel({OwnerApiService? apiService})
      : _apiService = apiService ?? OwnerApiService();

  ScreenState<List<OwnerOrderSummaryModel>> _state = const StateInitial();
  ScreenState<List<OwnerOrderSummaryModel>> get state => _state;

  String _currentSlot = 'CA_TRUA_11H30';
  String get currentSlot => _currentSlot;

  Future<void> fetchKitchenOrders({
    required String ownerId,
    String? idToken,
    String? slotTime,
  }) async {
    if (slotTime != null) {
      _currentSlot = slotTime;
    }
    _state = const StateLoading();
    notifyListeners();

    try {
      final orders = await _apiService.fetchKitchenOrders(
        idToken: idToken,
        ownerId: ownerId,
        slotTime: _currentSlot,
      );
      if (orders.isEmpty) {
        _state = const StateEmpty(message: 'Không có đơn gom nào cho ca này.');
      } else {
        _state = StateSuccess(orders);
      }
    } catch (e) {
      _state = StateError('Lỗi tải đơn bếp: $e');
    }
    notifyListeners();
  }

  Future<void> toggleAvailability({
    required int menuItemId,
    required bool isAvailable,
    required String ownerId,
    String? idToken,
  }) async {
    await _apiService.updateItemAvailability(
      menuItemId: menuItemId,
      isAvailable: isAvailable,
      idToken: idToken,
      ownerId: ownerId,
    );
    notifyListeners();
  }

  ScreenState<StoreRevenueModel> _revenueState = const StateInitial();
  ScreenState<StoreRevenueModel> get revenueState => _revenueState;

  Future<void> fetchRevenueReport({
    required String ownerId,
    String? idToken,
    String? slotTime,
  }) async {
    _revenueState = const StateLoading();
    notifyListeners();
    try {
      final report = await _apiService.fetchRevenueReport(
        idToken: idToken,
        ownerId: ownerId,
        slotTime: slotTime ?? _currentSlot,
      );
      _revenueState = StateSuccess(report);
    } catch (e) {
      _revenueState = StateError('Lỗi tải báo cáo doanh thu: $e');
    }
    notifyListeners();
  }
}