import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class ShipperShiftSummaryScreen extends StatelessWidget {
  final String shipperId;

  const ShipperShiftSummaryScreen({super.key, required this.shipperId});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Tổng kết ca gom hàng'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.border,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: AppColors.success, size: 48),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Ca Trưa Hoàn Tất Tuyệt Vời!', style: AppTypography.heading2),
                const SizedBox(height: 4),
                Text('Ca gom trưa 11:30 – KTX Khu B (Trụ A1-A2)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const Divider(height: 32),
                _buildMetricRow('Số đơn giao thành công', '8 / 8 đơn (100%)', isGreen: true),
                const SizedBox(height: 12),
                _buildMetricRow('Tỷ lệ đúng giờ', '100% (Trước 12:15)', isGreen: true),
                const SizedBox(height: 12),
                _buildMetricRow('Thù lao ca nhận được', currencyFormatter.format(40000), isBold: true, isOrange: true),
                const SizedBox(height: 12),
                _buildMetricRow('Tổng tiền COD đã thu hộ', currencyFormatter.format(172000), isBold: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đối soát tiền mặt COD', style: AppTypography.heading3),
                const SizedBox(height: 6),
                Text(
                  'Vui lòng nộp số tiền 172.000đ tại Bàn Quản lý KTX Khu B trước 12:45 để hệ thống tự động cộng 40.000đ thù lao vào ví của bạn.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Mã đối soát ca: #CA-TRUA-B-104', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          KtxButton(
            label: 'Đã hoàn thành ca & Trở về',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã ghi nhận tổng kết ca gom thành công!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isBold = false, bool isGreen = false, bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: isOrange
                ? AppColors.primary
                : isGreen
                    ? AppColors.success
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
