import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Footer chuáº©n KTX Food:
/// - Chiá»u cao chuáº©n 56px, ná»n tráº¯ng #ffffff, viá»n trÃªn #f3f4f6
/// - 5 tab chuáº©n tÆ°Æ¡ng á»©ng:
///   Tab 0: KhÃ¡m phÃ¡ (Icon explore)
///   Tab 1: Äáº·t mÃ³n (Icon restaurant_menu)
///   Tab 2: ThÃ´ng bÃ¡o (Icon notifications kÃ¨m badge sá»‘ thÃ´ng bÃ¡o)
///   Tab 3: Lá»‹ch sá»­ (Icon history)
///   Tab 4: TÃ i khoáº£n (Icon person)
/// - Tab Ä‘ang chá»n mÃ u cam thÆ°Æ¡ng hiá»‡u #ff5722, tab khÃ´ng chá»n mÃ u xÃ¡m #9ca3af
class KtxBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int activeOrderBadgeCount;
  final int notificationBadgeCount;
  final int cartBadgeCount;

  const KtxBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeOrderBadgeCount = 0,
    this.notificationBadgeCount = 0,
    this.cartBadgeCount = 0,
  });

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? AppColors.primary
        : AppColors.chevron; // #ff5722 vs #9ca3af

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
      child: Semantics(
        identifier: 'nav_tab_$index',
        button: true,
        selected: isSelected,
        label: badgeCount > 0 ? 'Tab $label, $badgeCount má»¥c' : 'Tab $label',
        excludeSemantics: true,
        onTap: () => onTap(index),
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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
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
        child: SizedBox(
          height: 56.0,
          child: Row(
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: 'KhÃ¡m phÃ¡',
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.restaurant_outlined,
              activeIcon: Icons.restaurant,
              label: 'Äáº·t mÃ³n',
            ),
            _buildTabItem(
              index: 2,
              icon: Icons.shopping_bag_outlined,
              activeIcon: Icons.shopping_bag_rounded,
              label: 'Giá» hÃ ng',
              badgeCount: cartBadgeCount,
            ),
            _buildTabItem(
              index: 3,
              icon: Icons.access_time_rounded,
              activeIcon: Icons.access_time_filled_rounded,
              label: 'Lá»‹ch sá»­',
              badgeCount: activeOrderBadgeCount,
            ),
            _buildTabItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'TÃ i khoáº£n',
            ),
          ],
        ),
      ),
    ),
  );
}
}
