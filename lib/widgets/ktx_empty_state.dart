import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';

/// Hiển thị trạng thái rỗng C08 kèm nút hành động (Call To Action)
class KtxEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KtxEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Chưa có dữ liệu',
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'empty_state_view',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                KtxButton(
                  label: actionLabel!,
                  onPressed: onAction!,
                  variant: KtxButtonVariant.outline,
                  width: 220,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
