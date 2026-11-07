import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/screen_state.dart';
import 'live_order_tracking_screen.dart';
import 'pickup_qr_code_screen.dart';
import 'notification_board_screen.dart';
import 'group_cart_checkout_screen.dart';
import 'review_feedback_screen.dart';

/// Màn hình Lịch Sử Đơn Hàng chuẩn 100% Figma
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
  int _viewMode = 0; // 0: Có đơn hàng, 1: Trạng thái rỗng, 2: Mất kết nối mạng
  final TextEditingController _searchCtrl = TextEditingController();
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

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

  void _openQrScreenForOrder(OrderDetailModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickupQrCodeScreen(order: order),
      ),
    ).then((_) {
      if (mounted) {
        context.read<OrderTrackingViewModel>().loadOrderHistory();
      }
    });
  }

  OrderDetailModel? _getLatestActiveOrder() {
    final state = context.watch<OrderTrackingViewModel>().historyState;
    if (state is StateSuccess<List<OrderDetailModel>>) {
      final sorted = List<OrderDetailModel>.from(state.data)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted
          .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
          .firstOrNull;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final latestActive = _getLatestActiveOrder();
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
            tooltip: 'Làm mới lịch sử đơn',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: () => context.read<OrderTrackingViewModel>().loadOrderHistory(),
          ),
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
        ],
      ),
      bottomNavigationBar: (_shouldShowBottomQr() && latestActive != null)
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
                  onPressed: () => _openQrScreenForOrder(latestActive),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: Text(
                    'Mã QR Nhận Hàng (${latestActive.orderCode})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    return state is StateSuccess<List<OrderDetailModel>>;
  }

  Widget _buildBodyContent() {
    if (_viewMode == 1) return _buildEmptyState();
    if (_viewMode == 2) return _buildOfflineErrorState();

    final state = context.watch<OrderTrackingViewModel>().historyState;
    return switch (state) {
      StateInitial() || StateLoading() => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF521B)),
        ),
      StateError() => _buildOfflineErrorState(),
      StateEmpty() => _buildEmptyState(),
      StateSuccess(data: final orders) => _buildActiveHistoryList(orders),
    };
  }

  // ==================== DANH SÁCH ĐƠN HÀNG THỰC TẾ TỪ BACKEND ====================
  Widget _buildActiveHistoryList(List<OrderDetailModel> rawOrders) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final sortedOrders = List<OrderDetailModel>.from(rawOrders)
      ..sort((a, b) {
        final cmp = b.createdAt.compareTo(a.createdAt);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });

    final filteredOrders = query.isEmpty
        ? sortedOrders
        : sortedOrders.where((o) {
            final matchCode = o.orderCode.toLowerCase().contains(query);
            final matchStore = o.storeName.toLowerCase().contains(query);
            final matchItems = o.items.any((i) => i.itemName.toLowerCase().contains(query));
            return matchCode || matchStore || matchItems;
          }).toList();

    final activeOrders = filteredOrders
        .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
        .toList();
    final completedOrders = filteredOrders
        .where((o) => o.status == 'DELIVERED' || o.status == 'CANCELLED')
        .toList();

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
                  onChanged: (_) => setState(() {}),
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

        // 2. Banner GOM ĐƠN ĐHQG
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
                          'KTX FOOD',
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
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                      children: [
                        const TextSpan(text: 'Tổng cộng '),
                        TextSpan(
                          text: '${sortedOrders.length} đơn',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' • Tiết kiệm phí ship nhờ gom ca KTX'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. 3 Tabs: Tất cả, Đang diễn ra, Hoàn tất
        Row(
          children: [
            _buildCustomTab(0, 'Tất cả (${filteredOrders.length})', _selectedTab == 0),
            const SizedBox(width: 8),
            _buildCustomTab(1, '• Đang giao (${activeOrders.length})', _selectedTab == 1),
            const SizedBox(width: 8),
            _buildCustomTab(2, 'Hoàn tất (${completedOrders.length})', _selectedTab == 2),
          ],
        ),
        const SizedBox(height: 18),

        // 4. Section: ĐƠN HÀNG ĐANG GIAO
        if ((_selectedTab == 0 || _selectedTab == 1) && activeOrders.isNotEmpty) ...[
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.delivery_dining_rounded, color: Color(0xFFFF521B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'ĐƠN HÀNG ĐANG DIỄN RA (MỚI NHẤT Ở TRÊN)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activeOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildActiveOrderCard(order),
              )),
          const SizedBox(height: 6),
        ],

        // 5. Section: ĐƠN HÀNG ĐÃ HOÀN TẤT
        if ((_selectedTab == 0 || _selectedTab == 2) && completedOrders.isNotEmpty) ...[
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'ĐƠN HÀNG ĐÃ HOÀN TẤT / LỊCH SỬ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...completedOrders.map((order) {
            final isCod = order.paymentMethod.toUpperCase() == 'COD';
            final dishSummary = order.items.isNotEmpty
                ? order.items.map((i) => '${i.quantity}x ${i.itemName}').join(', ')
                : 'Đơn hàng tại ${order.storeName}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPastOrderCard(
                order: order,
                orderCode: order.orderCode.startsWith('#') ? order.orderCode : '#${order.orderCode}',
                time: DateFormat('dd/MM HH:mm').format(order.createdAt),
                status: order.status == 'CANCELLED' ? 'Đã hủy' : 'Đã giao thành công',
                isDelivered: order.status == 'DELIVERED',
                storeName: order.storeName,
                dishSummary: dishSummary,
                locationAndPrice:
                    '${isCod ? "COD" : "VietQR"} • ${_currencyFmt.format(order.finalAmount)}',
                extraTag: order.status == 'DELIVERED' ? '🎁 Đánh giá (+50 Xu)' : 'Đã hủy',
                extraTagColor: order.status == 'DELIVERED'
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF64748B),
              ),
            );
          }),
        ],

        // 6. Box trợ giúp
        const SizedBox(height: 10),
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
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActiveOrderCard(OrderDetailModel order) {
    final isCod = order.paymentMethod.toUpperCase() == 'COD';
    final displayCode = order.orderCode.startsWith('#') ? order.orderCode : '#${order.orderCode}';

    return Container(
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
          // Hàng tag: Mã đơn, KTX Khu B, Ca gom
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayCode,
                  style: const TextStyle(
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
                child: Text(
                  order.statusLabel,
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFFFF521B), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      order.slotTime.contains('CHIEU') ? 'CA CHIỀU' : 'CA TRƯA',
                      style: const TextStyle(
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
                    Text(
                      order.storeName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 Điểm nhận: ${order.pickupLocation}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Danh sách món thực tế đã đặt
          if (order.items.isNotEmpty)
            ...order.items.map((item) {
              final linePrice = item.itemTotalAmount > 0
                  ? item.itemTotalAmount
                  : item.unitPrice * item.quantity;
              final optNote = item.selectedOptions.isNotEmpty
                  ? 'Topping/Tùy chọn: ${item.selectedOptions.map((o) => o.choice).join(", ")}'
                  : null;
              return _buildDishItemRow(
                '${item.quantity}x ${item.itemName}',
                _currencyFmt.format(linePrice),
                note: optNote,
              );
            })
          else
            _buildDishItemRow('Đơn hàng tại ${order.storeName}', _currencyFmt.format(order.finalAmount)),

          if (order.note != null && order.note!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Ghi chú đơn: ${order.note}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFFC2410C), fontStyle: FontStyle.italic),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Tổng tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCod ? Icons.payments_outlined : Icons.check_circle_rounded,
                    color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCod ? 'Thanh toán COD khi nhận' : 'Đã thanh toán VietQR',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  children: [
                    const TextSpan(text: 'Tổng gom: '),
                    TextSpan(
                      text: _currencyFmt.format(order.finalAmount),
                      style: const TextStyle(
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

          // 2 Nút: Theo dõi trực tiếp & Mã QR Nhận Hàng (truyền đúng order thực tế)
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LiveOrderTrackingScreen(initialOrder: order),
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
                  onPressed: () => _openQrScreenForOrder(order),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text('Mã QR Nhận Hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
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
    required OrderDetailModel order,
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
                  color: isDelivered ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDelivered ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
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
                      maxLines: 2,
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
              Expanded(
                child: Text(
                  locationAndPrice,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
                  onPressed: () => _openQrScreenForOrder(order),
                  icon: const Icon(Icons.receipt_outlined, size: 14),
                  label: const Text('Hóa đơn & Món', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewFeedbackScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline_rounded, size: 14),
                  label: const Text('Đánh giá món', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
