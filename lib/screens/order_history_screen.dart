import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../viewmodels/order_tracking_vm.dart';
import 'live_order_tracking_screen.dart';
import 'pickup_qr_code_screen.dart';
import 'notification_board_screen.dart';
import 'group_cart_checkout_screen.dart';

/// Màn hình Lịch Sử Đơn Hàng chuẩn 100% Figma
/// Hỗ trợ đầy đủ:
/// - Danh sách đơn hàng đang giao KTX-8829B + Đơn gần đây (Hình 1 mới)
/// - Trạng thái rỗng: "Chưa có đơn hàng nào cần nhận" (Hình 1 cũ)
/// - Trạng thái mất kết nối máy chủ (Hình 2 cũ)
class OrderHistoryScreen extends StatefulWidget {
  final bool initialOfflineDemo;

  const OrderHistoryScreen({
    super.key,
    this.initialOfflineDemo = false,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedTab = 1; // 0: Tất cả 18, 1: Đang diễn ra 1, 2: Hoàn tất 15
  int _viewMode = 0; // 0: Có đơn hàng (Figma mới), 1: Trạng thái rỗng, 2: Mất kết nối mạng
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialOfflineDemo) {
      _viewMode = 2;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderTrackingViewModel>().loadOrderHistory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showOfflineGuidanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.offline_pin_rounded, color: Color(0xFFFF521B)),
            SizedBox(width: 8),
            Text(
              'Nhận hàng offline tại KTX',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khi mất mạng tại cổng KTX:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '1. Đến trực tiếp Bàn Gom KTX Khu B (Cổng 2).\n'
              '2. Đọc 4 số cuối SĐT (ví dụ: 4829) và Tên sinh viên (Lê Thùy Linh).\n'
              '3. Điều phối viên sẽ đối soát hộp cơm dán nhãn theo danh sách giấy offline.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF521B),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _openQrScreen() {
    final sampleOrder = OrderDetailModel(
      id: 8829,
      orderCode: '#KTX-8829B',
      userId: 1,
      storeId: 1,
      storeName: 'Quán Cơm Tấm Cô Ba - ĐHQG',
      status: 'DELIVERING',
      paymentStatus: 'PAID',
      paymentMethod: 'VIETQR',
      slotTime: '11:30 - 12:00',
      pickupLocation: 'Bàn số 2 – Cổng KTX Khu B (Đối diện nhà B5)',
      note: 'Ít mỡ hành, không ớt',
      subtotalAmount: 45000,
      deliveryFee: 0,
      groupDiscountAmount: 0,
      finalAmount: 45000,
      pickupQrCode: 'KTX-ORDER-8829B-LETHUYLINH',
      pickupPin: '4829',
      createdAt: DateTime.now(),
      items: const [
        OrderItemModel(
          id: 1,
          menuItemId: 101,
          itemName: 'Cơm Tấm Sườn Bì Chả Đặc Biệt',
          unitPrice: 35000,
          quantity: 1,
          itemTotalAmount: 35000,
        ),
        OrderItemModel(
          id: 2,
          menuItemId: 102,
          itemName: 'Trà Đào Cam Sả Tươi 500ml',
          unitPrice: 10000,
          quantity: 1,
          itemTotalAmount: 10000,
        ),
      ],
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickupQrCodeScreen(order: sampleOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Lịch Sử Đơn Hàng',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationBoardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E293B)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupCartCheckoutScreen(
                    onOrderCompleted: (order) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LiveOrderTrackingScreen(initialOrder: order),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                // Nhấn vào Avatar để chuyển đổi qua lại giữa 3 chế độ: Có đơn -> Rỗng -> Mất mạng
                setState(() => _viewMode = (_viewMode + 1) % 3);
                final modeName = switch (_viewMode) {
                  0 => 'Chế độ 1: Có đơn hàng đang giao & gần đây (Figma)',
                  1 => 'Chế độ 2: Chưa có đơn hàng (Rỗng)',
                  _ => 'Chế độ 3: Mất kết nối máy chủ (Offline)',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(modeName), duration: const Duration(seconds: 1)),
                );
              },
              child: CircleAvatar(
                radius: 14,
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                ),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _shouldShowBottomQr()
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: Colors.white,
              child: SizedBox(
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
                  onPressed: _openQrScreen,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text(
                    'Mã QR Nhận Hàng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            )
          : null,
      body: _buildBodyContent(),
    );
  }

  bool _shouldShowBottomQr() {
    if (_viewMode == 1 || _viewMode == 2) return false;
    final state = context.watch<OrderTrackingViewModel>().historyState;
    return state is StateSuccess;
  }

  Widget _buildBodyContent() {
    if (_viewMode == 1) return _buildEmptyState();
    if (_viewMode == 2) return _buildOfflineErrorState();

    final state = context.watch<OrderTrackingViewModel>().historyState;
    return switch (state) {
      StateLoading() => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF521B)),
        ),
      StateError() => _buildOfflineErrorState(),
      StateEmpty() => _buildEmptyState(),
      StateSuccess() => _buildActiveHistoryList(),
    };
  }

  // ==================== CHẾ ĐỘ 1: CÓ ĐƠN HÀNG ĐANG GIAO & GẦN ĐÂY (FIGMA MỚI) ====================
  Widget _buildActiveHistoryList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Ô tìm kiếm
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo mã đơn (#KTX-...) hoặc tên món...',
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Banner GOM ĐƠN ĐHQG • THÁNG 10
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'GOM ĐƠN ĐHQG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'THÁNG 10',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                      children: [
                        TextSpan(text: 'Đã gom '),
                        TextSpan(text: '14 đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' • Tiết kiệm '),
                        TextSpan(
                          text: '168.000đ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. 3 Tabs: Tất cả 18, Đang diễn ra 1, Hoàn tất 15
        Row(
          children: [
            _buildCustomTab(0, 'Tất cả 18', _selectedTab == 0),
            const SizedBox(width: 8),
            _buildCustomTab(1, '• Đang diễn ra 1', _selectedTab == 1),
            const SizedBox(width: 8),
            _buildCustomTab(2, 'Hoàn tất 15', _selectedTab == 2),
          ],
        ),
        const SizedBox(height: 18),

        // 4. Section: ĐƠN HÀNG ĐANG GIAO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.delivery_dining_rounded, color: Color(0xFFFF521B), size: 18),
                SizedBox(width: 6),
                Text(
                  'ĐƠN HÀNG ĐANG GIAO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Text(
              'Cập nhật 30s trước',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Thẻ đơn hàng đang giao KTX-8829B
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng tag: #KTX-8829B, KTX Khu B, CA TRƯA
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '#KTX-8829B',
                      style: TextStyle(
                        color: Color(0xFFFF521B),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.apartment_rounded, color: Color(0xFF059669), size: 12),
                        SizedBox(width: 3),
                        Text(
                          'KTX Khu B',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Color(0xFFFF521B), size: 12),
                        SizedBox(width: 3),
                        Text(
                          'CA TRƯA',
                          style: TextStyle(
                            color: Color(0xFFFF521B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thông tin quán
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
                        Row(
                          children: [
                            const Text(
                              'Cơm Tấm Cô Ba – ĐHQG',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Bàn số 2',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '📍 Khung giờ: 11:30 – 12:00 • Cổng chính KTX Khu B',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Trạng thái shipper đang tới cổng (~3 phút)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF34D399), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipper đang tới cổng KTX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bác tài đang mang thùng hàng gom tới Bàn số 2',
                            style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '~3 phút',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Danh sách món
              _buildDishItemRow('1x Cơm Tấm Sườn Bì Chả Đặc Biệt', '35.000đ', note: 'Ghi chú: Ít mỡ hành, không ớt'),
              _buildDishItemRow('1x Trà Đào Cam Sả Tươi (500ml)', '10.000đ'),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Tổng tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Đã thanh toán VietQR',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      children: [
                        TextSpan(text: 'Tổng gom: '),
                        TextSpan(
                          text: '45.000đ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF521B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2 Nút: Theo dõi trực tiếp & Mã QR Nhận Hàng
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
                      onPressed: () {
                        final sampleOrder = OrderDetailModel(
                          id: 8829,
                          orderCode: '#KTX-8829B',
                          userId: 1,
                          storeId: 1,
                          storeName: 'Quán Cơm Tấm Cô Ba - ĐHQG',
                          status: 'DELIVERING',
                          paymentStatus: 'PAID',
                          paymentMethod: 'VIETQR',
                          slotTime: '11:30 - 12:00',
                          pickupLocation: 'Bàn số 2 – Cổng KTX Khu B (Đối diện nhà B5)',
                          subtotalAmount: 45000,
                          deliveryFee: 0,
                          groupDiscountAmount: 0,
                          finalAmount: 45000,
                          pickupQrCode: 'KTX-ORDER-8829B',
                          pickupPin: '4829',
                          createdAt: DateTime.now(),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LiveOrderTrackingScreen(initialOrder: sampleOrder),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: const Text('Theo dõi trực tiếp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF7ED),
                        foregroundColor: const Color(0xFFFF521B),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFFFEDD5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: _openQrScreen,
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: const Text('Mã QR Nhận Hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 5. Section: ĐƠN HÀNG GẦN ĐÂY
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 18),
                SizedBox(width: 6),
                Text(
                  'ĐƠN HÀNG GẦN ĐÂY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {},
              child: const Text(
                'Xem theo tháng',
                style: TextStyle(fontSize: 11, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Card 1: Bún Đậu Mắm Tôm A-B ĐHQG
        _buildPastOrderCard(
          orderCode: '#KTX-8512A',
          time: 'Hôm qua 18:30',
          status: 'Giao thành công',
          isDelivered: true,
          storeName: 'Bún Đậu Mắm Tôm A-B ĐHQG',
          dishSummary: '1x Bún đậu tá lả + Nem chua rán, 1x Nước sấu đá',
          locationAndPrice: 'Cổng Bàn 1 • COD: 48.000đ',
          extraTag: '★ 5.0 Đã đánh giá',
          extraTagColor: const Color(0xFFD97706),
        ),
        const SizedBox(height: 10),

        // Card 2: Trà Sữa Sinh Viên & Trà Đào
        _buildPastOrderCard(
          orderCode: '#KTX-7994B',
          time: '15/10 • Ca Trưa',
          status: 'Hoàn tất',
          isDelivered: true,
          storeName: 'Trà Sữa Sinh Viên & Trà Đào',
          dishSummary: '2x Trà sữa trân châu hoàng kim (~30% đường)',
          locationAndPrice: 'VietQR • 36.000đ',
          extraTag: '🎁 Đánh giá (+50 Xu)',
          extraTagColor: const Color(0xFFEA580C),
        ),
        const SizedBox(height: 10),

        // Card 3: Bánh Mì Chảo KTX
        _buildPastOrderCard(
          orderCode: '#KTX-7420A',
          time: '12/10 • Ca Trưa',
          status: 'Hoàn tất',
          isDelivered: true,
          storeName: 'Bánh Mì Chảo KTX',
          dishSummary: '1x Bánh mì chảo xíu mại trứng muối',
          locationAndPrice: 'Cổng KTX Khu A • 32.000đ',
          extraTag: 'Đã thanh toán',
          extraTagColor: const Color(0xFF059669),
        ),
        const SizedBox(height: 20),

        // 6. Box trợ giúp
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cần hỗ trợ về ca gom hoặc điểm nhận?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Liên hệ Điều phối viên Cổng KTX Khu B qua nhóm Zalo hoặc Hotline sinh viên 1900-KTX',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {},
                child: const Text(
                  'Chat với Trưởng Bàn Giao Hàng >',
                  style: TextStyle(fontSize: 11, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomTab(int index, String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF521B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }

  Widget _buildDishItemRow(String name, String price, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                if (note != null) ...[
                  const SizedBox(height: 1),
                  Text(note, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildPastOrderCard({
    required String orderCode,
    required String time,
    required String status,
    required bool isDelivered,
    required String storeName,
    required String dishSummary,
    required String locationAndPrice,
    required String extraTag,
    required Color extraTagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$orderCode • $time',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF521B), size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dishSummary,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locationAndPrice,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Text(
                extraTag,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: extraTagColor),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_outlined, size: 14),
                  label: const Text('Hóa đơn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF521B),
                    side: const BorderSide(color: Color(0xFFFFCCBC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Đặt lại đơn này', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TRẠNG THÁI RỖNG (EMPTY STATE) ====================
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFFF521B)),
                  SizedBox(width: 4),
                  Text('KTX Khu B (Cổng 2)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF059669), size: 7),
                  SizedBox(width: 5),
                  Text('Ca gom đang mở', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const Center(
          child: Icon(Icons.takeout_dining_rounded, size: 80, color: Color(0xFFFFCCBC)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Chưa có đơn hàng nào cần nhận',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bạn không có đơn giao đến cổng KTX trong khung giờ này. Đặt món ngay để kịp chốt đơn nhé!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF521B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Đặt món ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  // ==================== TRẠNG THÁI MẤT KẾT NỐI (OFFLINE) ====================
  Widget _buildOfflineErrorState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE4E6)),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFFE11D48), size: 8),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mất kết nối mạng • Dữ liệu chưa cập nhật',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                ),
              ),
              Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFE11D48)),
            ],
          ),
        ),
        const SizedBox(height: 36),
        const Center(
          child: Icon(Icons.wifi_off_rounded, size: 80, color: Color(0xFFFDA4AF)),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mất kết nối máy chủ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Không thể đồng bộ dữ liệu đơn hàng. Vui lòng kiểm tra lại kết nối WiFi/4G hoặc thử lại.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF521B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() => _viewMode = 0);
              context.read<OrderTrackingViewModel>().loadOrderHistory();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại kết nối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showOfflineGuidanceDialog,
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: const Text('Xem cách nhận hàng offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
