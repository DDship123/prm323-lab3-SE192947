import 'package:flutter/material.dart';
import '../models/user_role_enum.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class RoleSelectionBottomSheet extends StatelessWidget {
  final UserAppRole currentRole;
  final ValueChanged<UserAppRole> onRoleSelected;

  const RoleSelectionBottomSheet({
    super.key,
    required this.currentRole,
    required this.onRoleSelected,
  });

  static Future<UserAppRole?> show(
    BuildContext context, {
    required UserAppRole currentRole,
  }) {
    return showModalBottomSheet<UserAppRole>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RoleSelectionBottomSheet(
        currentRole: currentRole,
        onRoleSelected: (role) => Navigator.pop(ctx, role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn vai trò trải nghiệm KTX Food', style: AppTypography.heading3),
            const SizedBox(height: 4),
            Text(
              'Chuyển đổi linh hoạt giữa 4 vai trò để kiểm thử toàn diện luồng nghiệp vụ',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            ...UserAppRole.values.map((role) {
              final isSelected = role == currentRole;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected ? AppColors.primaryLight.withOpacity(0.3) : AppColors.surface,
                  borderRadius: AppRadius.roundedMd,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.roundedMd,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                      child: Icon(
                        _getRoleIcon(role),
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    title: Text(
                      role.labelVi,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(role.defaultEmail, style: AppTypography.bodySmall),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => onRoleSelected(role),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserAppRole role) {
    switch (role) {
      case UserAppRole.student:
        return Icons.school_rounded;
      case UserAppRole.storeOwner:
        return Icons.storefront_rounded;
      case UserAppRole.shipper:
        return Icons.two_wheeler_rounded;
      case UserAppRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}