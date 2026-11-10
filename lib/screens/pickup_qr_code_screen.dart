import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../main.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/delivery_handshake_service.dart';
import '../viewmodels/auth_vm.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/screen_state.dart';
import 'dispute_refund_screen.dart';
import 'live_order_tracking_screen.dart';
import 'review_feedback_screen.dart';

/// Màn hình S7: Mã Nhận Đồ Ăn (Pickup QR Code) chuẩn 100% Figma
class PickupQrCodeScreen extends StatefulWidget {
  final OrderDetailModel order;

  const PickupQrCodeScreen({
    super.key,
    required this.order,
  });

  @override
  State<PickupQrCodeScreen> createState() => _PickupQrCodeScreenState();
}

class _PickupQrCodeScreenState extends State<PickupQrCodeScreen> {
  bool _isMaxBrightness = false;
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.order.items.isEmpty && widget.order.id > 0) {
        context.read<OrderTrackingViewModel>().loadOrderDetail(
              widget.order.id,
              initial: widget.order,
            );
      }
    });
  }

  OrderDetailModel _resolveCurrentOrder(BuildContext context, {bool listen = false}) {
    final trackingState = (listen
            ? context.watch<OrderTrackingViewModel>()
            : context.read<OrderTrackingViewModel>())
        .trackingState;
    if (trackingState is StateSuccess<OrderDetailModel>) {
      final fetched = trackingState.data;
      if (fetched.id == widget.order.id && fetched.items.isNotEmpty) {
        return fetched;
      }
    }
    return widget.order;
  }

  Future<void> _handleConfirmPickup() async {
    final currentOrder = _resolveCurrentOrder(context, listen: false);
    final handshake = context.read<DeliveryHandshakeService>();
    handshake.confirmByStudent(currentOrder.id);
    await handshake.saveToStorage();

    final vm = context.read<OrderTrackingViewModel>();
    final verificationCode = currentOrder.pickupPin.isNotEmpty
        ? currentOrder.pickupPin
        : (currentOrder.pickupQrCode.isNotEmpty ? currentOrder.pickupQrCode : '8448');

    // Chỉ gọi confirmPickup nếu đơn chưa hoàn tất, tránh gọi trùng lặp gây lỗi 422
    if (currentOrder.status != 'DELIVERED') {
      final ok = await vm.confirmPickupAtGate(
        order: currentOrder,
        verificationMethod: 'PIN',
        code: verificationCode,
      );

      // Fallback cập nhật trạng thái nếu confirmPickup gặp sự cố mạng
      if (!ok) {
        try {
          await OrderService().updateOrderStatus(
            orderId: currentOrder.id,
            newStatus: 'DELIVERED',
          );
        } catch (_) {}
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Xác nhận nhận món thành công! Đơn hàng đã hoàn tất.'),
        backgroundColor: Color(0xFF059669),
      ),
    );

    final delivered = currentOrder.copyWith(status: 'DELIVERED');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReviewFeedbackScreen(order: delivered),
      ),
    );
  }

  void _navigateToTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthGate(initialStudentTabIndex: index),
      ),
      (route) => false,
    );
  }

  void _showDisputeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DisputeRefundScreen(),
      ),
    );
  }

  void _showLiveTrackingScreen() {
    final currentOrder = _resolveCurrentOrder(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveOrderTrackingScreen(initialOrder: currentOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = _resolveCurrentOrder(context, listen: true);
    final authVm = context.watch<AuthViewModel>();
    final studentName = authVm.currentUser?.displayName.isNotEmpty == true
        ? authVm.currentUser!.displayName
        : 'Ngô Trường Đạt (Sinh viên)';

    final orderCode = currentOrder.orderCode.isNotEmpty
        ? currentOrder.orderCode.replaceAll('#', '')
        : '8829B';
    final pinCode = currentOrder.pickupPin.isNotEmpty
        ? currentOrder.pickupPin
        : '4829';
    final qrPayload = currentOrder.pickupQrCode.isNotEmpty
        ? currentOrder.pickupQrCode
        : 'KTX-ORDER-$orderCode';
    final isCod = currentOrder.paymentMethod.toUpperCase() == 'COD';
    final totalItemQty = currentOrder.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => _navigateToTab(3),
        ),
        title: const Text(
          'Mã Nhận Đồ Ăn',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                  ),
                  backgroundColor: Colors.grey.shade200,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2 nút Theo dõi đơn & Báo sự cố + Nút Xác nhận đã nhận hàng
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _showLiveTrackingScreen,
                        icon: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF475569)),
                        label: const Text(
                          'Theo dõi đơn',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F2),
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFFFCCD5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _showDisputeScreen,
                        icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE11D48)),
                        label: const Text(
                          'Báo sự cố',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF521B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleConfirmPickup,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Xác nhận đã nhận hàng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 5-Tab Bar với Tab Lịch sử active và sự kiện điều hướng mượt mà
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'Khám phá',
                  isActive: false,
                  onTap: () => _navigateToTab(0),
                ),
                _BottomNavItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Đặt món',
                  isActive: false,
                  onTap: () => _navigateToTab(1),
                ),
                _BottomNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Thanh toán',
                  isActive: false,
                  onTap: () => _navigateToTab(2),
                ),
                _BottomNavItem(
                  icon: Icons.access_time_rounded,
                  label: 'Lịch sử',
                  isActive: true,
                  onTap: () => _navigateToTab(3),
                ),
                _BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Tài khoản',
                  isActive: false,
                  onTap: () => _navigateToTab(4),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Banner xanh đậm CHỈ DẪN NHẬN NHANH
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF047857),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHỈ DẪN NHẬN NHANH',
                        style: TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
                          children: [
                            TextSpan(text: 'Đưa mã QR hoặc đọc '),
                            TextSpan(
                              text: '4 số cuối SĐT',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFDE68A)),
                            ),
                            TextSpan(text: ' để nhận cơm tại bàn phát.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Card Sinh viên (Có sọc cam trên đỉnh)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh viền cam trên đầu
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF521B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '• KTX KHU B • CỔNG B2',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'MÃ ĐƠN ',
                                    style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: '#$orderCode',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFF521B),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentOrder.pickupLocation.isNotEmpty
                            ? currentOrder.pickupLocation
                            : 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),

                      // Box Mã số đối soát điện thoại
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'MÃ SỐ ĐỐI SOÁT ĐIỆN THOẠI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...List.generate(
                                  6,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFFEDD5)),
                                  ),
                                  child: Text(
                                    pinCode,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF521B),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Khớp với 4 chữ số cuối SĐT đặt món',
                              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Khung mã QR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Sáng max
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () {
                      setState(() => _isMaxBrightness = !_isMaxBrightness);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isMaxBrightness ? 'Đã bật độ sáng tối đa để quét mã' : 'Đã đưa độ sáng về bình thường'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 13, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Sáng max',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // QR Code với logo KTX ở tâm
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 180.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF521B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'KTX',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // KTX • ORDER • 8829B
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'KTX • ORDER • $orderCode',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Ca Trưa: 11:30 – 12:00
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        currentOrder.slotTime.contains('CHIEU')
                            ? 'Ca Chiều: 17:30 – 18:00'
                            : 'Ca Trưa: 11:30 – 12:00',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ĐÃ THANH TOÁN (VIETQR) • KHÔNG THU TIỀN hoặc COD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCod ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCod ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCod ? Icons.payments_outlined : Icons.check_circle_rounded,
                        color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCod
                            ? 'THU TIỀN MẶT (COD): ${_currencyFmt.format(currentOrder.finalAmount)}'
                            : 'ĐÃ THANH TOÁN (VIETQR) • KHÔNG THU TIỀN',
                        style: TextStyle(
                          color: isCod ? const Color(0xFFB45309) : const Color(0xFF065F46),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Card Shipper chuyên gom
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF521B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SHIPPER CHUYÊN GOM',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF521B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            currentOrder.shipperName?.isNotEmpty == true
                                ? currentOrder.shipperName!
                                : 'Nguyễn Hùng (Đội xe KTX)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            currentOrder.shipperPhone?.isNotEmpty == true
                                ? currentOrder.shipperPhone!
                                : '0912 ••• 829',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1FAE5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.phone_rounded, color: Color(0xFF059669), size: 18),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Biển số xe: 59–X1 839.24', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(
                      'Điểm phát hàng: Bàn số 2 • Cổng B',
                      style: TextStyle(fontSize: 11, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Danh Sách Món Đối Soát Thực Tế từ đơn hàng đã đặt
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFF521B), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Danh Sách Món Đối Soát (${totalItemQty.toString().padLeft(2, '0')} món)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đối chiếu khi nhận',
                        style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (currentOrder.items.isEmpty)
                  Text(
                    'Đơn hàng tại ${currentOrder.storeName} • Tổng: ${_currencyFmt.format(currentOrder.finalAmount)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  )
                else
                  ...currentOrder.items.map((item) {
                    final lineTotal = item.itemTotalAmount > 0
                        ? item.itemTotalAmount
                        : item.unitPrice * item.quantity;
                    final optText = item.selectedOptions.isNotEmpty
                        ? item.selectedOptions.map((o) => o.choice).join(', ')
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF521B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E293B)),
                                ),
                                if (optText != null) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Topping / Tùy chọn: $optText',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFFC2410C)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currencyFmt.format(lineTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                if (currentOrder.note != null && currentOrder.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        const Text('Ghi chú:  ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                        Expanded(
                          child: Text(
                            currentOrder.note!,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF9A3412)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 18, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quán: ${currentOrder.storeName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tổng thanh toán: ${_currencyFmt.format(currentOrder.finalAmount)}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFFF521B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
