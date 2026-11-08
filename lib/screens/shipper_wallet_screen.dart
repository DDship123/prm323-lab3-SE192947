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
import '../widgets/ktx_button.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'shipper_wallet_history_screen.dart';
import 'shipper_withdraw_confirm_screen.dart';

class ShipperWalletScreen extends StatefulWidget {
  final String shipperId;

  const ShipperWalletScreen({super.key, required this.shipperId});

  @override
  State<ShipperWalletScreen> createState() => _ShipperWalletScreenState();
}

class _ShipperWalletScreenState extends State<ShipperWalletScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipperViewModel>().fetchWallet(shipperId: widget.shipperId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shipperVm = context.watch<ShipperViewModel>();
    final state = shipperVm.walletState;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Ví Thu nhập & Đối soát',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới ví',
            onPressed: () {
              context.read<ShipperViewModel>().fetchWallet(shipperId: widget.shipperId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử ví',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShipperWalletHistoryScreen(shipperId: widget.shipperId),
                ),
              );
            },
          ),
        ],
      ),
      body: switch (state) {
        StateInitial() || StateLoading() => const KtxLoadingState(message: 'Đang tải thông tin ví...'),
        StateError(errorMessage: final msg) => KtxErrorState(
            errorMessage: msg,
            onRetry: () => shipperVm.fetchWallet(shipperId: widget.shipperId),
          ),
        StateEmpty(message: final msg) => KtxEmptyState(title: 'Ví trống', message: msg),
        StateSuccess(data: final data) => RefreshIndicator(
            onRefresh: () async {
              await shipperVm.fetchWallet(shipperId: widget.shipperId);
            },
            child: _buildWalletContent(data),
          ),
      },
    );
  }

  Widget _buildWalletContent(ShipperWalletModel wallet) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FF5722),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số dư khả dụng',
                style: AppTypography.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                currencyFormatter.format(wallet.walletBalance),
                style: AppTypography.heading1.copyWith(color: Colors.white, fontSize: 30),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thực nhận hôm nay', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(wallet.completedEarnings),
                            style: const TextStyle(color: Color(0xFFE0F2FE), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.white24),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Chờ đối soát ca', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormatter.format(wallet.pendingEarnings),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.white24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Thu hộ COD', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(wallet.codCollectedToday),
                            style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KtxButton(
          label: 'Rút tiền thù lao',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShipperWithdrawConfirmScreen(
                  shipperId: widget.shipperId,
                  maxBalance: wallet.walletBalance,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Giao dịch gần đây', style: AppTypography.heading2),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShipperWalletHistoryScreen(shipperId: widget.shipperId),
                  ),
                );
              },
              child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...wallet.recentTransactions.map((tx) => _buildTransactionTile(tx)),
      ],
    );
  }

  Widget _buildTransactionTile(WalletTransactionItem tx) {
    final isIncome = tx.amount > 0;
    String timeStr = '';
    if (tx.createdAt != null) {
      final dt = tx.createdAt!;
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      timeStr = '$d/$m $h:$min';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(tx.transactionId, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('•  $timeStr', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
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
  }
}

