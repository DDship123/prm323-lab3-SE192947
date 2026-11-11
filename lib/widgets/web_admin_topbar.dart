import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Thanh Header trên cùng của Dashboard Admin (Web Top Bar) chuẩn Design System KTX Food
/// Tích hợp tìm kiếm nhanh, hiển thị ngày an toàn
class WebAdminTopbar extends StatelessWidget {
  final int activeTabIndex;
  final VoidCallback onRefresh;
  final VoidCallback? onToggleSidebar;
  final bool isMobile;
  final VoidCallback? onOpenDrawer;

  const WebAdminTopbar({
    super.key,
    required this.activeTabIndex,
    required this.onRefresh,
    this.onToggleSidebar,
    this.isMobile = false,
    this.onOpenDrawer,
  });

  String _formatDate(DateTime dt) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final wd = weekdays[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$wd, $d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Bảng Điều Khiển Tổng Quan KPI',
      'Xử Lý Khiếu Nại & Bồi Hoàn',
      'Giám Sát Toàn Bộ Đơn Hàng KTX',
      'Quản Lý Voucher & Khuyến Mãi KTX',
      'Quản Lý Tài Khoản & Người Dùng',
      'Quản Lý Quán Ăn & Đối Tác KTX',
      'Giám Sát & Báo Cáo Dòng Tiền KTX',
    ];
    final breadcrumbs = [
      'Hệ thống / Tổng quan KPI',
      'Nghiệp vụ / Xử lý Khiếu nại',
      'Nghiệp vụ / Giám sát Gom ca',
      'Cấu hình / Quản trị Voucher',
      'Đối tác & Người dùng / Quản lý Tài khoản',
      'Đối tác & Người dùng / Quán ăn Đối tác',
      'Tài chính / Giám sát Dòng tiền',
    ];

    final nowStr = _formatDate(DateTime.now());

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.sm : AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Nút mở Drawer trên Mobile
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 24),
              onPressed: onOpenDrawer,
              tooltip: 'Mở Menu Quản trị',
            ),
            const SizedBox(width: AppSpacing.xs),
          ],

          // Tiêu đề trang & Breadcrumb
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breadcrumbs[activeTabIndex],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  titles[activeTabIndex],
                  style: AppTypography.heading3.copyWith(
                    fontSize: isMobile ? 14 : 16,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (!isMobile) ...[
            const SizedBox(width: AppSpacing.lg),

            // Thanh tìm kiếm nhanh KTX Food
            Expanded(
              child: Container(
                height: 38,
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(Icons.search_rounded, size: 18, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm đơn hàng, mã sinh viên, món ăn...',
                          hintStyle: AppTypography.caption.copyWith(color: AppColors.textHint),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.roundedSm,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'Ctrl K',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Ngày hiện tại (An toàn, không bị LocaleDataException)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.roundedSm,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    nowStr,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),
          ],

          // Nút Refresh
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.roundedSm,
              ),
              child: const Icon(Icons.refresh_rounded, size: 17, color: AppColors.textPrimary),
            ),
            onPressed: onRefresh,
          ),

          // Nút Chuông thông báo
          Stack(
            children: [
              IconButton(
                tooltip: 'Thông báo hệ thống',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 17, color: AppColors.textPrimary),
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
