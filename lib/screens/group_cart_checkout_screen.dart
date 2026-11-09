import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/order_model.dart';
import '../models/voucher_model.dart';
import '../services/commission_policy_service.dart';
import '../services/voucher_service.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../widgets/ktx_dialog.dart';
import '../services/commission_policy_service.dart';
import '../services/order_service.dart';
import 'online_payment_screen.dart';
import 'pickup_qr_code_screen.dart';

/// Màn hình S4: Thanh Toán Gom Đơn chuẩn 100% Figma
class GroupCartCheckoutScreen extends StatefulWidget {
  final ValueChanged<OrderDetailModel> onOrderCompleted;
  final VoidCallback? onBackToMenu;

  const GroupCartCheckoutScreen({
    super.key,
    required this.onOrderCompleted,
    this.onBackToMenu,
  });

  @override
  State<GroupCartCheckoutScreen> createState() =>
      _GroupCartCheckoutScreenState();
}

class _GroupCartCheckoutScreenState extends State<GroupCartCheckoutScreen> {
  final _noteCtrl = TextEditingController();

  int _selectedLocationIndex = 0;
  int _selectedShiftIndex = 0; // 0: Ca Trưa, 1: Ca Tối
  String _deliveryMode = 'GROUP'; // 'GROUP' (5.000đ) hoặc 'EXPRESS' (15.000đ)
  String _paymentMethod = 'VIETQR';
  VoucherModel? _appliedFoodVoucher; // Tối đa 1 voucher giảm tiền món từ Quán
  VoucherModel? _appliedShippingVoucher; // Tối đa 1 voucher giảm phí ship KTX
  bool _voucherInitialized = false;

