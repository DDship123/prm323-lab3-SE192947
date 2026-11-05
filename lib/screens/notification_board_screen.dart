import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
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
import 'dispute_history_screen.dart';
import 'live_order_tracking_screen.dart';

/// Màn hình S12: Bảng Thông báo Đơn hàng & Danh sách Thông báo FCM đã nhận (API-019 -> API-022)
class NotificationBoardScreen extends StatefulWidget {
  const NotificationBoardScreen({super.key});

  /// Hàm điều hướng chung khi người dùng nhấn vào thông báo (từ danh sách S12 hoặc từ FCM Push)
  static void navigateByNotificationType(
    BuildContext context, {
    required String type,
    String? dataPayload,
  }) {
    if (type == 'DISPUTE_UPDATE') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DisputeHistoryScreen()),
      );
      return;
    }

    // Mặc định điều hướng sang màn hình Theo dõi đơn hàng trực tiếp S6
    final orderId = int.tryParse(dataPayload ?? '') ?? 101;
    final demoOrder = OrderDetailModel(
      id: orderId,
      orderCode: 'ORD-KTX-$orderId',
      userId: 1,
      storeId: 101,
      storeName: 'Cơm Tấm Phúc Lộc Thọ – KTX Khu B',
      slotTime: 'CA_TRUA_11H30',
      pickupLocation: 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
      subtotalAmount: 70000,
      deliveryFee: 5000,
      groupDiscountAmount: 10000,
      finalAmount: 65000,
      status: 'DELIVERING',
      paymentMethod: 'VIETQR',
      paymentStatus: 'PAID',
      pickupQrCode: 'KTX_QR_ORD_$orderId',
      pickupPin: '4829',
      note: 'Giao tại cổng B2 đúng 11h30',
      items: const [
        OrderItemModel(
          id: 1,
          menuItemId: 501,
          itemName: 'Cơm sườn bì chả đặc biệt',
          unitPrice: 35000,
          quantity: 2,
          selectedOptions: [],
          itemTotalAmount: 70000,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveOrderTrackingScreen(initialOrder: demoOrder),
      ),
    );
  }

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
    final timeStr = DateFormat('HH:mm - dd/MM').format(noti.createdAt);
    final isDispute = noti.type == 'DISPUTE_UPDATE';

    return InkWell(
      onTap: () {
        if (!noti.isRead) {
          vm.markAsRead(noti.id);
        }
        NotificationBoardScreen.navigateByNotificationType(
          context,
          type: noti.type,
          dataPayload: noti.dataPayload,
        );
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
              isDispute
                  ? Icons.published_with_changes_rounded
                  : Icons.notifications_active_outlined,
              color: isDispute ? Colors.deepOrange : AppColors.primary,
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(timeStr, style: AppTypography.bodySmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDispute
                              ? Colors.deepOrange.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Text(
                          isDispute
                              ? '👉 Xem Khiếu nại (S8b)'
                              : '👉 Theo dõi đơn (S6)',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDispute
                                ? Colors.deepOrange
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
