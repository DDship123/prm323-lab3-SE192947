import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/order_model.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../widgets/ktx_dialog.dart';
import '../services/order_service.dart';
import 'online_payment_screen.dart';
import 'pickup_qr_code_screen.dart';

/// MÃ n hÃ¬nh S4: Thanh ToÃ¡n Gom ÄÆ¡n chuáº©n 100% Figma
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
  final _noteCtrl = TextEditingController(
    text: 'Ãt má»¡ hÃ nh, khÃ´ng á»›t, thÃªm nÆ°á»›c máº¯m ngá»t',
  );

  int _selectedLocationIndex = 0;
  int _selectedShiftIndex = 0; // 0: Ca TrÆ°a, 1: Ca Tá»‘i
  String _paymentMethod = 'VIETQR';
  VoucherModel? _appliedVoucher;
  bool _voucherInitialized = false;

  final List<Map<String, dynamic>> _pickupPoints = [
    {
      'title': 'Cá»•ng KTX Khu B (Trá»¥ A1â€“A2)',
      'badge': 'Khu B',
      'desc': 'Shipper Ä‘áº­u Ã´ tÃ´ táº£i ngay cá»•ng chÃ­nh KTX Khu B, sinh viÃªn kiá»ƒm tra tÃªn táº¡i bÃ n trá»±c',
      'highlight': 'âœ“ ÄÃ£ cÃ³ 28 báº¡n cÃ¹ng tÃ²a Ä‘áº·t Ä‘á»£t nÃ y',
    },
    {
      'title': 'Cá»•ng KTX Khu A (Cá»•ng Parabol)',
      'badge': 'Khu A',
      'desc': 'BÃ n giao táº¡i cá»•ng chÃ­nh Ä‘Æ°á»ng LÆ°Æ¡ng Äá»‹nh Cá»§a',
      'highlight': null,
    },
    {
      'title': 'Cá»•ng Viá»‡n MÃ´i trÆ°á»ng LÃ ng ÄH',
      'badge': 'Cá»¥m ÄH',
      'desc': 'Äiá»ƒm háº¹n vá»‰a hÃ¨ trÆ°á»›c cá»•ng viá»‡n, thuáº­n tiá»‡n cho SV KTX A',
      'highlight': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final remoteFee = context
          .read<RemoteConfigService>()
          .groupShipFee
          .toDouble();
      context.read<CartCheckoutViewModel>().updateDeliveryFee(remoteFee);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_voucherInitialized) {
      final v = context.read<VoucherService>().findByCode('SINHVIENKTX');
      if (v != null && v.isActive) {
        _appliedVoucher = v;
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
    return '${formatter.format(amount)}Ä‘';
  }

  Future<void> _handlePlaceOrder(CartCheckoutViewModel cartVm) async {
    context.read<AnalyticsService>().logBeginCheckout(
      itemCount: cartVm.totalItemCount > 0 ? cartVm.totalItemCount : 2,
      subtotalAmount: cartVm.totalItemCount > 0 ? cartVm.subtotalAmount : 50000,
      shippingFee: cartVm.deliveryFee,
    );

    cartVm.setNote(_noteCtrl.text);
    cartVm.setPaymentMethod(_paymentMethod);
    cartVm.setPickupLocation(
      _pickupPoints[_selectedLocationIndex]['title'] as String,
    );
    cartVm.setSlotTime(
      _selectedShiftIndex == 0 ? 'CA_TRUA_11H30' : 'CA_CHIEU_18H00',
    );

    OrderDetailModel? created;
    if (cartVm.items.isNotEmpty && cartVm.storeId != null) {
      created = await cartVm.placeOrder();
    } else {
      // ÄÆ¡n hÃ ng mÃ´ phá»ng theo Figma náº¿u giá» Ä‘ang trá»‘ng
      created = OrderDetailModel(
        id: 8829,
        orderCode: '#KTX-8829B',
        userId: 1,
        storeId: 1,
        storeName: 'QuÃ¡n CÆ¡m Táº¥m CÃ´ Ba - ÄHQG',
        status: 'PENDING_PAYMENT',
        paymentStatus: 'UNPAID',
        paymentMethod: _paymentMethod,
        slotTime: _selectedShiftIndex == 0 ? '11:30 - 12:00' : '18:00 - 18:30',
        pickupLocation:
            _pickupPoints[_selectedLocationIndex]['title'] as String,
        note: _noteCtrl.text,
        subtotalAmount: 50000,
        deliveryFee: 5000,
        groupDiscountAmount: 10000,
        finalAmount: 45000,
        pickupQrCode: 'KTX_PICKUP_8829_SECRET_CODE',
        pickupPin: '8829',
        createdAt: DateTime.now(),
        items: const [
          OrderItemModel(
            id: 1,
            menuItemId: 101,
            itemName: 'CÆ¡m Táº¥m SÆ°á»n BÃ¬ Cháº£ Äáº·c Biá»‡t',
            unitPrice: 35000,
            quantity: 1,
            itemTotalAmount: 35000,
            selectedOptions: [
              SelectedItemOption(
                group: 'Ghi chÃº',
                choice: 'Ãt má»¡ hÃ nh, khÃ´ng á»›t',
                extraPrice: 0,
              ),
            ],
          ),
          OrderItemModel(
            id: 2,
            menuItemId: 102,
            itemName: 'TrÃ  ÄÃ o Cam Sáº£ TÆ°Æ¡i 500ml',
            unitPrice: 15000,
            quantity: 1,
            itemTotalAmount: 15000,
            selectedOptions: [
              SelectedItemOption(
                group: 'ÄÆ°á»ng Ä‘Ã¡',
                choice: '50% Ä‘Æ°á»ng, Ã­t Ä‘Ã¡',
                extraPrice: 0,
              ),
            ],
          ),
        ],
      );
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
              MaterialPageRoute(
                builder: (_) => PickupQrCodeScreen(order: delivering),
              ),
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
        title: const Text(
          'Lá»i nháº¯n cho QuÃ¡n Äƒn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nháº­p ghi chÃº cho quÃ¡n (vÃ­ dá»¥: Ãt cÆ¡m, nhiá»u Ä‘á»“ chua...)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Há»§y', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF521B),
            ),
            onPressed: () {
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text(
              'LÆ°u ghi chÃº',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartCheckoutViewModel>();
    final voucherService = context.watch<VoucherService>();

    // Náº¿u voucher Ä‘ang chá»n bá»‹ Admin Disable á»Ÿ cháº¿ Ä‘á»™ ná»n -> Tá»± Ä‘á»™ng ngáº¯t Ã¡p dá»¥ng ngay tá»©c thÃ¬
    if (_appliedVoucher != null) {
      final latest = voucherService.findByCode(_appliedVoucher!.code);
      if (latest == null || !latest.isActive) {
        _appliedVoucher = null;
      } else {
        _appliedVoucher = latest;
      }
    }

    final double itemsSubtotal = cartVm.totalItemCount > 0
        ? cartVm.subtotalAmount
        : 50000;
    const double originalShipFee = 15000;
    final double shipFee = cartVm.deliveryFee > 0 ? cartVm.deliveryFee : 5000;
    final double voucherDiscount = _voucherApplied ? 10000 : 0;
    final double totalPayment = (itemsSubtotal + shipFee - voucherDiscount)
        .clamp(0, double.infinity);

    // TÃ­nh toÃ¡n giáº£m giÃ¡:
    // QUY Táº®C Báº¢O Vá»† TIá»€N MÃ“N Ä‚N:
    // - Voucher phÃ­ ship CHá»ˆ ÄÆ¯á»¢C GIáº¢M Tá»I ÄA Báº°NG TIá»€N SHIP min(voucherDiscount, shipFee). Tuyá»‡t Ä‘á»‘i KHÃ”NG trá»« láº¹m vÃ o tiá»n mÃ³n Äƒn!
    // - Voucher tiá»n mÃ³n CHá»ˆ ÄÆ¯á»¢C GIáº¢M Tá»I ÄA Báº°NG TIá»€N MÃ“N min(voucherDiscount, itemsSubtotal).
    double voucherDiscount = 0.0;
    if (_appliedVoucher != null) {
      voucherDiscount = _appliedVoucher!.calculateActualDiscount(
        itemsSubtotal: itemsSubtotal,
        deliveryFee: shipFee,
      );
    }

    final double effectiveShipFee = _appliedVoucher?.type == VoucherType.shipping
        ? (shipFee - voucherDiscount).clamp(0, double.infinity)
        : shipFee;

    final double effectiveItemsSubtotal = _appliedVoucher?.type == VoucherType.order
        ? (itemsSubtotal - voucherDiscount).clamp(0, double.infinity)
        : itemsSubtotal;

    final double totalPayment = effectiveItemsSubtotal + effectiveShipFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay láº¡i giá» hÃ ng',
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
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thanh ToÃ¡n Gom ÄÆ¡n',
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
            tooltip: 'ThÃ´ng bÃ¡o',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                ),
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
                  : () => _handlePlaceOrder(cartVm),
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: Text(
                'Äáº·t Ä‘Æ¡n nháº­n táº¡i ${_selectedLocationIndex == 0 ? "Cá»•ng KTX Khu B" : "Cá»•ng KTX"} (${_formatCurrency(totalPayment)})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner cáº£nh bÃ¡o Ä‘Ã³ng Ä‘á»£t gom
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
                        'Äá»£t gom Ca TrÆ°a sáº¯p Ä‘Ã³ng',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chá»‘t Ä‘Æ¡n toÃ n KTX sau 14 phÃºt ná»¯a',
                        style: TextStyle(
                          color: Color(0xFFC2410C),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFFFF521B),
                      ),
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

          // 1. Äiá»ƒm nháº­n hÃ ng cá»‘ Ä‘á»‹nh táº¡i KTX
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Äiá»ƒm nháº­n hÃ ng cá»‘ Ä‘á»‹nh táº¡i KTX',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Báº®T BUá»˜C',
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
                  'Shipper táº­p káº¿t vÃ  bÃ n giao Ä‘á»“ng loáº¡t táº¡i Ä‘iá»ƒm gom chung',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Danh sÃ¡ch Ä‘iá»ƒm nháº­n hÃ ng
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
                        color: isSelected
                            ? const Color(0xFFFFFBF9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF521B)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? const Color(0xFFFF521B)
                                    : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pt['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pt['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 26, top: 4),
                            child: Text(
                              pt['desc'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (pt['highlight'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 26, top: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
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

          // 2. Chá»n Khung giá» nháº­n hÃ ng theo Ca
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
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chá»n Khung giá» nháº­n hÃ ng theo Ca',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Ca TrÆ°a
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedShiftIndex = 0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedShiftIndex == 0
                                ? const Color(0xFFFFFBF9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedShiftIndex == 0
                                  ? const Color(0xFFFF521B)
                                  : const Color(0xFFE2E8F0),
                              width: _selectedShiftIndex == 0 ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'â˜€ï¸ Ca TrÆ°a',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFFF521B),
                                    ),
                                  ),
                                  if (_selectedShiftIndex == 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF521B),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ÄANG CHá»ŒN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '11:30 â€“ 12:00',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Chá»‘t gom lÃºc 10:45',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Ca Tá»‘i
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedShiftIndex = 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedShiftIndex == 1
                                ? const Color(0xFFFFFBF9)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedShiftIndex == 1
                                  ? const Color(0xFFFF521B)
                                  : const Color(0xFFE2E8F0),
                              width: _selectedShiftIndex == 1 ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ðŸŒ™ Ca Tá»‘i',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '18:00 â€“ 18:30',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Má»Ÿ nháº­n Ä‘áº¿n 17:15',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. TÃ³m táº¯t mÃ³n Ä‘Ã£ chá»n (2)
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
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TÃ³m táº¯t mÃ³n Ä‘Ã£ chá»n (${cartVm.totalItemCount > 0 ? cartVm.totalItemCount : 2})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
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
                        'Chá»‰nh sá»­a',
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
                    const Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: Color(0xFFFF521B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cartVm.storeName.isNotEmpty
                          ? cartVm.storeName
                          : 'CÆ¡m Táº¥m CÃ´ Ba Sinh ViÃªn â€“ Chá»£ ÄÃªm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Danh sÃ¡ch mÃ³n Äƒn
                if (cartVm.items.isNotEmpty)
                  ...cartVm.items.map((it) {
                    final noteText = it.selectedOptions
                        .map((e) => e.choice)
                        .join(', ');
                    return _buildDishItem(
                      name: '${it.quantity}x ${it.itemName}',
                      price: _formatCurrency(it.totalPrice),
                      imageUrl: it.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                      note: noteText.isNotEmpty ? noteText : null,
                    );
                  })
                else ...[
                  _buildDishItem(
                    name: '1x CÆ¡m Táº¥m SÆ°á»n BÃ¬ Cháº£',
                    price: '35.000Ä‘',
                    imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                    note: _noteCtrl.text.isNotEmpty
                        ? 'Ghi chÃº: ${_noteCtrl.text}'
                        : 'Ghi chÃº: Ãt má»¡ hÃ nh, khÃ´ng á»›t, thÃªm nÆ°á»›c máº¯m ngá»t',
                  ),
                  _buildDishItem(
                    name: '1x TrÃ  ÄÃ o Cam Sáº£',
                    price: '15.000Ä‘',
                    imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=200',
                    note: '50% Ä‘Æ°á»ng, Ã­t Ä‘Ã¡',
                  ),
                ],

                const SizedBox(height: 8),
                InkWell(
                  onTap: _showEditNoteDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Color(0xFFFF521B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '+ ThÃªm lá»i nháº¯n cho QuÃ¡n Äƒn',
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

          // 4. MÃ£ giáº£m giÃ¡ / Æ¯u Ä‘Ã£i KTX
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
                        child: Text(
                          '4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MÃ£ giáº£m giÃ¡ / Æ¯u Ä‘Ã£i KTX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_appliedVoucher != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 18),
                        ),
                        child: const Icon(
                          Icons.confirmation_num_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'SINHVIENKTX',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ÄÃ£ Ã¡p dá»¥ng',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Giáº£m 10.000Ä‘ phÃ­ giao gom chung',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _voucherApplied = !_voucherApplied);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _voucherApplied
                                    ? 'ÄÃ£ Ã¡p dá»¥ng mÃ£ SINHVIENKTX'
                                    : 'ÄÃ£ gá»¡ mÃ£ Æ°u Ä‘Ã£i',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          _voucherApplied ? 'Äá»•i mÃ£' : 'Ãp dá»¥ng',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _appliedVoucher!.code,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF065F46)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ÄÃ£ Ã¡p dá»¥ng',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _appliedVoucher!.type == VoucherType.shipping
                                    ? 'Giáº£m tá»‘i Ä‘a ${_formatCurrency(_appliedVoucher!.discountAmount)} phÃ­ giao gom chung'
                                    : 'Giáº£m ${_formatCurrency(_appliedVoucher!.discountAmount)} tiá»n mÃ³n Äƒn',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showVoucherPickerModal(context, itemsSubtotal, shipFee),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'Äá»•i mÃ£',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.confirmation_num_outlined, color: Color(0xFF64748B), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ChÆ°a chá»n mÃ£ Æ°u Ä‘Ã£i',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Báº¥m chá»n mÃ£ Ä‘á»ƒ Ä‘Æ°á»£c giáº£m phÃ­ ship hoáº·c tiá»n mÃ³n',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showVoucherPickerModal(context, itemsSubtotal, shipFee),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF521B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Chá»n mÃ£',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. PhÆ°Æ¡ng thá»©c thanh toÃ¡n
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
                        child: Text(
                          '5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PhÆ°Æ¡ng thá»©c thanh toÃ¡n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
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
                        color: _paymentMethod == 'VIETQR'
                            ? const Color(0xFFFFFBF9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == 'VIETQR'
                              ? const Color(0xFFFF521B)
                              : const Color(0xFFE2E8F0),
                          width: _paymentMethod == 'VIETQR' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _paymentMethod == 'VIETQR'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _paymentMethod == 'VIETQR'
                                    ? const Color(0xFFFF521B)
                                    : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Chuyá»ƒn khoáº£n VietQR trÆ°á»›c cho QuÃ¡n',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF521B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'KHUYÃŠN DÃ™NG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 26, top: 4),
                            child: Text(
                              'QuÃ©t mÃ£ QR qua app ngÃ¢n hÃ ng, khÃ´ng lo thiáº¿u tiá»n láº» khi láº¥y Ä‘á»“ trÆ°á»ng KTX',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.only(left: 26),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFEDD5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 14,
                                  color: Color(0xFFFF521B),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Táº¡o mÃ£ QR tá»± Ä‘á»™ng sau khi báº¥m Ä‘áº·t',
                                  style: TextStyle(
                                    color: Color(0xFFFF521B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                        color: _paymentMethod == 'COD'
                            ? const Color(0xFFFFFBF9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == 'COD'
                              ? const Color(0xFFFF521B)
                              : const Color(0xFFE2E8F0),
                          width: _paymentMethod == 'COD' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _paymentMethod == 'COD'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _paymentMethod == 'COD'
                                    ? const Color(0xFFFF521B)
                                    : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tiá»n máº·t khi nháº­n táº¡i cá»•ng (COD)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 26, top: 4),
                            child: Text(
                              'Chuáº©n bá»‹ sáºµn ${_formatCurrency(totalPayment)} tiá»n máº·t Ä‘á»ƒ khÃ´ng lÃ m ngháº½n luá»“ng Ä‘iá»ƒm nháº­n hÃ ng',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
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

          // 6. Chi tiáº¿t thanh toÃ¡n
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
                        child: Text(
                          '6',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chi tiáº¿t thanh toÃ¡n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  'Tiá»n mÃ³n (${cartVm.totalItemCount > 0 ? cartVm.totalItemCount : 2} pháº§n)',
                  _formatCurrency(itemsSubtotal),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'PhÃ­ gom Ä‘Æ¡n KTX',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(originalShipFee),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
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
                  ],
                ),
                if (_appliedVoucher != null && voucherDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giáº£m giÃ¡ voucher [SINHVIENKTX]',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                        ),
                      Text(
                        _appliedVoucher!.type == VoucherType.shipping
                            ? 'Giáº£m phÃ­ gom Ä‘Æ¡n [${_appliedVoucher!.code}]'
                            : 'Giáº£m giÃ¡ mÃ³n Äƒn [${_appliedVoucher!.code}]',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
                      ),
                      Text(
                        '-${_formatCurrency(voucherDiscount)}',
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
                      'Tá»•ng thanh toÃ¡n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
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
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: Color(0xFFFF521B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tiáº¿t kiá»‡m 20.000Ä‘ nhá» gom Ä‘Æ¡n',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF521B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Card an tÃ¢m báº£o Ä‘áº£m
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
                      Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF059669),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ÄÆ¡n gom Ä‘Æ°á»£c giao Ä‘á»“ng loáº¡t Ä‘áº¿n cá»•ng KTX vÃ o khung giá» Ä‘Ã£ chá»n. Shipper sáº½ gá»­i mÃ£ PIN qua App Ä‘á»ƒ báº¡n Ä‘á»‘i soÃ¡t nháº­n mÃ³n, trÃ¡nh tháº¥t láº¡c Ä‘á»“ Äƒn giá» cao Ä‘iá»ƒm.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                            height: 1.35,
                          ),
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
                child: const Icon(
                  Icons.fastfood_rounded,
                  color: Color(0xFFFF521B),
                  size: 24,
                ),
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
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                    ),
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
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
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

  void _showVoucherPickerModal(
    BuildContext context,
    double itemsSubtotal,
    double shipFee,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<VoucherService>(
          builder: (context, voucherService, child) {
            final allVouchers = voucherService.vouchers;
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
                        const Row(
                          children: [
                            Icon(Icons.confirmation_num_rounded, color: Color(0xFFFF521B), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'MÃ£ giáº£m giÃ¡ & Æ¯u Ä‘Ã£i KTX',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
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
                        // Option: KhÃ´ng dÃ¹ng voucher
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => _appliedVoucher = null);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ÄÃ£ gá»¡ mÃ£ Æ°u Ä‘Ã£i')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _appliedVoucher == null ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                                width: _appliedVoucher == null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _appliedVoucher == null ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: _appliedVoucher == null ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'KhÃ´ng sá»­ dá»¥ng mÃ£ giáº£m giÃ¡',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...allVouchers.map((v) {
                          final isApplied = _appliedVoucher?.code == v.code;
                          final bool isDisabled = !v.isActive;
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
                                    : const Color(0xFFE2E8F0),
                                width: isApplied ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (isDisabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('MÃ£ "${v.code}" Ä‘Ã£ bá»‹ Ban Quáº£n LÃ½ KTX táº¡m ngÆ°ng kÃ­ch hoáº¡t!'),
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                  );
                                  return;
                                }
                                if (notEnoughSubtotal) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('ÄÆ¡n hÃ ng chÆ°a Ä‘áº¡t tá»‘i thiá»ƒu ${_formatCurrency(v.minOrderValue)} Ä‘á»ƒ Ã¡p dá»¥ng mÃ£ nÃ y!'),
                                      backgroundColor: const Color(0xFFEA580C),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _appliedVoucher = v);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ÄÃ£ Ã¡p dá»¥ng mÃ£ ${v.code} (${_formatCurrency(discount)})'),
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
                                              if (isDisabled)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF2F2),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFFFECACA)),
                                                  ),
                                                  child: const Text(
                                                    'Táº¡m khÃ³a bá»Ÿi Admin',
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
                                                    'Äang Ã¡p dá»¥ng',
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
                                                  'Tá»‘i Ä‘a ${v.maxUsagePerAccount} lÆ°á»£t/SV',
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
                                                    'ÄÆ¡n tá»« ${_formatCurrency(v.minOrderValue)}',
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
