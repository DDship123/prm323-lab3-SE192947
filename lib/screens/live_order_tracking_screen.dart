import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../theme/ktx_design_system.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/ktx_dialog.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'dispute_refund_screen.dart';
import 'pickup_qr_code_screen.dart';
import 'review_feedback_screen.dart';

/// Màn hình S6: Theo dõi tiến trình đơn hàng Live theo tài liệu Thông số thiết kế KTX Food
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
        title: 'Theo Dõi Đơn Hàng',
        subtitle: widget.initialOrder.orderCode,
        actions: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.headerBtnBackground,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => vm.loadOrderDetail(widget.initialOrder.id),
                customBorder: const CircleBorder(),
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const Padding(
            padding: EdgeInsets.all(AppSpacing.cardPadding),
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
    final isDelivering = order.status == 'DELIVERING';
    final isDelivered = order.status == 'DELIVERED';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      children: [
        if (vm.actionError != null) ...[
          KtxErrorState(
            message: vm.actionError!,
            isInlineBanner: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 1. THẺ THÔNG TIN ĐƠN HÀNG (Bo 16, viền #f3f4f6, bóng mờ 5%)
        KtxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      order.storeName,
                      style: AppTypography.heading2,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  KtxPill(
                    label: order.statusLabel,
                    variant: isCancelled
                        ? KtxPillVariant.rejected
                        : isDelivered
                            ? KtxPillVariant.done
                            : isDelivering
                                ? KtxPillVariant.waiting
                                : KtxPillVariant.waiting,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Điểm nhận: ${order.pickupLocation}',
                      style: AppTypography.bodySmall,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Ca gom: ${order.slotTime} • Thanh toán: ${order.paymentMethod}',
                style: AppTypography.caption,
                softWrap: true,
              ),
              const Divider(height: 18, color: AppColors.divider),

              // TIMELINE TRẠNG THÁI
              if (isCancelled)
                Text(
                  'Đơn hàng này đã bị hủy.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                ...List.generate(_steps.length, (idx) {
                  final step = _steps[idx];
                  final done = idx <= currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: done ? AppColors.success : AppColors.borderStrong,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step['label']!,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: idx == currentStep
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: done
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            softWrap: true,
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

        // 2. THẺ SHIPPER (CHỈ HIỂN THỊ KHI DELIVERING - THEO FIGMA S6)
        if (isDelivering) ...[
          _buildShipperCard(order),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3. THẺ MÓN ĂN & GIÁ TIỀN
        KtxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết món ăn',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.itemName}',
                          style: AppTypography.bodyMedium,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatCurrency(item.itemTotalAmount),
                        style: AppTypography.price,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 18, color: AppColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng thanh toán',
                    style: AppTypography.heading3,
                  ),
                  Text(
                    _formatCurrency(order.finalAmount),
                    style: AppTypography.price.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4. NÚT CHÍNH VÀ NÚT PHỤ (Mỗi màn hình chỉ 1 nút chính nền #ff5722)
        if (!isCancelled && !isDelivered) ...[
          // NÚT CHÍNH DUY NHẤT: Mở mã QR / Nhận hàng
          KtxButton(
            label: 'Mở Mã Nhận Hàng (QR Code)',
            variant: KtxButtonVariant.primary,
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
          const SizedBox(height: 8),

          // Nút phụ: Bỏ qua chờ / Test Demo
          if (!isDelivering) ...[
            KtxButton(
              label: 'Chuyển trạng thái kế tiếp (Demo)',
              variant: KtxButtonVariant.secondary,
              icon: Icons.fast_forward_rounded,
              isLoading: vm.isActionLoading,
              onPressed: () => vm.advanceOrderStatusForDemo(order),
            ),
            const SizedBox(height: 8),
          ],

          if (order.status == 'PENDING')
            KtxButton(
              label: 'Hủy đơn hàng (Chỉ khi PENDING)',
              variant: KtxButtonVariant.danger,
              icon: Icons.cancel_outlined,
              isLoading: vm.isActionLoading,
              onPressed: () => _confirmCancel(vm, order),
            ),
        ],

        if (isDelivered) ...[
          // NÚT CHÍNH: Đánh giá
          KtxButton(
            label: 'Đánh Giá Quán & Shipper',
            variant: KtxButtonVariant.primary,
            icon: Icons.star_rate_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewFeedbackScreen(order: order),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Nút phụ / Báo cáo sự cố
          KtxButton(
            label: 'Báo Cáo Sự Cố / Hoàn Tiền',
            variant: KtxButtonVariant.secondary,
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
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// Thẻ Shipper theo chuẩn Figma Frame 6 (Nguyễn Văn Minh - Bàn số 2 Cổng B2)
  Widget _buildShipperCard(OrderDetailModel order) {
    final shipperName = order.shipperName?.isNotEmpty == true
        ? order.shipperName!
        : 'Nguyễn Văn Minh';
    final shipperPhone = order.shipperPhone?.isNotEmpty == true
        ? order.shipperPhone!
        : '0912 345 829';

    return KtxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.iconBoxBackground, // #fff7ed
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TÀI XẾ KTX PHỤ TRÁCH',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Đội xe KTX Food • Đang tới Cổng',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const KtxPill(
                label: '★ 4.9',
                variant: KtxPillVariant.done,
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.divider),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(
                  shipperName.isNotEmpty ? shipperName[0] : 'S',
                  style: AppTypography.storeTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipperName,
                      style: AppTypography.storeTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Honda Wave Đỏ • 59-X1 839.24',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.roundedSm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.store_mall_directory_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Điểm phát: Bàn số 2 – Trước Cổng KTX Khu B',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          KtxButton(
            label: 'Gọi tài xế: $shipperPhone',
            variant: KtxButtonVariant.secondary,
            icon: Icons.phone_rounded,
            height: 38,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Số điện thoại tài xế: $shipperPhone'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
