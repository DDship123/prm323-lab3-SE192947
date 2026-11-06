import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';
import '../models/review_model.dart';
import '../models/store_model.dart';
import '../services/review_service.dart';
import '../services/store_service.dart';
import '../widgets/screen_state.dart';

/// ViewModel quản lý Chi tiết Quán ăn & Thực đơn tùy biến (S2, S3)
class StoreDetailViewModel extends ChangeNotifier {
  final StoreService _storeService;
  final ReviewService _reviewService;

  StoreModel? _store;
  ScreenState<List<MenuItemModel>> _menuState = const StateLoading();
  List<ReviewModel> _reviews = [];
  String _selectedCategory = 'ALL';

  StoreDetailViewModel({
    required StoreService storeService,
    required ReviewService reviewService,
  })  : _storeService = storeService,
        _reviewService = reviewService;

  StoreModel? get store => _store;
  ScreenState<List<MenuItemModel>> get menuState => _menuState;
  List<ReviewModel> get reviews => _reviews;
  String get selectedCategory => _selectedCategory;

  /// Tải thông tin quán, thực đơn và danh sách đánh giá (API-004, API-005, API-018)
  Future<void> loadStoreDetail(StoreModel initialStore) async {
    _store = initialStore;
    _selectedCategory = 'ALL';
    _menuState = const StateLoading();
    notifyListeners();

    try {
      final results = await Future.wait([
        _storeService.fetchStoreById(initialStore.id),
        _storeService.fetchMenuItems(initialStore.id),
        _reviewService.fetchStoreReviews(initialStore.id),
      ]);

      _store = results[0] as StoreModel;
      final items = results[1] as List<MenuItemModel>;
      _reviews = results[2] as List<ReviewModel>;

      if (items.isEmpty) {
        _menuState = const StateEmpty(
          message: 'Quán hiện chưa cập nhật thực đơn.',
        );
      } else {
        _menuState = StateSuccess(items);
      }
    } catch (e) {
      _menuState = StateError(
        'Không thể tải thực đơn quán: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  /// Lọc món ăn theo danh mục (ALL, COM, BUN_PHO, NUOC, AN_VAT)
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<MenuItemModel> get filteredMenuItems {
    final current = _menuState;
    if (current is! StateSuccess<List<MenuItemModel>>) return const [];
    if (_selectedCategory == 'ALL') return current.data;
    if (_selectedCategory == 'BEST_SELLER') {
      return current.data
          .where((item) => item.promoBadge != null || item.id == 1)
          .toList();
    }
    return current.data
        .where((item) => item.category == _selectedCategory)
        .toList();
  }
}
