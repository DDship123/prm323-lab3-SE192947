import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// ViewModel quản lý Đánh giá Quán ăn & Shipper sau khi nhận hàng (S9 - BR-REV-01, BR-REV-02)
class ReviewViewModel extends ChangeNotifier {
  final ReviewService _reviewService;

  int _storeRating = 5;
  int _shipperRating = 5;
  String _comment = '';
  bool _isSubmitting = false;
  String? _errorMessage;
  ReviewModel? _submittedReview;

  ReviewViewModel({required ReviewService reviewService})
      : _reviewService = reviewService;

  int get storeRating => _storeRating;
  int get shipperRating => _shipperRating;
  String get comment => _comment;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  ReviewModel? get submittedReview => _submittedReview;

  void setStoreRating(int rating) {
    _storeRating = rating.clamp(1, 5);
    notifyListeners();
  }

  void setShipperRating(int rating) {
    _shipperRating = rating.clamp(1, 5);
    notifyListeners();
  }

  void setComment(String value) {
    _comment = value;
  }

  void resetForm() {
    _storeRating = 5;
    _shipperRating = 5;
    _comment = '';
    _errorMessage = null;
    _submittedReview = null;
  }

  /// API-017: Gửi đánh giá quán & shipper
  Future<bool> submitOrderReview(int orderId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _submittedReview = await _reviewService.submitReview(
        orderId: orderId,
        storeRating: _storeRating,
        shipperRating: _shipperRating,
        comment: _comment.isEmpty
            ? 'Đồ ăn nóng hổi, shipper giao đúng giờ tại trụ KTX!'
            : _comment,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
