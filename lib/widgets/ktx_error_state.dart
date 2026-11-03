import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';

/// Hiển thị trạng thái lỗi C09 kèm nút Thử lại (Retry)
class KtxErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const KtxErrorState({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
                errorMessage,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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

