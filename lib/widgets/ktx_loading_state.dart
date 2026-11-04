import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Hiển thị trạng thái đang tải C07
class KtxLoadingState extends StatelessWidget {
  final String message;
  final int? itemCount;

  const KtxLoadingState({
    super.key,
    this.message = 'Đang xử lý dữ liệu...',
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'loading_indicator',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
