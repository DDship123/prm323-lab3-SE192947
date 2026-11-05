import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shipper_batch_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/shipper_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'shipper_handover_confirm_screen.dart';
import 'shipper_pickup_detail_screen.dart';
import 'shipper_route_screen.dart';
import 'shipper_shift_registration_screen.dart';
import 'shipper_shift_summary_screen.dart';
import 'shipper_wallet_screen.dart';

class ShipperBatchPickupScreen extends StatefulWidget {
  final String shipperId;
  final VoidCallback? onSwitchRole;
  final VoidCallback? onSignOut;

  const ShipperBatchPickupScreen({
    super.key,
    this.shipperId = '3',
    this.onSwitchRole,
    this.onSignOut,
  });

  @override
  State<ShipperBatchPickupScreen> createState() => _ShipperBatchPickupScreenState();
}

class _ShipperBatchPickupScreenState extends State<ShipperBatchPickupScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipperViewModel>().fetchBatch(shipperId: widget.shipperId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipperViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Bảng giao nhận tại Cổng KTX',
        actions: [
          IconButton(
            tooltip: 'Ví Thu nhập & Đối soát',
            icon: const Icon(Icons.account_balance_wallet_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShipperWalletScreen(shipperId: widget.shipperId),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => vm.fetchBatch(shipperId: widget.shipperId),
          ),
          if (widget.onSwitchRole != null)
            IconButton(
              tooltip: 'Đổi vai trò',
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: widget.onSwitchRole,
            ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: widget.onSignOut,
            ),
        ],
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const KtxLoadingState(message: 'Đang tải lộ trình gom hàng KTX...'),
        StateEmpty(message: final msg) => KtxEmptyState(
            icon: Icons.two_wheeler_outlined,
            title: 'Chưa có đơn gom',
            message: msg,
          ),
        StateError(errorMessage: final err) => KtxErrorState(
            errorMessage: err,
            onRetry: () => vm.fetchBatch(shipperId: widget.shipperId),
          ),
        StateSuccess(data: final batch) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildBatchSummaryCard(batch),
              const SizedBox(height: AppSpacing.md),
              Text('Danh sách đơn gom cần giao:', style: AppTypography.heading3),
              const SizedBox(height: AppSpacing.sm),
              ...batch.orders.map((o) => _buildShipperOrderCard(o, vm)),
            ],
          ),
      },
    );
  }

  Widget _buildBatchSummaryCard(ShipperBatchModel batch) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.4),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chuyến gom: Ca Trưa 11:30', style: AppTypography.heading3),
              Text('${batch.totalOrders} đơn', style: AppTypography.heading3.copyWith(color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Điểm tập kết: ${batch.campusZone}', style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Text('Thù lao ước tính: ${currencyFormatter.format(batch.totalDeliveryEarnings)}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.route, size: 16, color: AppColors.primary),
                  label: const Text('Lộ trình gom hàng', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShipperRouteScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  label: const Text('Đăng ký ca', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperShiftRegistrationScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.assessment, size: 16, color: AppColors.primary),
                  label: const Text('Tổng kết ca', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperShiftSummaryScreen(shipperId: widget.shipperId),
                      ),
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

  Widget _buildShipperOrderCard(ShipperBatchItemModel order, ShipperViewModel vm) {
    final isDelivering = order.status == 'DELIVERING';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedMd,
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn #${order.orderCode}', style: AppTypography.heading3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivering ? AppColors.primaryLight : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: isDelivering ? AppColors.primaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Quán: ${order.storeName} (${order.storeAddress})', style: AppTypography.bodySmall),
            Text('Người nhận: ${order.customerName} - ${order.customerPhone}', style: AppTypography.bodySmall),
            Text('PIN đối soát: ${order.pickupPin ?? "4567"}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currencyFormatter.format(order.finalAmount),
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                if (!isDelivering)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShipperPickupDetailScreen(
                                order: order,
                                onPickupConfirmed: () {
                                  vm.confirmPickup(
                                    orderId: order.orderId,
                                    shipperId: widget.shipperId,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: const Text('Chi tiết quán', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      KtxButton(
                        label: 'Lấy hàng',
                        icon: Icons.check_circle_outline,
                        onPressed: () async {
                          await vm.confirmPickup(
                            orderId: order.orderId,
                            shipperId: widget.shipperId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã nhận đơn tại quán! Bắt đầu giao KTX.')),
                          );
                        },
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        icon: const Icon(Icons.report_problem_outlined, size: 14),
                        label: const Text('Bom hàng', style: TextStyle(fontSize: 11)),
                        onPressed: () => _showReportFailureDialog(context, order, vm),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 14),
                        label: const Text('Hủy nhận', style: TextStyle(fontSize: 11)),
                        onPressed: () => _showCancelPickupDialog(context, order, vm),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(Icons.qr_code_scanner, size: 14, color: Colors.white),
                        label: const Text('Trao hàng', style: TextStyle(color: Colors.white, fontSize: 11)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShipperHandoverConfirmScreen(
                                order: order,
                                shipperId: widget.shipperId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelPickupDialog(
    BuildContext context,
    ShipperBatchItemModel order,
    ShipperViewModel vm,
  ) async {
    final reasonController = TextEditingController(text: 'Sự cố xe cộ / Không thể giao kịp');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        title: Text('Hủy nhận đơn #${order.orderCode}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đơn hàng sẽ được chuyển lại trạng thái SẴN SÀNG để tài xế khác trong ca tiếp nhận giao đến KTX.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy nhận',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận trả đơn'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await vm.cancelPickup(
        orderId: order.orderId,
        shipperId: widget.shipperId,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã hủy nhận đơn thành công, trả lại bếp KTX.' : 'Không thể hủy đơn lúc này.'),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReportFailureDialog(
    BuildContext context,
    ShipperBatchItemModel order,
    ShipperViewModel vm,
  ) async {
    String selectedReason = 'Khách không nghe máy (đã gọi 3 lần)';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
          title: Text('Báo cáo khách bom hàng #${order.orderCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Biên bản sự cố sẽ được gửi tới Ban Quản Lý KTX và Quán ăn để ghi nhận đối soát:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Khách không nghe máy (đã gọi 3 lần)', child: Text('Không nghe máy (3 lần)')),
                  DropdownMenuItem(value: 'Khách từ chối nhận đồ ăn', child: Text('Khách từ chối nhận')),
                  DropdownMenuItem(value: 'Khách sai thông tin phòng/tòa KTX', child: Text('Sai địa chỉ / phòng')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy bỏ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gửi báo cáo sự cố'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await vm.reportFailure(
        orderId: order.orderId,
        shipperId: widget.shipperId,
        reason: selectedReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã ghi nhận sự cố bom hàng. Admin KTX sẽ đối soát bảo vệ quyền lợi tài xế.' : 'Gửi báo cáo thất bại.'),
            backgroundColor: ok ? AppColors.warning : AppColors.error,
          ),
        );
      }
    }
  }
}