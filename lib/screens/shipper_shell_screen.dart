import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'shipper_batch_pickup_screen.dart';
import 'shipper_route_screen.dart';
import 'shipper_wallet_screen.dart';
import 'shipper_shift_registration_screen.dart';

/// Khung giao diện đa tab cho Tài Xế Gom Đơn KTX (Shipper Shell)
/// Tích hợp thanh điều hướng Bottom Navigation Bar chuẩn Design System
class ShipperShellScreen extends StatefulWidget {
  final String shipperId;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const ShipperShellScreen({
    super.key,
    this.shipperId = '3',
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  State<ShipperShellScreen> createState() => _ShipperShellScreenState();
}

class _ShipperShellScreenState extends State<ShipperShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ShipperBatchPickupScreen(
        shipperId: widget.shipperId,
        onSwitchRole: widget.onSwitchRole,
        onSignOut: widget.onSignOut,
      ),
      const ShipperRouteScreen(),
      ShipperWalletScreen(shipperId: widget.shipperId),
      ShipperShiftRegistrationScreen(shipperId: widget.shipperId),
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
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded, color: AppColors.primary),
            label: 'Chuyến gom',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Lộ trình',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
            label: 'Ví thu nhập',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available_rounded, color: AppColors.primary),
            label: 'Đăng ký ca',
          ),
        ],
      ),
    );
  }
}
