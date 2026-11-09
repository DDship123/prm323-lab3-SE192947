import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  FirebaseAnalytics? _analyticsInstance;
  bool _initAttempted = false;

  FirebaseAnalytics? get _safeAnalytics {
    if (_initAttempted) return _analyticsInstance;
    _initAttempted = true;
    try {
      _analyticsInstance = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('FirebaseAnalytics not available: $e');
    }
    return _analyticsInstance;
  }

  // 1. Sự kiện sign-in (login)
  Future<void> logSignIn({
    required String method,
    String campusZone = 'KTX_KHU_B',
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logLogin(loginMethod: method);
      await client.logEvent(
        name: 'login_ktx',
        parameters: {'method': method, 'campus_zone': campusZone},
      );
    } catch (_) {}
  }

  // 2. Sự kiện sign-out
  Future<void> logSignOut({String sessionType = 'authenticated'}) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'sign_out',
        parameters: {'session_type': sessionType},
      );
    } catch (_) {}
  }

  // 3. Sự kiện search
  Future<void> logSearch({
    required String searchTerm,
    required String campusZone,
    required int resultCount,
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'search',
        parameters: {
          'search_term': searchTerm,
          'campus_zone': campusZone,
          'result_count': resultCount,
        },
      );
    } catch (_) {}
  }

  // 4. Sự kiện xem chi tiết quán (view_store_detail)
  Future<void> logViewStoreDetail({
    required int storeId,
    required String storeCategory,
    required double ratingAvg,
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'view_store_detail',
        parameters: {
          'store_id': storeId,
          'store_category': storeCategory,
          'rating_avg': ratingAvg,
        },
      );
    } catch (_) {}
  }

  // 5. Sự kiện thêm món vào giỏ (add_to_cart)
  Future<void> logAddToCart({
    required int menuItemId,
    required int storeId,
    required int quantity,
    required double unitPrice,
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'add_to_cart',
        parameters: {
          'menu_item_id': menuItemId,
          'store_id': storeId,
          'quantity': quantity,
          'unit_price': unitPrice,
        },
      );
    } catch (_) {}
  }

  // 6. Sự kiện bắt đầu thanh toán (begin_checkout)
  Future<void> logBeginCheckout({
    required int itemCount,
    required double subtotalAmount,
    required double shippingFee,
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'begin_checkout',
        parameters: {
          'item_count': itemCount,
          'subtotal_amount': subtotalAmount,
          'shipping_fee': shippingFee,
        },
      );
    } catch (_) {}
  }

  // 7. Sự kiện đặt đơn thành công (purchase)
  Future<void> logPurchase({
    required String orderId,
    required double totalValue,
    required String paymentMethod,
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'purchase',
        parameters: {
          'order_id': orderId,
          'value': totalValue,
          'currency': 'VND',
          'payment_method': paymentMethod,
        },
      );
    } catch (_) {}
  }

  // 8. Sự kiện upload ảnh bằng chứng khiếu nại (upload_dispute_evidence)
  Future<void> logUploadDisputeEvidence({
    required String orderId,
    required String reasonCode,
    required double refundRequested,
    required String uploadStatus,
  }) async {
    try {
      final client = _safeAnalytics;
      if (client == null) return;
      await client.logEvent(
        name: 'upload_dispute_evidence',
        parameters: {
          'order_id': orderId,
          'reason_code': reasonCode,
          'refund_requested': refundRequested,
          'upload_status': uploadStatus,
        },
      );
    } catch (_) {}
  }
}
