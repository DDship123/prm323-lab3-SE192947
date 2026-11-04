import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/dispute_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/dispute_vm.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';

/// Màn hình S8b: Lịch sử khiếu nại & Theo dõi tiến trình thẩm định hoàn tiền
class DisputeHistoryScreen extends StatefulWidget {
  const DisputeHistoryScreen({super.key});

  @override
  State<DisputeHistoryScreen> createState() => _DisputeHistoryScreenState();
}

class _DisputeHistoryScreenState extends State<DisputeHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<DisputeViewModel>().fetchDisputeHistory(userId: user.uid);
    }
  }

  Color _getStatusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.pending:
        return AppColors.warning;
      case DisputeStatus.approved:
      case DisputeStatus.refunded:
        return AppColors.success;
      case DisputeStatus.rejected:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DisputeViewModel>();
    final state = vm.historyState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử khiếu nại KTX'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const KtxLoadingState(
            message: 'Đang tải lịch sử khiếu nại...',
          ),
        StateEmpty(message: final msg) => KtxEmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Không có khiếu nại nào',
            message: msg,
          ),
        StateError(errorMessage: final err) => KtxErrorState(
            errorMessage: err,
            onRetry: _loadHistory,
          ),
        StateSuccess(data: final disputes) => RefreshIndicator(
            onRefresh: () async => _loadHistory(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final dispute = disputes[index];
                final statusColor = _getStatusColor(dispute.status);

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
                        // Tiêu đề đơn hàng và trạng thái
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đơn hàng #${dispute.orderId}',
                              style: AppTypography.heading3,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                dispute.status.label,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dispute.storeName ?? 'Quán ăn KTX',
                          style: AppTypography.bodySmall,
                        ),
                        const Divider(height: 20),

                        // Lý do & Mô tả
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.report_problem_outlined, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dispute.reason,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 26.0),
                          child: Text(
                            dispute.description,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ảnh bằng chứng tải từ Cloud Storage
                        if (dispute.evidenceImageUrl.isNotEmpty) ...[
                          const Text(
                            'Bằng chứng tải từ Cloud Storage:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: AppRadius.roundedSm,
                            child: Image.network(
                              dispute.evidenceImageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: Text('Không thể tải ảnh bằng chứng', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Số tiền hoàn & Thời gian
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Yêu cầu hoàn: ${currencyFormatter.format(dispute.requestedRefundAmount)}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateFormatter.format(dispute.createdAt),
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),

                        if (dispute.adminNote != null && dispute.adminNote!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.roundedSm,
                            ),
                            child: Text(
                              'Phản hồi từ KTX: ${dispute.adminNote}',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      },
    );
  }
}

