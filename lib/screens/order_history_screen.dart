import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/screen_state.dart';
import 'pickup_qr_code_screen.dart';

/// Màn hình Lịch Sử Đơn Hàng chuẩn 100% Figma
/// Bao gồm cả 2 trạng thái:
/// 1. Trạng thái rỗng: "Chưa có đơn hàng nào cần nhận" + Card Gợi ý ca gom hôm nay
/// 2. Trạng thái lỗi mạng: "Mất kết nối máy chủ" + Banner mất kết nối + Hướng dẫn nhận offline
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
  int _selectedTab = 0; // 0: Tất cả, 1: Đang diễn ra, 2: Hoàn tất
  bool _isOfflineDemo = false;

  @override
  void initState() {
    super.initState();
    _isOfflineDemo = widget.initialOfflineDemo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderTrackingViewModel>().loadOrderHistory();
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderTrackingViewModel>();
    final state = vm.historyState;

    final allOrders = state is StateSuccess<List<OrderDetailModel>> ? state.data : <OrderDetailModel>[];
    final activeOrders = allOrders.where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED').toList();
    final completedOrders = allOrders.where((o) => o.status == 'DELIVERED').toList();

    final currentList = switch (_selectedTab) {
      1 => activeOrders,
      2 => completedOrders,
      _ => allOrders,
    };

    return Scaffold(
      backgroundColor: Colors.white,
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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                // Nhấn vào avatar để toggle nhanh chế độ Offline Demo / Online phục vụ chấm bài
                setState(() => _isOfflineDemo = !_isOfflineDemo);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isOfflineDemo
                        ? 'Chuyển sang Trạng thái 2: Mất kết nối máy chủ'
                        : 'Chuyển sang Trạng thái 1: Bình thường'),
                    duration: const Duration(seconds: 1),
                  ),
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
      body: _isOfflineDemo || state is StateError
          ? _buildOfflineErrorState()
          : (currentList.isEmpty
              ? _buildEmptyState(activeOrders.length, completedOrders.length, allOrders.length)
              : _buildOrderList(currentList)),
    );
  }

  // ==================== TRẠNG THÁI 1: CHƯA CÓ ĐƠN HÀNG (EMPTY STATE) ====================
  Widget _buildEmptyState(int activeCount, int completedCount, int totalCount) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thanh vị trí & Ca gom đang mở
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
                  Text(
                    'KTX Khu B (Cổng 2)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
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
                  Text(
                    'Ca gom đang mở',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tabs: Tất cả (0), Đang diễn ra (0), Hoàn tất (0)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFilterTab(0, 'Tất cả ($totalCount)'),
              _buildFilterTab(1, 'Đang diễn ra ($activeCount)'),
              _buildFilterTab(2, 'Hoàn tất ($completedCount)'),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Illustration nồi cơm điện cute
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFF6FF).withValues(alpha: 0.6),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hơi nóng bốc lên
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSteamWave(),
                      const SizedBox(width: 6),
                      _buildSteamWave(height: 16),
                      const SizedBox(width: 6),
                      _buildSteamWave(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Thân nồi cơm
                  Container(
                    width: 90,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Nắp nồi cam
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF521B),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ),
                        ),
                        // Quai cầm nắp
                        Positioned(
                          top: -6,
                          left: 36,
                          child: Container(
                            width: 18,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF521B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // Mặt cười mắt nhắm
                        const Positioned(
                          top: 24,
                          left: 26,
                          right: 26,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('◠', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              Text('◠', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Icon chuông nhỏ góc dưới
              Positioned(
                bottom: 0,
                right: 8,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.notifications_active_outlined, color: Color(0xFFFF521B), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tiêu đề & mô tả rỗng
        const Text(
          'Chưa có đơn hàng nào cần nhận',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bạn không có đơn giao đến cổng KTX trong khung giờ này. Đặt món ngay để kịp chốt đơn nhé!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Nút Đặt món ngay
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF521B),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x66FF521B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text(
              'Đặt món ngay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Card Gợi ý ca gom hôm nay
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GỢI Ý CA GOM HÔM NAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF521B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ca Trưa (11:30 – 12:00)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Freeship Cổng 2',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Box tiến độ gom đơn 24/30
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFFF521B)),
                            SizedBox(width: 4),
                            Text(
                              'Đang nhận đơn, chốt lúc 10:45',
                              style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                        Text(
                          'Đã gom: 24/30 suất',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 24 / 30,
                        backgroundColor: Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF521B)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Avatars bạn bè + Xem 18 quán ngon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildInitialsAvatar('T', const Color(0xFFFDE8E8), const Color(0xFF9B1C1C)),
                      Transform.translate(
                        offset: const Offset(-6, 0),
                        child: _buildInitialsAvatar('M', const Color(0xFFFEF08A), const Color(0xFF713F12)),
                      ),
                      Transform.translate(
                        offset: const Offset(-12, 0),
                        child: _buildInitialsAvatar('K', const Color(0xFFBBF7D0), const Color(0xFF14532D)),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        '+21 bạn cùng tòa B3',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Row(
                      children: [
                        Text(
                          'Xem 18 quán ngon',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF521B),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFFF521B)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TRẠNG THÁI 2: MẤT KẾT NỐI MÁY CHỦ (ERROR / OFFLINE) ====================
  Widget _buildOfflineErrorState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner đỏ/hồng mất kết nối mạng
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
              Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFE11D48)),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Illustration wifi-off trong vòng tròn
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
            ),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF1F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFE11D48), size: 24),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE11D48),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '!',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 10, color: Color(0xFF64748B)),
                          SizedBox(width: 3),
                          Text(
                            'Bàn Gom Khu B',
                            style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tiêu đề & mô tả mất kết nối
        const Text(
          'Mất kết nối máy chủ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Không thể đồng bộ dữ liệu đơn hàng. Vui lòng kiểm tra lại kết nối WiFi/4G hoặc thử lại.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Nút Thử lại kết nối
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF521B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() => _isOfflineDemo = false);
              context.read<OrderTrackingViewModel>().loadOrderHistory();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Thử lại kết nối',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Nút Xem cách nhận hàng offline
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _showOfflineGuidanceDialog,
            icon: const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF64748B)),
            label: const Text(
              'Xem cách nhận hàng offline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Card Cần nhận cơm gấp tại cổng KTX?
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
              const Row(
                children: [
                  Icon(Icons.takeout_dining_rounded, color: Color(0xFFFF521B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Cần nhận cơm gấp tại cổng KTX?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                  children: [
                    TextSpan(text: 'Đọc trực tiếp '),
                    TextSpan(
                      text: '4 số cuối SĐT',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF521B)),
                    ),
                    TextSpan(text: ' cho Điều phối viên trực Bàn gom để nhận hộp cơm đã dán mã đơn.'),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Hotline gọi trực bàn gom
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFFFF521B)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gọi Trực Bàn Gom KTX',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '1900 6899 (Miễn cước sinh viên)',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFEA580C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFEA580C)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TRẠNG THÁI CÓ ĐƠN HÀNG ====================
  Widget _buildOrderList(List<OrderDetailModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, idx) {
        final order = orders[idx];
        final isCompleted = order.status == 'DELIVERED';
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PickupQrCodeScreen(order: order),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
                      order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCompleted ? 'Đã hoàn tất' : 'Đang giao nhận',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? const Color(0xFF059669) : const Color(0xFFFF521B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  order.storeName,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} món • ${_formatCurrency(order.finalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF521B)),
                    ),
                    const Row(
                      children: [
                        Text('Xem mã nhận', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF521B) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSteamWave({double height = 12}) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFF521B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildInitialsAvatar(String text, Color bg, Color textCol) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: bg,
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }
}
