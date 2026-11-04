import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

class RestaurantDisputesScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantDisputesScreen({super.key, required this.ownerId});

  @override
  State<RestaurantDisputesScreen> createState() => _RestaurantDisputesScreenState();
}

class _RestaurantDisputesScreenState extends State<RestaurantDisputesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đánh giá & Xử lý Khiếu nại KTX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Đánh giá món (4.8 ★)'),
            Tab(text: 'Khiếu nại KTX (2)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsList(),
          _buildDisputesList(),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviews = [
      {
        'student': 'Ngô Trường Đạt',
        'rating': 5,
        'dish': 'Cơm Tấm Sườn Nướng',
        'comment': 'Sườn ướp đậm đà, mỡ hành thơm, cơm nóng hổi ăn rất ngon!',
        'date': 'Hôm nay 12:15',
      },
      {
        'student': 'Trần Sanh Điền',
        'rating': 5,
        'dish': 'Cơm Sườn Bì Chả Đặc Biệt',
        'comment': 'Chả trứng béo mềm, giao đúng ca trưa kịp giờ học.',
        'date': 'Hôm qua 11:45',
      },
      {
        'student': 'Lê Hoàng Nam',
        'rating': 4,
        'dish': 'Cơm Sườn Trứng Ốp La',
        'comment': 'Đồ ăn ngon nhưng nước mắm hơi ngọt một chút.',
        'date': '02/11/2026',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (ctx, i) {
        final r = reviews[i];
        return Container(
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
                  Text(r['student'] as String, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  Text(r['date'] as String, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (star) => Icon(
                    Icons.star,
                    size: 16,
                    color: star < (r['rating'] as int) ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('Món: ${r['dish']}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(r['comment'] as String, style: AppTypography.bodySmall),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisputesList() {
    final disputes = [
      {
        'orderCode': 'KTX-8420A',
        'student': 'Nguyễn Văn Minh',
        'reason': 'Thiếu trứng ốp la lòng đào đã thanh toán thêm',
        'amount': '5.000đ',
        'status': 'CHỜ PHẢN HỒI',
      },
      {
        'orderCode': 'KTX-8602C',
        'student': 'Phạm Thu Hương',
        'reason': 'Đơn bị đổ canh trong quá trình vận chuyển',
        'amount': '15.000đ',
        'status': 'ĐÃ HOÀN TIỀN',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: disputes.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (ctx, i) {
        final d = disputes[i];
        final isPending = d['status'] == 'CHỜ PHẢN HỒI';

        return Container(
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
                  Text('Đơn hàng #${d['orderCode']}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPending ? AppColors.warningLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      d['status'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPending ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Sinh viên: ${d['student']}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              Text('Nội dung: ${d['reason']}', style: AppTypography.bodySmall),
              const Divider(height: 16),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đồng ý hoàn tiền 5.000đ cho sinh viên')),
                          );
                        },
                        child: const Text('Đồng ý hoàn tiền'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi giải trình đến ban quản lý KTX')),
                          );
                        },
                        child: const Text('Giải trình', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              else
                Text('Đã đối soát xong và hoàn trả vào ví sinh viên.',
                    style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
