import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import '../services/notification_service.dart';
import '../services/store_service.dart';
import '../widgets/screen_state.dart';

/// ViewModel quản lý màn hình Trang chủ & Tìm kiếm quán ăn KTX (S1)
class HomeViewModel extends ChangeNotifier {
  final StoreService _storeService;
  final NotificationService _notificationService;

  ScreenState<List<StoreModel>> _storesState = const StateLoading();
  String _searchKeyword = '';
  String _selectedCampusZone = 'ALL';
  String _selectedPickupLocation = 'KTX Khu B – Trụ A1–A2 (Cổng B2)';
  int _unreadNotificationCount = 0;

  static const List<String> ktxPickupLocations = [
    'KTX Khu B – Trụ A1–A2 (Cổng B2)',
    'KTX Khu B – Nhà xe Tòa BA1',
    'KTX Khu A – Sảnh Tòa A3',
    'KTX Khu A – Cổng chính Đường Quảng Trường',
  ];

  HomeViewModel({
    required StoreService storeService,
    required NotificationService notificationService,
  })  : _storeService = storeService,
        _notificationService = notificationService;

  ScreenState<List<StoreModel>> get storesState => _storesState;
  String get searchKeyword => _searchKeyword;
  String get selectedCampusZone => _selectedCampusZone;
  String get selectedPickupLocation => _selectedPickupLocation;
  int get unreadNotificationCount => _unreadNotificationCount;

  /// Tải danh sách quán ăn và số lượng thông báo chưa đọc
  Future<void> loadHomeData() async {
    _storesState = const StateLoading();
    notifyListeners();

    try {
      final results = await Future.wait([
        _storeService.fetchStores(
          keyword: _searchKeyword,
          campusZone: _selectedCampusZone,
        ),
        _notificationService.fetchUnreadCount(),
      ]);

      final stores = results[0] as List<StoreModel>;
      _unreadNotificationCount = results[1] as int;

      if (stores.isEmpty) {
        _storesState = StateEmpty(
          message: _searchKeyword.isNotEmpty
              ? 'Không tìm thấy quán nào khớp với "$_searchKeyword".'
              : 'Chưa có quán ăn nào mở bán tại khu vực này.',
        );
      } else {
        _storesState = StateSuccess(stores);
      }
    } catch (e) {
      _storesState = StateError(
        'Không thể tải danh sách quán ăn: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  /// Tìm kiếm quán ăn theo từ khóa
  Future<void> searchStores(String keyword) async {
    _searchKeyword = keyword;
    await loadHomeData();
  }

  /// Lọc quán ăn theo phân khu KTX (ALL, KTX_KHU_A, KTX_KHU_B)
  Future<void> selectCampusZone(String zone) async {
    if (_selectedCampusZone == zone) return;
    _selectedCampusZone = zone;
    await loadHomeData();
  }

  /// Đổi điểm nhận hàng KTX trên Header
  void selectPickupLocation(String location) {
    _selectedPickupLocation = location;
    notifyListeners();
  }

  /// Làm mới số thông báo chưa đọc
  Future<void> refreshUnreadCount() async {
    _unreadNotificationCount = await _notificationService.fetchUnreadCount();
    notifyListeners();
  }
}
