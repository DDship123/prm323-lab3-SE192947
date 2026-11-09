import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/dispute_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/admin_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';

class AdminDisputeManagementScreen extends StatefulWidget {
  final String adminId;

  const AdminDisputeManagementScreen({super.key, this.adminId = '4'});

  @override
  State<AdminDisputeManagementScreen> createState() => _AdminDisputeManagementScreenState();
}

class _AdminDisputeManagementScreenState extends State<AdminDisputeManagementScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Set<int> _bannedUsers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchAllDisputes(adminId: widget.adminId);
    });
  }

  Future<void> _handleBanUser(int userId, AdminViewModel vm) async {
    final isCurrentlyBanned = _bannedUsers.contains(userId);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCurrentlyBanned ? Icons.lock_open_rounded : Icons.gavel_rounded,
              color: isCurrentlyBanned ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isCurrentlyBanned ? 'Mở khóa tài khoản?' : 'Khóa tài khoản (Ban)?'),
          ],
        ),
        content: Text(
          isCurrentlyBanned
              ? 'Bạn có chắc chắn muốn mở khóa lại tài khoản sinh viên (ID: $userId) không?'
              : 'Bạn có chắc chắn muốn KHÓA / BAN tài khoản (ID: $userId) này không? Tài khoản bị khóa sẽ không thể đặt hàng hoặc nhận đơn trên hệ thống KTX Food.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBanned ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCurrentlyBanned ? 'Mở khóa' : 'Xác nhận Khóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await vm.banUser(
        userId: userId,
        isBanned: !isCurrentlyBanned,
        adminId: widget.adminId,
      );
      setState(() {
        if (isCurrentlyBanned) {
          _bannedUsers.remove(userId);
        } else {
          _bannedUsers.add(userId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyBanned
                  ? 'Đã mở khóa tài khoản ID: $userId thành công!'
                  : 'Đã khóa (Ban) tài khoản ID: $userId thành công!',
            ),
            backgroundColor: isCurrentlyBanned ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Thẩm định Khiếu nại (Ban Quản Lý KTX)',
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => vm.fetchAllDisputes(adminId: widget.adminId),
          ),
        ],
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const KtxLoadingState(message: 'Đang tải danh sách khiếu nại KTX...'),
        StateEmpty(message: final msg) => KtxEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Không có khiếu nại',
            message: msg,
          ),
        StateError(errorMessage: final err) => KtxErrorState(
            errorMessage: err,
            onRetry: () => vm.fetchAllDisputes(adminId: widget.adminId),
          ),
        StateSuccess(data: final disputes) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: disputes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (ctx, i) => _buildDisputeCard(disputes[i], vm),
          ),
      },
    );
  }

  Widget _buildDisputeCard(DisputeModel dispute, AdminViewModel vm) {
    final isPending = dispute.status == DisputeStatus.pending;
    final isBanned = _bannedUsers.contains(dispute.userId);

    return Card(
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
                Row(
                  children: [
                    Text('Đơn hàng #${dispute.orderId}', style: AppTypography.heading3),
                    if (isBanned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Text(
                          'ĐÃ KHÓA TK',
                          style: TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dispute.status.label,
                    style: TextStyle(
                      color: isPending ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Người gửi khiếu nại: Sinh viên ID #${dispute.userId}', style: AppTypography.bodySmall),
            Text('Quán bị khiếu nại: ${dispute.storeName ?? "Cơm Tấm Cô Ba"}', style: AppTypography.bodySmall),
            Text('Lý do: ${dispute.reason}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text('Mô tả sự cố: ${dispute.description}', style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            Text(
              'Yêu cầu hoàn tiền: ${currencyFormatter.format(dispute.requestedRefundAmount)}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
            ),
            if (dispute.evidenceImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: dispute.evidenceImages.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      img,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 20, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 16),
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: KtxButton(
                      label: 'Duyệt hoàn tiền',
                      icon: Icons.check_circle_rounded,
                      onPressed: () async {
                        await vm.resolveDispute(
                          disputeId: dispute.id,
                          status: 'APPROVED',
                          resolutionNote: 'BQL KTX duyệt hoàn tiền theo chính sách đảm bảo bữa ăn',
                          approvedAmount: dispute.requestedRefundAmount,
                          adminId: widget.adminId,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã duyệt hoàn tiền thành công!')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KtxButton(
                      label: 'Từ chối',
                      variant: KtxButtonVariant.danger,
                      icon: Icons.cancel_outlined,
                      onPressed: () async {
                        await vm.resolveDispute(
                          disputeId: dispute.id,
                          status: 'REJECTED',
                          resolutionNote: 'Không đủ bằng chứng theo quy định KTX',
                          approvedAmount: 0.0,
                          adminId: widget.adminId,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã từ chối khiếu nại')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Nút Khóa tài khoản / Ban TK dành cho Admin
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isBanned ? Colors.green : const Color(0xFFDC2626),
                    side: BorderSide(color: isBanned ? Colors.green : const Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(isBanned ? Icons.lock_open_rounded : Icons.block_rounded, size: 16),
                  label: Text(
                    isBanned ? 'Mở TK' : 'Khóa TK',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _handleBanUser(dispute.userId, vm),
                ),
              ],
            ),
            if (!isPending) ...[
              const SizedBox(height: 6),
              Text(
                'Ghi chú thẩm định: ${dispute.adminNote ?? "Đã xử lý"}',
                style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
