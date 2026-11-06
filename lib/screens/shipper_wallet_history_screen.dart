import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shipper_wallet_model.dart';
import '../services/shipper_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';

class ShipperWalletHistoryScreen extends StatefulWidget {
  final String shipperId;

  const ShipperWalletHistoryScreen({super.key, required this.shipperId});

  @override
  State<ShipperWalletHistoryScreen> createState() => _ShipperWalletHistoryScreenState();
}

class _ShipperWalletHistoryScreenState extends State<ShipperWalletHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final ShipperApiService _shipperService = ShipperApiService();
  int _filterIndex = 0; // 0: Tất cả, 1: Thù lao, 2: Rút tiền
  bool _isLoading = true;
  List<WalletTransactionItem> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await _shipperService.fetchWallet(
        idToken: null,
        shipperId: widget.shipperId,
      );
      if (mounted) {
        setState(() {
          _transactions = wallet.recentTransactions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _transactions = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    try {
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m $h:$min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _transactions.where((tx) {
      if (_filterIndex == 1) return tx.type == 'CONG_THU_LAO';
      if (_filterIndex == 2) return tx.type == 'RUT_TIEN';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Lịch sử giao dịch ví'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                  child: filtered.isEmpty
                      ? const KtxEmptyState(
                          title: 'Chưa có giao dịch',
                          message: 'Lịch sử ví của bạn sẽ xuất hiện tại đây sau khi hoàn tất các chuyến gom.',
                        )
                      : ListView.separated(
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
                                          '${tx.transactionId} • ${tx.createdAt != null ? _formatDateTime(tx.createdAt!) : ''}',
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

