import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Footer chuẩn KTX Food:
/// - Chiều cao chuẩn 56px, nền trắng #ffffff, viền trên #f3f4f6
/// - 5 tab chuẩn tương ứng:
///   Tab 0: Khám phá (Icon explore)
///   Tab 1: Đặt món (Icon restaurant_menu)
///   Tab 2: Thông báo (Icon notifications kèm badge số thông báo)
///   Tab 3: Lịch sử (Icon history)
///   Tab 4: Tài khoản (Icon person)
/// - Tab đang chọn màu cam thương hiệu #ff5722, tab không chọn màu xám #9ca3af
class KtxBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int activeOrderBadgeCount;
  final int notificationBadgeCount;

  const KtxBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeOrderBadgeCount = 0,
    this.notificationBadgeCount = 0,
  });

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.chevron; // #ff5722 vs #9ca3af

    Widget iconWidget = Icon(
      isSelected ? activeIcon : icon,
      size: 22,
      color: color,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text('$badgeCount', style: const TextStyle(fontSize: 9)),
        backgroundColor: AppColors.primary,
        child: iconWidget,
      );
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.chipLabel.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'Khám phá',
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.restaurant_outlined,
              activeIcon: Icons.restaurant,
              label: 'Đặt món',
            ),
            _buildTabItem(
              index: 2,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Thanh toán',
            ),
            _buildTabItem(
              index: 3,
              icon: Icons.access_time_rounded,
              activeIcon: Icons.access_time_filled_rounded,
              label: 'Lịch sử',
              badgeCount: activeOrderBadgeCount,
            ),
            _buildTabItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
