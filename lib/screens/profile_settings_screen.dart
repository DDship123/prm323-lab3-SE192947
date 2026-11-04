import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';
import '../viewmodels/profile_demo_vm.dart';
import '../widgets/crash_confirm_dialog.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import 'dispute_history_screen.dart';
import 'dispute_refund_screen.dart';

/// Màn hình S13: Hồ sơ Sinh viên KTX & Khu vực Firebase Lab 3 Demo Area
class ProfileSettingsScreen extends StatelessWidget {
  final String displayName;
  final String email;
  final String uid;
  final String? photoUrl;
  final VoidCallback onSignOut;

  const ProfileSettingsScreen({
    super.key,
    required this.displayName,
    required this.email,
    required this.uid,
    this.photoUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final demoVm = context.watch<ProfileDemoViewModel>();
    final profile = authVm.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Hồ sơ & Firebase Demo S13'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? displayName,
                        style: AppTypography.heading3,
                      ),
                      Text(
                        profile?.email ?? email,
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phòng: ${profile?.ktxBuilding ?? 'Khu B - Tòa BA1'} - P.${profile?.ktxRoom ?? '312'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDisputeCard(context),
          const SizedBox(height: AppSpacing.md),
          _buildFirebaseDemoCard(context, demoVm),
          const SizedBox(height: AppSpacing.lg),
          KtxButton(
            label: 'Đăng xuất tài khoản',
            variant: KtxButtonVariant.danger,
            icon: Icons.logout_rounded,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Khiếu nại & Cloud Storage (S8 / S8b)',
                style: AppTypography.heading3,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tải ảnh bằng chứng món hỏng lên Firebase Cloud Storage (reports/{uid}/) và theo dõi tiến trình hoàn tiền.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: KtxButton(
                  label: 'Gửi khiếu nại S8',
                  icon: Icons.report_problem_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DisputeRefundScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: KtxButton(
                  label: 'Lịch sử S8b',
                  variant: KtxButtonVariant.outline,
                  icon: Icons.history_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DisputeHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseDemoCard(
    BuildContext context,
    ProfileDemoViewModel demoVm,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Firebase Lab 3 Demo Area (S13)',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: 4),
          Text(
            'Bảng điều khiển kiểm thử trực tiếp Remote Config, FCM và Crashlytics phục vụ chấm điểm Lab 3.',
            style: AppTypography.bodySmall,
          ),
          const Divider(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text('Remote Config: Banner Gom đơn 5.000đ'),
            subtitle: Text(
              demoVm.remoteConfigFreeShipBanner
                  ? 'Đang bật (Hiển thị trên Trang chủ S1)'
                  : 'Đang tắt',
            ),
            value: demoVm.remoteConfigFreeShipBanner,
            onChanged: (_) => demoVm.toggleRemoteConfigFreeShip(),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
            title: const Text('FCM Push Notification Simulator'),
            subtitle: Text(demoVm.fcmStatusMessage),
            trailing: OutlinedButton(
              onPressed: () {
                demoVm.simulateIncomingFcmPush();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã giả lập nhận FCM Push: Shipper đã tới cổng KTX!',
                    ),
                  ),
                );
              },
              child: const Text('Test FCM'),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.bug_report_outlined,
              color: AppColors.warning,
            ),
            title: const Text('Firebase Crashlytics Non-Fatal Log'),
            subtitle: Text(demoVm.lastCrashlyticsLog),
            trailing: OutlinedButton(
              onPressed: () {
                demoVm.triggerCrashlyticsNonFatalTest();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã ghi log Non-Fatal Exception!'),
                  ),
                );
              },
              child: const Text('Ghi Log'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Demo Crashlytics Fatal Crash',
                        style: AppTypography.heading4.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Nhấn nút để gây sập ứng dụng tức thì. Sau đó mở lại app để Crashlytics đồng bộ báo cáo lỗi lên Firebase Console.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                KtxButton(
                  label: '💥 Gây Crash App (Test Crashlytics)',
                  backgroundColor: AppColors.error,
                  onPressed: () {
                    CrashConfirmDialog.show(
                      context,
                      onConfirm: () => demoVm.triggerFatalCrashTest(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
