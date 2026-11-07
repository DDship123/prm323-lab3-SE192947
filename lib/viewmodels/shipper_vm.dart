import 'package:flutter/foundation.dart';
import '../models/shipper_batch_model.dart';
import '../models/shipper_wallet_model.dart';
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

  Future<bool> cancelPickup({
    required int orderId,
    required String shipperId,
    String? reason,
    String? idToken,
  }) async {
    final success = await _apiService.cancelPickupAtStore(
      orderId: orderId,
      shipperId: shipperId,
      reason: reason,
      idToken: idToken,
    );
    if (success) {
      await fetchBatch(shipperId: shipperId, idToken: idToken);
    }
    return success;
  }

  Future<bool> reportFailure({
    required int orderId,
    required String shipperId,
    String? reason,
    String? idToken,
  }) async {
    final success = await _apiService.reportDeliveryFailure(
      orderId: orderId,
      shipperId: shipperId,
      reason: reason,
      idToken: idToken,
    );
    if (success) {
      await fetchBatch(shipperId: shipperId, idToken: idToken);
    }
    return success;
  }

  Future<bool> confirmDelivery({
    required int orderId,
    required String shipperId,
    String? idToken,
  }) async {
    final success = await _apiService.confirmDeliveryAtGate(
      orderId: orderId,
      shipperId: shipperId,
      idToken: idToken,
    );
    await fetchBatch(shipperId: shipperId, idToken: idToken);
    return success;
  }

  ScreenState<ShipperWalletModel> _walletState = const StateInitial();
  ScreenState<ShipperWalletModel> get walletState => _walletState;

  Future<void> fetchWallet({
    required String shipperId,
    String? idToken,
  }) async {
    _walletState = const StateLoading();
    notifyListeners();

    try {
      final wallet = await _apiService.fetchWallet(
        idToken: idToken,
        shipperId: shipperId,
      );
      _walletState = StateSuccess(wallet);
    } catch (e) {
      _walletState = StateError('Lỗi tải ví thu nhập: $e');
    }
    notifyListeners();
  }

  Future<bool> withdrawEarnings({
    required double amount,
    required String bankName,
    required String bankAccountNumber,
    required String accountHolderName,
    required String shipperId,
    String? idToken,
  }) async {
    final success = await _apiService.withdrawEarnings(
      amount: amount,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      accountHolderName: accountHolderName,
      idToken: idToken,
      shipperId: shipperId,
    );
    if (success) {
      await fetchWallet(shipperId: shipperId, idToken: idToken);
    }
    return success;
  }
}