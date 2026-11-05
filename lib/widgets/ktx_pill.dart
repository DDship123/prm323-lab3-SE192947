import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum KtxPillVariant {
  waiting, // Chờ / đang xử lý: pill #ffedd5, chữ #c2410c
  done, // Xong: pill #059669, chữ trắng
  rejected, // Từ chối: pill #fef2f2, viền #fecaca, chữ #b91c1c
  received, // Đã tiếp nhận: pill #f3f4f6, chữ #6b7280
}

/// Nhãn chip / pill trạng thái chuẩn KTX Food theo tài liệu thông số thiết kế (Mục 2, 3, 5):
/// - Bo góc 9999
/// - Nhãn: 10 Bold
class KtxPill extends StatelessWidget {
  final String label;
  final KtxPillVariant variant;
  final IconData? icon;

  const KtxPill({
    super.key,
    required this.label,
    this.variant = KtxPillVariant.waiting,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case KtxPillVariant.waiting:
        bg = AppColors.primaryLight; // #ffedd5
        text = AppColors.primaryDark; // #c2410c
        break;
      case KtxPillVariant.done:
        bg = AppColors.success; // #059669
        text = Colors.white;
        break;
      case KtxPillVariant.rejected:
        bg = AppColors.errorLight; // #fef2f2
        text = AppColors.error; // #b91c1c
        border = const BorderSide(color: AppColors.errorBorder, width: 1.0); // #fecaca
        break;
      case KtxPillVariant.received:
        bg = AppColors.surfaceVariant; // #f3f4f6
        text = AppColors.textSecondary; // #6b7280
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: text),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.chipLabel.copyWith(color: text),
          ),
        ],
      ),
    );
  }
}

