import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class ShipperWithdrawSuccessScreen extends StatelessWidget {
  final double amount;
  final String bankName;
  final String accountNumber;

  const ShipperWithdrawSuccessScreen({
    super.key,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KtxAppBar(title: 'Thông báo kết quả rút tiền'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Yêu cầu rút tiền thành công!', style: AppTypography.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Số tiền sẽ được chuyển về tài khoản ngân hàng của bạn trong vòng 5–15 phút.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildRow('Số tiền rút', currencyFormatter.format(amount), isBold: true),
                  const Divider(height: 16),
                  _buildRow('Ngân hàng', bankName),
                  const SizedBox(height: 8),
                  _buildRow('Số tài khoản', accountNumber),
                  const SizedBox(height: 8),
                  _buildRow('Thời gian tạo', 'Hôm nay - Vừa xong'),
                  const SizedBox(height: 8),
                  _buildRow('Phí dịch vụ', 'Miễn phí (0đ)', isGreen: true),
                ],
              ),
            ),
            const Spacer(),
            KtxButton(
              label: 'Hoàn tất & Quay lại ví',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isGreen ? AppColors.success : AppColors.textPrimary,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
