import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

class ShipperRouteScreen extends StatelessWidget {
  const ShipperRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Điểm 1: Lấy hàng tại Quán',
        'location': 'Cơm Tấm Cô Ba - Cổng B2 ĐHQG',
        'time': '11:15',
        'status': 'COMPLETED',
        'desc': 'Nhận 10 suất cơm giữ nhiệt và kiểm tra đầy đủ canh/muỗng nĩa.',
      },
      {
        'title': 'Điểm 2: Di chuyển gom đơn',
        'location': 'Tuyến đường Cổng B2 -> KTX Khu B',
        'time': '11:25',
        'status': 'IN_PROGRESS',
        'desc': 'Di chuyển an toàn tốc độ dưới 30km/h trong khuôn viên ĐHQG.',
      },
      {
        'title': 'Điểm 3: Bàn giao nhận tập trung',
        'location': 'KTX Khu B – Trụ A1–A2 (Cổng B2)',
        'time': '11:30 – 12:15',
        'status': 'PENDING',
        'desc': 'Bày hàng lên bàn giao nhận, đối chiếu mã PIN 4 số sinh viên.',
      },
      {
        'title': 'Điểm 4: Đối soát tiền mặt COD',
        'location': 'Văn phòng Quản lý KTX Khu B',
        'time': '12:20',
        'status': 'PENDING',
        'desc': 'Nộp lại tiền mặt COD đã thu và chốt tổng kết thù lao ca.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Lộ trình gom hàng'),
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
            child: Row(
              children: [
                const Icon(Icons.navigation, color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lộ trình Ca Trưa KTX Khu B', style: AppTypography.heading2),
                      Text('Ước tính quãng đường: 2.3 km • 15 phút di chuyển',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(steps.length, (i) {
            final s = steps[i];
            final isCompleted = s['status'] == 'COMPLETED';
            final isInProgress = s['status'] == 'IN_PROGRESS';

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isInProgress ? AppColors.primary : AppColors.border,
                  width: isInProgress ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isCompleted
                            ? AppColors.success
                            : isInProgress
                                ? AppColors.primary
                                : Colors.grey.shade300,
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : isInProgress
                                  ? Icons.directions_bike
                                  : Icons.circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: isCompleted ? AppColors.success : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s['title']!, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text(s['time']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isInProgress ? AppColors.primary : AppColors.textSecondary,
                                )),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(s['location']!, style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(s['desc']!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
