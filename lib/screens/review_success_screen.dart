import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme/ktx_design_system.dart';
import 'order_history_screen.dart';

/// Màn hình Đánh giá thành công theo tài liệu Thông số thiết kế KTX Food
class ReviewSuccessScreen extends StatelessWidget {
  final OrderDetailModel order;

  const ReviewSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(
        title: 'Đánh Giá Thành Công',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),

            // Icon tick xanh thành công
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.iconBoxBackground, // #fff7ed
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 46,
                    color: AppColors.success, // #059669
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đánh giá thành công!',
              style: AppTypography.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Cảm ơn bạn đã phản hồi. Nhận xét của bạn giúp cải thiện chất lượng phục vụ tại KTX.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Thẻ thưởng sinh viên +50 điểm (Node 766:8279)
            KtxCard(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.iconBoxBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thưởng sinh viên: +50 Điểm KTX',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Tương đương giảm 5.000đ cho đơn ca tối kế tiếp!',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Thẻ tóm tắt đơn hàng đã đánh giá
            KtxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MÃ ĐƠN: #${order.orderCode}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      KtxPill(
                        label: order.status == 'DELIVERED'
                            ? 'HOÀN TẤT'
                            : (order.status == 'CONFIRMED'
                                ? 'ĐÃ TIẾP NHẬN'
                                : (order.status == 'DELIVERING'
                                    ? 'ĐANG GIAO'
                                    : 'HOÀN TẤT')),
                        variant: KtxPillVariant.done,
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: AppColors.divider),
                  Text(
                    order.storeName,
                    style: AppTypography.storeTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Điểm nhận: ${order.pickupLocation}',
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // NÚT CHÍNH DUY NHẤT: Xem lịch sử đơn hàng
            KtxButton(
              label: 'Xem Lịch Sử Đơn Hàng',
              variant: KtxButtonVariant.primary,
              icon: Icons.history_rounded,
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const OrderHistoryScreen(),
                  ),
                  (route) => route.isFirst,
                );
              },
            ),
            const SizedBox(height: 8),

            // Nút phụ: Về trang chủ
            KtxButton(
              label: 'Về Trang Chủ',
              variant: KtxButtonVariant.secondary,
              icon: Icons.home_rounded,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
