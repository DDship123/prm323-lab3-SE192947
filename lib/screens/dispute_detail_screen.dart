import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

class DisputeDetailScreen extends StatelessWidget {
  final String disputeCode;
  final String orderCode;

  const DisputeDetailScreen({
    super.key,
    this.disputeCode = 'DISP-8420A',
    this.orderCode = 'KTX-8420A',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(title: 'Chi tiết khiếu nại đã gửi - #$orderCode'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mã đơn: #$orderCode', style: AppTypography.heading2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'ĐANG XỬ LÝ',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Quán ăn liên quan: Cơm Tấm Cô Ba - ĐHQG',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                Text('Thời gian gửi: Hôm nay lúc 12:20',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                Text('Lý do & Mô tả sự cố', style: AppTypography.heading3),
                const SizedBox(height: 8),
                Text('Lý do: Thiếu món hoặc thành phần topping',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Em có đặt phần Cơm Tấm Sườn Nướng và chọn thêm Topping Trứng ốp la (+5.000đ), nhưng khi nhận hộp cơm tại cổng KTX thì mở ra không thấy có trứng ốp la ạ.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Hình ảnh minh chứng tải lên:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, color: AppColors.primary, size: 40),
                        const SizedBox(height: 6),
                        Text('Ảnh chụp hộp cơm sườn thiếu trứng ốp la',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.successLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Phương án giải quyết đề xuất',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hoàn trả 5.000đ tiền mặt hoặc cộng vào ví số dư KTX trong vòng 24 giờ sau khi Ban quản trị thẩm định.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
