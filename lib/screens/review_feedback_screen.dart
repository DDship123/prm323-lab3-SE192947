import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../theme/ktx_design_system.dart';
import '../viewmodels/review_vm.dart';
import '../widgets/ktx_error_state.dart';
import 'review_success_screen.dart';

/// Màn hình S9: Đánh giá bữa ăn KTX theo tài liệu Thông số thiết kế (Figma Frame 9 - Node 766:8086)
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
  final Set<String> _selectedStoreTags = {};
  final Set<String> _selectedShipperTags = {};
  bool _isAnonymous = false;

  static const _storeTags = [
    'Ngon miệng',
    'Nóng hổi',
    'Đóng gói cẩn thận',
    'Đúng ghi chú',
    'Khẩu phần đầy đặn',
  ];

  static const _shipperTags = [
    'Đến cổng đúng hẹn',
    'Nhiệt tình, lễ phép',
    'Bảo quản thức ăn tốt',
    'Giao đúng bàn KTX',
  ];

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
    final extraDetails = <String>[];
    if (_selectedStoreTags.isNotEmpty) {
      extraDetails.add('Quán: ${_selectedStoreTags.join(", ")}');
    }
    if (_selectedShipperTags.isNotEmpty) {
      extraDetails.add('Shipper: ${_selectedShipperTags.join(", ")}');
    }
    if (_isAnonymous) {
      extraDetails.add('(Đánh giá ẩn danh)');
    }

    final commentText = _commentCtrl.text.trim();
    final fullComment = [
      if (commentText.isNotEmpty) commentText,
      if (extraDetails.isNotEmpty) '[${extraDetails.join(" • ")}]',
    ].join('\n');

    vm.setComment(fullComment);
    final ok = await vm.submitOrderReview(widget.order.id);
    if (!mounted || !ok) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReviewSuccessScreen(order: widget.order),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Xuất sắc • Rất hài lòng';
      case 4:
        return 'Tốt • Hài lòng';
      case 3:
        return 'Bình thường';
      case 2:
        return 'Chưa hài lòng';
      case 1:
        return 'Kém • Cần cải thiện';
      default:
        return '$rating sao';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewViewModel>();
    final shipperDisplayName = widget.order.shipperName?.isNotEmpty == true
        ? widget.order.shipperName!
        : 'Nguyễn Văn Minh';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Đánh Giá & Phản Hồi',
        subtitle: widget.order.orderCode,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
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

            // 1. THẺ ĐÁNH GIÁ MÓN ĂN (Mục 4: bo 16, đệm 12, viền #f3f4f6, bóng 5%)
            KtxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Text(
                          '01',
                          style: AppTypography.chipLabel.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chất lượng món ăn',
                          style: AppTypography.heading3,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          widget.order.storeName,
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: AppColors.divider),
                  Text(
                    'Món ăn có tươi ngon, chuẩn vị và đóng gói kỹ càng không?',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _buildInteractiveStarRow(
                    currentRating: vm.storeRating,
                    onChanged: vm.setStoreRating,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _ratingLabel(vm.storeRating),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ĐIỂM NỔI BẬT CỦA MÓN ĂN',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _storeTags.map((tag) {
                      final isSelected = _selectedStoreTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedStoreTags.remove(tag);
                            } else {
                              _selectedStoreTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
                            borderRadius: AppRadius.roundedFull,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.chipLabel.copyWith(
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. THẺ ĐÁNH GIÁ SHIPPER
            KtxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Text(
                          '02',
                          style: AppTypography.chipLabel.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đánh giá Người Giao Hàng',
                          style: AppTypography.heading3,
                        ),
                      ),
                      const KtxPill(
                        label: 'SH - 042',
                        variant: KtxPillVariant.received,
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: AppColors.divider),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.two_wheeler_rounded,
                          color: AppColors.primaryDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shipperDisplayName,
                              style: AppTypography.storeTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Đội xe Gom KTX B • Chuyến 11:30 - 12:00',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInteractiveStarRow(
                    currentRating: vm.shipperRating,
                    onChanged: vm.setShipperRating,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _ratingLabel(vm.shipperRating),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PHẢN HỒI DỊCH VỤ GIAO HÀNG',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _shipperTags.map((tag) {
                      final isSelected = _selectedShipperTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedShipperTags.remove(tag);
                            } else {
                              _selectedShipperTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
                            borderRadius: AppRadius.roundedFull,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.chipLabel.copyWith(
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. THẺ NHẬN XÉT CHI TIẾT & ẨN DANH
            KtxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KtxTextField(
                    label: 'CHI TIẾT NHẬN XÉT',
                    hintText: 'Chia sẻ cảm nhận về hương vị, độ tươi ngon và nhiệt độ món ăn...',
                    controller: _commentCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đánh giá ẩn danh',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Ẩn tên tài khoản và số phòng KTX với người bán',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isAnonymous = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. THẺ THƯỞNG SINH VIÊN (Theo Figma Node 766:8279)
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.iconBoxBackground, // #fff7ed
                borderRadius: AppRadius.roundedCard,
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn sẽ nhận được +50 Điểm KTX (tương đương giảm 5.000đ cho đơn ca tối kế tiếp).',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // NÚT CHÍNH DUY NHẤT: Gửi Đánh Giá (Mục 5: nền #ff5722, cao 44)
            KtxButton(
              label: 'Gửi Đánh Giá & Nhận 50 Điểm KTX',
              variant: KtxButtonVariant.primary,
              icon: Icons.send_rounded,
              isLoading: vm.isSubmitting,
              onPressed: () => _submitReview(vm),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveStarRow({
    required int currentRating,
    required ValueChanged<int> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final starSize = (constraints.maxWidth / 7).clamp(26.0, 36.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (idx) {
            final starValue = idx + 1;
            final isFilled = starValue <= currentRating;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: starSize * 0.08),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: starSize,
                  color: Colors.amber,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
