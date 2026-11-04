import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'dispute_refund_screen.dart';
import 'live_order_tracking_screen.dart';
import 'review_feedback_screen.dart';

/// Màn hình S10: Lịch sử Đơn hàng của Sinh viên KTX (API-008)
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderTrackingViewModel>().loadOrderHistory();
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderTrackingViewModel>();
    final state = vm.historyState;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Lịch sử Đơn hàng S10',
        actions: [
          IconButton(
            onPressed: vm.loadOrderHistory,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadOrderHistory,
        child: switch (state) {
          StateInitial() || StateLoading() => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: KtxLoadingState(itemCount: 3),
            ),
          StateError(:final errorMessage) => KtxErrorState(
              message: errorMessage,
              onRetry: vm.loadOrderHistory,
            ),
          StateEmpty(:final message) => KtxEmptyState(
              title: 'Chưa có đơn hàng nào',
              message: message,
            ),
          StateSuccess(:final data) => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: data.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm + 4),
              itemBuilder: (_, idx) => _buildOrderCard(context, data[idx]),
            ),
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderDetailModel order) {
    final isDelivered = order.status == 'DELIVERED';
    final isCancelled = order.status == 'CANCELLED';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveOrderTrackingScreen(initialOrder: order),
          ),
        );
      },
      borderRadius: AppRadius.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderCode,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? AppColors.error.withValues(alpha: 0.12)
                        : isDelivered
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    order.statusLabel,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCancelled
                          ? AppColors.error
                          : isDelivered
                              ? AppColors.success
                              : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.storeName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Nhận tại: ${order.pickupLocation}',
              style: AppTypography.bodySmall,
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} món • ${order.paymentMethod}',
                  style: AppTypography.bodySmall,
                ),
                Text(
                  _formatCurrency(order.finalAmount),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (isDelivered) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DisputeRefundScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.report_problem_outlined,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Khiếu nại S8',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewFeedbackScreen(order: order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rounded, size: 16),
                    label: const Text('Đánh giá S9'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
