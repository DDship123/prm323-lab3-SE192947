import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum KtxButtonVariant { primary, secondary, outline, danger }

/// Widget Button chuẩn Design System C01 tuân thủ kích thước chạm tối thiểu 48x48dp
class KtxButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KtxButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const KtxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KtxButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case KtxButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        break;
      case KtxButtonVariant.secondary:
        backgroundColor = AppColors.surfaceVariant;
        foregroundColor = AppColors.textPrimary;
        break;
      case KtxButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case KtxButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        break;
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.button.copyWith(color: foregroundColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      label: label,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: width ?? double.infinity,
          minHeight: 48,
        ),
        height: 48, // Đảm bảo touch target >= 48dp theo WCAG
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: variant == KtxButtonVariant.primary ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd,
              side: borderSide,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      ),
    );
  }
}
