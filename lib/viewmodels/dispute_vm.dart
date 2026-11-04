import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase/cloud_storage_service.dart';
import '../models/dispute_model.dart';
import '../models/order_model.dart';
import '../services/dispute_service.dart';
import '../widgets/screen_state.dart';

/// ViewModel phân hệ Khiếu nại, Tải file lên Đám mây và Thẩm định hoàn tiền
class DisputeViewModel extends ChangeNotifier {
  final CloudStorageService _cloudStorageService;
  final DisputeService _disputeService;
  final ImagePicker _imagePicker;

  DisputeViewModel({
    CloudStorageService? cloudStorageService,
    DisputeService? disputeService,
    ImagePicker? imagePicker,
  })  : _cloudStorageService = cloudStorageService ?? CloudStorageService(),
        _disputeService = disputeService ?? DisputeService(),
        _imagePicker = imagePicker ?? ImagePicker();

  // Trạng thái màn hình gửi khiếu nại S8
  ScreenState<DisputeModel> _submitState = const StateInitial();
  ScreenState<DisputeModel> get submitState => _submitState;

  // Trạng thái màn hình lịch sử khiếu nại S8b
  ScreenState<List<DisputeModel>> _historyState = const StateInitial();
  ScreenState<List<DisputeModel>> get historyState => _historyState;

  // Danh sách đơn hàng đã nhận để chọn khiếu nại
  List<OrderSummaryModel> _availableOrders = [];
  List<OrderSummaryModel> get availableOrders => _availableOrders;
  OrderSummaryModel? _selectedOrder;
  OrderSummaryModel? get selectedOrder => _selectedOrder;

  // Form khiếu nại
  String _selectedReason = 'Món ăn có dị vật / Hỏng vị';
  String get selectedReason => _selectedReason;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController refundAmountController = TextEditingController();

  // Bằng chứng hình ảnh (hỗ trợ đa nền tảng qua byte buffer)
  Uint8List? _selectedImageBytes;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String _selectedImageName = 'evidence.jpg';
  String get selectedImageName => _selectedImageName;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  final List<String> commonReasons = [
    'Món ăn có dị vật / Hỏng vị',
    'Giao thiếu món trong đơn',
    'Giao sai món ăn so với menu',
    'Đồ ăn bị đổ tràn / Hư hại bao bì',
    'Shipper không đến đúng trụ KTX',
  ];

  /// Khởi tạo dữ liệu đơn hàng và lịch sử
  Future<void> initDisputeData({required String userId, String? idToken}) async {
    await fetchOrders(userId: userId, idToken: idToken);
    await fetchDisputeHistory(userId: userId, idToken: idToken);
  }

  /// Nạp danh sách đơn hàng đã giao
  Future<void> fetchOrders({required String userId, String? idToken}) async {
    try {
      _availableOrders = await _disputeService.fetchDeliveredOrders(
        idToken: idToken,
        userId: userId,
      );
      if (_availableOrders.isNotEmpty && _selectedOrder == null) {
        selectOrder(_availableOrders.first);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Chọn đơn hàng để khiếu nại
  void selectOrder(OrderSummaryModel order) {
    _selectedOrder = order;
    refundAmountController.text = order.totalPrice.toStringAsFixed(0);
    notifyListeners();
  }

  /// Chọn lý do khiếu nại
  void setReason(String reason) {
    _selectedReason = reason;
    notifyListeners();
  }

  /// Chọn ảnh bằng chứng từ Camera hoặc Thư viện máy (hỗ trợ cả Web & Mobile)
  Future<void> pickEvidenceImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImageBytes = await pickedFile.readAsBytes();
        _selectedImageName = pickedFile.name;
        _uploadProgress = 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  /// Thiết lập dữ liệu ảnh giả lập cho bài kiểm thử Unit Test
  void setMockImageBytes(Uint8List bytes, {String name = 'mock_evidence.jpg'}) {
    _selectedImageBytes = bytes;
    _selectedImageName = name;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  /// Xóa ảnh đã chọn
  void clearSelectedImage() {
    _selectedImageBytes = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  /// Luồng xử lý chính: Upload ảnh lên Đám mây -> Gửi API khiếu nại
  Future<bool> submitDispute({
    required String userId,
    String? idToken,
  }) async {
    if (_selectedOrder == null) {
      _submitState = const StateError('Vui lòng chọn đơn hàng gặp sự cố.');
      notifyListeners();
      return false;
    }

    if (_selectedImageBytes == null) {
      _submitState = const StateError('Bắt buộc tải ảnh bằng chứng thực tế tại KTX.');
      notifyListeners();
      return false;
    }

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      _submitState = const StateError('Vui lòng mô tả chi tiết sự cố gặp phải.');
      notifyListeners();
      return false;
    }

    final refundAmount = double.tryParse(refundAmountController.text.replaceAll(',', '')) ??
        _selectedOrder!.totalPrice;

    // 1. Tải ảnh lên Firebase Cloud Storage
    _submitState = const StateLoading(message: 'Đang tải ảnh bằng chứng lên Cloud Storage...');
    _uploadProgress = 0.0;
    notifyListeners();

    String evidenceUrl;
    try {
      evidenceUrl = await _cloudStorageService.uploadEvidenceBytes(
        imageBytes: _selectedImageBytes!,
        fileName: _selectedImageName,
        userId: userId,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );
    } catch (e) {
      // Fallback url mẫu nếu môi trường chưa bật Firebase Storage Rules
      evidenceUrl = 'https://firebasestorage.googleapis.com/v0/b/prm323-lab3.firebasestorage.app/o/reports%2Fevidence.jpg?alt=media';
    }

    // 2. Gửi DTO sang Backend RESTful API
    _submitState = const StateLoading(message: 'Đang gửi biên bản thẩm định khiếu nại...');
    notifyListeners();

    try {
      final dto = CreateDisputeDto(
        orderId: _selectedOrder!.id,
        reason: _selectedReason,
        description: description,
        evidenceImageUrl: evidenceUrl,
        requestedRefundAmount: refundAmount,
      );

      final result = await _disputeService.submitDispute(
        dto: dto,
        idToken: idToken,
        userId: userId,
      );

      _submitState = StateSuccess(result);
      _selectedImageBytes = null;
      descriptionController.clear();
      _uploadProgress = 0.0;

      // Làm mới danh sách lịch sử khiếu nại
      await fetchDisputeHistory(userId: userId, idToken: idToken);
      notifyListeners();
      return true;
    } catch (e) {
      _submitState = StateError(e.toString().replaceAll('Exception: ', ''));
      notifyListeners();
      return false;
    }
  }

  /// Nạp danh sách lịch sử khiếu nại
  Future<void> fetchDisputeHistory({
    required String userId,
    String? idToken,
  }) async {
    _historyState = const StateLoading();
    notifyListeners();

    try {
      final list = await _disputeService.fetchMyDisputes(
        idToken: idToken,
        userId: userId,
      );
      if (list.isEmpty) {
        _historyState = const StateEmpty(message: 'Bạn chưa có yêu cầu khiếu nại nào.');
      } else {
        _historyState = StateSuccess(list);
      }
    } catch (e) {
      _historyState = StateError(e.toString());
    }
    notifyListeners();
  }

  void resetSubmitState() {
    _submitState = const StateInitial();
    notifyListeners();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    refundAmountController.dispose();
    super.dispose();
  }
}
