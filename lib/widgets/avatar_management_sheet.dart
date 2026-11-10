import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';

/// Modal quản lý ảnh đại diện dùng chung cho cả 4 vai trò
/// (STUDENT, SHIPPER, STORE_OWNER, ADMIN)
class AvatarManagementSheet extends StatelessWidget {
  const AvatarManagementSheet({super.key});

  /// Hiển thị bottom sheet quản lý ảnh đại diện
  static Future<void> show(BuildContext context) async {
    final authVm = context.read<AuthViewModel>();
    final hasAvatar = authVm.currentUser?.avatarUrl != null &&
        authVm.currentUser!.avatarUrl!.isNotEmpty;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ảnh đại diện',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Chọn ảnh từ Thư viện'),
                subtitle: const Text('Tải ảnh có sẵn trên thiết bị'),
                onTap: () => Navigator.pop(bottomSheetContext, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Chụp ảnh mới bằng Camera'),
                subtitle: const Text('Sử dụng camera để chụp ảnh đại diện'),
                onTap: () => Navigator.pop(bottomSheetContext, 'camera'),
              ),
              if (hasAvatar) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text(
                    'Xóa ảnh đại diện',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Khôi phục về ảnh mặc định của hệ thống'),
                  onTap: () => Navigator.pop(bottomSheetContext, 'delete'),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    if (source == 'delete') {
      await _confirmAndDeleteAvatar(context);
    } else {
      final imageSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
      await _pickAndPreviewImage(context, imageSource);
    }
  }

  /// Xác nhận xóa ảnh đại diện và gọi API xóa
  static Future<void> _confirmAndDeleteAvatar(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa ảnh'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh đại diện hiện tại và quay về ảnh mặc định không?'),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            child: const Text('Xóa ảnh'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.removeAvatar();

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xóa ảnh đại diện thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVm.errorMessage ?? 'Không thể xóa ảnh đại diện. Vui lòng thử lại.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Chọn ảnh và mở Dialog xem trước trước khi upload
  static Future<void> _pickAndPreviewImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final fileSizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
              title: const Text(
                'Xem trước ảnh đại diện',
                textAlign: TextAlign.center,
                style: AppTypography.heading3,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Circular image preview
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.memory(
                        bytes,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    file.name,
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kích thước: $fileSizeKb KB',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  if (isSubmitting) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 10),
                        Text('Đang tải ảnh lên máy chủ...', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          final authVm = context.read<AuthViewModel>();
                          final success = await authVm.uploadAvatarFile(
                            bytes: bytes,
                            fileName: file.name,
                          );

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }

                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Đã cập nhật ảnh đại diện thành công!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authVm.errorMessage ?? 'Không thể tải ảnh đại diện lên máy chủ.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                  ),
                  child: const Text('Lưu làm ảnh đại diện'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
