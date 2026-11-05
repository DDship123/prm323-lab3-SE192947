import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Thẻ (Card) chuẩn KTX Food theo tài liệu thông số thiết kế (Mục 4):
/// - Nền trắng, bo góc 16, viền #f3f4f6 dày 1
/// - Bóng DROP_SHADOW: y 1, blur 2, đen 5% (Color.fromRGBO(0, 0, 0, 0.05))
/// - Đệm 12, khoảng cách giữa các phần 12 (thẻ form đệm 16)
class KtxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isFormCard;

  const KtxCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isFormCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.all(
          isFormCard ? AppSpacing.formPadding : AppSpacing.cardPadding,
        );

    Widget content = Container(
      margin: margin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedCard,
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.roundedCard,
          child: content,
        ),
      );
    }

    return content;
  }
}

