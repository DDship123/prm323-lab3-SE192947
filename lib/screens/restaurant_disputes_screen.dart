import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class RestaurantDisputesScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantDisputesScreen({super.key, required this.ownerId});

  @override
  State<RestaurantDisputesScreen> createState() => _RestaurantDisputesScreenState();
}

class _RestaurantDisputesScreenState extends State<RestaurantDisputesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreReviews() async {
    setState(() => _isLoadingReviews = true);
    final reviewService = ReviewService();
    final list = await reviewService.fetchStoreReviews(1);
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoadingReviews = false;
      });
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const Text('Không thể tải ảnh'),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRating = _reviews.fold<double>(0.0, (acc, r) => acc + r.storeRating);
    final avgRating = _reviews.isNotEmpty ? (totalRating / _reviews.length) : 4.8;

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
          tabs: [
            Tab(text: 'Đánh giá món (${avgRating.toStringAsFixed(1)} ★)'),
            const Tab(text: 'Khiếu nại KTX (2)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsList(avgRating),
          _buildDisputesList(),
        ],
      ),
    );
  }

  Widget _buildReviewsList(double avgRating) {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text('Chưa có đánh giá nào từ sinh viên KTX', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStoreReviews,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Thẻ tổng quan điểm trung bình
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá trung bình: ${avgRating.toStringAsFixed(1)} / 5.0 sao',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB45309)),
                    ),
                    Text(
                      'Tổng điểm cộng lại chia đều cho ${_reviews.length} lượt đánh giá từ khách hàng',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFB45309)),
                onPressed: _loadStoreReviews,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews.map((rev) {
          final timeStr = DateFormat('dd/MM/yyyy • HH:mm').format(rev.createdAt);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFFECE5),
                      backgroundImage: rev.userAvatarUrl != null && rev.userAvatarUrl!.isNotEmpty
                          ? NetworkImage(rev.userAvatarUrl!)
                          : null,
                      child: rev.userAvatarUrl == null || rev.userAvatarUrl!.isEmpty
                          ? Text(
                              rev.userDisplayName.isNotEmpty ? rev.userDisplayName[0].toUpperCase() : 'S',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF521B), fontSize: 13),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rev.userDisplayName,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            timeStr,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (star) => Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: star < rev.storeRating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Đơn: ${rev.orderCode}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                if (rev.comment != null && rev.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(rev.comment!, style: AppTypography.bodySmall),
                ],
                if (rev.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rev.images.map((imgUrl) {
                      return InkWell(
                        onTap: () => _showImageDialog(context, imgUrl),
                        borderRadius: BorderRadius.circular(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imgUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.broken_image, size: 20, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
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
