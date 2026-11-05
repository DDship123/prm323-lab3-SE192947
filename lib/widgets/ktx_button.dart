import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum KtxButtonVariant {
  primary, // Nền #ff5722, chữ trắng, FILL ngang. Mỗi màn hình chỉ 1 nút chính.
  secondary, // Nền #ffedd5, chữ #c2410c.
  outline, // Viền cam #ff5722, chữ #ff5722.
  danger, // Nền #fef2f2, viền #fecaca, chữ #b91c1c.
}

/// Nút bấm chuẩn KTX Food theo tài liệu thông số thiết kế (Mục 5):
/// - Nút: bo góc 12, cao 44, chữ 12 Bold.
/// - Vùng chạm tối thiểu 44x44.
/// - Nút chính: nền #ff5722, chữ trắng.
/// - Nút phụ: nền #ffedd5, chữ #c2410c.
/// - Nút nguy hiểm: nền #fef2f2, viền #fecaca, chữ #b91c1c.
class KtxButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KtxButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const KtxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KtxButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 44.0, // Chuẩn mục 5: cao 44
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
        backgroundColor = AppColors.primaryLight; // #ffedd5
        foregroundColor = AppColors.primaryDark; // #c2410c
        break;
      case KtxButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.0);
        break;
      case KtxButtonVariant.danger:
        backgroundColor = AppColors.errorLight; // #fef2f2
        foregroundColor = AppColors.error; // #b91c1c
        borderSide = const BorderSide(color: AppColors.errorBorder, width: 1.0); // #fecaca
        break;
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foregroundColor),
                const SizedBox(width: 6),
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
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd, // bo 12
              side: borderSide,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      ),
    );
  }
}
