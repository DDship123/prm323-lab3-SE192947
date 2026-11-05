import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

/// ViewModel quản lý Giỏ hàng Gom đơn KTX (S4) & Thanh toán VietQR / COD Fallback (S5)
class CartCheckoutViewModel extends ChangeNotifier {
  final OrderService _orderService;
  final PaymentService _paymentService;

  int? _storeId;
  String _storeName = '';
  final List<CartItemModel> _items = [];

  String _selectedSlotTime = 'CA_TRUA_11H30';
  String _selectedPickupLocation = 'KTX Khu B – Trụ A1–A2 (Cổng B2)';
  String _selectedPaymentMethod = 'VIETQR';
  String _note = '';

  bool _isSubmitting = false;
  String? _errorMessage;
  OrderDetailModel? _createdOrder;
  PaymentModel? _currentPayment;

  static const List<Map<String, String>> ktxShifts = [
    {
      'code': 'CA_TRUA_11H30',
      'label': 'Ca Trưa (Chốt 11:00 - Giao 11:30)',
    },
    {
      'code': 'CA_CHIEU_18H00',
      'label': 'Ca Chiều (Chốt 17:30 - Giao 18:00)',
    },
  ];

  static const List<String> ktxPickupLocations = [
    'KTX Khu B – Trụ A1–A2 (Cổng B2)',
    'KTX Khu B – Nhà xe Tòa BA1',
    'KTX Khu A – Sảnh Tòa A3',
    'KTX Khu A – Cổng chính Đường Quảng Trường',
  ];

  CartCheckoutViewModel({
    required OrderService orderService,
    required PaymentService paymentService,
  })  : _orderService = orderService,
        _paymentService = paymentService;

  int? get storeId => _storeId;
  String get storeName => _storeName;
  List<CartItemModel> get items => List.unmodifiable(_items);
  String get selectedSlotTime => _selectedSlotTime;
  String get selectedPickupLocation => _selectedPickupLocation;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get note => _note;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  OrderDetailModel? get createdOrder => _createdOrder;
  PaymentModel? get currentPayment => _currentPayment;

  int get totalItemCount =>
      _items.fold(0, (sum, element) => sum + element.quantity);

  double get subtotalAmount =>
      _items.fold(0.0, (sum, element) => sum + element.totalPrice);

  /// Phí giao hàng gom đơn KTX theo BR-ORD-03 (5.000đ khi đặt theo ca gom đơn)
  double _customDeliveryFee = 5000.0;

  /// Cập nhật phí giao hàng gom đơn từ Firebase Remote Config
  void updateDeliveryFee(double fee) {
    if (_customDeliveryFee != fee) {
      _customDeliveryFee = fee;
      notifyListeners();
    }
  }

  double get deliveryFee => _items.isEmpty ? 0.0 : _customDeliveryFee;

  double get finalAmount => subtotalAmount + deliveryFee;

  /// Thêm món ăn đã chọn Size/Topping vào giỏ hàng
  void addItemToCart({
    required int storeId,
    required String storeName,
    required MenuItemModel menuItem,
    required int quantity,
    required List<SelectedItemOption> selectedOptions,
  }) {
    // Nếu giỏ hàng đang chứa món của quán khác thì làm mới giỏ cho quán hiện tại
    if (_storeId != null && _storeId != storeId) {
      _items.clear();
    }
    _storeId = storeId;
    _storeName = storeName;

    _items.add(
      CartItemModel(
        menuItemId: menuItem.id,
        itemName: menuItem.name,
        imageUrl: menuItem.imageUrl,
        basePrice: menuItem.basePrice,
        quantity: quantity,
        selectedOptions: selectedOptions,
      ),
    );
    _errorMessage = null;
    notifyListeners();
  }

  void updateQuantity(int index, int delta) {
    if (index < 0 || index >= _items.length) return;
    final newQty = _items[index].quantity + delta;
    if (newQty <= 0) {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _storeId = null;
        _storeName = '';
      }
    } else {
      _items[index].quantity = newQty;
    }
    notifyListeners();
  }

  void setSlotTime(String slotTime) {
    _selectedSlotTime = slotTime;
    notifyListeners();
  }

  void setPickupLocation(String location) {
    _selectedPickupLocation = location;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setNote(String value) {
    _note = value;
  }

  void clearCart() {
    _items.clear();
    _storeId = null;
    _storeName = '';
    _note = '';
    notifyListeners();
  }

  /// API-006: Đặt đơn hàng gom đơn KTX (S4)
  Future<OrderDetailModel?> placeOrder() async {
    if (_items.isEmpty || _storeId == null) {
      _errorMessage = 'Giỏ hàng đang trống. Vui lòng chọn ít nhất 1 món ăn.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        storeId: _storeId!,
        storeName: _storeName,
        slotTime: _selectedSlotTime,
        pickupLocation: _selectedPickupLocation,
        paymentMethod: _selectedPaymentMethod,
        note: _note,
        items: _items,
      );
      _createdOrder = order;

      if (_selectedPaymentMethod == 'VIETQR') {
        _currentPayment = await _paymentService.generateVietQr(
          orderId: order.id,
          fallbackAmount: order.finalAmount,
          fallbackOrderCode: order.orderCode,
        );
      }

      clearCart();
      return order;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// API-012: Nạp hoặc sinh lại mã VietQR cho một đơn hàng
  Future<void> loadVietQrForOrder(OrderDetailModel order) async {
    _createdOrder = order;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPayment = await _paymentService.generateVietQr(
        orderId: order.id,
        fallbackAmount: order.finalAmount,
        fallbackOrderCode: order.orderCode,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// API-013: Chuyển đổi dự phòng sang Tiền mặt (COD Fallback tại S5)
  Future<bool> switchOrderToCod(int orderId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPayment = await _paymentService.switchToCod(orderId);
      _selectedPaymentMethod = 'COD';
      return true;
    } catch (_) {
      // Nếu chạy ở chế độ offline demo thì vẫn cho phép fallback sang COD
      _selectedPaymentMethod = 'COD';
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Xác nhận đã chuyển khoản VietQR thành công tại S5
  Future<bool> confirmVietQrPaid(int orderId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPayment = await _paymentService.confirmPaymentSuccess(orderId);
      return true;
    } catch (_) {
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
