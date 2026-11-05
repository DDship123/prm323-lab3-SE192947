import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'restaurant_dashboard_screen.dart';
import 'restaurant_menu_management_screen.dart';
import 'restaurant_revenue_screen.dart';
import 'restaurant_store_settings_screen.dart';

/// Khung giao diện đa tab cho Chủ Quán KTX (Store Owner Shell)
/// Tích hợp thanh điều hướng Bottom Navigation Bar chuẩn Design System
class RestaurantShellScreen extends StatefulWidget {
  final String ownerId;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const RestaurantShellScreen({
    super.key,
    this.ownerId = '2',
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  State<RestaurantShellScreen> createState() => _RestaurantShellScreenState();
}

class _RestaurantShellScreenState extends State<RestaurantShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      RestaurantDashboardScreen(
        ownerId: widget.ownerId,
        onSwitchRole: widget.onSwitchRole,
        onSignOut: widget.onSignOut,
      ),
      RestaurantMenuManagementScreen(ownerId: widget.ownerId),
      RestaurantRevenueScreen(ownerId: widget.ownerId),
      RestaurantStoreSettingsScreen(ownerId: widget.ownerId),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.45),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.soup_kitchen_outlined),
            selectedIcon: Icon(Icons.soup_kitchen_rounded, color: AppColors.primary),
            label: 'Vận hành Bếp',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
            label: 'Thực đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            label: 'Doanh thu',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store_rounded, color: AppColors.primary),
            label: 'Cài đặt quán',
          ),
        ],
      ),
    );
  }
}
