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
import '../widgets/ktx_button.dart';
import '../widgets/ktx_dialog.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'dispute_refund_screen.dart';
import 'pickup_qr_code_screen.dart';
import 'review_feedback_screen.dart';

/// Màn hình S6: Theo dõi tiến trình đơn hàng Live & Quản lý trạng thái (API-007, API-009, API-010)
class LiveOrderTrackingScreen extends StatefulWidget {
  final OrderDetailModel initialOrder;

  const LiveOrderTrackingScreen({
    super.key,
    required this.initialOrder,
  });

  @override
  State<LiveOrderTrackingScreen> createState() =>
      _LiveOrderTrackingScreenState();
}

class _LiveOrderTrackingScreenState extends State<LiveOrderTrackingScreen> {
  static const _steps = [
    {'code': 'PENDING', 'label': 'Đã đặt đơn (Chờ xác nhận)'},
    {'code': 'CONFIRMED', 'label': 'Quán đã xác nhận ca gom'},
    {'code': 'PREPARING', 'label': 'Quán đang chế biến món ăn'},
    {'code': 'READY', 'label': 'Đã đóng gói xong theo trụ KTX'},
    {'code': 'DELIVERING', 'label': 'Shipper đang giao tới cổng KTX'},
    {'code': 'DELIVERED', 'label': 'Đã giao nhận thành công'},
  ];

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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  int _stepIndex(String status) {
    final idx = _steps.indexWhere((s) => s['code'] == status);
    return idx >= 0 ? idx : 0;
  }

  Future<void> _confirmCancel(
    OrderTrackingViewModel vm,
    OrderDetailModel order,
  ) async {
    final confirmed = await KtxDialog.showDangerConfirm(
      context,
      title: 'Hủy đơn hàng ${order.orderCode}?',
      message:
          'Theo quy tắc BR-ORD-06, sinh viên chỉ có thể hủy khi quán chưa chế biến (trạng thái PENDING). Bạn có chắc chắn muốn hủy?',
    );
    if (confirmed != true || !mounted) return;

    final ok = await vm.cancelOrder(order.id);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy đơn hàng thành công.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderTrackingViewModel>();
    final state = vm.trackingState;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Theo dõi Đơn hàng S6',
        subtitle: widget.initialOrder.orderCode,
        actions: [
          IconButton(
            onPressed: () => vm.loadOrderDetail(widget.initialOrder.id),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới trạng thái',
          ),
        ],
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: KtxLoadingState(itemCount: 3),
          ),
        StateError(:final errorMessage) => KtxErrorState(
            message: errorMessage,
            onRetry: () => vm.loadOrderDetail(widget.initialOrder.id),
          ),
        StateEmpty(:final message) => Center(child: Text(message)),
        StateSuccess(:final data) => _buildContent(context, vm, data),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderTrackingViewModel vm,
    OrderDetailModel order,
  ) {
    final currentStep = _stepIndex(order.status);
    final isCancelled = order.status == 'CANCELLED';
    final isDelivered = order.status == 'DELIVERED';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (vm.actionError != null) ...[
          KtxErrorState(
            message: vm.actionError!,
            isInlineBanner: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
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
                  Text(order.storeName, style: AppTypography.heading3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? AppColors.error.withValues(alpha: 0.12)
                          : isDelivered
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: AppRadius.roundedFull,
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Điểm nhận: ${order.pickupLocation}',
                style: AppTypography.bodyMedium,
              ),
              Text(
                'Ca gom: ${order.slotTime} • Thanh toán: ${order.paymentMethod} (${order.paymentStatus})',
                style: AppTypography.bodySmall,
              ),
              const Divider(height: AppSpacing.lg),
              if (isCancelled)
                const Text(
                  'Đơn hàng này đã bị hủy.',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                ...List.generate(_steps.length, (idx) {
                  final step = _steps[idx];
                  final done = idx <= currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: done ? AppColors.success : AppColors.border,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            step['label']!,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: idx == currentStep
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: done
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết món ăn (Price Snapshot - BR-ORD-02)',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.itemName}',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Text(
                        _formatCurrency(item.itemTotalAmount),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng thanh toán', style: AppTypography.heading3),
                  Text(
                    _formatCurrency(order.finalAmount),
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!isCancelled && !isDelivered) ...[
          if (order.status != 'DELIVERING') ...[
            KtxButton(
              label: '🚀 Bỏ qua chờ: Tới thẳng Nhận hàng (Mở QR)',
              variant: KtxButtonVariant.primary,
              icon: Icons.rocket_launch_rounded,
              isLoading: vm.isActionLoading,
              onPressed: () async {
                final deliveringOrder = await vm.skipToDeliveryStep(order);
                if (context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PickupQrCodeScreen(order: deliveringOrder),
                    ),
                  );
                  if (context.mounted) {
                    vm.loadOrderDetail(order.id);
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          KtxButton(
            label: 'Mở Mã QR / PIN Nhận Hàng tại Cổng (S7)',
            variant: order.status == 'DELIVERING' ? KtxButtonVariant.primary : KtxButtonVariant.secondary,
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PickupQrCodeScreen(order: order),
                ),
              );
              if (context.mounted) {
                vm.loadOrderDetail(order.id);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (order.status != 'DELIVERING')
            KtxButton(
              label: 'Chuyển trạng thái kế tiếp (Demo Store/Shipper)',
              variant: KtxButtonVariant.outline,
              icon: Icons.fast_forward_rounded,
              isLoading: vm.isActionLoading,
              onPressed: () => vm.advanceOrderStatusForDemo(order),
            ),
          if (order.status == 'PENDING') ...[
            const SizedBox(height: AppSpacing.sm),
            KtxButton(
              label: 'Hủy đơn hàng (Chỉ khi PENDING)',
              variant: KtxButtonVariant.danger,
              icon: Icons.cancel_outlined,
              isLoading: vm.isActionLoading,
              onPressed: () => _confirmCancel(vm, order),
            ),
          ],
        ],
        if (isDelivered) ...[
          KtxButton(
            label: 'Đánh giá Quán & Shipper (S9)',
            icon: Icons.star_rate_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewFeedbackScreen(order: order),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          KtxButton(
            label: 'Báo cáo sự cố / Khiếu nại hoàn tiền (S8)',
            variant: KtxButtonVariant.outline,
            icon: Icons.report_problem_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DisputeRefundScreen(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
