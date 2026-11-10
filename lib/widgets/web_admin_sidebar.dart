import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';
import 'avatar_management_sheet.dart';

/// Menu thanh bên (Left Vertical Sidebar) chuẩn Design System KTX Food (Figma Lab 2 & 3)
/// Đồng bộ 100% với nhận diện màu Cam KTX (#FF5722), Typography và Token thiết kế
class WebAdminSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const WebAdminSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    UserModel? currentUser;
    try {
      currentUser = context.watch<AuthViewModel>().currentUser;
    } catch (_) {}

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.fastOutSlowIn,
        width: isCollapsed ? 76 : 260,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ================= 1. HEADER THƯƠNG HIỆU KTX FOOD =================
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: isCollapsed
                ? Center(
                    child: InkWell(
                      onTap: onToggleCollapse,
                      borderRadius: AppRadius.roundedMd,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'KTX FOOD ADMIN',
                              style: AppTypography.heading3.copyWith(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Cổng Web Quản Trị KTX',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Thu gọn menu',
                        icon: const Icon(
                          Icons.menu_open_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: onToggleCollapse,
                      ),
                    ],
                  ),
          ),

          // ================= 2. DANH SÁCH MỤC ĐIỀU HƯỚNG =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              children: [
                if (!isCollapsed) _buildSectionLabel('TỔNG QUAN'),
                _buildMenuItem(
                  index: 0,
                  title: 'Bảng Điều Khiển',
                  icon: Icons.dashboard_rounded,
                ),
                SizedBox(height: isCollapsed ? 6 : AppSpacing.sm),

                if (!isCollapsed) _buildSectionLabel('NGHIỆP VỤ QUẢN TRỊ'),
                _buildMenuItem(
                  index: 1,
                  title: 'Xử Lý Khiếu Nại',
                  icon: Icons.assignment_late_rounded,
                  badgeText: '3 chờ',
                  badgeColor: AppColors.error,
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  index: 2,
                  title: 'Giám Sát Đơn Hàng',
                  icon: Icons.receipt_long_rounded,
                  badgeText: 'Ca trưa',
                  badgeColor: AppColors.primary,
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  index: 3,
                  title: 'Quản Lý Voucher',
                  icon: Icons.confirmation_num_rounded,
                  badgeText: 'Ưu đãi',
                  badgeColor: AppColors.success,
                ),
                SizedBox(height: isCollapsed ? 6 : AppSpacing.sm),
                if (!isCollapsed) _buildSectionLabel('ĐỐI TÁC & NGƯỜI DÙNG'),
                _buildMenuItem(
                  index: 4,
                  title: 'Quản Lý Người Dùng',
                  icon: Icons.people_alt_rounded,
                  badgeText: 'RBAC',
                  badgeColor: Colors.blue,
                ),
                const SizedBox(height: 4),
                _buildMenuItem(
                  index: 5,
                  title: 'Quán Ăn Đối Tác',
                  icon: Icons.storefront_rounded,
                  badgeText: 'KTX',
                  badgeColor: AppColors.primary,
                ),
                SizedBox(height: isCollapsed ? 6 : AppSpacing.sm),
                if (!isCollapsed) _buildSectionLabel('TÀI CHÍNH'),
                _buildMenuItem(
                  index: 6,
                  title: 'Giám Sát Dòng Tiền',
                  icon: Icons.account_balance_wallet_rounded,
                  badgeText: 'Dòng tiền',
                  badgeColor: AppColors.success,
                ),
                SizedBox(height: isCollapsed ? 6 : AppSpacing.sm),

                if (!isCollapsed) ...[
                  _buildSectionLabel('HỆ THỐNG & KẾT NỐI'),
                  _buildStaticMenuItem(
                    title: 'Máy Chủ VPS TP.HCM',
                    subtitle: '103.179.189.120',
                    icon: Icons.dns_rounded,
                    statusColor: AppColors.success,
                    statusText: 'Online',
                  ),
                  const SizedBox(height: 4),
                  _buildStaticMenuItem(
                    title: 'Firebase Crashlytics',
                    subtitle: 'Giám sát lỗi di động',
                    icon: Icons.bug_report_rounded,
                    statusColor: AppColors.info,
                    statusText: 'Active',
                  ),
                ] else ...[
                  Tooltip(
                    message: 'VPS Online: 103.179.189.120',
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: const Icon(
                          Icons.dns_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ================= 3. THẺ ADMIN & ĐỔI VAI TRÒ / ĐĂNG XUẤT =================
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: isCollapsed
                ? Center(
                    child: PopupMenuButton<String>(
                      tooltip: 'Ban Quản Lý KTX',
                      offset: const Offset(60, -80),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedMd,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'avatar',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Đổi ảnh đại diện', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'avatar') {
                          AvatarManagementSheet.show(context);
                        } else if (val == 'logout') {
                          onSignOut();
                        }
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(currentUser.avatarUrl!)
                            : null,
                        child: (currentUser?.avatarUrl == null || currentUser!.avatarUrl!.isEmpty)
                            ? const Text(
                                'BQL',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Tooltip(
                              message: 'Đổi ảnh đại diện',
                              child: InkWell(
                                onTap: () => AvatarManagementSheet.show(context),
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primary,
                                      backgroundImage: (currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty)
                                          ? NetworkImage(currentUser.avatarUrl!)
                                          : null,
                                      child: (currentUser?.avatarUrl == null || currentUser!.avatarUrl!.isEmpty)
                                          ? const Text(
                                              'BQL',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryDark,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, size: 8, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser?.displayName ?? 'BQL KTX ĐHQG',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentUser?.email ?? 'admin.ktx@fpt.edu.vn',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: onSignOut,
                                borderRadius: AppRadius.roundedSm,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Đăng xuất',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required String title,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = selectedIndex == index;

    if (isCollapsed) {
      return Tooltip(
        message: title,
        preferBelow: false,
        child: InkWell(
          onTap: () => onTabSelected(index),
          borderRadius: AppRadius.roundedSm,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                if (badgeText != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: AppRadius.roundedSm,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppRadius.roundedSm,
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.primary,
                  borderRadius: AppRadius.roundedFull,
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaticMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color statusColor,
    required String statusText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: AppRadius.roundedSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.roundedFull,
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
