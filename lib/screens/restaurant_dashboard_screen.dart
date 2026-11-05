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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OwnerViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Bảng điều khiển Quán Cơm Tấm Cô Ba',
        actions: [
          IconButton(
            tooltip: 'Quản lý thực đơn',
            icon: const Icon(Icons.restaurant_menu_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantMenuManagementScreen(ownerId: widget.ownerId),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => vm.fetchKitchenOrders(ownerId: widget.ownerId),
          ),
          if (widget.onSwitchRole != null)
            IconButton(
              tooltip: 'Đổi vai trò',
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: widget.onSwitchRole,
            ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: widget.onSignOut,
            ),
        ],
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenSummaryHeader(OwnerViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vận hành Bếp & Đơn gom Ca Trưa', style: AppTypography.heading3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '11:30 KTX Khu B',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
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
                ActionChip(
                  avatar: const Icon(Icons.bar_chart, size: 16, color: AppColors.primary),
                  label: const Text('Báo cáo & Đối soát COD', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantRevenueScreen(ownerId: widget.ownerId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.local_offer, size: 16, color: AppColors.primary),
                  label: const Text('Khuyến mãi', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantPromotionScreen(ownerId: widget.ownerId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.rate_review, size: 16, color: AppColors.primary),
                  label: const Text('Đánh giá & Khiếu nại', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDisputesScreen(ownerId: widget.ownerId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.settings, size: 16, color: AppColors.primary),
                  label: const Text('Thiết lập quán', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantStoreSettingsScreen(ownerId: widget.ownerId),
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
        await orderService.cancelOrder(order.id);
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedMd,
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn #${order.orderCode}', style: AppTypography.heading3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Khách hàng: ${order.customerName} (${order.customerPhone})', style: AppTypography.bodySmall),
            Text('Điểm nhận: ${order.pickupLocation}', style: AppTypography.bodySmall),
            const Divider(height: 16),
            ...order.items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.quantity}x ${it.itemName} (${it.selectedOptions ?? "Chuẩn"})',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Text(currencyFormatter.format(it.itemTotalAmount), style: AppTypography.bodyMedium),
                    ],
                  ),
                )),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng tiền: ${currencyFormatter.format(order.finalAmount)}',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                Text(order.paymentMethod, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            if (order.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Từ chối đơn'),
                      onPressed: () => _rejectOrder(order),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Nhận đơn'),
                      onPressed: () => _acceptOrder(order),
                    ),
                  ),
                ],
              ),
            ] else if (order.status == 'PREPARING' || order.status == 'CONFIRMED') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                  ),
                  icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
                  label: const Text('Nấu xong (Sẵn sàng giao cho Shipper)'),
                  onPressed: () => _markOrderReady(order),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}