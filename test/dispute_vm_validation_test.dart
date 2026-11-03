import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/order_model.dart';
import 'package:prm393_lab03_se192947/viewmodels/dispute_vm.dart';
import 'package:prm393_lab03_se192947/widgets/screen_state.dart';

void main() {
  group('DisputeViewModel Form & Validation Tests', () {
    late DisputeViewModel viewModel;

    setUp(() {
      viewModel = DisputeViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('Trạng thái khởi tạo của ViewModel là StateInitial', () {
      expect(viewModel.submitState, isA<StateInitial>());
      expect(viewModel.historyState, isA<StateInitial>());
      expect(viewModel.selectedImageBytes, isNull);
      expect(viewModel.uploadProgress, 0.0);
    });

    test('Từ chối gửi khiếu nại nếu chưa chọn đơn hàng', () async {
      final success = await viewModel.submitDispute(userId: 'test_uid_123');

      expect(success, isFalse);
      expect(viewModel.submitState, isA<StateError>());
      final error = viewModel.submitState as StateError;
      expect(error.errorMessage, contains('Vui lòng chọn đơn hàng'));
    });

    test('Từ chối gửi khiếu nại nếu chưa tải ảnh bằng chứng', () async {
      final mockOrder = OrderSummaryModel(
        id: 99,
        storeName: 'Quán cơm KTX',
        totalPrice: 40000,
        status: 'DELIVERED',
        pickupLocation: 'Trụ B2',
        createdAt: DateTime.now(),
      );

      viewModel.selectOrder(mockOrder);
      expect(viewModel.selectedOrder, mockOrder);
      expect(viewModel.refundAmountController.text, '40000');

      final success = await viewModel.submitDispute(userId: 'test_uid_123');

      expect(success, isFalse);
      expect(viewModel.submitState, isA<StateError>());
      final error = viewModel.submitState as StateError;
      expect(error.errorMessage, contains('Bắt buộc tải ảnh bằng chứng'));
    });

    test('Thay đổi lý do khiếu nại hoạt động chính xác', () {
      expect(viewModel.selectedReason, 'Món ăn có dị vật / Hỏng vị');
      viewModel.setReason('Giao thiếu món trong đơn');
      expect(viewModel.selectedReason, 'Giao thiếu món trong đơn');
    });
  });
}

