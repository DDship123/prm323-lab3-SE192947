import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';

/// Thành phần C06: KtxDialog hỗ trợ OrderSuccessDialog và DangerConfirmDialog
class KtxDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDanger;
  final IconData? icon;
  final Widget? extraButton;

  const KtxDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    required this.onConfirm,
    this.onCancel,
    this.isDanger = false,
    this.icon,
    this.extraButton,
  });

  /// Hiển thị hộp thoại đặt đơn hàng thành công (S5_OrderSuccessDialog)
  static Future<void> showOrderSuccess(
    BuildContext context, {
    required String orderCode,
    required VoidCallback onTrackOrder,
    VoidCallback? onSkipToPickup,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => KtxDialog(
        title: 'Đặt đơn thành công!',
        message:
            'Đơn hàng $orderCode của bạn đã được ghi nhận vào ca gom đơn KTX. Bạn có thể theo dõi tiến trình hoặc lấy mã QR nhận hàng ngay.',
        confirmLabel: 'Theo dõi đơn hàng',
        icon: Icons.check_circle_rounded,
        onConfirm: onTrackOrder,
        extraButton: onSkipToPickup != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: KtxButton(
                  label: '🚀 Tới thẳng Nhận hàng (Mở QR Code)',
                  variant: KtxButtonVariant.secondary,
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: onSkipToPickup,
                ),
              )
            : null,
      ),
    );
  }

  /// Hiển thị hộp thoại xác nhận hành động nguy hiểm (Hủy đơn hàng)
  static Future<bool?> showDangerConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận hủy',
    String cancelLabel = 'Đóng',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => KtxDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: true,
        icon: Icons.warning_amber_rounded,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isDanger ? AppColors.error : AppColors.success;

    return Semantics(
      namesRoute: true,
      label: title,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ??
                      (isDanger
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded),
                  size: 36,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (cancelLabel != null) ...[
                    Expanded(
                      child: KtxButton(
                        label: cancelLabel!,
                        variant: KtxButtonVariant.secondary,
                        onPressed:
                            onCancel ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: KtxButton(
                      label: confirmLabel,
                      variant: isDanger
                          ? KtxButtonVariant.danger
                          : KtxButtonVariant.primary,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
              if (extraButton != null) extraButton!,
            ],
          ),
        ),
      ),
    );
  }
}
