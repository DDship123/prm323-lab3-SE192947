import '../services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/owner_order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/owner_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'restaurant_disputes_screen.dart';
import 'restaurant_menu_management_screen.dart';
import 'restaurant_promotion_screen.dart';
import 'restaurant_revenue_screen.dart';
import 'restaurant_store_settings_screen.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  final String ownerId;
  final VoidCallback? onSwitchRole;
  final VoidCallback? onSignOut;

  const RestaurantDashboardScreen({
    super.key,
    this.ownerId = '2',
    this.onSwitchRole,
    this.onSignOut,
  });

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerViewModel>().fetchKitchenOrders(ownerId: widget.ownerId);
    });
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Chủ quán không?'),
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
    final vm = context.watch<OwnerViewModel>();
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
                      child: Icon(Icons.soup_kitchen_rounded, color: Color(0xFFFF521B), size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Cơm Tấm Cô Ba - ĐHQG',
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
                            const Text(
                              'Đang mở Bếp ca trưa 11:30 • KTX Khu B',
                              style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () => vm.fetchKitchenOrders(ownerId: widget.ownerId),
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
                            Text('Cô Ba (Chủ Quán)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('coba.owner@fpt.edu.vn', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đăng xuất',
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                    onPressed: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildKitchenSummaryHeader(vm),
          Expanded(
            child: switch (state) {
              StateInitial() || StateLoading() => const KtxLoadingState(message: 'Đang tải danh sách đơn bếp...'),
              StateEmpty(message: final msg) => KtxEmptyState(
                  icon: Icons.soup_kitchen_rounded,
                  title: 'Bếp trống',
                  message: msg,
                ),
              StateError(errorMessage: final err) => KtxErrorState(
                  errorMessage: err,
                  onRetry: () => vm.fetchKitchenOrders(ownerId: widget.ownerId),
                ),
              StateSuccess(data: final orders) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
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

  Widget _buildKitchenSummaryHeader(OwnerViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFFF521B)),
                  SizedBox(width: 6),
                  Text(
                    'Ca gom trưa (11:30 - 12:00)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Freeship Cổng Khu B',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSlotChip(vm, 'Ca Trưa 11:30', 'CA_TRUA_11H30'),
              const SizedBox(width: 8),
              _buildSlotChip(vm, 'Ca Chiều 18:00', 'CA_CHIEU_18H00'),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(
                  icon: Icons.bar_chart_rounded,
                  label: 'Báo cáo & Đối soát COD',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantRevenueScreen(ownerId: widget.ownerId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.local_offer_rounded,
                  label: 'Khuyến mãi ca',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantPromotionScreen(ownerId: widget.ownerId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.rate_review_rounded,
                  label: 'Đánh giá & Khiếu nại',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDisputesScreen(ownerId: widget.ownerId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Quản lý Menu',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantMenuManagementScreen(ownerId: widget.ownerId),
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

  Widget _buildSlotChip(OwnerViewModel vm, String label, String slotCode) {
    final isSelected = vm.currentSlot == slotCode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => vm.fetchKitchenOrders(ownerId: widget.ownerId, slotTime: slotCode),
    );
  }

  
  Future<void> _acceptOrder(OwnerOrderSummaryModel order) async {
    try {
      final orderService = OrderService();
      await orderService.updateOrderStatus(orderId: order.id, newStatus: 'PREPARING');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận đơn #${order.orderCode} và chuyển cho Bếp nấu!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<OwnerViewModel>().fetchKitchenOrders(ownerId: widget.ownerId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi nhận đơn: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectOrder(OwnerOrderSummaryModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        title: Text('Xác nhận từ chối đơn #${order.orderCode}?'),
        content: const Text('Bạn có chắc chắn muốn từ chối đơn hàng này (hết nguyên liệu / quá tải)? Số tiền sẽ được hoàn trả cho sinh viên.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối đơn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final orderService = OrderService();
        await orderService.updateOrderStatus(orderId: order.id, newStatus: 'CANCELLED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã từ chối đơn #${order.orderCode}!'),
              backgroundColor: AppColors.warning,
            ),
          );
          context.read<OwnerViewModel>().fetchKitchenOrders(ownerId: widget.ownerId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi từ chối đơn: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _markOrderReady(OwnerOrderSummaryModel order) async {
    try {
      final orderService = OrderService();
      await orderService.updateOrderStatus(orderId: order.id, newStatus: 'READY');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đơn #${order.orderCode} đã nấu xong! Đã báo Shipper đến lấy.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<OwnerViewModel>().fetchKitchenOrders(ownerId: widget.ownerId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildOrderCard(OwnerOrderSummaryModel order) {
    final isPending = order.status == 'PENDING';
    final isPreparing = order.status == 'PREPARING' || order.status == 'CONFIRMED';
    final isReady = order.status == 'READY';

    return Container(
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
                  color: isPending
                      ? const Color(0xFFFFFBEB)
                      : (isPreparing ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPending
                        ? const Color(0xFFFDE68A)
                        : (isPreparing ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0)),
                  ),
                ),
                child: Text(
                  isPending
                      ? 'Chờ Bếp nhận đơn'
                      : (isPreparing ? 'Bếp đang nấu' : (isReady ? 'Sẵn sàng giao Shipper' : order.status)),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPending
                        ? const Color(0xFFB45309)
                        : (isPreparing ? const Color(0xFF1D4ED8) : const Color(0xFF047857)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.pickupLocation,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          ...order.items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF521B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${it.quantity}x',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.itemName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        if (it.selectedOptions != null && it.selectedOptions!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Ghi chú: ${it.selectedOptions}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(it.itemTotalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Tổng tiền: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    currencyFormatter.format(order.finalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF521B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  order.paymentMethod == 'VIETQR' ? 'Đã TT VietQR' : 'Thu tiền COD',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _rejectOrder(order),
                    child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF521B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Nhận đơn & Nấu', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _acceptOrder(order),
                  ),
                ),
              ],
            ),
          ] else if (isPreparing) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
                label: const Text('Nấu xong (Sẵn sàng giao Shipper)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _markOrderReady(order),
              ),
            ),
          ],
        ],
      ),
    );
  }
}