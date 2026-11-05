import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../firebase/crashlytics_service.dart';
import '../firebase/remote_config_service.dart';
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
import 'notification_board_screen.dart';

/// Màn hình S13: Hồ sơ Sinh viên KTX & Khu vực Firebase Lab 3 Demo Area
class ProfileSettingsScreen extends StatelessWidget {
  final String displayName;
  final String email;
  final String uid;
  final String? photoUrl;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const ProfileSettingsScreen({
    super.key,
    required this.displayName,
    required this.email,
    required this.uid,
    this.photoUrl,
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final demoVm = context.watch<ProfileDemoViewModel>();
    final profile = authVm.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Tài Khoản'),
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
          if (onSwitchRole != null) ...[
            const SizedBox(height: AppSpacing.md),
            KtxButton(
              label: 'Đổi vai trò người dùng (Demo)',
              variant: KtxButtonVariant.outline,
              icon: Icons.swap_horiz_rounded,
              onPressed: onSwitchRole,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
    final remoteConfig = context.watch<RemoteConfigService>();
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
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
            'Bảng điều khiển kiểm thử trực tiếp Remote Config, FCM, Crashlytics và Analytics phục vụ chấm điểm Lab 3.',
            style: AppTypography.bodySmall,
          ),
          const Divider(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.analytics_rounded,
              color: Colors.blue,
              size: 32,
            ),
            title: const Text(
              'Bắn 8 sự kiện lên DebugView',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Gửi tức thì 8 sự kiện đo lường lên Firebase Console'),
            trailing: FilledButton.tonal(
              onPressed: () => _triggerAllAnalyticsEvents(context),
              child: const Text('Bắn 8 Sự Kiện'),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.cloud_sync_outlined,
              color: Colors.teal,
              size: 32,
            ),
            title: const Text(
              'Firebase Remote Config',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('• Banner Trang chủ S1: ${remoteConfig.promoBannerEnabled ? "BẬT" : "TẮT"}'),
                Text('• Phí ship gom đơn: ${remoteConfig.groupShipFee}đ'),
                Text(
                  '• Nội dung banner: "${remoteConfig.promoBannerText}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: FilledButton.tonal(
              onPressed: () async {
                final updated = await context.read<RemoteConfigService>().fetchAndActivate();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        updated
                            ? '🎉 Đã cập nhật giá trị mới từ Firebase Remote Config!'
                            : 'Đã kích hoạt cấu hình mới nhất từ Firebase Console.',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
              child: const Text('Fetch & Activate'),
            ),
          ),
          const Divider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
                title: const Text(
                  'Firebase Cloud Messaging (FCM)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('• Trạng thái: ${demoVm.fcmStatusMessage}'),
                    Text(
                      '• FCM Token: ${demoVm.fcmToken ?? "Đang lấy token..."}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                trailing: demoVm.fcmToken != null
                    ? IconButton(
                        tooltip: 'Copy FCM Token',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: demoVm.fcmToken!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '📋 Đã copy FCM Token vào Clipboard! Có thể dán vào Firebase Console.',
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text('Test FCM Đơn hàng (S6)'),
                    onPressed: () {
                      final noti = demoVm.simulateIncomingFcmPush(
                        type: 'ORDER_STATUS',
                        appState: 'FOREGROUND',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🔔 Đã lưu vào S12: ${noti.title}\nNhấn "Xem ngay" hoặc mở tab Thông báo S12 để chuyển màn hình.',
                          ),
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Xem ngay (S6)',
                            textColor: Colors.amberAccent,
                            onPressed: () {
                              demoVm.markAsRead(noti.id);
                              NotificationBoardScreen.navigateByNotificationType(
                                context,
                                type: noti.type,
                                dataPayload: noti.dataPayload,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.published_with_changes_rounded, size: 18),
                    label: const Text('Test FCM Khiếu nại (S8b)'),
                    onPressed: () {
                      final noti = demoVm.simulateIncomingFcmPush(
                        type: 'DISPUTE_UPDATE',
                        appState: 'FOREGROUND',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🔔 Đã lưu vào S12: ${noti.title}\nNhấn "Xem ngay" hoặc mở tab Thông báo S12 để chuyển màn hình.',
                          ),
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Xem ngay (S8b)',
                            textColor: Colors.amberAccent,
                            onPressed: () {
                              demoVm.markAsRead(noti.id);
                              NotificationBoardScreen.navigateByNotificationType(
                                context,
                                type: noti.type,
                                dataPayload: noti.dataPayload,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
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
              onPressed: () async {
                demoVm.triggerCrashlyticsNonFatalTest();
                await context.read<CrashlyticsService>().recordNonFatalError(
                      Exception('HandledPaymentTimeoutException: Simulated timeout after 30s'),
                      StackTrace.current,
                      reason: 'Thử nghiệm ghi log Non-Fatal Error tại S13 Hồ sơ',
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã gửi Non-Fatal Error lên Firebase Crashlytics!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
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
                        style: AppTypography.heading3.copyWith(color: AppColors.error, fontSize: 14),
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
                  variant: KtxButtonVariant.danger,
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
    ),
    );
  }

  Future<void> _triggerAllAnalyticsEvents(BuildContext context) async {
    final analytics = context.read<AnalyticsService>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang gửi 8 sự kiện lên Firebase DebugView...'),
        duration: Duration(seconds: 2),
      ),
    );

    // 1. login
    await analytics.logSignIn(method: 'google', campusZone: 'KTX_KHU_B');
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. search
    await analytics.logSearch(
      searchTerm: 'Cơm tấm sườn bì',
      campusZone: 'KTX_KHU_B',
      resultCount: 3,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. view_store_detail
    await analytics.logViewStoreDetail(
      storeId: 101,
      storeCategory: 'KTX_KHU_B',
      ratingAvg: 4.8,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. add_to_cart
    await analytics.logAddToCart(
      menuItemId: 501,
      storeId: 101,
      quantity: 2,
      unitPrice: 35000,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // 5. begin_checkout
    await analytics.logBeginCheckout(
      itemCount: 2,
      subtotalAmount: 70000,
      shippingFee: 5000,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // 6. purchase
    await analytics.logPurchase(
      orderId: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
      totalValue: 75000,
      paymentMethod: 'VIETQR',
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // 7. upload_dispute_evidence
    await analytics.logUploadDisputeEvidence(
      orderId: 'ORD_DEMO_KTX',
      reasonCode: 'MISSING_ITEM',
      refundRequested: 35000,
      uploadStatus: 'success',
    );
    await Future.delayed(const Duration(milliseconds: 300));

    // 8. sign_out
    await analytics.logSignOut(sessionType: 'authenticated');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 Đã gửi thành công đủ 8 sự kiện! Hãy kiểm tra dòng thời gian trên Firebase DebugView.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
