import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../screens/pickup_qr_code_screen.dart';
import '../theme/app_colors.dart';

/// Hộp thoại Pop-up Toàn Màn Hình thông báo Tài xế đã tới Cổng KTX
/// Phía sau được làm mờ (Blur) và tối đi (Darkened Backdrop)
/// Che khoảng nửa màn hình để người dùng tập trung nhận món
class ShipperArrivedPopupDialog extends StatelessWidget {
  final OrderDetailModel order;

  const ShipperArrivedPopupDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, OrderDetailModel order) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ShipperArrivedModal',
      barrierColor: Colors.black.withOpacity(0.68),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return ShipperArrivedPopupDialog(order: order);
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * anim1.value,
            sigmaY: 8.0 * anim1.value,
          ),
          child: ScaleTransition(
            scale: curved,
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dialogWidth = math.min(420.0, media.size.width * 0.90);
    final pin = order.pickupPin.isNotEmpty ? order.pickupPin : '8448';
    final location = order.pickupLocation.isNotEmpty
        ? order.pickupLocation
        : 'Bàn số 2 • Cổng KTX Khu B';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: media.size.height * 0.78,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFFFF521B).withOpacity(0.25),
                blurRadius: 48,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header gradient rực rỡ với icon xe giao hàng phát sáng
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 28, bottom: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6E40), Color(0xFFFF521B), Color(0xFFE64A19)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Nút đóng góc trên
                        Positioned(
                          top: -12,
                          right: 12,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Column(
                          children: [
                            // Icon xe giao hàng nổi bật có vòng tròn phát sáng
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  color: Color(0xFFFF521B),
                                  size: 46,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              '🚚 TÀI XẾ ĐÃ ĐẾN CỔNG KTX!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Món ăn nóng hổi của bạn đã sẵn sàng tại điểm hẹn!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Phần thân: Chi tiết đơn & Mã PIN
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Khung thông tin đơn hàng
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFEDD5), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Mã đơn: #${order.orderCode.replaceAll('#', '')}',
                                      style: const TextStyle(
                                        color: Color(0xFFC2410C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ĐÃ TỚI CỔNG',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF9A3412)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      order.storeName.isNotEmpty ? order.storeName : 'Quán KTX',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFEA580C)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF431407),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Khung mã PIN đối soát to rõ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'MÃ PIN NHẬN HÀNG (ĐỌC CHO TÀI XẾ)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pin,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  color: Color(0xFFFF521B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'hoặc quét mã QR tại bàn để lấy món trong 3 giây',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // NÚT CHÍNH: Mở mã QR / PIN
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF521B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PickupQrCodeScreen(order: order),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_2_rounded, size: 22, color: Colors.white),
                          label: const Text(
                            'Mở Mã QR / PIN Nhận Món',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // NÚT PHỤ: Đóng / Để sau
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Để lát nữa nhận / Đóng',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }
}

