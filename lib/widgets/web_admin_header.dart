import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Thanh Header và Điều hướng Responsive dành riêng cho Cổng Web Quản trị KTX (Web Admin)
class WebAdminHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const WebAdminHeader({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo & Tên Cổng Admin
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KTX FOOD ADMIN',
                    style: AppTypography.heading3.copyWith(
                      letterSpacing: 1.1,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Cổng Web Quản Trị Hệ Thống KTX ĐHQG',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 32),

          // Menu Tabs
          Expanded(
            child: Row(
              children: [
                _buildNavItem(0, 'Tổng quan KPI', Icons.dashboard_rounded),
                const SizedBox(width: 8),
                _buildNavItem(1, 'Trọng tài Khiếu nại', Icons.gavel_rounded),
                const SizedBox(width: 8),
                _buildNavItem(2, 'Giám sát Đơn hàng', Icons.receipt_long_rounded),
              ],
            ),
          ),

          // Profile & Actions
          Row(
            children: [
              if (onSwitchRole != null)
                TextButton.icon(
                  onPressed: onSwitchRole,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Đổi vai trò', style: TextStyle(fontSize: 13)),
                ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.person, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BQL KTX (Admin)',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                onPressed: onSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
