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
                  KtxButton(
                    label: 'Nhận đơn tại Quán',
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
                  )
                else
                  Text('Đang giao tới trụ KTX', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}