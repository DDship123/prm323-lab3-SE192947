import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Thành phần C04: KtxBottomNavBar hỗ trợ 4 Tabs: Home, Explore, Orders (có Badge), Profile
class KtxBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int activeOrderBadgeCount;

  const KtxBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeOrderBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'bottom_nav_bar',
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.45),
        elevation: 8,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppColors.primary),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon:
                Icon(Icons.notifications_rounded, color: AppColors.primary),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeOrderBadgeCount > 0,
              label: Text('$activeOrderBadgeCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeOrderBadgeCount > 0,
              label: Text('$activeOrderBadgeCount'),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            label: 'Đơn hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
