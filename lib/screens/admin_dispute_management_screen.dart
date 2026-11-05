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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchAllDisputes(adminId: widget.adminId);
    });
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
                Text('Đơn hàng #${dispute.orderId}', style: AppTypography.heading3),
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
            Text('Quán bị khiếu nại: ${dispute.storeName ?? "Cơm Tấm Cô Ba"}', style: AppTypography.bodySmall),
            Text('Lý do: ${dispute.reason}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            Text('Mô tả sự cố: ${dispute.description}', style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            Text(
              'Yêu cầu hoàn tiền: ${currencyFormatter.format(dispute.requestedRefundAmount)}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            if (isPending)
              Row(
                children: [
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã duyệt hoàn tiền thành công!')),
                        );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã từ chối khiếu nại')),
                        );
                      },
                    ),
                  ),
                ],
              )
            else
              Text(
                'Ghi chú thẩm định: ${dispute.adminNote ?? "Đã xử lý"}',
                style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}