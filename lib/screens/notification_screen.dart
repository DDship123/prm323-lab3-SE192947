import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Đơn hàng #KTX-1045 đã tới cổng KTX!',
      'body': 'Shipper đang đứng tại Trụ A1–A2 Cổng B2 KTX Khu B. Vui lòng mang điện thoại đọc mã PIN 4567 để nhận món.',
      'time': '5 phút trước',
      'isRead': false,
      'type': 'ORDER',
    },
    {
      'title': 'Mở cổng gom đơn Ca Trưa 11:30',
      'body': 'Ca gom trưa đã chính thức mở. Hơn 15 quán ăn đối tác đang có ưu đãi freeship gom đơn.',
      'time': '1 giờ trước',
      'isRead': false,
      'type': 'BATCH',
    },
    {
      'title': 'Hoàn tiền khiếu nại thành công',
      'body': 'Khiếu nại #KTX-8602C đã được chấp thuận. 15.000đ đã được hoàn trả về tài khoản của bạn.',
      'time': 'Hôm qua',
      'isRead': true,
      'type': 'DISPUTE',
    },
    {
      'title': 'Voucher mới: Giảm 5.000đ phí gom đơn',
      'body': 'Nhập mã GOMDONKTX khi đặt đơn từ 40.000đ để được miễn phí gom đơn ca trưa hôm nay.',
      'time': '2 ngày trước',
      'isRead': true,
      'type': 'PROMO',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Bảng thông báo KTX',
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu đã đọc tất cả')),
              );
            },
            child: const Text('Đọc hết', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (ctx, i) {
          final n = _notifications[i];
          final isRead = n['isRead'] as bool;
          final type = n['type'] as String;

          IconData iconData;
          Color iconColor;
          switch (type) {
            case 'ORDER':
              iconData = Icons.delivery_dining;
              iconColor = AppColors.primary;
              break;
            case 'BATCH':
              iconData = Icons.group_work;
              iconColor = Colors.orange;
              break;
            case 'DISPUTE':
              iconData = Icons.check_circle;
              iconColor = AppColors.success;
              break;
            default:
              iconData = Icons.local_offer;
              iconColor = Colors.purple;
          }

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isRead ? Colors.white : AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n['title'] as String,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['body'] as String, style: AppTypography.bodySmall),
                      const SizedBox(height: 6),
                      Text(n['time'] as String, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
