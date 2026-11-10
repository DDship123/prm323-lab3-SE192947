import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';

enum KtxAppBarVariant {
  standard, // Trang chuẩn: Quay lại tròn 44x44 + Tiêu đề + Chuông/Giỏ hàng/Avatar tròn 44x44
  homeHeader, // Home header với ô chọn điểm nhận KTX chuẩn Figma (Node 822:414)
  authHeader, // Trang auth: Chỉ có nút quay lại (nếu có), không icon chuông/cart
}

/// Header chuẩn KTX Food đồng bộ 100% theo Figma Prototype (Mục 6):
/// - Chiều cao chuẩn 66px, nền trắng 95% (#F2FFFFFF), viền dưới #f3f4f6
/// - Các nút thao tác tròn 44x44, nền #f9fafb:
///   + Nút Quay lại
///   + Nút Thông báo (chuông)
///   + Nút Giỏ hàng (shopping bag kèm badge)
///   + Nút Avatar / Đổi vai trò
/// - Tiêu đề căn chỉnh 16 Bold
class KtxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final KtxAppBarVariant variant;
  final int unreadNotificationCount;
  final int cartItemCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;
  final List<Widget>? actions;
  final bool showBackButton;
  final String? avatarUrl;

  const KtxAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.variant = KtxAppBarVariant.standard,
    this.unreadNotificationCount = 0,
    this.cartItemCount = 0,
    this.onNotificationTap,
    this.onCartTap,
    this.onAvatarTap,
    this.onLocationTap,
    this.actions,
    this.showBackButton = true,
    this.avatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66.0);

  Widget _buildCircleButton({
    required Widget child,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final btn = Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.headerBtnBackground, // #f9fafb
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    String? effectiveAvatarUrl = avatarUrl;
    if (effectiveAvatarUrl == null) {
      try {
        final authVm = Provider.of<AuthViewModel>(context, listen: true);
        effectiveAvatarUrl = authVm.currentUser?.avatarUrl;
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF), // Nền trắng 95% chuẩn Figma
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 66.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Nút quay lại tròn 44x44
                if (showBackButton && canPop) ...[
                  _buildCircleButton(
                    onTap: () => Navigator.of(context).maybePop(),
                    tooltip: 'Quay lại',
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Tiêu đề header hoặc Chọn địa điểm KTX (Home)
                Expanded(
                  child: variant == KtxAppBarVariant.homeHeader
                      ? InkWell(
                          onTap: onLocationTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFEDD5), // Cam nhạt #ffedd5
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      subtitle ?? 'GIAO ĐẾN',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9CA3AF),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: AppTypography.heading1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                subtitle!,
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                ),

                const SizedBox(width: 8),

                // Các nút bên phải: Chuông (44x44) + Giỏ hàng (44x44) + Avatar (44x44)
                if (variant != KtxAppBarVariant.authHeader) ...[
                  if (onNotificationTap != null) ...[
                    _buildCircleButton(
                      onTap: onNotificationTap,
                      tooltip: 'Thông báo',
                      child: Badge(
                        isLabelVisible: unreadNotificationCount > 0,
                        label: Text(
                          unreadNotificationCount > 99
                              ? '99+'
                              : '$unreadNotificationCount',
                          style: const TextStyle(fontSize: 9),
                        ),
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  if (onCartTap != null) ...[
                    _buildCircleButton(
                      onTap: onCartTap,
                      tooltip: 'Giỏ hàng gom đơn',
                      child: Badge(
                        isLabelVisible: cartItemCount > 0,
                        label: Text(
                          '$cartItemCount',
                          style: const TextStyle(fontSize: 9),
                        ),
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  if (actions != null) ...[
                    ...actions!,
                    if (actions!.isNotEmpty && onAvatarTap != null)
                      const SizedBox(width: 8),
                  ],

                  if (onAvatarTap != null)
                    _buildCircleButton(
                      onTap: onAvatarTap,
                      tooltip: 'Tài khoản / Đổi vai trò',
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFFFEDD5),
                        backgroundImage: (effectiveAvatarUrl != null && effectiveAvatarUrl.isNotEmpty)
                            ? NetworkImage(effectiveAvatarUrl)
                            : null,
                        child: (effectiveAvatarUrl == null || effectiveAvatarUrl.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
