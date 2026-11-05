import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Thanh giỏ hàng nổi bám đáy chuẩn Figma (Node 822:394 & 605:381):
/// - Nền tối Dark Card: #111827 (RGB: 17, 24, 39, bo góc 16)
/// - Trái: Icon giỏ hàng cam (#ff5722) 36x36 kèm huy hiệu số lượng đỏ (#ef4444)
/// - Giữa:
///   + Dòng 1: "Đơn gom KTX Khu B" (#9ca3af, 11px)
///   + Dòng 2: "X món" (trắng 13 Bold) • "XXX.000đ" (cam #ff5722 14 Bold)
/// - Phải: Nút "Xem giỏ hàng" hoặc "Chốt đơn" nền cam #ff5722 bo tròn 12 với icon mũi tên ->
class KtxStickyCartBar extends StatelessWidget {
  final int itemCount;
  final double totalAmount;
  final VoidCallback onCheckoutTap;
  final String pickupLocation;
  final String buttonLabel;

  const KtxStickyCartBar({
    super.key,
    required this.itemCount,
    required this.totalAmount,
    required this.onCheckoutTap,
    this.pickupLocation = 'Đơn gom KTX Khu B',
    this.buttonLabel = 'Xem giỏ hàng',
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    return Semantics(
      label: 'bar_sticky_cart',
      button: true,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCheckoutTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827), // Chuẩn Figma: Dark surface #111827 (95%)
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1F2937),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.3),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon Giỏ hàng tròn 36x36 cam kèm badge số lượng đỏ
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.primary, // Cam #ff5722
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // Badge đỏ tươi #ef4444
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: const Color(0xFF111827), width: 1.5),
                            ),
                            child: Text(
                              '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Thông tin: Địa điểm gom & Dòng tổng số món + tiền gắn biến
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pickupLocation,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$itemCount món',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _formatCurrency(totalAmount),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Nút hành động bên phải: "Xem giỏ hàng" hoặc "Chốt đơn"
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
