import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/profile_demo_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';

/// Màn hình S12: Bảng Thông báo Đơn hàng & Hệ thống (API-019, API-020, API-021, API-022)
class NotificationBoardScreen extends StatefulWidget {
  const NotificationBoardScreen({super.key});

  @override
  State<NotificationBoardScreen> createState() =>
      _NotificationBoardScreenState();
}

class _NotificationBoardScreenState extends State<NotificationBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileDemoViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileDemoViewModel>();
    final state = vm.notificationsState;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Trung tâm Thông báo S12',
        actions: [
          TextButton.icon(
            onPressed: vm.markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadNotifications,
        child: switch (state) {
          StateInitial() || StateLoading() => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: KtxLoadingState(itemCount: 3),
            ),
          StateError(:final errorMessage) => KtxErrorState(
              message: errorMessage,
              onRetry: vm.loadNotifications,
            ),
          StateEmpty(:final message) => KtxEmptyState(
              title: 'Chưa có thông báo',
              message: message,
            ),
          StateSuccess(:final data) => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: data.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, idx) => _buildNotificationTile(vm, data[idx]),
            ),
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    ProfileDemoViewModel vm,
    NotificationModel noti,
  ) {
    String timeStr;
    try {
      timeStr = DateFormat('HH:mm - dd/MM').format(noti.createdAt);
    } catch (_) {
      timeStr = '${noti.createdAt.hour.toString().padLeft(2, '0')}:${noti.createdAt.minute.toString().padLeft(2, '0')} - ${noti.createdAt.day.toString().padLeft(2, '0')}/${noti.createdAt.month.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: () {
        if (!noti.isRead) {
          vm.markAsRead(noti.id);
        }
      },
      borderRadius: AppRadius.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: noti.isRead
              ? AppColors.surface
              : AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: AppRadius.roundedMd,
          border: Border.all(
            color: noti.isRead ? AppColors.divider : AppColors.primary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              noti.type == 'DISPUTE_UPDATE'
                  ? Icons.published_with_changes_rounded
                  : Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          noti.title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: noti.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!noti.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(noti.body, style: AppTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text(timeStr, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
