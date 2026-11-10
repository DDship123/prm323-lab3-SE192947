import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  void initState() {
    super.initState();
    _loadSavedTab();
  }

  Future<void> _loadSavedTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('saved_owner_tab_index') ?? 0;
      if (mounted && savedIndex >= 0 && savedIndex <= 3) {
        setState(() => _currentIndex = savedIndex);
      }
    } catch (_) {}
  }

  Future<void> _onSelectTab(int index) async {
    setState(() => _currentIndex = index);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('saved_owner_tab_index', index);
    } catch (_) {}
  }

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
          onTap: () => _onSelectTab(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
    );
  }

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
      RestaurantStoreSettingsScreen(
        ownerId: widget.ownerId,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
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
          child: SizedBox(
            height: 56.0,
            child: Row(
              children: [
                _buildTabItem(
                  index: 0,
                  icon: Icons.soup_kitchen_outlined,
                  activeIcon: Icons.soup_kitchen_rounded,
                  label: 'Bếp & Gom ca',
                ),
                _buildTabItem(
                  index: 1,
                  icon: Icons.restaurant_menu_outlined,
                  activeIcon: Icons.restaurant_menu_rounded,
                  label: 'Thực đơn',
                ),
                _buildTabItem(
                  index: 2,
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Doanh thu & COD',
                ),
                _buildTabItem(
                  index: 3,
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store_rounded,
                  label: 'Cài đặt quán',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

