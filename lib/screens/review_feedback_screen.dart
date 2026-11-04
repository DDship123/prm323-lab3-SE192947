import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/review_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_text_field.dart';

/// Màn hình S9: Đánh giá Chất lượng Quán ăn & Shipper sau khi nhận hàng (API-017)
class ReviewFeedbackScreen extends StatefulWidget {
  final OrderDetailModel order;

  const ReviewFeedbackScreen({
    super.key,
    required this.order,
  });

  @override
  State<ReviewFeedbackScreen> createState() => _ReviewFeedbackScreenState();
}

class _ReviewFeedbackScreenState extends State<ReviewFeedbackScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewViewModel>().resetForm();
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview(ReviewViewModel vm) async {
    vm.setComment(_commentCtrl.text);
    final ok = await vm.submitOrderReview(widget.order.id);
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cảm ơn bạn đã gửi đánh giá! Điểm trung bình của quán đã được cập nhật.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Đánh giá Đơn hàng S9',
        subtitle: widget.order.orderCode,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.errorMessage != null) ...[
              KtxErrorState(
                message: vm.errorMessage!,
                isInlineBanner: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildRatingCard(
              title: 'Chất lượng món ăn (${widget.order.storeName})',
              subtitle: 'Món ăn có nóng hổi, đầy đủ và đúng vị không?',
              currentRating: vm.storeRating,
              onChanged: vm.setStoreRating,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRatingCard(
              title: 'Dịch vụ Shipper giao gom KTX',
              subtitle:
                  'Shipper giao tại ${widget.order.pickupLocation} có đúng giờ?',
              currentRating: vm.shipperRating,
              onChanged: vm.setShipperRating,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: KtxTextField(
                label: 'Nhận xét chi tiết của bạn',
                hintText:
                    'Ví dụ: Cơm sườn ngon, shipper giao đúng 11h30 tại trụ B2...',
                controller: _commentCtrl,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            KtxButton(
              label: 'Gửi đánh giá (1 - 5 sao)',
              icon: Icons.send_rounded,
              isLoading: vm.isSubmitting,
              onPressed: () => _submitReview(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required String subtitle,
    required int currentRating,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTypography.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (idx) {
              final starValue = idx + 1;
              return IconButton(
                onPressed: () => onChanged(starValue),
                iconSize: 38,
                icon: Icon(
                  starValue <= currentRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          Text(
            '$currentRating / 5 sao',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
