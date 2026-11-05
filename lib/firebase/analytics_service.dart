import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // 1. Sự kiện sign-in (login)
  Future<void> logSignIn({
    required String method,
    String campusZone = 'KTX_KHU_B',
  }) async {
    await _analytics.logLogin(loginMethod: method);
    await _analytics.logEvent(
      name: 'login_ktx',
      parameters: {'method': method, 'campus_zone': campusZone},
    );
  }

  // 2. Sự kiện sign-out
  Future<void> logSignOut({String sessionType = 'authenticated'}) async {
    await _analytics.logEvent(
      name: 'sign_out',
      parameters: {'session_type': sessionType},
    );
  }

  // 3. Sự kiện search
  Future<void> logSearch({
    required String searchTerm,
    required String campusZone,
    required int resultCount,
  }) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        'campus_zone': campusZone,
        'result_count': resultCount,
      },
    );
  }

  // 4. Sự kiện xem chi tiết quán (view_store_detail)
  Future<void> logViewStoreDetail({
    required int storeId,
    required String storeCategory,
    required double ratingAvg,
  }) async {
    await _analytics.logEvent(
      name: 'view_store_detail',
      parameters: {
        'store_id': storeId,
        'store_category': storeCategory,
        'rating_avg': ratingAvg,
      },
    );
  }

  // 5. Sự kiện thêm món vào giỏ (add_to_cart)
  Future<void> logAddToCart({
    required int menuItemId,
    required int storeId,
    required int quantity,
    required double unitPrice,
  }) async {
    await _analytics.logEvent(
      name: 'add_to_cart',
      parameters: {
        'menu_item_id': menuItemId,
        'store_id': storeId,
        'quantity': quantity,
        'unit_price': unitPrice,
      },
    );
  }

  // 6. Sự kiện bắt đầu thanh toán (begin_checkout)
  Future<void> logBeginCheckout({
    required int itemCount,
    required double subtotalAmount,
    required double shippingFee,
  }) async {
    await _analytics.logEvent(
      name: 'begin_checkout',
      parameters: {
        'item_count': itemCount,
        'subtotal_amount': subtotalAmount,
        'shipping_fee': shippingFee,
      },
    );
  }

  // 7. Sự kiện đặt đơn thành công (purchase)
  Future<void> logPurchase({
    required String orderId,
    required double totalValue,
    required String paymentMethod,
  }) async {
    await _analytics.logEvent(
      name: 'purchase',
      parameters: {
        'order_id': orderId,
        'value': totalValue,
        'currency': 'VND',
        'payment_method': paymentMethod,
      },
    );
  }

  // 8. Sự kiện upload ảnh bằng chứng khiếu nại (upload_dispute_evidence)
  Future<void> logUploadDisputeEvidence({
    required String orderId,
    required String reasonCode,
    required double refundRequested,
    required String uploadStatus,
  }) async {
    await _analytics.logEvent(
      name: 'upload_dispute_evidence',
      parameters: {
        'order_id': orderId,
        'reason_code': reasonCode,
        'refund_requested': refundRequested,
        'upload_status': uploadStatus,
      },
    );
  }
}
