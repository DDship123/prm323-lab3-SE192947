import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/evidence_upload_service.dart';
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
import '../widgets/ktx_text_field.dart';
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
                InkWell(
                  onTap: () => _pickAndUploadAvatar(context),
                  borderRadius: BorderRadius.circular(34),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primaryLight.withValues(
                          alpha: 0.4,
                        ),
                        backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(profile.avatarUrl!)
                            : (photoUrl != null && photoUrl!.isNotEmpty
                                ? NetworkImage(photoUrl!)
                                : null),
                        child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty) && (photoUrl == null || photoUrl!.isEmpty)
                            ? const Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            profile?.phone ?? 'Chưa cập nhật SĐT',
                            style: AppTypography.caption.copyWith(
                              color: (profile?.phone != null && profile!.phone!.isNotEmpty)
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
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
                IconButton(
                  tooltip: 'Chỉnh sửa thông tin cá nhân',
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                  onPressed: () => _showEditProfileModal(context, profile, authVm),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPersonalInfoCard(context, profile, authVm),
          const SizedBox(height: AppSpacing.md),
          _buildDisputeCard(context),
          const SizedBox(height: AppSpacing.md),
          _buildFirebaseDemoCard(context, demoVm),
          const SizedBox(height: AppSpacing.md),
          KtxButton(
            label: 'Đăng xuất tài khoản',
            variant: KtxButtonVariant.danger,
            icon: Icons.logout_rounded,
            onPressed: onSignOut,
            semanticsId: 'btn_sign_out',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    BuildContext context,
    UserModel? profile,
    AuthViewModel authVm,
  ) {
    final currentPhone = profile?.phone;
    final currentBuilding = profile?.ktxBuilding ?? 'Khu B - Tòa BA1';
    final currentRoom = profile?.ktxRoom ?? '312';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Thông Tin Cá Nhân & KTX',
                    style: AppTypography.heading3,
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showEditProfileModal(context, profile, authVm),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('Chỉnh sửa'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thông tin dùng để Shipper giao món tận phòng và liên hệ khi giao nhận đơn hàng.',
            style: AppTypography.bodySmall,
          ),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            title: 'Họ và tên',
            value: profile?.displayName ?? displayName,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.phone_android_rounded,
            title: 'Số điện thoại',
            value: (currentPhone != null && currentPhone.isNotEmpty)
                ? currentPhone
                : 'Chưa cập nhật (Bấm để thêm)',
            isHighlight: currentPhone == null || currentPhone.isEmpty,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.email_outlined,
            title: 'Email đăng nhập',
            value: profile?.email ?? email,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.apartment_rounded,
            title: 'Tòa nhà KTX',
            value: currentBuilding,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.meeting_room_outlined,
            title: 'Số phòng KTX',
            value: 'Phòng $currentRoom',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: KtxButton(
              label: 'Chỉnh sửa thông tin cá nhân',
              icon: Icons.edit_rounded,
              variant: KtxButtonVariant.outline,
              onPressed: () => _showEditProfileModal(context, profile, authVm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isHighlight ? AppColors.warning : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileModal(
    BuildContext context,
    UserModel? profile,
    AuthViewModel authVm,
  ) async {
    final nameController = TextEditingController(
      text: profile?.displayName ?? displayName,
    );
    final phoneController = TextEditingController(
      text: profile?.phone ?? '',
    );
    final roomController = TextEditingController(
      text: profile?.ktxRoom ?? '312',
    );

    final ktxBuildingOptions = [
      'Khu B - Tòa BA1',
      'Khu B - Tòa BA2',
      'Khu B - Tòa BA3',
      'Khu B - Tòa BA4',
      'Khu B - Tòa B3',
      'Khu B - Tòa B4',
      'Khu A - Tòa A1',
      'Khu A - Tòa A2',
      'Khu A - Tòa A3',
    ];

    String selectedBuilding = profile?.ktxBuilding ?? 'Khu B - Tòa BA1';
    if (!ktxBuildingOptions.contains(selectedBuilding)) {
      ktxBuildingOptions.insert(0, selectedBuilding);
    }

    bool isSubmitting = false;
    String? formError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final mediaQuery = MediaQuery.of(ctx);
            final bottomInset = mediaQuery.viewInsets.bottom;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: AppSpacing.md + bottomInset,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.3),
                                borderRadius: AppRadius.roundedSm,
                              ),
                              child: const Icon(
                                Icons.manage_accounts_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cấu hình thông tin cá nhân',
                                    style: AppTypography.heading3,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Đồng bộ với hệ thống KTX & giao nhận',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.lg),
                        if (formError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight.withValues(alpha: 0.2),
                              borderRadius: AppRadius.roundedSm,
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formError!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        KtxTextField(
                          controller: nameController,
                          label: 'Họ và tên sinh viên',
                          hintText: 'Nhập họ và tên đầy đủ',
                          prefixIcon: Icons.person_rounded,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KtxTextField(
                          controller: phoneController,
                          label: 'Số điện thoại',
                          hintText: 'Ví dụ: 0981234567',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_rounded,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tòa nhà KTX',
                          style: AppTypography.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.roundedSm,
                            border: Border.all(color: AppColors.borderStrong),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBuilding,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: ktxBuildingOptions.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b,
                                  child: Text(b, style: AppTypography.bodySmall),
                                );
                              }).toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedBuilding = val;
                                        });
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KtxTextField(
                          controller: roomController,
                          label: 'Số phòng KTX',
                          hintText: 'Ví dụ: 312, 405,...',
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.door_front_door_outlined,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: KtxButton(
                                label: 'Hủy',
                                variant: KtxButtonVariant.outline,
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(ctx).pop(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: KtxButton(
                                label: isSubmitting ? 'Đang lưu...' : 'Lưu thay đổi',
                                icon: isSubmitting ? null : Icons.check_circle_outline_rounded,
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final trimmedName = nameController.text.trim();
                                        final trimmedPhone = phoneController.text.trim();
                                        final trimmedRoom = roomController.text.trim();

                                        if (trimmedName.isEmpty) {
                                          setModalState(() {
                                            formError = 'Vui lòng nhập họ và tên';
                                          });
                                          return;
                                        }

                                        if (trimmedPhone.isEmpty) {
                                          setModalState(() {
                                            formError = 'Vui lòng nhập số điện thoại';
                                          });
                                          return;
                                        }

                                        if (!RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$').hasMatch(trimmedPhone)) {
                                          setModalState(() {
                                            formError = 'Số điện thoại không đúng định dạng VN (10 chữ số, ví dụ 0981234567)';
                                          });
                                          return;
                                        }

                                        if (trimmedRoom.isEmpty) {
                                          setModalState(() {
                                            formError = 'Vui lòng nhập số phòng KTX';
                                          });
                                          return;
                                        }

                                        setModalState(() {
                                          isSubmitting = true;
                                          formError = null;
                                        });

                                        final success = await authVm.updateProfile(
                                          displayName: trimmedName,
                                          phone: trimmedPhone,
                                          ktxBuilding: selectedBuilding,
                                          ktxRoom: trimmedRoom,
                                        );

                                        if (!ctx.mounted) return;

                                        if (success) {
                                          Navigator.of(ctx).pop();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '🎉 Đã lưu thông tin cá nhân & KTX thành công!',
                                                ),
                                                backgroundColor: AppColors.success,
                                              ),
                                            );
                                          }
                                        } else {
                                          setModalState(() {
                                            isSubmitting = false;
                                            formError = authVm.errorMessage ?? 'Không thể cập nhật hồ sơ';
                                          });
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
                'Khiếu nại & Bằng chứng',
                style: AppTypography.heading3,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tải ảnh bằng chứng món hỏng lên Firebase Cloud Storage và theo dõi tiến trình hoàn tiền.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                child: KtxButton(
                  label: 'Gửi khiếu nại',
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
                  label: 'Lịch sử khiếu nại',
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
              'Trung Tâm Kiểm Thử Firebase',
              style: AppTypography.heading3,
            ),
            const SizedBox(height: 4),
            Text(
              'Bảng điều khiển kiểm thử trực tiếp Remote Config, FCM, Crashlytics và Analytics phục vụ hệ thống.',
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
              subtitle: const Text(
                'Gửi tức thì 8 sự kiện đo lường lên Firebase Console',
              ),
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
                  Text(
                    '• Banner Trang chủ: ${remoteConfig.promoBannerEnabled ? "BẬT" : "TẮT"}',
                  ),
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
                  final updated = await context
                      .read<RemoteConfigService>()
                      .fetchAndActivate();
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
                      label: const Text('Test FCM Đơn hàng'),
                      onPressed: () {
                        final noti = demoVm.simulateIncomingFcmPush(
                          type: 'ORDER_STATUS',
                          appState: 'FOREGROUND',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🔔 Đã nhận thông báo: ${noti.title}\nNhấn "Xem ngay" hoặc mở Bảng thông báo để chuyển màn hình.',
                            ),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'Xem ngay',
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
                      icon: const Icon(
                        Icons.published_with_changes_rounded,
                        size: 18,
                      ),
                      label: const Text('Test FCM Khiếu nại'),
                      onPressed: () {
                        final noti = demoVm.simulateIncomingFcmPush(
                          type: 'DISPUTE_UPDATE',
                          appState: 'FOREGROUND',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🔔 Đã nhận thông báo: ${noti.title}\nNhấn "Xem ngay" hoặc mở Bảng thông báo để chuyển màn hình.',
                            ),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'Xem ngay',
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
                    Exception(
                      'HandledPaymentTimeoutException: Simulated timeout after 30s',
                    ),
                    StackTrace.current,
                    reason: 'Thử nghiệm ghi log Non-Fatal Error tại S13 Hồ sơ',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Đã gửi Non-Fatal Error lên Firebase Crashlytics!',
                        ),
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
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Demo Crashlytics Fatal Crash',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
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

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Chọn ảnh từ Thư viện máy'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Chụp ảnh mới bằng Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải ảnh đại diện lên máy chủ...')),
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final uploadService = EvidenceUploadService();
      final url = await uploadService.uploadEvidence(
        bytes: bytes,
        fileName: file.name,
        userId: uid,
      );

      if (context.mounted) {
        final authVm = context.read<AuthViewModel>();
        await authVm.updateAvatar(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật ảnh đại diện từ máy lên thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh đại diện lên: '),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
