import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

/// Màn hình Hồ sơ Shipper (Tài xế Đội Gom KTX)
/// Khách và Shipper đều có thể xem điểm đánh giá trung bình và danh sách các nhận xét từ khách
class ShipperProfileScreen extends StatefulWidget {
  final int shipperId;
  final String shipperName;
  final String? shipperAvatarUrl;
  final String shipperPhone;

  const ShipperProfileScreen({
    super.key,
    this.shipperId = 3,
    this.shipperName = 'Nguyễn Hùng (Shipper Đội Gom KTX)',
    this.shipperAvatarUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    this.shipperPhone = '0918765432',
  });

  @override
  State<ShipperProfileScreen> createState() => _ShipperProfileScreenState();
}

class _ShipperProfileScreenState extends State<ShipperProfileScreen> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadShipperReviews();
  }

  Future<void> _loadShipperReviews() async {
    setState(() => _isLoading = true);
    final reviewService = ReviewService();
    final list = await reviewService.fetchShipperReviews(widget.shipperId);
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoading = false;
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
    final totalRating = _reviews.fold<double>(
      0.0,
      (acc, r) => acc + (r.shipperRating > 0 ? r.shipperRating : r.storeRating),
    );
    final double avgRating = _reviews.isNotEmpty ? (totalRating / _reviews.length) : 4.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const KtxAppBar(title: 'Hồ Sơ Tài Xế Gom KTX'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF521B)))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. Thẻ thông tin cá nhân Shipper
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.03),
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFEFF6FF),
                        backgroundImage: widget.shipperAvatarUrl != null
                            ? NetworkImage(widget.shipperAvatarUrl!)
                            : null,
                        child: widget.shipperAvatarUrl == null
                            ? const Icon(Icons.two_wheeler_rounded, size: 42, color: Color(0xFF2563EB))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.shipperName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đội xe Gom KTX Khu B • ĐT: ${widget.shipperPhone}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      // Thẻ điểm đánh giá trung bình
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                    const SizedBox(width: 4),
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    const Text(' / 5.0', style: TextStyle(fontSize: 13, color: Color(0xFFB45309))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Đánh giá trung bình',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 36, color: const Color(0xFFFDE68A)),
                            Column(
                              children: [
                                Text(
                                  '${_reviews.length}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Lượt đánh giá',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '★ Điểm đánh giá trung bình = Tổng số điểm các chuyến đi cộng lại chia đều',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Danh sách nhận xét từ khách hàng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nhận xét từ khách hàng (${_reviews.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: _loadShipperReviews,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'Chưa có nhận xét nào cho tài xế này.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  ..._reviews.map((rev) {
                    final rating = rev.shipperRating > 0 ? rev.shipperRating : rev.storeRating;
                    final timeStr = DateFormat('dd/MM/yyyy • HH:mm').format(rev.createdAt);
                    final commentText = rev.shipperComment?.trim().isNotEmpty == true
                        ? rev.shipperComment!
                        : (rev.comment?.trim().isNotEmpty == true ? rev.comment! : 'Giao hàng đúng giờ, đồ ăn bảo quản tốt!');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      '$timeStr • Đơn ${rev.orderCode}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 16,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            commentText,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                          ),
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
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 72,
                                        height: 72,
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
            ),
    );
  }
}
