import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shipper_batch_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/shipper_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../services/delivery_handshake_service.dart';
import '../viewmodels/profile_demo_vm.dart';
import '../widgets/screen_state.dart';
import 'shipper_handover_confirm_screen.dart';
import 'shipper_pickup_detail_screen.dart';
import 'shipper_route_screen.dart';
import 'shipper_shift_registration_screen.dart';
import 'shipper_shift_summary_screen.dart';
import 'shipper_wallet_screen.dart';
import 'shipper_profile_screen.dart';
import '../services/review_service.dart';
import '../models/review_model.dart';

class ShipperBatchPickupScreen extends StatefulWidget {
  final String shipperId;
  final int initialTabIndex;
  final VoidCallback? onSwitchRole;
  final VoidCallback? onSignOut;

  const ShipperBatchPickupScreen({
    super.key,
    this.shipperId = '3',
    this.initialTabIndex = 0,
    this.onSwitchRole,
    this.onSignOut,
  });

  @override
  State<ShipperBatchPickupScreen> createState() => _ShipperBatchPickupScreenState();
}

class _ShipperBatchPickupScreenState extends State<ShipperBatchPickupScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late int _selectedTabIndex; // 0: Cần phát, 1: Đã hoàn tất
  String? _lastCompletedOrderCode;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipperViewModel>().fetchBatch(shipperId: widget.shipperId);
    });
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Shipper không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSignOut?.call();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipperViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.local_shipping_rounded, color: Color(0xFFFF521B), size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Đội Xe Gom KTX Food',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Trực Bàn số 2 • Cổng KTX Khu B (Ca Trưa)',
                                style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quét QR giao nhanh',
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFF521B), size: 22),
                    onPressed: () => _openQuickScanDialog(context, vm),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () => vm.fetchBatch(shipperId: widget.shipperId),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Tài khoản & Đăng xuất',
                    onSelected: (val) {
                      if (val == 'logout') {
                        _confirmSignOut(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nguyễn Hùng (Shipper)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('shipper.hung@fpt.edu.vn', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF521B), width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const KtxLoadingState(message: 'Đang tải lộ trình gom hàng KTX...'),
        StateEmpty(message: final msg) => KtxEmptyState(
            icon: Icons.two_wheeler_outlined,
            title: 'Chưa có đơn gom',
            message: msg,
          ),
        StateError(errorMessage: final err) => KtxErrorState(
            errorMessage: err,
            onRetry: () => vm.fetchBatch(shipperId: widget.shipperId),
          ),
        StateSuccess(data: final batch) => _buildSuccessBatchView(batch, vm),
      },
    );
  }

  Widget _buildSuccessBatchView(ShipperBatchModel batch, ShipperViewModel vm) {
    final handshake = context.watch<DeliveryHandshakeService>();

    // 1. Sắp xếp đơn hàng: Đơn mới nhất nằm ở trên, đơn cũ hơn nằm ở dưới
    final allOrders = List<ShipperBatchItemModel>.from(batch.orders)
      ..sort((a, b) {
        final cmp = b.createdAt.compareTo(a.createdAt);
        if (cmp != 0) return cmp;
        return b.orderId.compareTo(a.orderId);
      });

    // 2. Phân loại đơn: Đơn hoàn tất tách riêng sang tab "Đã hoàn thành"
    final completedOrders = allOrders.where((o) =>
        o.status == 'DELIVERED' ||
        o.status == 'COMPLETED' ||
        handshake.isFullyDelivered(o.orderId)
    ).toList();

    final activeOrders = allOrders.where((o) =>
        !completedOrders.contains(o) &&
        o.status != 'CANCELLED' &&
        o.status != 'FAILED'
    ).toList();

    final liveEarnings = (completedOrders.length * 15000.0) + handshake.extraShipperEarnings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thẻ tổng quan ca gom & thù lao
        _buildBatchSummaryCard(
          batch: batch,
          completedCount: completedOrders.length,
          totalCount: allOrders.length,
          accumulatedEarnings: liveEarnings,
        ),
        const SizedBox(height: 12),

        if (_lastCompletedOrderCode != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã giao thành công đơn #$_lastCompletedOrderCode! (+15.000đ vào ví)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedTabIndex = 1;
                    });
                  },
                  child: const Text(
                    'Xem đơn đã giao →',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3. Tab chuyển đổi rõ ràng giữa: Đơn cần phát vs Đơn đã hoàn tất
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedTabIndex == 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 16,
                          color: _selectedTabIndex == 0 ? const Color(0xFFFF521B) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cần giao (${activeOrders.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedTabIndex == 0 ? const Color(0xFFFF521B) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedTabIndex == 1
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: _selectedTabIndex == 1 ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đã hoàn tất (${completedOrders.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedTabIndex == 1 ? const Color(0xFF059669) : const Color(0xFF64748B),
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

        // Danh sách đơn hàng theo Tab
        if (_selectedTabIndex == 0) ...[
          if (activeOrders.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFFFF521B), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã tới Cổng KTX?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412)),
                        ),
                        Text(
                          'Báo đồng loạt ${activeOrders.length} sinh viên mang mã QR ra nhận món.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF521B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _handleShipperNotifyAllArrival(context, activeOrders, handshake),
                    child: const Text('Báo tất cả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
          if (activeOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.task_alt_rounded, size: 48, color: Color(0xFF059669)),
                  const SizedBox(height: 10),
                  const Text(
                    'Đã giao xong toàn bộ đơn!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bạn đã hoàn tất phát thành công ${completedOrders.length} đơn gom trong ca này. Mở tab "Đã hoàn tất" để xem chi tiết.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...activeOrders.map((o) => _buildShipperOrderCard(o, vm, handshake)),
        ] else ...[
          if (completedOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text(
                    'Chưa có đơn hoàn tất',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Khi bạn quét mã QR hoặc nhập đúng mã PIN đối soát của sinh viên, đơn sẽ lập tức chuyển sang mục này và cộng tiền thù lao vào ví.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...completedOrders.map((o) => _buildCompletedShipperOrderCard(o)),
        ],
      ],
    );
  }

  Widget _buildBatchSummaryCard({
    required ShipperBatchModel batch,
    required int completedCount,
    required int totalCount,
    required double accumulatedEarnings,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFFF521B)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Chuyến gom Ca Trưa 11:30',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'Đã phát: $completedCount / $totalCount đơn',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Điểm tập kết: Bàn số 2 • Cổng KTX Khu B',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              const Text(
                'Thù lao đã cộng ví: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              Text(
                currencyFormatter.format(accumulatedEarnings > 0 ? accumulatedEarnings : (completedCount * 15000.0)),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
              const Text(
                ' (+15k / đơn hoàn tất)',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildShipperActionChip(
                  icon: Icons.alt_route_rounded,
                  label: 'Lộ trình gom hàng',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShipperRouteScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildShipperActionChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Ví thu nhập & COD',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperWalletScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildShipperActionChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Đăng ký ca mới',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperShiftRegistrationScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildShipperActionChip(
                  icon: Icons.assessment_rounded,
                  label: 'Tổng kết ca',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperShiftSummaryScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipperActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFFF521B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipperOrderCard(
    ShipperBatchItemModel order,
    ShipperViewModel vm,
    DeliveryHandshakeService handshake,
  ) {
    final isDelivering = order.status == 'DELIVERING';
    final isStudentConfirmed = handshake.isStudentConfirmed(order.orderId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  '#${order.orderCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFFF521B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivering ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDelivering ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  isDelivering ? 'Đang giao tới sảnh' : order.status,
                  style: TextStyle(
                    color: isDelivering ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.customerName} • ${order.customerPhone}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ),
              // BẢO MẬT: Tuyệt đối KHÔNG hiển thị mã 4 số của Sinh viên tại đây.
              // Thay bằng trạng thái đối soát bảo mật 2 chiều.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isStudentConfirmed ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isStudentConfirmed ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isStudentConfirmed ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      size: 13,
                      color: isStudentConfirmed ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isStudentConfirmed ? 'SV đã bấm nhận món' : 'Cần quét QR / PIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: isStudentConfirmed ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.storeName} (${order.storeAddress})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          if (order.itemSummaries.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 15, color: Color(0xFFFF521B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Món: ${order.itemSummaries.join(', ')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Tiền thu: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    order.paymentMethod.toUpperCase() == 'COD'
                        ? currencyFormatter.format(order.finalAmount)
                        : '0đ (Online)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: order.paymentMethod.toUpperCase() == 'COD'
                          ? const Color(0xFFFF521B)
                          : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              if (!isDelivering)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShipperPickupDetailScreen(
                              order: order,
                              onPickupConfirmed: () {
                                vm.confirmPickup(
                                  orderId: order.orderId,
                                  shipperId: widget.shipperId,
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text('Chi tiết quán', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF521B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Lấy hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        await vm.confirmPickup(
                          orderId: order.orderId,
                          shipperId: widget.shipperId,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã nhận đơn tại quán! Bắt đầu giao KTX.')),
                          );
                        }
                      },
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Builder(
                      builder: (ctx) {
                        final isArrived = handshake.isShipperArrived(order.orderId);
                        return ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isArrived ? const Color(0xFFEFF6FF) : const Color(0xFFFF521B),
                            foregroundColor: isArrived ? const Color(0xFF2563EB) : Colors.white,
                            side: isArrived ? const BorderSide(color: Color(0xFF3B82F6), width: 1.2) : BorderSide.none,
                            elevation: isArrived ? 0 : 1,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(
                            isArrived ? Icons.mark_chat_read_rounded : Icons.notifications_active_rounded,
                            size: 14,
                            color: isArrived ? const Color(0xFF2563EB) : Colors.white,
                          ),
                          label: Text(
                            isArrived ? 'Đã báo SV ra nhận' : 'Báo đã đến nơi',
                            style: TextStyle(
                              color: isArrived ? const Color(0xFF2563EB) : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _handleShipperNotifyArrival(context, order, handshake),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.report_problem_outlined, size: 14),
                      label: const Text('Sự cố', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showReportFailureDialog(context, order, vm),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 14, color: Colors.white),
                      label: const Text('Trao hàng QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final res = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShipperHandoverConfirmScreen(
                              order: order,
                              shipperId: widget.shipperId,
                            ),
                          ),
                        );
                        if (res == true && mounted) {
                          setState(() {
                            _lastCompletedOrderCode = order.orderCode;
                          });
                        }
                        vm.fetchBatch(shipperId: widget.shipperId);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showShipperOrderReviewSheet(BuildContext context, ShipperBatchItemModel order) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<ReviewModel?>(
          future: ReviewService().fetchOrderReview(order.orderId),
          builder: (context, snapshot) {
            final review = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đánh giá từ khách hàng',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Đơn #',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else ...[
                    // Thông tin khách hàng
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            review?.userAvatarUrl ??
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review?.userDisplayName ?? order.customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                review != null
                                    ? DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt)
                                    : 'Vừa xong',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        // Đánh giá sao shipper
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text(
                                '.0',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Nhận xét shipper
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF047857)),
                              SizedBox(width: 6),
                              Text(
                                'Nhận xét về Shipper:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF047857)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (review?.shipperComment != null && review!.shipperComment!.isNotEmpty)
                                ? review.shipperComment!
                                : ((review?.comment != null && review!.comment!.isNotEmpty)
                                    ? review.comment!
                                    : 'Khách hàng không để lại nhận xét bằng chữ (chỉ chấm sao hoặc gửi ảnh).'),
                            style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (review != null && review.comment != null && review.comment!.isNotEmpty && review.shipperComment != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFFFF521B)),
                                SizedBox(width: 6),
                                Text(
                                  'Nhận xét món ăn:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFFF521B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              review.comment!,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Hình ảnh từ khách (tối đa 3 ảnh)
                    if (review != null && review.images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Hình ảnh từ khách hàng (tối đa 3 ảnh):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: review.images.take(3).map((url) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(url, fit: BoxFit.contain),
                                      ),
                                      IconButton(
                                        icon: const CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 16,
                                          child: Icon(Icons.close, color: Colors.white, size: 18),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Khách hàng không đính kèm hình ảnh.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedShipperOrderCard(ShipperBatchItemModel order) {
    final isCod = order.paymentMethod.toUpperCase() == 'COD';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '#${order.orderCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF047857)),
                    SizedBox(width: 4),
                    Text(
                      'ĐÃ HOÀN TẤT',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.customerName} • ${order.customerPhone}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+15.000đ vào ví',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.storeName} (${order.storeAddress})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          if (order.itemSummaries.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 15, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đã giao: ${order.itemSummaries.join(', ')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCod ? 'Đã thu tiền mặt COD: ${currencyFormatter.format(order.finalAmount)}' : 'VietQR - Đã thanh toán trước',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCod ? const Color(0xFFD97706) : const Color(0xFF059669),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text(
                    'Đối soát 2 chiều thành công',
                    style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelPickupDialog(
    BuildContext context,
    ShipperBatchItemModel order,
    ShipperViewModel vm,
  ) async {
    final reasonController = TextEditingController(text: 'Sự cố xe cộ / Không thể giao kịp');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        title: Text('Hủy nhận đơn #${order.orderCode}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đơn hàng sẽ được chuyển lại trạng thái SẴN SÀNG để tài xế khác trong ca tiếp nhận giao đến KTX.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy nhận',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận trả đơn'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await vm.cancelPickup(
        orderId: order.orderId,
        shipperId: widget.shipperId,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã hủy nhận đơn thành công, trả lại bếp KTX.' : 'Không thể hủy đơn lúc này.'),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _handleShipperNotifyArrival(
    BuildContext context,
    ShipperBatchItemModel order,
    DeliveryHandshakeService handshake,
  ) {
    handshake.markShipperArrived(order.orderId);

    // Kích hoạt thông báo lưu vào trung tâm thông báo của Sinh viên
    try {
      final demoVm = context.read<ProfileDemoViewModel>();
      demoVm.recordIncomingFcmMessage(
        title: '🚚 Shipper đã tới Cổng KTX!',
        body: 'Đơn gom #${order.orderCode} từ ${order.storeName} đã tới Bàn số 2 • Cổng KTX Khu B. Vui lòng mang mã QR / PIN ra nhận món!',
        type: 'ORDER_STATUS',
        appState: 'FOREGROUND',
        dataPayload: order.orderId.toString(),
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '📢 Đã gửi thông báo đến điện thoại sinh viên đơn #${order.orderCode}! Sinh viên đã nhận được chuông thông báo.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleShipperNotifyAllArrival(
    BuildContext context,
    List<ShipperBatchItemModel> orders,
    DeliveryHandshakeService handshake,
  ) {
    handshake.markAllShipperArrived(orders.map((o) => o.orderId));

    try {
      final demoVm = context.read<ProfileDemoViewModel>();
      for (final order in orders) {
        demoVm.recordIncomingFcmMessage(
          title: '🚚 Shipper đã tới Cổng KTX!',
          body: 'Đơn gom #${order.orderCode} từ ${order.storeName} đã tới Bàn số 2 • Cổng KTX Khu B. Vui lòng mang mã QR / PIN ra nhận món!',
          type: 'ORDER_STATUS',
          appState: 'FOREGROUND',
          dataPayload: order.orderId.toString(),
        );
      }
    } catch (_) {}

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '📢 Đã gửi thông báo đồng loạt đến ${orders.length} sinh viên có đơn trong ca này!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF521B),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showReportFailureDialog(
    BuildContext context,
    ShipperBatchItemModel order,
    ShipperViewModel vm,
  ) async {
    String selectedReason = 'Khách không nghe máy (đã gọi 3 lần)';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
          title: Text('Báo cáo khách bom hàng #${order.orderCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Biên bản sự cố sẽ được gửi tới Ban Quản Lý KTX và Quán ăn để ghi nhận đối soát:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Khách không nghe máy (đã gọi 3 lần)', child: Text('Không nghe máy (3 lần)')),
                  DropdownMenuItem(value: 'Khách từ chối nhận đồ ăn', child: Text('Khách từ chối nhận')),
                  DropdownMenuItem(value: 'Khách sai thông tin phòng/tòa KTX', child: Text('Sai địa chỉ / phòng')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gửi báo cáo sự cố'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await vm.reportFailure(
        orderId: order.orderId,
        shipperId: widget.shipperId,
        reason: selectedReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã ghi nhận sự cố bom hàng. Admin KTX sẽ đối soát bảo vệ quyền lợi tài xế.' : 'Gửi báo cáo thất bại.'),
            backgroundColor: ok ? AppColors.warning : AppColors.error,
          ),
        );
      }
    }
  }

  void _openQuickScanDialog(BuildContext context, ShipperViewModel vm) {
    final state = vm.state;
    if (state is! StateSuccess<ShipperBatchModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đợi tải danh sách đơn hàng ca gom.')),
      );
      return;
    }

    final batch = state.data;
    final orders = batch.orders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có đơn hàng nào trong ca gom này.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Quét QR Giao Nhanh', style: AppTypography.heading2),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn đơn hàng để đối soát mã QR / PIN với sinh viên tại cổng KTX:',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...orders.map((ord) {
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text('#${ord.orderCode} - ${ord.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SĐT: ${ord.customerPhone} • ${ord.storeName}'),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Trao hàng', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShipperHandoverConfirmScreen(
                            order: ord,
                            shipperId: widget.shipperId,
                          ),
                        ),
                      ).then((_) => vm.fetchBatch(shipperId: widget.shipperId));
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}