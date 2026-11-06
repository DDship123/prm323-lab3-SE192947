import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

class ShipperShiftRegistrationScreen extends StatefulWidget {
  final String shipperId;
  final VoidCallback? onSignOut;

  const ShipperShiftRegistrationScreen({
    super.key,
    required this.shipperId,
    this.onSignOut,
  });

  @override
  State<ShipperShiftRegistrationScreen> createState() => _ShipperShiftRegistrationScreenState();
}

class _ShipperShiftRegistrationScreenState extends State<ShipperShiftRegistrationScreen> {
  final List<Map<String, dynamic>> _shifts = [
    {
      'id': 'SHIFT-1',
      'title': 'Ca Trưa KTX Khu B (Trụ A1-A2)',
      'time': '11:00 – 12:30 • Hôm nay',
      'registered': 4,
      'quota': 5,
      'status': 'REGISTERED',
      'reward': '5.000đ / đơn (~35.000đ)',
    },
    {
      'id': 'SHIFT-2',
      'title': 'Ca Trưa KTX Khu A (Cổng 1)',
      'time': '11:15 – 12:45 • Hôm nay',
      'registered': 5,
      'quota': 5,
      'status': 'FULL',
      'reward': '5.000đ / đơn (~45.000đ)',
    },
    {
      'id': 'SHIFT-3',
      'title': 'Ca Chiều KTX Khu B (Trụ A1-A2)',
      'time': '17:30 – 19:00 • Hôm nay',
      'registered': 2,
      'quota': 6,
      'status': 'OPEN',
      'reward': '5.000đ / đơn (~40.000đ)',
    },
    {
      'id': 'SHIFT-4',
      'title': 'Ca Chiều KTX Khu A (Cổng 2)',
      'time': '17:45 – 19:15 • Hôm nay',
      'registered': 1,
      'quota': 4,
      'status': 'OPEN',
      'reward': '5.000đ / đơn (~30.000đ)',
    },
  ];

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Shipper không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSignOut?.call();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Đăng ký Ca & Chuyến gom',
        actions: [
          IconButton(
            tooltip: 'Đăng xuất tài khoản',
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.4),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đăng ký ca trước giờ mở bán 45 phút để hệ thống điều phối gom đơn chính xác đến cổng KTX.',
                    style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Danh sách ca gom hôm nay', style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.sm),
          ..._shifts.map((s) => _buildShiftCard(s)),
          const SizedBox(height: AppSpacing.lg),
          if (widget.onSignOut != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Đăng xuất tài khoản Shipper', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _confirmSignOut(context),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> s) {
    final status = s['status'] as String;
    final isRegistered = status == 'REGISTERED';
    final isFull = status == 'FULL';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isRegistered ? AppColors.primary : AppColors.border,
          width: isRegistered ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(s['title'] as String, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isRegistered
                      ? AppColors.primaryLight
                      : isFull
                          ? AppColors.errorLight
                          : AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  isRegistered
                      ? 'ĐÃ ĐĂNG KÝ'
                      : isFull
                          ? 'HẾT CHỖ'
                          : 'CÒN NHẬN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRegistered
                        ? AppColors.primary
                        : isFull
                            ? AppColors.error
                            : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(s['time'] as String, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Thù lao dự kiến: ${s['reward']}', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Số shipper đã nhận: ${s['registered']}/${s['quota']}',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const Divider(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered
                    ? AppColors.error
                    : isFull
                        ? Colors.grey
                        : AppColors.primary,
              ),
              onPressed: isFull
                  ? null
                  : () {
                      setState(() {
                        if (isRegistered) {
                          s['status'] = 'OPEN';
                          s['registered'] = (s['registered'] as int) - 1;
                        } else {
                          s['status'] = 'REGISTERED';
                          s['registered'] = (s['registered'] as int) + 1;
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRegistered ? 'Đã hủy đăng ký ca gom' : 'Đăng ký nhận ca gom thành công!'),
                        ),
                      );
                    },
              child: Text(
                isRegistered ? 'Hủy nhận ca' : 'Nhận ca gom này',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
