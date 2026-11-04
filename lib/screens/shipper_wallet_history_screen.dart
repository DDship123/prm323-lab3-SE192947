import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shipper_wallet_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/shipper_vm.dart';
import '../widgets/ktx_app_bar.dart';

class ShipperWalletHistoryScreen extends StatefulWidget {
  final String shipperId;

  const ShipperWalletHistoryScreen({super.key, required this.shipperId});

  @override
  State<ShipperWalletHistoryScreen> createState() => _ShipperWalletHistoryScreenState();
}

class _ShipperWalletHistoryScreenState extends State<ShipperWalletHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  int _filterIndex = 0; // 0: Tất cả, 1: Thù lao, 2: Rút tiền

  @override
  Widget build(BuildContext context) {
    final shipperVm = context.watch<ShipperViewModel>();
    final state = shipperVm.walletState;

    final mockHistory = [
      WalletTransactionItem(
        transactionId: 'TX-KTX-101',
        type: 'CONG_THU_LAO',
        title: 'Thù lao ca gom trưa 11:30 KTX Khu B',
        amount: 30000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'SUCCESS',
      ),
      WalletTransactionItem(
        transactionId: 'TX-KTX-099',
        type: 'RUT_TIEN',
        title: 'Rút tiền thù lao về Vietcombank (*9876)',
        amount: -200000,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'SUCCESS',
      ),
      WalletTransactionItem(
        transactionId: 'TX-KTX-098',
        type: 'CONG_THU_LAO',
        title: 'Thù lao ca gom chiều 18:00 KTX Khu A',
        amount: 45000,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        status: 'SUCCESS',
      ),
      WalletTransactionItem(
        transactionId: 'TX-KTX-095',
        type: 'NOP_COD',
        title: 'Nộp tiền COD ca trưa cho thủ quỹ KTX',
        amount: -125000,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'SUCCESS',
      ),
    ];

    final filtered = mockHistory.where((tx) {
      if (_filterIndex == 1) return tx.type == 'CONG_THU_LAO';
      if (_filterIndex == 2) return tx.type == 'RUT_TIEN';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Lịch sử giao dịch ví'),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 0),
                const SizedBox(width: 8),
                _buildFilterChip('Thù lao', 1),
                const SizedBox(width: 8),
                _buildFilterChip('Rút tiền', 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final tx = filtered[i];
                final isIncome = tx.amount > 0;
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isIncome ? AppColors.successLight : AppColors.errorLight,
                        child: Icon(
                          isIncome ? Icons.add_rounded : Icons.remove_rounded,
                          color: isIncome ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.transactionId} • ${tx.createdAt != null ? DateFormat('dd/MM HH:mm').format(tx.createdAt!) : ''}',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : ''}${currencyFormatter.format(tx.amount)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _filterIndex = index),
    );
  }
}
