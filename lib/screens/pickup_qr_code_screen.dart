import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/order_tracking_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_error_state.dart';
import 'review_feedback_screen.dart';

/// Màn hình S7: Xuất trình Mã QR & Mã PIN 4 số Đối soát Nhận hàng tại Cổng KTX (BR-ORD-05, API-011)
class PickupQrCodeScreen extends StatelessWidget {
  final OrderDetailModel order;

  const PickupQrCodeScreen({
    super.key,
    required this.order,
  });

  Future<void> _confirmPickup(
    BuildContext context,
    OrderTrackingViewModel vm,
    String method,
    String code,
  ) async {
    final ok = await vm.confirmPickupAtGate(
      order: order,
      verificationMethod: method,
      code: code,
    );
    if (!context.mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đối soát nhận hàng thành công! Đơn hàng đã chuyển sang DELIVERED.',
        ),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReviewFeedbackScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderTrackingViewModel>();
    final qrCode =
        order.pickupQrCode.isNotEmpty ? order.pickupQrCode : 'QR_KTX_${order.id}';
    final pinCode = order.pickupPin.isNotEmpty ? order.pickupPin : '4321';

    return Scaffold(
      backgroundColor:
          vm.isMaxBrightness ? Colors.white : AppColors.background,
      appBar: KtxAppBar(
        title: 'Mã QR Nhận hàng tại Cổng S7',
        subtitle: order.orderCode,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.actionError != null) ...[
              KtxErrorState(
                message: vm.actionError!,
                isInlineBanner: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(
                  color: vm.isMaxBrightness
                      ? AppColors.primary
                      : AppColors.divider,
                  width: vm.isMaxBrightness ? 2.5 : 1,
                ),
                boxShadow: [
                  if (vm.isMaxBrightness)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: AppRadius.roundedFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order.pickupLocation,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Đưa mã này cho Shipper tại Trụ KTX',
                    style: AppTypography.heading3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 230,
                    height: 230,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Text(
                      'Mã QR đối soát: $qrCode',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: vm.toggleBrightness,
                    icon: Icon(
                      vm.isMaxBrightness
                          ? Icons.wb_sunny_rounded
                          : Icons.wb_sunny_outlined,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      vm.isMaxBrightness
                          ? 'Đã bật độ sáng tối đa (Chống chói nắng)'
                          : 'Tăng độ sáng màn hình ngoài trời',
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Text(
                    'Dự phòng khi chói nắng / Camera lỗi (BR-ORD-05):',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MÃ PIN ĐỐI SOÁT (4 SỐ CUỐI SĐT)',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Text(
                      pinCode.split('').join(' - '),
                      style: AppTypography.heading1.copyWith(
                        fontSize: 30,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            KtxButton(
              label: 'Đã nhận được hàng (Đối soát QR)',
              icon: Icons.qr_code_rounded,
              isLoading: vm.isActionLoading,
              onPressed: () => _confirmPickup(
                context,
                vm,
                'QR_SCAN',
                qrCode,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            KtxButton(
              label: 'Đối soát thủ công bằng Mã PIN ($pinCode)',
              variant: KtxButtonVariant.outline,
              icon: Icons.pin_outlined,
              isLoading: vm.isActionLoading,
              onPressed: () => _confirmPickup(
                context,
                vm,
                'PIN',
                pinCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
