import 'package:flutter/foundation.dart';
import '../models/shipper_batch_model.dart';
import '../services/shipper_api_service.dart';
import '../widgets/screen_state.dart';

class ShipperViewModel extends ChangeNotifier {
  final ShipperApiService _apiService;

  ShipperViewModel({ShipperApiService? apiService})
      : _apiService = apiService ?? ShipperApiService();

  ScreenState<ShipperBatchModel> _state = const StateInitial();
  ScreenState<ShipperBatchModel> get state => _state;

  String _currentSlot = 'CA_TRUA_11H30';
  String get currentSlot => _currentSlot;

  Future<void> fetchBatch({
    required String shipperId,
    String? idToken,
    String? slotTime,
  }) async {
    if (slotTime != null) {
      _currentSlot = slotTime;
    }
    _state = const StateLoading();
    notifyListeners();

    try {
      final batch = await _apiService.fetchBatches(
        idToken: idToken,
        shipperId: shipperId,
        slotTime: _currentSlot,
      );
      _state = StateSuccess(batch);
    } catch (e) {
      _state = StateError('Lỗi tải chuyến gom: $e');
    }
    notifyListeners();
  }

  Future<bool> confirmPickup({
    required int orderId,
    required String shipperId,
    String? idToken,
  }) async {
    final success = await _apiService.confirmPickupAtStore(
      orderId: orderId,
      shipperId: shipperId,
      idToken: idToken,
    );
    if (success) {
      await fetchBatch(shipperId: shipperId, idToken: idToken);
    }
    return success;
  }
}