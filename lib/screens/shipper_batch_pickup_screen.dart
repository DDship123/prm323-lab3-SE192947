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

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Shipper không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSignOut?.call();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShipperViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.local_shipping_rounded, color: Color(0xFFFF521B), size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Đội Xe Gom KTX Food',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Trực Bàn số 2 • Cổng KTX Khu B (Ca Trưa)',
                              style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quét QR giao nhanh',
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFF521B), size: 22),
                    onPressed: () => _openQuickScanDialog(context, vm),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () => vm.fetchBatch(shipperId: widget.shipperId),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Tài khoản & Đăng xuất',
                    onSelected: (val) {
                      if (val == 'logout') {
                        _confirmSignOut(context);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nguyễn Hùng (Shipper)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('shipper.hung@fpt.edu.vn', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF521B), width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
            padding: const EdgeInsets.all(16),
            children: [
              _buildBatchSummaryCard(batch),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFFFF521B)),
                  SizedBox(width: 6),
                  Text(
                    'Danh sách đơn gom cần phát tại bàn:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...batch.orders.map((o) => _buildShipperOrderCard(o, vm)),
            ],
          ),
      },
    );
  }

  Widget _buildBatchSummaryCard(ShipperBatchModel batch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFFF521B)),
                  SizedBox(width: 6),
                  Text(
                    'Chuyến gom Ca Trưa 11:30',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '${batch.totalOrders} đơn gom',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Điểm tập kết: Bàn số 2 • Cổng KTX Khu B',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text(
                'Thù lao ước tính: ',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              Text(
                currencyFormatter.format(batch.totalDeliveryEarnings),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF521B)),
              ),
              const Text(
                ' (15k ship / đơn)',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildShipperActionChip(
                  icon: Icons.alt_route_rounded,
                  label: 'Lộ trình gom hàng',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShipperRouteScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildShipperActionChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Ví thu nhập & COD',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperWalletScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildShipperActionChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Đăng ký ca mới',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperShiftRegistrationScreen(shipperId: widget.shipperId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildShipperActionChip(
                  icon: Icons.assessment_rounded,
                  label: 'Tổng kết ca',
                  onTap: () {
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

  Widget _buildShipperActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFFF521B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipperOrderCard(ShipperBatchItemModel order, ShipperViewModel vm) {
    final isDelivering = order.status == 'DELIVERING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  '#${order.orderCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFFF521B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivering ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDelivering ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  isDelivering ? 'Đang giao tới sảnh' : order.status,
                  style: TextStyle(
                    color: isDelivering ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.customerName} • ${order.customerPhone}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'PIN: ${order.pickupPin ?? "4829"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.storeName} (${order.storeAddress})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Tiền thu: ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    currencyFormatter.format(order.finalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF521B)),
                  ),
                ],
              ),
              if (!isDelivering)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF521B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Lấy hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.report_problem_outlined, size: 14),
                      label: const Text('Sự cố', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showReportFailureDialog(context, order, vm),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 14, color: Colors.white),
                      label: const Text('Trao hàng QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _openQuickScanDialog(BuildContext context, ShipperViewModel vm) {
    final state = vm.state;
    if (state is! StateSuccess<ShipperBatchModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đợi tải danh sách đơn hàng ca gom.')),
      );
      return;
    }

    final batch = state.data;
    final orders = batch.orders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có đơn hàng nào trong ca gom này.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Quét QR Giao Nhanh', style: AppTypography.heading2),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn đơn hàng để đối soát mã QR / PIN với sinh viên tại cổng KTX:',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...orders.map((ord) {
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text('#${ord.orderCode} - ${ord.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SĐT: ${ord.customerPhone} • PIN: ${ord.pickupPin ?? "4567"}'),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Trao hàng', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShipperHandoverConfirmScreen(
                            order: ord,
                            shipperId: widget.shipperId,
                          ),
                        ),
                      ).then((_) => vm.fetchBatch(shipperId: widget.shipperId));
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}