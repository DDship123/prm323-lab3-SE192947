import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';

/// Hiển thị trạng thái lỗi C09 kèm nút Thử lại (Retry) và biến thể InlineErrorBanner
class KtxErrorState extends StatelessWidget {
  final String? errorMessage;
  final String? message;
  final VoidCallback? onRetry;
  final bool isInlineBanner;

  const KtxErrorState({
    super.key,
    this.errorMessage,
    this.message,
    this.onRetry,
    this.isInlineBanner = false,
  });

  String get _resolvedMessage =>
      errorMessage ?? message ?? 'Đã xảy ra sự cố không xác định.';

  @override
  Widget build(BuildContext context) {
    if (isInlineBanner) {
      return Semantics(
        label: 'error_state_view',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.error),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _resolvedMessage,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: 'error_state_view',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 72, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra sự cố',
                style: AppTypography.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _resolvedMessage,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                KtxButton(
                  label: 'Thử lại',
                  icon: Icons.refresh,
                  onPressed: onRetry!,
                  variant: KtxButtonVariant.primary,
                  width: 160,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
