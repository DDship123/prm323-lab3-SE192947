import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';

/// Hộp thoại cảnh báo và xác nhận trước khi gây sập ứng dụng (Fatal Crash)
class CrashConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CrashConfirmDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<bool?> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CrashConfirmDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Xác nhận kiểm thử Crashlytics',
              style: AppTypography.heading3.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Thao tác này sẽ cố tình gây sập (Fatal Crash) ứng dụng ngay lập tức.\n\nSau khi ứng dụng văng ra ngoài, vui lòng mở lại ứng dụng để Crashlytics đồng bộ báo cáo lỗi lên Firebase Console.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy bỏ'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: KtxButton(
                    label: 'Gây Crash',
                    variant: KtxButtonVariant.danger,
                    icon: Icons.flash_on_rounded,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
