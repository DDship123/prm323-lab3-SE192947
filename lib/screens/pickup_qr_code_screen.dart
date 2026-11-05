import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order_model.dart';
import '../theme/ktx_design_system.dart';
import '../viewmodels/order_tracking_vm.dart';
import 'review_feedback_screen.dart';

/// Màn hình S7: Mã QR nhận đồ ăn tại cổng theo tài liệu Thông số thiết kế KTX Food
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
    final pinCode = order.pickupPin.isNotEmpty ? order.pickupPin : '4829';
    final shipperName = order.shipperName?.isNotEmpty == true
        ? order.shipperName!
        : 'Nguyễn Văn Minh';
    final shipperPhone = order.shipperPhone?.isNotEmpty == true
        ? order.shipperPhone!
        : '0912 ••• 829';

    return Scaffold(
      backgroundColor:
          vm.isMaxBrightness ? Colors.white : AppColors.background,
      appBar: KtxAppBar(
        title: 'Mã Nhận Đồ Ăn',
        subtitle: order.orderCode,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // THẺ QR & MÃ PIN (Bo góc 16, đệm 12, viền #f3f4f6, bóng 5%)
            KtxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.pickupLocation,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const KtxPill(
                        label: 'ĐÃ THANH TOÁN',
                        variant: KtxPillVariant.done,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'CHỈ DẪN NHẬN NHANH',
                    style: AppTypography.heading3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đưa mã QR hoặc đọc 4 số cuối SĐT để nhận cơm tại bàn phát.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // QR Code Box tự thích ứng
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final qrContainerSize = (constraints.maxWidth * 0.65)
                          .clamp(170.0, 240.0);
                      final actualQrSize = qrContainerSize - 24;

                      return Center(
                        child: Container(
                          width: qrContainerSize,
                          height: qrContainerSize,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(255, 87, 34, 0.12),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: QrImageView(
                              data: qrCode,
                              version: QrVersions.auto,
                              size: actualQrSize,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Text(
                        'MÃ ĐƠN: #$qrCode',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nút tăng độ sáng (Nút phụ nền #ffedd5)
                  KtxButton(
                    label: vm.isMaxBrightness
                        ? 'Đã bật sáng tối đa (Chống chói nắng)'
                        : 'Sáng max ngoài trời',
                    variant: KtxButtonVariant.secondary,
                    icon: vm.isMaxBrightness
                        ? Icons.wb_sunny_rounded
                        : Icons.wb_sunny_outlined,
                    height: 38,
                    onPressed: vm.toggleBrightness,
                  ),

                  const Divider(height: 20, color: AppColors.divider),

                  Text(
                    'MÃ SỐ ĐỐI SOÁT ĐIỆN THOẠI (4 SỐ CUỐI SĐT)',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          pinCode.split('').join('  -  '),
                          style: AppTypography.heading1.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Thẻ thông tin tài xế đối soát
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHIPPER CHUYẾN GOM',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$shipperName ($shipperPhone)',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Xe: 59-X1 839.24',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Điểm phát: Bàn số 2 • Cổng B KTX',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // NÚT CHÍNH DUY NHẤT TRÊN MÀN HÌNH (Mục 5): Nền #ff5722, cao 44, bo 12
            KtxButton(
              label: 'Xác Nhận Đã Nhận Hàng (Đối soát QR)',
              variant: KtxButtonVariant.primary,
              icon: Icons.qr_code_rounded,
              isLoading: vm.isActionLoading,
              onPressed: () => _confirmPickup(
                context,
                vm,
                'QR_SCAN',
                qrCode,
              ),
            ),
            const SizedBox(height: 8),

            // Nút phụ: Đối soát PIN
            KtxButton(
              label: 'Đối Soát Thủ Công Bằng Mã PIN ($pinCode)',
              variant: KtxButtonVariant.secondary,
              icon: Icons.pin_outlined,
              isLoading: vm.isActionLoading,
              onPressed: () => _confirmPickup(
                context,
                vm,
                'PIN',
                pinCode,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
