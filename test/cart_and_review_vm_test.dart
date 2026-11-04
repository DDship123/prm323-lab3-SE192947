import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/menu_item_model.dart';
import 'package:prm393_lab03_se192947/models/order_model.dart';
import 'package:prm393_lab03_se192947/services/auth_api_service.dart';
import 'package:prm393_lab03_se192947/services/order_service.dart';
import 'package:prm393_lab03_se192947/services/payment_service.dart';
import 'package:prm393_lab03_se192947/services/review_service.dart';
import 'package:prm393_lab03_se192947/viewmodels/auth_vm.dart';
import 'package:prm393_lab03_se192947/viewmodels/cart_checkout_vm.dart';
import 'package:prm393_lab03_se192947/viewmodels/review_vm.dart';

void main() {
  group('CartCheckoutViewModel & Business Rules BR-ORD Tests', () {
    late CartCheckoutViewModel cartVm;

    setUp(() {
      cartVm = CartCheckoutViewModel(
        orderService: OrderService(),
        paymentService: PaymentService(),
      );
    });

    test('BR-ORD-01: Từ chối đặt hàng khi giỏ hàng rỗng', () async {
      final result = await cartVm.placeOrder();
      expect(result, isNull);
      expect(cartVm.errorMessage, isNotNull);
    });

    test('BR-ORD-02 & BR-ORD-03: Tính đúng tổng tiền món kèm Topping và phí gom đơn 5.000đ', () {
      const item = MenuItemModel(
        id: 101,
        storeId: 1,
        name: 'Cơm Sườn Nướng',
        basePrice: 35000,
        category: 'COM',
      );

      cartVm.addItemToCart(
        storeId: 1,
        storeName: 'Cơm Tấm KTX B2',
        menuItem: item,
        quantity: 2,
        selectedOptions: const [
          SelectedItemOption(group: 'Kích cỡ', choice: 'Lớn', extraPrice: 5000),
          SelectedItemOption(
              group: 'Topping', choice: 'Trứng ốp la', extraPrice: 6000),
        ],
      );

      // (35000 + 5000 + 6000) * 2 = 92000
      expect(cartVm.subtotalAmount, 92000);
      expect(cartVm.deliveryFee, 5000);
      expect(cartVm.finalAmount, 97000);
    });
  });

  group('ReviewViewModel & AuthViewModel Validation Tests', () {
    test('BR-REV-02: Điểm đánh giá Quán và Shipper luôn nằm trong khoảng 1 đến 5 sao', () {
      final reviewVm = ReviewViewModel(reviewService: ReviewService());
      reviewVm.setStoreRating(10);
      reviewVm.setShipperRating(0);

      expect(reviewVm.storeRating, 5);
      expect(reviewVm.shipperRating, 1);
    });

    test('S0_OTP: Xác thực mã OTP bắt buộc đủ 6 chữ số', () {
      final authVm = AuthViewModel(authApiService: AuthApiService());
      expect(authVm.verifyOtp('123'), isFalse);
      expect(authVm.errorMessage, isNotNull);

      expect(authVm.verifyOtp('123456'), isTrue);
      expect(authVm.errorMessage, isNull);
    });
  });
}
