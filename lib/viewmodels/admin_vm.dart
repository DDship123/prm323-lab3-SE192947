import 'package:flutter/foundation.dart';
import '../models/dispute_model.dart';
import '../services/admin_api_service.dart';
import '../widgets/screen_state.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  AdminViewModel({AdminApiService? apiService})
      : _apiService = apiService ?? AdminApiService();

  ScreenState<List<DisputeModel>> _state = const StateInitial();
  ScreenState<List<DisputeModel>> get state => _state;

  Future<void> fetchAllDisputes({
    required String adminId,
    String? idToken,
  }) async {
    _state = const StateLoading();
    notifyListeners();

    try {
      final disputes = await _apiService.fetchAllDisputes(
        adminId: adminId,
        idToken: idToken,
      );
      if (disputes.isEmpty) {
        _state = const StateEmpty(message: 'Không có khiếu nại nào cần thẩm định.');
      } else {
        _state = StateSuccess(disputes);
      }
    } catch (e) {
      _state = StateError('Lỗi tải danh sách khiếu nại: $e');
    }
    notifyListeners();
  }

  Future<bool> resolveDispute({
    required int disputeId,
    required String status,
    required String resolutionNote,
    required double approvedAmount,
    required String adminId,
    String? idToken,
  }) async {
    final success = await _apiService.resolveDispute(
      disputeId: disputeId,
      status: status,
      resolutionNote: resolutionNote,
      approvedRefundAmount: approvedAmount,
      adminId: adminId,
      idToken: idToken,
    );
    if (success) {
      await fetchAllDisputes(adminId: adminId, idToken: idToken);
    }
    return success;
  }
}