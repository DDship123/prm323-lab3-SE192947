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

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFFF521B) : const Color(0xFF94A3B8);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 56.0,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
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
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping_rounded,
                label: 'Chuyến gom',
              ),
              _buildTabItem(
                index: 1,
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Lộ trình',
              ),
              _buildTabItem(
                index: 2,
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Ví thu nhập',
              ),
              _buildTabItem(
                index: 3,
                icon: Icons.event_available_outlined,
                activeIcon: Icons.event_available_rounded,
                label: 'Đăng ký ca',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

