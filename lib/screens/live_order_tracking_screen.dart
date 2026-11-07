import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/screen_state.dart';
import 'dispute_refund_screen.dart';
import 'pickup_qr_code_screen.dart';

/// Màn hình S6: Theo Dõi Đơn Hàng Live chuẩn 100% Figma
class LiveOrderTrackingScreen extends StatefulWidget {
  final OrderDetailModel initialOrder;

  const LiveOrderTrackingScreen({
    super.key,
    required this.initialOrder,
  });

  @override
  State<LiveOrderTrackingScreen> createState() => _LiveOrderTrackingScreenState();
}

class _LiveOrderTrackingScreenState extends State<LiveOrderTrackingScreen> {
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderTrackingViewModel>().loadOrderDetail(
            widget.initialOrder.id,
            initial: widget.initialOrder,
          );
    });
  }

  OrderDetailModel _resolveCurrentOrder(BuildContext context) {
    final trackingState = context.watch<OrderTrackingViewModel>().trackingState;
    if (trackingState is StateSuccess<OrderDetailModel>) {
      final fetched = trackingState.data;
      if (fetched.id == widget.initialOrder.id && fetched.items.isNotEmpty) {
        return fetched;
      }
    }
    return widget.initialOrder;
  }

  void _openQrScreen(OrderDetailModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickupQrCodeScreen(order: order),
      ),
    );
  }

  void _openDisputeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DisputeRefundScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _resolveCurrentOrder(context);
    final orderCode = order.orderCode.isNotEmpty ? order.orderCode : '#KTX-8829B';
    final isCod = order.paymentMethod.toUpperCase() == 'COD';
    final itemsSummary = order.items.isNotEmpty
        ? order.items.map((i) {
            final opts = i.selectedOptions.isNotEmpty
                ? ' (+${i.selectedOptions.map((o) => o.choice).join(", ")})'
                : '';
            return '${i.quantity}x ${i.itemName}$opts';
          }).join(', ')
        : 'Đơn hàng tại ${order.storeName}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Theo Dõi Đơn Hàng',
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
      bottomNavigationBar: _buildBottomNavBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thẻ tiến trình 4 bước giao hàng
          Container(
            padding: const EdgeInsets.all(16),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFFFF521B), size: 6),
                          SizedBox(width: 4),
                          Text(
                            'ĐANG GIAO HÀNG • 3/4',
                            style: TextStyle(
                              color: Color(0xFFFF521B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.group_outlined, color: Color(0xFF059669), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Gom đợt 12 đơn',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tài xế đang tới Cổng KTX',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    children: [
                      TextSpan(text: 'Dự kiến còn '),
                      TextSpan(
                        text: '3 phút',
                        style: TextStyle(color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' nữa sẽ tới. Vui lòng di chuyển xuống sảnh thang máy!'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4 bước tiến trình
                _buildTimelineStep(
                  isDone: true,
                  isActive: false,
                  title: 'Đã chốt & Bếp nấu xong',
                  desc: 'Đã đóng hộp giữ nhiệt',
                  time: '10:45',
                  hasBottomLine: true,
                ),
                _buildTimelineStep(
                  isDone: true,
                  isActive: false,
                  title: 'Tài xế đã nhận món',
                  desc: 'Đã kiểm tra niêm phong túi',
                  time: '11:15',
                  hasBottomLine: true,
                ),
                _buildTimelineStep(
                  isDone: false,
                  isActive: true,
                  title: 'Đang tới KTX Khu B',
                  desc: 'Qua ngã ba Tạ Quang Bửu',
                  time: 'DỰ KIẾN 11:28',
                  hasBottomLine: true,
                ),
                _buildTimelineStep(
                  isDone: false,
                  isActive: false,
                  title: 'Sẵn sàng phát hàng',
                  desc: 'Tại bàn gom đơn sảnh chính',
                  time: '11:30',
                  hasBottomLine: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Thẻ Bản đồ định vị Shipper
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
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đang đi: Đ. Tạ Quang Bửu',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Khung mô phỏng bản đồ
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Đường cong bản đồ
                      CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: _RoadPainter(),
                      ),
                      // Pin định vị cam
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF521B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF521B).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      ),
                      // Pill Cách cổng 450m
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFF521B)),
                              SizedBox(width: 4),
                              Text(
                                'Cách cổng 450m',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF521B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Hàng Đơn xếp số 04/12 & Tiết kiệm 15k ship
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(text: '📦 Đơn xếp số '),
                          TextSpan(
                            text: '04/12',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          TextSpan(text: ' đợt trưa'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Tiết kiệm 15k ship',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Card Tài xế KTX phụ trách
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
                    const Text(
                      'TÀI XẾ KTX PHỤ TRÁCH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đội xe KTX Food',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Thông tin tài xế
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Nguyễn Văn Minh',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.verified_rounded, color: Color(0xFF0284C7), size: 16),
                            ],
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            '★ 4.9 • 340 chuyến KTX',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Honda Wave Đỏ • 59-X1 839.24',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Vị trí tập kết phát hàng (Khung xanh dương nhạt)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VỊ TRÍ TẬP KẾT PHÁT HÀNG',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D4ED8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Bàn số 2 – Trước Cổng KTX Khu B',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Bàn có dù màu cam logo KTX Food',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2 Nút: Gọi tài xế & Nhắn tin
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFFFF521B)),
                        label: const Text('Gọi tài xế', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFFFF521B)),
                        label: const Text('Nhắn tin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Card Mã đơn hàng tóm tắt
          Container(
            padding: const EdgeInsets.all(12),
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
                    Text(
                      'MÃ ĐƠN HÀNG $orderCode',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Row(
                      children: [
                        Text(
                          isCod ? 'Thanh toán tiền mặt COD' : 'Đã thanh toán VietQR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          isCod ? Icons.payments_outlined : Icons.check_circle_rounded,
                          color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.storeName.isNotEmpty ? order.storeName : 'Quán ăn KTX',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            itemsSummary,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCod
                                ? 'Cần thu khi nhận: ${_currencyFmt.format(order.finalAmount)}'
                                : 'Cần thu khi nhận: 0đ (Tổng đơn: ${_currencyFmt.format(order.finalAmount)})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Nút cam to Mở Mã Nhận Hàng (QR Code)
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
              onPressed: () => _openQrScreen(order),
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text(
                'Mở Mã Nhận Hàng (QR Code)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Link Khiếu nại / Báo sự cố đơn hàng
          Center(
            child: InkWell(
              onTap: _openDisputeScreen,
              child: const Text(
                'Khiếu nại / Báo sự cố đơn hàng',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isDone,
    required bool isActive,
    required String title,
    required String desc,
    required String time,
    required bool hasBottomLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (isDone)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
            else if (isActive)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF521B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 12),
              )
            else
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
            if (hasBottomLine)
              Container(
                width: 2,
                height: 38,
                color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: isActive
              ? Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF521B)),
                          ),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF521B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDone ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDone ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Text(desc, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(icon: Icons.home_outlined, label: 'Khám phá', isActive: false),
          _BottomNavItem(icon: Icons.shopping_bag_outlined, label: 'Đặt món', isActive: false),
          _BottomNavItem(icon: Icons.receipt_long_outlined, label: 'Thanh toán', isActive: false),
          _BottomNavItem(icon: Icons.access_time_rounded, label: 'Lịch sử', isActive: true),
          _BottomNavItem(icon: Icons.person_outline_rounded, label: 'Tài khoản', isActive: false),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintRoad = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.5)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final paintLine = Paint()
      ..color = const Color(0xFFFF521B).withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height * 0.4);

    canvas.drawPath(path, paintRoad);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
