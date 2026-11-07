import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum KtxFoodCardLayout { vertical, horizontal }

/// Thành phần C03: KtxFoodItemCard hiển thị món ăn / quán ăn
/// Hỗ trợ 2 kiểu bố cục (Vertical / Horizontal) và trạng thái Hết món (SoldOut phủ xám)
class KtxFoodItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final KtxFoodCardLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;
  final String? badgeText;
  final double? rating;
  final int? ratingCount;

  const KtxFoodItemCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.layout = KtxFoodCardLayout.horizontal,
    this.onTap,
    this.onAddTap,
    this.badgeText,
    this.rating,
    this.ratingCount,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'card_food_item',
      label: isAvailable ? 'Món $title' : 'Món $title (hết món)',
      button: true,
      enabled: isAvailable,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.65,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
            side: const BorderSide(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isAvailable ? onTap : null,
            child: layout == KtxFoodCardLayout.horizontal
                ? _buildHorizontal(context)
                : _buildVertical(context),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double width, double height) {
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          color: AppColors.surfaceVariant,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.fastfood_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                )
              : const Icon(
                  Icons.fastfood_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
        ),
        if (!isAvailable)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: const Text(
                  'HẾT MÓN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        if (badgeText != null && isAvailable)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.roundedSm,
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.roundedSm,
            child: _buildImage(88, 88),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (ratingCount != null) ...[
                        const SizedBox(width: 4),
                        Text('($ratingCount)', style: AppTypography.bodySmall),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price > 0 ? _formatCurrency(price) : 'Xem thực đơn',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onAddTap != null)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: isAvailable ? onAddTap : null,
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: AppRadius.roundedSm,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          tooltip: 'Thêm $title vào giỏ',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVertical(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(double.infinity, 120),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatCurrency(price),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onAddTap != null)
                    Semantics(
                      button: true,
                      label: 'Thêm $title vào giỏ',
                      child: InkWell(
                        onTap: isAvailable ? onAddTap : null,
                        borderRadius: AppRadius.roundedSm,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: AppRadius.roundedSm,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
