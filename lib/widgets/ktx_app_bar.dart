import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum KtxAppBarVariant { homeHeader, detailHeader, trackingHeader }

/// Thành phần C05: KtxAppBar hỗ trợ HomeHeader (chọn điểm nhận + chuông thông báo), DetailHeader, TrackingHeader
class KtxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final KtxAppBarVariant variant;
  final int unreadNotificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  final List<Widget>? actions;

  const KtxAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.variant = KtxAppBarVariant.detailHeader,
    this.unreadNotificationCount = 0,
    this.onNotificationTap,
    this.onLocationTap,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: variant != KtxAppBarVariant.homeHeader,
        title: variant == KtxAppBarVariant.homeHeader
            ? InkWell(
                onTap: onLocationTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            subtitle ?? 'Điểm gom đơn KTX',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      Text(
                        title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall,
                    ),
                ],
              ),
        actions: [
          if (onNotificationTap != null)
            IconButton(
              onPressed: onNotificationTap,
              tooltip: 'Thông báo đơn hàng',
              icon: Badge(
                isLabelVisible: unreadNotificationCount > 0,
                label: Text(
                  unreadNotificationCount > 99
                      ? '99+'
                      : '$unreadNotificationCount',
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