  final List<Map<String, dynamic>> _pickupPoints = [
    {
      'title': 'Cổng KTX Khu B (Trụ A1–A2)',
      'badge': 'Khu B',
      'desc':
          'Shipper đậu ô tô tải ngay cổng chính KTX Khu B, sinh viên kiểm tra tên tại bàn trực',
      'highlight': '✓ Đã có 28 bạn cùng tòa đặt đợt này',
    },
    {
      'title': 'Cổng KTX Khu A (Cổng Parabol)',
      'badge': 'Khu A',
      'desc': 'Bàn giao tại cổng chính đường Lương Định Của',
      'highlight': null,
    },
    {
      'title': 'Cổng Viện Môi trường Làng ĐH',
      'badge': 'Cụm ĐH',
      'desc': 'Điểm hẹn vỉa hè trước cổng viện, thuận tiện cho SV KTX A',
      'highlight': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final remoteFee =
          context.read<RemoteConfigService>().groupShipFee.toDouble();
      context.read<CartCheckoutViewModel>().updateDeliveryFee(remoteFee);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_voucherInitialized) {
      final v = context.read<VoucherService>().findByCode('SINHVIENKTX');
      if (v != null && v.isValidForStudent) {
        _appliedShippingVoucher = v;
      }
      _voucherInitialized = true;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  Future<void> _handlePlaceOrder(
    CartCheckoutViewModel cartVm, {
    double foodDiscount = 0.0,
    double shippingDiscount = 0.0,
    double totalPayment = 0.0,
  }) async {
    if (cartVm.items.isEmpty || cartVm.storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đang trống! Vui lòng chọn món ăn từ thực đơn trước khi đặt đơn.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final double totalDiscount = foodDiscount + shippingDiscount;
    final List<String> codes = [];
    if (_appliedFoodVoucher != null) codes.add(_appliedFoodVoucher!.code);
    if (_appliedShippingVoucher != null) codes.add(_appliedShippingVoucher!.code);
    final String? combinedVoucherCode = codes.isNotEmpty ? codes.join(',') : null;

    try {
      context.read<AnalyticsService>().logBeginCheckout(
            itemCount: cartVm.totalItemCount,
            subtotalAmount: cartVm.subtotalAmount,
            shippingFee: cartVm.deliveryFee,
          );
    } catch (_) {}

    cartVm.setNote(_noteCtrl.text);
    cartVm.setPaymentMethod(_paymentMethod);
    cartVm.setPickupLocation(_pickupPoints[_selectedLocationIndex]['title'] as String);
    cartVm.setSlotTime(_deliveryMode == 'EXPRESS'
        ? 'GIAO_HOA_TOC_NGAY'
        : (_selectedShiftIndex == 0 ? 'CA_TRUA_11H30' : 'CA_CHIEU_18H00'));

    final created = await cartVm.placeOrder(
      voucherCode: combinedVoucherCode,
      discountAmount: totalDiscount,
    );

    if (!mounted || created == null) {
      if (mounted && cartVm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cartVm.errorMessage!), backgroundColor: const Color(0xFFDC2626)),
        );
      }
      return;
    }

    // Ghi nhận số lượt dùng voucher vào hệ thống
    final voucherService = context.read<VoucherService>();
    if (_appliedFoodVoucher != null) {
      await voucherService.recordVoucherUsage(_appliedFoodVoucher!.code);
    }
    if (_appliedShippingVoucher != null) {
      await voucherService.recordVoucherUsage(_appliedShippingVoucher!.code);
    }

    if (!mounted || created == null) return;

    if (_paymentMethod == 'VIETQR') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OnlinePaymentScreen(
            order: created!,
            onPaymentDone: (ord) {
              Navigator.of(context).pop();
              widget.onOrderCompleted(ord);
            },
          ),
        ),
      );
    } else {
      await KtxDialog.showOrderSuccess(
        context,
        orderCode: created.orderCode,
        onTrackOrder: () {
          Navigator.of(context).pop();
          widget.onOrderCompleted(created!);
        },
        onSkipToPickup: () async {
          Navigator.of(context).pop();
          try {
            await OrderService().updateOrderStatus(
              orderId: created!.id,
              newStatus: 'DELIVERING',
            );
          } catch (_) {}
          final delivering = created!.copyWith(status: 'DELIVERING');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PickupQrCodeScreen(order: delivering)),
            );
          }
        },
      );
    }
  }

  void _showEditNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lời nhắn cho Quán ăn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú cho quán (ví dụ: Ít cơm, nhiều đồ chua...)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF521B)),
            onPressed: () {
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Lưu ghi chú', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartCheckoutViewModel>();
    final voucherService = context.watch<VoucherService>();

    // Đồng bộ trạng thái Voucher từ VoucherService (ngắt nếu bị tắt hoặc hết lượt)
    if (_appliedFoodVoucher != null) {
      final latest = voucherService.findByCode(_appliedFoodVoucher!.code);
      if (latest == null || !latest.isValidForStudent) {
        _appliedFoodVoucher = null;
      } else {
        _appliedFoodVoucher = latest;
      }
    }
    if (_appliedShippingVoucher != null) {
      final latest = voucherService.findByCode(_appliedShippingVoucher!.code);
      if (latest == null || !latest.isValidForStudent) {
        _appliedShippingVoucher = null;
      } else {
        _appliedShippingVoucher = latest;
      }
    }

    final double itemsSubtotal = cartVm.subtotalAmount;
    final double shipFee = _deliveryMode == 'EXPRESS' ? 15000.0 : 5000.0;

    // Giảm giá tiền món (tối đa 1 voucher loại order)
    final double foodDiscount = _appliedFoodVoucher != null
        ? _appliedFoodVoucher!.calculateActualDiscount(itemsSubtotal: itemsSubtotal, deliveryFee: shipFee)
        : 0.0;

    // Giảm giá tiền ship (tối đa 1 voucher loại shipping, tối đa bằng đúng tiền ship)
    final double shippingDiscount = _appliedShippingVoucher != null
        ? _appliedShippingVoucher!.calculateActualDiscount(itemsSubtotal: itemsSubtotal, deliveryFee: shipFee)
        : 0.0;

    final double discountedFoodSubtotal = (itemsSubtotal - foodDiscount).clamp(0.0, double.infinity);
    final double effectiveShipFee = (shipFee - shippingDiscount).clamp(0.0, double.infinity);
    final double totalPayment = discountedFoodSubtotal + effectiveShipFee;

    // Chính sách hoa hồng Admin (10% trên tiền món sau chiết khấu voucher)
    final commissionRate = CommissionPolicyService().commissionRate; // 10.0
    final adminCommission = discountedFoodSubtotal * (commissionRate / 100.0);
    final storeNetPayout = discountedFoodSubtotal - adminCommission;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () {
            if (widget.onBackToMenu != null) {
              widget.onBackToMenu!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF521B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thanh Toán Gom Đơn',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF521B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
              ),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Semantics(
            identifier: 'btn_place_order',
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF521B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: cartVm.isSubmitting
                  ? null
                  : () => _handlePlaceOrder(cartVm, foodDiscount: foodDiscount, shippingDiscount: shippingDiscount, totalPayment: totalPayment),
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: Text(
                'Đặt đơn nhận tại ${_selectedLocationIndex == 0 ? "Cổng KTX Khu B" : "Cổng KTX"} (${_formatCurrency(totalPayment)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner cảnh báo đóng đợt gom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF521B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đợt gom Ca Trưa sắp đóng',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chốt đơn toàn KTX sau 14 phút nữa',
                        style: TextStyle(
                          color: Color(0xFFC2410C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFFF521B)),
                      SizedBox(width: 4),
                      Text(
                        '10:45',
                        style: TextStyle(
                          color: Color(0xFFFF521B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 1. Điểm nhận hàng cố định tại KTX
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF521B),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Điểm nhận hàng cố định tại KTX',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BẮT BUỘC',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Shipper tập kết và bàn giao đồng loạt tại điểm gom chung',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Danh sách điểm nhận hàng
                ...List.generate(_pickupPoints.length, (idx) {
                  final pt = _pickupPoints[idx];
                  final isSelected = _selectedLocationIndex == idx;
                  return InkWell(
                    onTap: () => setState(() => _selectedLocationIndex = idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFFBF9) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pt['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pt['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 26, top: 4),
                            child: Text(
                              pt['desc'] as String,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ),
                          if (pt['highlight'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 26, top: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pt['highlight'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Chọn Khung giờ nhận hàng theo Ca
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF521B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('2', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Phương thức giao hàng & Khung giờ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Lựa chọn Hình thức: Gom đơn KTX vs Giao lẻ Hỏa tốc
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _deliveryMode = 'GROUP');
                          cartVm.setDeliveryMode('GROUP');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _deliveryMode == 'GROUP' ? const Color(0xFFFFFBF9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _deliveryMode == 'GROUP' ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                              width: _deliveryMode == 'GROUP' ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '📦 Gom đơn KTX',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF521B)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '5.000đ',
                                      style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Giao theo ca trưa/chiều (hẹn gặp linh hoạt)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _deliveryMode = 'EXPRESS');
                          cartVm.setDeliveryMode('EXPRESS');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _deliveryMode == 'EXPRESS' ? const Color(0xFFFFFBF9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _deliveryMode == 'EXPRESS' ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                              width: _deliveryMode == 'EXPRESS' ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '⚡ Giao lẻ hỏa tốc',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '15.000đ',
                                      style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Shipper lấy & giao ngay lúc này', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_deliveryMode == 'GROUP') ...[
                  Row(
                    children: [
                      // Ca Trưa
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedShiftIndex = 0),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _selectedShiftIndex == 0 ? const Color(0xFFFFFBF9) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedShiftIndex == 0 ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                                width: _selectedShiftIndex == 0 ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '☀️ Ca Trưa',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF521B)),
                                    ),
                                    if (_selectedShiftIndex == 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF521B),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ĐANG CHỌN',
                                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '11:30 – 12:00',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Chốt gom lúc 10:45',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Ca Tối
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedShiftIndex = 1),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _selectedShiftIndex == 1 ? const Color(0xFFFFFBF9) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedShiftIndex == 1 ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                                width: _selectedShiftIndex == 1 ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🌙 Ca Tối',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '18:00 – 18:30',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Mở nhận đến 17:15',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đơn lẻ hỏa tốc: Shipper sẽ nhận đơn, tới quán lấy món và giao ngay lúc này tới cổng KTX.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Tóm tắt món đã chọn (2)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF521B),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('3', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tóm tắt món đã chọn (${cartVm.totalItemCount > 0 ? cartVm.totalItemCount : 2})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        if (widget.onBackToMenu != null) {
                          widget.onBackToMenu!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          color: Color(0xFFFF521B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFFFF521B)),
                    const SizedBox(width: 6),
                    Text(
                      cartVm.storeName.isNotEmpty ? cartVm.storeName : 'Cơm Tấm Cô Ba Sinh Viên – Chợ Đêm',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Danh sách món ăn
                if (cartVm.items.isNotEmpty)
                  ...cartVm.items.map((it) {
                    final optsText = it.selectedOptions
                        .where((o) => o.group != 'Ghi chú')
                        .map((e) => e.extraPrice > 0 ? '${e.choice} (+${_formatCurrency(e.extraPrice)})' : e.choice)
                        .join(', ');
                    final dishNote = it.itemNote ?? it.selectedOptions.where((o) => o.group == 'Ghi chú').map((o) => o.choice).firstOrNull;
                    return _buildDishItem(
                      name: '${it.quantity}x ${it.itemName}',
                      price: _formatCurrency(it.totalPrice),
                      imageUrl: it.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                      options: optsText.isNotEmpty ? optsText : null,
                      note: dishNote != null && dishNote.isNotEmpty ? dishNote : null,
                    );
                  })
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, color: Color(0xFF94A3B8), size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Giỏ hàng đang trống',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vui lòng chọn món từ menu quán ăn trước khi thanh toán.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                InkWell(
                  onTap: _showEditNoteDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: Color(0xFFFF521B)),
                        SizedBox(width: 6),
                        Text(
                          '+ Thêm lời nhắn cho Quán ăn',
                          style: TextStyle(
                            color: Color(0xFFFF521B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Mã giảm giá / Ưu đãi KTX (Tối đa 1 mã món ăn & 1 mã phí ship)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF521B),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('4', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Mã giảm giá & Ưu đãi KTX',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Tối đa 1 Món + 1 Ship',
                        style: TextStyle(color: Color(0xFFFF521B), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // SLOT 1: Voucher Món Ăn
                _buildVoucherSlot(
                  title: 'mã giảm tiền món ăn',
                  typeLabel: 'Món ăn',
                  voucher: _appliedFoodVoucher,
                  discountAmount: foodDiscount,
                  onPick: () => _showVoucherPickerModal(context, itemsSubtotal, shipFee, VoucherType.order),
                  onRemove: () => setState(() => _appliedFoodVoucher = null),
                ),
                const SizedBox(height: 8),

                // SLOT 2: Voucher Phí Ship
                _buildVoucherSlot(
                  title: 'mã giảm phí ship KTX',
                  typeLabel: 'Phí ship',
                  voucher: _appliedShippingVoucher,
                  discountAmount: shippingDiscount,
                  onPick: () => _showVoucherPickerModal(context, itemsSubtotal, shipFee, VoucherType.shipping),
                  onRemove: () => setState(() => _appliedShippingVoucher = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Phương thức thanh toán
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF521B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('5', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Option 1: VietQR
                Semantics(
                  identifier: 'radio_payment_vietqr',
                  inMutuallyExclusiveGroup: true,
                  checked: _paymentMethod == 'VIETQR',
                  child: InkWell(
                  onTap: () => setState(() => _paymentMethod = 'VIETQR'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'VIETQR' ? const Color(0xFFFFFBF9) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'VIETQR' ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                        width: _paymentMethod == 'VIETQR' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _paymentMethod == 'VIETQR' ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _paymentMethod == 'VIETQR' ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Chuyển khoản VietQR trước cho Quán',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF521B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'KHUYÊN DÙNG',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 26, top: 4),
                          child: Text(
                            'Quét mã QR qua app ngân hàng, không lo thiếu tiền lẻ khi lấy đồ trường KTX',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.only(left: 26),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFF521B)),
                              SizedBox(width: 4),
                              Text(
                                'Tạo mã QR tự động sau khi bấm đặt',
                                style: TextStyle(color: Color(0xFFFF521B), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                const SizedBox(height: 8),

                // Option 2: COD
                Semantics(
                  identifier: 'radio_payment_cod',
                  inMutuallyExclusiveGroup: true,
                  checked: _paymentMethod == 'COD',
                  child: InkWell(
                  onTap: () => setState(() => _paymentMethod = 'COD'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'COD' ? const Color(0xFFFFFBF9) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 'COD' ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                        width: _paymentMethod == 'COD' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _paymentMethod == 'COD' ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _paymentMethod == 'COD' ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tiền mặt khi nhận tại cổng (COD)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 26, top: 4),
                          child: Text(
                            'Chuẩn bị sẵn ${_formatCurrency(totalPayment)} tiền mặt để không làm nghẽn luồng điểm nhận hàng',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 6. Chi tiết thanh toán
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF521B),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('6', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chi tiết thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  'Tiền món (${cartVm.totalItemCount > 0 ? cartVm.totalItemCount : 2} phần)',
                  _formatCurrency(itemsSubtotal),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('Phí gom đơn KTX', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        SizedBox(width: 4),
                        Icon(Icons.info_outline, size: 13, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    Text(
                      _formatCurrency(shipFee),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (_appliedFoodVoucher != null && foodDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giảm giá món ăn [${_appliedFoodVoucher!.code}]',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
                      ),
                      Text(
                        '-${_formatCurrency(foodDiscount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_appliedShippingVoucher != null && shippingDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giảm phí giao hàng [${_appliedShippingVoucher!.code}]',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
                      ),
                      Text(
                        '-${_formatCurrency(shippingDiscount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      _formatCurrency(totalPayment),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF521B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Minh bạch hoa hồng nền tảng: Quán 90% & Admin 10%
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quán ăn thực nhận (90% tiền món):', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                          Text(_formatCurrency(storeNetPayout), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hoa hồng sàn Admin (${commissionRate.toInt()}% tiền món sau voucher):', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                          Text(_formatCurrency(adminCommission), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card an tâm bảo đảm
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF059669), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn gom được giao đồng loạt đến cổng KTX vào khung giờ đã chọn. Shipper sẽ gửi mã PIN qua App để bạn đối soát nhận món, tránh thất lạc đồ ăn giờ cao điểm.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF065F46), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDishItem({
    required String name,
    required String price,
    required String imageUrl,
    String? options,
    String? note,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.fastfood_rounded, color: Color(0xFFFF521B), size: 24),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (options != null && options.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    options,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFFF521B)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Ghi chú: $note',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherSlot({
    required String title,
    required String typeLabel,
    required VoucherModel? voucher,
    required double discountAmount,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    if (voucher != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        voucher.code,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${_formatCurrency(discountAmount)}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    voucher.description,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF047857)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Gỡ mã',
              icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF059669)),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_num_outlined, size: 16, color: Color(0xFFFF521B)),
                const SizedBox(width: 6),
                Text(
                  '+ Chọn $title',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showVoucherPickerModal(
    BuildContext context,
    double itemsSubtotal,
    double shipFee,
    VoucherType targetType,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<VoucherService>(
          builder: (context, voucherService, child) {
            final allVouchers = voucherService.vouchers
                .where((v) => v.type == targetType)
                .toList();
            final currentVoucher = targetType == VoucherType.order ? _appliedFoodVoucher : _appliedShippingVoucher;
            final sheetTitle = targetType == VoucherType.order
                ? 'Chọn Voucher Giảm Món Ăn (Từ Quán)'
                : 'Chọn Voucher Giảm Phí Ship KTX';

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_num_rounded, color: Color(0xFFFF521B), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              sheetTitle,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Option: Không dùng voucher
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (targetType == VoucherType.order) {
                                _appliedFoodVoucher = null;
                              } else {
                                _appliedShippingVoucher = null;
                              }
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã gỡ mã ưu đãi')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: currentVoucher == null ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                                width: currentVoucher == null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentVoucher == null ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: currentVoucher == null ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Không sử dụng mã này',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (allVouchers.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('Chưa có mã ưu đãi phù hợp cho phân loại này.', style: TextStyle(color: Color(0xFF94A3B8))),
                            ),
                          )
                        else
                          ...allVouchers.map((v) {
                            final isApplied = currentVoucher?.code == v.code;
                            final bool isInactive = !v.isActive;
                            final bool isExhausted = v.isExhausted;
                            final bool isDisabled = isInactive || isExhausted;
                            final bool notEnoughSubtotal = itemsSubtotal < v.minOrderValue;
                            final discount = v.calculateActualDiscount(itemsSubtotal: itemsSubtotal, deliveryFee: shipFee);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDisabled ? const Color(0xFFF8FAFC) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isApplied
                                      ? const Color(0xFF059669)
                                      : (isDisabled ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0)),
                                  width: isApplied ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (isInactive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Mã "${v.code}" đã bị tạm ngưng kích hoạt!'),
                                        backgroundColor: const Color(0xFFDC2626),
                                      ),
                                    );
                                    return;
                                  }
                                  if (isExhausted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Mã "${v.code}" đã hết lượt sử dụng (${v.usedCount}/${v.usageLimit})!'),
                                        backgroundColor: const Color(0xFFDC2626),
                                      ),
                                    );
                                    return;
                                  }
                                  if (notEnoughSubtotal) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đơn hàng chưa đạt tối thiểu ${_formatCurrency(v.minOrderValue)} để áp dụng mã này!'),
                                        backgroundColor: const Color(0xFFEA580C),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    if (targetType == VoucherType.order) {
                                      _appliedFoodVoucher = v;
                                    } else {
                                      _appliedShippingVoucher = v;
                                    }
                                  });
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã áp dụng mã ${v.code} (${_formatCurrency(discount)})'),
                                      backgroundColor: const Color(0xFF059669),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDisabled
                                              ? Colors.grey.shade200
                                              : (v.type == VoucherType.shipping
                                                  ? const Color(0xFFEFF6FF)
                                                  : const Color(0xFFFFF7ED)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          v.type == VoucherType.shipping
                                              ? Icons.local_shipping_rounded
                                              : Icons.restaurant_rounded,
                                          color: isDisabled
                                              ? Colors.grey
                                              : (v.type == VoucherType.shipping
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFFEA580C)),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  v.code,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: isDisabled ? Colors.grey : const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (isExhausted)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF2F2),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFFFECACA)),
                                                    ),
                                                    child: const Text(
                                                      'Hết lượt',
                                                      style: TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  )
                                                else if (isInactive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF2F2),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFFFECACA)),
                                                    ),
                                                    child: const Text(
                                                      'Tạm ngưng',
                                                      style: TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  )
                                                else if (isApplied)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFECFDF5),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                                    ),
                                                    child: const Text(
                                                      'Đang áp dụng',
                                                      style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              v.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: isDisabled ? Colors.grey : const Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              v.description,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Đã dùng ${v.usedCount}/${v.usageLimit > 0 ? v.usageLimit : "∞"} lượt',
                                                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                                if (v.minOrderValue > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Đơn từ ${_formatCurrency(v.minOrderValue)}',
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isDisabled)
                                        Icon(
                                          isApplied ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                          color: isApplied ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
