import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService extends ChangeNotifier {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Cho phép fetch liên tục không bị throttle trong quá trình dev/demo chấm bài
          minimumFetchInterval: Duration.zero,
        ),
      );

      // 1. Giá trị mặc định in-app khi chưa có mạng hoặc chưa publish từ Firebase Console
      await _remoteConfig.setDefaults(const {
        'ktx_promo_banner_enabled': true,
        'ktx_promo_banner_text':
            'Đồng giá ship 5.000đ giao thẳng tới Trụ A1–A2 (Cổng B2) & Khu A.',
        'ktx_group_ship_fee': 5000,
      });

      await fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfig initialize error: $e');
    }
  }

  /// Lấy cấu hình mới nhất từ Firebase Console và kích hoạt
  Future<bool> fetchAndActivate() async {
    if (kIsWeb) return false;
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      notifyListeners();
      return updated;
    } catch (e) {
      debugPrint('RemoteConfig fetchAndActivate error: $e');
      return false;
    }
  }

  /// Tham số 1: Ẩn/Hiện banner khuyến mãi trên Trang chủ S1
  bool get promoBannerEnabled {
    if (kIsWeb) return true;
    return _remoteConfig.getBool('ktx_promo_banner_enabled');
  }

  /// Tham số 2: Nội dung chữ trên banner khuyến mãi
  String get promoBannerText {
    if (kIsWeb) {
      return 'Đồng giá ship 5.000đ giao thẳng tới Trụ A1–A2 (Cổng B2) & Khu A.';
    }
    final text = _remoteConfig.getString('ktx_promo_banner_text');
    return text.isNotEmpty
        ? text
        : 'Đồng giá ship 5.000đ giao thẳng tới Trụ A1–A2 (Cổng B2) & Khu A.';
  }

  /// Tham số 3: Mức phí ship gom đơn (được dùng để tính tổng tiền đơn hàng)
  int get groupShipFee {
    if (kIsWeb) return 5000;
    final fee = _remoteConfig.getInt('ktx_group_ship_fee');
    return fee > 0 ? fee : 5000;
  }
}
