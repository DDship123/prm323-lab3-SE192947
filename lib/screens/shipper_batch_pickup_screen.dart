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
import '../widgets/screen_state.dart';
import 'shipper_handover_confirm_screen.dart';
import 'shipper_pickup_detail_screen.dart';
import 'shipper_route_screen.dart';
import 'shipper_shift_registration_screen.dart';
import 'shipper_shift_summary_screen.dart';
import 'shipper_wallet_screen.dart';

class ShipperBatchPickupScreen extends StatefulWidget {
  final String shipperId;

  const ShipperBatchPickupScreen({super.key, this.shipperId = '3'});

  @override
  State<ShipperBatchPickupScreen> createState() => _ShipperBatchPickupScreenState();
}

class _ShipperBatchPickupScreenState extends State<ShipperBatchPickupScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipperViewModel>().fetchBatch(shipperId: widget.shipperId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipperViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Bảng giao nhận tại Cổng KTX',
        actions: [
          IconButton(
            tooltip: 'Ví Thu nhập & Đối soát',
            icon: const Icon(Icons.account_balance_wallet_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShipperWalletScreen(shipperId: widget.shipperId),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => vm.fetchBatch(shipperId: widget.shipperId),
          ),
        ],
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
        StateSuccess(data: final batch) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildBatchSummaryCard(batch),
              const SizedBox(height: AppSpacing.md),
              Text('Danh sách đơn gom cần giao:', style: AppTypography.heading3),
              const SizedBox(height: AppSpacing.sm),
              ...batch.orders.map((o) => _buildShipperOrderCard(o, vm)),
            ],
          ),
      },
    );
  }

  Widget _buildBatchSummaryCard(ShipperBatchModel batch) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.4),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chuyến gom: Ca Trưa 11:30', style: AppTypography.heading3),
              Text('${batch.totalOrders} đơn', style: AppTypography.heading3.copyWith(color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Điểm tập kết: ${batch.campusZone}', style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Text('Thù lao ước tính: ${currencyFormatter.format(batch.totalDeliveryEarnings)}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.route, size: 16, color: AppColors.primary),
                  label: const Text('Lộ trình gom hàng', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShipperRouteScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  label: const Text('Đăng ký ca', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperShiftRegistrationScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.assessment, size: 16, color: AppColors.primary),
                  label: const Text('Tổng kết ca', style: TextStyle(fontSize: 12)),
                  onPressed: () {
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

  Widget _buildShipperOrderCard(ShipperBatchItemModel order, ShipperViewModel vm) {
    final isDelivering = order.status == 'DELIVERING';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    color: isDelivering ? AppColors.primaryLight : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: isDelivering ? AppColors.primaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Quán: ${order.storeName} (${order.storeAddress})', style: AppTypography.bodySmall),
            Text('Người nhận: ${order.customerName} - ${order.customerPhone}', style: AppTypography.bodySmall),
            Text('PIN đối soát: ${order.pickupPin ?? "4567"}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currencyFormatter.format(order.finalAmount),
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                if (!isDelivering)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      KtxButton(
                        label: 'Lấy hàng',
                        icon: Icons.check_circle_outline,
                        onPressed: () async {
                          await vm.confirmPickup(
                            orderId: order.orderId,
                            shipperId: widget.shipperId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã nhận đơn tại quán! Bắt đầu giao KTX.')),
                          );
                        },
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                    label: const Text('Trao hàng & Thu tiền', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShipperHandoverConfirmScreen(
                            order: order,
                            shipperId: widget.shipperId,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}