import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// ViewModel quản lý Đánh giá Quán ăn & Shipper sau khi nhận hàng (S9 - BR-REV-01, BR-REV-02)
class ReviewViewModel extends ChangeNotifier {
  final ReviewService _reviewService;

  int _storeRating = 5;
  int _shipperRating = 5;
  String _comment = '';
  String _shipperComment = '';
  final List<String> _images = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  ReviewModel? _submittedReview;

  List<ReviewModel> _storeReviews = [];
  List<ReviewModel> _shipperReviews = [];
  bool _isLoadingReviews = false;

  ReviewViewModel({required ReviewService reviewService})
      : _reviewService = reviewService;

  int get storeRating => _storeRating;
  int get shipperRating => _shipperRating;
  String get comment => _comment;
  String get shipperComment => _shipperComment;
  List<String> get images => List.unmodifiable(_images);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  ReviewModel? get submittedReview => _submittedReview;

  List<ReviewModel> get storeReviews => _storeReviews;
  List<ReviewModel> get shipperReviews => _shipperReviews;
  bool get isLoadingReviews => _isLoadingReviews;

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
    notifyListeners();
  }

  void setShipperComment(String value) {
    _shipperComment = value;
    notifyListeners();
  }

  bool addImage(String path) {
    if (_images.length < 3) {
      _images.add(path);
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  void clearImages() {
    _images.clear();
    notifyListeners();
  }

  void resetForm() {
    _storeRating = 5;
    _shipperRating = 5;
    _comment = '';
    _shipperComment = '';
    _images.clear();
    _errorMessage = null;
    _submittedReview = null;
    notifyListeners();
  }

  /// API-017: Gửi đánh giá quán & shipper
  /// Hỗ trợ cả cmt không ảnh, hoặc ảnh không cmt (không ràng buộc)
  Future<bool> submitOrderReview(
    int orderId, {
    String storeName = 'Cơm Tấm Cô Ba - KTX Khu B',
    String shipperName = 'Nguyễn Hùng (Shipper Đội Gom KTX)',
    String userDisplayName = 'Ngô Trường Đạt (Sinh viên)',
    String? userAvatarUrl,
    int storeId = 1,
    int shipperId = 3,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _submittedReview = await _reviewService.submitReview(
        orderId: orderId,
        storeRating: _storeRating,
        shipperRating: _shipperRating,
        comment: _comment.trim().isNotEmpty ? _comment.trim() : null,
        shipperComment: _shipperComment.trim().isNotEmpty ? _shipperComment.trim() : null,
        images: _images,
        storeName: storeName,
        shipperName: shipperName,
        userDisplayName: userDisplayName,
        userAvatarUrl: userAvatarUrl,
        storeId: storeId,
        shipperId: shipperId,
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

  Future<void> loadStoreReviews(int storeId) async {
    _isLoadingReviews = true;
    notifyListeners();
    try {
      _storeReviews = await _reviewService.fetchStoreReviews(storeId);
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<void> loadShipperReviews(int shipperId) async {
    _isLoadingReviews = true;
    notifyListeners();
    try {
      _shipperReviews = await _reviewService.fetchShipperReviews(shipperId);
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }
}
